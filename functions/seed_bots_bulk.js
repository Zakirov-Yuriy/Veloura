/**
 * Массовая генерация ИИ-ботов для Veloura.
 *
 * Запуск (из папки functions):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\путь\к\service-account.json"
 *   node seed_bots_bulk.js 1000
 *
 * Аргумент — сколько ботов создать (по умолчанию 100).
 * Пол распределяется 50/50. Имена, возраст, города и био комбинируются
 * случайно из пулов ниже, поэтому профили получаются разнообразными.
 *
 * ВАЖНО ПРО ФОТО: используются портреты randomuser.me, их всего ~100
 * на каждый пол, поэтому при большом количестве ботов лица будут
 * повторяться. Для продакшена подготовьте собственный пак фотографий
 * (например, сгенерированные нейросетью уникальные лица), залейте в
 * Cloudinary и подставьте ссылки в функцию photoFor().
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const COUNT = Math.max(1, parseInt(process.argv[2] || "100", 10));

// ---------------------------------------------------------------------------
// Пулы данных
// ---------------------------------------------------------------------------

const femaleNames = [
  "Алиса", "Кира", "Мария", "Анна", "Дарья", "Полина", "Ксения",
  "Екатерина", "Виктория", "София", "Алина", "Вероника", "Юлия",
  "Елена", "Ольга", "Наталья", "Татьяна", "Ирина", "Светлана",
  "Маргарита", "Валерия", "Диана", "Кристина", "Арина", "Милана",
  "Ева", "Варвара", "Александра", "Лилия", "Карина",
];

const maleNames = [
  "Максим", "Артём", "Иван", "Дмитрий", "Александр", "Михаил",
  "Никита", "Андрей", "Сергей", "Кирилл", "Егор", "Илья", "Алексей",
  "Владимир", "Денис", "Павел", "Роман", "Тимур", "Глеб", "Антон",
  "Виктор", "Олег", "Степан", "Марк", "Лев", "Игорь", "Владислав",
  "Константин", "Григорий", "Арсений",
];

const cities = [
  "Москва", "Санкт-Петербург", "Казань", "Новосибирск", "Екатеринбург",
  "Нижний Новгород", "Краснодар", "Самара", "Ростов-на-Дону", "Уфа",
  "Воронеж", "Пермь", "Волгоград", "Тюмень", "Сочи", "Калининград",
];

const hobbies = [
  "путешествия", "кофейни", "йога", "бег по утрам", "фотография",
  "кино", "книги", "готовка", "горные лыжи", "настолки", "плавание",
  "выставки", "музыка", "велопрогулки", "психология", "танцы",
  "сериалы", "походы", "теннис", "рисование", "вино и сыр",
];

const bioOpeners = [
  "Люблю", "Обожаю", "Не представляю жизнь без", "В свободное время —",
  "Моя слабость —", "Живу в ритме:",
];

const bioClosers = [
  "Ценю юмор и лёгкость в общении.",
  "Ищу человека, с которым интересно молчать и разговаривать.",
  "Верю, что лучшие истории начинаются со случайного «привет».",
  "Не люблю переписки ни о чём, люблю живой интерес.",
  "За спонтанные планы и тёплые вечера.",
  "Сначала кофе, потом всё остальное ☕",
  "Из тех, кто смеётся со своих же шуток.",
  "Романтик с практичным взглядом на жизнь.",
];

// ---------------------------------------------------------------------------

const randInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

const pick = (arr) => arr[randInt(0, arr.length - 1)];

function makeBio() {
  const h1 = pick(hobbies);
  let h2 = pick(hobbies);
  while (h2 === h1) h2 = pick(hobbies);
  return `${pick(bioOpeners)} ${h1} и ${h2}. ${pick(bioClosers)}`;
}

/** Портрет randomuser.me. Индексы 0–99, поэтому лица повторяются. */
function photoFor(gender, index) {
  const folder = gender === "female" ? "women" : "men";
  return `https://randomuser.me/api/portraits/${folder}/${index % 100}.jpg`;
}

function makeBot(index) {
  const gender = index % 2 === 0 ? "female" : "male";
  const name = gender === "female" ? pick(femaleNames) : pick(maleNames);

  return {
    uid: `bot_${gender}_${String(index).padStart(5, "0")}`,
    name: name,
    age: randInt(19, 38),
    gender: gender,
    lookingFor: gender === "female" ? "male" : "female",
    city: pick(cities),
    bio: makeBio(),
    photoUrls: [photoFor(gender, index)],
  };
}

async function seed() {
  console.log(`Создаю ботов: ${COUNT}...`);
  const now = admin.firestore.Timestamp.now();

  let written = 0;

  // Firestore позволяет максимум 500 операций в одном batch.
  for (let start = 0; start < COUNT; start += 400) {
    const batch = db.batch();
    const end = Math.min(start + 400, COUNT);

    for (let i = start; i < end; i++) {
      const bot = makeBot(i);
      const ref = db.collection("users").doc(bot.uid);

      batch.set(ref, {
        uid: bot.uid,
        email: `${bot.uid}@veloura.bots`,
        name: bot.name,
        age: bot.age,
        gender: bot.gender,
        lookingFor: bot.lookingFor,
        city: bot.city,
        bio: bot.bio,
        photoUrls: bot.photoUrls,
        minAge: 18,
        maxAge: 60,
        profileCompleted: true,
        isBot: true,
        isOnline: false,
        lastSeen: now,
        createdAt: now,
      }, {merge: true});
    }

    await batch.commit();
    written = end;
    console.log(`...записано ${written}/${COUNT}`);
  }

  console.log(`\nГотово, ботов создано: ${written}`);
  console.log("Учтите: каждая запись — это 1 операция записи Firestore, " +
      "на тарифе Spark лимит 20 000 записей в сутки.");
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});