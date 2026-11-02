import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device currently has a network connection.
abstract class INetworkInfo {
  Future<bool> isConnected();
}

class NetworkInfo implements INetworkInfo {
  NetworkInfo._internal();

  static final NetworkInfo _instance = NetworkInfo._internal();

  factory NetworkInfo() => _instance;

  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      // Fail closed when the connectivity check itself cannot be completed.
      return false;
    }
  }
}
