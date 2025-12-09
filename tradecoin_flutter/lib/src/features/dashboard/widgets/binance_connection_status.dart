import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../binance/screens/binance_onboarding_screen.dart';
import '../../binance/providers/binance_connection_provider.dart';

class BinanceConnectionStatus extends ConsumerStatefulWidget {
  const BinanceConnectionStatus({super.key});

  @override
  ConsumerState<BinanceConnectionStatus> createState() => _BinanceConnectionStatusState();
}

class _BinanceConnectionStatusState extends ConsumerState<BinanceConnectionStatus> {
  @override
  void initState() {
    super.initState();
    // 초기 연결 상태 확인만 수행 (반복 체크 제거)
    Future.microtask(() {
      _initializeBinanceConnection();
    });
  }

  Future<void> _initializeBinanceConnection() async {
    // Provider를 통해 바이낸스 연결 상태 초기화 (1회만)
    if (mounted) {
      await ref.read(binanceConnectionProvider.notifier).checkConnectionStatus();
    }
  }

  Future<void> _forceRefresh() async {
    // 사용자가 수동으로 새로고침 버튼을 누를 때만 업데이트
    await ref.read(binanceConnectionProvider.notifier).checkConnectionStatus();
  }

  void _navigateToConnection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BinanceOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(binanceConnectionProvider);

    if (connectionState.isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('연결 상태 확인 중...', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: connectionState.isConnected
            ? const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        ),
        child: Row(
          children: [
            Icon(
              connectionState.isConnected ? Icons.check_circle : Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connectionState.isConnected ? '바이낸스 연결됨' : '바이낸스 연결 필요',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (connectionState.isConnected)
                    Text(
                      connectionState.accountType == "testnet" ? "테스트넷" : "실거래 계정",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (connectionState.isConnected)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                onPressed: _forceRefresh,
                tooltip: '새로고침',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            if (!connectionState.isConnected)
              TextButton(
                onPressed: _navigateToConnection,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('연결', style: TextStyle(fontSize: 12)),
              ),
            if (connectionState.isConnected)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                onPressed: _navigateToConnection,
                tooltip: '설정',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }
}