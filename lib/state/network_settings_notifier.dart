import 'package:flutter/foundation.dart';

import '../repositories/network_simulator.dart';

/// Переключатель «имитировать сбой сети» для проверки экрана ошибки.
class NetworkSettingsNotifier extends ChangeNotifier {
  NetworkSettingsNotifier(this._simulator);

  final NetworkSimulator _simulator;

  bool get failRequests => _simulator.failRequests;

  void toggleFailures() {
    _simulator.failRequests = !_simulator.failRequests;
    notifyListeners();
  }
}
