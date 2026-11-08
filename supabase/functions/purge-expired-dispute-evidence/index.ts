import { createClient } from "npm:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  const suppliedSecret = req.headers.get("x-retention-secret");
  if (!suppliedSecret) return json({ error: "AUTH_REQUIRED" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  let serviceKey = "";
  try {
    const keys = Deno.env.get("SUPABASE_SECRET_KEYS");
    if (keys) serviceKey = JSON.parse(keys).default ?? "";
  } catch {
    // Fall back to the legacy service-role environment variable.
  }
  serviceKey ||= Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    console.error("Retention cleanup server credentials are unavailable");
    return json({ error: "SERVER_CONFIGURATION_ERROR" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const { data: authorized, error: authError } = await supabase.rpc(
      "verify_dispute_retention_cron_secret",
      { p_secret: suppliedSecret },
    );
    if (authError || authorized !== true) return json({ error: "INVALID_CRON_SECRET" }, 401);

    const { data: expired, error: selectError } = await supabase
      .from("dispute_evidence")
      .select("id, storage_path")
      .eq("legal_hold", false)
      .not("retention_expires_at", "is", null)
      .lte("retention_expires_at", new Date().toISOString())
      .order("retention_expires_at", { ascending: true })
      .limit(100);

    if (selectError) {
      console.error("Could not load expired dispute evidence", selectError.message);
      return json({ error: "EVIDENCE_QUERY_FAILED" }, 500);
    }

    let deletedFiles = 0;
    let deletedRows = 0;
    let failedBatches = 0;

    for (let i = 0; i < (expired ?? []).length; i += 50) {
      const batch = (expired ?? []).slice(i, i + 50);
      const paths = batch.map((row: { storage_path: string }) => row.storage_path);
      const ids = batch.map((row: { id: string }) => row.id);

      // A previous run may have removed objects but failed before deleting metadata.
      const { data: existingBefore, error: checkBeforeError } = await supabase.rpc(
        "dispute_evidence_existing_storage_paths",
        { p_paths: paths },
      );
      if (checkBeforeError || !Array.isArray(existingBefore)) {
        failedBatches++;
        console.error("Could not inspect evidence storage objects", checkBeforeError?.message);
        continue;
      }

      if (existingBefore.length > 0) {
        const { error: storageError } = await supabase.storage
          .from("dispute-evidence")
          .remove(existingBefore);

        if (storageError) {
          // Confirm whether the failure left any objects behind before deciding to retry.
          const { data: remaining, error: verifyError } = await supabase.rpc(
            "dispute_evidence_existing_storage_paths",
            { p_paths: paths },
          );
          if (verifyError || !Array.isArray(remaining) || remaining.length > 0) {
            failedBatches++;
            console.error("Storage evidence cleanup remains incomplete", storageError.message);
            continue;
          }
        }
      }

      // Never delete metadata until every corresponding object is confirmed absent.
      const { data: remaining, error: verifyError } = await supabase.rpc(
        "dispute_evidence_existing_storage_paths",
        { p_paths: paths },
      );
      if (verifyError || !Array.isArray(remaining) || remaining.length > 0) {
        failedBatches++;
        console.error("Evidence objects still exist or could not be verified");
        continue;
      }

      const { data: removedRows, error: deleteError } = await supabase
        .from("dispute_evidence")
        .delete()
        .in("id", ids)
        .eq("legal_hold", false)
        .select("id");

      if (deleteError) {
        failedBatches++;
        console.error("Evidence metadata cleanup failed", deleteError.message);
      } else {
        deletedFiles += existingBefore.length;
        deletedRows += removedRows?.length ?? 0;
        if ((removedRows?.length ?? 0) !== ids.length) {
          failedBatches++;
          console.error("Some evidence metadata rows were not deleted; a later run can retry");
        }
      }
    }

    return json({
      success: failedBatches === 0,
      examined: expired?.length ?? 0,
      deleted_storage_objects: deletedFiles,
      deleted_evidence_rows: deletedRows,
      failed_batches: failedBatches,
    });
  } catch (error) {
    console.error("Dispute evidence retention cleanup failed", error instanceof Error ? error.message : "unknown");
    return json({ error: "INTERNAL_ERROR" }, 500);
  }
});
