import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/user.service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_message_utils.dart';
import '../login_screen.dart';

bool _matchesDeleteConfirmation(String input) {
  final normalized = input.trim().toUpperCase();
  return normalized == 'SIL' || normalized == 'SİL';
}

Future<void> showDeleteAccountDialog(BuildContext context) async {
  final token = context.read<AuthProvider>().token;
  if (token == null || token.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hesap silmek için giriş yapmalısın.'),
        backgroundColor: AppColors.errorRed,
      ),
    );
    return;
  }

  final controller = TextEditingController();
  final authProvider = context.read<AuthProvider>();
  var isDeleting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canDelete = _matchesDeleteConfirmation(controller.text);

          return AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text(
              'Hesabı Sil',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu işlem geri alınamaz.\n'
                  'Skorların, profilin ve hesabın tamamen silinir.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  onChanged: (_) => setDialogState(() {}),
                  enabled: !isDeleting,
                  decoration: const InputDecoration(
                    labelText: 'Onay',
                    hintText: 'SİL yaz',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton.icon(
                onPressed: (!canDelete || isDeleting)
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await UserService().deleteAccount(token);
                          await authProvider.logout();

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          final msg = errorMessageFrom(e);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => isDeleting = false);
                          }
                        }
                      },
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  'Hesabı Sil',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
}

