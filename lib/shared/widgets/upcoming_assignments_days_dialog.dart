import 'package:flutter/material.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';

/// 課題表示範囲設定の共通ダイアログ
class UpcomingAssignmentsDaysDialog extends StatelessWidget {
  const UpcomingAssignmentsDaysDialog._({required this.settingsProvider});

  final SettingsProvider settingsProvider;

  static Future<void> show(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return showDialog(
      context: context,
      builder:
          (context) => UpcomingAssignmentsDaysDialog._(
            settingsProvider: settingsProvider,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDays = settingsProvider.upcomingAssignmentsDays;
    final daysOptions = [1, 3, 7, 14, 21, 30];

    return AlertDialog(
      title: const Text('課題表示範囲'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ダッシュボードの「期限が近い課題」カードに表示する日数範囲を設定します。',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: currentDays,
            decoration: const InputDecoration(
              labelText: '表示する日数範囲',
              border: OutlineInputBorder(),
            ),
            items:
                daysOptions.map((days) {
                  return DropdownMenuItem<int>(
                    value: days,
                    child: Text(_getDaysDescription(days)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                settingsProvider.setUpcomingAssignmentsDays(value);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }

  String _getDaysDescription(int days) {
    switch (days) {
      case 1:
        return '今日と明日の課題のみ';
      case 3:
        return '3日以内の緊急課題';
      case 7:
        return '1週間以内の課題（推奨）';
      case 14:
        return '2週間以内の課題';
      case 21:
        return '3週間以内の課題';
      case 30:
        return '1ヶ月以内の課題';
      default:
        return '';
    }
  }
}
