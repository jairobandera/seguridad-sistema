-- DropForeignKey
ALTER TABLE "Dispositivo" DROP CONSTRAINT "Dispositivo_casaId_fkey";

-- AlterTable
ALTER TABLE "Dispositivo" ALTER COLUMN "casaId" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "Dispositivo" ADD CONSTRAINT "Dispositivo_casaId_fkey" FOREIGN KEY ("casaId") REFERENCES "Casa"("id") ON DELETE SET NULL ON UPDATE CASCADE;
