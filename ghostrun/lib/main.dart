import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screens/status_screen.dart';
import 'screens/scan_analyzing_screen.dart';
import 'screens/scan_sandbox_screen.dart';
import 'screens/scan_vulnerabilities_screen.dart';
import 'screens/news_screen.dart';
import 'screens/file_preview_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/community_screen.dart';
import 'theme/app_theme.dart';
import 'api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const GhostRunApp());
}

class GhostRunApp extends StatelessWidget {
  const GhostRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GhostRun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;

  // Scan flow
  int _scanStep = 0; // 0=analyzing, 1=sandbox, 2=vulns, 3=result
  String? _currentScanId;
  String? _currentFileId;

  // News sub-tab
  int _newsSubIndex = 0;

  // Live Alerts WebSocket
  WebSocketChannel? _wsChannel;
  bool _isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  @override
  void dispose() {
    _closeWebSocket();
    super.dispose();
  }

  void _initWebSocket() {
    _closeWebSocket();
    try {
      final wsUrlStr = ApiService.wsUrl;
      debugPrint('Connecting to WebSocket alerts at $wsUrlStr');
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrlStr));
      _wsChannel!.stream.listen(
        (message) {
          debugPrint('WS Received: $message');
          _handleWsMessage(message);
        },
        onError: (err) {
          debugPrint('WS Error: $err');
          _reconnectWs();
        },
        onDone: () {
          debugPrint('WS Closed');
          _reconnectWs();
        },
      );
      setState(() {
        _isWsConnected = true;
      });
    } catch (e) {
      debugPrint('WS Connect Exception: $e');
      _reconnectWs();
    }
  }

  void _reconnectWs() {
    setState(() {
      _isWsConnected = false;
    });
    // Try reconnecting after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isWsConnected) {
        _initWebSocket();
      }
    });
  }

  void _closeWebSocket() {
    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    _wsChannel = null;
    _isWsConnected = false;
  }

  void _handleWsMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final type = data['type'];
      if (type == 'threat_reported') {
        final threat = data['threat'];
        _showLiveAlert(
          title: 'NEW THREAT REPORTED',
          message: '${threat['title']} - ${threat['location']}',
          color: AppTheme.accentOrange,
          icon: Icons.warning_amber_rounded,
        );
      } else if (type == 'threat_voted') {
        final threat = data['threat'];
        if (threat['verified'] == true) {
          _showLiveAlert(
            title: 'THREAT VERIFIED',
            message: '${threat['title']} has been verified by the community.',
            color: AppTheme.accentRed,
            icon: Icons.gpp_bad_rounded,
          );
        }
      } else if (type == 'scan_completed') {
        final verdict = data['verdict'];
        final score = data['score'];
        final isSafe = verdict == 'safe';
        _showLiveAlert(
          title: 'SECURITY SCAN COMPLETED',
          message: 'Verdict: ${verdict.toString().toUpperCase()} (Score: $score/100)',
          color: isSafe ? AppTheme.accentGreen : AppTheme.accentRed,
          icon: isSafe ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
        );
      }
    } catch (e) {
      debugPrint('WS Message parsing error: $e');
    }
  }

  void _showLiveAlert({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startScan({String? fileId}) {
    setState(() {
      _tabIndex = 1;
      _scanStep = 0;
      _currentScanId = null;
      _currentFileId = fileId;
    });
  }

  void _advanceScanStep({String? scanId}) {
    setState(() {
      if (scanId != null) _currentScanId = scanId;
      _scanStep = (_scanStep + 1).clamp(0, 3);
    });
  }

  void _goToCommunity() {
    setState(() {
      _tabIndex = 3;
      _newsSubIndex = 1;
    });
  }

  Widget _buildScanBody() {
    switch (_scanStep) {
      case 0:
        return ScanAnalyzingScreen(
          onNext: _advanceScanStep,
          fileId: _currentFileId,
        );
      case 1:
        return ScanSandboxScreen(onNext: _advanceScanStep);
      case 2:
        return ScanVulnerabilitiesScreen(onNext: _advanceScanStep);
      case 3:
        return ScanResultScreen(
          scanId: _currentScanId,
          onDone: () => setState(() {
            _tabIndex = 0;
            _scanStep = 0;
            _currentScanId = null;
            _currentFileId = null;
          }),
        );
      default:
        return ScanAnalyzingScreen(onNext: _advanceScanStep);
    }
  }

  Widget _buildNewsBody() {
    return _newsSubIndex == 0
        ? NewsScreen(onViewAll: _goToCommunity)
        : const CommunityScreen();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_tabIndex) {
      case 0:
        body = StatusScreen(onStartScan: _startScan);
        break;
      case 1:
        body = _buildScanBody();
        break;
      case 2:
        body = FilePreviewScreen(onStartScan: _startScan);
        break;
      case 3:
        body = _buildNewsBody();
        break;
      default:
        body = StatusScreen(onStartScan: _startScan);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey('$_tabIndex-$_scanStep-$_newsSubIndex'),
          child: body,
        ),
      ),
      bottomNavigationBar: _GhostBottomNav(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() {
            _tabIndex = i;
            if (i == 1) _scanStep = 0;
            if (i == 3) _newsSubIndex = 0;
          });
        },
      ),
    );
  }
}

class _GhostBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GhostBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'STATUS'),
      _NavItem(icon: Icons.track_changes_rounded, label: 'SCAN'),
      _NavItem(icon: Icons.terminal_rounded, label: 'TOOLS'),
      _NavItem(icon: Icons.calendar_view_week_rounded, label: 'NEWS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon,
                          color: selected ? AppTheme.accentBlue : AppTheme.textMuted,
                          size: 22),
                      const SizedBox(height: 4),
                      Text(items[i].label,
                          style: GoogleFonts.rajdhani(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: selected ? AppTheme.accentBlue : AppTheme.textMuted)),
                      if (selected)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 16, height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
