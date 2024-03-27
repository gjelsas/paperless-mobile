import 'package:hive/hive.dart';
import 'package:paperless_api/paperless_api.dart';

class PaperlessApiHiveTypeIds {
  PaperlessApiHiveTypeIds._();

  static const int sortField = 108;
  static const int sortOrder = 109;
  static const int queryType = 115;
  static const int userModelv3 = 121;
  static const int userPermissions = 122;
  static const int inheritedPermissions = 123;
  static const int groupModel = 124;
  static const int permissions = 125;
  static const int userModelv2 = 126;
  static const int usersAndGroupsPermissions = 127;
  static const int documentFilter = 128;
}

void registerPaperlessApiHiveTypeAdapters() {
  Hive.registerAdapter(DocumentFilterAdapter());

  Hive.registerAdapter(SortFieldAdapter());
  Hive.registerAdapter(SortOrderAdapter());
  Hive.registerAdapter(QueryTypeAdapter());
  Hive.registerAdapter(UserModelV3Adapter());
  Hive.registerAdapter(UserModelV2Adapter());
  Hive.registerAdapter(GroupModelAdapter());
  Hive.registerAdapter(PermissionsAdapter());
}
