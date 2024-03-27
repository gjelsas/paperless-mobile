// ignore_for_file: type_literal_in_constant_pattern

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

class LabelRepository extends ChangeNotifier {
  final PaperlessLabelsApi _api;
  final LocalUserAccount _currentUser;
  Map<int, Correspondent> correspondents = {};
  Map<int, DocumentType> documentTypes = {};
  Map<int, StoragePath> storagePaths = {};
  Map<int, Tag> tags = {};

  LabelRepository(this._api, this._currentUser);

  // Resets the repository to its initial state and loads all data from the API.
  Future<void> initialize() async {
    correspondents = {};
    documentTypes = {};
    storagePaths = {};
    tags = {};
    await reload();
  }

  Future<void> reload() async {
    await Future.wait([
      if (_currentUser.paperlessUser.canViewCorrespondents)
        findAll<Correspondent>(updateShouldNotify: false),
      if (_currentUser.paperlessUser.canViewDocumentTypes)
        findAll<DocumentType>(updateShouldNotify: false),
      if (_currentUser.paperlessUser.canViewStoragePaths)
        findAll<StoragePath>(updateShouldNotify: false),
      if (_currentUser.paperlessUser.canViewTags)
        findAll<Tag>(updateShouldNotify: false),
    ]);
    notifyListeners();
  }

  Future<T> create<T extends Label>(T label) async {
    logger.ft(
      "Creating new ${label.runtimeType.toString().toLowerCase()}...",
      className: runtimeType.toString(),
      methodName: "create",
    );
    final created = await _api.create<T>(label);
    logger.ft(
      "${label.runtimeType.toString()} successfully created, updating cache...",
      className: runtimeType.toString(),
      methodName: "create",
    );
    switch (created) {
      case Correspondent():
        correspondents = {...correspondents, created.id!: created};
        break;
      case DocumentType():
        documentTypes = {...documentTypes, created.id!: created};
        break;
      case StoragePath():
        storagePaths = {...storagePaths, created.id!: created};
        break;
      case Tag():
        tags = {...tags, created.id!: created};
        break;
    }
    notifyListeners();
    return created;
  }

  Future<int> delete<T extends Label>(T label) async {
    logger.ft(
      "Deleting ${label.runtimeType.toString().toLowerCase()} ${label.id}...",
      className: runtimeType.toString(),
      methodName: "delete",
    );
    await _api.delete(label);

    logger.ft(
      "${label.runtimeType.toString()} ${label.id} successfully deleted, updating cache...",
      className: runtimeType.toString(),
      methodName: "delete",
    );
    switch (label) {
      case Correspondent():
        correspondents.remove(label.id!);
        break;
      case DocumentType():
        documentTypes.remove(label.id!);
        break;
      case StoragePath():
        storagePaths.remove(label.id!);
        break;
      case Tag():
        tags.remove(label.id!);
        break;
    }
    notifyListeners();
    return label.id!;
  }

  Future<T> update<T extends Label>(T label) async {
    logger.ft(
      "Updating ${label.runtimeType.toString().toLowerCase()} ${label.id}...",
      className: runtimeType.toString(),
      methodName: "delete",
    );
    final updated = await _api.update(label);

    logger.ft(
      "${label.runtimeType.toString()} ${label.id} successfully updated, updating cache...",
      className: runtimeType.toString(),
      methodName: "delete",
    );
    switch (updated) {
      case Correspondent():
        correspondents = {...correspondents, updated.id!: updated};
        break;
      case DocumentType():
        documentTypes = {...documentTypes, updated.id!: updated};
        break;
      case StoragePath():
        storagePaths = {...storagePaths, updated.id!: updated};
        break;
      case Tag():
        tags = {...tags, updated.id!: updated};
        break;
    }
    notifyListeners();
    return updated;
  }

  Future<T> find<T extends Label>(int id) async {
    logger.ft(
      "Trying to fetch ${T.toString().toLowerCase()} $id...",
      className: runtimeType.toString(),
      methodName: "find",
    );

    final label = await _api.find<T>(id);
    logger.ft(
      "${T.toString()} ${label.id} successfully loaded, updating cache...",
      className: runtimeType.toString(),
      methodName: "find",
    );
    switch (label) {
      case Correspondent():
        correspondents = {...correspondents, id: label};
        break;
      case DocumentType():
        documentTypes = {...documentTypes, id: label};
        break;
      case StoragePath():
        storagePaths = {...storagePaths, id: label};
        break;
      case Tag():
        tags = {...tags, id: label};
        break;
    }
    notifyListeners();
    return label;
  }

  Future<Iterable<T>> findAll<T extends Label>({
    Iterable<int>? ids,
    bool updateShouldNotify = true,
  }) async {
    logger.ft(
      "Trying to fetch all ${T.toString().toLowerCase()}s${ids != null ? " with ids ${ids.join(",")}" : ""}...",
      className: runtimeType.toString(),
      methodName: "find",
    );
    final data = await _api.findAll<T>(ids);

    logger.ft(
      "${data.length} ${T.toString().toLowerCase()}(s) successfully loaded, updating cache...",
      className: runtimeType.toString(),
      methodName: "find",
    );
    switch (T) {
      case Correspondent:
        correspondents = {
          ...correspondents,
          for (var label in data) label.id!: label as Correspondent
        };
        break;
      case DocumentType:
        documentTypes = {
          ...documentTypes,
          for (var label in data) label.id!: label as DocumentType
        };
        break;
      case StoragePath:
        storagePaths = {
          ...storagePaths,
          for (var label in data) label.id!: label as StoragePath
        };
        break;
      case Tag:
        tags = {...tags, for (var label in data) label.id!: label as Tag};
        break;
    }
    if (updateShouldNotify) {
      notifyListeners();
    }
    return data;
  }
}
