import 'package:sixam_mart/features/chat/domain/models/chat_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class ConversationsModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Conversation?>? conversations;

  ConversationsModel({this.totalSize, this.limit, this.offset, this.conversations});

  ConversationsModel.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size');
    limit = json.parseInt('limit');
    offset = json.parseInt('offset');
    if (json['conversations'] != null) {
      conversations = <Conversation?>[];
      if (json['conversations'] is List) {
        for (var v in (json['conversations'] as List)) {
          conversations!.add(Conversation.fromJson(v as Map<String, dynamic>));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (conversations != null) {
      data['conversations'] = conversations!.map((v) => v!.toJson()).toList();
    }
    return data;
  }
}

class Conversation {
  int? id;
  int? senderId;
  String? senderType;
  int? receiverId;
  String? receiverType;
  int? unreadMessageCount;
  int? lastMessageId;
  String? lastMessageTime;
  String? createdAt;
  String? updatedAt;
  User? sender;
  User? receiver;
  Message? lastMessage;

  Conversation({
    this.id,
    this.senderId,
    this.senderType,
    this.receiverId,
    this.receiverType,
    this.unreadMessageCount,
    this.lastMessageId,
    this.lastMessageTime,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
    this.lastMessage,
  });

  Conversation.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    senderId = json.parseInt('sender_id');
    senderType = json.parseString('sender_type');
    receiverId = json.parseInt('receiver_id');
    receiverType = json.parseString('receiver_type');
    unreadMessageCount = json.parseInt('unread_message_count');
    lastMessageId = json.parseInt('last_message_id');
    lastMessageTime = json['last_message_time']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    sender = json['sender'] != null ? User.fromJson(json['sender'] as Map<String, dynamic>) : null;
    receiver = json['receiver'] != null ? User.fromJson(json['receiver'] as Map<String, dynamic>) : null;
    lastMessage = json['last_message'] != null ? Message.fromJson(json['last_message'] as Map<String, dynamic>) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sender_id'] = senderId;
    data['sender_type'] = senderType;
    data['receiver_id'] = receiverId;
    data['receiver_type'] = receiverType;
    data['unread_message_count'] = unreadMessageCount;
    data['last_message_id'] = lastMessageId;
    data['last_message_time'] = lastMessageTime;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (sender != null) {
      data['sender'] = sender!.toJson();
    }
    if (receiver != null) {
      data['receiver'] = receiver!.toJson();
    }
    if (lastMessage != null) {
      data['last_message'] = lastMessage!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? imageFullUrl;
  String? createdAt;
  String? updatedAt;

  User({this.id, this.fName, this.lName, this.phone, this.email, this.imageFullUrl, this.createdAt, this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    fName = json['f_name']?.toString();
    lName = json['l_name']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
