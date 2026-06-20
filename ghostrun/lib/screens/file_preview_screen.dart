import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';

class FilePreviewScreen extends StatefulWidget {
  final Function({String? fileId})? onStartScan;
  const FilePreviewScreen({super.key, this.onStartScan});

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  int _subTabIndex = 0;
  final _subTabs = ['PREVIEW', 'SANDBOX', 'LOGS', 'SETTINGS'];

  bool _isUploading = false;
  bool _hasResult = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _inspectionResult;

  Future<void> _pickAndInspect() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() {
        _isUploading = true;
        _hasResult = false;
        _uploadProgress = 0.0;
        _inspectionResult = null;
      });

      // Animate progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) setState(() => _uploadProgress = i / 10.0);
      }

      final result2 = await ApiService.inspectFile(
          Uint8List.fromList(bytes), file.name);

      if (mounted) {
        setState(() {
          _isUploading = false;
          _hasResult = true;
          _inspectionResult = result2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    }
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
                  const SizedBox(height: 20),
                  _buildUploadZone(),
                  const SizedBox(height: 20),
                  if (_hasResult && _inspectionResult != null) ...[
                    _buildResultHeader(),
                    const SizedBox(height: 14),
                    _buildHashCard(),
                    const SizedBox(height: 14),
                    _buildPermissionsCard(),
                    const SizedBox(height: 14),
                    _buildComponentsCard(),
                    const SizedBox(height: 14),
                    _buildRiskAnalysisCard(),
                    const SizedBox(height: 20),
                    _buildScanButton(),
                    const SizedBox(height: 24),
                  ] else if (!_isUploading) ...[
                    _buildStaticPreview(),
                    const SizedBox(height: 24),
                  ],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FILE INSPECTOR', style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
        const SizedBox(height: 6),
        Text('Binary &\nAPK Analysis', style: AppTheme.headingXL.copyWith(fontSize: 32)),
        const SizedBox(height: 4),
        Text('Upload any file to inspect permissions, hashes, and risk indicators.',
            style: AppTheme.bodyS),
      ],
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndInspect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isUploading ? AppTheme.accentBlue : AppTheme.borderLight,
            width: _isUploading ? 2 : 1,
          ),
        ),
        child: _isUploading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('UPLOADING & ANALYZING...', style: AppTheme.labelXS.copyWith(color: AppTheme.accentBlue)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.accentBlue),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(_uploadProgress * 100).toInt()}%',
                      style: AppTheme.mono.copyWith(color: AppTheme.accentBlue)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: AppTheme.accentBlue, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text('Tap to Upload File', style: AppTheme.headingS),
                  const SizedBox(height: 4),
                  Text('APK, EXE, PDF, ZIP, or any binary', style: AppTheme.bodyS),
                ],
              ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final r = _inspectionResult!;
    final verdict = r['verdict'] ?? 'unknown';
    final score = (r['risk_score'] ?? 0.0).toDouble();
    final verdictColor = verdict == 'safe'
        ? AppTheme.accentGreen
        : verdict == 'suspicious'
            ? AppTheme.accentOrange
            : AppTheme.accentRed;
    return GhostCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: verdictColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              verdict == 'safe' ? Icons.verified_user_rounded : Icons.warning_rounded,
              color: verdictColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GhostChip(
                        label: (r['file_type'] ?? 'FILE').toString(),
                        color: AppTheme.accentBlue),
                    const SizedBox(width: 8),
                    GhostChip(label: verdict.toUpperCase(), color: verdictColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r['filename'] ?? 'Unknown File',
                  style: AppTheme.headingS.copyWith(fontSize: 16),
                ),
                Text(
                  '${((r['file_size'] ?? 0) / 1024).toStringAsFixed(1)} KB  •  Risk Score: ${score.toStringAsFixed(1)}/100',
                  style: AppTheme.bodyS,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashCard() {
    final hashes = _inspectionResult!['hashes'] as Map<String, dynamic>? ?? {};
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.fingerprint_rounded, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('CRYPTOGRAPHIC HASHES', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 14),
          ...hashes.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(e.key.toUpperCase(),
                          style: AppTheme.labelXS.copyWith(fontSize: 9)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: AppTheme.mono.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final perms = (_inspectionResult!['permissions'] as List<dynamic>? ?? [])
        .map((e) => e.toString().replaceFirst('android.permission.', ''))
        .toList();
    final dangerousPerms = {
      'READ_CONTACTS', 'READ_SMS', 'SEND_SMS', 'RECORD_AUDIO', 'CAMERA',
      'ACCESS_FINE_LOCATION', 'READ_CALL_LOG', 'RECEIVE_BOOT_COMPLETED',
      'SYSTEM_ALERT_WINDOW', 'WRITE_EXTERNAL_STORAGE'
    };
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.key_rounded, color: AppTheme.textMuted, size: 18),
            const SizedBox(width: 8),
            Text('REQUESTED PERMISSIONS (${perms.length})', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 14),
          if (perms.isEmpty)
            Text('No permissions declared', style: AppTheme.bodyS)
          else
            ...perms.map((p) {
              final isDangerous = dangerousPerms.contains(p);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDangerous ? AppTheme.accentOrange : AppTheme.accentGreen,
                      ),
                    ),
                    Expanded(
                      child: Text(p,
                          style: AppTheme.bodyM.copyWith(
                              color: isDangerous
                                  ? AppTheme.accentOrange
                                  : AppTheme.textSecondary)),
                    ),
                    if (isDangerous)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('DANGER',
                            style: AppTheme.labelXS.copyWith(
                                color: AppTheme.accentOrange, fontSize: 8)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildComponentsCard() {
    final r = _inspectionResult!;
    final activities = r['activities'] as List<dynamic>? ?? [];
    final services = r['services'] as List<dynamic>? ?? [];
    final receivers = r['receivers'] as List<dynamic>? ?? [];
    final providers = r['providers'] as List<dynamic>? ?? [];

    if (activities.isEmpty && services.isEmpty) return const SizedBox();

    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.device_hub_rounded, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('APK COMPONENT TREE', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 14),
          if (activities.isNotEmpty)
            _componentSection('Activities', activities, Icons.window_rounded, AppTheme.accentBlue),
          if (services.isNotEmpty)
            _componentSection('Services', services, Icons.settings_applications_rounded, AppTheme.accentOrange),
          if (receivers.isNotEmpty)
            _componentSection('Receivers', receivers, Icons.radio_rounded, AppTheme.accentRed),
          if (providers.isNotEmpty)
            _componentSection('Providers', providers, Icons.storage_rounded, AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _componentSection(String name, List<dynamic> items, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text('$name (${items.length})',
                style: AppTheme.labelXS.copyWith(color: color, fontSize: 10)),
          ]),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 3),
                child: Text('• $item',
                    style: AppTheme.mono.copyWith(fontSize: 11)),
              )),
        ],
      ),
    );
  }

  Widget _buildRiskAnalysisCard() {
    final score = (_inspectionResult!['risk_score'] ?? 0.0).toDouble();
    final verdict = _inspectionResult!['verdict'] ?? 'unknown';
    final verdictColor = verdict == 'safe'
        ? AppTheme.accentGreen
        : verdict == 'suspicious' ? AppTheme.accentOrange : AppTheme.accentRed;
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('RISK ANALYSIS', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTheme.headingXL.copyWith(fontSize: 42),
              children: [
                TextSpan(
                    text: verdict[0].toUpperCase() + verdict.substring(1),
                    style: TextStyle(color: verdictColor)),
                TextSpan(
                  text: '  ${score.toStringAsFixed(1)}/100',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: AppTheme.borderColor,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [verdictColor.withOpacity(0.7), verdictColor],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final fileId = _inspectionResult?['file_id'] as String?;
    return GestureDetector(
      onTap: () {
        if (widget.onStartScan != null) {
          widget.onStartScan!(fileId: fileId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Starting scan with uploaded file...'),
              backgroundColor: AppTheme.accentBlue,
            ),
          );
        }
      },
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
            const Icon(Icons.rocket_launch_rounded, color: AppTheme.bgPrimary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Run Full Scan on This File',
              style: GoogleFonts.rajdhani(
                color: AppTheme.bgPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticPreview() {
    return GhostCard(
      color: AppTheme.bgCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostChip(label: 'DEMO MODE', color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text('SecurePass.apk', style: AppTheme.headingM.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Text('Upload a real file above to run a live inspection, or continue browsing the demo.',
              style: AppTheme.bodyS),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.shield_outlined, color: AppTheme.accentBlue, size: 14),
            const SizedBox(width: 6),
            Text('Risk Score: 98.2 / 100  •  Safe', style: AppTheme.bodyS.copyWith(color: AppTheme.accentGreen)),
          ]),
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
                          color: sel ? AppTheme.accentBlue : AppTheme.textMuted,
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
