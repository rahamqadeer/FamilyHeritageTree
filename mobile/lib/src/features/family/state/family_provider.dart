import 'package:flutter/foundation.dart';
import '../../../core/models/family.dart';
import '../../../core/models/family_tree_node.dart';
import '../../../core/services/service_locator.dart';

class FamilyProvider extends ChangeNotifier {
  List<Family> _families = [];
  Family? _selectedFamily;
  FamilyTree? _familyTree;
  bool _loading = false;
  String? _error;

  List<Family> get families => _families;
  Family? get selectedFamily => _selectedFamily;
  FamilyTree? get familyTree => _familyTree;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasFamily => _families.isNotEmpty;

  Future<void> loadFamilies() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _families = await services.familyService.listFamilies();
      if (_families.isNotEmpty && _selectedFamily == null) {
        _selectedFamily = _families.first;
        await loadFamilyTree();
      }
    } catch (e) {
      _error = 'Failed to load families: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectFamily(Family family) async {
    _selectedFamily = family;
    notifyListeners();
    await loadFamilyTree();
  }

  Future<void> createFamily(String name) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final family = await services.familyService.createFamily(name);
      _families.add(family);
      _selectedFamily = family;
      _familyTree = FamilyTree(nodes: [], relationships: []);
    } catch (e) {
      _error = 'Failed to create family: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> inviteMember({
    required String email,
    String role = 'ADULT',
  }) async {
    if (_selectedFamily == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await services.familyService.inviteMember(
        familyId: _selectedFamily!.id,
        email: email,
        role: role,
      );
    } catch (e) {
      _error = 'Failed to invite member: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadFamilyTree() async {
    if (_selectedFamily == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _familyTree = await services.familyTreeService.getFamilyTree(_selectedFamily!.id);
    } catch (e) {
      _error = 'Failed to load family tree: ${e.toString()}';
      _familyTree = FamilyTree(nodes: [], relationships: []);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<FamilyTreeNode?> addFamilyMember({
    required String fullName,
    DateTime? birthDate,
    DateTime? deathDate,
    Map<String, dynamic>? metadata,
  }) async {
    if (_selectedFamily == null) return null;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final node = await services.familyTreeService.createOrUpdateNode(
        familyId: _selectedFamily!.id,
        fullName: fullName,
        birthDate: birthDate,
        deathDate: deathDate,
        metadata: metadata,
      );
      await loadFamilyTree();
      return node;
    } catch (e) {
      _error = 'Failed to add family member: ${e.toString()}';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFamilyMember({
    required String nodeId,
    required String fullName,
    DateTime? birthDate,
    DateTime? deathDate,
    Map<String, dynamic>? metadata,
  }) async {
    if (_selectedFamily == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await services.familyTreeService.createOrUpdateNode(
        familyId: _selectedFamily!.id,
        id: nodeId,
        fullName: fullName,
        birthDate: birthDate,
        deathDate: deathDate,
        metadata: metadata,
      );
      await loadFamilyTree();
      return true;
    } catch (e) {
      _error = 'Failed to update family member: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addRelationship({
    required String fromNodeId,
    required String toNodeId,
    required RelationshipType type,
  }) async {
    if (_selectedFamily == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await services.familyTreeService.createRelationship(
        familyId: _selectedFamily!.id,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        type: type,
      );
      await loadFamilyTree();
      return true;
    } catch (e) {
      _error = 'Failed to add relationship: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFamilyMember(String nodeId) async {
    if (_selectedFamily == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await services.familyTreeService.deleteNode(
        familyId: _selectedFamily!.id,
        nodeId: nodeId,
      );
      await loadFamilyTree();
      return true;
    } catch (e) {
      _error = 'Failed to delete family member: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
