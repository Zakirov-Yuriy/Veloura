/**
 * Генерация «карточек жизни» (persona) для всех ИИ-ботов Veloura.
 *
 * Скрипт проходит по всем документам users с isBot: true и каждому
 * боту, у которого ещё нет поля persona, генерирует его через
 * OpenRouter на основе имени, возраста, города и био.
 *
 * Запуск (из папки functions, тот же .env, что у bot_worker.js):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\путь\к\service-account.json"
 *   node --env-file=.env add_personas.js
 *
 * Полезные варианты:
 *   node --env-file=.env add_personas.js --limit=10   только 10 ботов (тест)
 *   node --env-file=.env add_personas.js --force      перегенерировать всем
 *
 * Скрипт можно безопасно запускать повторно: боты, у которых persona
 * уже есть, пропускаются (без --force). Новых ботов после очередного
 * сидинга достаточно «доперсонить» повторным запуском.
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const AI_MODEL = process.env.AI_MODEL || "openai/gpt-oss-120b:free";

const API_KEYS = (process.env.OPENROUTER_API_KEYS || "")
    .split(",")
    .map((k) => k.trim())
    .filter(Boolean);

if (API_KEYS.length === 0) {
  console.error("ОШИБКА: OPENROUTER_API_KEYS не задан. " +
      "Запускайте так: node --env-file=.env add_personas.js");
  process.exit(1);
}

const FORCE = process.argv.includes("--force");
const limitArg = process.argv.find((a) => a.startsWith("--limit="));
const LIMIT = limitArg ? parseInt(limitArg.split("=")[1], 10) : Infinity;
const CONCURRENCY = 4;

let keyCursor = 0;

/** Запрос к OpenRouter с ротацией ключей по кругу. */
async function callOpenRouter(messages) {
  let lastError = new Error("Все ключи OpenRouter исчерпаны");

  for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
    const index = (keyCursor + attempt) % API_KEYS.length;
    const key = API_KEYS[index];

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30000);

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
              max_tokens: 700,
              temperature: 1.0,
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

/** Промпт генерации карточки. Модель обязана вернуть чистый JSON. */
function buildGenPrompt(bot) {
  const genderWord = bot.gender === "female" ? "девушка" : "парень";
  return [
    "Придумай реалистичную «карточку жизни» персонажа для " +
      "дейтинг-приложения. Персонаж:",
    `${bot.name}, ${genderWord}, ${bot.age} лет, город ` +
      `${bot.city || "Москва"}.`,
    bot.bio ? `Био из профиля: «${bot.bio}». Карточка не должна ему ` +
      "противоречить." : "",
    "",
    "Требования:",
    "- Обычный живой человек, без гламура и пафоса. Реальная работа " +
      "с конкретикой (место, должность), не «фрилансер» у всех подряд.",
    "- Район/часть города должны существовать в этом городе.",
    "- В likes/dislikes — бытовые, конкретные вещи, а не абстракции.",
    "- В facts — 2-3 цепляющих, но правдоподобных факта (история, " +
      "питомец, шрам, привычка).",
    "- now — что происходит в жизни именно в этом месяце (ремонт, " +
      "учёба, отпуск копит, и т.п.).",
    "- speech — особенности переписки: любимые словечки, частота " +
      "смайлов, длина сообщений.",
    "",
    "Ответь ТОЛЬКО валидным JSON без пояснений и без markdown, " +
      "строго такой структуры:",
    "{",
    "  \"job\": \"строка\",",
    "  \"area\": \"строка\",",
    "  \"home\": \"строка\",",
    "  \"schedule\": \"строка\",",
    "  \"likes\": [\"строка\", \"строка\", \"строка\"],",
    "  \"dislikes\": [\"строка\", \"строка\"],",
    "  \"facts\": [\"строка\", \"строка\"],",
    "  \"now\": \"строка\",",
    "  \"speech\": \"строка\"",
    "}",
  ].filter(Boolean).join("\n");
}

/** Достаёт и валидирует JSON из ответа модели. */
function parsePersona(text) {
  const cleaned = text
      .replace(/```json/gi, "")
      .replace(/```/g, "")
      .trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start === -1 || end === -1) throw new Error("В ответе нет JSON");

  const obj = JSON.parse(cleaned.slice(start, end + 1));

  const str = (v) => typeof v === "string" && v.trim() ? v.trim() : null;
  const arr = (v) => Array.isArray(v) ?
      v.map(str).filter(Boolean).slice(0, 5) : [];

  const persona = {
    job: str(obj.job),
    area: str(obj.area),
    home: str(obj.home),
    schedule: str(obj.schedule),
    likes: arr(obj.likes),
    dislikes: arr(obj.dislikes),
    facts: arr(obj.facts),
    now: str(obj.now),
    speech: str(obj.speech),
  };

  if (!persona.job || !persona.area || persona.likes.length === 0) {
    throw new Error("Карточка неполная: " + JSON.stringify(obj));
  }

  // Убираем null-поля, чтобы не засорять Firestore.
  Object.keys(persona).forEach((k) => {
    if (persona[k] === null) delete persona[k];
  });
  return persona;
}

/** Генерирует и сохраняет карточку одному боту (с одним ретраем). */
async function processBot(doc) {
  const bot = doc.data();
  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      const raw = await callOpenRouter([
        {role: "user", content: buildGenPrompt(bot)},
      ]);
      const persona = parsePersona(raw);
      await doc.ref.update({persona: persona});
      console.log(`✓ ${bot.name} (${doc.id}): ${persona.job}`);
      return true;
    } catch (e) {
      console.warn(`✗ ${bot.name} (${doc.id}), попытка ${attempt}: ` +
          e.message);
    }
  }
  return false;
}

async function main() {
  console.log(`Модель: ${AI_MODEL}, ключей: ${API_KEYS.length}, ` +
      `force: ${FORCE}, limit: ${LIMIT === Infinity ? "нет" : LIMIT}`);

  const snapshot = await db.collection("users")
      .where("isBot", "==", true)
      .get();

  let docs = snapshot.docs;
  if (!FORCE) {
    docs = docs.filter((d) => !d.data().persona);
  }
  docs = docs.slice(0, LIMIT);

  console.log(`Ботов всего: ${snapshot.size}, к обработке: ${docs.length}`);
  if (docs.length === 0) {
    console.log("Делать нечего: у всех уже есть persona " +
        "(используйте --force для перегенерации).");
    process.exit(0);
  }

  let ok = 0;
  let fail = 0;

  for (let i = 0; i < docs.length; i += CONCURRENCY) {
    const chunk = docs.slice(i, i + CONCURRENCY);
    const results = await Promise.all(chunk.map(processBot));
    ok += results.filter(Boolean).length;
    fail += results.filter((r) => !r).length;
    console.log(`Прогресс: ${Math.min(i + CONCURRENCY, docs.length)}` +
        `/${docs.length}`);
  }

  console.log(`Готово. Успешно: ${ok}, с ошибками: ${fail}.`);
  if (fail > 0) {
    console.log("Запустите скрипт ещё раз: он дообработает только тех, " +
        "у кого карточки не появились.");
  }
  process.exit(0);
}

main().catch((e) => {
  console.error("Фатальная ошибка:", e);
  process.exit(1);
});
