// Writes the game catalog (games.json) to Firestore `games/{id}`.
// Run: node seed.js   (needs service-account.json next to this file)

const path = require("node:path");
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({ credential: cert(require(path.join(__dirname, "service-account.json"))) });
const db = getFirestore();
const games = require("./games.json");

// 14.99 at 50% off is 7.495; stores show it as 7.49.
const salePrice = (oldPrice, percent) =>
  Math.floor(oldPrice * (100 - percent)) / 100;

(async () => {
  const batch = db.batch();
  // Drop games that are no longer in the catalog.
  const keep = new Set(games.map((g) => g.id));
  const existing = await db.collection("games").listDocuments();
  for (const doc of existing) {
    if (!keep.has(doc.id)) batch.delete(doc);
  }
  for (const { id, ...game } of games) {
    batch.set(db.collection("games").doc(id), {
      ...game,
      price: salePrice(game.oldPrice, game.discountPercent),
      featured: game.featured === true,
      topSeller: game.topSeller === true,
    });
  }
  await batch.commit();
  console.log(`Seeded ${games.length} games.`);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
