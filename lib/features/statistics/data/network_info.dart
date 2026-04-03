import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final List<ConnectivityResult> connectivityResults =
        await _connectivity.checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }
}
