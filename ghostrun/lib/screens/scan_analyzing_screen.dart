import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';

class ScanAnalyzingScreen extends StatefulWidget {
  final Function({String? scanId}) onNext;
  final String? fileId;

  const ScanAnalyzingScreen({super.key, required this.onNext, this.fileId});

  @override
  State<ScanAnalyzingScreen> createState() => _ScanAnalyzingScreenState();
}

class _ScanAnalyzingScreenState extends State<ScanAnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _pulseAnim;

  String? _scanId;
  String _phase = 'analyzing';
  double _progress = 0.0;
  Timer? _pollTimer;
  final List<String> _liveLog = [];
  final _rng = Random();

  // AI simulation log messages per phase
  final _analyzingLogs = [
    '> Initializing GhostRun sandbox engine v4.2...',
    '> Loading YARA ruleset (42,817 signatures)...',
    '> Mounting isolated execution environment...',
    '> Intercepting system call table...',
    '> Attaching behavioral tracer to PID 4821...',
    '> Static entropy analysis: 7.82 bits/byte',
    '> Extracting embedded strings from binary...',
    '> Cross-referencing against threat intelligence feeds...',
  ];
  final _sandboxLogs = [
    '> [SYSCALL] openat("/data/data/...", O_RDONLY) → fd=12',
    '> [NET] DNS query: api.analytics-tracker.com → 185.112.14.8',
    '> [PERM] Attempting READ_CONTACTS — MONITORED',
    '> [PERM] Attempting CAMERA access — FLAGGED',
    '> [SYSCALL] connect(185.112.14.8:443) TCP — INTERCEPTED',
    '> [FS] Writing to /sdcard/tmp/.hidden_cache — SUSPICIOUS',
    '> [NET] TLS handshake with unknown cert (SHA1 mismatch)',
    '> [PERM] RECEIVE_BOOT_COMPLETED registered — PERSISTENCE',
    '> [SYSCALL] ptrace(PTRACE_TRACEME) — ANTI-DEBUG DETECTED',
    '> [NET] C2 beacon attempt blocked: malicious-sinkhole.net',
  ];
  final _vulnLogs = [
    '> Mapping syscall traces to MITRE ATT&CK v14...',
    '> T1429: Audio Capture detected (RECORD_AUDIO)',
    '> T1636.001: Contact List enumeration (READ_CONTACTS)',
    '> T1398: Boot persistence registered (RECEIVE_BOOT_COMPLETED)',
    '> T1071: Command & Control over HTTP/S',
    '> Bayesian threat scorer: posterior probability 0.87',
    '> Generating AI threat intelligence summary...',
    '> Finalizing risk assessment model...',
  ];

  int _logIndex = 0;
  Timer? _logTimer;

  final _phases = ['analyzing', 'sandbox', 'finding_vulnerabilities', 'completed'];
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _progressCtrl.forward();

    _startScan();
  }

  Future<void> _startScan() async {
    try {
      final result = await ApiService.startScan('user_001', fileId: widget.fileId);
      if (mounted) {
        _scanId = result['scan_id']?.toString();
        _startLiveLog();
        _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
      }
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  void _startLiveLog() {
    _logTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      List<String> pool;
      if (_phaseIndex == 0) pool = _analyzingLogs;
      else if (_phaseIndex == 1) pool = _sandboxLogs;
      else pool = _vulnLogs;

      if (_liveLog.length < 30) {
        final msg = pool[_logIndex % pool.length];
        setState(() {
          _liveLog.add(msg);
          _logIndex++;
        });
      }
    });
  }

  Future<void> _pollStatus() async {
    if (_scanId == null) return;
    try {
      final status = await ApiService.getScanStatus(_scanId!);
      if (!mounted) return;

      final serverPhase = status['status']?.toString() ?? 'error';
      final phaseIdx = _phases.indexOf(serverPhase);
      setState(() {
        _phase = serverPhase;
        _phaseIndex = phaseIdx.clamp(0, 3);
        _progress = (phaseIdx + 1) / _phases.length;
      });

      if (serverPhase == 'completed') {
        _pollTimer?.cancel();
        _logTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onNext(scanId: _scanId);
      }
    } catch (e) {
      print('Error polling scan status: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _pollTimer?.cancel();
    _logTimer?.cancel();
    super.dispose();
  }

  Color get _phaseColor => _phaseIndex < 2
      ? AppTheme.accentBlue
      : _phaseIndex == 2 ? AppTheme.accentOrange : AppTheme.accentGreen;

  String get _phaseLabel {
    switch (_phase) {
      case 'analyzing': return 'STATIC ANALYSIS';
      case 'sandbox': return 'SANDBOX EXECUTION';
      case 'finding_vulnerabilities': return 'THREAT MAPPING';
      case 'completed': return 'COMPLETE';
      default: return 'INITIALIZING';
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildPulsingOrb(),
                  const SizedBox(height: 28),
                  _buildPhaseIndicators(),
                  const SizedBox(height: 24),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  _buildLiveTerminal(),
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
        left: 20, right: 20, bottom: 12,
      ),
      child: Row(children: [
        GhostChip(label: 'SCANNING', color: _phaseColor),
        const Spacer(),
        Text('GHOSTRUN SCANNER',
            style: AppTheme.labelXS.copyWith(color: AppTheme.textMuted)),
      ]),
    );
  }

  Widget _buildPulsingOrb() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _phaseColor.withOpacity(0.08 * _pulseAnim.value),
          border: Border.all(color: _phaseColor.withOpacity(0.4 * _pulseAnim.value), width: 2),
          boxShadow: [BoxShadow(color: _phaseColor.withOpacity(0.3 * _pulseAnim.value), blurRadius: 40, spreadRadius: 10)],
        ),
        child: Center(
          child: Icon(
            _phaseIndex == 0 ? Icons.search_rounded
                : _phaseIndex == 1 ? Icons.precision_manufacturing_rounded
                : _phaseIndex == 2 ? Icons.bug_report_rounded
                : Icons.check_circle_rounded,
            color: _phaseColor,
            size: 54,
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseIndicators() {
    final labels = ['Static\nAnalysis', 'Sandbox\nExec', 'MITRE\nMapping', 'Complete'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final done = i < _phaseIndex;
        final active = i == _phaseIndex;
        final color = done || active ? _phaseColor : AppTheme.textDim;
        return Row(children: [
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _phaseColor : active ? _phaseColor.withOpacity(0.2) : AppTheme.bgCard,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(done ? Icons.check_rounded : Icons.circle, color: done ? Colors.white : color, size: done ? 16 : 6),
            ),
            const SizedBox(height: 4),
            Text(labels[i], textAlign: TextAlign.center, style: AppTheme.labelXS.copyWith(color: color, fontSize: 9)),
          ]),
          if (i < 3)
            Container(width: 32, height: 2, color: done ? _phaseColor : AppTheme.borderColor),
        ]);
      }),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_phaseLabel, style: AppTheme.labelXS.copyWith(color: _phaseColor)),
          Text('${(_progress * 100).toInt()}%', style: AppTheme.mono.copyWith(color: _phaseColor, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation(_phaseColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTerminal() {
    return GhostCard(
      color: const Color(0xFF0A0D14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentRed)),
            const SizedBox(width: 6),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentOrange)),
            const SizedBox(width: 6),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen)),
            const SizedBox(width: 12),
            Text('ghostrun@sandbox:~\$', style: AppTheme.mono.copyWith(color: AppTheme.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              reverse: true,
              itemCount: _liveLog.length,
              itemBuilder: (_, i) {
                final line = _liveLog[_liveLog.length - 1 - i];
                Color lineColor = AppTheme.accentGreen;
                if (line.contains('FLAGGED') || line.contains('SUSPICIOUS') || line.contains('BLOCKED') || line.contains('ANTI-DEBUG')) {
                  lineColor = AppTheme.accentRed;
                } else if (line.contains('MONITORED') || line.contains('INTERCEPTED') || line.contains('PERSISTENCE')) {
                  lineColor = AppTheme.accentOrange;
                } else if (line.contains('T1') || line.contains('MITRE')) {
                  lineColor = AppTheme.accentPurple;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(line, style: AppTheme.mono.copyWith(color: lineColor, fontSize: 11, height: 1.5)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
