import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/chat/enums/user_type_enum.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/chat/domain/models/chat_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/services/chat_service_interface.dart';

class ChatController extends GetxController implements GetxService {
  final ChatServiceInterface chatServiceInterface;
  ChatController({required this.chatServiceInterface});

  List<bool>? _showDate;
  List<bool>? get showDate => _showDate;

  bool _isSendButtonActive = false;
  bool get isSendButtonActive => _isSendButtonActive;

  final bool _isSeen = false;
  bool get isSeen => _isSeen;

  final bool _isSend = true;
  bool get isSend => _isSend;

  bool _isMe = false;
  bool get isMe => _isMe;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGetMessageError = false;
  bool get isGetMessageError => _isGetMessageError;

  final List<Message> _deliveryManMessage = [];
  List<Message> get deliveryManMessage => _deliveryManMessage;

  final List<Message> _adminManMessage = [];
  List<Message> get adminManMessages => _adminManMessage;

  List<XFile> _chatImage = [];
  List<XFile> get chatImage => _chatImage;

  List<Uint8List> _chatRawImage = [];
  List<Uint8List> get chatRawImage => _chatRawImage;

  ChatModel? _messageModel;
  ChatModel? get messageModel => _messageModel;

  ConversationsModel? _conversationModel;
  ConversationsModel? get conversationModel => _conversationModel;

  ConversationsModel? _searchConversationModel;
  ConversationsModel? get searchConversationModel => _searchConversationModel;

  bool _hasAdmin = true;
  bool get hasAdmin => _hasAdmin;

  NotificationBodyModel? _notificationBody;
  NotificationBodyModel? get notificationBody => _notificationBody;

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;

  String _type = 'vendor1';
  String? get type => _type;

  bool _clickTab = false;
  bool get clickTab => _clickTab;

  void setType(String type) {
    _type = type;
    update();
  }

  void setTabSelect() {
    _clickTab = !_clickTab;
  }

  Future<void> getConversationList(int offset, {String type = ''}) async {
    _hasAdmin = true;
    _searchConversationModel = null;
    final ConversationsModel? conversationModel =
        await chatServiceInterface.getConversationList(offset, type);

    if (conversationModel != null) {
      if (offset == 1) {
        _conversationModel = conversationModel;
      } else {
        _conversationModel!.totalSize = conversationModel.totalSize;
        _conversationModel!.offset = conversationModel.offset;
        _conversationModel!.conversations!
            .addAll(conversationModel.conversations!);
      }
      final int index0 =
          chatServiceInterface.setIndex(_conversationModel!.conversations);
      final bool sender =
          chatServiceInterface.checkSender(_conversationModel!.conversations);
      _hasAdmin = false;
      if (index0 != -1 &&
          (Get.context == null || !ResponsiveHelper.isDesktop(Get.context!))) {
        _hasAdmin = true;
        if (sender) {
          _conversationModel!.conversations![index0]!.sender = User(
            id: 0,
            fName: Get.find<SplashController>().configModel!.businessName,
            lName: '',
            phone: Get.find<SplashController>().configModel!.phone,
            email: Get.find<SplashController>().configModel!.email,
            imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
          );
        } else {
          _conversationModel!.conversations![index0]!.receiver = User(
            id: 0,
            fName: Get.find<SplashController>().configModel!.businessName,
            lName: '',
            phone: Get.find<SplashController>().configModel!.phone,
            email: Get.find<SplashController>().configModel!.email,
            imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
          );
        }
      }
    }
    update();
  }

  Future<void> searchConversation(String name) async {
    _searchConversationModel = ConversationsModel(
      conversations: [],
    );
    update();

    if (name.contains('admin') ||
        name.contains('Admin') ||
        name.contains('a') ||
        name.contains('A')) {
      _searchConversationModel!.conversations = [];
      _searchConversationModel!.conversations!.add(Conversation(
        id: 0,
        senderId: 0,
        senderType: UserType.admin.name,
        receiverId: 0,
        receiverType: UserType.admin.name,
        unreadMessageCount: 0,
        lastMessageId: 0,
        lastMessageTime: '2024-07-14 11:05:20',
        createdAt: '2024-07-14T05:05:20.000000Z',
        updatedAt: '2024-07-14T05:05:20.000000Z',
        sender: User(
          id: 0,
          fName: Get.find<SplashController>().configModel!.businessName,
          lName: '',
          phone: Get.find<SplashController>().configModel!.phone,
          email: Get.find<SplashController>().configModel!.email,
          imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
        ),
        receiver: User(
          id: 0,
          fName: Get.find<SplashController>().configModel!.businessName,
          lName: '',
          phone: Get.find<SplashController>().configModel!.phone,
          email: Get.find<SplashController>().configModel!.email,
          imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
        ),
        lastMessage: Message(
          id: 0,
          conversationId: 0,
          senderId: 0,
          message: 'Welcome to Sixam Mart',
          createdAt: '2024-07-14T05:05:20.000000Z',
          updatedAt: '2024-07-14T05:05:20.000000Z',
        ),
      ));
    }

    final ConversationsModel? searchConversationModel =
        await chatServiceInterface.searchConversationList(name);
    if (searchConversationModel != null) {
      for (final element in searchConversationModel.conversations!) {
        _searchConversationModel!.conversations!.add(element);
      }
      // _searchConversationModel = searchConversationModel;
      // int index0 = chatServiceInterface.setIndex(_searchConversationModel!.conversations);
      // bool sender = chatServiceInterface.checkSender(_searchConversationModel!.conversations);
      //
      // print('searchConversationModel: ${index0}');
      //
      // if(index0 != -1) {
      //   if(sender) {
      //     _searchConversationModel!.conversations![index0]!.sender = User(
      //       id: 0, fName: Get.find<SplashController>().configModel!.businessName, lName: '',
      //       phone: Get.find<SplashController>().configModel!.phone, email: Get.find<SplashController>().configModel!.email,
      //       imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
      //     );
      //   }else {
      //     _searchConversationModel!.conversations![index0]!.receiver = User(
      //       id: 0, fName: Get.find<SplashController>().configModel!.businessName, lName: '',
      //       phone: Get.find<SplashController>().configModel!.phone, email: Get.find<SplashController>().configModel!.email,
      //       imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
      //     );
      //   }
      // }
    }
    update();
  }

  void removeSearchMode() {
    _searchConversationModel = null;
    update();
  }

  Future<void> getMessages(int offset, NotificationBodyModel? notificationBody,
      User? user, int? conversationID,
      {bool firstLoad = false}) async {
    const String logPrefixOrange = '\x1B[38;5;208m[CHAT:getMessages]';
    const String logReset = '\x1B[0m';
    Response? response;
    final int? effectiveConversationId =
        conversationID ?? notificationBody?.conversationId;

    debugPrint('$logPrefixOrange START offset=$offset firstLoad=$firstLoad '
        'convID=$conversationID effectiveConvID=$effectiveConversationId '
        'adminId=${notificationBody?.adminId} '
        'restaurantId=${notificationBody?.restaurantId} '
        'deliverymanId=${notificationBody?.deliverymanId} '
        'user.id=${user?.id}$logReset');

    if (firstLoad) {
      _messageModel = null;
      _isSendButtonActive = false;
      _isLoading = false;
      _isGetMessageError = false;
    }
    if (effectiveConversationId != null) {
      final int fallbackUserId = notificationBody?.restaurantId ??
          notificationBody?.deliverymanId ??
          notificationBody?.adminId ??
          user?.id ??
          0;
      final String fallbackUserType = notificationBody?.adminId != null
          ? UserType.admin.name
          : notificationBody?.deliverymanId != null
              ? UserType.delivery_man.name
              : UserType.vendor.name;
      debugPrint('$logPrefixOrange BRANCH=conversationId userId=$fallbackUserId type=$fallbackUserType convId=$effectiveConversationId$logReset');
      response = await chatServiceInterface.getMessages(
          offset, fallbackUserId, fallbackUserType, effectiveConversationId);
    } else if (notificationBody == null || notificationBody.adminId != null) {
      debugPrint('$logPrefixOrange BRANCH=admin userId=0$logReset');
      response = await chatServiceInterface.getMessages(
          offset, 0, UserType.admin.name, null);
    } else if (notificationBody.restaurantId != null) {
      debugPrint('$logPrefixOrange BRANCH=vendor restaurantId=${notificationBody.restaurantId}$logReset');
      response = await chatServiceInterface.getMessages(
          offset, notificationBody.restaurantId, UserType.vendor.name, null);
    } else if (notificationBody.deliverymanId != null) {
      debugPrint('$logPrefixOrange BRANCH=delivery_man deliverymanId=${notificationBody.deliverymanId}$logReset');
      response = await chatServiceInterface.getMessages(offset,
          notificationBody.deliverymanId, UserType.delivery_man.name, null);
    } else {
      debugPrint('$logPrefixOrange BRANCH=NONE — missing all ids, request skipped$logReset');
    }

    final dynamic responseBody = response?.body;
    debugPrint('$logPrefixOrange RESPONSE status=${response?.statusCode} bodyType=${responseBody.runtimeType} '
        'bodyIsMap=${responseBody is Map<String, dynamic>}$logReset');

    final bool isSuccess = response != null &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300 &&
        responseBody is Map<String, dynamic>;

    debugPrint('$logPrefixOrange isSuccess=$isSuccess firstLoad=$firstLoad$logReset');

    if (isSuccess) {
      _isGetMessageError = false;
      if (offset == 1) {
        /// Unread-read
        if (effectiveConversationId != null &&
            _conversationModel != null &&
            (Get.context == null ||
                !ResponsiveHelper.isDesktop(Get.context!))) {
          final int index0 =
              chatServiceInterface.findOutConversationUnreadIndex(
                  _conversationModel!.conversations, effectiveConversationId);
          if (index0 != -1) {
            _conversationModel!.conversations![index0]!.unreadMessageCount = 0;
          }
        }
        if (Get.find<ProfileController>().userInfoModel == null) {
          await Get.find<ProfileController>().getUserInfo();
        }

        /// Manage Receiver
        _messageModel =
            ChatModel.fromJson(response.body as Map<String, dynamic>);
        _messageModel!.messages ??=
            []; // ensure non-null for new/empty conversations
        debugPrint('$logPrefixOrange SUCCESS parsed model: '
            'messageCount=${_messageModel!.messages!.length} '
            'status=${_messageModel!.status} '
            'hasConversation=${_messageModel!.conversation != null}$logReset');
        if (_messageModel!.conversation == null) {
          debugPrint('$logPrefixOrange conversation==null → building from user param$logReset');
          _messageModel!.conversation = Conversation(
              sender: User(
                id: Get.find<ProfileController>().userInfoModel!.id,
                imageFullUrl:
                    Get.find<ProfileController>().userInfoModel!.imageFullUrl,
                fName: Get.find<ProfileController>().userInfoModel!.fName,
                lName: Get.find<ProfileController>().userInfoModel!.lName,
              ),
              receiver: notificationBody?.adminId != null
                  ? User(
                      id: 0,
                      fName: Get.find<SplashController>()
                          .configModel!
                          .businessName,
                      lName: '',
                      imageFullUrl:
                          Get.find<SplashController>().configModel!.logoFullUrl,
                    )
                  : user);
        }
        _sortMessage(notificationBody?.adminId);
      } else {
        final chatModel =
            ChatModel.fromJson(response.body as Map<String, dynamic>);
        _messageModel!.totalSize = chatModel.totalSize;
        _messageModel!.offset = chatModel.offset;
        _messageModel!.messages!.addAll(chatModel.messages!);
        debugPrint('$logPrefixOrange PAGINATE loaded ${chatModel.messages?.length ?? 0} more messages$logReset');
      }
    } else if (firstLoad) {
      // 404 means no conversation exists yet (new chat) — treat as empty, not error
      if (response == null || response.statusCode == 404) {
        debugPrint('$logPrefixOrange 404/null → new conversation, showing empty chat$logReset');
        _isGetMessageError = false;
        if (Get.find<ProfileController>().userInfoModel == null) {
          await Get.find<ProfileController>().getUserInfo();
        }
        _messageModel = ChatModel(
          messages: [],
          status: true,
          conversation: Conversation(
            sender: User(
              id: Get.find<ProfileController>().userInfoModel?.id,
              imageFullUrl:
                  Get.find<ProfileController>().userInfoModel?.imageFullUrl,
              fName: Get.find<ProfileController>().userInfoModel?.fName,
              lName: Get.find<ProfileController>().userInfoModel?.lName,
            ),
            receiver: notificationBody?.adminId != null
                ? User(
                    id: 0,
                    fName:
                        Get.find<SplashController>().configModel!.businessName,
                    lName: '',
                    imageFullUrl:
                        Get.find<SplashController>().configModel!.logoFullUrl,
                  )
                : user,
          ),
        );
      } else {
        debugPrint('$logPrefixOrange ERROR status=${response.statusCode} → setting isGetMessageError=true$logReset');
        _isGetMessageError = true;
      }
    }
    update();
  }

  void pickImage(bool isRemove) async {
    if (isRemove) {
      _chatImage = [];
      _chatRawImage = [];
    } else {
      final List<XFile> imageFiles =
          await ImagePicker().pickMultiImage(imageQuality: 40);
      for (final XFile xFile in imageFiles) {
        if (_chatImage.length >= 5) {
          showCustomSnackBar('can_not_add_more_than_3_image'.tr);
          break;
        } else {
          // XFile file = await chatServiceInterface.compressImage(xFile);
          _chatImage.add(xFile);
          _chatRawImage.add(await xFile.readAsBytes());
        }
      }
      _isSendButtonActive = true;
    }
    update();
  }

  void removeImage(int index, String messageText) {
    _chatImage.removeAt(index);
    _chatRawImage.removeAt(index);
    if (_chatImage.isEmpty && messageText.isEmpty) {
      _isSendButtonActive = false;
    }
    update();
  }

  Future<Response?> sendMessage(
      {required String message,
      required NotificationBodyModel? notificationBody,
      required int? conversationID,
      required int? index,
      String? orderId}) async {
    const String so = '\x1B[38;5;208m[CHAT:sendMessage]';
    const String sr = '\x1B[0m';
    Response? response;
    _isLoading = true;
    update();

    final List<MultipartBody> myImages =
        chatServiceInterface.processMultipartBody(_chatImage);

    final int? effectiveConversationId =
        conversationID ?? _messageModel?.conversation?.id;

    debugPrint('$so START msg="${message.substring(0, message.length.clamp(0, 30))}" '
        'convID=$conversationID effectiveConvID=$effectiveConversationId '
        'adminId=${notificationBody?.adminId} '
        'restaurantId=${notificationBody?.restaurantId} '
        'deliverymanId=${notificationBody?.deliverymanId} '
        'imageCount=${myImages.length}$sr');

    if (notificationBody == null || notificationBody.adminId != null) {
      debugPrint('$so BRANCH=admin$sr');
      response = await chatServiceInterface.sendMessage(
        message,
        orderId ?? '',
        myImages,
        notificationBody?.adminId ?? 0,
        UserType.admin.name,
        effectiveConversationId,
      );
    } else if (notificationBody.restaurantId != null) {
      debugPrint('$so BRANCH=vendor restaurantId=${notificationBody.restaurantId} effectiveConvID=$effectiveConversationId$sr');
      response = await chatServiceInterface.sendMessage(
          message,
          orderId ?? '',
          myImages,
          notificationBody.restaurantId,
          UserType.vendor.name,
          effectiveConversationId);
    } else if (notificationBody.deliverymanId != null) {
      debugPrint('$so BRANCH=delivery_man deliverymanId=${notificationBody.deliverymanId} effectiveConvID=$effectiveConversationId$sr');
      response = await chatServiceInterface.sendMessage(
          message,
          orderId ?? '',
          myImages,
          notificationBody.deliverymanId,
          UserType.delivery_man.name,
          effectiveConversationId);
    } else if (effectiveConversationId != null) {
      debugPrint('$so BRANCH=conversationId fallback effectiveConvID=$effectiveConversationId$sr');
      response = await chatServiceInterface.sendMessage(
          message,
          orderId ?? '',
          myImages,
          notificationBody.restaurantId,
          UserType.vendor.name,
          effectiveConversationId);
    } else {
      debugPrint('$so BRANCH=NONE — no matching branch, response will be null$sr');
    }

    final dynamic sendBody = response?.body;
    debugPrint('$so RESPONSE status=${response?.statusCode} bodyType=${sendBody.runtimeType} bodyIsMap=${sendBody is Map<String, dynamic>}$sr');

    final bool sendHttpSuccess = response != null &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    debugPrint('$so sendHttpSuccess=$sendHttpSuccess$sr');

    if (sendHttpSuccess) {
      _chatImage = [];
      _chatRawImage = [];
      _isSendButtonActive = false;

      if (sendBody is Map<String, dynamic>) {
        _messageModel = ChatModel.fromJson(sendBody);
        _messageModel!.messages ??= [];
        debugPrint('$so SUCCESS parsed model: messageCount=${_messageModel!.messages!.length} '
            'hasConversation=${_messageModel!.conversation != null} '
            'convId=${_messageModel!.conversation?.id}$sr');
        if (index != null && _messageModel!.messages!.isNotEmpty) {
          if (_searchConversationModel != null) {
            _searchConversationModel!.conversations![index]!.lastMessageTime =
                DateConverter.isoStringToLocalString(
                    _messageModel!.messages![0].createdAt!);
          } else if (_conversationModel != null) {
            _conversationModel!.conversations![index]!.lastMessageTime =
                DateConverter.isoStringToLocalString(
                    _messageModel!.messages![0].createdAt!);
          }
        }
        if (_messageModel?.conversation != null &&
            _conversationModel != null &&
            !_hasAdmin &&
            (_messageModel!.conversation!.senderType == UserType.admin.name ||
                _messageModel!.conversation!.receiverType ==
                    UserType.admin.name) &&
            (Get.context == null ||
                !ResponsiveHelper.isDesktop(Get.context!))) {
          _conversationModel!.conversations!.add(_messageModel!.conversation);
          _hasAdmin = true;
        }
        if (_messageModel?.conversation != null &&
            Get.find<ProfileController>().userInfoModel!.userInfo == null) {
          Get.find<ProfileController>()
              .updateUserWithNewData(_messageModel!.conversation!.sender);
        }
        _sortMessage(notificationBody?.adminId);
      }

      Future.delayed(const Duration(seconds: 2), () {
        getMessages(1, notificationBody, null, effectiveConversationId);
      });
    } else {
      final String bodyPreview = response?.body?.toString() ?? 'null';
      debugPrint('$so FAILED status=${response?.statusCode} bodyPreview=${bodyPreview.substring(0, bodyPreview.length.clamp(0, 200))}$sr');
      bool recoveredByReload = false;
      if ((response?.statusCode ?? 0) >= 500) {
        await getMessages(1, notificationBody, null, effectiveConversationId);
        final String normalizedMessage = message.trim();
        if (normalizedMessage.isNotEmpty) {
          recoveredByReload = _messageModel?.messages?.any(
                (Message m) => (m.message ?? '').trim() == normalizedMessage,
              ) ??
              false;
        }
      }

      if (!recoveredByReload) {
        showCustomSnackBar('failed_to_send_message'.tr);
      } else {
        debugPrint(
            '[SupportFlow][Chat] sendMessage recovered after reload despite API error');
      }
    }
    _isLoading = false;
    update();
    return response;
  }

  void _sortMessage(int? adminId) {
    if (_messageModel!.conversation != null &&
        (_messageModel!.conversation!.receiverType == UserType.user.name ||
            _messageModel!.conversation!.receiverType ==
                UserType.customer.name)) {
      final User? receiver = _messageModel!.conversation!.receiver;
      _messageModel!.conversation!.receiver =
          _messageModel!.conversation!.sender;
      _messageModel!.conversation!.sender = receiver;
    }
    if (adminId != null) {
      _messageModel!.conversation!.receiver = User(
        id: 0,
        fName: Get.find<SplashController>().configModel!.businessName,
        lName: '',
        imageFullUrl: Get.find<SplashController>().configModel!.logoFullUrl,
      );
    }
  }

  /// Silent background refresh — used by the polling timer in ChatScreen.
  /// Does NOT reset _messageModel or show loading. Only updates messages if
  /// the latest message ID or count has changed.
  Future<void> timerRefreshMessages(
      NotificationBodyModel? notificationBody, int? conversationID) async {
    const String logPrefixPoll = '\x1B[38;5;208m[CHAT:poll]';
    const String logReset = '\x1B[0m';

    if (_messageModel == null) {
      debugPrint('$logPrefixPoll skip — _messageModel is null$logReset');
      return;
    }

    final int? effectiveConversationId =
        conversationID ?? notificationBody?.conversationId ?? _messageModel?.conversation?.id;

    debugPrint('$logPrefixPoll tick convID=$conversationID effectiveConvID=$effectiveConversationId '
        'currentMsgCount=${_messageModel!.messages?.length ?? 0} '
        'latestId=${_messageModel!.messages?.isNotEmpty == true ? _messageModel!.messages!.first.id : null}$logReset');

    Response? response;
    if (effectiveConversationId != null) {
      final int fallbackUserId = notificationBody?.restaurantId ??
          notificationBody?.deliverymanId ??
          notificationBody?.adminId ??
          0;
      final String fallbackUserType = notificationBody?.adminId != null
          ? UserType.admin.name
          : notificationBody?.deliverymanId != null
              ? UserType.delivery_man.name
              : UserType.vendor.name;
      debugPrint('$logPrefixPoll fetching by convId=$effectiveConversationId userId=$fallbackUserId type=$fallbackUserType$logReset');
      response = await chatServiceInterface.getMessages(
          1, fallbackUserId, fallbackUserType, effectiveConversationId);
    } else if (notificationBody == null || notificationBody.adminId != null) {
      debugPrint('$logPrefixPoll fetching admin (no convId)$logReset');
      response = await chatServiceInterface.getMessages(1, 0, UserType.admin.name, null);
    } else if (notificationBody.restaurantId != null) {
      debugPrint('$logPrefixPoll fetching vendor restaurantId=${notificationBody.restaurantId}$logReset');
      response = await chatServiceInterface.getMessages(
          1, notificationBody.restaurantId, UserType.vendor.name, null);
    } else if (notificationBody.deliverymanId != null) {
      debugPrint('$logPrefixPoll fetching delivery_man deliverymanId=${notificationBody.deliverymanId}$logReset');
      response = await chatServiceInterface.getMessages(
          1, notificationBody.deliverymanId, UserType.delivery_man.name, null);
    }

    final dynamic body = response?.body;
    debugPrint('$logPrefixPoll response status=${response?.statusCode} bodyIsMap=${body is Map<String, dynamic>}$logReset');

    if (response?.statusCode != null &&
        response!.statusCode! >= 200 &&
        response.statusCode! < 300 &&
        body is Map<String, dynamic>) {
      final ChatModel fresh = ChatModel.fromJson(body);
      fresh.messages ??= [];

      final int? existingLatestId =
          _messageModel!.messages?.isNotEmpty == true ? _messageModel!.messages!.first.id : null;
      final int? freshLatestId =
          fresh.messages!.isNotEmpty ? fresh.messages!.first.id : null;

      debugPrint('$logPrefixPoll compare: existingLatestId=$existingLatestId freshLatestId=$freshLatestId '
          'existingCount=${_messageModel!.messages?.length ?? 0} freshCount=${fresh.messages!.length}$logReset');

      if (freshLatestId != existingLatestId ||
          fresh.messages!.length != (_messageModel!.messages?.length ?? 0)) {
        debugPrint('$logPrefixPoll NEW MESSAGES DETECTED — updating UI$logReset');
        _messageModel!.messages = fresh.messages;
        _messageModel!.totalSize = fresh.totalSize;
        _messageModel!.offset = fresh.offset;
        update();
      } else {
        debugPrint('$logPrefixPoll no change$logReset');
      }
    }
  }

  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    update();
  }

  void setIsMe(bool value) {
    _isMe = value;
  }

  void reloadConversationWithNotification(int conversationID) {
    int index0 = -1;
    Conversation? conversation;
    for (int index = 0;
        index < _conversationModel!.conversations!.length;
        index++) {
      if (_conversationModel!.conversations![index]!.id == conversationID) {
        index0 = index;
        conversation = _conversationModel!.conversations![index];
        break;
      }
    }
    if (index0 != -1) {
      _conversationModel!.conversations!.removeAt(index0);
    }
    conversation!.unreadMessageCount = conversation.unreadMessageCount! + 1;
    _conversationModel!.conversations!.insert(0, conversation);
    update();
  }

  void reloadMessageWithNotification(Message message) {
    _messageModel!.messages!.insert(0, message);
    update();
  }

  void setNotificationBody(NotificationBodyModel notificationBody) {
    _notificationBody = notificationBody;
    update();
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    update();
  }
}
