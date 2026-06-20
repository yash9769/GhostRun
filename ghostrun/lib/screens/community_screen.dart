import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _threats = [];
  bool _loading = true;
  int _selectedFilter = 0;
  final List<String> _filters = ['ALL', 'CRITICAL', 'WARNING', 'VERIFIED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadThreats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadThreats() async {
    setState(() => _loading = true);
    final threats = await ApiService.fetchThreats();
    if (mounted) setState(() { _threats = threats; _loading = false; });
  }

  List<dynamic> get _filteredThreats {
    switch (_selectedFilter) {
      case 1: return _threats.where((t) => t['severity'] == 'critical').toList();
      case 2: return _threats.where((t) => t['severity'] == 'warning').toList();
      case 3: return _threats.where((t) => t['verified'] == true).toList();
      default: return _threats;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapView(),
                _buildListView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportSheet,
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text('REPORT THREAT',
            style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20, right: 20, bottom: 12),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THREAT INTEL', style: AppTheme.labelXS.copyWith(color: AppTheme.accentRed)),
          Text('Community Map', style: AppTheme.headingM),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentRed)),
            const SizedBox(width: 6),
            Text('${_threats.length} ACTIVE', style: AppTheme.labelXS.copyWith(color: AppTheme.accentRed)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.bgSecondary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accentBlue,
        labelColor: AppTheme.accentBlue,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
        tabs: const [
          Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'LIVE MAP'),
          Tab(icon: Icon(Icons.list_rounded, size: 18), text: 'REPORTS'),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue));
    }
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(37.7749, -122.4194),
            initialZoom: 12.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ghostrun.app',
            ),
            MarkerLayer(
              markers: _filteredThreats.map((t) {
                final lat = (t['lat'] as num).toDouble();
                final lng = (t['lng'] as num).toDouble();
                final severity = t['severity'] as String;
                final verified = t['verified'] as bool? ?? false;
                final color = severity == 'critical'
                    ? AppTheme.accentRed
                    : AppTheme.accentOrange;
                return Marker(
                  point: LatLng(lat, lng),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showThreatDetail(t),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.25),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Icon(
                            severity == 'critical'
                                ? Icons.gpp_bad_rounded
                                : Icons.warning_amber_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        if (verified)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentGreen,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 8),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Map overlay legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LEGEND', style: AppTheme.labelXS),
                const SizedBox(height: 8),
                _legendItem(AppTheme.accentRed, 'Critical Threat'),
                const SizedBox(height: 4),
                _legendItem(AppTheme.accentOrange, 'Warning'),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen)),
                  const SizedBox(width: 6),
                  Text('Verified', style: AppTheme.bodyS.copyWith(fontSize: 11)),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 14, height: 14,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 1.5))),
      const SizedBox(width: 6),
      Text(label, style: AppTheme.bodyS.copyWith(fontSize: 11)),
    ]);
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(_filters.length, (i) {
              final sel = i == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.accentBlue : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.accentBlue : AppTheme.borderLight),
                    ),
                    child: Text(_filters[i],
                        style: AppTheme.labelXS.copyWith(
                            color: sel ? Colors.white : AppTheme.textMuted,
                            fontSize: 10)),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredThreats.length,
                  itemBuilder: (_, i) => _buildThreatCard(_filteredThreats[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildThreatCard(Map<String, dynamic> threat) {
    final severity = threat['severity'] as String;
    final verified = threat['verified'] as bool? ?? false;
    final severityColor = severity == 'critical' ? AppTheme.accentRed : AppTheme.accentOrange;
    final categoryIcons = {
      'phishing': Icons.phishing_rounded,
      'wifi': Icons.wifi_off_rounded,
      'qr': Icons.qr_code_scanner_rounded,
      'malware': Icons.bug_report_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GhostCard(
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcons[threat['category']] ?? Icons.warning_rounded,
                  color: severityColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(threat['title'] ?? '', style: AppTheme.headingS.copyWith(fontSize: 15))),
                    if (verified)
                      const Icon(Icons.verified_rounded, color: AppTheme.accentGreen, size: 16),
                  ]),
                  const SizedBox(height: 3),
                  Text(threat['description'] ?? '',
                      style: AppTheme.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 12),
                    const SizedBox(width: 3),
                    Text(threat['location'] ?? '', style: AppTheme.bodyS.copyWith(fontSize: 11)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ApiService.voteThreat(threat['id'], true).then((_) => _loadThreats()),
                      child: Row(children: [
                        Icon(Icons.thumb_up_rounded, color: AppTheme.accentGreen, size: 12),
                        const SizedBox(width: 3),
                        Text('${threat['upvotes'] ?? 0}', style: AppTheme.bodyS.copyWith(color: AppTheme.accentGreen)),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThreatDetail(Map<String, dynamic> threat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              GhostChip(
                  label: (threat['severity'] as String).toUpperCase(),
                  color: threat['severity'] == 'critical' ? AppTheme.accentRed : AppTheme.accentOrange),
              if (threat['verified'] == true) ...[
                const SizedBox(width: 8),
                GhostChip(label: 'VERIFIED', color: AppTheme.accentGreen),
              ],
            ]),
            const SizedBox(height: 12),
            Text(threat['title'] ?? '', style: AppTheme.headingM),
            const SizedBox(height: 8),
            Text(threat['description'] ?? '', style: AppTheme.bodyM),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(threat['location'] ?? '', style: AppTheme.bodyS),
              const Spacer(),
              Icon(Icons.thumb_up_rounded, color: AppTheme.accentGreen, size: 14),
              const SizedBox(width: 4),
              Text('${threat['upvotes']} upvotes', style: AppTheme.bodyS.copyWith(color: AppTheme.accentGreen)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentGreen),
                    foregroundColor: AppTheme.accentGreen,
                  ),
                  onPressed: () {
                    ApiService.voteThreat(threat['id'], true);
                    Navigator.pop(context);
                    _loadThreats();
                  },
                  icon: const Icon(Icons.thumb_up_rounded, size: 16),
                  label: const Text('CONFIRM'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentRed),
                    foregroundColor: AppTheme.accentRed,
                  ),
                  onPressed: () {
                    ApiService.voteThreat(threat['id'], false);
                    Navigator.pop(context);
                    _loadThreats();
                  },
                  icon: const Icon(Icons.thumb_down_rounded, size: 16),
                  label: const Text('DISPUTE'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showReportSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'phishing';
    String selectedSeverity = 'warning';
    final categories = ['phishing', 'wifi', 'qr', 'malware', 'other'];
    final severities = ['warning', 'critical'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORT A THREAT', style: AppTheme.headingM),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary),
                decoration: _inputDec('Threat Title (e.g. Phishing SMS)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary),
                decoration: _inputDec('Description'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text('Category: ', style: AppTheme.bodyS),
                ...categories.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setLocal(() => selectedCategory = c),
                    child: GhostChip(
                      label: c.toUpperCase(),
                      color: selectedCategory == c ? AppTheme.accentBlue : AppTheme.textMuted,
                    ),
                  ),
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('Severity: ', style: AppTheme.bodyS),
                ...severities.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setLocal(() => selectedSeverity = s),
                    child: GhostChip(
                      label: s.toUpperCase(),
                      color: selectedSeverity == s
                          ? (s == 'critical' ? AppTheme.accentRed : AppTheme.accentOrange)
                          : AppTheme.textMuted,
                    ),
                  ),
                )),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
                    await ApiService.reportThreat({
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'category': selectedCategory,
                      'severity': selectedSeverity,
                      'location': 'Current Location',
                      'lat': 37.7749 + (0.01 * (DateTime.now().millisecond % 10 - 5)),
                      'lng': -122.4194 + (0.01 * (DateTime.now().second % 10 - 5)),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadThreats();
                  },
                  child: Text('SUBMIT REPORT',
                      style: GoogleFonts.rajdhani(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTheme.bodyS,
    filled: true,
    fillColor: AppTheme.bgCardLight,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.accentBlue)),
  );
}
