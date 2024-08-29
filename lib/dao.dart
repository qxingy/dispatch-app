import 'dart:async';
import 'dart:typed_data';
import 'package:floor/floor.dart';
import 'package:json_path/json_path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'dao.g.dart';

@Database(version: 1, entities: [AppEntity])
abstract class AppDatabase extends FloorDatabase {
  AppDao get appDao;
}

@Entity(indices: [
  Index(unique: true, value: ["uid"])
])
class AppEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int uid;
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final Uint8List icon;
  final String promotionLink;
  final bool isCut;
  final bool enable;

  final String waitingPageNode;
  final String waitingNode;
  final String getNode;
  final String descNode;

  AppEntity({
    this.id,
    required this.uid,
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.icon,
    required this.promotionLink,
    required this.isCut,
    required this.enable,
    required this.waitingPageNode,
    required this.waitingNode,
    required this.getNode,
    required this.descNode,
  });
}

@dao
abstract class AppDao {
  @Query('SELECT * FROM AppEntity')
  Stream<List<AppEntity>> findAll();

  @Query('SELECT * FROM AppEntity')
  Future<List<AppEntity>> syncFindAll();

  @Query("UPDATE AppEntity SET isCut = :isCut WHERE id = :id")
  Future<void> updateIsCut(int id, bool isCut);

  @Query("UPDATE AppEntity SET enable = :enable WHERE id = :id")
  Future<void> updateEnable(int id, bool enable);

  @Query("SELECT * FROM AppEntity WHERE id = :id")
  Stream<AppEntity?> findAppById(int id);

  @Query("SELECT * FROM AppEntity WHERE enable = true")
  Future<List<AppEntity>> findAllEnable();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPerson(List<AppEntity> app);
}
