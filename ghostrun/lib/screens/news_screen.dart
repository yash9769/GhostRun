import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_widgets.dart';
import '../api_service.dart';

class NewsScreen extends StatefulWidget {
  final VoidCallback? onViewAll;
  const NewsScreen({super.key, this.onViewAll});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> _articles = [];
  List<dynamic> _filteredArticles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSource = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final news = await ApiService.fetchNews();
      setState(() {
        _articles = news;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load live cybersecurity news feed.', style: AppTheme.bodyM.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.accentRedDim,
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredArticles = _articles.where((article) {
        final matchesSearch = (article['title'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (article['content'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesSource = _selectedSource == 'All' || (article['source'] ?? '') == _selectedSource;
        return matchesSearch && matchesSource;
      }).toList();
    });
  }

  Future<void> _openArticleUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open article link.', style: AppTheme.bodyM.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.accentRedDim,
        ),
      );
    }
  }

  void _showArticleDetail(BuildContext context, Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GhostChip(
                        label: article['source'] ?? 'SECURITY NEWS',
                        color: AppTheme.accentBlue,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article['title'] ?? '',
                    style: AppTheme.headingM.copyWith(fontSize: 22, height: 1.3),
                  ),
                  if (article['date'] != null && article['date'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Published on: ${article['date']}',
                      style: AppTheme.bodyS.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (article['image_url'] != null && article['image_url'].toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'http://127.0.0.1:8001/api/news/image?url=${Uri.encodeComponent(article['image_url'])}',
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        FutureBuilder<List<String>>(
                          future: ApiService.fetchArticleContent(article['url'] ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final paragraphs = snapshot.data ?? [];
                            if (paragraphs.isEmpty) {
                              return Text(
                                article['content'] ?? 'No additional description available.',
                                style: AppTheme.bodyM.copyWith(fontSize: 16, height: 1.6),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: paragraphs.map((paragraph) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    paragraph,
                                    style: AppTheme.bodyM.copyWith(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _openArticleUrl(article['url'] ?? '');
                      },
                      icon: const Icon(Icons.open_in_new, size: 20),
                      label: Text(
                        'OPEN ORIGINAL ARTICLE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildAppBar(context),
          _buildSearchBar(),
          _buildSourceChips(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.accentBlue,
              backgroundColor: AppTheme.bgCard,
              onRefresh: _fetchNews,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredArticles.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            const Center(
                              child: Icon(Icons.search_off, size: 60, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'No matching security advisories found.',
                                style: AppTheme.bodyM,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = _filteredArticles[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: GestureDetector(
                                onTap: () => _showArticleDetail(context, article),
                                child: _articleCard(
                                  icon: Icons.security,
                                  iconBg: AppTheme.accentBlue.withOpacity(0.12),
                                  iconColor: AppTheme.accentBlue,
                                  tag: article['source'] ?? 'SECURITY',
                                  title: article['title'] ?? '',
                                  body: article['content'] ?? '',
                                  footer: 'CLICK TO READ FULL REPORT →',
                                  date: article['date'] ?? '',
                                  imageUrl: article['image_url'],
                                ),
                              ),
                            );
                          },
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
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            onPressed: _fetchNews,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applyFilters();
          });
        },
        style: AppTheme.bodyM.copyWith(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.bgSecondary,
          hintText: 'Search scams, tech threats, exploits...',
          hintStyle: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accentBlue),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSourceChips() {
    final sources = ['All', 'The Hacker News', 'Wired Security'];
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          final isSelected = _selectedSource == source;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                source.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSource = source;
                    _applyFilters();
                  });
                }
              },
              selectedColor: AppTheme.accentBlue,
              backgroundColor: AppTheme.bgSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.borderLight,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
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
    String date = '',
    String? imageUrl,
  }) {
    return GhostCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                'http://127.0.0.1:8001/api/news/image?url=${Uri.encodeComponent(imageUrl)}',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (tag.isNotEmpty) GhostChip(label: tag, color: tagColor),
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: AppTheme.bodyS.copyWith(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(title, style: AppTheme.headingS),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: AppTheme.bodyM,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Text(
                  footer,
                  style: AppTheme.bodyS.copyWith(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
