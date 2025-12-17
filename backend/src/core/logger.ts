// src/core/logger.ts
export const logger = {
  info: (msg: string) => console.log(`ℹ️ [INFO] ${new Date().toISOString()} - ${msg}`),
  warn: (msg: string) => console.warn(`⚠️ [WARN] ${new Date().toISOString()} - ${msg}`),
  error: (msg: string) => console.error(`❌ [ERROR] ${new Date().toISOString()} - ${msg}`),
};
