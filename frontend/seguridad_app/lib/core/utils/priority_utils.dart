enum Prioridad {
  critica,
  alta,
  media,
  normal,
  indeterminada,
}

Prioridad calcularPrioridad({
  required bool dispositivoOnline,
  required bool alarmaArmada,
  String? ultimoEventoTipo,
}) {
  if (!dispositivoOnline) return Prioridad.critica;

  if (ultimoEventoTipo == 'door_open') {
    return alarmaArmada ? Prioridad.critica : Prioridad.alta;
  }

  if (ultimoEventoTipo == 'reconexion') {
    return Prioridad.media;
  }

  if (ultimoEventoTipo == null) {
    return Prioridad.indeterminada;
  }

  return Prioridad.normal;
}
