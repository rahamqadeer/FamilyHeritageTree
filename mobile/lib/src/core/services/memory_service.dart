import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';
import 'api_client.dart';

class MemoryService {
  final ApiClient _client;
  final _supabase = Supabase.instance.client;

  MemoryService(this._client);

  Future<List<Memory>> listMemories(String familyId) async {
    final response = await _client.get('/api/memories', queryParams: {'familyId': familyId});
    final list = response as List<dynamic>;
    return list.map((json) => Memory.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Memory> getMemory(String memoryId) async {
    final response = await _client.get('/api/memories/$memoryId');
    return Memory.fromJson(response as Map<String, dynamic>);
  }

  Future<Memory> createMemory({
    required String familyId,
    required String title,
    String? description,
    required MediaType mediaType,
    String? storagePath,
    String? event,
    DateTime? eventDate,
    List<String>? tags,
    List<String>? peopleNodeIds,
  }) async {
    final body = <String, dynamic>{
      'familyId': familyId,
      'title': title,
      'mediaType': mediaType.value,
      if (description != null) 'description': description,
      if (storagePath != null) 'storagePath': storagePath,
      if (event != null) 'event': event,
      if (eventDate != null) 'eventDate': eventDate.toIso8601String().split('T').first,
      if (tags != null) 'tags': tags,
      if (peopleNodeIds != null) 'peopleNodeIds': peopleNodeIds,
    };

    final response = await _client.post('/api/memories', body: body);
    return Memory.fromJson(response as Map<String, dynamic>);
  }

  Future<InheritanceRule> createInheritanceRule({
    required String memoryId,
    required String familyId,
    required String beneficiaryNodeId,
    required ConditionType conditionType,
    DateTime? unlockDate,
    int? unlockAge,
  }) async {
    final body = <String, dynamic>{
      'familyId': familyId,
      'beneficiaryNodeId': beneficiaryNodeId,
      'conditionType': conditionType.value,
      if (unlockDate != null) 'unlockDate': unlockDate.toIso8601String().split('T').first,
      if (unlockAge != null) 'unlockAge': unlockAge,
    };

    final response = await _client.post('/api/memories/$memoryId/inheritance-rules', body: body);
    return InheritanceRule.fromJson(response as Map<String, dynamic>);
  }

  Future<String> uploadMedia({
    required String familyId,
    required File file,
    required MediaType mediaType,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storagePath = 'memories/$familyId/$fileName';

    await _supabase.storage
        .from('memories')
        .upload(storagePath, file);

    final publicUrl = _supabase.storage
        .from('memories')
        .getPublicUrl(storagePath);

    return publicUrl;
  }
}
