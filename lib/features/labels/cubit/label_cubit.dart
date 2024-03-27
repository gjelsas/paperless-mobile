import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';

part 'label_cubit.freezed.dart';
part 'label_state.dart';

class LabelCubit extends Cubit<LabelState> {
  final LabelRepository labelRepository;

  LabelCubit(this.labelRepository) : super(const LabelState()) {
    labelRepository.addListener(_updateStateListener);
  }

  void _updateStateListener() {
    emit(state.copyWith(
      correspondents: labelRepository.correspondents,
      documentTypes: labelRepository.documentTypes,
      storagePaths: labelRepository.storagePaths,
      tags: labelRepository.tags,
    ));
  }

  Future<void> reload() {
    return labelRepository.initialize();
  }

  Future<Correspondent> addCorrespondent(Correspondent item) async {
    assert(item.id == null);
    final addedItem = await labelRepository.create<Correspondent>(item);
    return addedItem;
  }

  Future<void> reloadCorrespondents() {
    return labelRepository.findAll<Correspondent>();
  }

  Future<Correspondent> replaceCorrespondent(Correspondent item) async {
    assert(item.id != null);
    final updatedItem = await labelRepository.update<Correspondent>(item);
    return updatedItem;
  }

  Future<void> removeCorrespondent(Correspondent item) async {
    assert(item.id != null);
    if (labelRepository.correspondents.containsKey(item.id)) {
      await labelRepository.delete<Correspondent>(item);
    }
  }

  Future<DocumentType> addDocumentType(DocumentType item) async {
    assert(item.id == null);
    final addedItem = await labelRepository.create<DocumentType>(item);
    return addedItem;
  }

  Future<void> reloadDocumentTypes() {
    return labelRepository.findAll<DocumentType>();
  }

  Future<DocumentType> replaceDocumentType(DocumentType item) async {
    assert(item.id != null);
    final updatedItem = await labelRepository.update<DocumentType>(item);
    return updatedItem;
  }

  Future<void> removeDocumentType(DocumentType item) async {
    assert(item.id != null);
    if (labelRepository.documentTypes.containsKey(item.id)) {
      await labelRepository.delete<DocumentType>(item);
    }
  }

  Future<StoragePath> addStoragePath(StoragePath item) async {
    assert(item.id == null);
    final addedItem = await labelRepository.create<StoragePath>(item);
    return addedItem;
  }

  Future<void> reloadStoragePaths() {
    return labelRepository.findAll<StoragePath>();
  }

  Future<StoragePath> replaceStoragePath(StoragePath item) async {
    assert(item.id != null);
    final updatedItem = await labelRepository.update<StoragePath>(item);
    return updatedItem;
  }

  Future<void> removeStoragePath(StoragePath item) async {
    assert(item.id != null);
    if (labelRepository.storagePaths.containsKey(item.id)) {
      await labelRepository.delete<StoragePath>(item);
    }
  }

  Future<Tag> addTag(Tag item) async {
    assert(item.id == null);
    final addedItem = await labelRepository.create<Tag>(item);
    return addedItem;
  }

  Future<void> reloadTags() {
    return labelRepository.findAll<Tag>();
  }

  Future<Tag> replaceTag(Tag item) async {
    assert(item.id != null);
    final updatedItem = await labelRepository.update<Tag>(item);
    return updatedItem;
  }

  Future<void> removeTag(Tag item) async {
    assert(item.id != null);
    if (labelRepository.tags.containsKey(item.id)) {
      await labelRepository.delete<Tag>(item);
    }
  }

  @override
  Future<void> close() {
    labelRepository.removeListener(_updateStateListener);
    return super.close();
  }
}
