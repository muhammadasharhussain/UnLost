// lib/ui/reviews/reviews_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_panel.dart';
import '../../data/models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reviews_provider.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    final reviews = context.read<ReviewsProvider>();
    await Future.wait([
      reviews.loadReunions(),
      if (userId != null) reviews.loadForUser(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final reviewsProv = context.watch<ReviewsProvider>();

    final userId = auth.currentUser?.id;
    final myReviews = userId != null ? reviewsProv.reviewsFor(userId) : <ReviewModel>[];
    final reunions = reviewsProv.reunions;
    final avg = userId != null ? reviewsProv.averageFor(userId) : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          color: isDark ? AppColors.emerald : AppColors.emeraldInk,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 22,
                      color: isDark ? AppColors.champagne : AppColors.champagneInk,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reviews',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (userId != null && myReviews.isNotEmpty) ...[
                SectionPanel(
                  title: 'My reputation',
                  icon: CupertinoIcons.person_badge_plus_fill,
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.champagne : AppColors.champagneInk)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            avg.toStringAsFixed(1),
                            style: TextStyle(
                              fontFamily: AppTheme.monoFontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.champagne : AppColors.champagneInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StarRow(rating: avg.round()),
                            const SizedBox(height: 4),
                            Text(
                              '${myReviews.length} review${myReviews.length == 1 ? '' : 's'} from campus community',
                              style: TextStyle(fontSize: 12, color: p.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SectionPanel(
                  title: 'Reviews about me (${myReviews.length})',
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  child: Column(
                    children: myReviews.map((r) => _ReviewTile(review: r)).toList(),
                  ),
                ),
              ] else if (userId != null) ...[
                SectionPanel(
                  title: 'My reputation',
                  icon: CupertinoIcons.person_badge_plus_fill,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No reviews yet. Complete a handover to earn your first review!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textDim, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
              SectionPanel(
                title: 'Recent reunions',
                subtitle: 'Items successfully returned on campus',
                icon: Icons.celebration_rounded,
                child: reviewsProv.isLoadingReunions
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : reunions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No reunions yet. Be the first to return something!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.textDim, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: reunions.map((r) => _ReviewTile(review: r)).toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.hairline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.emerald : AppColors.emeraldInk).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.text)),
                    Text('about ${review.aboutName}',
                        style: TextStyle(fontSize: 11, color: p.textDim)),
                  ],
                ),
              ),
              _StarRow(rating: review.rating, size: 13),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${review.comment}"',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: p.textDim),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.emerald : AppColors.emeraldInk).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                      )),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: size,
          color: i < rating
              ? (isDark ? AppColors.champagne : AppColors.champagneInk)
              : context.palette.hairline,
        );
      }),
    );
  }
}
