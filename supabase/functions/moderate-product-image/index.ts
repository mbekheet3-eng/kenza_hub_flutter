import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiKey) return json({ error: "GEMINI_NOT_CONFIGURED" }, 503);

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) return json({ error: "AUTH_REQUIRED" }, 401);

  let secretKey = "";
  try {
    const keys = Deno.env.get("SUPABASE_SECRET_KEYS");
    if (keys) secretKey = JSON.parse(keys).default ?? "";
  } catch { /* fall back to legacy key below */ }
  secretKey ||= Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!secretKey) return json({ error: "SERVER_CONFIGURATION_ERROR" }, 500);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    secretKey,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  try {
    const { data: authData, error: authError } = await supabase.auth.getUser(token);
    const user = authData?.user;
    if (authError || !user) return json({ error: "INVALID_SESSION" }, 401);

    const body = await req.json();
    const imageId = body?.image_id;
    if (typeof imageId !== "string") return json({ error: "IMAGE_ID_REQUIRED" }, 400);

    const { data: image, error: imageError } = await supabase
      .from("product_images")
      .select("id, product_id, image_path, storage_bucket, ai_review_status, ai_review_result")
      .eq("id", imageId)
      .maybeSingle();
    if (imageError || !image) return json({ error: "IMAGE_NOT_FOUND" }, 404);

    const { data: product, error: productError } = await supabase
      .from("products")
      .select("id, seller_id, moderation_status")
      .eq("id", image.product_id)
      .maybeSingle();
    if (productError || !product) return json({ error: "PRODUCT_NOT_FOUND" }, 404);
    if (product.moderation_status !== "pending") {
      return json({ error: "PRODUCT_NOT_PENDING_REVIEW" }, 409);
    }

    const { data: activeUser, error: activeUserError } = await supabase
      .from("users")
      .select("is_active")
      .eq("id", user.id)
      .maybeSingle();
    if (activeUserError || !activeUser?.is_active) {
      return json({ error: "ACTIVE_USER_REQUIRED" }, 403);
    }

    const { data: sellerProfile, error: sellerProfileError } = await supabase
      .from("seller_profiles")
      .select("owner_user_id, is_active")
      .eq("id", product.seller_id)
      .maybeSingle();
    if (sellerProfileError || !sellerProfile?.is_active) {
      return json({ error: "ACTIVE_SELLER_PROFILE_REQUIRED" }, 403);
    }

    let canManageImages = sellerProfile.owner_user_id === user.id;
    if (!canManageImages) {
      const { data: membership, error: membershipError } = await supabase
        .from("seller_profile_members")
        .select("permissions")
        .eq("seller_profile_id", product.seller_id)
        .eq("user_id", user.id)
        .is("revoked_at", null)
        .maybeSingle();
      if (membershipError) {
        console.error("Seller membership lookup failed", membershipError.message);
        return json({ error: "PRODUCT_IMAGE_PERMISSION_CHECK_FAILED" }, 500);
      }
      canManageImages = membership?.permissions?.["products:update"] === true;
    }
    if (!canManageImages) {
      return json({ error: "PRODUCT_IMAGE_PERMISSION_REQUIRED" }, 403);
    }

    // PostgreSQL atomically claims the image and enforces the per-user limit.
    // It also recovers a processing lease abandoned for more than ten minutes.
    const { data: claimed, error: claimError } = await supabase.rpc(
      "claim_product_image_review",
      { p_image_id: image.id, p_requester_user_id: user.id },
    );
    if (claimError || claimed !== true) {
      const message = claimError?.message ?? "";
      if (message.includes("IMAGE_REVIEW_RATE_LIMITED")) {
        return json({ error: "IMAGE_REVIEW_RATE_LIMITED" }, 429);
      }
      if (message.includes("IMAGE_REVIEW_ALREADY_STARTED_OR_COMPLETED")) {
        return json({ error: "IMAGE_REVIEW_ALREADY_STARTED_OR_COMPLETED" }, 409);
      }
      return json({ error: "IMAGE_REVIEW_CLAIM_FAILED" }, 500);
    }

    const { data: signed, error: signedError } = await supabase.storage
      .from(image.storage_bucket)
      .createSignedUrl(image.image_path, 90);
    if (signedError || !signed?.signedUrl) return json({ error: "IMAGE_UNAVAILABLE" }, 422);

    const imageResponse = await fetch(signed.signedUrl);
    if (!imageResponse.ok) return json({ error: "IMAGE_FETCH_FAILED" }, 502);
    const contentType = imageResponse.headers.get("content-type") ?? "image/jpeg";
    if (!["image/jpeg", "image/png", "image/webp"].includes(contentType)) {
      return json({ error: "UNSUPPORTED_IMAGE_TYPE" }, 415);
    }
    const bytes = new Uint8Array(await imageResponse.arrayBuffer());
    if (bytes.length > 10 * 1024 * 1024) return json({ error: "IMAGE_TOO_LARGE" }, 413);
    let binary = "";
    for (let i = 0; i < bytes.length; i += 0x8000) {
      binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    }
    const base64 = btoa(binary);

    const prompt = `أنت نظام مراجعة صور Marketplace اسمه Kenza Hub. افحص الصورة فقط ولا تستنتج هوية الأشخاص.
أعد JSON صالحًا فقط بالمفاتيح:
decision: "approved" أو "rejected" أو "manual_review"
quality: "good" أو "poor" أو "uncertain"
quality_issues: مصفوفة من blur, dark, overexposed, low_resolution, obstructed أو []
unsafe_content: true/false
adult_or_sexual_content: true/false
violence_or_gore: true/false
irrelevant_or_misleading: true/false
prohibited_item: true/false
product_visible: true/false
reason_ar: جملة عربية قصيرة للمستخدم
confidence: رقم بين 0 و1
rules:
- ارفض فقط عند وجود مخالفة واضحة مؤكدة مثل العري/المحتوى الجنسي الصريح أو العنف الدموي أو منتج محظور بوضوح.
- إذا كانت الصورة مشوشة/مظلمة جدًا أو المنتج غير ظاهر، اجعل القرار manual_review أو quality poor ولا ترفض تلقائيًا.
- إذا لم تكن متأكدًا، اختر manual_review.
- لا ترفض صورة لمجرد ظهور شخص أو طفل بملابس عادية.
- الصورة يجب أن تعرض سلعة مناسبة للبيع ضمن الملابس والأحذية ومستلزمات الأطفال والمنزل.
- لا تحكم على حالة المنتج (جديد/سبق استخدامه) من الصورة وحدها.`;

    const geminiResponse = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent",
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": geminiKey },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }, { inline_data: { mime_type: contentType, data: base64 } }] }],
          generationConfig: { responseMimeType: "application/json", temperature: 0.1 },
        }),
      },
    );
    if (!geminiResponse.ok) {
      const failure = await geminiResponse.text();
      console.error("Gemini request failed", geminiResponse.status, failure.slice(0, 300));
      return json({ error: "GEMINI_REQUEST_FAILED" }, 502);
    }
    const geminiPayload = await geminiResponse.json();
    const textPart = geminiPayload?.candidates?.[0]?.content?.parts?.find((p: any) => p.text)?.text;
    if (!textPart) return json({ error: "GEMINI_EMPTY_RESPONSE" }, 502);

    let review: any;
    try { review = JSON.parse(textPart); } catch { return json({ error: "GEMINI_INVALID_RESPONSE" }, 502); }

    const allowed = ["approved", "rejected", "manual_review"];
    const quality = ["good", "poor", "uncertain"].includes(review.quality)
      ? review.quality
      : "uncertain";
    const qualityIssues = Array.isArray(review.quality_issues)
      ? review.quality_issues.filter((item: unknown) =>
          ["blur", "dark", "overexposed", "low_resolution", "obstructed"].includes(String(item)))
      : [];
    const confidenceValue = Number(review.confidence);
    const confidence = Number.isFinite(confidenceValue)
      ? Math.max(0, Math.min(1, confidenceValue))
      : 0;
    const flags = {
      unsafe_content: review.unsafe_content === true,
      adult_or_sexual_content: review.adult_or_sexual_content === true,
      violence_or_gore: review.violence_or_gore === true,
      irrelevant_or_misleading: review.irrelevant_or_misleading === true,
      prohibited_item: review.prohibited_item === true,
    };
    const clearViolation = Object.values(flags).some(Boolean);
    const safeForAutoApproval =
      review.decision === "approved" &&
      confidence >= 0.85 &&
      quality === "good" &&
      review.product_visible === true &&
      qualityIssues.length === 0 &&
      !clearViolation;
    const clearForAutoRejection =
      allowed.includes(review.decision) &&
      review.decision === "rejected" &&
      confidence >= 0.90 &&
      clearViolation;
    const decision = clearForAutoRejection
      ? "rejected"
      : safeForAutoApproval
        ? "approved"
        : "manual_review";
    const status = decision === "approved" ? "approved" : decision === "rejected" ? "rejected" : "pending";
    const result = {
      decision,
      quality,
      quality_issues: qualityIssues,
      ...flags,
      product_visible: review.product_visible === true,
      reason_ar: String(review.reason_ar ?? "الصورة تحتاج إلى مراجعة"),
      confidence,
    };

    const { error: updateError } = await supabase.from("product_images").update({
      ai_review_status: status,
      ai_review_result: result,
      ai_reviewed_at: new Date().toISOString(),
      ai_review_model: "gemini-3.8-flash",
    }).eq("id", image.id);
    if (updateError) {
      console.error("Image review persistence failed", updateError.message);
      return json({ error: "REVIEW_SAVE_FAILED" }, 500);
    }

    const { data: imageRows, error: rowsError } = await supabase
      .from("product_images").select("ai_review_status").eq("product_id", product.id);
    if (rowsError || !imageRows?.length) {
      console.error("Could not evaluate all product image reviews", rowsError?.message);
      return json({ error: "PRODUCT_REVIEW_STATUS_FAILED" }, 500);
    }

    if (imageRows.some((row: any) => row.ai_review_status === "rejected")) {
      const { data: hiddenStatus, error: hiddenStatusError } = await supabase
        .from("product_statuses")
        .select("id")
        .eq("slug", "hidden")
        .eq("is_active", true)
        .maybeSingle();
      if (hiddenStatusError || !hiddenStatus?.id) {
        console.error("Hidden product status is not configured", hiddenStatusError?.message);
        return json({ error: "PRODUCT_STATUS_CONFIGURATION_ERROR" }, 500);
      }
      const { error: productUpdateError } = await supabase
        .from("products")
        .update({
          moderation_status: "rejected",
          status_id: hiddenStatus.id,
          published_at: null,
        })
        .eq("id", product.id);
      if (productUpdateError) {
        console.error("Product rejection persistence failed", productUpdateError.message);
        return json({ error: "PRODUCT_REVIEW_SAVE_FAILED" }, 500);
      }
    } else if (imageRows.every((row: any) => row.ai_review_status === "approved")) {
      const { data: published, error: publishError } = await supabase.rpc(
        "publish_product_after_ai_review",
        { p_product_id: product.id },
      );
      if (publishError) {
        console.error("Product publication gate failed", publishError.message);
        return json({ error: "PRODUCT_PUBLICATION_GATE_FAILED" }, 500);
      }
      if (published !== true) {
        return json({
          image_id: image.id,
          status,
          review: result,
          product_status: "pending_review",
          publication_blocked: true,
        });
      }
    }

    return json({ image_id: image.id, status, review: result });
  } catch (error) {
    console.error("Image moderation error", error instanceof Error ? error.message : "unknown");
    return json({ error: "INTERNAL_ERROR" }, 500);
  }
});
