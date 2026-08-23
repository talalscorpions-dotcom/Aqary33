import 'package:flutter/material.dart';
import '../../models/category_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';

/// The one reusable screen behind Properties (top level), Residential,
/// Commercial, Buy, and Agriculture in the mockup. Per the Properties
/// Module Architecture doc: "one data-driven component reading from a
/// taxonomy table — not one hardcoded screen per level." Everything
/// this screen shows comes from its constructor arguments; there is no
/// screen-specific logic to duplicate when a new category is added.
class CategoryGridScreen extends StatelessWidget {
  final String title;
  final List<String> breadcrumbPath;
  final List<CategoryItem> items;
  final String? footerNote;
  final void Function(CategoryItem item) onSelect;

  const CategoryGridScreen({
    super.key,
    required this.title,
    required this.breadcrumbPath,
    required this.items,
    required this.onSelect,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    // Cards render with descriptions in a 2-column list when every item
    // has one (e.g. Residential: Buy/Rent/Sell), and compactly in a
    // 2-column grid without descriptions otherwise (e.g. the 4-category
    // Properties top level) — matching the two card styles in the mockup.
    final hasDescriptions = items.every((i) => i.description != null);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: ListView(
            children: [
              Breadcrumb(path: breadcrumbPath),
              hasDescriptions ? _DescriptiveGrid(items: items, onSelect: onSelect) : _CompactGrid(items: items, onSelect: onSelect),
              if (footerNote != null) ...[
                const SizedBox(height: 18),
                _FooterNote(text: footerNote!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactGrid extends StatelessWidget {
  final List<CategoryItem> items;
  final void Function(CategoryItem item) onSelect;
  const _CompactGrid({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) => _CategoryCard(item: items[i], onTap: () => onSelect(items[i])),
    );
  }
}

class _DescriptiveGrid extends StatelessWidget {
  final List<CategoryItem> items;
  final void Function(CategoryItem item) onSelect;
  const _DescriptiveGrid({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) => _CategoryCard(item: items[i], onTap: () => onSelect(items[i]), showDescription: true),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback onTap;
  final bool showDescription;

  const _CategoryCard({required this.item, required this.onTap, this.showDescription = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              if (showDescription && item.description != null) ...[
                const SizedBox(height: 5),
                Text(
                  item.description!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.mute),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  final String text;
  const _FooterNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, size: 16, color: AppColors.tealDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.tealDark, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
