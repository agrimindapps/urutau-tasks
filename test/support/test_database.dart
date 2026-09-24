import 'package:drift/native.dart';

import 'package:urutau_tasks/src/data/app_database.dart';

/// Banco em memória isolado para testes (spec 06, RF-26).
AppDatabase createMemoryDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());
