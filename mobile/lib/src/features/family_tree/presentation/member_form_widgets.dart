import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:family_digital_heritage_vault/src/core/models/family_tree_node.dart';
import 'package:family_digital_heritage_vault/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile photo picker for add/edit member forms.
class MemberPhotoPicker extends StatelessWidget {
  final XFile? pickedFile;
  final String? existingPhotoUrl;
  final VoidCallback onPickGallery;
  final VoidCallback? onClear;

  const MemberPhotoPicker({
    super.key,
    this.pickedFile,
    this.existingPhotoUrl,
    required this.onPickGallery,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPickGallery,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.divider,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPreview(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPickGallery,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(pickedFile != null || existingPhotoUrl != null
                ? 'Change photo'
                : 'Add photo'),
          ),
          if ((pickedFile != null || existingPhotoUrl != null) && onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text('Remove photo'),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (pickedFile != null) {
      return FutureBuilder<Uint8List>(
        future: pickedFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }
    if (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: existingPhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 40),
      );
    }
    return const Icon(Icons.person_add_alt_1, size: 40, color: AppColors.textSecondary);
  }
}

/// Gender dropdown for member forms.
class MemberGenderField extends StatelessWidget {
  final MemberGender value;
  final ValueChanged<MemberGender> onChanged;

  const MemberGenderField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MemberGender>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.wc_outlined),
      ),
      items: MemberGender.values
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g.label),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Circular avatar for cards and detail (photo or initials).
class MemberAvatar extends StatelessWidget {
  final FamilyTreeNode node;
  final double size;
  final Color? textColor;
  final Color? backgroundColor;

  const MemberAvatar({
    super.key,
    required this.node,
    this.size = 60,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = node.displayPhotoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _initialsFallback(),
              errorWidget: (_, __, ___) => _initialsFallback(),
            )
          : _initialsFallback(),
    );
  }

  Widget _initialsFallback() {
    return Center(
      child: Text(
        node.initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

IconData genderIcon(MemberGender gender) {
  switch (gender) {
    case MemberGender.male:
      return Icons.male;
    case MemberGender.female:
      return Icons.female;
    case MemberGender.other:
      return Icons.transgender;
    case MemberGender.unspecified:
      return Icons.person_outline;
  }
}
