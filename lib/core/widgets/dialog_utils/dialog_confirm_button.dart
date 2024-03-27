import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

enum DialogConfirmButtonStyle {
  normal,
  danger;
}

class DialogConfirmButton<T> extends StatelessWidget {
  final DialogConfirmButtonStyle style;
  final String? label;

  /// The value [Navigator.pop] will be called with. If [onPressed] is
  /// specified, this value will be ignored.
  final T? returnValue;

  /// Function called when the button is pressed. Takes precedence over [returnValue].
  final void Function()? onPressed;
  const DialogConfirmButton({
    super.key,
    this.style = DialogConfirmButtonStyle.normal,
    this.label,
    this.returnValue,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        onPressed ?? () => Navigator.of(context).pop(returnValue ?? true);
    return FilledButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(switch (style) {
          DialogConfirmButtonStyle.normal =>
            Theme.of(context).colorScheme.primaryContainer,
          DialogConfirmButtonStyle.danger =>
            Theme.of(context).colorScheme.error,
        }),
      ),
      onPressed: effectiveOnPressed,
      child: Text(label ?? S.of(context)!.confirm,
          style: switch (style) {
            DialogConfirmButtonStyle.normal => TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            DialogConfirmButtonStyle.danger => TextStyle(
                color: Theme.of(context).colorScheme.onError,
              ),
          }),
    );
  }
}
