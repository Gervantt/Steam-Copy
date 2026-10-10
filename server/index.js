// Local QR sign-in server for the free Spark plan (no Cloud Functions).
//
// The browser that shows the QR code calls POST /redeem once a signed-in
// phone has approved the request. The server checks the request in
// Firestore and returns a custom token for the phone's account, which the
// browser uses with signInWithCustomToken.
//
// Run: node index.js   (needs service-account.json next to this file)

const http = require("node:http");
const path = require("node:path");
const fs = require("node:fs");
const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const PORT = Number(process.env.PORT) || 8787;
const KEY_PATH = process.env.SERVICE_ACCOUNT || path.join(__dirname, "service-account.json");
// Browsers allowed to call the server. Flutter web dev servers run on localhost.
const ALLOWED_ORIGIN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

const SESSION_ID = /^[A-Za-z0-9_-]{16,128}$/;
// How long after approval the browser may still redeem it.
const REDEEM_WINDOW_MS = 2 * 60 * 1000;

if (!fs.existsSync(KEY_PATH)) {
  console.error(`Missing ${KEY_PATH}. Download it from Firebase console →`);
  console.error("Project settings → Service accounts → Generate new private key.");
  process.exit(1);
}

initializeApp({ credential: cert(require(KEY_PATH)) });
const auth = getAuth();
const db = getFirestore();

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

async function redeem(idToken, sessionId) {
  let caller;
  try {
    caller = await auth.verifyIdToken(idToken);
  } catch {
    throw new HttpError(401, "Sign in first.");
  }
  if (typeof sessionId !== "string" || !SESSION_ID.test(sessionId)) {
    throw new HttpError(400, "Bad session id.");
  }

  const ref = db.collection("qr_sessions").doc(sessionId);
  const uid = await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists) throw new HttpError(404, "Unknown sign-in request.");
    const session = snapshot.data();
    if (session.webUid !== caller.uid) {
      throw new HttpError(403, "Not your sign-in request.");
    }
    if (session.status !== "approved" || !session.approvedBy || !session.approvedAt) {
      throw new HttpError(409, "Request is not approved.");
    }
    if (Date.now() - session.approvedAt.toMillis() > REDEEM_WINDOW_MS) {
      throw new HttpError(410, "Approval expired.");
    }
    tx.update(ref, { status: "redeemed", redeemedAt: FieldValue.serverTimestamp() });
    return session.approvedBy;
  });

  return auth.createCustomToken(uid);
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 10_000) reject(new HttpError(413, "Body too large."));
    });
    req.on("end", () => {
      try {
        resolve(JSON.parse(body || "{}"));
      } catch {
        reject(new HttpError(400, "Body must be JSON."));
      }
    });
    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  const origin = req.headers.origin;
  if (origin && ALLOWED_ORIGIN.test(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
    res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  }
  if (req.method === "OPTIONS") {
    res.writeHead(204).end();
    return;
  }

  const send = (status, body) => {
    res.writeHead(status, { "Content-Type": "application/json" });
    res.end(JSON.stringify(body));
  };

  if (req.method !== "POST" || req.url !== "/redeem") {
    send(404, { error: "Not found." });
    return;
  }

  try {
    const header = req.headers.authorization || "";
    const idToken = header.startsWith("Bearer ") ? header.slice(7) : "";
    const { sessionId } = await readJson(req);
    const token = await redeem(idToken, sessionId);
    console.log(`Redeemed QR session ${sessionId.slice(0, 6)}…`);
    send(200, { token });
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    if (status === 500) console.error(e);
    send(status, { error: status === 500 ? "Server error." : e.message });
  }
});

server.listen(PORT, () => {
  console.log(`GameVault QR server on http://localhost:${PORT}`);
});
