import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';

class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).value ?? [];
    final selected = ref.watch(tagFilterProvider);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(tagFilterProvider.notifier).set(null),
            ),
          ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: CircleAvatar(
                  radius: 6,
                  backgroundColor: Color(tag.color),
                ),
                label: Text(tag.name),
                selected: selected == tag.id,
                onSelected: (_) =>
                    ref.read(tagFilterProvider.notifier).set(tag.id),
              ),
            ),
        ],
      ),
    );
  }
}
