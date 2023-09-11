import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class AddSavedViewPage extends StatefulWidget {
  final DocumentFilter? initialFilter;
  const AddSavedViewPage({
    super.key,
    this.initialFilter,
  });

  @override
  State<AddSavedViewPage> createState() => _AddSavedViewPageState();
}

class _AddSavedViewPageState extends State<AddSavedViewPage> {
  static const fkName = 'name';
  static const fkShowOnDashboard = 'show_on_dashboard';
  static const fkShowInSidebar = 'show_in_sidebar';

  final _savedViewFormKey = GlobalKey<FormBuilderState>();
  final _filterFormKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.newView),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_add_saved_view_page",
        icon: const Icon(Icons.add),
        onPressed: () => _onCreate(context),
        label: Text(S.of(context)!.create),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FormBuilder(
              key: _savedViewFormKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: _AddSavedViewPageState.fkName,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return S.of(context)!.thisFieldIsRequired;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      label: Text(S.of(context)!.name),
                    ),
                  ),
                  FormBuilderCheckbox(
                    name: _AddSavedViewPageState.fkShowOnDashboard,
                    initialValue: false,
                    title: Text(S.of(context)!.showOnDashboard),
                  ),
                  FormBuilderCheckbox(
                    name: _AddSavedViewPageState.fkShowInSidebar,
                    initialValue: false,
                    title: Text(S.of(context)!.showInSidebar),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void _onCreate(BuildContext context) {
    if (_savedViewFormKey.currentState?.saveAndValidate() ?? false) {
      // context.pop(
      //   SavedView.fromDocumentFilter(
      //     DocumentFilterForm.assembleFilter(
      //       _filterFormKey,
      //       widget.currentFilter,
      //     ),
      //     name: _savedViewFormKey.currentState?.value[fkName] as String,
      //     showOnDashboard:
      //         _savedViewFormKey.currentState?.value[fkShowOnDashboard] as bool,
      //     showInSidebar:
      //         _savedViewFormKey.currentState?.value[fkShowInSidebar] as bool,
      //   ),
      // );
    }
  }
}
