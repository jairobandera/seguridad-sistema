import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WifiPage extends StatelessWidget {
  final String casaNombre;
  final bool dispositivoOnline;

  const WifiPage({
    super.key,
    required this.casaNombre,
    required this.dispositivoOnline,
  });

  static const String portalSsid = "SEC-HUB-CONFIG";
  static const String portalPass = "12345678";
  static const String portalUrl = "http://192.168.4.1";

  Future<void> _abrirPortal(BuildContext context) async {
    final uri = Uri.parse(portalUrl);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Conectate a la red SEC-HUB-CONFIG (clave 12345678) y abrí http://192.168.4.1",
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        title: const Text("Configuración WiFi"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dispositivo",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    casaNombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        dispositivoOnline
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: dispositivoOnline
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dispositivoOnline
                            ? "Dispositivo online"
                            : "Dispositivo offline",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configurar red WiFi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "1) Conectate a la red SEC-HUB-CONFIG\n"
                    "2) Clave: 12345678\n"
                    "3) Se abrirá el portal del dispositivo",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirPortal(context),
                      icon: const Icon(Icons.wifi),
                      label: const Text("Abrir portal WiFi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
