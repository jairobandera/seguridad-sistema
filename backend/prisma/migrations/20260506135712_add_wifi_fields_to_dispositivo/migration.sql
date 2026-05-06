/*
  Warnings:

  - You are about to drop the column `ssid` on the `Dispositivo` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Dispositivo" DROP COLUMN "ssid",
ADD COLUMN     "wifiRssi" INTEGER,
ADD COLUMN     "wifiSsid" TEXT;
