import { assertEquals } from "jsr:@std/assert@1";
import { shouldFallbackToNextModel } from "../_shared/gemini_model_fallback.ts";

Deno.test("primary model 404 proceeds to the next model", () => {
  assertEquals(shouldFallbackToNextModel(404, 0, 3), true);
});

Deno.test("model-specific 403 availability errors proceed to fallback", () => {
  assertEquals(shouldFallbackToNextModel(403, 0, 3, '{"reason":"MODEL_NOT_AVAILABLE_FOR_ACCOUNT"}'), true);
  assertEquals(shouldFallbackToNextModel(403, 0, 3, "The model is not available"), true);
});

Deno.test("generic authentication and request errors do not fallback", () => {
  assertEquals(shouldFallbackToNextModel(401, 0, 3), false);
  assertEquals(shouldFallbackToNextModel(403, 0, 3, "API key is invalid"), false);
  assertEquals(shouldFallbackToNextModel(400, 0, 3), false);
});

Deno.test("fallback does not recurse beyond the model list", () => {
  assertEquals(shouldFallbackToNextModel(404, 2, 3), false);
});
