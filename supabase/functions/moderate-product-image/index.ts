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
      .select("id, product_id, image_path, storage_bucket")
      .eq("id", imageId)
      .maybeSingle();
    if (imageError || !image) return json({ error: "IMAGE_NOT_FOUND" }, 404);

    const { data: product, error: productError } = await supabase
      .from("products")
      .select("id, seller_id, moderation_status, status_id")
      .eq("id", image.product_id)
      .maybeSingle();
    if (productError || !product) return json({ error: "PRODUCT_NOT_FOUND" }, 404);

    const { data: seller, error: sellerError } = await supabase
      .from("seller_profiles")
      .select("owner_user_id")
      .eq("id", product.seller_id)
      .maybeSingle();
    if (sellerError || !seller || seller.owner_user_id !== user.id) {
      return json({ error: "NOT_PRODUCT_OWNER" }, 403);
    }

    const { data: pendingStatus, error: pendingStatusError } = await supabase
      .from("product_statuses")
      .select("id")
      .eq("slug", "pending_review")
      .eq("is_active", true)
      .maybeSingle();
    if (pendingStatusError || !pendingStatus) {
      console.error("Pending review status is not configured", pendingStatusError?.message);
      return json({ error: "PENDING_STATUS_NOT_CONFIGURED" }, 500);
    }
    if (
      product.moderation_status !== "pending" ||
      product.status_id !== pendingStatus.id
    ) {
      return json({ error: "PRODUCT_NOT_PENDING_REVIEW" }, 409);
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
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
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

    const flagKeys = [
      "unsafe_content",
      "adult_or_sexual_content",
      "violence_or_gore",
      "irrelevant_or_misleading",
      "prohibited_item",
    ] as const;
    const flagsAreValid = flagKeys.every((key) => typeof review[key] === "boolean");
    const qualityIsValid = ["good", "poor", "uncertain"].includes(review.quality);
    const issuesAreValid = Array.isArray(review.quality_issues) &&
      review.quality_issues.every((issue: unknown) =>
        ["blur", "dark", "overexposed", "low_resolution", "obstructed"].includes(String(issue))
      );
    const confidence = review.confidence;
    const confidenceIsValid =
      typeof confidence === "number" && Number.isFinite(confidence) &&
      confidence >= 0 && confidence <= 1;
    const hasHardViolation = flagKeys.some((key) => review[key] === true);

    // Gemini can approve only a complete, internally consistent, high-confidence result.
    // Any explicit safety/prohibited-content flag rejects; ambiguity fails closed to manual review.
    const canApprove =
      review.decision === "approved" &&
      flagsAreValid &&
      flagKeys.every((key) => review[key] === false) &&
      qualityIsValid &&
      review.quality === "good" &&
      issuesAreValid &&
      review.quality_issues.length === 0 &&
      review.product_visible === true &&
      confidenceIsValid &&
      confidence >= 0.85 &&
      typeof review.reason_ar === "string" &&
      review.reason_ar.trim().length > 0;

    const decision = hasHardViolation
      ? "rejected"
      : canApprove
      ? "approved"
      : "manual_review";
    const status = decision === "approved" ? "approved" : decision === "rejected" ? "rejected" : "pending";
    const result = {
      decision,
      quality: qualityIsValid ? review.quality : "uncertain",
      quality_issues: issuesAreValid ? review.quality_issues : [],
      unsafe_content: review.unsafe_content === true,
      adult_or_sexual_content: review.adult_or_sexual_content === true,
      violence_or_gore: review.violence_or_gore === true,
      irrelevant_or_misleading: review.irrelevant_or_misleading === true,
      prohibited_item: review.prohibited_item === true,
      product_visible: review.product_visible === true,
      reason_ar: typeof review.reason_ar === "string" && review.reason_ar.trim()
        ? review.reason_ar.trim().slice(0, 500)
        : "الصورة تحتاج إلى مراجعة بشرية",
      confidence: confidenceIsValid ? confidence : 0,
    };

    // Re-check the product immediately before persisting the result. An admin decision
    // made while Gemini was processing must never be overwritten or bypassed.
    const { data: currentProduct, error: currentProductError } = await supabase
      .from("products")
      .select("moderation_status, status_id")
      .eq("id", product.id)
      .maybeSingle();
    if (currentProductError || !currentProduct) {
      return json({ error: "PRODUCT_RECHECK_FAILED" }, 500);
    }
    if (
      currentProduct.moderation_status !== "pending" ||
      currentProduct.status_id !== pendingStatus.id
    ) {
      return json({ error: "PRODUCT_NOT_PENDING_REVIEW" }, 409);
    }

    const { error: updateError } = await supabase.from("product_images").update({
      ai_review_status: status,
      ai_review_result: result,
      ai_reviewed_at: new Date().toISOString(),
      ai_review_model: "gemini-2.5-flash",
    }).eq("id", image.id);
    if (updateError) {
      console.error("Image review persistence failed", updateError.message);
      return json({ error: "REVIEW_SAVE_FAILED" }, 500);
    }

    // AI image review never publishes, rejects, hides, or changes product lifecycle.
    // The product remains pending until the existing admin moderation workflow decides.
    return json({ image_id: image.id, status, review: result });
  } catch (error) {
    console.error("Image moderation error", error instanceof Error ? error.message : "unknown");
    return json({ error: "INTERNAL_ERROR" }, 500);
  }
});
