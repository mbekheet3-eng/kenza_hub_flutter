import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

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

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!apiKey || !supabaseUrl || !anonKey) {
      return json({ error: "Search service is not configured" }, 503);
    }

    const body = await req.json();
    const imageBase64 = body?.image_base64;
    const mimeType = body?.mime_type;
    if (typeof imageBase64 !== "string" || !["image/jpeg", "image/png", "image/webp"].includes(mimeType)) {
      return json({ error: "A JPEG, PNG, or WebP image is required" }, 400);
    }
    if (imageBase64.length > 12_000_000) return json({ error: "Image is too large" }, 413);

    const geminiResponse = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: "Analyze this product photo for marketplace search. Return ONLY JSON with keys: terms (array of 5-10 short product search terms in Arabic and English), category (short category), description (one concise sentence). Do not identify people. Focus only on the visible item." },
              { inline_data: { mime_type: mimeType, data: imageBase64 } },
            ],
          }],
          generationConfig: { responseMimeType: "application/json", temperature: 0.1 },
        }),
      },
    );
    if (!geminiResponse.ok) {
      const details = await geminiResponse.text();
      console.error("Gemini request failed", geminiResponse.status, details.slice(0, 500));
      return json({ error: "Image analysis failed" }, 502);
    }

    const geminiData = await geminiResponse.json();
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof rawText !== "string") return json({ error: "No image description returned" }, 502);

    let analysis: { terms?: unknown; category?: unknown; description?: unknown };
    try {
      analysis = JSON.parse(rawText);
    } catch {
      return json({ error: "Invalid image analysis response" }, 502);
    }
    const terms = Array.isArray(analysis.terms)
      ? analysis.terms.filter((term): term is string => typeof term === "string").slice(0, 10)
      : [];
    const cleanedTerms = [...new Set(terms.map((term) => term.trim()).filter((term) => term.length >= 2))];
    if (cleanedTerms.length === 0) return json({ terms: [], product_ids: [], message: "لم نتمكن من تحديد المنتج في الصورة" });

    const supabase = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: products, error } = await supabase
      .from("products")
      .select("id,title,description")
      .eq("status", "published")
      .limit(500);
    if (error) {
      console.error("Product lookup failed", error.message);
      return json({ error: "Could not search marketplace products" }, 500);
    }

    const ranked = (products ?? []).map((product) => {
      const haystack = `${product.title ?? ""} ${product.description ?? ""}`.toLocaleLowerCase();
      const score = cleanedTerms.reduce((sum, term) => {
        const normalized = term.toLocaleLowerCase();
        return sum + (haystack.includes(normalized) ? (normalized.length > 4 ? 3 : 1) : 0);
      }, 0);
      return { id: product.id, score };
    }).filter((item) => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 60);

    return json({
      terms: cleanedTerms,
      category: typeof analysis.category === "string" ? analysis.category : "",
      description: typeof analysis.description === "string" ? analysis.description : "",
      product_ids: ranked.map((item) => item.id),
    });
  } catch (error) {
    console.error("visual-search error", error);
    return json({ error: "Unexpected search error" }, 500);
  }
});