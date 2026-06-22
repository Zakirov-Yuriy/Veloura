/**
 * Раскладывает характеры (архетипы из bot_characters.js) по всем ИИ-ботам.
 *
 * Проходит по users с isBot: true и каждому боту, у которого ещё нет
 * поля character, назначает архетип. Раздаёт равномерно по кругу, плюс
 * лёгкая вариация шкал (boldness/flirt/energy), чтобы боты одного
 * архетипа не были клонами.
 *
 * Это НЕ трогает persona (карточку жизни). Слои дополняют друг друга.
 *
 * Запуск (из папки functions; ИИ-ключи здесь не нужны, только доступ к БД):
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\путь\к\service-account.json"
 *   node assign_characters.js
 *
 * Флаги:
 *   --force         перезаписать характер у всех (иначе пропускает тех, у кого есть)
 *   --limit=20      обработать только N ботов (для теста)
 *   --dry           показать раскладку, но НЕ писать в БД
 *   --only=id1,id2  использовать только эти архетипы (id из bot_characters.js)
 *
 * Запускать можно повторно: без --force дополняет только новых ботов.
 */

const admin = require("firebase-admin");
const {ARCHETYPES, makeCharacter} = require("./bot_characters");

admin.initializeApp();
const db = admin.firestore();

const FORCE = process.argv.includes("--force");
const DRY = process.argv.includes("--dry");
const limitArg = process.argv.find((a) => a.startsWith("--limit="));
const LIMIT = limitArg ? parseInt(limitArg.split("=")[1], 10) : Infinity;
const onlyArg = process.argv.find((a) => a.startsWith("--only="));

let pool = ARCHETYPES.map((a) => a.id);
if (onlyArg) {
  const wanted = onlyArg.split("=")[1].split(",").map((s) => s.trim());
  const filtered = pool.filter((id) => wanted.includes(id));
  if (filtered.length === 0) {
    console.error("Ни один архетип из --only не найден. Доступные:", pool.join(", "));
    process.exit(1);
  }
  pool = filtered;
}

// Перемешиваем порядок раздачи, чтобы соседние по списку боты не
// получали один и тот же архетип подряд, но раздаём по кругу (равномерно).
function shuffled(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function main() {
  console.log(`Архетипов в пуле: ${pool.length} (${pool.join(", ")})`);
  console.log(`force: ${FORCE}, dry: ${DRY}, ` +
      `limit: ${LIMIT === Infinity ? "нет" : LIMIT}`);

  const snapshot = await db.collection("users")
      .where("isBot", "==", true)
      .get();

  let docs = snapshot.docs;
  if (!FORCE) {
    docs = docs.filter((d) => !d.data().character);
  }
  docs = docs.slice(0, LIMIT);

  console.log(`Ботов всего: ${snapshot.size}, к обработке: ${docs.length}`);
  if (docs.length === 0) {
    console.log("Делать нечего: у всех уже есть character (--force для перезаписи).");
    process.exit(0);
  }

  // Раздача по кругу из перемешанного пула — равномерно по архетипам.
  const order = shuffled(pool);
  const counts = {};
  let cursor = 0;

  let ok = 0;
  let fail = 0;

  for (const doc of docs) {
    const archetypeId = order[cursor % order.length];
    cursor++;
    const character = makeCharacter(archetypeId);
    if (!character) {
      fail++;
      continue;
    }
    counts[archetypeId] = (counts[archetypeId] || 0) + 1;

    const bot = doc.data();
    if (DRY) {
      console.log(`(dry) ${bot.name} (${doc.id}) → ${character.label} ` +
          `[b${character.boldness} f${character.flirt} e${character.energy}]`);
      ok++;
      continue;
    }

    try {
      await doc.ref.update({character: character});
      console.log(`✓ ${bot.name} (${doc.id}) → ${character.label} ` +
          `[b${character.boldness} f${character.flirt} e${character.energy}]`);
      ok++;
    } catch (e) {
      console.warn(`✗ ${bot.name} (${doc.id}): ${e.message}`);
      fail++;
    }
  }

  console.log("\nРаспределение по архетипам:");
  Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .forEach(([id, n]) => console.log(`  ${id}: ${n}`));

  console.log(`\nГотово. ${DRY ? "(dry-run, в БД не писалось) " : ""}` +
      `Успешно: ${ok}, ошибок: ${fail}.`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Фатальная ошибка:", e);
  process.exit(1);
});
