import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/saved_recipient_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Screen for choosing a receiver from contacts or saved recipients
class ChooseReceiverScreen extends StatefulWidget {
  const ChooseReceiverScreen({super.key});

  @override
  State<ChooseReceiverScreen> createState() => _ChooseReceiverScreenState();
}

class _ChooseReceiverScreenState extends State<ChooseReceiverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads contacts from device
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool permissionGranted = await FlutterContacts.requestPermission();
      if (permissionGranted) {
        _hasPermission = true;
        final List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Filters contacts based on search query
  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number).join(' ').toLowerCase();
        return name.contains(lowerQuery) || phones.contains(lowerQuery);
      }).toList();
    });
  }

  /// Gets saved recipients from controller
  List<SavedRecipientModel> _getSavedRecipients() {
    final controller = Get.find<WalletTransferController>();
    return controller.savedRecipients ?? [];
  }

  /// Handles contact selection
  Future<void> _onContactSelected(Contact contact) async {
    if (contact.phones.isNotEmpty) {
      final phone = contact.phones.first.number;
      await _validateAndSelectRecipient(phone);
    }
  }

  /// Handles saved recipient selection
  Future<void> _onSavedRecipientSelected(SavedRecipientModel recipient) async {
    await _validateAndSelectRecipient(recipient.recipientPhone ?? '');
  }

  Future<void> _validateAndSelectRecipient(String phoneInput) async {
    final WalletTransferController controller =
        Get.find<WalletTransferController>();
    final bool isValid = await controller.validateRecipient(phoneInput);
    if (!isValid || controller.validatedRecipient == null) {
      return;
    }
    final recipient = controller.validatedRecipient!;
    debugPrint(
        '[WALLET_TRANSFER][RECIPIENT_SELECTED] id=${recipient.id} phone=${recipient.phone}');
    Get.back(result: {
      'name': recipient.name ?? '',
      'phone': recipient.phone ?? '',
      'isContact': false,
    });
  }

  Widget _buildManualInputSection() {
    return GetBuilder<WalletTransferController>(builder: (controller) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          0,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدخال رقم الجوال يدويًا',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  hintText: '+9665XXXXXXXX',
                  suffixIcon: controller.isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _validateAndSelectRecipient(
                            _searchController.text.trim(),
                          ),
                        ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                onChanged: (String value) {
                  if (controller.validatedRecipient != null) {
                    controller.clearValidatedRecipient();
                  }
                  _filterContacts(value);
                },
                onSubmitted: (String value) {
                  _validateAndSelectRecipient(value.trim());
                },
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (controller.validatedRecipient != null)
              _buildValidatedManualRecipientCard(controller),
            if (!controller.isValidating &&
                controller.validatedRecipient == null &&
                _searchController.text.trim().isNotEmpty &&
                controller.lastError == 'USER_NOT_FOUND')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'لا يوجد مستخدم بهذا الرقم',
                  style: robotoRegular.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildValidatedManualRecipientCard(WalletTransferController controller) {
    final recipient = controller.validatedRecipient!;
    return InkWell(
      onTap: () {
        debugPrint(
            '[WALLET_TRANSFER][RECIPIENT_SELECTED] id=${recipient.id} phone=${recipient.phone}');
        Get.back(result: {
          'name': recipient.name ?? '',
          'phone': recipient.phone ?? '',
          'isContact': false,
        });
      },
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).primaryColor),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: ClipOval(
                child: CustomImage(
                  image: recipient.image ?? '',
                  height: 38,
                  width: 38,
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipient.name ?? '',
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault)),
                  Text(
                    recipient.phone ?? '',
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            Text('اختيار', style: robotoMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'choose_receiver'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildManualInputSection(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContactsList(),
          ),
        ],
      ),
    );
  }

  /// Builds permission denied view
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              'contacts_permission_required'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'contacts_permission_denied'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton(
              onPressed: _loadContacts,
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds contacts list
  Widget _buildContactsList() {
    final savedRecipients = _getSavedRecipients();
    final hasSearch = _searchController.text.isNotEmpty;

    return ListView(
      children: [
        // Saved recipients section (only show if not searching)
        if (!hasSearch && savedRecipients.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Text(
              'saved_recipients'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ),
          ...savedRecipients.map((recipient) => _buildSavedRecipientItem(recipient)),
          const Divider(height: 1),
        ],

        if (!_hasPermission)
          _buildPermissionDeniedView(),
        if (_hasPermission && !hasSearch)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Text(
              'contacts'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ),

        // Contact list
        if (_filteredContacts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Center(
              child: Text(
                'no_contacts_found'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
          )
        else
          ..._filteredContacts.map((contact) => _buildContactItem(contact)),
      ],
    );
  }

  /// Builds contact list item
  Widget _buildContactItem(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final name = contact.displayName;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: robotoBold.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      title: Text(
        name,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      subtitle: phone.isNotEmpty
          ? Text(
              phone,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            )
          : null,
      onTap: () => _onContactSelected(contact),
    );
  }

  /// Builds saved recipient list item
  Widget _buildSavedRecipientItem(SavedRecipientModel recipient) {
    final name = recipient.displayName;
    final phone = recipient.recipientPhone ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: robotoBold.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      title: Text(
        name,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      subtitle: phone.isNotEmpty
          ? Text(
              phone,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            )
          : null,
      trailing: Icon(
        Icons.star,
        color: Theme.of(context).primaryColor,
        size: 20,
      ),
      onTap: () => _onSavedRecipientSelected(recipient),
    );
  }
}

