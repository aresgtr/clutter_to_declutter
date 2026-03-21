import 'package:flutter/material.dart';

class ExpandableItemCard extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? actionBar;

  const ExpandableItemCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    this.actionBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          child: ListTile(
            onTap: onToggle,
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 0),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: actionBar ?? const SizedBox.shrink(),
              ),
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 150),
        ),
      ],
    );
  }
}

