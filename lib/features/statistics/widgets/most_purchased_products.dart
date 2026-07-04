import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';
import '../../../helper/grid_view_fix_height.dart';
import '../../../util/app_colors.dart';

class MostPurchasedProducts extends StatelessWidget {
  const MostPurchasedProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'st_most_purchased'.tr,
          style: font14Black400W(context),
        ),
        const SizedBox(
          height: 16,
        ),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
            crossAxisCount: 3, // Number of columns in the grid
            crossAxisSpacing: 5.0, // Spacing between columns
            mainAxisSpacing: 5.0, // Spacing between rows
            height: 200,
          ),
          itemCount: products.length, // Total number of products
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        )
      ],
    );
  }
}

class Product {
  final String image;
  final String name;
  final double price;
  final double discountPrice;

  Product(
      {required this.image,
      required this.name,
      required this.price,
      required this.discountPrice});
}

final List<Product> products = [
  Product(
    image: 'assets/image/b2.png',
    name: 'st_lipton_48'.tr,
    price: 10.0,
    discountPrice: 10.0,
  ),
  Product(
      image: 'assets/image/b1.png',
      name: 'st_digestive_biscuit'.tr,
      price: 15.0,
      discountPrice: 15.0),
  // Add more products here
];

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Card(
        color: AppColors.gryColor_3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                product.image,
                height: 100, // Adjust image height as needed
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: Text(
                      product.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: font10Black400W(context),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: font13Black400W(context)
                            .copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      const Spacer(),
                      Text(
                        '\$${product.discountPrice.toStringAsFixed(2)}',
                        style: font13SecondaryColor400W(context),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
