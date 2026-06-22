import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/i18n/locale_controller.dart';

/// Переключатель языка приложения.
/// Вариант «Системный» (null) — следовать за языком телефона.
/// Можно положить в profile_screen списком пунктов или открыть как лист.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider); // null = системный
    final controller = ref.read(localeControllerProvider.notifier);

    Widget tile(String title, Locale? value) {
      final selected = current == value ||
          (value == null && current == null);
      return ListTile(
        title: Text(title),
        trailing: selected
            ? const Icon(Icons.check, color: Colors.amber)
            : null,
        onTap: () => controller.setLocale(value),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.language,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        tile(l10n.languageSystem, null),
        tile(l10n.languageRussian, const Locale('ru')),
        tile(l10n.languageEnglish, const Locale('en')),
      ],
    );
  }
}

/// Открыть переключатель языка как нижний лист.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const SafeArea(child: LanguagePicker()),
  );
}
