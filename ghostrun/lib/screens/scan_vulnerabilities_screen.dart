import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class ScanVulnerabilitiesScreen extends StatefulWidget {
  final Function({String? scanId}) onNext;
  const ScanVulnerabilitiesScreen({super.key, required this.onNext});

  @override
  State<ScanVulnerabilitiesScreen> createState() =>
      _ScanVulnerabilitiesScreenState();
}

class _ScanVulnerabilitiesScreenState
    extends State<ScanVulnerabilitiesScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) widget.onNext();
    });
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
                  Text('OPERATION: INFILTRATION', style: AppTheme.labelXS),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: AppTheme.headingXL,
                      children: const [
                        TextSpan(text: 'Hack Mode '),
                        TextSpan(
                          text: 'Active',
                          style: TextStyle(color: AppTheme.accentBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildScanProgress(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text('Detected Vulnerabilities',
                          style: AppTheme.headingS),
                      const Spacer(),
                      Text('RANKED BY SEVERITY',
                          style: AppTheme.labelXS.copyWith(fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _vulnCard(
                    borderColor: AppTheme.accentRed,
                    severity: 'CRITICAL',
                    severityColor: AppTheme.accentRed,
                    node: 'NODE 0X8F',
                    title: 'Unauthorized Root Access Attempt',
                    icon: Icons.warning_rounded,
                    iconBg: AppTheme.accentRed,
                  ),
                  const SizedBox(height: 12),
                  _vulnCard(
                    borderColor: AppTheme.accentOrange,
                    severity: 'SUSPICIOUS',
                    severityColor: AppTheme.accentOrange,
                    node: 'ENCRYPTED TUNNEL',
                    title: 'Abnormal Traffic at Port 443',
                    icon: Icons.fingerprint_rounded,
                    iconBg: AppTheme.accentOrange,
                  ),
                  const SizedBox(height: 12),
                  _vulnCard(
                    borderColor: AppTheme.accentGreen,
                    severity: 'SAFE',
                    severityColor: AppTheme.accentGreen,
                    node: 'INTERNAL BUS',
                    title: 'Firewall Integrity Check Passed',
                    icon: Icons.verified_user_rounded,
                    iconBg: AppTheme.accentGreen,
                  ),
                  const SizedBox(height: 12),
                  _vulnCard(
                    borderColor: AppTheme.accentGreen,
                    severity: 'SAFE',
                    severityColor: AppTheme.accentGreen,
                    node: 'IDENTITY',
                    title: 'Key Rotation Verified',
                    icon: Icons.lock_rounded,
                    iconBg: AppTheme.accentGreen,
                    dimmed: true,
                  ),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildDeepScanButton(),
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

  Widget _buildScanProgress() {
    return GhostCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.track_changes_rounded,
                color: AppTheme.accentBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Deep Scan in Progress',
                  style: AppTheme.bodyM.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w700),
                ),
                Text('Scanning nodes: 8,241 / 10,000',
                    style: AppTheme.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vulnCard({
    required Color borderColor,
    required String severity,
    required Color severityColor,
    required String node,
    required String title,
    required IconData icon,
    required Color iconBg,
    bool dimmed = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: borderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg.withOpacity(dimmed ? 0.08 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          color: dimmed
                              ? iconBg.withOpacity(0.5)
                              : iconBg,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                severity,
                                style: AppTheme.labelXS.copyWith(
                                  color: dimmed
                                      ? severityColor.withOpacity(0.5)
                                      : severityColor,
                                  fontSize: 10,
                                ),
                              ),
                              Text(' • $node',
                                  style: AppTheme.labelXS
                                      .copyWith(fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTheme.headingS.copyWith(
                              fontSize: 16,
                              color: dimmed
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: dimmed
                            ? AppTheme.textDim
                            : AppTheme.textMuted,
                        size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GhostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LATENCY', style: AppTheme.labelXS),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: AppTheme.headingXL.copyWith(fontSize: 40),
                    children: const [
                      TextSpan(text: '14'),
                      TextSpan(
                        text: ' ms',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GhostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHIELD LEVEL', style: AppTheme.labelXS),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: AppTheme.headingXL.copyWith(fontSize: 40),
                    children: const [
                      TextSpan(text: '92'),
                      TextSpan(
                        text: ' %',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeepScanButton() {
    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.accentLavender,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt_rounded,
                color: AppTheme.bgPrimary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Full System Deep Scan',
              style: GoogleFonts.rajdhani(
                color: AppTheme.bgPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
