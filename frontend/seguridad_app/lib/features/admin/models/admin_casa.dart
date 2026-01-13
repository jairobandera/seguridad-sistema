// lib/features/admin/models/admin_casa.dart
class AdminCasa {
  final int id;

  final String? codigo;
  final String? numero;
  final String? calle;
  final String? barrio;
  final String? manzana;

  final bool alarmaArmada;
  final bool activo;

  final int? usuarioId;
  final String? clienteNombre; // si el backend lo manda (opcional)

  AdminCasa({
    required this.id,
    this.codigo,
    this.numero,
    this.calle,
    this.barrio,
    this.manzana,
    required this.alarmaArmada,
    required this.activo,
    this.usuarioId,
    this.clienteNombre,
  });

  String get direccion {
    final dir = "${calle ?? ""} ${numero ?? ""}".trim();
    final parts = <String>[
      if (dir.isNotEmpty) dir,
      if ((barrio ?? "").trim().isNotEmpty) barrio!.trim(),
      if ((manzana ?? "").trim().isNotEmpty) "Mz ${manzana!.trim()}",
    ];
    return parts.join(" · ");
  }

  factory AdminCasa.fromJson(Map<String, dynamic> json) {
    return AdminCasa(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo']?.toString(),
      numero: json['numero']?.toString(),
      calle: json['calle']?.toString(),
      barrio: json['barrio']?.toString(),
      manzana: json['manzana']?.toString(),
      alarmaArmada: (json['alarmaArmada'] ?? false) == true,
      activo: (json['activo'] ?? true) == true,
      usuarioId:
          json['usuarioId'] == null ? null : (json['usuarioId'] as num).toInt(),
      clienteNombre: json['clienteNombre']?.toString(), // opcional
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'codigo': codigo,
      'numero': numero,
      'calle': calle,
      'barrio': barrio,
      'manzana': manzana,
      'usuarioId': usuarioId,
      'alarmaArmada': alarmaArmada,
      'activo': activo,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'numero': numero,
      'calle': calle,
      'barrio': barrio,
      'manzana': manzana,
      'activa': activo,
    };
  }

  AdminCasa copyWith({
    String? codigo,
    String? numero,
    String? calle,
    String? barrio,
    String? manzana,
    bool? alarmaArmada,
    bool? activo,
    int? usuarioId,
    String? clienteNombre,
  }) {
    return AdminCasa(
      id: id,
      codigo: codigo ?? this.codigo,
      numero: numero ?? this.numero,
      calle: calle ?? this.calle,
      barrio: barrio ?? this.barrio,
      manzana: manzana ?? this.manzana,
      alarmaArmada: alarmaArmada ?? this.alarmaArmada,
      activo: activo ?? this.activo,
      usuarioId: usuarioId ?? this.usuarioId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
    );
  }
}
