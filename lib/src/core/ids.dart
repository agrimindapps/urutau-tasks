import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Gera identificadores estáveis de domínio (spec 06, RF-03).
String newId() => _uuid.v4();
