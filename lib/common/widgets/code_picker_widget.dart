import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CodePickerWidget extends StatefulWidget {
  final ValueChanged<CountryCode>? onChanged;
  final ValueChanged<CountryCode>? onInit;
  final String? initialSelection;
  final List<String>? favorite;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool? showCountryOnly;
  final InputDecoration? searchDecoration;
  final TextStyle? searchStyle;
  final TextStyle? dialogTextStyle;
  final WidgetBuilder? emptySearchBuilder;
  final Widget Function(CountryCode)? builder;
  final bool? enabled;
  final TextOverflow? textOverflow;
  final Icon? closeIcon;
  final Color? barrierColor;
  final Color? backgroundColor;
  final BoxDecoration? boxDecoration;
  final Size? dialogSize;
  final Color? dialogBackgroundColor;
  final List<String>? countryFilter;
  final bool? showOnlyCountryWhenClosed;
  final bool? alignLeft;
  final bool? showFlag;
  final bool? hideMainText;
  final bool? showFlagMain;
  final bool? showFlagDialog;
  final double? flagWidth;
  final Comparator<CountryCode>? comparator;
  final bool? hideSearch;
  final bool? showDropDownButton;
  final Decoration? flagDecoration;
  final List<Map<String, String>>? countryList;

  const CodePickerWidget({
    super.key,
    this.onChanged,
    this.onInit,
    this.initialSelection,
    this.favorite = const [],
    this.textStyle,
    this.padding = const EdgeInsets.all(8),
    this.showCountryOnly = false,
    this.searchDecoration = const InputDecoration(),
    this.searchStyle,
    this.dialogTextStyle,
    this.emptySearchBuilder,
    this.builder,
    this.enabled = true,
    this.textOverflow = TextOverflow.ellipsis,
    this.closeIcon = const Icon(Icons.close),
    this.barrierColor,
    this.backgroundColor,
    this.boxDecoration,
    this.dialogSize,
    this.dialogBackgroundColor,
    this.countryFilter,
    this.showOnlyCountryWhenClosed = false,
    this.alignLeft = false,
    this.showFlag = true,
    this.hideMainText = false,
    this.showFlagMain,
    this.showFlagDialog,
    this.flagWidth = 32,
    this.comparator,
    this.hideSearch = false,
    this.showDropDownButton = false,
    this.flagDecoration,
    this.countryList = codes,
  });

  @override
  State<CodePickerWidget> createState() => _CodePickerWidgetState();
}

class _CodePickerWidgetState extends State<CodePickerWidget> {
  CountryCode? selectedItem;
  List<CountryCode> elements = [];
  List<CountryCode> favoriteElements = [];

  @override
  void initState() {
    super.initState();
    _initCountries();
  }

  void _initCountries() {
    final list = widget.countryList ?? [];

    elements = list
        .map((json) => CountryCode.fromJson(json))
        .toList();

    if (widget.comparator != null) {
      elements.sort(widget.comparator);
    }

    if (widget.countryFilter != null &&
        widget.countryFilter!.isNotEmpty) {
      final filter =
          widget.countryFilter!.map((e) => e.toUpperCase()).toList();

      elements = elements.where((c) =>
          filter.contains(c.code?.toUpperCase()) ||
          filter.contains(c.name?.toUpperCase()) ||
          filter.contains(c.dialCode)).toList();
    }

    selectedItem = _resolveInitialSelection();

    favoriteElements = elements.where((e) {
      return widget.favorite!.any((f) =>
          f.toUpperCase() == e.code?.toUpperCase() ||
          f == e.dialCode ||
          f.toUpperCase() == e.name?.toUpperCase());
    }).toList();

    widget.onInit?.call(selectedItem!);
  }

  CountryCode _resolveInitialSelection() {
    if (widget.initialSelection == null) {
      return elements.first;
    }

    return elements.firstWhere(
      (e) =>
          e.code?.toUpperCase() ==
              widget.initialSelection!.toUpperCase() ||
          e.dialCode == widget.initialSelection ||
          e.name?.toUpperCase() ==
              widget.initialSelection!.toUpperCase(),
      orElse: () => elements.first,
    );
  }

  Future<CountryCode?> _showPickerBottomSheet() {
    return showModalBottomSheet<CountryCode>(
      context: context,
      barrierColor: widget.barrierColor ?? Colors.black54,
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      builder: (_) => _buildDialog(),
    );
  }

  Future<CountryCode?> _showPickerDialog() {
    return showDialog<CountryCode>(
      context: context,
      barrierColor: widget.barrierColor ?? Colors.black54,
      builder: (_) => Dialog(child: _buildDialog()),
    );
  }

  Future<void> _openPicker() async {
    if (!mounted) {
      return;
    }
    final Future<CountryCode?> pickerFuture =
        (GetPlatform.isAndroid || GetPlatform.isIOS)
            ? _showPickerBottomSheet()
            : _showPickerDialog();

    final CountryCode? result = await pickerFuture;
    if (!mounted) {
      return;
    }
    if (result != null) {
      setState(() => selectedItem = result);
      widget.onChanged?.call(result);
    }
  }

Widget _buildDialog() {
  return SelectionDialog(
    elements,
    favoriteElements,
    showCountryOnly: widget.showCountryOnly,
    emptySearchBuilder: widget.emptySearchBuilder,
    searchDecoration: widget.searchDecoration!,
    searchStyle: widget.searchStyle,
    textStyle: widget.dialogTextStyle,
    boxDecoration: widget.boxDecoration,
    showFlag: widget.showFlagDialog ?? widget.showFlag,
    flagWidth: widget.flagWidth!,
    size: widget.dialogSize,
    backgroundColor: widget.dialogBackgroundColor,
    barrierColor: widget.barrierColor,
    hideSearch: widget.hideSearch!,
    closeIcon: widget.closeIcon,
    flagDecoration: widget.flagDecoration,

    // ✅ الباراميترات الجديدة المطلوبة
    hideHeaderText: false,
    headerAlignment: MainAxisAlignment.start,
    headerTextStyle: const TextStyle(),
    topBarPadding: EdgeInsets.zero,
  );
}


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (widget.enabled ?? true) ? _openPicker : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showFlagMain ?? widget.showFlag!)
            Image.asset(
              selectedItem!.flagUri!,
              package: 'country_code_picker',
              width: widget.flagWidth,
            ),
          const SizedBox(width: 6),
          if (!widget.hideMainText!)
            Text(
              widget.showOnlyCountryWhenClosed!
                  ? selectedItem!.toCountryStringOnly()
                  : selectedItem.toString(),
              overflow: widget.textOverflow,
              style: widget.textStyle,
            ),
          if (widget.showDropDownButton!)
            const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
