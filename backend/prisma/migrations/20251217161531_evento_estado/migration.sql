-- CreateTable
CREATE TABLE "EventoEstado" (
    "id" SERIAL NOT NULL,
    "eventoId" INTEGER NOT NULL,
    "leido" BOOLEAN NOT NULL DEFAULT false,
    "atendido" BOOLEAN NOT NULL DEFAULT false,
    "leidoEn" TIMESTAMP(3),
    "atendidoEn" TIMESTAMP(3),
    "guardiaId" INTEGER,

    CONSTRAINT "EventoEstado_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "EventoEstado_eventoId_key" ON "EventoEstado"("eventoId");

-- AddForeignKey
ALTER TABLE "EventoEstado" ADD CONSTRAINT "EventoEstado_guardiaId_fkey" FOREIGN KEY ("guardiaId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventoEstado" ADD CONSTRAINT "EventoEstado_eventoId_fkey" FOREIGN KEY ("eventoId") REFERENCES "Evento"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
