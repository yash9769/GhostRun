import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

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
                  const SizedBox(height: 16),
                  _buildGlobalStatusCard(),
                  const SizedBox(height: 28),
                  _buildTrendingHeader(),
                  const SizedBox(height: 16),
                  _threatCard(
                    icon: Icons.sms_rounded,
                    iconBg: AppTheme.accentBlue.withOpacity(0.15),
                    iconColor: AppTheme.accentBlue,
                    badge: 'CRITICAL',
                    badgeColor: AppTheme.accentRed,
                    title: 'Phishing SMS Alert',
                    body:
                        'Fake package delivery links targeting 415/650 area codes. Do not click short URLs from unknown senders.',
                    location: 'San Francisco, CA',
                    timeAgo: '2M AGO',
                  ),
                  const SizedBox(height: 14),
                  _threatCard(
                    icon: Icons.wifi_rounded,
                    iconBg: AppTheme.accentBlue.withOpacity(0.12),
                    iconColor: AppTheme.accentBluePale,
                    badge: 'ACTIVE',
                    badgeColor: AppTheme.accentGreen,
                    title: 'Evil Twin WiFi',
                    body:
                        'Unsecured network named "Free_SF_Public" detected near Union Square. Man-in-the-middle risk high.',
                    location: 'Union Square',
                    timeAgo: '14M AGO',
                  ),
                  const SizedBox(height: 14),
                  _threatCard(
                    icon: Icons.qr_code_rounded,
                    iconBg: AppTheme.accentOrange.withOpacity(0.12),
                    iconColor: AppTheme.accentOrange,
                    badge: 'WARNING',
                    badgeColor: AppTheme.accentOrange,
                    title: 'Malicious QR Codes',
                    body:
                        'Tampered parking meter stickers found on Embarcadero. Leads to fraudulent payment gateway.',
                    location: 'The Embarcadero',
                    timeAgo: '1H AGO',
                  ),
                  const SizedBox(height: 28),
                  _buildCommunityPower(),
                  const SizedBox(height: 28),
                  _buildTrustScore(),
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

  Widget _buildGlobalStatusCard() {
    return GhostCard(
      color: AppTheme.bgCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GLOBAL STATUS', style: AppTheme.labelXS),
          const SizedBox(height: 6),
          Text('Active Shield', style: AppTheme.headingM),
          const SizedBox(height: 6),
          Text(
            '1,402 threats neutralized in the last 24\nhours across your sector.',
            style: AppTheme.bodyS,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text('SAN FRANCISCO (YOU)',
                    style: AppTheme.labelXS.copyWith(color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentRed,
                  ),
                ),
                Text('HIGH ALERT: SECTOR 7',
                    style: AppTheme.labelXS.copyWith(color: AppTheme.accentRed)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trending Nearby', style: AppTheme.headingS),
              const SizedBox(height: 4),
              Text(
                'Real-time alerts based on community\nreports in San Francisco.',
                style: AppTheme.bodyS,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('View All',
                  style: AppTheme.bodyS.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600)),
              Text('Alerts',
                  style: AppTheme.bodyS.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _threatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String body,
    required String location,
    required String timeAgo,
  }) {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              GhostChip(label: badge, color: badgeColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTheme.headingS),
          const SizedBox(height: 8),
          Text(body, style: AppTheme.bodyM),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(location, style: AppTheme.bodyS),
              const Spacer(),
              Text(timeAgo, style: AppTheme.bodyS),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPower() {
    return GhostCard(
      color: AppTheme.bgCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GhostRun', style: AppTheme.headingM),
          Text('Community Power', style: AppTheme.headingM),
          const SizedBox(height: 12),
          Text(
            'Every time you ignore a scam call or report a suspicious link, you protect thousands of others in the GhostRun network. Our mesh-grid analysis is 40% more accurate thanks to your local reports.',
            style: AppTheme.bodyM,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Center(
                    child: Text(
                      'Report A\nThreat',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Center(
                    child: Text(
                      'Learn\nMore',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustScore() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue.withOpacity(0.15),
              border:
                  Border.all(color: AppTheme.accentBlue.withOpacity(0.4), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_rounded,
                    color: AppTheme.accentBlue, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Trust Score: 9.8',
              style: AppTheme.headingS.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            'Your contributions have secured 45 devices\nin the last month.',
            style: AppTheme.bodyS,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
