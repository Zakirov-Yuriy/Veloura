const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

// ===========================================================================
// Конфигурация ИИ (functions/.env, см. .env.example)
// ===========================================================================

const AI_MODEL = process.env.AI_MODEL || "openai/gpt-oss-120b:free";

/** Ключи OpenRouter через запятую: OPENROUTER_API_KEYS=sk-or-1,sk-or-2 */
const API_KEYS = (process.env.OPENROUTER_API_KEYS || "")
    .split(",")
    .map((k) => k.trim())
    .filter(Boolean);

/**
 * Курсор последнего рабочего ключа. Живёт в памяти инстанса функции:
 * после удачного запроса следующий начнётся с того же ключа, а не с
 * первого, поэтому «мёртвый» ключ не будет дёргаться каждый раз.
 */
let keyCursor = 0;

/**
 * Запрос к OpenRouter с ротацией ключей.
 * Если ключ не отвечает (таймаут, 401/402/403/429/5xx, пустой ответ),
 * пробуем следующий по кругу, пока ключи не закончатся.
 * @param {Array<Object>} messages — массив сообщений chat-формата.
 * @return {Promise<string>} текст ответа модели.
 */
async function callOpenRouter(messages) {
  if (API_KEYS.length === 0) {
    throw new Error("OPENROUTER_API_KEYS не задан в functions/.env");
  }

  let lastError = new Error("Все ключи OpenRouter исчерпаны");

  for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
    const index = (keyCursor + attempt) % API_KEYS.length;
    const key = API_KEYS[index];

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 25_000);

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
            }),
            signal: controller.signal,
          },
      );

      if (!res.ok) {
        lastError = new Error(`OpenRouter HTTP ${res.status} (ключ #${index})`);
        logger.warn(lastError.message);
        continue; // следующий ключ
      }

      const data = await res.json();
      const text = data.choices?.[0]?.message?.content?.trim();

      if (!text) {
        lastError = new Error(`Пустой ответ модели (ключ #${index})`);
        logger.warn(lastError.message);
        continue;
      }

      keyCursor = index; // запоминаем рабочий ключ
      return text;
    } catch (e) {
      lastError = e;
      logger.warn(`Ключ #${index} не ответил: ${e.message}`);
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

/** Пауза. */
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Случайное целое в диапазоне [min, max]. */
const randInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

/** Системный промпт: личность бота из его карточки профиля. */
function buildPersonaPrompt(bot, user) {
  const genderWord = bot.gender === "female" ? "девушка" : "парень";
  return [
    `Ты — ${bot.name}, ${genderWord} ${bot.age} лет из города ` +
      `${bot.city || "Москва"}.`,
    bot.bio ? `О себе ты пишешь так: «${bot.bio}».` : "",
    `Ты общаешься в дейтинг-приложении Veloura с собеседником ` +
      `по имени ${user.name || "незнакомец"}` +
      (user.age ? ` (${user.age} лет` : "") +
      (user.city ? `, город ${user.city})` : user.age ? ")" : "") + ".",
    "",
    "Правила общения:",
    "- Ты живой человек. Никогда не признавайся, что ты бот, ИИ или " +
      "нейросеть, даже если прямо спросят — отшутись.",
    "- Пиши как в мессенджере: коротко, 1–2 предложения, иногда " +
      "одно слово или вопрос.",
    "- Ты НЕ напористый собеседник. В начале знакомства отвечай " +
      "сдержанно и немного на дистанции, раскрывайся постепенно, " +
      "по мере того как разговор теплеет.",
    "- Не задавай вопрос в каждом сообщении. Иногда просто отреагируй: " +
      "согласись, улыбнись, ответь на то, что написали. Вопросы — " +
      "примерно в одном сообщении из двух-трёх.",
    "- Не делай комплименты и не флиртуй первым. Дай собеседнику " +
      "вести: подстраивайся под его темп и тон.",
    "- Используй эмодзи умеренно и только к месту 😊",
    "- Пиши на языке собеседника (по умолчанию русский), допускай " +
      "лёгкий разговорный стиль, без канцелярита.",
    "- Не выдумывай номера телефонов, ссылки и соцсети. На предложение " +
      "встретиться отвечай тепло, но уклончиво: мол, сначала хочется " +
      "пообщаться здесь.",
    "- Никогда не проси денег и не давай советов про деньги и здоровье.",
    "- Отвечай ТОЛЬКО текстом сообщения, без кавычек и пояснений.",
  ].filter(Boolean).join("\n");
}

/**
 * Первое сообщение после мэтча: простой короткий привет БЕЗ вопросов
 * и без ИИ. Напористое «расскажи о себе» в первом сообщении отпугивает.
 */
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

/** Случайное приветствие в зависимости от пола бота. */
function pickGreeting(bot) {
  const pool = bot.gender === "female" ? greetingsFemale : greetingsMale;
  return pool[randInt(0, pool.length - 1)];
}

/** Обновляет «присутствие» бота, чтобы он выглядел живым. */
async function touchBotPresence(botId) {
  await db.collection("users").doc(botId).update({
    isOnline: true,
    lastSeen: admin.firestore.Timestamp.now(),
  });
}

/** Записывает сообщение от бота по той же схеме, что и приложение. */
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
// Пуш-уведомление о новом сообщении (переписано на API v2)
// ===========================================================================

exports.sendMessageNotification = onDocumentCreated(
    "messages/{messageId}",
    async (event) => {
      const message = event.data?.data();
      if (!message) return;

      const [receiverDoc, senderDoc] = await Promise.all([
        db.collection("users").doc(message.receiverId).get(),
        db.collection("users").doc(message.senderId).get(),
      ]);

      const receiver = receiverDoc.data();
      const sender = senderDoc.data();
      if (!receiver || !sender) return;

      // Ботам пуши не нужны.
      if (receiver.isBot === true) return;

      const token = receiver.fcmToken;
      if (!token) return;

      await admin.messaging().send({
        notification: {
          title: sender.name || "Новое сообщение",
          body: message.text,
        },
        token: token,
      });
    },
);

// ===========================================================================
// БОТЫ. Часть 1: взаимный лайк, мэтч, чат и первое сообщение
// ===========================================================================

exports.botAutoMatch = onDocumentCreated(
    "likes/{likeId}",
    async (event) => {
      const like = event.data?.data();
      if (!like) return;

      const fromUserId = like.fromUserId;
      const toUserId = like.toUserId;

      const [toDoc, fromDoc] = await Promise.all([
        db.collection("users").doc(toUserId).get(),
        db.collection("users").doc(fromUserId).get(),
      ]);

      const bot = toDoc.data();
      const user = fromDoc.data();

      // Реагируем только когда ЖИВОЙ пользователь лайкнул БОТА.
      // Лайк, созданный этой же функцией от имени бота, сюда не пройдёт.
      if (!bot || bot.isBot !== true) return;
      if (!user || user.isBot === true) return;

      // Взаимный лайк от бота (идемпотентно: один лайк на пару).
      const reverseLikeId = `${toUserId}_${fromUserId}`;
      await db.collection("likes").doc(reverseLikeId).set({
        fromUserId: toUserId,
        toUserId: fromUserId,
        createdAt: admin.firestore.Timestamp.now(),
      });

      // Мэтч и чат — та же схема ID, что в приложении: sorted uids + "_".
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

      // Бот пишет первым: простой короткий привет, без вопросов.
      try {
        const greeting = pickGreeting(bot);

        // Человекоподобная пауза перед первым сообщением.
        await sleep(randInt(4_000, 12_000));
        await sendBotMessage(matchId, toUserId, fromUserId, greeting);
      } catch (e) {
        // Если что-то пошло не так, мэтч всё равно создан.
        logger.error(`Бот ${toUserId} не смог поздороваться: ${e.message}`);
      }
    },
);

// ===========================================================================
// БОТЫ. Часть 2: ответ на сообщение пользователя
// ===========================================================================

exports.botReply = onDocumentCreated(
    {document: "messages/{messageId}", timeoutSeconds: 120},
    async (event) => {
      const message = event.data?.data();
      if (!message) return;

      const [receiverDoc, senderDoc] = await Promise.all([
        db.collection("users").doc(message.receiverId).get(),
        db.collection("users").doc(message.senderId).get(),
      ]);

      const bot = receiverDoc.data();
      const user = senderDoc.data();

      // Отвечаем только на сообщения ЖИВОГО пользователя БОТУ.
      // Сообщение самого бота сюда не пройдёт — защита от зацикливания.
      if (!bot || bot.isBot !== true) return;
      if (!user || user.isBot === true) return;

      const chatId = message.chatId;
      const botId = message.receiverId;
      const userId = message.senderId;

      // История переписки для контекста (последние 20 сообщений).
      const historySnapshot = await db
          .collection("messages")
          .where("chatId", "==", chatId)
          .get();

      const history = historySnapshot.docs
          .map((d) => d.data())
          .sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis())
          .slice(-20)
          .map((m) => ({
            role: m.senderId === botId ? "assistant" : "user",
            content: m.text,
          }));

      try {
        await touchBotPresence(botId);

        // Пауза «прочитал сообщение» перед началом печати.
        await sleep(randInt(2_000, 6_000));

        // Включаем индикатор «Печатает...» — UI уже умеет его показывать.
        await db.collection("chats").doc(chatId).update({
          typingUsers: admin.firestore.FieldValue.arrayUnion(botId),
        });

        const reply = await callOpenRouter([
          {role: "system", content: buildPersonaPrompt(bot, user)},
          ...history,
        ]);

        // «Печатаем» со скоростью человека: ~55 мс на символ, 2–9 секунд.
        const typingMs = Math.min(Math.max(reply.length * 55, 2_000), 9_000);
        await sleep(typingMs);

        await sendBotMessage(chatId, botId, userId, reply);
        await touchBotPresence(botId);
      } catch (e) {
        logger.error(`Бот ${botId} не смог ответить: ${e.message}`);
      } finally {
        // Гасим «Печатает...» в любом случае.
        await db.collection("chats").doc(chatId).update({
          typingUsers: admin.firestore.FieldValue.arrayRemove(botId),
        }).catch(() => null);
      }
    },
);