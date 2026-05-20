class FamilyTreeNode {
  final String id;
  final String familyId;
  final String fullName;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  FamilyTreeNode({
    required this.id,
    required this.familyId,
    required this.fullName,
    this.birthDate,
    this.deathDate,
    this.userId,
    this.metadata,
    required this.createdAt,
  });

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    return FamilyTreeNode(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      fullName: json['full_name'] as String,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      deathDate: json['death_date'] != null
          ? DateTime.parse(json['death_date'] as String)
          : null,
      userId: json['user_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'full_name': fullName,
    if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T').first,
    if (deathDate != null) 'death_date': deathDate!.toIso8601String().split('T').first,
    if (userId != null) 'user_id': userId,
    if (metadata != null) 'metadata': metadata,
  };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  int? get age {
    if (birthDate == null) return null;
    final endDate = deathDate ?? DateTime.now();
    return endDate.year - birthDate!.year;
  }

  bool get isDeceased => deathDate != null;
}

enum RelationshipType {
  parent,
  child,
  spouse;

  String get value {
    switch (this) {
      case RelationshipType.parent:
        return 'PARENT';
      case RelationshipType.child:
        return 'CHILD';
      case RelationshipType.spouse:
        return 'SPOUSE';
    }
  }

  static RelationshipType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PARENT':
        return RelationshipType.parent;
      case 'CHILD':
        return RelationshipType.child;
      case 'SPOUSE':
        return RelationshipType.spouse;
      default:
        throw ArgumentError('Unknown relationship type: $value');
    }
  }
}

class FamilyRelationship {
  final String id;
  final String familyId;
  final String fromNodeId;
  final String toNodeId;
  final RelationshipType type;
  final DateTime createdAt;

  FamilyRelationship({
    required this.id,
    required this.familyId,
    required this.fromNodeId,
    required this.toNodeId,
    required this.type,
    required this.createdAt,
  });

  factory FamilyRelationship.fromJson(Map<String, dynamic> json) {
    return FamilyRelationship(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      fromNodeId: json['from_node_id'] as String,
      toNodeId: json['to_node_id'] as String,
      type: RelationshipType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'from_node_id': fromNodeId,
    'to_node_id': toNodeId,
    'type': type.value,
  };
}

class FamilyTree {
  final List<FamilyTreeNode> nodes;
  final List<FamilyRelationship> relationships;

  FamilyTree({
    required this.nodes,
    required this.relationships,
  });

  factory FamilyTree.fromJson(Map<String, dynamic> json) {
    return FamilyTree(
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => FamilyTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List<dynamic>)
          .map((e) => FamilyRelationship.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  FamilyTreeNode? getNodeById(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  List<FamilyTreeNode> getParentsOf(String nodeId) {
    final parentIds = relationships
        .where((r) => r.toNodeId == nodeId && r.type == RelationshipType.parent)
        .map((r) => r.fromNodeId)
        .toList();
    return nodes.where((n) => parentIds.contains(n.id)).toList();
  }

  List<FamilyTreeNode> getChildrenOf(String nodeId) {
    final childIds = relationships
        .where((r) => r.fromNodeId == nodeId && r.type == RelationshipType.parent)
        .map((r) => r.toNodeId)
        .toList();
    return nodes.where((n) => childIds.contains(n.id)).toList();
  }

  List<FamilyTreeNode> getSpousesOf(String nodeId) {
    final spouseIds = relationships
        .where((r) =>
            (r.fromNodeId == nodeId || r.toNodeId == nodeId) &&
            r.type == RelationshipType.spouse)
        .map((r) => r.fromNodeId == nodeId ? r.toNodeId : r.fromNodeId)
        .toList();
    return nodes.where((n) => spouseIds.contains(n.id)).toList();
  }
}
