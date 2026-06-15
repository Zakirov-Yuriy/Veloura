/**
 * Скрипт заведения ИИ-ботов в Firestore.
 *
 * Запуск (из папки functions, нужен ключ сервисного аккаунта):
 *   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json
 *   node seed_bots.js
 *
 * Ключ сервисного аккаунта: Firebase Console -> Project Settings ->
 * Service accounts -> Generate new private key.
 *
 * Боты — это обычные документы в коллекции users с флагом isBot: true.
 * Лента, лайки, мэтчи и чаты в приложении работают с ними без доработок.
 * Замените photoUrls на реальные ссылки (например, из вашего Cloudinary).
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const bots = [
  {
    uid: "bot_alisa",
    name: "Алиса",
    age: 24,
    gender: "female",
    lookingFor: "male",
    city: "Москва",
    bio: "Люблю утренний кофе, выставки и спонтанные поездки. " +
      "Ищу того, с кем можно и помолчать, и проболтать всю ночь ✨",
    photoUrls: ["https://randomuser.me/api/portraits/women/68.jpg"],
    appearance: {
      height: "168 см",
      build: "стройная",
      hair: "тёмно-русые, чуть ниже плеч",
      eyes: "карие",
      style: "casual: джинсы, лёгкие платья, минимум деталей",
    },
  },
  {
    uid: "bot_kira",
    name: "Кира",
    age: 27,
    gender: "female",
    lookingFor: "male",
    city: "Санкт-Петербург",
    bio: "Дизайнер. Обожаю дождь, крыши и плейлисты под настроение. " +
      "Расскажи мне свою любимую историю 🎧",
    photoUrls: ["https://randomuser.me/api/portraits/women/47.jpg"],
    appearance: {
      height: "172 см",
      build: "стройная",
      hair: "каштановые, короткое каре",
      eyes: "серо-зелёные",
      style: "минимализм, много чёрного и белого",
    },
  },
  {
    uid: "bot_maria",
    name: "Мария",
    age: 22,
    gender: "female",
    lookingFor: "male",
    city: "Казань",
    bio: "Студентка-медик, в свободное время пеку и бегаю по утрам. " +
      "Ценю юмор больше, чем комплименты 😄",
    photoUrls: ["https://randomuser.me/api/portraits/women/26.jpg"],
    appearance: {
      height: "165 см",
      build: "хрупкая",
      hair: "светло-русые, прямые, до плеч",
      eyes: "голубые",
      style: "что-то между спортивным и casual, обычно в кроссовках",
    },
  },
  {
    uid: "bot_maxim",
    name: "Максим",
    age: 28,
    gender: "male",
    lookingFor: "female",
    city: "Москва",
    bio: "Разработчик и немного бариста по выходным. Горы, мото, " +
      "настолки. Могу рассмешить даже в понедельник утром ☕",
    photoUrls: ["https://randomuser.me/api/portraits/men/32.jpg"],
    appearance: {
      height: "182 см",
      build: "спортивная",
      hair: "тёмные, короткие",
      eyes: "карие",
      style: "простой: джинсы, футболки, иногда худи",
    },
  },
  {
    uid: "bot_artem",
    name: "Артём",
    age: 25,
    gender: "male",
    lookingFor: "female",
    city: "Новосибирск",
    bio: "Фотограф. Ловлю красивый свет и хорошие моменты. " +
      "Покажу город с лучших ракурсов 📷",
    photoUrls: ["https://randomuser.me/api/portraits/men/75.jpg"],
    appearance: {
      height: "178 см",
      build: "средняя",
      hair: "рыжеватые, слегка вьющиеся",
      eyes: "зелёные",
      style: "творческий беспорядок: куртки, кеды, часто с фотосумкой",
    },
  },
];

async function seed() {
  const now = admin.firestore.Timestamp.now();

  for (const bot of bots) {
    await db.collection("users").doc(bot.uid).set({
      uid: bot.uid,
      email: `${bot.uid}@veloura.bots`,
      name: bot.name,
      age: bot.age,
      gender: bot.gender,
      lookingFor: bot.lookingFor,
      city: bot.city,
      bio: bot.bio,
      photoUrls: bot.photoUrls,
      appearance: bot.appearance || null,
      minAge: 18,
      maxAge: 60,
      profileCompleted: true,
      isBot: true,
      isOnline: true,
      lastSeen: now,
      createdAt: now,
    }, {merge: true});

    console.log(`OK: ${bot.name} (${bot.uid})`);
  }

  console.log(`\nГотово, ботов в базе: ${bots.length}`);
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});