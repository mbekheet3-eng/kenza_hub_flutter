/// Network Connectivity Checker
abstract class INetworkInfo {
  /// التحقق من وجود اتصال إنترنت
  Future<bool> isConnected();
}

/// Implementation
class NetworkInfo implements INetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();

  factory NetworkInfo() {
    return _instance;
  }

  NetworkInfo._internal();

  @override
  Future<bool> isConnected() async {
    // في الإصدارات المستقبلية، يمكن استخدام connectivity_plus package
    // import 'package:connectivity_plus/connectivity_plus.dart';
    // final result = await (Connectivity().checkConnectivity());
    // return result != ConnectivityResult.none;

    // الآن نرجع true (يمكن تحسينها لاحقاً)
    return true;
  }
}
