import 'package:sixam_mart/common/utils/json_parser.dart';

class AnalyticsInsights {
  final List<Insight> insights;
  final List<String> smartTips;
  final String generatedAt;

  const AnalyticsInsights({
    required this.insights,
    required this.smartTips,
    required this.generatedAt,
  });

  factory AnalyticsInsights.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsights(
      insights: (json['insights'] as List<dynamic>?)
              ?.map((item) => Insight.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      smartTips: (json['smart_tips'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      generatedAt: json.parseString('generated_at') ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insights': insights.map((item) => item.toJson()).toList(),
      'smart_tips': smartTips,
      'generated_at': generatedAt,
    };
  }
}

class Insight {
  final String type;
  final String title;
  final String message;
  final String severity;
  final String? action;
  final int? productId;
  final String? description;
  final String? priority;
  final Map<String, dynamic>? metadata;

  const Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.action,
    this.productId,
    this.description,
    this.priority,
    this.metadata,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json.parseString('type') ?? '',
      title: json.parseString('title') ?? '',
      message: json.parseString('message') ?? '',
      severity: json.parseString('severity') ?? 'info',
      action: json.parseString('action'),
      productId: json.parseInt('product_id'),
      description: json.parseString('description'),
      priority: json.parseString('priority'),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'severity': severity,
      if (action != null) 'action': action,
      if (productId != null) 'product_id': productId,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
