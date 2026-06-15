import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/util/design_tokens.dart';

/// Shared loading indicator shown while search results are being fetched.
class SearchResultsLoading extends StatelessWidget {
  const SearchResultsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceLarge * 2),
      child: LoadingWidget(
        messageKey: 'bringing_great_products',
        showMessage: true,
      ),
    );
  }
}
