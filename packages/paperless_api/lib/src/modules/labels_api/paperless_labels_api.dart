import 'package:paperless_api/src/models/models.dart';

///
/// Provides basic CRUD operations for labels, including:
/// <ul>
///    <li>Correspondents</li>
///    <li>Document Types</li>
///    <li>Tags</li>
///    <li>Storage Paths</li>
/// </ul>
///
abstract class PaperlessLabelsApi {
  Future<int> delete<T extends Label>(T label);
  Future<T> create<T extends Label>(T label);
  Future<T> update<T extends Label>(T label);
  Future<T> find<T extends Label>(int id);
  Future<Iterable<T>> findAll<T extends Label>([Iterable<int>? ids]);
}
