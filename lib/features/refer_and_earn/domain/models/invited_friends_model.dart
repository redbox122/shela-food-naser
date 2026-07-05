// نموذج استجابة API الأصدقاء المدعوين
// GET /api/v2/customer/referrals/invited-friends

class InvitedFriendsModel {
  final ReferralSummary? summary;
  final List<InvitedFriendItem> friends;
  final ReferralPagination? pagination;

  InvitedFriendsModel({
    this.summary,
    this.friends = const [],
    this.pagination,
  });

  factory InvitedFriendsModel.fromJson(Map<String, dynamic> json) {
    return InvitedFriendsModel(
      summary: json['summary'] is Map
          ? ReferralSummary.fromJson(
              (json['summary'] as Map).cast<String, dynamic>())
          : null,
      friends: json['friends'] is List
          ? (json['friends'] as List)
              .whereType<Map>()
              .map((e) => InvitedFriendItem.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <InvitedFriendItem>[],
      pagination: json['pagination'] is Map
          ? ReferralPagination.fromJson(
              (json['pagination'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

class ReferralSummary {
  final int totalInvites;
  final double totalRewards;
  final String currency;

  ReferralSummary({
    this.totalInvites = 0,
    this.totalRewards = 0,
    this.currency = '',
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    return ReferralSummary(
      totalInvites: _toInt(json['total_invites']),
      totalRewards: _toDouble(json['total_rewards']),
      currency: json['currency']?.toString() ?? '',
    );
  }
}

class InvitedFriendItem {
  final int? userId;
  final String name;
  final String phone;
  final String avatarFullUrl;
  final String registeredAt;
  final String dateGroupKey;
  final String dateGroupLabel;
  final String status;
  final String statusLabel;
  final double rewardAmount;
  final String rewardText;
  final String rewardStatus;

  InvitedFriendItem({
    this.userId,
    this.name = '',
    this.phone = '',
    this.avatarFullUrl = '',
    this.registeredAt = '',
    this.dateGroupKey = '',
    this.dateGroupLabel = '',
    this.status = '',
    this.statusLabel = '',
    this.rewardAmount = 0,
    this.rewardText = '',
    this.rewardStatus = '',
  });

  /// هل تم تسجيل الصديق (يُعتبر مسجّلاً إن كانت الحالة registered/completed)
  bool get isRegistered {
    final String s = status.toLowerCase();
    return s == 'registered' || s == 'completed' || s == 'rewarded';
  }

  factory InvitedFriendItem.fromJson(Map<String, dynamic> json) {
    return InvitedFriendItem(
      userId: _toIntOrNull(json['user_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarFullUrl: json['avatar_full_url']?.toString() ?? '',
      registeredAt: json['registered_at']?.toString() ?? '',
      dateGroupKey: json['date_group_key']?.toString() ?? '',
      dateGroupLabel: json['date_group_label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      rewardAmount: _toDouble(json['reward_amount']),
      rewardText: json['reward_text']?.toString() ?? '',
      rewardStatus: json['reward_status']?.toString() ?? '',
    );
  }
}

class ReferralPagination {
  final int offset;
  final int limit;
  final int totalSize;

  ReferralPagination({
    this.offset = 1,
    this.limit = 10,
    this.totalSize = 0,
  });

  factory ReferralPagination.fromJson(Map<String, dynamic> json) {
    return ReferralPagination(
      offset: _toInt(json['offset']),
      limit: _toInt(json['limit']),
      totalSize: _toInt(json['total_size']),
    );
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
