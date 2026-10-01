import 'package:flutter/material.dart';

void dismissKeyboard(BuildContext context) {
  final currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      onPanDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
