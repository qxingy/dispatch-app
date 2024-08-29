// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dao.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  AppDao? _appDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `AppEntity` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `uid` INTEGER NOT NULL, `name` TEXT NOT NULL, `packageName` TEXT NOT NULL, `versionName` TEXT NOT NULL, `versionCode` INTEGER NOT NULL, `icon` BLOB NOT NULL, `promotionLink` TEXT NOT NULL, `isCut` INTEGER NOT NULL, `enable` INTEGER NOT NULL, `waitingPageNode` TEXT NOT NULL, `waitingNode` TEXT NOT NULL, `getNode` TEXT NOT NULL, `descNode` TEXT NOT NULL)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_AppEntity_uid` ON `AppEntity` (`uid`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  AppDao get appDao {
    return _appDaoInstance ??= _$AppDao(database, changeListener);
  }
}

class _$AppDao extends AppDao {
  _$AppDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _appEntityInsertionAdapter = InsertionAdapter(
            database,
            'AppEntity',
            (AppEntity item) => <String, Object?>{
                  'id': item.id,
                  'uid': item.uid,
                  'name': item.name,
                  'packageName': item.packageName,
                  'versionName': item.versionName,
                  'versionCode': item.versionCode,
                  'icon': item.icon,
                  'promotionLink': item.promotionLink,
                  'isCut': item.isCut ? 1 : 0,
                  'enable': item.enable ? 1 : 0,
                  'waitingPageNode': item.waitingPageNode,
                  'waitingNode': item.waitingNode,
                  'getNode': item.getNode,
                  'descNode': item.descNode
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AppEntity> _appEntityInsertionAdapter;

  @override
  Stream<List<AppEntity>> findAll() {
    return _queryAdapter.queryListStream('SELECT * FROM AppEntity',
        mapper: (Map<String, Object?> row) => AppEntity(
            id: row['id'] as int?,
            uid: row['uid'] as int,
            name: row['name'] as String,
            packageName: row['packageName'] as String,
            versionName: row['versionName'] as String,
            versionCode: row['versionCode'] as int,
            icon: row['icon'] as Uint8List,
            promotionLink: row['promotionLink'] as String,
            isCut: (row['isCut'] as int) != 0,
            enable: (row['enable'] as int) != 0,
            waitingPageNode: row['waitingPageNode'] as String,
            waitingNode: row['waitingNode'] as String,
            getNode: row['getNode'] as String,
            descNode: row['descNode'] as String),
        queryableName: 'AppEntity',
        isView: false);
  }

  @override
  Future<List<AppEntity>> syncFindAll() async {
    return _queryAdapter.queryList('SELECT * FROM AppEntity',
        mapper: (Map<String, Object?> row) => AppEntity(
            id: row['id'] as int?,
            uid: row['uid'] as int,
            name: row['name'] as String,
            packageName: row['packageName'] as String,
            versionName: row['versionName'] as String,
            versionCode: row['versionCode'] as int,
            icon: row['icon'] as Uint8List,
            promotionLink: row['promotionLink'] as String,
            isCut: (row['isCut'] as int) != 0,
            enable: (row['enable'] as int) != 0,
            waitingPageNode: row['waitingPageNode'] as String,
            waitingNode: row['waitingNode'] as String,
            getNode: row['getNode'] as String,
            descNode: row['descNode'] as String));
  }

  @override
  Future<void> updateIsCut(
    int id,
    bool isCut,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE AppEntity SET isCut = ?2 WHERE id = ?1',
        arguments: [id, isCut ? 1 : 0]);
  }

  @override
  Future<void> updateEnable(
    int id,
    bool enable,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE AppEntity SET enable = ?2 WHERE id = ?1',
        arguments: [id, enable ? 1 : 0]);
  }

  @override
  Stream<AppEntity?> findAppById(int id) {
    return _queryAdapter.queryStream('SELECT * FROM AppEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => AppEntity(
            id: row['id'] as int?,
            uid: row['uid'] as int,
            name: row['name'] as String,
            packageName: row['packageName'] as String,
            versionName: row['versionName'] as String,
            versionCode: row['versionCode'] as int,
            icon: row['icon'] as Uint8List,
            promotionLink: row['promotionLink'] as String,
            isCut: (row['isCut'] as int) != 0,
            enable: (row['enable'] as int) != 0,
            waitingPageNode: row['waitingPageNode'] as String,
            waitingNode: row['waitingNode'] as String,
            getNode: row['getNode'] as String,
            descNode: row['descNode'] as String),
        arguments: [id],
        queryableName: 'AppEntity',
        isView: false);
  }

  @override
  Future<List<AppEntity>> findAllEnable() async {
    return _queryAdapter.queryList(
        'SELECT * FROM AppEntity WHERE enable = true',
        mapper: (Map<String, Object?> row) => AppEntity(
            id: row['id'] as int?,
            uid: row['uid'] as int,
            name: row['name'] as String,
            packageName: row['packageName'] as String,
            versionName: row['versionName'] as String,
            versionCode: row['versionCode'] as int,
            icon: row['icon'] as Uint8List,
            promotionLink: row['promotionLink'] as String,
            isCut: (row['isCut'] as int) != 0,
            enable: (row['enable'] as int) != 0,
            waitingPageNode: row['waitingPageNode'] as String,
            waitingNode: row['waitingNode'] as String,
            getNode: row['getNode'] as String,
            descNode: row['descNode'] as String));
  }

  @override
  Future<void> insertPerson(List<AppEntity> app) async {
    await _appEntityInsertionAdapter.insertList(
        app, OnConflictStrategy.replace);
  }
}
