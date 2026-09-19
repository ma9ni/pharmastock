class ApiConfig {
  // Change this to your backend URL:
  //   somee.com  → http://pharmacy-wms.somee.com/api
  //   Render.com → https://pharmacy-wms-backend.onrender.com/api
  //   Local LAN  → http://192.168.1.x:5000/api
  static const String baseUrl = 'https://pharmacy-wms-backend.onrender.com/api';

  // ── Mode Mock ──────────────────────────────────────────────────────────────
  // Mettre à true pour utiliser les données factices (pas de backend requis).
  // Mettre à false pour utiliser le vrai backend REST.
  static const bool useMock = true;
}
