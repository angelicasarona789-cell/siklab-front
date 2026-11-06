# Siklab

Siklab is a Flutter client for the Siklab Flask API. The API is the database
boundary: it connects to the MySQL schema in `database_schema.sql` or
`siklab.sql`, while the Flutter app communicates with it over HTTP.

## Connect The App

The app runs without a database. If the Flask API is unavailable, sign-up and
login use a local account saved in the browser or device storage. Start the
Flask API on port `5000` only when you want server-backed synchronization.

The default API endpoint is:

- Android emulator: `http://10.0.2.2:5000`
- Web, Windows, macOS, Linux, and iOS simulator: `http://127.0.0.1:5000`

For a physical phone, use the computer's LAN address and keep both devices on
the same network:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000
```

Replace `192.168.1.5` with the computer running the Flask API. Do not put
MySQL credentials in the Flutter app; configure those in the API server.
