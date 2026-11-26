import { assertEquals } from "jsr:@std/assert@1";
import { shouldFallbackToNextModel } from "../_shared/gemini_model_fallback.ts";

Deno.test("primary model 404 proceeds to the next model", () => {
  assertEquals(shouldFallbackToNextModel(404, 0, 2), true);
});

Deno.test("fallback model 404 does not recurse beyond the model list", () => {
  assertEquals(shouldFallbackToNextModel(404, 1, 2), false);
});

Deno.test("authentication and request errors remain fatal", () => {
  assertEquals(shouldFallbackToNextModel(401, 0, 2), false);
  assertEquals(shouldFallbackToNextModel(403, 0, 2), false);
  assertEquals(shouldFallbackToNextModel(400, 0, 2), false);
});
