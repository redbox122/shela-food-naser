import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';

void main() {
  runApp(const MyApp());
}

/// Simple color palette inspired by the mock
class AppColors {
  static const primary = Color(0xFF2E3A38);
  static const textDark = Color(0xFF1E1E1E);
  static const textLight = Color(0xFF8E8E8E);
  static const pillBg = Color(0xFFF6F7F8);
  static const divider = Color(0xFFEAEAEA);
  static const card = Color(0xFFF9FAFB);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 👇 No locales or delegates — we’ll force RTL in the screen itself.
      home: const SearchScreen(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // replace with an Arabic font if you like
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 16),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: AppColors.pillBg,
          labelStyle: TextStyle(color: AppColors.textDark, fontSize: 14),
          side: BorderSide(color: Colors.transparent),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: StadiumBorder(),
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // sample “most searched” tiles
    final tiles = <_CategoryTile>[
      _CategoryTile(
        title: 'عروض وتخفيضات',
        banner: true,
        image:
            'https://images.unsplash.com/photo-1607082350899-7e105aa886ae?w=1200',
      ),
      _CategoryTile(
        title: 'متاجر جديدة',
        image:
            'https://images.unsplash.com/photo-1542831371-d531d36971e6?w=1200',
      ),
      _CategoryTile(
        title: 'مشروبات وقهوة',
        image:
            'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=1200',
      ),
      _CategoryTile(
        title: 'المخبوزات',
        image:
            'https://images.unsplash.com/photo-1509440159598-8b1d0a1d5e3d?w=1200',
      ),
      _CategoryTile(
        title: 'شوكلَا',
        image:
            'https://images.unsplash.com/photo-1606313564200-e75d5e1df57d?w=1200',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl, // 👈 hard-coded RTL
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderBar(),
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.expand_more, size: 20, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'التوصيل إلى : الموقع الحالي',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'البحث',
                    suffixIcon: Icon(Icons.search, color: AppColors.textLight),
                  ),
                ),
                const SizedBox(height: 12),
                const _ChipsRow(
                  chips: [
                    'أصناف المتاجر',
                    'المطاعم والمتاجر',
                    'أصناف المطاعم',
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionLabel(text: 'بحث مسبقًا عن'),
                const SizedBox(height: 6),
                const _RecentSearchRow(text: 'عروض وخصومات'),
                const Divider(height: 1, color: AppColors.divider),
                const _RecentSearchRow(text: 'مشروبات'),
                const Divider(height: 1, color: AppColors.divider),
                const _RecentSearchRow(text: 'ماركت'),
                const SizedBox(height: 18),
                const _SectionLabel(text: 'الأكثر بحثاً'),
                const SizedBox(height: 10),

                // Tiles
                for (final t in tiles) ...[
                  _MostSearchedTile(tile: t),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 8),
                // iOS home indicator style bar (purely visual)
                Center(
                  child: Container(
                    width: 280,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar: back chevron, title, and cart with badge
class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // Back arrow (on the far right in RTL)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark),
          ),
          const Spacer(),
          const Text(
            'بحث',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          // Cart with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.textDark),
              ),
              PositionedDirectional(
                top: 2,
                start: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19C37D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pills row for quick filters
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Chip(
          label: Text(chips[i]),
          backgroundColor: AppColors.pillBg,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: chips.length,
      ),
    );
  }
}

/// Small grey section label
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textLight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A single recent search row
class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              splashRadius: 20,
              icon: const Icon(Icons.close, color: AppColors.textDark),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.search, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// Data for “most searched” tiles
class _CategoryTile {
  final String title;
  final String image;
  final bool banner;

  _CategoryTile({
    required this.title,
    required this.image,
    this.banner = false,
  });
}

/// Visual card used for each entry in the “most searched” list.
/// In RTL, the image sits on the right, text on the left.
class _MostSearchedTile extends StatelessWidget {
  const _MostSearchedTile({required this.tile});

  final _CategoryTile tile;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final img = ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: tile.banner ? 16 / 6 : 1,
        child: SmartImage(
          url: tile.image,
          cacheWidth: tile.banner ? 800 : 300,
          cacheHeight: tile.banner ? 800 : 300,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: AppColors.card,
            child: const Center(child: Icon(Icons.image_not_supported)),
          ),
        ),
      ),
    );

    if (tile.banner) {
      // Full-width banner with label on the left
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          img,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tile.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Regular row tile
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tile.title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              height: 100,
              child: img,
            ),
          ],
        ),
      ),
    );
  }
}
