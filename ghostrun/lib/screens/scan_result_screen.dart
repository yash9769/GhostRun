import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class ScanResultScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ScanResultScreen({super.key, required this.onDone});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
                children: [
                  const SizedBox(height: 40),
                  _buildSafeIndicator(),
                  const SizedBox(height: 28),
                  Text('Analysis Complete',
                      style: AppTheme.headingM.copyWith(fontSize: 24)),
                  const SizedBox(height: 10),
                  Text(
                    'GhostRun has verified the binary. No malicious\nbehavior or suspicious data exfiltration\ndetected.',
                    style: AppTheme.bodyM,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildRiskAssessment(),
                  const SizedBox(height: 16),
                  _buildNetworkActivity(),
                  const SizedBox(height: 16),
                  _buildPermissions(),
                  const SizedBox(height: 24),
                  _buildDoneButton(),
                  const SizedBox(height: 12),
                  _buildLearnMoreButton(),
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

  Widget _buildSafeIndicator() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.2), width: 2),
              ),
            ),
            // Middle ring
            Container(
              width: 158,
              height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.35), width: 2),
              ),
            ),
            // Inner filled circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGreen.withOpacity(0.15),
                border: Border.all(
                    color: AppTheme.accentGreen, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.accentGreen, size: 44),
            ),
            // "Safe" label
            Positioned(
              bottom: 28,
              child: Text(
                'Safe',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.accentGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessment() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RISK ASSESSMENT', style: AppTheme.labelXS),
          const SizedBox(height: 8),
          Text('Minimal', style: AppTheme.headingM),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: 0.12,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('12%',
                style: AppTheme.bodyS.copyWith(color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkActivity() {
    final bars = [0.4, 0.6, 0.8, 0.5, 0.9, 0.3, 0.6, 0.7, 0.4, 0.5];
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('NETWORK ACTIVITY', style: AppTheme.labelXS),
              const Spacer(),
              Icon(Icons.language_rounded, color: AppTheme.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text('Idle', style: AppTheme.headingM),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((h) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 50 * h,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions() {
    final perms = [
      {'label': 'Read-Only FS', 'icon': Icons.folder_outlined},
      {'label': 'System Profiling', 'icon': Icons.settings_applications_outlined},
      {'label': 'Camera (Denied)', 'icon': Icons.no_photography_outlined},
      {'label': 'Contacts (Denied)', 'icon': Icons.person_off_outlined},
    ];
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERMISSIONS OVERVIEW', style: AppTheme.labelXS),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: perms.map((p) {
              final isDenied = (p['label'] as String).contains('Denied');
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      size: 15,
                      color: isDenied
                          ? AppTheme.textMuted
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p['label'] as String,
                      style: AppTheme.bodyS.copyWith(
                        color: isDenied
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.accentLavender,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'Done',
            style: GoogleFonts.rajdhani(
              color: AppTheme.bgPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnMoreButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Center(
        child: Text(
          'Learn More',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
