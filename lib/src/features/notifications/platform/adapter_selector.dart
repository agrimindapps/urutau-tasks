import 'adapter_stub.dart'
    if (dart.library.js_interop) 'adapter_web.dart'
    if (dart.library.io) 'adapter_io.dart';

import '../domain/reminder_delivery.dart';

/// Seleciona o adaptador por compilação condicional (spec 08, §5).
ReminderAdapter createReminderAdapter() => createPlatformReminderAdapter();
