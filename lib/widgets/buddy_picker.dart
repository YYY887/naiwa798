import 'package:flutter/material.dart';

import '../core/app_palette.dart';
import '../core/app_state.dart';
import '../models/buddy_character.dart';
import 'app_ui.dart';

Future<void> showBuddyPicker(BuildContext context, AppState state) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('选择你的喝水搭子', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '也可以长按首页人物来更换',
                style: TextStyle(color: AppColors(state.dark).muted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final character in BuddyCharacter.values)
                    SizedBox(
                      width: (MediaQuery.sizeOf(sheetContext).width - 60) / 2,
                      child: AppSurface(
                        selected: state.buddy == character,
                        padding: const EdgeInsets.all(12),
                        onTap: () async {
                          try {
                            await state.setBuddy(character);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          } catch (_) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('角色保存失败，请重试')),
                              );
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              character.asset,
                              height: 145,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            Text(character.label, textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text(
                              state.buddy == character ? '当前角色' : '选择角色',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors(state.dark).accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
