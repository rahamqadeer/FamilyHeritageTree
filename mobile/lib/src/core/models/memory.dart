enum MediaType {
  image,
  video,
  audio,
  document;

  String get value {
    switch (this) {
      case MediaType.image:
        return 'IMAGE';
      case MediaType.video:
        return 'VIDEO';
      case MediaType.audio:
        return 'AUDIO';
      case MediaType.document:
        return 'DOCUMENT';
    }
  }

  static MediaType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'IMAGE':
        return MediaType.image;
      case 'VIDEO':
        return MediaType.video;
      case 'AUDIO':
        return MediaType.audio;
      case 'DOCUMENT':
        return MediaType.document;
      default:
        return MediaType.image;
    }
  }

  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Photo';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
      case MediaType.document:
        return 'Document';
    }
  }
}

class Memory {
  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final String? description;
  final MediaType mediaType;
  final String? storagePath;
  final String? event;
  final DateTime? eventDate;
  final List<String>? tags;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.mediaType,
    this.storagePath,
    this.event,
    this.eventDate,
    this.tags,
    required this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaType: MediaType.fromString(json['media_type'] as String),
      storagePath: json['storage_path'] as String?,
      event: json['event'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'title': title,
    if (description != null) 'description': description,
    'media_type': mediaType.value,
    if (storagePath != null) 'storage_path': storagePath,
    if (event != null) 'event': event,
    if (eventDate != null) 'event_date': eventDate!.toIso8601String().split('T').first,
    if (tags != null) 'tags': tags,
  };

  String? get publicUrl {
    if (storagePath == null) return null;
    // Supabase public URL pattern
    return storagePath;
  }
}

enum ConditionType {
  unlockAtDate,
  unlockAtAge;

  String get value {
    switch (this) {
      case ConditionType.unlockAtDate:
        return 'UNLOCK_AT_DATE';
      case ConditionType.unlockAtAge:
        return 'UNLOCK_AT_AGE';
    }
  }

  static ConditionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'UNLOCK_AT_DATE':
        return ConditionType.unlockAtDate;
      case 'UNLOCK_AT_AGE':
        return ConditionType.unlockAtAge;
      default:
        return ConditionType.unlockAtDate;
    }
  }

  String get displayName {
    switch (this) {
      case ConditionType.unlockAtDate:
        return 'Unlock on specific date';
      case ConditionType.unlockAtAge:
        return 'Unlock when beneficiary reaches age';
    }
  }
}

class InheritanceRule {
  final String id;
  final String memoryId;
  final String familyId;
  final String beneficiaryNodeId;
  final ConditionType conditionType;
  final DateTime? unlockDate;
  final int? unlockAge;
  final String createdBy;
  final DateTime createdAt;

  InheritanceRule({
    required this.id,
    required this.memoryId,
    required this.familyId,
    required this.beneficiaryNodeId,
    required this.conditionType,
    this.unlockDate,
    this.unlockAge,
    required this.createdBy,
    required this.createdAt,
  });

  factory InheritanceRule.fromJson(Map<String, dynamic> json) {
    return InheritanceRule(
      id: json['id'] as String,
      memoryId: json['memory_id'] as String,
      familyId: json['family_id'] as String,
      beneficiaryNodeId: json['beneficiary_node_id'] as String,
      conditionType: ConditionType.fromString(json['condition_type'] as String),
      unlockDate: json['unlock_date'] != null
          ? DateTime.parse(json['unlock_date'] as String)
          : null,
      unlockAge: json['unlock_age'] as int?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'memory_id': memoryId,
    'family_id': familyId,
    'beneficiary_node_id': beneficiaryNodeId,
    'condition_type': conditionType.value,
    if (unlockDate != null) 'unlock_date': unlockDate!.toIso8601String().split('T').first,
    if (unlockAge != null) 'unlock_age': unlockAge,
  };
}
