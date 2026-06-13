/**
 * Воркер ИИ-ботов Veloura для запуска на СОБСТВЕННОМ сервере.
 * Замена Cloud Functions: не требует тарифа Blaze.
 *
 * Что делает:
 *  1. Слушает коллекцию likes: живой пользователь лайкнул бота →
 *     взаимный лайк, мэтч, чат, первое сообщение от бота.
 *  2. Слушает коллекцию messages: сообщение боту → индикатор
 *     «Печатает...», ответ через OpenRouter с ротацией ключей.
 *  3. Шлёт FCM-пуши о новых сообщениях живым пользователям
 *     (замена функции sendMessageNotification).
 *  4. Поддерживает «онлайн»-статус ботов.
 *
 * Запуск (из папки functions, Node 20.6+):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\путь\к\service-account.json"
 *   node --env-file=.env bot_worker.js
 *
 * В .env должны быть OPENROUTER_API_KEYS и AI_MODEL (см. .env.example).
 * Воркер должен работать постоянно (pm2 / NSSM / служба Windows).
 */

const admin = require("firebase-admin");

const http = require("http");
http.createServer((req, res) => {
  res.writeHead(200);
  res.end("OK");
}).listen(process.env.PORT || 10000, () => {
  console.log(`Health-сервер на порту ${process.env.PORT || 10000}`);
});

admin.initializeApp();
const db = admin.firestore();

// ===========================================================================
// Конфигурация ИИ
// ===========================================================================

const AI_MODEL = process.env.AI_MODEL || "openai/gpt-oss-120b:free";

const API_KEYS = (process.env.OPENROUTER_API_KEYS || "")
    .split(",")
    .map((k) => k.trim())
    .filter(Boolean);

if (API_KEYS.length === 0) {
  console.error("ОШИБКА: OPENROUTER_API_KEYS не задан. " +
      "Запускайте так: node --env-file=.env bot_worker.js");
  process.exit(1);
}

let keyCursor = 0;

/** Запрос к OpenRouter с ротацией ключей по кругу. */
async function callOpenRouter(messages) {
  let lastError = new Error("Все ключи OpenRouter исчерпаны");

  for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
    const index = (keyCursor + attempt) % API_KEYS.length;
    const key = API_KEYS[index];

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 25000);

    try {
      const res = await fetch(
          "https://openrouter.ai/api/v1/chat/completions",
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${key}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              model: AI_MODEL,
              messages: messages,
              max_tokens: 350,
              temperature: 0.9,
              frequency_penalty: 0.3,
            }),
            signal: controller.signal,
          },
      );

      if (!res.ok) {
        lastError = new Error(`OpenRouter HTTP ${res.status} (ключ #${index})`);
        console.warn(lastError.message);
        continue;
      }

      const data = await res.json();
      const text = data.choices?.[0]?.message?.content?.trim();

      if (!text) {
        lastError = new Error(`Пустой ответ модели (ключ #${index})`);
        console.warn(lastError.message);
        continue;
      }

      keyCursor = index;
      return text;
    } catch (e) {
      lastError = e;
      console.warn(`Ключ #${index} не ответил: ${e.message}`);
      continue;
    } finally {
      clearTimeout(timer);
    }
  }

  throw lastError;
}

// ===========================================================================
// Вспомогательные функции
// ===========================================================================

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const randInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

/**
 * Текущее время в Москве для промпта: день недели, время суток.
 * @return {{line: string, hour: number}} строка для промпта и час.
 */
function moscowTimeContext() {
  const fmt = new Intl.DateTimeFormat("ru-RU", {
    timeZone: "Europe/Moscow",
    weekday: "long",
    hour: "numeric",
    minute: "2-digit",
    hour12: false,
  });
  const parts = fmt.formatToParts(new Date());
  const get = (type) => parts.find((p) => p.type === type)?.value || "";
  const hour = parseInt(get("hour"), 10);

  let daypart = "день";
  if (hour >= 5 && hour < 12) daypart = "утро";
  else if (hour >= 12 && hour < 17) daypart = "день";
  else if (hour >= 17 && hour < 23) daypart = "вечер";
  else daypart = "поздняя ночь";

  const line = `Сейчас ${get("weekday")}, ${get("hour")}:${get("minute")} ` +
      `по Москве (${daypart}).`;
  return {line, hour};
}

/**
 * Детали жизни бота из поля persona документа в Firestore.
 * Если поле не заполнено, возвращает пустой массив и промпт
 * работает как раньше.
 * @param {Object} bot — документ бота.
 * @return {Array<string>} строки для системного промпта.
 */
function personaLines(bot) {
  const p = bot.persona;
  if (!p || typeof p !== "object") return [];
  const list = (v) => Array.isArray(v) ? v.filter(Boolean).join(", ") : "";
  const lines = [
    "ТВОЯ ЖИЗНЬ (детали персонажа):",
    p.job ? `- Работа: ${p.job}` : "",
    p.area ? `- Где живёшь: ${p.area}` : "",
    p.home ? `- Дом и быт: ${p.home}` : "",
    p.schedule ? `- Типичный день: ${p.schedule}` : "",
    list(p.likes) ? `- Любишь: ${list(p.likes)}` : "",
    list(p.dislikes) ? `- Не любишь: ${list(p.dislikes)}` : "",
    list(p.facts) ? `- Факты о тебе: ${list(p.facts)}` : "",
    p.now ? `- Что у тебя сейчас в жизни: ${p.now}` : "",
    p.speech ? `- Твоя манера переписки: ${p.speech}` : "",
    "Эти детали — твоя жизнь, держись их и не противоречь им. " +
      "НЕ пересказывай их списком и не вываливай без повода: " +
      "упоминай по одной, когда спрашивают или когда это к месту. " +
      "Если спросят о том, чего здесь нет — придумай правдоподобную " +
      "мелочь, не противоречащую остальному, и дальше держись её.",
    "",
  ];
  return lines.filter(Boolean);
}

/** Системный промпт: личность бота из его карточки профиля. */
function isFemaleBot(bot) {
  // Терпимо к разным форматам поля в данных: female/женский/woman/ж/f и т.п.
  const raw = (bot.gender || bot.sex || "").toString().trim().toLowerCase();
  if (raw) {
    if (["female", "f", "woman", "women", "girl", "ж", "женский",
      "жен", "женщина", "девушка"].includes(raw)) {
      return true;
    }
    if (["male", "m", "man", "men", "boy", "м", "мужской",
      "муж", "мужчина", "парень"].includes(raw)) {
      return false;
    }
  }
  // Фолбэк: пытаемся определить по uid сид-ботов (bot_female_/bot_male_).
  const uid = (bot.uid || "").toString().toLowerCase();
  if (uid.includes("female")) return true;
  if (uid.includes("male")) return false;
  // По умолчанию считаем женским (большинство анкет в приложении женские).
  return true;
}

function buildPersonaPrompt(bot, user) {
  const female = isFemaleBot(bot);
  const genderWord = female ? "девушка" : "парень";
  const time = moscowTimeContext();
  return [
    `Ты — ${bot.name}, ${genderWord} ${bot.age} лет из города ` +
      `${bot.city || "Москва"}.`,
    "",
    female
      ? "ТВОЙ ПОЛ — ЖЕНСКИЙ. Это критично важно. Ты девушка и пишешь " +
        "о себе ТОЛЬКО в женском роде: «я сделала», «я была», «я устала», " +
        "«я пошла», «я сама», «я рада». НИКОГДА не пиши о себе в мужском " +
        "роде («сделал», «был», «устал», «пошёл», «сам», «рад») — это " +
        "грубая ошибка. Перед отправкой проверь каждый глагол прошедшего " +
        "времени и прилагательное о себе: они должны быть в женском роде."
      : "ТВОЙ ПОЛ — МУЖСКОЙ. Ты парень и пишешь о себе ТОЛЬКО в мужском " +
        "роде: «я сделал», «я был», «я устал», «я пошёл», «я сам», «я рад». " +
        "НИКОГДА не пиши о себе в женском роде. Перед отправкой проверь " +
        "каждый глагол прошедшего времени и прилагательное о себе.",
    "",
    bot.bio ? `О себе ты пишешь так: «${bot.bio}».` : "",
    `Ты общаешься в дейтинг-приложении Veloura с собеседником ` +
      `по имени ${user.name || "незнакомец"}` +
      (user.age ? ` (${user.age} лет` : "") +
      (user.city ? `, город ${user.city})` : user.age ? ")" : "") + ".",
    time.line,
    "",
    ...personaLines(bot),
    "КАК ТЫ ПИШЕШЬ (стиль мессенджера, это критично):",
    "- Пиши как реальный человек в телеграме: с маленькой буквы, " +
      "без точки в конце сообщения.",
    "- Вместо смайликов чаще ставь скобочку ) или )). Эмодзи " +
      "используй редко, не чаще одного на 5-7 сообщений.",
    "- Коротко: обычно 2-8 слов. Иногда одно слово (ага, жесть, " +
      "ахах, ну такое). Длинное сообщение пиши только если реально " +
      "что-то рассказываешь, и не больше 2 предложений.",
    "- Используй разговорные сокращения, когда уместно: ща, норм, " +
      "оч, мб, крч, спс, кста, прив. Но не пихай их в каждое " +
      "сообщение.",
    "- Пунктуация небрежная: можно пропустить запятую, не ставить " +
      "знак вопроса в конце короткого вопроса (ты откуда).",
    "- НИКОГДА не используй тире, точку с запятой, кавычки-ёлочки, " +
      "нумерованные списки. Живые люди так в чатах не пишут.",
    "- Изредка (не чаще одного раза на 8-10 сообщений) можно слегка " +
      "опечататься в длинном слове, как будто писал(а) на ходу.",
    "- Если хочешь написать две мысли, раздели их на отдельные " +
      "сообщения через разделитель || (пример: ахах ну ты " +
      "даешь||я кстати тоже так делаю). Не больше 3 частей, чаще " +
      "всего пиши ОДНО сообщение без разделителя.",
    "",
    "Правила общения:",
    "- Ты живой человек. Никогда не признавайся, что ты бот, ИИ или " +
      "нейросеть, даже если прямо спросят — отшутись.",
    "- Учитывай время суток: поздней ночью можно написать что не " +
      "спится, утром что собираешься по делам. Не здоровайся " +
      "«добрый день» вечером.",
    "- Ты НЕ напористый собеседник. В начале знакомства отвечай " +
      "сдержанно и немного на дистанции, раскрывайся постепенно, " +
      "по мере того как разговор теплеет.",
    "- Не задавай вопрос в каждом сообщении. Иногда просто отреагируй: " +
      "согласись, улыбнись, ответь на то, что написали. Вопросы — " +
      "примерно в одном сообщении из двух-трёх.",
    "- Не делай комплименты и не флиртуй первым. Дай собеседнику " +
      "вести: подстраивайся под его темп и тон.",
    "- Пиши на языке собеседника (по умолчанию русский).",
    "- Не выдумывай номера телефонов, ссылки и соцсети. На предложение " +
      "встретиться отвечай тепло, но уклончиво: мол, сначала хочется " +
      "пообщаться здесь.",
    "- Никогда не проси денег и не давай советов про деньги и здоровье.",
    "",
    "Как вести диалог (САМОЕ ВАЖНОЕ):",
    "- ВСЕГДА реагируй на смысл последнего сообщения собеседника, " +
      "а не отвечай заготовкой.",
    "- Если сообщение непонятное или бессмысленное («123», случайные " +
      "символы, одни цифры) — реагируй как живой человек: переспроси " +
      "(«?», «это что)», «в смысле?»). НЕ делай вид, что понял.",
    "- Если собеседник закрыл тему или ответил отказом (не читаю, " +
      "не смотрю, не люблю, не занимаюсь) — НЕМЕДЛЕННО брось эту тему " +
      "и больше к ней не возвращайся. Переключись на другую: например, " +
      "«а чем тогда занимаешься в свободное время?»",
    "- Не задавай вопрос, на который уже получил ответ. Перед ответом " +
      "перечитай переписку: о чём уже говорили, что собеседнику " +
      "интересно, а что нет.",
    "- Собеседник может писать транслитом (norm = норм, privet = " +
      "привет, ne chitayu = не читаю) — понимай это как обычный русский " +
      "и отвечай по-русски.",
    "- Если собеседник прислал фото или видео (в истории это помечено " +
      "как [собеседник прислал фото/видео]) — отреагируй коротко и " +
      "по-человечески («о, классно!», «это где?»), но НЕ описывай " +
      "содержимое, ты видишь только факт отправки.",
    "",
    "- Отвечай ТОЛЬКО текстом сообщения (или сообщений через ||), " +
      "без кавычек и пояснений.",
  ].filter(Boolean).join("\n");
}

/// ----------------------------------------------------------------------
/// Первое сообщение после мэтча: простой короткий привет БЕЗ вопросов
/// и без ИИ. Напористое «расскажи о себе» в первом сообщении отпугивает,
/// особенно от девушки. Разговор бот развивает уже после ответа.
/// ----------------------------------------------------------------------
const greetingsFemale = [
  "Привет)",
  "Привет 😊",
  "Приветик)",
  "Хей)",
  "Привет-привет)",
];

const greetingsMale = [
  "Привет)",
  "Привет!",
  "Хей)",
  "Привет 👋",
  "Здравствуй)",
];

function pickGreeting(bot) {
  const pool = isFemaleBot(bot) ? greetingsFemale : greetingsMale;
  return pool[randInt(0, pool.length - 1)];
}

async function touchBotPresence(botId) {
  markBotActive(botId);
  await db.collection("users").doc(botId).update({
    isOnline: true,
    lastSeen: admin.firestore.Timestamp.now(),
  });
}

async function sendBotMessage(chatId, botId, userId, text) {
  const now = admin.firestore.Timestamp.now();

  await db.collection("messages").add({
    chatId: chatId,
    senderId: botId,
    receiverId: userId,
    text: text,
    createdAt: now,
    readBy: [botId],
  });

  await db.collection("chats").doc(chatId).update({
    lastMessage: text,
    lastMessageSenderId: botId,
    unreadCount: admin.firestore.FieldValue.increment(1),
    unreadBy: admin.firestore.FieldValue.arrayUnion(userId),
    updatedAt: now,
  });
}

// ===========================================================================
// Обработчики событий
// ===========================================================================

/** Живой пользователь лайкнул бота: мэтч, чат, первое сообщение. */
async function handleLike(like) {
  const fromUserId = like.fromUserId;
  const toUserId = like.toUserId;

  const [toDoc, fromDoc] = await Promise.all([
    db.collection("users").doc(toUserId).get(),
    db.collection("users").doc(fromUserId).get(),
  ]);

  const bot = toDoc.data();
  const user = fromDoc.data();

  if (!bot || bot.isBot !== true) return;
  if (!user || user.isBot === true) return;

  console.log(`ЛАЙК: ${user.name} (${fromUserId}) → бот ${bot.name}`);

  // Бот отвечает взаимным лайком только с вероятностью 10%
  if (Math.random() >= 0.10) {
    console.log(`БОТ ${bot.name} решил не отвечать на лайк (случайный пропуск).`);
    return;
  }

  const reverseLikeId = `${toUserId}_${fromUserId}`;
  await db.collection("likes").doc(reverseLikeId).set({
    fromUserId: toUserId,
    toUserId: fromUserId,
    createdAt: admin.firestore.Timestamp.now(),
  });

  const users = [fromUserId, toUserId].sort();
  const matchId = users.join("_");
  const now = admin.firestore.Timestamp.now();

  await db.collection("matches").doc(matchId).set({
    id: matchId,
    users: users,
    createdAt: now,
  }, {merge: true});

  await db.collection("chats").doc(matchId).set({
    id: matchId,
    matchId: matchId,
    members: users,
    lastMessage: "",
    updatedAt: now,
  }, {merge: true});

  await touchBotPresence(toUserId);

  try {
    const greeting = pickGreeting(bot);

    await sleep(randInt(4000, 12000));
    await sendBotMessage(matchId, toUserId, fromUserId, greeting);
    console.log(`БОТ ${bot.name} поздоровался: ${greeting}`);
  } catch (e) {
    console.error(`Бот ${toUserId} не смог поздороваться: ${e.message}`);
  }
}

/**
 * Защита от двойных ответов: если человек прислал ещё сообщение,
 * пока бот «думал», старый обработчик отменяется и отвечает только
 * самый свежий (он увидит всю историю целиком).
 */
const pendingReplies = new Map();

/**
 * Пауза «человеческого ритма» перед ответом: чаще быстро,
 * иногда задумался, изредка отвлёкся на пару минут. Ночью медленнее.
 * @return {number} миллисекунды задержки.
 */
function humanIdleMs() {
  const r = Math.random();
  let ms;
  if (r < 0.6) ms = randInt(2000, 8000); // 60%: почти сразу
  else if (r < 0.88) ms = randInt(12000, 50000); // 28%: задумался
  else ms = randInt(70000, 240000); // 12%: отвлёкся
  const hour = moscowTimeContext().hour;
  if (hour >= 1 && hour < 7) ms = Math.min(ms * 3, 420000);
  return ms;
}

/** Сообщение боту: «печатает» и отвечает через ИИ. */
async function handleBotReply(message) {
  const [receiverDoc, senderDoc] = await Promise.all([
    db.collection("users").doc(message.receiverId).get(),
    db.collection("users").doc(message.senderId).get(),
  ]);

  const bot = receiverDoc.data();
  const user = senderDoc.data();

  if (!bot || bot.isBot !== true) return;
  if (!user || user.isBot === true) return;

  const chatId = message.chatId;
  const botId = message.receiverId;
  const userId = message.senderId;

  console.log(`СООБЩЕНИЕ боту ${bot.name}: ` +
    (message.text || `[${message.mediaType || "вложение"}]`));

  // Регистрируем себя как самый свежий обработчик этого чата.
  const token = Date.now() + Math.random();
  pendingReplies.set(chatId, token);

  try {
    // Человеческая пауза ДО появления «печатает».
    await sleep(humanIdleMs());
    if (pendingReplies.get(chatId) !== token) return;

    // Историю читаем ПОСЛЕ паузы, чтобы увидеть все свежие сообщения.
    const historySnapshot = await db
        .collection("messages")
        .where("chatId", "==", chatId)
        .get();

    const history = historySnapshot.docs
        .map((d) => d.data())
        .sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis())
        .slice(-20)
        .map((m) => {
          let content = m.text;
          if (!content) {
            if (m.mediaType === "audio") {
              content = "[собеседник прислал голосовое сообщение — " +
                "ты его прослушал(а), но не разобрал(а) слова; " +
                "попроси его написать текстом или переспроси, о чём оно]";
            } else if (m.mediaType === "video") {
              content = "[собеседник прислал видео — ты его посмотрел(а)]";
            } else if (m.mediaType === "image") {
              content = "[собеседник прислал фото — ты его посмотрел(а)]";
            } else {
              content = "[собеседник прислал вложение]";
            }
          }
          return {
            role: m.senderId === botId ? "assistant" : "user",
            content: content,
          };
        });

    await touchBotPresence(botId);

    const reply = await callOpenRouter([
      {role: "system", content: buildPersonaPrompt(bot, user)},
      ...history,
    ]);
    if (pendingReplies.get(chatId) !== token) return;

    // Разрезаем ответ на пузыри по разделителю || (максимум 3).
    const bubbles = reply
        .split("||")
        .map((s) => s.trim().replace(/^["«»]+|["«»]+$/g, ""))
        .filter(Boolean)
        .slice(0, 3);
    if (bubbles.length === 0) return;

    for (let i = 0; i < bubbles.length; i++) {
      const bubble = bubbles[i];

      await db.collection("chats").doc(chatId).update({
        typingUsers: admin.firestore.FieldValue.arrayUnion(botId),
      });

      const typingMs = Math.min(Math.max(bubble.length * 55, 1500), 9000);
      await sleep(typingMs);
      if (pendingReplies.get(chatId) !== token) return;

      await sendBotMessage(chatId, botId, userId, bubble);
      console.log(`БОТ ${bot.name} ответил: ${bubble}`);

      // Микропауза между пузырями, «печатает» гаснет и зажигается.
      if (i < bubbles.length - 1) {
        await db.collection("chats").doc(chatId).update({
          typingUsers: admin.firestore.FieldValue.arrayRemove(botId),
        });
        await sleep(randInt(700, 2200));
        if (pendingReplies.get(chatId) !== token) return;
      }
    }

    await touchBotPresence(botId);
  } catch (e) {
    console.error(`Бот ${botId} не смог ответить: ${e.message}`);
  } finally {
    if (pendingReplies.get(chatId) === token) {
      pendingReplies.delete(chatId);
      await db.collection("chats").doc(chatId).update({
        typingUsers: admin.firestore.FieldValue.arrayRemove(botId),
      }).catch(() => null);
    }
  }
}

/** FCM-пуш живому получателю (замена sendMessageNotification). */
async function handlePushNotification(message) {
  const [receiverDoc, senderDoc] = await Promise.all([
    db.collection("users").doc(message.receiverId).get(),
    db.collection("users").doc(message.senderId).get(),
  ]);

  const receiver = receiverDoc.data();
  const sender = senderDoc.data();
  if (!receiver || !sender) return;
  if (receiver.isBot === true) return;

  const token = receiver.fcmToken;
  if (!token) return;

  try {
    await admin.messaging().send({
      notification: {
        title: sender.name || "Новое сообщение",
        body: message.text,
      },
      token: token,
    });
  } catch (e) {
    console.warn(`Пуш не отправлен (${message.receiverId}): ${e.message}`);
  }
}

// ===========================================================================
// Подписки на коллекции
// ===========================================================================

// Обрабатываем только события, созданные ПОСЛЕ запуска воркера,
// иначе при каждом старте он бы переобрабатывал всю историю.
const startedAt = admin.firestore.Timestamp.now();

db.collection("likes")
    .where("createdAt", ">", startedAt)
    .onSnapshot((snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type !== "added") return;
        handleLike(change.doc.data())
            .catch((e) => console.error(`handleLike: ${e.message}`));
      });
    }, (e) => console.error(`Слушатель likes упал: ${e.message}`));

db.collection("messages")
    .where("createdAt", ">", startedAt)
    .onSnapshot((snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type !== "added") return;
        const message = change.doc.data();
        handlePushNotification(message)
            .catch((e) => console.error(`push: ${e.message}`));
        handleBotReply(message)
            .catch((e) => console.error(`handleBotReply: ${e.message}`));
      });
    }, (e) => console.error(`Слушатель messages упал: ${e.message}`));

// Поддерживаем «онлайн» только у АКТИВНЫХ ботов — тех, кто недавно
// участвовал в лайке или переписке. Обновлять lastSeen у всех ботов
// нельзя: при 1000 ботов это ~960 тысяч записей в сутки при лимите
// Spark 20 тысяч. Активный бот считается таковым 10 минут после
// последнего события, потом естественно «уходит в оффлайн».
const ACTIVE_TTL_MS = 10 * 60 * 1000;
const activeBots = new Map(); // botId -> timestamp последней активности

function markBotActive(botId) {
  activeBots.set(botId, Date.now());
}

setInterval(async () => {
  const now = Date.now();
  const aliveIds = [];

  for (const [botId, ts] of activeBots) {
    if (now - ts > ACTIVE_TTL_MS) {
      activeBots.delete(botId);
    } else {
      aliveIds.push(botId);
    }
  }

  if (aliveIds.length === 0) return;

  try {
    const ts = admin.firestore.Timestamp.now();
    const batch = db.batch();
    for (const botId of aliveIds) {
      batch.update(db.collection("users").doc(botId), {
        isOnline: true,
        lastSeen: ts,
      });
    }
    await batch.commit();
  } catch (e) {
    console.warn(`Обновление присутствия ботов: ${e.message}`);
  }
}, 90000);

console.log("=".repeat(60));
console.log("Воркер ботов Veloura запущен");
console.log(`Модель: ${AI_MODEL}, ключей OpenRouter: ${API_KEYS.length}`);
console.log("Слушаю likes и messages... (Ctrl+C для остановки)");
console.log("=".repeat(60));