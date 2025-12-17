// src/core/prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'info', emit: 'event' },
    { level: 'warn', emit: 'event' },
    { level: 'error', emit: 'event' },
  ],
});

// Logs bonitos
prisma.$on('query', (e) => {
  console.log(`\n🟦 Prisma Query: ${e.query}`);
  if (e.params !== '[]') console.log(`🔸 Params: ${e.params}`);
});

prisma.$on('info', (e) => console.log(`ℹ️ Prisma: ${e.message}`));
prisma.$on('warn', (e) => console.log(`⚠️ Prisma: ${e.message}`));
prisma.$on('error', (e) => console.log(`❌ Prisma: ${e.message}`));

// Cierre seguro
process.on('beforeExit', async () => {
  console.log('🔌 Cerrando Prisma...');
  await prisma.$disconnect();
});

export default prisma;
