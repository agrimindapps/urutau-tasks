import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/tasks/application/task_providers.dart';
import '../data/data_portability_service.dart';

final dataPortabilityServiceProvider = Provider<DataPortabilityService>(
  (ref) => DataPortabilityService(ref.watch(appDatabaseProvider)),
);
