export function shouldFallbackToNextModel(
  httpStatus: number,
  modelIndex: number,
  modelCount: number,
): boolean {
  return httpStatus === 404 && modelIndex < modelCount - 1;
}
