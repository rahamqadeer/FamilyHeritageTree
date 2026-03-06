import 'package:family_digital_heritage_vault/src/features/auth/state/auth_provider.dart';
import 'package:family_digital_heritage_vault/src/features/family_tree/presentation/family_tree_screen.dart';
import 'package:family_digital_heritage_vault/src/features/memories/presentation/memory_upload_screen.dart';
import 'package:family_digital_heritage_vault/src/features/memories/presentation/memory_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Vault'),
        actions: [
          IconButton(
            onPressed: () {
              auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _DashboardTile(
            icon: Icons.account_tree,
            label: 'Family Tree',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FamilyTreeScreen()),
              );
            },
          ),
          _DashboardTile(
            icon: Icons.cloud_upload,
            label: 'Upload Memory',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemoryUploadScreen()),
              );
            },
          ),
          _DashboardTile(
            icon: Icons.photo_library,
            label: 'View Memories',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemoryViewerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
