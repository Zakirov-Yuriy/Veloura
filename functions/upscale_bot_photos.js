/**
 * Улучшение фотографий ботов через AI-апскейл Cloudinary.
 *
 * Что делает:
 *   1. Находит всех ботов (isBot == true), у которых фото ведёт на
 *      randomuser.me (мыльные 128x128).
 *   2. Каждую такую картинку заливает в ваш Cloudinary (Cloudinary сам
 *      скачивает её по URL — локально ничего качать не нужно).
 *   3. Прописывает ботам новую ссылку с трансформацией e_upscale:
 *      AI-апскейл x4 (128 -> 512) + автокачество. Апскейл выполняется
 *      на серверах Cloudinary при первом обращении и кэшируется.
 *
 * Запуск (из папки functions):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\путь\к\service-account.json"
 *   node upscale_bot_photos.js
 *
 * Если тариф Cloudinary не поддерживает e_upscale (картинки по новым
 * ссылкам не открываются) — поставьте USE_AI_UPSCALE = false и
 * запустите скрипт ещё раз: будет применено простое увеличение с
 * улучшением резкости (хуже AI, но лучше, чем ничего).
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const CLOUD_NAME = "dccyuxqzj";
const UPLOAD_PRESET = "veloura_profiles";

/** AI-апскейл (e_upscale). При false — обычный ресайз с шарпеном. */
const USE_AI_UPSCALE = true;

/** Трансформация, вшиваемая в URL доставки. */
const TRANSFORMATION = USE_AI_UPSCALE
  ? "e_upscale/q_auto:best"
  : "c_scale,w_512/e_sharpen:80/q_auto:best";

/** Заливает картинку в Cloudinary ПО ССЫЛКЕ, возвращает public_id. */
async function uploadRemote(imageUrl) {
  const url =
    `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`;

  const form = new FormData();
  form.append("upload_preset", UPLOAD_PRESET);
  form.append("file", imageUrl);

  const res = await fetch(url, {method: "POST", body: form});
  const data = await res.json();

  if (!res.ok) {
    throw new Error(
        `Cloudinary ${res.status}: ${data.error?.message || "ошибка"}`,
    );
  }

  return {publicId: data.public_id, format: data.format};
}

/** Собирает URL доставки с трансформацией. */
function deliveryUrl(publicId, format) {
  return `https://res.cloudinary.com/${CLOUD_NAME}/image/upload/` +
    `${TRANSFORMATION}/${publicId}.${format}`;
}

async function main() {
  const botsSnapshot = await db
      .collection("users")
      .where("isBot", "==", true)
      .get();

  const bots = botsSnapshot.docs.map((d) => ({ref: d.ref, ...d.data()}));

  // Берём только ботов с randomuser-фото: уже обработанных не трогаем.
  const targets = bots.filter((b) => {
    const photos = b.photoUrls || [];
    return photos.length > 0 && photos[0].includes("randomuser.me");
  });

  console.log(`Ботов всего: ${bots.length}, ` +
      `с фото randomuser: ${targets.length}`);

  if (targets.length === 0) {
    console.log("Обрабатывать нечего.");
    process.exit(0);
  }

  // Одинаковые randomuser-ссылки заливаем один раз (кэш по URL).
  const uploadedCache = new Map(); // исходный URL -> новый URL

  let done = 0;
  for (const bot of targets) {
    const sourceUrl = bot.photoUrls[0];

    try {
      let newUrl = uploadedCache.get(sourceUrl);

      if (!newUrl) {
        const {publicId, format} = await uploadRemote(sourceUrl);
        newUrl = deliveryUrl(publicId, format);
        uploadedCache.set(sourceUrl, newUrl);
      }

      await bot.ref.update({photoUrls: [newUrl]});
      done++;

      if (done % 20 === 0 || done === targets.length) {
        console.log(`...обработано ${done}/${targets.length}`);
      }
    } catch (e) {
      console.error(`ОШИБКА у ${bot.uid}: ${e.message}`);
    }
  }

  console.log(`\nГотово: ${done} ботов получили улучшенные фото.`);
  console.log("Проверьте одну из ссылок в браузере (коллекция users, " +
      "поле photoUrls). Если картинка не открывается — тариф Cloudinary " +
      "не поддерживает e_upscale: поставьте USE_AI_UPSCALE = false " +
      "и запустите скрипт снова.");
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});