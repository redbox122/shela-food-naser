import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cart Mock',
      home: const CartPage(),
      // Force RTL for the whole screen
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // swap with your Arabic font later
      ),
    );
  }
}

/* ------------------------------ COLORS ------------------------------ */
class AppColors {
  static const green = Color(0xFF31A342);
  static const dark = Color(0xFF2D3633);
  static const light = Color(0xFF7B8280);
  static const divider = Color(0xFFE9ECEB);
  static const cardShadow = Color(0x14333333); // subtle
  static const orange = Color(0xFFFA9D2B);
}

/* ------------------------------ MODELS ------------------------------ */
class CartItem {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final int price; // SAR
  int qty;

  CartItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.price,
    required this.qty,
  });
}

/* ------------------------------ APP BAR ------------------------------ */
class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CartAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.green,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 80,
      systemOverlayStyle: SystemUiOverlayStyle.light, // white status icons
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'السلة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
      // In RTL, `leading` sits on the RIGHT — matches the mock
      leading: IconButton(
        onPressed: onBack ?? () {},
        icon: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 20,
          color: Colors.white,
        ),
        tooltip: 'رجوع',
      ),
    );
  }
}

/* ------------------------------ PAGE ------------------------------ */
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Replace this with your DB-driven list later.
  final List<CartItem> _items = [
    CartItem(
      id: '1',
      title: 'نسكافيه 30 ظرف',
      subtitle: 'عرض 30 ظرف 5+ هدية',
      image:
          'https://images.unsplash.com/photo-1587731678171-9b54f0f31d6e?w=800',
      price: 50,
      qty: 1,
    ),
    CartItem(
      id: '2',
      title: 'شاي ليبتون',
      subtitle: 'عرض 35 ظرف 5+ هدية',
      image:
          'https://images.unsplash.com/photo-1587731678171-9b54f0f31d6e?w=800',
      price: 10,
      qty: 1,
    ),
    CartItem(
      id: '3',
      title: 'شاي الوزة',
      subtitle: '50 غرام مجانًا',
      image:
          'https://images.unsplash.com/photo-1587731678171-9b54f0f31d6e?w=800',
      price: 10,
      qty: 3,
    ),
  ];

  int get _subtotal => _items.fold(0, (sum, it) => sum + (it.price * it.qty));
  int get _fees => 0;
  int get _delivery => 15;
  int get _total => _subtotal + _fees + _delivery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CartAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ..._items.map(
              (e) => _CartCard(
                item: e,
                onRemove: () => setState(() => _items.remove(e)),
                onMinus: () => setState(() {
                  if (e.qty > 1) e.qty--;
                }),
                onPlus: () => setState(() => e.qty++),
              ),
            ),
            const SizedBox(height: 8),
            const _CouponField(),
            const SizedBox(height: 12),
            _SummaryRow(label: 'المجموع الفرعي', value: 'ريال $_subtotal'),
            const _DividerLine(),
            _SummaryRow(label: 'الضرائب والرسوم', value: 'ريال $_fees'),
            const _DividerLine(),
            _SummaryRow(label: 'التوصيل', value: 'ريال $_delivery'),
            const _DividerLine(),
            _SummaryRow(
              label: 'الإجمالي',
              value: 'ريال $_total',
              trailingNote: '(5 عناصر)',
              isTotal: true,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'الدفع',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ CART CARD ------------------------------ */
class _CartCard extends StatelessWidget {
  const _CartCard({
    required this.item,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Keep image on the *left* by forcing this Row LTR only
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 90,
                            height: 86,
                            color: const Color(0xFFF6F6F6),
                            child: SmartImage(
                              url: item.image,
                              height: 86,
                              width: 90,
                              cacheWidth: 300,
                              cacheHeight: 300,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.light,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    color: AppColors.light,
                                    fontSize: 15,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'ريال ${item.price}',
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quantity line
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        _RoundMinus(onTap: onMinus),
                        const SizedBox(width: 10),
                        Text(
                          '${item.qty}',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoundPlus(onTap: onPlus),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button on the (visual) right
          PositionedDirectional(
            top: 10,
            end: 10,
            child: _CloseDot(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ SMALL WIDGETS ------------------------------ */

class _RoundMinus extends StatelessWidget {
  const _RoundMinus({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 3),
        ),
        child: const Center(
          child: Icon(Icons.remove, color: AppColors.orange, size: 22),
        ),
      ),
    );
  }
}

class _RoundPlus extends StatelessWidget {
  const _RoundPlus({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _CloseDot extends StatelessWidget {
  const _CloseDot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Icon(Icons.close, color: AppColors.dark, size: 18),
        ),
      ),
    );
  }
}

class _CouponField extends StatelessWidget {
  const _CouponField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Expanded(
              child: TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'برومو كود',
                  hintStyle: TextStyle(color: AppColors.light, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  'إدخال',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: AppColors.divider, height: 24, thickness: 1),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.trailingNote,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final String? trailingNote;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppColors.dark,
      fontSize: isTotal ? 18 : 17,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
    );
    final valueStyle = TextStyle(
      color: AppColors.dark,
      fontSize: isTotal ? 18 : 17,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Row(
            children: [
              if (trailingNote != null) ...[
                Text(
                  trailingNote!,
                  style: const TextStyle(
                    color: AppColors.light,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(value, style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }
}
