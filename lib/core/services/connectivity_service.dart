import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityResult(result);

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen(_handleConnectivityResult);
    } catch (e) {
      print('Error initializing connectivity: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }

  void _handleConnectivityResult(dynamic result) {
    ConnectivityResult connectivityResult;
    
    if (result is List<ConnectivityResult>) {
      connectivityResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
    } else if (result is ConnectivityResult) {
      connectivityResult = result;
    } else {
      connectivityResult = ConnectivityResult.none;
    }
    
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    _connectionStatusController.add(_isConnected);
    
    // Log connection status changes
    if (!wasConnected && _isConnected) {
      print('✅ Internet connected - syncing will start');
    } else if (wasConnected && !_isConnected) {
      print('⚠️ Internet disconnected - offline mode active');
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
