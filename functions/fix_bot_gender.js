/**
 * Аудит и починка поля gender у ботов в Firestore.
 *
 * Зачем: если часть женских ботов имеет пустое или нестандартное поле
 * gender, воркер по умолчанию считал их мужчинами, и они отвечали в
 * мужском роде. Скрипт находит таких ботов и приводит gender к
 * "female" / "male".
 *
 * Запуск:
 *   # сначала аудит (ничего не меняет, только показывает):
 *   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json
 *   node fix_bot_gender.js
 *
 *   # затем реальная починка:
 *   node fix_bot_gender.js --apply
 */

const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const APPLY = process.argv.includes("--apply");

// Списки женских и мужских имён для определения пола по имени,
// если другие способы не сработали. Дополни при необходимости.
const femaleNames = [
  "анна", "мария", "елена", "ольга", "наталья", "ирина", "татьяна",
  "екатерина", "светлана", "юлия", "анастасия", "вероника", "ксения",
  "дарья", "виктория", "полина", "алиса", "софия", "софья", "арина",
  "валерия", "марина", "кристина", "евгения", "людмила", "галина",
  "оксана", "яна", "алёна", "алена", "диана", "карина", "лилия",
  "маргарита", "альбина", "регина", "элина", "милана", "влада",
  "камила", "камилла", "эльвира", "снежана", "лера", "настя", "катя",
  "лена", "оля", "таня", "света", "юля", "вика", "даша", "маша",
];

const maleNames = [
  "александр", "сергей", "дмитрий", "андрей", "алексей", "максим",
  "евгений", "иван", "михаил", "артём", "артем", "никита", "роман",
  "владимир", "павел", "денис", "егор", "кирилл", "антон", "игорь",
  "олег", "виктор", "константин", "юрий", "тимур", "руслан", "марат",
  "ринат", "данил", "данила", "глеб", "степан", "матвей", "арсений",
  "богдан", "влад", "саша", "женя", "дима", "лёша", "леша", "макс",
];

function firstName(name) {
  return (name || "").toString().trim().toLowerCase().split(/\s+/)[0];
}

/**
 * Возвращает "female" | "male" | null.
 * null означает, что определить пол не удалось.
 */
function resolveGender(bot) {
  const raw = (bot.gender || bot.sex || "").toString().trim().toLowerCase();
  if (["female", "f", "woman", "women", "girl", "ж", "женский",
    "жен", "женщина", "девушка"].includes(raw)) {
    return "female";
  }
  if (["male", "m", "man", "men", "boy", "м", "мужской",
    "муж", "мужчина", "парень"].includes(raw)) {
    return "male";
  }

  const uid = (bot.uid || "").toString().toLowerCase();
  if (uid.includes("female")) return "female";
  if (uid.includes("male")) return "male";

  const fn = firstName(bot.name);
  if (femaleNames.includes(fn)) return "female";
  if (maleNames.includes(fn)) return "male";

  return null;
}

async function main() {
  console.log(APPLY ? "РЕЖИМ: ПОЧИНКА (--apply)" : "РЕЖИМ: только аудит");

  const snapshot = await db
      .collection("users")
      .where("isBot", "==", true)
      .get();

  let total = 0;
  let alreadyOk = 0;
  let willFix = 0;
  let unresolved = 0;

  const unresolvedNames = [];
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    total++;
    const bot = doc.data();
    const current = (bot.gender || "").toString().trim().toLowerCase();
    const resolved = resolveGender(bot);

    if (resolved === null) {
      unresolved++;
      unresolvedNames.push(`${bot.name || "?"} (uid=${doc.id})`);
      continue;
    }

    if (current === resolved) {
      alreadyOk++;
      continue;
    }

    willFix++;
    console.log(
        `ПОЧИНКА: ${bot.name || "?"} (uid=${doc.id}) ` +
      `gender "${bot.gender || ""}" -> "${resolved}"`,
    );

    if (APPLY) {
      batch.update(doc.ref, {gender: resolved});
      batchCount++;
      // Firestore batch максимум 500 операций.
      if (batchCount >= 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (APPLY && batchCount > 0) {
    await batch.commit();
  }

  console.log("\n=== ИТОГ ===");
  console.log(`Всего ботов:           ${total}`);
  console.log(`Уже корректны:         ${alreadyOk}`);
  console.log(`${APPLY ? "Исправлено" : "Будет исправлено"}: ${willFix}`);
  console.log(`Не удалось определить: ${unresolved}`);

  if (unresolvedNames.length > 0) {
    console.log("\nБоты без определённого пола (проставь вручную):");
    unresolvedNames.slice(0, 50).forEach((n) => console.log(`  - ${n}`));
    if (unresolvedNames.length > 50) {
      console.log(`  ...и ещё ${unresolvedNames.length - 50}`);
    }
  }

  if (!APPLY && willFix > 0) {
    console.log(
        "\nЭто был аудит. Чтобы применить изменения, запусти:\n" +
      "  node fix_bot_gender.js --apply",
    );
  }

  process.exit(0);
}

main().catch((e) => {
  console.error("Ошибка:", e);
  process.exit(1);
});
