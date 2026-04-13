import 'package:flutter/material.dart';

/// A reusable confirmation dialog
/// 
/// Phase 1: Critical Security & Stability - Created missing file
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Show a confirmation dialog and return the result
/// 
/// Returns true if confirmed, false if cancelled
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

/// Show a delete confirmation dialog
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  String itemName = 'this item',
}) async {
  return showConfirmDialog(
    context,
    title: 'Delete Confirmation',
    message: 'Are you sure you want to delete $itemName? This action cannot be undone.',
    confirmText: 'Delete',
    cancelText: 'Cancel',
    isDestructive: true,
  );
}

/// Show a logout confirmation dialog
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  return showConfirmDialog(
    context,
    title: 'Logout',
    message: 'Are you sure you want to logout?',
    confirmText: 'Logout',
    cancelText: 'Cancel',
  );
}
