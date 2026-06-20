import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';

class ScanResultScreen extends StatefulWidget {
  final VoidCallback onDone;
  final String? scanId;

  const ScanResultScreen({super.key, required this.onDone, this.scanId});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  Map<String, dynamic>? _scan;
  Map<String, dynamic>? _aiAnalysis;
  bool _loading = true;
  bool _showMitre = false;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    _loadResults();
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    if (widget.scanId != null) {
      final s = await ApiService.getScanStatus(widget.scanId!);
      final ai = await ApiService.aiAnalyze(widget.scanId!);
      if (mounted) {
        setState(() {
          _scan = s;
          _aiAnalysis = ai;
          _loading = false;
        });
        _scoreCtrl.forward();
      }
    } else {
      // Demo fallback
      setState(() {
        _scan = {
          'score': 72.0,
          'verdict': 'suspicious',
          'ai_summary': 'Analysis detected 7 permissions, 4 of which map to known MITRE ATT&CK techniques. The application exhibits suspicious behavior patterns consistent with data collection. Threat verdict: SUSPICIOUS with a security score of 72.0/100.',
          'behavior_summary': {
            'file_access_calls': 142,
            'network_connections': [
              {'host': 'api.analytics.com', 'ip': '104.22.14.8', 'status': 'monitored'},
              {'host': 'cdn.updates.io', 'ip': '151.101.1.57', 'status': 'safe'},
            ],
            'blocked_permissions_attempted': ['CAMERA', 'READ_CONTACTS'],
            'mitre_techniques': [
              {'id': 'T1636.001', 'tactic': 'Collection', 'name': 'Contact List'},
              {'id': 'T1125', 'tactic': 'Collection', 'name': 'Video Capture'},
              {'id': 'T1398', 'tactic': 'Persistence', 'name': 'Boot/Logon Autostart'},
              {'id': 'T1071', 'tactic': 'Command and Control', 'name': 'C2 over HTTP'},
            ],
          },
          'vulnerabilities': [
            {'title': 'Unencrypted Network Traffic', 'severity': 'Medium', 'description': 'Detected HTTP requests without TLS encryption.', 'mitre_id': 'T1071', 'mitre_tactic': 'Command and Control'},
            {'title': 'Overly Broad Permissions', 'severity': 'High', 'description': 'Requests 7 permissions, some may be excessive.', 'mitre_id': 'T1418', 'mitre_tactic': 'Discovery'},
          ],
        };
        _aiAnalysis = {
          'mitre_grid': {
            'Collection': [{'id': 'T1636.001', 'name': 'Contact List'}, {'id': 'T1125', 'name': 'Video Capture'}],
            'Persistence': [{'id': 'T1398', 'name': 'Boot/Logon Autostart'}],
            'Command and Control': [{'id': 'T1071', 'name': 'C2 over HTTP'}],
          },
        };
        _loading = false;
      });
      _scoreCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentBlue)),
      );
    }

    final score = (_scan!['score'] as num?)?.toDouble() ?? 85.0;
    final verdict = _scan!['verdict'] as String? ?? 'safe';
    final verdictColor = verdict == 'safe' ? AppTheme.accentGreen : verdict == 'suspicious' ? AppTheme.accentOrange : AppTheme.accentRed;
    final behavior = _scan!['behavior_summary'] as Map<String, dynamic>? ?? {};
    final vulns = _scan!['vulnerabilities'] as List<dynamic>? ?? [];
    final mitreGrid = _aiAnalysis?['mitre_grid'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildAppBar(context, verdict, verdictColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildScoreHero(score, verdict, verdictColor),
                  const SizedBox(height: 20),
                  _buildAiSummaryCard(),
                  const SizedBox(height: 16),
                  _buildBehaviorCard(behavior),
                  const SizedBox(height: 16),
                  if (vulns.isNotEmpty) _buildVulnsCard(vulns),
                  const SizedBox(height: 16),
                  _buildMitreToggle(mitreGrid),
                  const SizedBox(height: 16),
                  _buildNetworkCard(behavior),
                  const SizedBox(height: 20),
                  if (verdict != 'safe') _buildRemediationButton(context),
                  const SizedBox(height: 12),
                  _buildDoneButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String verdict, Color verdictColor) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20, right: 20, bottom: 12),
      child: Row(children: [
        GhostChip(label: 'SCAN COMPLETE', color: verdictColor),
        const Spacer(),
        GhostChip(label: verdict.toUpperCase(), color: verdictColor),
      ]),
    );
  }

  Widget _buildScoreHero(double score, String verdict, Color verdictColor) {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (_, __) {
        final animScore = score * _scoreAnim.value;
        return GhostCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(animScore.toStringAsFixed(0),
                      style: GoogleFonts.rajdhani(
                          fontSize: 80, fontWeight: FontWeight.w900, color: verdictColor, height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text('/100', style: AppTheme.headingM.copyWith(color: AppTheme.textMuted)),
                  ),
                ],
              ),
              Text('SECURITY SCORE', style: AppTheme.labelXS),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: animScore / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation(verdictColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(verdict == 'safe' ? Icons.verified_user_rounded : Icons.warning_rounded,
                    color: verdictColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  verdict == 'safe'
                      ? 'Device is secure. No threats detected.'
                      : verdict == 'suspicious'
                          ? 'Suspicious behavior detected. Review recommended.'
                          : 'Malware confirmed. Immediate action required.',
                  style: AppTheme.bodyS.copyWith(color: verdictColor),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiSummaryCard() {
    final summary = _scan!['ai_summary'] as String? ?? '';
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.psychology_rounded, color: AppTheme.accentPurple, size: 18),
            const SizedBox(width: 8),
            Text('AI THREAT INTELLIGENCE', style: AppTheme.labelXS.copyWith(color: AppTheme.accentPurple)),
          ]),
          const SizedBox(height: 12),
          Text(summary, style: AppTheme.bodyM.copyWith(height: 1.7)),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(Map<String, dynamic> behavior) {
    final fileAccess = behavior['file_access_calls'] ?? 0;
    final blockedPerms = (behavior['blocked_permissions_attempted'] as List<dynamic>? ?? []);
    final techniques = (behavior['mitre_techniques'] as List<dynamic>? ?? []);

    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.analytics_rounded, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('BEHAVIORAL ANALYSIS', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _statItem('$fileAccess', 'System Calls', AppTheme.accentBlue)),
            Expanded(child: _statItem('${blockedPerms.length}', 'Blocked Perms', AppTheme.accentOrange)),
            Expanded(child: _statItem('${techniques.length}', 'MITRE Hits', AppTheme.accentRed)),
          ]),
          if (blockedPerms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('BLOCKED PERMISSION ATTEMPTS', style: AppTheme.labelXS.copyWith(color: AppTheme.accentOrange)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: blockedPerms.map((p) => GhostChip(label: p.toString(), color: AppTheme.accentOrange)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.rajdhani(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: AppTheme.labelXS.copyWith(fontSize: 9), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildVulnsCard(List<dynamic> vulns) {
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.gpp_maybe_rounded, color: AppTheme.accentRed, size: 18),
            const SizedBox(width: 8),
            Text('VULNERABILITIES DETECTED (${vulns.length})', style: AppTheme.labelXS.copyWith(color: AppTheme.accentRed)),
          ]),
          const SizedBox(height: 14),
          ...vulns.map((v) {
            final sev = v['severity'] as String? ?? 'Medium';
            final sevColor = sev == 'High' || sev == 'Critical'
                ? AppTheme.accentRed : sev == 'Medium' ? AppTheme.accentOrange : AppTheme.accentYellow;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 4, height: 40, color: sevColor, margin: const EdgeInsets.only(right: 12)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(v['title'] as String, style: AppTheme.headingS.copyWith(fontSize: 14))),
                    GhostChip(label: sev.toUpperCase(), color: sevColor),
                  ]),
                  if (v['mitre_id'] != null)
                    Text('${v['mitre_id']} · ${v['mitre_tactic']}',
                        style: AppTheme.mono.copyWith(color: AppTheme.accentPurple, fontSize: 10)),
                  Text(v['description'] as String, style: AppTheme.bodyS),
                ])),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMitreToggle(Map<String, dynamic> mitreGrid) {
    final allTactics = [
      'Reconnaissance', 'Resource Development', 'Initial Access', 'Execution',
      'Persistence', 'Privilege Escalation', 'Defense Evasion', 'Credential Access',
      'Discovery', 'Lateral Movement', 'Collection', 'Command and Control',
      'Exfiltration', 'Impact',
    ];
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showMitre = !_showMitre),
            child: Row(children: [
              Icon(Icons.grid_view_rounded, color: AppTheme.accentPurple, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('MITRE ATT&CK MATRIX', style: AppTheme.labelXS.copyWith(color: AppTheme.accentPurple))),
              Icon(_showMitre ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted),
            ]),
          ),
          if (_showMitre) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allTactics.map((tactic) {
                final hits = (mitreGrid[tactic] as List<dynamic>? ?? []);
                final isHit = hits.isNotEmpty;
                return Tooltip(
                  message: isHit
                      ? hits.map((t) => '${t['id']}: ${t['name']}').join('\n')
                      : tactic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHit ? AppTheme.accentPurple.withOpacity(0.2) : AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHit ? AppTheme.accentPurple : AppTheme.borderColor,
                        width: isHit ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      if (isHit)
                        Icon(Icons.flash_on_rounded, color: AppTheme.accentPurple, size: 12),
                      Text(
                        tactic,
                        style: AppTheme.labelXS.copyWith(
                            color: isHit ? AppTheme.accentPurple : AppTheme.textMuted,
                            fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                      if (isHit)
                        Text('${hits.length} hit${hits.length > 1 ? 's' : ''}',
                            style: AppTheme.labelXS.copyWith(color: AppTheme.accentPurple, fontSize: 8)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkCard(Map<String, dynamic> behavior) {
    final connections = (behavior['network_connections'] as List<dynamic>? ?? []);
    if (connections.isEmpty) return const SizedBox();
    return GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lan_rounded, color: AppTheme.accentBlue, size: 18),
            const SizedBox(width: 8),
            Text('NETWORK CONNECTIONS', style: AppTheme.labelXS),
          ]),
          const SizedBox(height: 12),
          ...connections.map((c) {
            final status = c['status'] as String;
            final statusColor = status == 'safe' ? AppTheme.accentGreen
                : status == 'monitored' ? AppTheme.accentOrange : AppTheme.accentRed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.language_rounded, color: statusColor, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(c['host'] as String, style: AppTheme.mono.copyWith(fontSize: 12))),
                Text(c['ip'] as String, style: AppTheme.mono.copyWith(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(width: 8),
                GhostChip(label: status.toUpperCase(), color: statusColor),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRemediationButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RemediationScreen(
              verdict: _scan!['verdict'] as String,
              scanId: widget.scanId))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.accentRed.withOpacity(0.8), AppTheme.accentRed]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppTheme.accentRed.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('BEGIN INCIDENT REMEDIATION',
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
    );
  }

  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text('BACK TO STATUS', textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remediation Screen (Feature 10)
// ─────────────────────────────────────────────────────────────────────────────
class RemediationScreen extends StatefulWidget {
  final String verdict;
  final String? scanId;
  const RemediationScreen({super.key, required this.verdict, this.scanId});

  @override
  State<RemediationScreen> createState() => _RemediationScreenState();
}

class _RemediationScreenState extends State<RemediationScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _stepCtrl;
  late Animation<double> _stepAnim;

  final _steps = [
    {
      'title': 'IDENTIFY',
      'icon': Icons.manage_search_rounded,
      'color': AppTheme.accentOrange,
      'description': 'Threat identified and catalogued in GhostRun database.',
      'actions': ['Threat fingerprint logged', 'Hash submitted to community', 'IOCs extracted'],
    },
    {
      'title': 'ISOLATE',
      'icon': Icons.block_rounded,
      'color': AppTheme.accentRed,
      'description': 'Isolating malicious process and blocking network egress.',
      'actions': ['Network connections blocked', 'Process suspended', 'Outbound packets quarantined'],
    },
    {
      'title': 'ALERT',
      'icon': Icons.notifications_active_rounded,
      'color': AppTheme.accentYellow,
      'description': 'Security team and administrators have been notified.',
      'actions': ['Incident ticket created', 'SIEM alert broadcast', 'Community threat reported'],
    },
    {
      'title': 'RESTORE',
      'icon': Icons.health_and_safety_rounded,
      'color': AppTheme.accentGreen,
      'description': 'System restoration complete. Follow the checklist below.',
      'actions': ['Uninstall suspicious application', 'Change passwords if credentials accessed', 'Run full GhostRun deep scan', 'Enable 2FA on all accounts'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _stepAnim = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _stepCtrl.reset();
      setState(() => _currentStep++);
      _stepCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          Container(
            color: AppTheme.bgSecondary,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20, right: 20, bottom: 12),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
              Text('INCIDENT REMEDIATION', style: AppTheme.headingS.copyWith(fontSize: 16)),
              const Spacer(),
              GhostChip(label: widget.verdict.toUpperCase(), color: AppTheme.accentRed),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Timeline steps
                  Row(
                    children: List.generate(_steps.length, (i) {
                      final s = _steps[i];
                      final done = i < _currentStep;
                      final active = i == _currentStep;
                      final c = s['color'] as Color;
                      return Expanded(
                        child: Row(children: [
                          Expanded(
                            child: Column(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done ? c : active ? c.withOpacity(0.2) : AppTheme.bgCard,
                                  border: Border.all(color: done || active ? c : AppTheme.borderColor, width: 2),
                                ),
                                child: Icon(done ? Icons.check_rounded : s['icon'] as IconData,
                                    color: done ? Colors.white : active ? c : AppTheme.textMuted,
                                    size: done ? 20 : 22),
                              ),
                              const SizedBox(height: 4),
                              Text(s['title'] as String,
                                  style: AppTheme.labelXS.copyWith(
                                      color: done || active ? c : AppTheme.textDim, fontSize: 9)),
                            ]),
                          ),
                          if (i < _steps.length - 1)
                            Container(width: 20, height: 2, color: i < _currentStep ? (s['color'] as Color) : AppTheme.borderColor),
                        ]),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  // Active step card
                  FadeTransition(
                    opacity: _stepAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_stepAnim),
                      child: GhostCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.15),
                                  border: Border.all(color: color),
                                ),
                                child: Icon(step['icon'] as IconData, color: color, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('STEP ${_currentStep + 1} OF ${_steps.length}', style: AppTheme.labelXS),
                                Text(step['title'] as String, style: AppTheme.headingL.copyWith(color: color)),
                              ]),
                            ]),
                            const SizedBox(height: 16),
                            Text(step['description'] as String, style: AppTheme.bodyM),
                            const SizedBox(height: 16),
                            ...(step['actions'] as List<String>).map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withOpacity(0.15),
                                  ),
                                  child: Icon(Icons.check_rounded, color: color, size: 12),
                                ),
                                const SizedBox(width: 10),
                                Text(a, style: AppTheme.bodyM),
                              ]),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_currentStep < _steps.length - 1)
                    GestureDetector(
                      onTap: _nextStep,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('PROCEED TO ${(_steps[_currentStep + 1]['title'] as String)}',
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ]),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppTheme.accentGreen.withOpacity(0.3), blurRadius: 12)],
                        ),
                        child: Text('INCIDENT RESOLVED — CLOSE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
