import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/widgets/hint_state_builder.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/settings/view/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DocumentNotesWidget extends StatefulWidget {
  final DocumentModel document;
  const DocumentNotesWidget({
    super.key,
    required this.document,
  });

  @override
  State<DocumentNotesWidget> createState() => _DocumentNotesWidgetState();
}

class _DocumentNotesWidgetState extends State<DocumentNotesWidget> {
  final _noteContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isNoteSubmitting = false;

  @override
  Widget build(BuildContext context) {
    const hintKey = "hideMarkdownSyntaxHint";
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildNoteHint(hintKey),
        ),
        SliverToBoxAdapter(
          child: _buildNoteForm(context),
        ),
        SliverToBoxAdapter(
          child: Divider(
            indent: 8,
            endIndent: 8,
          ),
        ),
        if (widget.document.notes.isEmpty)
          SliverToBoxAdapter(
            child: GlobalSettingsBuilder(
              builder: (context, settings) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "There are no notes associated with this document, yet.", //TODO: INTL
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: _buildNoteList(),
          ),
      ],
    );
  }

  Widget _buildNoteList() {
    return SliverList.separated(
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final note = widget.document.notes.elementAt(index);
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Html(
                data: markdownToHtml(note.note!),
                onLinkTap: (url, attributes, element) async {
                  if (url?.isEmpty ?? true) {
                    return;
                  }
                  if (await canLaunchUrlString(url!)) {
                    launchUrlString(url);
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (note.created != null)
                    Text(
                      DateFormat.yMMMd()
                          .addPattern('\u2014')
                          .add_jm()
                          .format(note.created!),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.5),
                          ),
                    ),
                  IconButton(
                    tooltip: S.of(context)!.delete,
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<DocumentDetailsCubit>().deleteNote(note);
                    },
                  ),
                ],
              ),
            ],
          ).padded(16),
        );
      },
      itemCount: widget.document.notes.length,
    );
  }

  HintStateBuilder _buildNoteHint(String hintKey) {
    return HintStateBuilder(
      listenKey: hintKey,
      builder: (context, box) {
        return HintCard(
          hintText: S.of(context)!.notesMarkdownSyntaxSupportHint,
          show: !box.get(hintKey, defaultValue: false)!,
          onHintAcknowledged: () {
            box.put(hintKey, true);
          },
        ).padded();
      },
    );
  }

  Widget _buildNoteForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextFormField(
              controller: _noteContentController,
              maxLines: null,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.thisFieldIsRequired;
                }
                return null;
              },
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: S.of(context)!.newNote,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _noteContentController.clear();
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.note_add_outlined)
                    .loading(loading: _isNoteSubmitting),
                label: Text(S.of(context)!.addNote),
                onPressed: _isNoteSubmitting ? null : () => _onSubmit(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isNoteSubmitting = true;
      });
      try {
        await context
            .read<DocumentDetailsCubit>()
            .addNote(_noteContentController.text.trim());
        _noteContentController.clear();
      } finally {
        setState(() {
          _isNoteSubmitting = false;
        });
      }
    }
  }
}
