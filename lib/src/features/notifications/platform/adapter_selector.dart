// Seleção do adaptador por plataforma (ADR-0004): a Web nunca importa
// pacotes nativos, preservando `flutter build web`.
import 'adapter_stub.dart'
    if (dart.library.io) 'adapter_io.dart'
    if (dart.library.js_interop) 'adapter_web.dart' as platform_adapter;

import '../domain/reminder_delivery.dart';

/// Instancia o adaptador da plataforma em compilação atual.
NotificationAdapter createNotificationAdapter() =>
    platform_adapter.createAdapter();
