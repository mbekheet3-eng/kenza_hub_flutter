import "jsr:@supabase/functions-js/edge-runtime.d.ts";

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

const recentRequests = new Map<string, number[]>();

function isRateLimited(req: Request): boolean {
  const key = req.headers.get("cf-connecting-ip") ?? req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  if (!key) return false;
  const now = Date.now();
  const recent = (recentRequests.get(key) ?? []).filter((time) => now - time < 60_000);
  if (recent.length >= 12) {
    recentRequests.set(key, recent);
    return true;
  }
  recent.push(now);
  recentRequests.set(key, recent);
  if (recentRequests.size > 500) {
    for (const [entry, times] of recentRequests) {
      if (times.every((time) => now - time >= 60_000)) recentRequests.delete(entry);
    }
  }
  return false;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (isRateLimited(req)) return json({ error: "Too many image searches. Please try again shortly." }, 429);

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
      try {
        return await fetch(url, geminiRequest);
      } catch (error) {
        console.error("Gemini request failed", model, String(error).slice(0, 200));
        return null;
      }
    };

    // Try the primary model once, then switch models during provider overload.
    let geminiResponse = await requestModel("gemini-3.8-flash");
    if (!geminiResponse?.ok) {
      const firstStatus = geminiResponse?.status ?? 0;
      const firstDetails = geminiResponse ? await geminiResponse.text() : "network error";
      console.error("Primary Gemini model failed", firstStatus, firstDetails.slice(0, 200));

      if ([400, 401, 403].includes(firstStatus)) {
        return json({
          error_code: "analysis_configuration_error",
          error: "Image analysis could not be completed. Please try again later.",
        }, 503);
      }

      await new Promise((resolve) => setTimeout(resolve, 600));
      geminiResponse = await requestModel("gemini-3.7-flash");

      // One retry on the fallback model for temporary capacity/network errors.
      if (!geminiResponse?.ok && (
        !geminiResponse || [408, 429, 500, 502, 503, 504].includes(geminiResponse.status)
      )) {
        const fallbackDetails = geminiResponse ? await geminiResponse.text() : "network error";
        console.error("Fallback Gemini model failed; retrying", geminiResponse?.status ?? 0, fallbackDetails.slice(0, 200));
        await new Promise((resolve) => setTimeout(resolve, 1200));
        geminiResponse = await requestModel("gemini-3.7-flash");
      }
    }

    if (!geminiResponse?.ok) {
      const status = geminiResponse?.status ?? 0;
      const details = geminiResponse ? await geminiResponse.text() : "network error";
      console.error("Gemini image analysis unavailable", status, details.slice(0, 300));
      return json({
        error_code: "temporary_unavailable",
        error: "Image search is temporarily busy. Please try again in a moment.",
      }, 503);
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
    console.error("visual-product-search error", error);
    return json({ error: "Unexpected image search error" }, 500);
  }
});