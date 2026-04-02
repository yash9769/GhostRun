import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class ScanSandboxScreen extends StatefulWidget {
  final VoidCallback onNext;
  const ScanSandboxScreen({super.key, required this.onNext});

  @override
  State<ScanSandboxScreen> createState() => _ScanSandboxScreenState();
}

class _ScanSandboxScreenState extends State<ScanSandboxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  double _timelineValue = 0.55;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Auto-advance after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStatusBar(),
                  const SizedBox(height: 20),
                  _buildPhoneMockup(),
                  const SizedBox(height: 24),
                  _buildBehaviorLogs(),
                  const SizedBox(height: 16),
                  _buildNetworkActivity(),
                  const SizedBox(height: 16),
                  _buildBehaviorTimeline(),
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
          Icon(Icons.security, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 8),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.bgCard,
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Icon(Icons.person, color: AppTheme.textMuted, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Running in Ghost', style: AppTheme.headingL.copyWith(fontSize: 30)),
        Text('Environment', style: AppTheme.headingL.copyWith(fontSize: 30)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.flag_outlined, color: AppTheme.accentBlue, size: 14),
            const SizedBox(width: 6),
            Text('RUNNING IN ISOLATION',
                style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 10),
          Text('Analyzing...',
              style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPhoneMockup() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone frame
          Container(
            width: 100,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (_, __) => Container(
                    height: 2,
                    margin: EdgeInsets.only(
                      top: _scanLineController.value * 140,
                    ),
                    color: AppTheme.accentBlue.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Scan icon overlay
          Positioned(
            bottom: 28,
            child: Column(
              children: [
                Text('LIVE STREAM DATA...',
                    style: AppTheme.labelXS.copyWith(fontSize: 9)),
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.accentBlue, width: 2),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorLogs() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppTheme.accentBlue, size: 18),
              const SizedBox(width: 8),
              Text('Behavior Logs', style: AppTheme.headingS),
            ],
          ),
          const SizedBox(height: 16),
          _behaviorRow(
            icon: Icons.folder_open_rounded,
            iconColor: AppTheme.accentBlue,
            label: 'FILE ACCESS',
            value: '142 calls',
            dotColor: AppTheme.accentBlue,
          ),
          const Divider(color: AppTheme.borderColor, height: 24),
          _behaviorRow(
            icon: Icons.no_photography_rounded,
            iconColor: AppTheme.accentRed,
            label: 'CAMERA/MIC',
            value: 'Blocked',
            dotColor: AppTheme.accentRed,
          ),
          const Divider(color: AppTheme.borderColor, height: 24),
          _behaviorRow(
            icon: Icons.timelapse_rounded,
            iconColor: AppTheme.accentOrange,
            label: 'BACKGROUND',
            value: 'High',
            valueSuffix: ' cpu',
            dotColor: AppTheme.accentOrange,
          ),
        ],
      ),
    );
  }

  Widget _behaviorRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String valueSuffix = '',
    required Color dotColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelXS),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: AppTheme.headingS.copyWith(fontSize: 20),
                  children: [
                    TextSpan(text: value),
                    if (valueSuffix.isNotEmpty)
                      TextSpan(
                        text: valueSuffix,
                        style: AppTheme.bodyS,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkActivity() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Network\nActivity', style: AppTheme.headingS),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ACTIVE SOCKETS:', style: AppTheme.labelXS),
                  Text('04',
                      style: AppTheme.bodyM.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _networkRow(
            icon: Icons.language_rounded,
            iconColor: AppTheme.accentBlue,
            domain: 'api-cluster-\n09.cdn.io',
            subtitle: 'Encrypted (TLS 1.3)',
            subtitleColor: AppTheme.textMuted,
            speed: '12.4\nKB/s',
            location: 'DE',
            speedColor: AppTheme.textPrimary,
          ),
          const Divider(color: AppTheme.borderColor, height: 20),
          _networkRow(
            icon: Icons.language_rounded,
            iconColor: AppTheme.accentRed,
            domain: 'malicious-\nsinkhole.net',
            subtitle: 'Intercepted Request',
            subtitleColor: AppTheme.accentRed,
            speed: '0.0\nKB/s',
            location: 'RU',
            speedColor: AppTheme.accentRed,
          ),
          const Divider(color: AppTheme.borderColor, height: 20),
          _networkRow(
            icon: Icons.language_rounded,
            iconColor: AppTheme.accentBlue,
            domain: 'telemetry.ghostrun\n.com',
            subtitle: 'Local Proxy',
            subtitleColor: AppTheme.textMuted,
            speed: '2.1\nKB/s',
            location: 'US',
            speedColor: AppTheme.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _networkRow({
    required IconData icon,
    required Color iconColor,
    required String domain,
    required String subtitle,
    required Color subtitleColor,
    required String speed,
    required String location,
    required Color speedColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(domain,
                  style: AppTheme.bodyM.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: AppTheme.bodyS.copyWith(color: subtitleColor)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(speed,
                style: AppTheme.mono.copyWith(color: speedColor),
                textAlign: TextAlign.right),
            Text('LOCATION:\n$location',
                style: AppTheme.monoMuted, textAlign: TextAlign.right),
          ],
        ),
      ],
    );
  }

  Widget _buildBehaviorTimeline() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Behavior\nTimeline', style: AppTheme.headingS),
              const Spacer(),
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.textMuted)),
                const SizedBox(width: 4),
                Text('NORMAL', style: AppTheme.labelXS),
                const SizedBox(width: 12),
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.accentRed)),
                const SizedBox(width: 4),
                Text('MALICIOUS', style: AppTheme.labelXS),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbColor: AppTheme.accentBlue,
              activeTrackColor: AppTheme.accentBlue,
              inactiveTrackColor: AppTheme.borderColor,
              overlayColor: AppTheme.accentBlue.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _timelineValue,
              onChanged: (v) => setState(() => _timelineValue = v),
            ),
          ),
          Row(
            children: [
              Text('00:00:0000', style: AppTheme.monoMuted),
              const Spacer(),
              Text('00:45:0001', style: AppTheme.monoMuted),
            ],
          ),
        ],
      ),
    );
  }
}
