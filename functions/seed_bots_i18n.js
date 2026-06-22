/**
 * Добавляет переводы (поле i18n) в документы ботов в коллекции users.
 *
 * Запуск (из папки functions, нужен ключ сервисного аккаунта):
 *   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json
 *   node seed_bots_i18n.js
 *
 * Что делает:
 *  - для известных сид-ботов (по uid) проставляет i18n.en и i18n.ru
 *    с осмысленным переводом имени, города и био;
 *  - для остальных ботов (isBot==true), которых нет в карте переводов,
 *    НЕ трогает данные, но выводит их uid списком — чтобы вы знали,
 *    каким ботам перевод ещё нужно добавить.
 *
 * Схема после миграции:
 *   users/{uid} = {
 *     name: "Алиса", city: "Москва", bio: "...",   // как было (дефолт)
 *     i18n: {
 *       ru: { name: "Алиса", city: "Москва", bio: "..." },
 *       en: { name: "Alisa", city: "Moscow", bio: "..." }
 *     }
 *   }
 *
 * Приложение читает i18n[язык] с фолбэком на верхнеуровневое поле,
 * поэтому живых пользователей (без i18n) миграция не касается.
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Переводы известных сид-ботов. Имена даны в естественной английской форме,
// города — официальными англоязычными названиями, био — человеческим переводом.
const translations = {
  bot_alisa: {
    ru: {
      name: "Алиса",
      city: "Москва",
      bio: "Люблю утренний кофе, выставки и спонтанные поездки. " +
        "Ищу того, с кем можно и помолчать, и проболтать всю ночь ✨",
    },
    en: {
      name: "Alisa",
      city: "Moscow",
      bio: "I love morning coffee, art shows and spontaneous trips. " +
        "Looking for someone I can stay quiet with or talk to all night ✨",
    },
  },
  bot_kira: {
    ru: {
      name: "Кира",
      city: "Санкт-Петербург",
      bio: "Дизайнер. Обожаю дождь, крыши и плейлисты под настроение. " +
        "Расскажи мне свою любимую историю 🎧",
    },
    en: {
      name: "Kira",
      city: "Saint Petersburg",
      bio: "Designer. I adore rain, rooftops and mood playlists. " +
        "Tell me your favorite story 🎧",
    },
  },
  bot_maria: {
    ru: {
      name: "Мария",
      city: "Казань",
      bio: "Студентка-медик, в свободное время пеку и бегаю по утрам. " +
        "Ценю юмор больше, чем комплименты 😄",
    },
    en: {
      name: "Maria",
      city: "Kazan",
      bio: "Med student. In my free time I bake and go for morning runs. " +
        "I value humor more than compliments 😄",
    },
  },
  bot_maxim: {
    ru: {
      name: "Максим",
      city: "Москва",
      bio: "Разработчик и немного бариста по выходным. Горы, мото, " +
        "настолки. Могу рассмешить даже в понедельник утром ☕",
    },
    en: {
      name: "Maxim",
      city: "Moscow",
      bio: "Developer, and a bit of a barista on weekends. Mountains, " +
        "motorbikes, board games. I can make you laugh even on a Monday ☕",
    },
  },
  bot_artem: {
    ru: {
      name: "Артём",
      city: "Новосибирск",
      bio: "Фотограф. Ловлю красивый свет и хорошие моменты. " +
        "Покажу город с лучших ракурсов 📷",
    },
    en: {
      name: "Artem",
      city: "Novosibirsk",
      bio: "Photographer. I chase good light and good moments. " +
        "I'll show you the city from its best angles 📷",
    },
  },
};

async function migrate() {
  const snapshot = await db
      .collection("users")
      .where("isBot", "==", true)
      .get();

  let updated = 0;
  const missing = [];

  for (const doc of snapshot.docs) {
    const uid = doc.id;
    const t = translations[uid];

    if (!t) {
      missing.push(uid);
      continue;
    }

    await doc.ref.set({i18n: t}, {merge: true});
    updated++;
    console.log(`OK: ${uid} -> i18n (${Object.keys(t).join(", ")})`);
  }

  console.log(`\nОбновлено ботов: ${updated}`);
  if (missing.length) {
    console.log(
        `\nБез перевода (добавьте их в translations и перезапустите):\n` +
        missing.map((u) => `  - ${u}`).join("\n"));
  }
  process.exit(0);
}

migrate().catch((e) => {
  console.error(e);
  process.exit(1);
});
