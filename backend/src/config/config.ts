/**
 * Runtime configuration loaded from environment variables
 */
export const config = {
  openRouterApiKey: process.env?.["OPENROUTER_API_KEY"],
  logDir: process.env?.["GAME_LOG_DIR"] ?? "./data",
  port:
    process.env?.["PORT"] !== undefined ? Number(process.env?.["PORT"]) : 3000,
  corsOrigin: process.env?.["CORS_ORIGIN"],
  maxLlmRetries: 3,
  bodyLimit: "1mb",
};
