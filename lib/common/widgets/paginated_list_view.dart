import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PaginatedListView extends StatefulWidget {
  final ScrollController scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final Widget itemView;
  final bool enabledPagination;
  final bool reverse;
  const PaginatedListView({
    super.key,
    required this.scrollController,
    required this.onPaginate,
    required this.totalSize,
    required this.offset,
    required this.itemView,
    this.enabledPagination = true,
    this.reverse = false,
  });

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;
  static const int _itemsPerPage = 12; // API limit is 12 items per page

  @override
  void initState() {
    super.initState();

    _offset = widget.offset ?? 1;
    _offsetList = [];
    for (int index = 1; index <= _offset!; index++) {
      _offsetList.add(index);
    }

    widget.scrollController.addListener(() {
      if (widget.scrollController.position.pixels == widget.scrollController.position.maxScrollExtent &&
          widget.totalSize != null &&
          !_isLoading &&
          widget.enabledPagination) {
        if (mounted && !ResponsiveHelper.isDesktop(context)) {
          _paginate();
        }
      }
    });
  }

  void _paginate() async {
    if (widget.totalSize == null) return;
    
    // Calculate total pages based on actual API limit (12 items per page)
    final int totalPages = (widget.totalSize! / _itemsPerPage).ceil();
    final int currentOffset = _offset ?? widget.offset ?? 1;
    
    // Check if we have more pages to load
    if (currentOffset < totalPages && !_offsetList.contains(currentOffset + 1)) {
      setState(() {
        _offset = currentOffset + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });
      
      try {
        await widget.onPaginate(_offset);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync offset from widget if it changed (e.g., after filter change)
    if (widget.offset != null && widget.offset != _offset) {
      _offset = widget.offset;
      _offsetList = [];
      for (int index = 1; index <= widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    if (widget.totalSize == null) {
      return widget.itemView;
    }

    final int totalPages = (widget.totalSize! / _itemsPerPage).ceil();
    final int currentOffset = _offset ?? widget.offset ?? 1;
    final bool hasMorePages = currentOffset < totalPages && !_offsetList.contains(currentOffset + 1);

    return Column(children: [
      widget.reverse ? const SizedBox() : widget.itemView,
      (ResponsiveHelper.isDesktop(context) && !hasMorePages)
          ? const SizedBox()
          : Center(
              child: Padding(
              padding: (_isLoading || ResponsiveHelper.isDesktop(context))
                  ? const EdgeInsets.all(Dimensions.paddingSizeSmall)
                  : EdgeInsets.zero,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : (ResponsiveHelper.isDesktop(context) && hasMorePages)
                      ? InkWell(
                          onTap: _paginate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              color: Theme.of(context).primaryColor,
                            ),
                            child: Text('view_more'.tr,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white)),
                          ),
                        )
                      : const SizedBox(),
            )),
      widget.reverse ? widget.itemView : const SizedBox(),
    ]);
  }
}
