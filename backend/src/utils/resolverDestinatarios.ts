import { prisma } from "../core/database/prisma";

export async function resolverDestinatarios(deviceId: string) {
  const dispositivo = await prisma.dispositivo.findUnique({
    where: { deviceId },
    include: {
      casa: {
        include: {
          usuario: {
            include: {
              contactos: true, // 👈 ESTA ES LA RELACIÓN REAL
            },
          },
        },
      },
    },
  });

  if (!dispositivo || !dispositivo.casa || !dispositivo.casa.usuario) {
    return null;
  }

  const casa = dispositivo.casa;
  const usuario = casa.usuario;

  return {
    dispositivoId: dispositivo.id,
    casaId: casa.id,
    nombreCliente: `${usuario.nombre ?? ""} ${usuario.apellido ?? ""}`.trim(),
    telefonoCliente: usuario.telefono,
    codigoCasa: casa.codigo ?? "",
    numeroCasa: casa.numero ?? "",
    alarmaArmada: casa.alarmaArmada ?? false,

    // 👇 contactos del usuario, NO de la casa
    contactos: usuario.contactos.map((c) => ({
      id: c.id,
      nombre: c.nombre,
      telefono: c.telefono,
    })),
     fcmToken: usuario.fcmToken ?? null,
  };
}
