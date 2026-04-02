import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../widgets/radar_widget.dart';

class StatusScreen extends StatelessWidget {
  final VoidCallback onStartScan;

  const StatusScreen({super.key, required this.onStartScan});

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
                  const SizedBox(height: 32),
                  _buildScanButton(),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'LAST SCAN: 14 MINUTES AGO',
                      style: AppTheme.labelXS,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRecentScans(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildActiveThreats()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildCommunityAlerts()),
                    ],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SYSTEM OVERVIEW', style: AppTheme.labelXS),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTheme.headingL.copyWith(fontSize: 32),
            children: const [
              TextSpan(text: 'Hello, '),
              TextSpan(
                text: 'Alex.',
                style: TextStyle(color: AppTheme.accentBlue),
              ),
            ],
          ),
        ),
        Text(
          'Your device is safe',
          style: AppTheme.headingL.copyWith(
            color: AppTheme.accentBlue,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return Center(
      child: GestureDetector(
        onTap: onStartScan,
        child: const RadarWidget(
          size: 210,
          isScanning: false,
          showScanText: true,
        ),
      ),
    );
  }

  Widget _buildRecentScans() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Scans', style: AppTheme.headingS),
              const Spacer(),
              Icon(Icons.history_rounded,
                  color: AppTheme.accentBlue, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _scanRow(
            icon: Icons.shield_outlined,
            title: 'Full System Audit',
            subtitle: 'Completed • 2:14 PM',
            status: 'SECURE',
          ),
          const SizedBox(height: 12),
          _scanRow(
            icon: Icons.folder_open_rounded,
            title: 'Deep File Inspection',
            subtitle: 'Completed • Yesterday',
            status: 'SECURE',
          ),
        ],
      ),
    );
  }

  Widget _scanRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTheme.bodyM.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTheme.bodyS),
            ],
          ),
        ),
        GhostChip(label: status, color: AppTheme.accentGreen),
      ],
    );
  }

  Widget _buildActiveThreats() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Active\nThreats',
                  style: AppTheme.headingS.copyWith(fontSize: 16)),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgCardLight,
                ),
                child: Center(
                  child: Text('0',
                      style: AppTheme.bodyS.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.shield, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 6),
              Text('SHIELD ACTIVE',
                  style: AppTheme.labelXS
                      .copyWith(color: AppTheme.accentBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityAlerts() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Community\nAlerts',
                  style: AppTheme.headingS.copyWith(fontSize: 16)),
              const Spacer(),
              Icon(Icons.notifications_outlined,
                  color: AppTheme.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            height: 3,
            color: AppTheme.borderColor,
            margin: const EdgeInsets.only(top: 0),
          ),
          const SizedBox(height: 8),
          Text('2 NEW GLOBAL TRENDS',
              style: AppTheme.labelXS.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
