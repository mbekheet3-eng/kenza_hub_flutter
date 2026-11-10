import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type JsonRecord = Record<string, unknown>;

const json = (body: JsonRecord, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

function encodeJson(value: unknown): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemToBytes(pem: string): Uint8Array {
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(body);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function getGoogleAccessToken(serviceAccount: JsonRecord): Promise<string> {
  const clientEmail = String(serviceAccount.client_email ?? "");
  const privateKey = String(serviceAccount.private_key ?? "");
  const tokenUri = String(serviceAccount.token_uri ?? "https://oauth2.googleapis.com/token");

  if (!clientEmail || !privateKey || !tokenUri.startsWith("https://")) {
    throw new Error("Firebase service account JSON is missing required credentials.");
  }

  const now = Math.floor(Date.now() / 1000);
  const unsigned = [
    encodeJson({ alg: "RS256", typ: "JWT" }),
    encodeJson({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: tokenUri,
      iat: now,
      exp: now + 3600,
    }),
  ].join(".");

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );
  const assertion = unsigned + "." + base64Url(signature);

  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const result = await response.json();
  if (!response.ok || !result.access_token) {
    console.error("Google OAuth token exchange failed:", result.error ?? response.status);
    throw new Error("Could not obtain a Firebase Cloud Messaging access token.");
  }
  return String(result.access_token);
}

function toFcmData(value: unknown): Record<string, string> {
  const output: Record<string, string> = {};
  if (!value || typeof value !== "object" || Array.isArray(value)) return output;

  for (const [key, item] of Object.entries(value as JsonRecord)) {
    if (!key || key.startsWith("google.") || key === "from" || key === "message_type") continue;
    if (item === null || item === undefined) continue;
    output[key] = typeof item === "string" ? item : JSON.stringify(item);
  }
  return output;
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const legacyServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}";
  let secretKeys: Record<string, string> = {};
  try {
    secretKeys = JSON.parse(secretKeysRaw) as Record<string, string>;
  } catch {
    secretKeys = {};
  }
  const authorization = request.headers.get("Authorization") ?? "";
  const requestApiKey = request.headers.get("apikey") ?? "";
  const legacyAuthorized =
    !!legacyServiceRoleKey && authorization === "Bearer " + legacyServiceRoleKey;
  const modernSecretAuthorized =
    !!requestApiKey && Object.values(secretKeys).includes(requestApiKey);
  if (!legacyAuthorized && !modernSecretAuthorized) {
    return json({ error: "Unauthorized webhook caller" }, 401);
  }
  const supabaseApiKey = legacyServiceRoleKey || requestApiKey;
  if (!supabaseApiKey) return json({ error: "Missing Supabase server API key" }, 500);

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";
  if (!serviceAccountRaw) {
    return json({ error: "Missing FIREBASE_SERVICE_ACCOUNT_JSON Edge Function secret" }, 503);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  if (!supabaseUrl) return json({ error: "Missing Supabase URL" }, 500);

  let payload: JsonRecord;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const record = (payload.record && typeof payload.record === "object"
    ? payload.record
    : payload) as JsonRecord;

  if (payload.table && payload.table !== "notifications") {
    return json({ error: "Unsupported webhook table" }, 400);
  }
  if (typeof record.id !== "string" || typeof record.user_id !== "string") {
    return json({ error: "Webhook record must include notification id and user_id" }, 400);
  }

  let serviceAccount: JsonRecord;
  try {
    serviceAccount = JSON.parse(serviceAccountRaw) as JsonRecord;
  } catch {
    return json({ error: "FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON" }, 500);
  }

  const firebaseProjectId = String(serviceAccount.project_id ?? "");
  if (!firebaseProjectId || firebaseProjectId !== "kenza-hub") {
    return json({ error: "Firebase service account belongs to an unexpected project" }, 500);
  }

  const notificationId = String(record.id);
  const userId = String(record.user_id);
  const title = String(record.title ?? "كنزة هب");
  const body = String(record.body ?? "لديك إشعار جديد");
  const data = {
    ...toFcmData(record.data),
    notification_id: notificationId,
    notification_type: String(record.type ?? ""),
  };

  const tokensUrl = new URL(supabaseUrl + "/rest/v1/device_tokens");
  tokensUrl.search = new URLSearchParams({
    select: "id,token",
    user_id: "eq." + userId,
    is_active: "eq.true",
    platform: "eq.android",
  }).toString();

  const headers = legacyServiceRoleKey
    ? {
        apikey: legacyServiceRoleKey,
        Authorization: "Bearer " + legacyServiceRoleKey,
      }
    : { apikey: supabaseApiKey };
  const tokenResponse = await fetch(tokensUrl, { headers });
  if (!tokenResponse.ok) {
    console.error("Could not load active device tokens:", tokenResponse.status);
    return json({ error: "Could not load device tokens" }, 502);
  }

  const tokens = await tokenResponse.json() as Array<{ id: string; token: string }>;
  if (!tokens.length) return json({ ok: true, sent: 0, reason: "No active Android devices" });

  let accessToken: string;
  try {
    accessToken = await getGoogleAccessToken(serviceAccount);
  } catch (error) {
    console.error("Firebase authentication failed:", error);
    return json({ error: "Firebase authentication failed" }, 502);
  }

  const results = await Promise.all(tokens.map(async (device) => {
    const response = await fetch(
      "https://fcm.googleapis.com/v1/projects/" + firebaseProjectId + "/messages:send",
      {
        method: "POST",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: device.token,
            notification: { title, body },
            data,
            android: {
              priority: "high",
              
            },
          },
        }),
      },
    );

    if (response.ok) return { ok: true, id: device.id };

    const errorBody = await response.json().catch(() => ({}));
    const errorText = JSON.stringify(errorBody);
    console.error("FCM send failed:", response.status, errorText.slice(0, 500));

    if (response.status === 404 || errorText.includes("UNREGISTERED")) {
      await fetch(
        supabaseUrl + "/rest/v1/device_tokens?id=eq." + encodeURIComponent(device.id),
        {
          method: "PATCH",
          headers: { ...headers, "Content-Type": "application/json", Prefer: "return=minimal" },
          body: JSON.stringify({ is_active: false, updated_at: new Date().toISOString() }),
        },
      );
    }
    return { ok: false, id: device.id, status: response.status };
  }));

  const sent = results.filter((result) => result.ok).length;
  const failed = results.length - sent;
  return json({ ok: failed === 0, notification_id: notificationId, sent, failed });
});
