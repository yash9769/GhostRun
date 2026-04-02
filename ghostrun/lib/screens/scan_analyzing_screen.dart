import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../widgets/radar_widget.dart';

class ScanAnalyzingScreen extends StatefulWidget {
  final VoidCallback onNext;

  const ScanAnalyzingScreen({super.key, required this.onNext});

  @override
  State<ScanAnalyzingScreen> createState() => _ScanAnalyzingScreenState();
}

class _ScanAnalyzingScreenState extends State<ScanAnalyzingScreen> {
  int _stepIndex = 0; // 0=integrity, 1=signatures, 2=heuristics

  final List<Map<String, dynamic>> _logs = [
    {'time': '14:22:01', 'msg': 'Unpacking packet headers... OK'},
    {'time': '14:22:03', 'msg': 'Cross-referencing global\ndatabase...'},
    {'time': '14:22:05', 'msg': 'Comparing signature SHA-256:\n8f3a...11e'},
    {'time': '14:22:08', 'msg': 'Initiating heuristic pattern\nrecognition', 'dot': true},
  ];

  @override
  void initState() {
    super.initState();
    _autoAdvance();
  }

  void _autoAdvance() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _stepIndex = 1);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _stepIndex = 2);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const RadarWidget(size: 220, isScanning: true),
                  const SizedBox(height: 36),
                  Text(
                    'Analyzing file in secure\nsandbox',
                    style: AppTheme.headingM.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SYSTEM THREAT LEVEL: NEUTRAL',
                        style: AppTheme.labelXS,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  _buildStepProgress(),
                  const SizedBox(height: 28),
                  _buildActivityLog(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.bgCardLight,
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Icon(Icons.person, color: AppTheme.textMuted, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            'GHOSTRUN',
            style: GoogleFonts.rajdhani(
              color: AppTheme.accentBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          const Icon(Icons.settings, color: AppTheme.textMuted, size: 24),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    final steps = [
      {'label': 'INTEGRITY', 'icon': Icons.check_rounded},
      {'label': 'SIGNATURES', 'icon': Icons.fingerprint_rounded},
      {'label': 'HEURISTICS', 'icon': Icons.psychology_outlined},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final done = i < _stepIndex;
        final active = i == _stepIndex;
        final color = done || active ? AppTheme.accentBlue : AppTheme.textMuted;

        return Row(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (done || active)
                        ? AppTheme.accentBlue.withOpacity(active ? 1.0 : 0.3)
                        : AppTheme.bgCard,
                    border: Border.all(
                      color: (done || active)
                          ? AppTheme.accentBlue
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    steps[i]['icon'] as IconData,
                    color: (done || active) ? Colors.white : AppTheme.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i]['label'] as String,
                  style: AppTheme.labelXS.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Container(
                width: 40,
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 28),
                color: i < _stepIndex ? AppTheme.accentBlue : AppTheme.borderColor,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildActivityLog() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LIVE ACTIVITY LOG',
                style: AppTheme.labelXS.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Text('SESSION_ID: GH-0922', style: AppTheme.monoMuted),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_logs.length, (i) {
            final log = _logs[i];
            final hasDot = log['dot'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDot)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  Text(
                    '[${log['time']}]',
                    style: AppTheme.monoMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      log['msg'] as String,
                      style: AppTheme.mono,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
