import '../models/family.dart';
import 'api_client.dart';

class FamilyService {
  final ApiClient _client;

  FamilyService(this._client);

  Future<List<Family>> listFamilies() async {
    final response = await _client.get('/api/families');
    final list = response as List<dynamic>;
    return list.map((json) => Family.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Family> createFamily(String name) async {
    final response = await _client.post('/api/families', body: {'name': name});
    return Family.fromJson({
      ...response as Map<String, dynamic>,
      'role': 'ADMIN',
    });
  }

  Future<void> inviteMember({
    required String familyId,
    required String email,
    String role = 'ADULT',
  }) async {
    await _client.post(
      '/api/families/$familyId/invite',
      body: {'email': email, 'role': role},
    );
  }
}
