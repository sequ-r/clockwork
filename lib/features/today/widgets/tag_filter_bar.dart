import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/features/tags/tag_manager_dialog.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Horizontal filter strip that lets the user scope today's task list
/// to a single tag, or clear the filter.
class TagFilterBar extends StatelessWidget {
  /// Creates the tag filter strip.
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final appVm = deps.appViewModel;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: appVm,
      builder: (context, _) {
        final selected = appVm.tagFilter;

        return StreamBuilder<List<Tag>>(
          stream: deps.tagRepository.watchAll(),
          builder: (context, snapshot) {
            final tags = snapshot.data ?? const [];

            return SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.allProjects),
                      selected: selected == null,
                      onSelected: (_) => appVm.setTagFilter(null),
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
                        onSelected: (_) => appVm.setTagFilter(tag.id),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.settings_outlined, size: 16),
                      label: Text(l10n.manageProjects),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const TagManagerDialog(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
