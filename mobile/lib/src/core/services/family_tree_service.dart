import '../models/family_tree_node.dart';
import 'api_client.dart';

class FamilyTreeService {
  final ApiClient _client;

  FamilyTreeService(this._client);

  Future<FamilyTree> getFamilyTree(String familyId) async {
    final response = await _client.get('/api/family-tree/$familyId');
    return FamilyTree.fromJson(response as Map<String, dynamic>);
  }

  Future<FamilyTreeNode> createOrUpdateNode({
    required String familyId,
    String? id,
    required String fullName,
    DateTime? birthDate,
    DateTime? deathDate,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      if (id != null) 'id': id,
      if (birthDate != null) 'birthDate': birthDate.toIso8601String().split('T').first,
      if (deathDate != null) 'deathDate': deathDate.toIso8601String().split('T').first,
      if (userId != null) 'userId': userId,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _client.post('/api/family-tree/$familyId/nodes', body: body);
    return FamilyTreeNode.fromJson(response as Map<String, dynamic>);
  }

  Future<FamilyRelationship> createRelationship({
    required String familyId,
    required String fromNodeId,
    required String toNodeId,
    required RelationshipType type,
  }) async {
    final body = {
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'type': type.value,
    };

    final response = await _client.post('/api/family-tree/$familyId/relationships', body: body);
    return FamilyRelationship.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteNode({
    required String familyId,
    required String nodeId,
  }) async {
    await _client.delete('/api/family-tree/$familyId/nodes/$nodeId');
  }
}
