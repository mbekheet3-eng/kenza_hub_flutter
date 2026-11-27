export function shouldFallbackToNextModel(
  httpStatus: number,
  modelIndex: number,
  modelCount: number,
  responseBody = "",
): boolean {
  if (modelIndex >= modelCount - 1) return false;
  if (httpStatus === 404) return true;
  if (httpStatus === 403) {
    return /MODEL_NOT_AVAILABLE|model.{0,30}(not available|not found|unavailable)/i.test(responseBody);
  }
  return false;
}
