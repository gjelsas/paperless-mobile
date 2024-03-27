import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class FieldSuggestionsWidget<T> extends StatelessWidget {
  final Iterable<T> suggestions;
  final T? currentValue;
  final Iterable<T>? currentValues;
  final String Function(T suggestion) valueTransformer;
  final ValueChanged<T> onSuggestionSelected;

  const FieldSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.valueTransformer,
    required this.onSuggestionSelected,
    this.currentValue,
    this.currentValues,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = suggestions.whereNot((element) =>
        element == currentValue || currentValues?.contains(element) == true);
    if (filteredSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        children: [
          Text(S.of(context)!.suggestions),
          for (final suggestion in filteredSuggestions)
            Text.rich(
              TextSpan(
                text: valueTransformer(suggestion),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    onSuggestionSelected(suggestion);
                  },
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ).paddedOnly(right: 8),
        ],
      ),
    );
  }
}
