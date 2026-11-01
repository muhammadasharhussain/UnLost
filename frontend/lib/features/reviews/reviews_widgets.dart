// lib/features/reviews/reviews_widgets.dart
// Display-only review widgets: profile section, Home "Recently returned" strip
// and the read-only admin list.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import '../../providers/reviews_provider.dart';
import 'review_sheet.dart';

TextStyle _monoLabel(BuildContext context, {Color? color}) => TextStyle(
      fontFamily: AppTheme.monoFontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: color ?? context.palette.textFaint,
    );

String _categoryName(String id) {
  try {
    return ItemCategories.getById(id).name;
  } catch (_) {
    return 'Item';
  }
}

/// One review row used on the profile and in the admin list.
class ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final bool showAbout; // admin view: "Author about Person"
  final bool showFlag;

  const ReviewTile({
    super.key,
    required this.review,
    this.showAbout = false,
    this.showFlag = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final flagged = showFlag && review.isFlaggedForAdmin;
    final errColor = AppColors.readable(AppColors.error, Theme.of(context).brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flagged ? errColor : p.hairline,
          width: flagged ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(rating: review.rating, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  showAbout
                      ? '${review.publicName} about ${review.aboutName.isEmpty ? "a student" : review.aboutName}'
                      : review.publicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
              ),
              if (flagged)
                Text('FLAGGED', style: _monoLabel(context, color: errColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${review.outcome.toUpperCase()}  ·  ${_categoryName(review.itemCategory).toUpperCase()}  ·  ${DateFormat('MMM d').format(review.createdAt).toUpperCase()}',
            style: _monoLabel(context),
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: p.textDim),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in review.tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.hairline),
                    ),
                    child: Text(t.toUpperCase(), style: _monoLabel(context, color: p.textDim)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Profile: average rating, count and the last 3 reviews about a user.
class UserReviewsSection extends StatefulWidget {
  final String userId;
  const UserReviewsSection({super.key, required this.userId});

  @override
  State<UserReviewsSection> createState() => _UserReviewsSectionState();
}

class _UserReviewsSectionState extends State<UserReviewsSection> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UserReviewsSection old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _load();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewsProvider>().loadForUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prov = context.watch<ReviewsProvider>();
    final reviews = prov.reviewsFor(widget.userId);
    final avg = prov.averageFor(widget.userId);
    final last3 = reviews.take(3).toList();

    final isLoading = prov.isUserLoading(widget.userId);
    final error = prov.userError(widget.userId);

    if (isLoading && reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null && reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load reviews: $error',
              style: TextStyle(fontSize: 13, color: p.textDim),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => prov.loadForUser(widget.userId),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              reviews.isEmpty ? '-' : avg.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: p.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(rating: avg.round(), size: 16),
                  const SizedBox(height: 2),
                  Text(
                    '${reviews.length} REVIEW${reviews.length == 1 ? '' : 'S'}',
                    style: _monoLabel(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (last3.isEmpty)
          Text(
            'No reviews yet. They appear here after a case is returned.',
            style: TextStyle(fontSize: 13, height: 1.4, color: p.textDim),
          )
        else
          for (final r in last3) ...[
            ReviewTile(review: r),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// Home: anonymised "Recently returned" strip.
class RecentlyReturnedStrip extends StatelessWidget {
  const RecentlyReturnedStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reunions = context.watch<ReviewsProvider>().reunions;
    if (reunions.isEmpty) return const SizedBox.shrink();

    final accent = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('RECENTLY RETURNED', style: _monoLabel(context, color: accent)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: reunions.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = reunions[i];
                final quote = r.comment.trim().isEmpty
                    ? 'Item returned to its owner.'
                    : r.comment.trim();
                return Semantics(
                  label:
                      '${r.publicName} got a ${_categoryName(r.itemCategory)} back. $quote',
                  child: Container(
                    width: 268,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.hairline, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.checkmark_seal_fill,
                                size: 14, color: accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_categoryName(r.itemCategory).toUpperCase()}  ·  RETURNED',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _monoLabel(context, color: accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            '\u201C$quote\u201D',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFontFamily,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                              color: p.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.publicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.textDim,
                                ),
                              ),
                            ),
                            StarRating(rating: r.rating, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin profile area: every review, read-only. Flagged ones come first.
class AdminReviewsList extends StatefulWidget {
  const AdminReviewsList({super.key});

  @override
  State<AdminReviewsList> createState() => _AdminReviewsListState();
}

class _AdminReviewsListState extends State<AdminReviewsList> {
  bool _flaggedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewsProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prov = context.watch<ReviewsProvider>();

    if (prov.isLoadingAll && prov.allReviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (prov.errorMessage != null) {
      return Text(
        prov.errorMessage!,
        style: TextStyle(fontSize: 13, color: p.textDim),
      );
    }

    final all = [...prov.allReviews];
    all.sort((a, b) {
      if (a.isFlaggedForAdmin != b.isFlaggedForAdmin) {
        return a.isFlaggedForAdmin ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    final flaggedCount = all.where((r) => r.isFlaggedForAdmin).length;
    final displayed = _flaggedOnly ? all.where((r) => r.isFlaggedForAdmin).toList() : all;

    if (all.isEmpty) {
      return Text(
        'No reviews yet.',
        style: TextStyle(fontSize: 13, color: p.textDim),
      );
    }

    Widget filterChip(String label, int count, bool active, VoidCallback onTap) {
      final border = active
          ? (p.isDark ? AppColors.cerulean : AppColors.ceruleanInk)
          : p.hairline;
      final textColor = active
          ? (p.isDark ? AppColors.cerulean : AppColors.ceruleanInk)
          : p.textDim;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? (p.isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            '$label ($count)',
            style: _monoLabel(context, color: textColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            filterChip('ALL', all.length, !_flaggedOnly, () {
              if (mounted) setState(() => _flaggedOnly = false);
            }),
            const SizedBox(width: 8),
            filterChip('FLAGGED', flaggedCount, _flaggedOnly, () {
              if (mounted) setState(() => _flaggedOnly = true);
            }),
          ],
        ),
        const SizedBox(height: 12),
        if (displayed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No flagged reviews.',
              style: TextStyle(fontSize: 13, color: p.textDim),
            ),
          )
        else
          for (final r in displayed) ...[
            ReviewTile(review: r, showAbout: true, showFlag: true),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
