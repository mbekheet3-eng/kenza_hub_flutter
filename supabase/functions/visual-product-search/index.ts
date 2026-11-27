import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

type UsageClient = {
  rpc: (name: string, args: Record<string, unknown>) => Promise<{ data: any; error: any }>;
};
class AiQuotaError extends Error {
  payload: Record<string, unknown>;
  constructor(payload: Record<string, unknown>) {
    super(String(payload.reason ?? "AI quota limit reached"));
    this.payload = payload;
  }
}
async function beginAiUsage(
  client: UsageClient, service: string, requestId: string, attemptNo: number, model: string,
): Promise<void> {
  const { data, error } = await client.rpc("consume_ai_usage_attempt", {
    p_service_key: service, p_request_id: requestId, p_attempt_no: attemptNo, p_model: model,
  });
  if (error) {
    console.error("AI quota check failed", error.message ?? error);
    throw new Error("Could not verify AI usage quota");
  }
  if (!data?.allowed) throw new AiQuotaError(data ?? { reason: "quota_check_failed" });
}
async function finishAiUsage(
  client: UsageClient, service: string, requestId: string, attemptNo: number,
  response: Response | null,
): Promise<void> {
  let inputTokens: number | null = null;
  let outputTokens: number | null = null;
  if (response) {
    try {
      const payload = await response.clone().json();
      inputTokens = Number.isFinite(Number(payload?.usageMetadata?.promptTokenCount))
        ? Number(payload.usageMetadata.promptTokenCount) : null;
      outputTokens = Number.isFinite(Number(payload?.usageMetadata?.candidatesTokenCount))
        ? Number(payload.usageMetadata.candidatesTokenCount) : null;
    } catch { /* Provider errors may not contain JSON usage metadata. */ }
  }
  const { error } = await client.rpc("finish_ai_usage_attempt", {
    p_service_key: service, p_request_id: requestId, p_attempt_no: attemptNo,
    p_http_status: response?.status ?? null, p_succeeded: response?.ok ?? false,
    p_input_tokens: inputTokens, p_output_tokens: outputTokens,
  });
  if (error) console.error("Could not finalize AI usage event", error.message ?? error);
}
function quotaErrorResponse(error: AiQuotaError) {
  const daily = error.payload.reason === "daily_quota_exceeded";
  return {
    error_code: daily ? "daily_quota_exceeded" : "rate_limited",
    message_ar: daily
      ? "وصلت للحد اليومي لاستخدام هذه الخدمة. حاول مرة أخرى غدًا."
      : "استخدمت الخدمة بسرعة. انتظر دقيقة ثم حاول مرة أخرى.",
    ...error.payload,
  };
}


const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return json({ error: "Authentication required" }, 401);
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  if (!supabaseUrl || !anonKey) return json({ error: "Service is not configured" }, 503);
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const token = authorization.slice("Bearer ".length).trim();
  const { data: authData, error: authError } = await userClient.auth.getUser(token);
  if (authError || !authData.user) return json({ error: "Invalid session" }, 401);

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json({ error: "Image search is not configured" }, 503);

    const body = await req.json();
    const imageBase64 = body?.image_base64;
    const mimeType = body?.mime_type;

    if (
      typeof imageBase64 !== "string" ||
      !["image/jpeg", "image/png", "image/webp"].includes(mimeType)
    ) {
      return json({ error: "A JPEG, PNG, or WebP image is required" }, 400);
    }
    if (imageBase64.length > 14_000_000) {
      return json({ error: "Image is too large. Please choose a smaller image." }, 413);
    }
    const usageRequestId = crypto.randomUUID();
    const usageAttemptCounter = { value: 0 };

    const geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";
    const geminiRequest = {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({
        contents: [{
          parts: [
            {
              text: "Analyze this product photo for search inside the Kenza marketplace only. Return ONLY JSON with keys: terms (array of 5-10 short product search terms; include Arabic and English terms where useful), category (short product category), description (one concise sentence). Focus only on the visible item. Do not identify people. Do not invent a brand, size, or attribute that is not clearly visible. Do not search the web or suggest external products.",
            },
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
          ],
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.1 },
      }),
    };

    const requestModel = async (model: string): Promise<Response | null> => {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 14_000);
      const attemptNo = ++usageAttemptCounter.value;
      await beginAiUsage(userClient, "image_search", usageRequestId, attemptNo, model);
      try {
        const response = await fetch(url, { ...geminiRequest, signal: controller.signal });
        await finishAiUsage(userClient, "image_search", usageRequestId, attemptNo, response);
        return response;
      } catch (error) {
        await finishAiUsage(userClient, "image_search", usageRequestId, attemptNo, null);
        console.error("Gemini request failed", model, String(error).slice(0, 200));
        return null;
      } finally {
        clearTimeout(timeout);
      }
    };

    // Fast-first cascade: Hydrogen, then two independently available Flash fallbacks.
    const models = ["gemini-4-hydrogen", "gemini-3.8-flash", "gemini-3.5-flash-lite"];
    let geminiResponse: Response | null = null;
    let lastStatus = 0;
    let lastDetails = "network error or timeout";

    for (let modelIndex = 0; modelIndex < models.length; modelIndex++) {
      const model = models[modelIndex];
      geminiResponse = await requestModel(model);
      if (geminiResponse?.ok) break;

      lastStatus = geminiResponse?.status ?? 0;
      lastDetails = geminiResponse ? await geminiResponse.text() : "network error or timeout";
      console.error("Gemini image search model failed", model, lastStatus, lastDetails.slice(0, 200));

      const modelSpecific403 = lastStatus === 403 &&
        /MODEL_NOT_AVAILABLE|model.{0,30}(not available|not found|unavailable)/i.test(lastDetails);
      const canFallback = ![400, 401].includes(lastStatus) &&
        (lastStatus !== 403 || modelSpecific403) &&
        (lastStatus === 0 || [403, 404, 408, 429, 500, 502, 503, 504].includes(lastStatus));

      if (!canFallback || modelIndex === models.length - 1) break;
      await new Promise((resolve) => setTimeout(resolve, 350));
    }

    if (!geminiResponse?.ok) {
      console.error("All Gemini image search models unavailable", lastStatus, lastDetails.slice(0, 300));
      return json({
        error_code: lastStatus === 429 ? "rate_limited" : "temporary_unavailable",
        error: "Image search is temporarily busy. Please try again in a moment.",
      }, lastStatus === 429 ? 429 : 503);
    }

    const geminiData = await geminiResponse.json();
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof rawText !== "string") return json({ error: "No image analysis was returned" }, 502);

    let analysis: { terms?: unknown; category?: unknown; description?: unknown };
    try {
      analysis = JSON.parse(rawText);
    } catch {
      return json({ error: "The image analysis response was invalid" }, 502);
    }

    const terms = Array.isArray(analysis.terms)
      ? analysis.terms
        .filter((term): term is string => typeof term === "string")
        .map((term) => term.trim().slice(0, 80))
        .filter((term) => term.length >= 2)
      : [];
    const cleanedTerms = [...new Set(terms)].slice(0, 10);

    return json({
      terms: cleanedTerms,
      category: typeof analysis.category === "string" ? analysis.category.slice(0, 80) : "",
      description: typeof analysis.description === "string" ? analysis.description.slice(0, 200) : "",
    });
  } catch (error) {
    if (error instanceof AiQuotaError) return json(quotaErrorResponse(error), 429);
    console.error("visual-product-search error", error);
    return json({ error: "Unexpected image search error" }, 500);
  }
});