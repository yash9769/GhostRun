import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/status_screen.dart';
import 'screens/scan_analyzing_screen.dart';
import 'screens/scan_sandbox_screen.dart';
import 'screens/scan_vulnerabilities_screen.dart';
import 'screens/news_screen.dart';
import 'screens/file_preview_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/community_screen.dart';
import 'theme/app_theme.dart';

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

  // Scan sub-screen: 0=analyzing, 1=sandbox, 2=vulnerabilities, 3=result
  int _scanStep = 0;

  // News sub-screen: 0=news, 1=community
  int _newsSubIndex = 0;

  void _startScan() {
    setState(() {
      _tabIndex = 1;
      _scanStep = 0;
    });
  }

  void _advanceScanStep() {
    setState(() {
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
        return ScanAnalyzingScreen(onNext: _advanceScanStep);
      case 1:
        return ScanSandboxScreen(onNext: _advanceScanStep);
      case 2:
        return ScanVulnerabilitiesScreen(onNext: _advanceScanStep);
      case 3:
        return ScanResultScreen(onDone: () {
          setState(() {
            _tabIndex = 0;
            _scanStep = 0;
          });
        });
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
        body = const FilePreviewScreen();
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

  const _GhostBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

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
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
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
                      Icon(
                        items[i].icon,
                        color: selected
                            ? AppTheme.accentBlue
                            : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: GoogleFonts.rajdhani(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: selected
                              ? AppTheme.accentBlue
                              : AppTheme.textMuted,
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
