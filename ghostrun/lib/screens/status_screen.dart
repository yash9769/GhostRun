import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';
import 'package:permission_handler/permission_handler.dart';

class StatusScreen extends StatefulWidget {
  final Function({String? fileId}) onStartScan;
  const StatusScreen({super.key, required this.onStartScan});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;

  // Device profile state (interactive toggles)
  bool _developerMode = false;
  bool _unknownSources = false;
  bool _openWifi = false;
  int _sideloadedApps = 0;

  // Real device info
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _networkInfo = {};

  Map<String, dynamic>? _scoreData;
  bool _loadingScore = false;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    _loadDeviceContext();
  }

  Future<void> _loadDeviceContext() async {
    // Request location permission (needed to read Wi-Fi SSID on Android 8.1+)
    if (!kIsWeb) {
      await Permission.locationWhenInUse.request();
    }

    final deviceInfo = await ApiService.getRealDeviceInfo();
    final networkInfo = await ApiService.getRealNetworkInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = deviceInfo;
        _networkInfo = networkInfo;
        _developerMode = deviceInfo['developer_mode'] as bool? ?? false;
        _openWifi = networkInfo['on_wifi'] as bool? ?? false;
      });
    }
    _refreshScore();
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshScore() async {
    setState(() => _loadingScore = true);
    _scoreCtrl.reset();
    final data = await ApiService.computeDeviceScore({
      'os_version': _deviceInfo['os_version'] ?? 'Android',
      'is_rooted': _deviceInfo['is_rooted'] ?? false,
      'developer_mode': _developerMode,
      'unknown_sources': _unknownSources,
      'last_os_update_days': 12,
      'sideloaded_apps': _sideloadedApps,
      'open_wifi_connected': _openWifi,
    });
    if (mounted) {
      setState(() { _scoreData = data; _loadingScore = false; });
      _scoreCtrl.forward();
    }
  }

  double get _score => (_scoreData?['score'] as num?)?.toDouble() ?? 100.0;
  String get _verdict => _scoreData?['verdict'] as String? ?? 'excellent';
  Color get _scoreColor {
    if (_score >= 90) return AppTheme.accentGreen;
    if (_score >= 70) return AppTheme.accentBlue;
    if (_score >= 50) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildScoreRing(),
                  const SizedBox(height: 24),
                  _buildInteractiveToggles(),
                  const SizedBox(height: 20),
                  _buildRiskFactors(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildStatusGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20, right: 20, bottom: 12),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DEVICE STATUS', style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
          Text('Security Overview', style: AppTheme.headingM),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: const Icon(Icons.settings_rounded, color: AppTheme.textMuted, size: 24),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue.withOpacity(0.15),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5)),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.accentBlue, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreRing() {
    return Center(
      child: AnimatedBuilder(
        animation: _scoreAnim,
        builder: (_, __) {
          final animScore = _score * _scoreAnim.value;
          return SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _RingPainter(
                    progress: animScore / 100,
                    color: _scoreColor,
                    bgColor: AppTheme.borderColor,
                  ),
                ),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(animScore.toStringAsFixed(0),
                      style: GoogleFonts.rajdhani(
                          fontSize: 56, fontWeight: FontWeight.w900, color: _scoreColor, height: 1)),
                  Text('THREAT SCORE', style: AppTheme.labelXS.copyWith(fontSize: 8)),
                  const SizedBox(height: 4),
                  GhostChip(label: _verdict.toUpperCase().replaceAll('_', ' '), color: _scoreColor),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractiveToggles() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tune_rounded, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('DEVICE INTEGRITY SIMULATOR', style: AppTheme.labelXS),
            const Spacer(),
            Text('Toggle to see score impact', style: AppTheme.bodyS.copyWith(fontSize: 10)),
          ]),
          const SizedBox(height: 14),
          _toggle('Developer Mode', 'Exposes debug interfaces', Icons.code_rounded,
              AppTheme.accentOrange, _developerMode, (v) {
            setState(() => _developerMode = v);
            _refreshScore();
          }),
          _toggle('Unknown Sources', 'Allows sideloading apps', Icons.warning_rounded,
              AppTheme.accentRed, _unknownSources, (v) {
            setState(() => _unknownSources = v);
            _refreshScore();
          }),
          _toggle('Open WiFi', 'Connected to unsecured network', Icons.wifi_rounded,
              AppTheme.accentOrange, _openWifi, (v) {
            setState(() => _openWifi = v);
            _refreshScore();
          }),
          Row(children: [
            Icon(Icons.apps_rounded, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sideloaded Apps: $_sideloadedApps', style: AppTheme.bodyM),
              Text('External APK installs', style: AppTheme.bodyS),
            ])),
            Row(children: [
              GestureDetector(
                onTap: () { if (_sideloadedApps > 0) { setState(() => _sideloadedApps--); _refreshScore(); } },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppTheme.bgCardLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.remove_rounded, color: AppTheme.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { setState(() => _sideloadedApps++); _refreshScore(); },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, IconData icon, Color color,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: value ? color : AppTheme.textMuted, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.bodyM.copyWith(color: value ? AppTheme.textPrimary : AppTheme.textSecondary)),
          Text(subtitle, style: AppTheme.bodyS),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged,
            activeColor: color, inactiveTrackColor: AppTheme.borderColor),
      ]),
    );
  }

  Widget _buildRiskFactors() {
    final factors = (_scoreData?['factors'] as List<dynamic>? ?? []);
    if (factors.isEmpty) return const SizedBox();
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.report_problem_rounded, color: AppTheme.accentOrange, size: 18),
            const SizedBox(width: 8),
            Text('RISK FACTORS (${factors.length})', style: AppTheme.labelXS.copyWith(color: AppTheme.accentOrange)),
          ]),
          const SizedBox(height: 12),
          ...factors.map((f) {
            final sev = f['severity'] as String;
            final color = sev == 'critical' ? AppTheme.accentRed
                : sev == 'high' ? AppTheme.accentOrange
                : sev == 'warning' ? AppTheme.accentYellow : AppTheme.textMuted;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.remove_circle_rounded, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(f['factor'] as String, style: AppTheme.bodyM)),
                Text('${f['impact']}', style: AppTheme.mono.copyWith(color: color, fontSize: 13)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(children: [
      Expanded(child: _actionButton('RUN SCAN', Icons.radar_rounded, AppTheme.accentBlue, widget.onStartScan)),
      const SizedBox(width: 12),
      Expanded(child: _actionButton('FLEET DASHBOARD', Icons.devices_rounded, AppTheme.accentPurple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetDashboardScreen()));
      })),
      const SizedBox(width: 12),
      Expanded(child: _actionButton('WIFI AUDIT', Icons.wifi_tethering_error_rounded, AppTheme.accentOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NetworkAuditorScreen()));
      })),
    ]);
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: AppTheme.labelXS.copyWith(color: color, fontSize: 8),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildStatusGrid() {
    final osVersion = _deviceInfo['os_version'] as String? ?? 'Android';
    final isRooted = _deviceInfo['is_rooted'] as bool? ?? false;
    final items = [
      {'label': 'OS Version', 'value': osVersion, 'icon': Icons.android_rounded, 'ok': true},
      {'label': 'Last OS Update', 'value': '12 days ago', 'icon': Icons.update_rounded, 'ok': true},
      {'label': 'Root Status', 'value': isRooted ? 'ROOTED' : 'Not Rooted', 'icon': Icons.lock_rounded, 'ok': !isRooted},
      {'label': 'Dev Mode', 'value': _developerMode ? 'ENABLED' : 'Disabled', 'icon': Icons.developer_mode_rounded, 'ok': !_developerMode},
      {'label': 'Unknown Sources', 'value': _unknownSources ? 'ENABLED' : 'Disabled', 'icon': Icons.source_rounded, 'ok': !_unknownSources},
      {'label': 'Sideloaded Apps', 'value': '$_sideloadedApps apps', 'icon': Icons.install_mobile_rounded, 'ok': _sideloadedApps == 0},
    ];

    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.fact_check_rounded, color: AppTheme.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text('INTEGRITY CHECKLIST', style: AppTheme.labelXS.copyWith(color: AppTheme.accentGreen)),
          ]),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final ok = item['ok'] as bool;
              final color = ok ? AppTheme.accentGreen : AppTheme.accentRed;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ok ? AppTheme.borderColor : color.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(item['icon'] as IconData, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(item['label'] as String, style: AppTheme.labelXS.copyWith(fontSize: 8)),
                    Text(item['value'] as String, style: AppTheme.bodyM.copyWith(fontSize: 12, color: ok ? AppTheme.textSecondary : color)),
                  ])),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Ring painter
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  _RingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    const sw = 12.0;

    final bgPaint = Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final double sweepAngle = 2 * pi * progress;
    if (sweepAngle > 0.001) {
      final fgPaint = Paint()
        ..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withOpacity(0.4), color],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + sweepAngle,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2, sweepAngle, false, fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Screen (Feature 4)
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _bgShield = true;
  bool _liveNotifs = true;
  int _sensitivity = 1;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    final currentUrl = ApiService.customBaseUrl.isNotEmpty
        ? ApiService.customBaseUrl
        : ApiService.baseUrl.replaceAll('/api', '');
    _urlCtrl = TextEditingController(text: currentUrl);
    _urlCtrl.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    ApiService.customBaseUrl = _urlCtrl.text.trim();
  }

  @override
  void dispose() {
    _urlCtrl.removeListener(_onUrlChanged);
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          Container(
            color: AppTheme.bgSecondary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
              Text('SETTINGS', style: AppTheme.headingM),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
            _section('PROTECTION', [
              _settingSwitch('Background Shield', 'Monitor threats in background', Icons.shield_rounded, AppTheme.accentGreen, _bgShield, (v) => setState(() => _bgShield = v)),
              _settingSwitch('Live Notifications', 'Push alerts for new threats', Icons.notifications_rounded, AppTheme.accentBlue, _liveNotifs, (v) => setState(() => _liveNotifs = v)),
            ]),
            const SizedBox(height: 16),
            _section('THREAT SENSITIVITY', [
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Current: ${['Low', 'Medium', 'High'][_sensitivity]}', style: AppTheme.bodyM)),
              Slider(
                value: _sensitivity.toDouble(),
                min: 0, max: 2, divisions: 2,
                activeColor: AppTheme.accentBlue,
                inactiveColor: AppTheme.borderColor,
                onChanged: (v) => setState(() => _sensitivity = v.toInt()),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Low', style: AppTheme.bodyS),
                Text('Medium', style: AppTheme.bodyS),
                Text('High', style: AppTheme.bodyS),
              ]),
            ]),
            const SizedBox(height: 16),
            _section('API CONFIGURATION', [
              TextField(
                controller: _urlCtrl,
                style: AppTheme.mono.copyWith(color: AppTheme.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  labelStyle: AppTheme.labelXS,
                  filled: true,
                  fillColor: AppTheme.bgCardLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.accentBlue)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _section('ABOUT', [
              _infoRow('Version', 'GhostRun v1.2.0'),
              _infoRow('Build', 'prod-2026.06.20'),
              _infoRow('Engine', 'GhostRun AI v4.2'),
              _infoRow('Signatures', '42,817 rules loaded'),
            ]),
          ]))),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
      const SizedBox(height: 14),
      ...children,
    ]));
  }

  Widget _settingSwitch(String title, String sub, IconData icon, Color color, bool val, ValueChanged<bool> cb) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, color: val ? color : AppTheme.textMuted, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.bodyM),
        Text(sub, style: AppTheme.bodyS),
      ])),
      Switch.adaptive(value: val, onChanged: cb, activeColor: color, inactiveTrackColor: AppTheme.borderColor),
    ]));
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Text(label, style: AppTheme.bodyS),
      const Spacer(),
      Text(value, style: AppTheme.mono.copyWith(fontSize: 11)),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Screen (Feature 4)
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = [
      {'label': 'First Report', 'icon': Icons.flag_rounded, 'color': AppTheme.accentBlue},
      {'label': 'Community Guardian', 'icon': Icons.shield_rounded, 'color': AppTheme.accentGreen},
      {'label': 'Threat Hunter', 'icon': Icons.gps_fixed_rounded, 'color': AppTheme.accentOrange},
    ];
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          Container(
            color: AppTheme.bgSecondary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
              Text('PROFILE', style: AppTheme.headingM),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentBlue.withOpacity(0.2),
                border: Border.all(color: AppTheme.accentBlue, width: 2),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.accentBlue, size: 44),
            ),
            const SizedBox(height: 14),
            Text('GhostRun User', style: AppTheme.headingL),
            Text('Security Analyst · Trust Score: 87', style: AppTheme.bodyS.copyWith(color: AppTheme.accentGreen)),
            const SizedBox(height: 24),
            // Stats
            GhostCard(child: Row(children: [
              Expanded(child: _stat('14', 'Scans Run')),
              Expanded(child: _stat('3', 'Threats Reported')),
              Expanded(child: _stat('87', 'Trust Score')),
              Expanded(child: _stat('2', 'Devices')),
            ])),
            const SizedBox(height: 16),
            // Badges
            GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ACHIEVEMENT BADGES', style: AppTheme.labelXS),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: badges.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (b['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (b['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(b['icon'] as IconData, color: b['color'] as Color, size: 16),
                  const SizedBox(width: 6),
                  Text(b['label'] as String, style: AppTheme.labelXS.copyWith(color: b['color'] as Color)),
                ]),
              )).toList()),
            ])),
          ]))),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: GoogleFonts.rajdhani(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      Text(label, style: AppTheme.labelXS.copyWith(fontSize: 9), textAlign: TextAlign.center),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fleet Dashboard Screen (Feature 6)
// ─────────────────────────────────────────────────────────────────────────────
class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});
  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await ApiService.fetchFleetStats();
    final devices = await ApiService.fetchFleetDevices();
    if (mounted) setState(() { _stats = stats; _devices = devices; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          Container(
            color: AppTheme.bgSecondary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CORPORATE FLEET', style: AppTheme.labelXS.copyWith(color: AppTheme.accentPurple)),
                Text('Security Dashboard', style: AppTheme.headingS),
              ]),
              const Spacer(),
              GhostChip(label: 'LIVE', color: AppTheme.accentGreen),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
                : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
                    _buildKPIGrid(),
                    const SizedBox(height: 20),
                    _buildFleetScore(),
                    const SizedBox(height: 20),
                    _buildDeviceList(),
                  ])),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    final kpis = [
      {'label': 'Total Devices', 'value': '${_stats['total_devices'] ?? 0}', 'icon': Icons.devices_rounded, 'color': AppTheme.accentBlue},
      {'label': 'At Risk', 'value': '${_stats['danger_devices'] ?? 0}', 'icon': Icons.gpp_bad_rounded, 'color': AppTheme.accentRed},
      {'label': 'Threat Blocks', 'value': '${_stats['active_threat_blocks'] ?? 0}', 'icon': Icons.block_rounded, 'color': AppTheme.accentOrange},
      {'label': 'WiFi Violations', 'value': '${_stats['wifi_violations'] ?? 0}', 'icon': Icons.wifi_off_rounded, 'color': AppTheme.accentYellow},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.8),
      itemCount: kpis.length,
      itemBuilder: (_, i) {
        final kpi = kpis[i];
        final color = kpi['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(kpi['icon'] as IconData, color: color, size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(kpi['value'] as String, style: GoogleFonts.rajdhani(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1)),
              Text(kpi['label'] as String, style: AppTheme.labelXS.copyWith(fontSize: 9)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildFleetScore() {
    final score = (_stats['fleet_risk_score'] as num?)?.toDouble() ?? 0;
    final color = score >= 80 ? AppTheme.accentGreen : score >= 60 ? AppTheme.accentOrange : AppTheme.accentRed;
    return GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.security_rounded, color: AppTheme.accentPurple, size: 18),
        const SizedBox(width: 8),
        Text('FLEET RISK SCORE', style: AppTheme.labelXS.copyWith(color: AppTheme.accentPurple)),
        const Spacer(),
        Text('${score.toStringAsFixed(1)}/100', style: AppTheme.headingM.copyWith(color: color)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
        value: score / 100, minHeight: 10, backgroundColor: AppTheme.borderColor,
        valueColor: AlwaysStoppedAnimation(color),
      )),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _fleetStat('${_stats['safe_devices'] ?? 0}', 'Safe', AppTheme.accentGreen),
        _fleetStat('${_stats['warning_devices'] ?? 0}', 'Warning', AppTheme.accentOrange),
        _fleetStat('${_stats['danger_devices'] ?? 0}', 'Critical', AppTheme.accentRed),
      ]),
    ]));
  }

  Widget _fleetStat(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: GoogleFonts.rajdhani(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: AppTheme.labelXS.copyWith(color: color, fontSize: 9)),
    ]);
  }

  Widget _buildDeviceList() {
    return GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.smartphone_rounded, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 8),
        Text('MANAGED DEVICES', style: AppTheme.labelXS),
      ]),
      const SizedBox(height: 14),
      ..._devices.map((d) {
        final status = d['status'] as String;
        final riskScore = (d['risk_score'] as num).toInt();
        final statusColor = status == 'safe' ? AppTheme.accentGreen
            : status == 'warning' ? AppTheme.accentOrange : AppTheme.accentRed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.smartphone_rounded, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'] as String, style: AppTheme.headingS.copyWith(fontSize: 14)),
              Text('${d['os']}  •  ${d['last_seen']}', style: AppTheme.bodyS),
            ])),
            SizedBox(
              width: 60,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$riskScore', style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor)),
                Text('SCORE', style: AppTheme.labelXS.copyWith(fontSize: 8)),
              ]),
            ),
          ]),
        );
      }),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Network Auditor Screen (Feature 9)
// ─────────────────────────────────────────────────────────────────────────────
class NetworkAuditorScreen extends StatefulWidget {
  const NetworkAuditorScreen({super.key});
  @override
  State<NetworkAuditorScreen> createState() => _NetworkAuditorScreenState();
}

class _NetworkAuditorScreenState extends State<NetworkAuditorScreen> {
  final _ssidCtrl = TextEditingController(text: 'Scanning...');
  String _encryption = 'WPA2';
  bool _loading = false;
  bool _loadingNetwork = true;
  Map<String, dynamic>? _result;
  Map<String, dynamic> _networkInfo = {};
  int _signalStrength = -65;
  final _encryptions = ['WPA3', 'WPA2', 'WEP', 'Open'];

  @override
  void initState() {
    super.initState();
    _loadRealNetwork();
  }

  Future<void> _loadRealNetwork() async {
    final info = await ApiService.getRealNetworkInfo();
    if (mounted) {
      setState(() {
        _networkInfo = info;
        _loadingNetwork = false;
        final ssid = info['ssid'] as String? ?? '';
        if (ssid.isNotEmpty && ssid != 'Unknown' && ssid != 'Cellular') {
          _ssidCtrl.text = ssid;
        } else {
          _ssidCtrl.text = '';
        }
      });
    }
  }

  @override
  void dispose() { _ssidCtrl.dispose(); super.dispose(); }

  Future<void> _audit() async {
    setState(() { _loading = true; _result = null; });
    final res = await ApiService.auditNetwork({
      'ssid': _ssidCtrl.text,
      'bssid': _networkInfo['bssid'],
      'encryption': _encryption,
      'signal_strength': _signalStrength,
    });
    if (mounted) setState(() { _result = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final verdict = _result?['verdict'] as String?;
    final riskScore = (_result?['risk_score'] as num?)?.toInt() ?? 100;
    final verdictColor = verdict == 'safe' ? AppTheme.accentGreen
        : verdict == 'suspicious' ? AppTheme.accentOrange : AppTheme.accentRed;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          Container(
            color: AppTheme.bgSecondary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WIFI AUDITOR', style: AppTheme.labelXS.copyWith(color: AppTheme.accentOrange)),
                Text('Network Security', style: AppTheme.headingS),
              ]),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
            GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NETWORK PROFILE', style: AppTheme.labelXS),
              const SizedBox(height: 8),
              // Show detected network info
              if (_loadingNetwork)
                const LinearProgressIndicator(color: AppTheme.accentOrange, backgroundColor: AppTheme.bgCardLight)
              else if (_networkInfo['on_wifi'] == true)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.wifi_rounded, color: AppTheme.accentGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Auto-detected: ${_networkInfo['ssid'] ?? 'Unknown'}',
                          style: AppTheme.bodyM.copyWith(color: AppTheme.accentGreen, fontSize: 12)),
                      if (_networkInfo['bssid'] != null && _networkInfo['bssid'] != 'Unknown')
                        Text('BSSID: ${_networkInfo['bssid']}', style: AppTheme.bodyS.copyWith(fontSize: 10)),
                    ])),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(children: [
                    const Icon(Icons.wifi_off_rounded, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Text('Not on Wi-Fi — enter SSID manually',
                        style: AppTheme.bodyS.copyWith(fontSize: 11)),
                  ]),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _ssidCtrl,
                style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary),
                decoration: _inputDec('Network Name (SSID)'),
              ),
              const SizedBox(height: 12),
              // Signal strength slider
              Row(children: [
                const Icon(Icons.signal_cellular_alt_rounded, color: AppTheme.textMuted, size: 16),
                const SizedBox(width: 8),
                Text('Signal Strength: $_signalStrength dBm', style: AppTheme.bodyM),
              ]),
              Slider(
                value: _signalStrength.toDouble(),
                min: -100,
                max: -30,
                divisions: 70,
                activeColor: _signalStrength > -60 ? AppTheme.accentGreen : _signalStrength > -75 ? AppTheme.accentOrange : AppTheme.accentRed,
                inactiveColor: AppTheme.bgCardLight,
                onChanged: (v) => setState(() => _signalStrength = v.toInt()),
              ),
              const SizedBox(height: 4),
              Text('ENCRYPTION TYPE', style: AppTheme.labelXS),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _encryptions.map((e) => GestureDetector(
                onTap: () => setState(() => _encryption = e),
                child: GhostChip(
                  label: e,
                  color: _encryption == e
                      ? (e == 'WPA3' ? AppTheme.accentGreen : e == 'WPA2' ? AppTheme.accentBlue : e == 'WEP' ? AppTheme.accentOrange : AppTheme.accentRed)
                      : AppTheme.textMuted,
                ),
              )).toList()),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loading ? null : _audit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(_loading ? 'AUDITING...' : 'RUN NETWORK AUDIT',
                        style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ])),

            if (_result != null) ...[
              const SizedBox(height: 16),
              // Result card
              GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(
                    verdict == 'safe' ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: verdictColor, size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(_ssidCtrl.text, style: AppTheme.headingS),
                  const Spacer(),
                  GhostChip(label: (verdict ?? '').toUpperCase(), color: verdictColor),
                ]),
                const SizedBox(height: 12),
                Text('Network Score: $riskScore/100',
                    style: AppTheme.headingM.copyWith(color: verdictColor)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                  value: riskScore / 100, minHeight: 6,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation(verdictColor),
                )),
                const SizedBox(height: 12),
                Text(_result!['recommendation'] as String? ?? '', style: AppTheme.bodyM),
              ])),
              if ((_result!['risk_factors'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RISK FLAGS', style: AppTheme.labelXS.copyWith(color: AppTheme.accentOrange)),
                  const SizedBox(height: 12),
                  ...(_result!['risk_factors'] as List).map((f) {
                    final sev = f['severity'] as String;
                    final color = sev == 'critical' ? AppTheme.accentRed : sev == 'warning' ? AppTheme.accentOrange : AppTheme.textMuted;
                    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 4, height: 36, color: color, margin: const EdgeInsets.only(right: 12)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f['flag'] as String, style: AppTheme.headingS.copyWith(fontSize: 14)),
                        Text(f['detail'] as String, style: AppTheme.bodyS),
                      ])),
                    ]));
                  }),
                ])),
              ],
              const SizedBox(height: 12),
              // Network hop graph
              GhostCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NETWORK HOP PATH', style: AppTheme.labelXS),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _hopNode('YOU', Icons.smartphone_rounded, verdictColor),
                  _hopArrow(verdictColor),
                  _hopNode('192.168.1.1', Icons.router_rounded, AppTheme.accentOrange),
                  _hopArrow(AppTheme.accentGreen),
                  _hopNode('ISP', Icons.cable_rounded, AppTheme.accentGreen),
                  _hopArrow(AppTheme.accentGreen),
                  _hopNode('8.8.8.8', Icons.public_rounded, AppTheme.accentGreen),
                ]),
              ])),
            ],
          ]))),
        ],
      ),
    );
  }

  Widget _hopNode(String label, IconData icon, Color color) {
    return Column(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 4),
      Text(label, style: AppTheme.labelXS.copyWith(fontSize: 8), textAlign: TextAlign.center),
    ]);
  }

  Widget _hopArrow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint, hintStyle: AppTheme.bodyS,
    filled: true, fillColor: AppTheme.bgCardLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.accentBlue)),
  );
}
