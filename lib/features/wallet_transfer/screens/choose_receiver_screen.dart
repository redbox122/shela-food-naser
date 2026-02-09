import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
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
  void _onContactSelected(Contact contact) {
    if (contact.phones.isNotEmpty) {
      final phone = contact.phones.first.number;
      Get.back(result: {
        'name': contact.displayName,
        'phone': phone,
        'isContact': true,
      });
    }
  }

  /// Handles saved recipient selection
  void _onSavedRecipientSelected(SavedRecipientModel recipient) {
    Get.back(result: {
      'name': recipient.displayName,
      'phone': recipient.recipientPhone ?? '',
      'isContact': false,
    });
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).disabledColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).disabledColor),
                        onPressed: () {
                          _searchController.clear();
                          _filterContacts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  borderSide: BorderSide(color: Theme.of(context).disabledColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filterContacts,
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                    ? _buildPermissionDeniedView()
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

        // Contacts section
        if (!hasSearch)
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

