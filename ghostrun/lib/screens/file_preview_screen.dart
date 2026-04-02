import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';

class FilePreviewScreen extends StatefulWidget {
  const FilePreviewScreen({super.key});

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  int _subTabIndex = 0;
  final _subTabs = ['PREVIEW', 'SANDBOX', 'LOGS', 'SETTINGS'];

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
                  _buildFileHeader(),
                  const SizedBox(height: 24),
                  _buildSandboxPreview(),
                  const SizedBox(height: 20),
                  _buildAppPurpose(),
                  const SizedBox(height: 14),
                  _buildPermissions(),
                  const SizedBox(height: 14),
                  _buildRiskAnalysis(),
                  const SizedBox(height: 24),
                  _buildRunScanButton(),
                  const SizedBox(height: 12),
                  _buildInstallButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildSubTabBar(),
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
            width: 34,
            height: 34,
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

  Widget _buildFileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GhostChip(label: 'ANDROID PACKAGE', color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            Text('V2.4.1', style: AppTheme.labelXS),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SecurePass.apk',
          style: AppTheme.headingXL.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.verified_user_outlined,
                color: AppTheme.accentBlue, size: 16),
            const SizedBox(width: 6),
            Text('Verified Source Fragment', style: AppTheme.bodyS),
          ],
        ),
      ],
    );
  }

  Widget _buildSandboxPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('SANDBOX PREVIEW',
                style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
            const Spacer(),
            _navArrow(icon: Icons.chevron_left_rounded),
            const SizedBox(width: 8),
            _navArrow(icon: Icons.chevron_right_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Phone mockup
              Container(
                width: 120,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1B2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A3A55), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0A2040), Color(0xFF051020)],
                      ),
                    ),
                  ),
                ),
              ),
              // Second phone peek
              Positioned(
                right: 16,
                child: Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    width: 90,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF080F1C),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFF1A2840), width: 2),
                    ),
                  ),
                ),
              ),
              // Label chip
              Positioned(
                top: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      Text('CAPTURED IN SANDBOX',
                          style: AppTheme.labelXS.copyWith(fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navArrow({required IconData icon}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Icon(icon, color: AppTheme.textMuted, size: 18),
    );
  }

  Widget _buildAppPurpose() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.terminal_rounded, color: AppTheme.accentBlue, size: 20),
          const SizedBox(height: 8),
          Text('APP PURPOSE', style: AppTheme.labelXS),
          const SizedBox(height: 4),
          Text('Password Management', style: AppTheme.headingS),
          const SizedBox(height: 6),
          Text(
            'Detected core functionality: Credential encryption, cloud synchronization, local vault storage.',
            style: AppTheme.bodyS,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key_rounded, color: AppTheme.textMuted, size: 20),
          const SizedBox(height: 8),
          Text('REQUESTED PERMISSIONS', style: AppTheme.labelXS),
          const SizedBox(height: 10),
          _permRow('Contacts'),
          _permRow('Storage Access'),
          _permRow('Network State', dimmed: true),
        ],
      ),
    );
  }

  Widget _permRow(String label, {bool dimmed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dimmed ? AppTheme.textDim : AppTheme.textSecondary,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodyM.copyWith(
              color:
                  dimmed ? AppTheme.textMuted : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAnalysis() {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.accentBlue, size: 20),
          const SizedBox(height: 8),
          Text('RISK ANALYSIS', style: AppTheme.labelXS),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: AppTheme.headingXL.copyWith(fontSize: 38),
              children: const [
                TextSpan(text: 'Low'),
                TextSpan(
                  text: '  98.2% Safe',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppTheme.borderColor,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.982,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentGreen],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 2,
            color: AppTheme.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildRunScanButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.accentLavender,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch_rounded,
              color: AppTheme.bgPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            'Run Full Scan',
            style: GoogleFonts.rajdhani(
              color: AppTheme.bgPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Install Anyway',
            style: GoogleFonts.rajdhani(
              color: AppTheme.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_subTabs.length, (i) {
              final sel = i == _subTabIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _subTabIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _subTabs[i],
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: sel
                              ? AppTheme.accentBlue
                              : AppTheme.textMuted,
                        ),
                      ),
                      if (sel)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 2,
                          color: AppTheme.accentBlue,
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
