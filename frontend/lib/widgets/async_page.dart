import 'package:flutter/material.dart';

import '../theme.dart';
import 'page_header.dart';

/// Scaffold + header + load/error handling for the simple drill-in pages.
class AsyncPage<T> extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final T? data;
  final bool errored;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  const AsyncPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.data,
    required this.errored,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: title, onBack: onBack),
            Expanded(
              child: errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load this page.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : data == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : builder(data as T),
            ),
          ],
        ),
      ),
    );
  }
}
