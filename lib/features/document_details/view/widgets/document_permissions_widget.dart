import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';

class DocumentPermissionsWidget extends StatefulWidget {
  final DocumentModel document;
  const DocumentPermissionsWidget({super.key, required this.document});

  @override
  State<DocumentPermissionsWidget> createState() =>
      _DocumentPermissionsWidgetState();
}

class _DocumentPermissionsWidgetState extends State<DocumentPermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserRepository, UserRepositoryState>(
      builder: (context, state) {
        final owner = state.users[widget.document.owner];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (owner != null)
              DetailsItem.text(
                owner.username,
                label: 'Owner',
                context: context,
              ),
          ],
        );
      },
    );
  }
}
