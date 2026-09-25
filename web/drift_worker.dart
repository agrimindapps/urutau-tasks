import 'package:drift/wasm.dart';

/// Worker Web do drift compilado com `dart compile js -O4`
/// (https://drift.simonbinder.eu/platforms/web/#compilation).
void main() => WasmDatabase.workerMainForOpen();
