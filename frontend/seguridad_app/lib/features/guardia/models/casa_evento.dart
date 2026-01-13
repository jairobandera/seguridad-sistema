class CasaEvento {
  final int id;
  final String? codigo;
  final String? numero;
  final String? calle;
  final String? manzana;
  final String? barrio;
  final bool? alarmaArmada;

  CasaEvento({
    required this.id,
    this.codigo,
    this.numero,
    this.calle,
    this.manzana,
    this.barrio,
    this.alarmaArmada,
  });

  factory CasaEvento.fromJson(Map<String, dynamic> json) {
    return CasaEvento(
      id: json['id'],
      codigo: json['codigo'],
      numero: json['numero'],
      calle: json['calle'],
      manzana: json['manzana'],
      barrio: json['barrio'],
      alarmaArmada: json['alarmaArmada'],
    );
  }
}
