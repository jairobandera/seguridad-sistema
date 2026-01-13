import { prisma } from "../core/database/prisma";

export async function resolverDestinatarios(deviceId: string) {
  const dispositivo = await prisma.dispositivo.findUnique({
    where: { deviceId },
    include: {
      casa: {
        include: {
          usuario: {
            include: {
              contactos: true,
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

    // 🏠 CASA
    casaId: casa.id,
    codigoCasa: casa.codigo ?? "",
    numeroCasa: casa.numero ?? "",
    calle: casa.calle ?? null,
    manzana: casa.manzana ?? null,
    barrio: casa.barrio ?? null,
    alarmaArmada: casa.alarmaArmada ?? false,

    // 👤 CLIENTE
    usuarioId: usuario.id,
    nombreCliente: usuario.nombre ?? "",
    apellidoCliente: usuario.apellido ?? "",
    telefonoCliente: usuario.telefono ?? null,
    fcmToken: usuario.fcmToken ?? null,

    // 📞 CONTACTOS
    contactos: usuario.contactos.map((c) => ({
      id: c.id,
      nombre: c.nombre,
      telefono: c.telefono,
    })),
  };
}
