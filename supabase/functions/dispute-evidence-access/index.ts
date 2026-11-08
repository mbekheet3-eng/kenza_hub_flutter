import { createClient } from "npm:@supabase/supabase-js@2";
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
const sha256 = async (bytes: ArrayBuffer) => {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
};
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "AUTH_REQUIRED" }, 401);
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  let serviceKey = "";
  try { const keys = Deno.env.get("SUPABASE_SECRET_KEYS"); if (keys) serviceKey = JSON.parse(keys).default ?? ""; } catch { /* legacy key fallback */ }
  serviceKey ||= Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !anonKey || !serviceKey) return json({ error: "SERVER_CONFIGURATION_ERROR" }, 500);
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false, autoRefreshToken: false } });
  const adminClient = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  const user = userData?.user;
  if (userError || !user) return json({ error: "INVALID_SESSION" }, 401);
  try {
    const body = await req.json();
    if (body?.action === "register") {
      const disputeId = String(body.dispute_id ?? "");
      const path = String(body.storage_path ?? "");
      const caption = typeof body.caption === "string" ? body.caption.slice(0, 500) : null;
      if (!/^[0-9a-f-]{36}$/i.test(disputeId) || !path.startsWith(disputeId + "/" + user.id + "/") || path.includes("..")) return json({ error: "INVALID_EVIDENCE_PATH" }, 400);
      const { data: dispute, error: disputeError } = await userClient.from("disputes").select("id,status").eq("id", disputeId).maybeSingle();
      if (disputeError || !dispute) return json({ error: "DISPUTE_ACCESS_DENIED" }, 403);
      if (["resolved", "rejected", "closed"].includes(dispute.status)) return json({ error: "DISPUTE_FINAL_EVIDENCE_LOCKED" }, 409);
      const { data: file, error: fileError } = await adminClient.storage.from("dispute-evidence").download(path);
      if (fileError || !file) return json({ error: "EVIDENCE_FILE_NOT_FOUND" }, 404);
      const digest = await sha256(await file.arrayBuffer());
      const { data: evidenceId, error: registerError } = await adminClient.rpc("register_dispute_evidence_with_hash", {
        p_dispute_id: disputeId, p_storage_path: path, p_caption: caption, p_sha256: digest, p_actor_user_id: user.id,
      });
      if (registerError || !evidenceId) {
        console.error("Evidence registration rejected", registerError?.message);
        return json({ error: "EVIDENCE_REGISTRATION_FAILED" }, 400);
      }
      return json({ success: true, evidence_id: evidenceId, sha256: digest });
    }
    if (body?.action === "signed_url") {
      const evidenceId = String(body.evidence_id ?? "");
      const purpose = body.purpose === "download" ? "download_url_issued" : "view_url_issued";
      if (!/^[0-9a-f-]{36}$/i.test(evidenceId)) return json({ error: "INVALID_EVIDENCE_ID" }, 400);
      const { data: evidence, error: evidenceError } = await userClient.from("dispute_evidence").select("id,dispute_id,storage_path,file_sha256").eq("id", evidenceId).maybeSingle();
      if (evidenceError || !evidence) return json({ error: "EVIDENCE_ACCESS_DENIED" }, 403);
      const { data: file, error: fileError } = await adminClient.storage.from("dispute-evidence").download(evidence.storage_path);
      if (fileError || !file) return json({ error: "EVIDENCE_FILE_NOT_FOUND" }, 404);
      const actualHash = await sha256(await file.arrayBuffer());
      if (!evidence.file_sha256 || actualHash !== evidence.file_sha256) {
        console.error("Dispute evidence integrity check failed", evidence.id);
        return json({ error: "EVIDENCE_INTEGRITY_CHECK_FAILED" }, 409);
      }
      const { data: signed, error: signedError } = await adminClient.storage.from("dispute-evidence").createSignedUrl(evidence.storage_path, 300, { download: body.purpose === "download" });
      if (signedError || !signed?.signedUrl) return json({ error: "SIGNED_URL_CREATION_FAILED" }, 500);
      const { error: logError } = await adminClient.from("dispute_evidence_access_log").insert({
        evidence_id: evidence.id, dispute_id: evidence.dispute_id, actor_user_id: user.id, action: purpose,
      });
      if (logError) {
        console.error("Could not write evidence access audit record", logError.message);
        return json({ error: "ACCESS_AUDIT_FAILED" }, 500);
      }
      return json({ signed_url: signed.signedUrl, expires_in_seconds: 300 });
    }
    return json({ error: "UNSUPPORTED_ACTION" }, 400);
  } catch (error) {
    console.error("Dispute evidence access request failed", error instanceof Error ? error.message : "unknown");
    return json({ error: "INTERNAL_ERROR" }, 500);
  }
});