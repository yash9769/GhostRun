import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class NewsScreen extends StatelessWidget {
  final VoidCallback? onViewAll;
  const NewsScreen({super.key, this.onViewAll});

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
                  Text('INTELLIGENCE FEED', style: AppTheme.labelXS),
                  const SizedBox(height: 8),
                  Text('Stay Two Steps', style: AppTheme.headingL),
                  Text(
                    'Ahead of Scams.',
                    style: AppTheme.headingL.copyWith(color: AppTheme.accentBlue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clear, actionable insights to protect your digital identity every single day.',
                    style: AppTheme.bodyM,
                  ),
                  const SizedBox(height: 24),
                  _articleCard(
                    icon: Icons.record_voice_over_rounded,
                    iconBg: AppTheme.accentBlue.withOpacity(0.15),
                    iconColor: AppTheme.accentBlue,
                    tag: 'NEW THREAT',
                    tagColor: AppTheme.accentBlue,
                    title: 'Deepfake Voice Scams',
                    body:
                        'Scammers use AI to mimic the voice of a loved one or boss. If you receive an urgent call for money, hang up and call them back on their known number to verify.',
                    footer: 'LEARN MORE →',
                    isLearnMore: true,
                  ),
                  const SizedBox(height: 14),
                  _articleCard(
                    icon: Icons.link_off_rounded,
                    iconBg: AppTheme.accentOrange.withOpacity(0.15),
                    iconColor: AppTheme.accentOrange,
                    tag: '',
                    title: 'The "Package Pending" Text',
                    body:
                        'A classic trick where you get a text about a failed delivery. Never click the link to "re-schedule." Official couriers will never ask for personal info via text links.',
                    footer: '2 DAYS AGO',
                    isLearnMore: false,
                  ),
                  const SizedBox(height: 14),
                  _articleCard(
                    icon: Icons.qr_code_rounded,
                    iconBg: AppTheme.accentBlueDim.withOpacity(0.2),
                    iconColor: AppTheme.accentBluePale,
                    tag: '',
                    title: 'Quishing',
                    body:
                        'Fake QR codes at restaurants or parking meters that lead to stolen credit card forms.',
                    footer: '',
                    isLearnMore: false,
                  ),
                  const SizedBox(height: 14),
                  _articleCard(
                    icon: Icons.warning_amber_rounded,
                    iconBg: AppTheme.accentRed.withOpacity(0.15),
                    iconColor: AppTheme.accentRed,
                    tag: '',
                    title: 'Urgent Update',
                    body:
                        'Avoid pop-ups claiming your "System is Infected." Close the browser tab immediately.',
                    footer: '',
                    isLearnMore: false,
                  ),
                  const SizedBox(height: 14),
                  _articleCard(
                    icon: Icons.fingerprint_rounded,
                    iconBg: AppTheme.accentBlue.withOpacity(0.1),
                    iconColor: AppTheme.accentBlue,
                    tag: '',
                    title: '2FA Social Engineering',
                    body:
                        'If someone asks for a code that was just sent to your phone, it\'s a scam. No legitimate company will ever ask for your security codes.',
                    footer: '',
                    isLearnMore: false,
                    proTip:
                        'Switch from SMS codes to an Authenticator app for maximum safety.',
                  ),
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

  Widget _articleCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String tag,
    Color tagColor = AppTheme.accentBlue,
    required String title,
    required String body,
    required String footer,
    bool isLearnMore = false,
    String proTip = '',
  }) {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              if (tag.isNotEmpty) GhostChip(label: tag, color: tagColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTheme.headingS),
          const SizedBox(height: 8),
          Text(body, style: AppTheme.bodyM),
          if (proTip.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRO TIP', style: AppTheme.labelXS),
                  const SizedBox(height: 4),
                  Text(proTip, style: AppTheme.bodyS),
                ],
              ),
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              footer,
              style: isLearnMore
                  ? AppTheme.bodyS.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w700,
                    )
                  : AppTheme.bodyS,
            ),
          ],
        ],
      ),
    );
  }
}
