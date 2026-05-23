import 'package:family_digital_heritage_vault/src/core/models/family_tree_node.dart';
import 'package:family_digital_heritage_vault/src/core/theme/app_theme.dart';
import 'package:family_digital_heritage_vault/src/features/family_tree/presentation/member_form_widgets.dart';
import 'package:flutter/material.dart';

/// Visual family tree grouped by generation with name and birth year.
class FamilyTreeDiagramView extends StatelessWidget {
  final FamilyTree tree;
  final void Function(FamilyTreeNode node)? onNodeTap;

  const FamilyTreeDiagramView({
    super.key,
    required this.tree,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tree.nodes.isEmpty) {
      return const Center(
        child: Text(
          'Add members and link them with relationships to build your tree.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final roots = _findRoots(tree);
    final hasLinks = tree.relationships.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: 0.4,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: hasLinks && roots.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: roots
                            .map(
                              (root) => _SubtreeWidget(
                                node: root,
                                tree: tree,
                                onNodeTap: onNodeTap,
                              ),
                            )
                            .toList(),
                      )
                    : _GenerationRowsView(tree: tree, onNodeTap: onNodeTap),
              ),
            ),
          ),
        );
      },
    );
  }

  List<FamilyTreeNode> _findRoots(FamilyTree tree) {
    final childIds = tree.relationships
        .where((r) => r.type == RelationshipType.parent)
        .map((r) => r.toNodeId)
        .toSet();
    final roots = tree.nodes.where((n) => !childIds.contains(n.id)).toList();
    roots.sort(_compareNodes);
    return roots;
  }

  static int _compareNodes(FamilyTreeNode a, FamilyTreeNode b) {
    final g = a.generation.compareTo(b.generation);
    if (g != 0) return g;
    final ay = a.birthDate?.year ?? 9999;
    final by = b.birthDate?.year ?? 9999;
    if (ay != by) return ay.compareTo(by);
    return a.fullName.compareTo(b.fullName);
  }
}

class _GenerationRowsView extends StatelessWidget {
  final FamilyTree tree;
  final void Function(FamilyTreeNode node)? onNodeTap;

  const _GenerationRowsView({
    required this.tree,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final byGen = <int, List<FamilyTreeNode>>{};
    for (final n in tree.nodes) {
      byGen.putIfAbsent(n.generation, () => []).add(n);
    }
    final levels = byGen.keys.toList()..sort();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final level in levels) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              FamilyTreeNode.labelForGeneration(level),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: (byGen[level]!..sort(FamilyTreeDiagramView._compareNodes))
                .map(
                  (n) => _TreeNodeChip(
                    node: n,
                    onTap: onNodeTap != null ? () => onNodeTap!(n) : null,
                  ),
                )
                .toList(),
          ),
          if (level != levels.last)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.arrow_downward, color: AppColors.textSecondary),
            ),
        ],
      ],
    );
  }
}

class _SubtreeWidget extends StatelessWidget {
  final FamilyTreeNode node;
  final FamilyTree tree;
  final void Function(FamilyTreeNode node)? onNodeTap;

  const _SubtreeWidget({
    required this.node,
    required this.tree,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = tree.getChildrenOf(node.id)
      ..sort(FamilyTreeDiagramView._compareNodes);
    final spouses = tree.getSpousesOf(node.id)
      ..sort(FamilyTreeDiagramView._compareNodes);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TreeNodeChip(
              node: node,
              onTap: onNodeTap != null ? () => onNodeTap!(node) : null,
            ),
            for (final spouse in spouses) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.favorite, size: 16, color: AppColors.accent),
              ),
              _TreeNodeChip(
                node: spouse,
                onTap: onNodeTap != null ? () => onNodeTap!(spouse) : null,
              ),
            ],
          ],
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: 2,
            height: 24,
            color: AppColors.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: children
                .map(
                  (child) => _SubtreeWidget(
                    node: child,
                    tree: tree,
                    onNodeTap: onNodeTap,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _TreeNodeChip extends StatelessWidget {
  final FamilyTreeNode node;
  final VoidCallback? onTap;

  const _TreeNodeChip({
    required this.node,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = memberCardStyleForGender(node.gender);
    final titleColor =
        style.useLightText ? Colors.white : AppColors.textPrimary;
    final subtitleColor = style.useLightText
        ? Colors.white.withOpacity(0.9)
        : AppColors.textSecondary;
    final year = node.birthDate?.year;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: style.gradient,
            borderRadius: BorderRadius.circular(12),
            border: style.border,
            boxShadow: [
              BoxShadow(
                color: style.shadowColor,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(
                node: node,
                size: 40,
                textColor: titleColor,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 6),
              Text(
                node.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: titleColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                year != null ? 'b. $year' : 'Year unknown',
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
