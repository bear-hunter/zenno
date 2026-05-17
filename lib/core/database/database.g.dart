// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CanvasFoldersTable extends CanvasFolders
    with TableInfo<$CanvasFoldersTable, CanvasFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, position, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CanvasFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CanvasFoldersTable createAlias(String alias) {
    return $CanvasFoldersTable(attachedDatabase, alias);
  }
}

class CanvasFolder extends DataClass implements Insertable<CanvasFolder> {
  final String id;
  final String name;

  /// Fractional ordering position.
  final double position;
  final DateTime createdAt;
  const CanvasFolder({
    required this.id,
    required this.name,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<double>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CanvasFoldersCompanion toCompanion(bool nullToAbsent) {
    return CanvasFoldersCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory CanvasFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasFolder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<double>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<double>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CanvasFolder copyWith({
    String? id,
    String? name,
    double? position,
    DateTime? createdAt,
  }) => CanvasFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  CanvasFolder copyWithCompanion(CanvasFoldersCompanion data) {
    return CanvasFolder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasFolder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasFolder &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class CanvasFoldersCompanion extends UpdateCompanion<CanvasFolder> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> position;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CanvasFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasFoldersCompanion.insert({
    required String id,
    required String name,
    required double position,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<CanvasFolder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? position,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasFoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? position,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CanvasFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasesTable extends Canvases with TableInfo<$CanvasesTable, Canvase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvas_folders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _worldOriginXMeta = const VerificationMeta(
    'worldOriginX',
  );
  @override
  late final GeneratedColumn<double> worldOriginX = GeneratedColumn<double>(
    'world_origin_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _worldOriginYMeta = const VerificationMeta(
    'worldOriginY',
  );
  @override
  late final GeneratedColumn<double> worldOriginY = GeneratedColumn<double>(
    'world_origin_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vpTxMeta = const VerificationMeta('vpTx');
  @override
  late final GeneratedColumn<double> vpTx = GeneratedColumn<double>(
    'vp_tx',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vpTyMeta = const VerificationMeta('vpTy');
  @override
  late final GeneratedColumn<double> vpTy = GeneratedColumn<double>(
    'vp_ty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vpScaleMeta = const VerificationMeta(
    'vpScale',
  );
  @override
  late final GeneratedColumn<double> vpScale = GeneratedColumn<double>(
    'vp_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _vpRotationMeta = const VerificationMeta(
    'vpRotation',
  );
  @override
  late final GeneratedColumn<double> vpRotation = GeneratedColumn<double>(
    'vp_rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BackgroundKind, int>
  backgroundKind = GeneratedColumn<int>(
    'background_kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<BackgroundKind>($CanvasesTable.$converterbackgroundKind);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createdAt,
    updatedAt,
    lastOpenedAt,
    thumbnailPath,
    isArchived,
    folderId,
    worldOriginX,
    worldOriginY,
    vpTx,
    vpTy,
    vpScale,
    vpRotation,
    backgroundKind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Canvase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('world_origin_x')) {
      context.handle(
        _worldOriginXMeta,
        worldOriginX.isAcceptableOrUnknown(
          data['world_origin_x']!,
          _worldOriginXMeta,
        ),
      );
    }
    if (data.containsKey('world_origin_y')) {
      context.handle(
        _worldOriginYMeta,
        worldOriginY.isAcceptableOrUnknown(
          data['world_origin_y']!,
          _worldOriginYMeta,
        ),
      );
    }
    if (data.containsKey('vp_tx')) {
      context.handle(
        _vpTxMeta,
        vpTx.isAcceptableOrUnknown(data['vp_tx']!, _vpTxMeta),
      );
    }
    if (data.containsKey('vp_ty')) {
      context.handle(
        _vpTyMeta,
        vpTy.isAcceptableOrUnknown(data['vp_ty']!, _vpTyMeta),
      );
    }
    if (data.containsKey('vp_scale')) {
      context.handle(
        _vpScaleMeta,
        vpScale.isAcceptableOrUnknown(data['vp_scale']!, _vpScaleMeta),
      );
    }
    if (data.containsKey('vp_rotation')) {
      context.handle(
        _vpRotationMeta,
        vpRotation.isAcceptableOrUnknown(data['vp_rotation']!, _vpRotationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Canvase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Canvase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      worldOriginX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}world_origin_x'],
      )!,
      worldOriginY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}world_origin_y'],
      )!,
      vpTx: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vp_tx'],
      )!,
      vpTy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vp_ty'],
      )!,
      vpScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vp_scale'],
      )!,
      vpRotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vp_rotation'],
      )!,
      backgroundKind: $CanvasesTable.$converterbackgroundKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}background_kind'],
        )!,
      ),
    );
  }

  @override
  $CanvasesTable createAlias(String alias) {
    return $CanvasesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BackgroundKind, int, int> $converterbackgroundKind =
      const EnumIndexConverter<BackgroundKind>(BackgroundKind.values);
}

class Canvase extends DataClass implements Insertable<Canvase> {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  final String? thumbnailPath;
  final bool isArchived;
  final String? folderId;

  /// Viewport rebasing anchor — keeps active world coordinates small.
  final double worldOriginX;
  final double worldOriginY;

  /// Last viewport, restored when the canvas is reopened.
  final double vpTx;
  final double vpTy;
  final double vpScale;
  final double vpRotation;
  final BackgroundKind backgroundKind;
  const Canvase({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpenedAt,
    this.thumbnailPath,
    required this.isArchived,
    this.folderId,
    required this.worldOriginX,
    required this.worldOriginY,
    required this.vpTx,
    required this.vpTy,
    required this.vpScale,
    required this.vpRotation,
    required this.backgroundKind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['world_origin_x'] = Variable<double>(worldOriginX);
    map['world_origin_y'] = Variable<double>(worldOriginY);
    map['vp_tx'] = Variable<double>(vpTx);
    map['vp_ty'] = Variable<double>(vpTy);
    map['vp_scale'] = Variable<double>(vpScale);
    map['vp_rotation'] = Variable<double>(vpRotation);
    {
      map['background_kind'] = Variable<int>(
        $CanvasesTable.$converterbackgroundKind.toSql(backgroundKind),
      );
    }
    return map;
  }

  CanvasesCompanion toCompanion(bool nullToAbsent) {
    return CanvasesCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      isArchived: Value(isArchived),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      worldOriginX: Value(worldOriginX),
      worldOriginY: Value(worldOriginY),
      vpTx: Value(vpTx),
      vpTy: Value(vpTy),
      vpScale: Value(vpScale),
      vpRotation: Value(vpRotation),
      backgroundKind: Value(backgroundKind),
    );
  }

  factory Canvase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Canvase(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      worldOriginX: serializer.fromJson<double>(json['worldOriginX']),
      worldOriginY: serializer.fromJson<double>(json['worldOriginY']),
      vpTx: serializer.fromJson<double>(json['vpTx']),
      vpTy: serializer.fromJson<double>(json['vpTy']),
      vpScale: serializer.fromJson<double>(json['vpScale']),
      vpRotation: serializer.fromJson<double>(json['vpRotation']),
      backgroundKind: $CanvasesTable.$converterbackgroundKind.fromJson(
        serializer.fromJson<int>(json['backgroundKind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'isArchived': serializer.toJson<bool>(isArchived),
      'folderId': serializer.toJson<String?>(folderId),
      'worldOriginX': serializer.toJson<double>(worldOriginX),
      'worldOriginY': serializer.toJson<double>(worldOriginY),
      'vpTx': serializer.toJson<double>(vpTx),
      'vpTy': serializer.toJson<double>(vpTy),
      'vpScale': serializer.toJson<double>(vpScale),
      'vpRotation': serializer.toJson<double>(vpRotation),
      'backgroundKind': serializer.toJson<int>(
        $CanvasesTable.$converterbackgroundKind.toJson(backgroundKind),
      ),
    };
  }

  Canvase copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    bool? isArchived,
    Value<String?> folderId = const Value.absent(),
    double? worldOriginX,
    double? worldOriginY,
    double? vpTx,
    double? vpTy,
    double? vpScale,
    double? vpRotation,
    BackgroundKind? backgroundKind,
  }) => Canvase(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    isArchived: isArchived ?? this.isArchived,
    folderId: folderId.present ? folderId.value : this.folderId,
    worldOriginX: worldOriginX ?? this.worldOriginX,
    worldOriginY: worldOriginY ?? this.worldOriginY,
    vpTx: vpTx ?? this.vpTx,
    vpTy: vpTy ?? this.vpTy,
    vpScale: vpScale ?? this.vpScale,
    vpRotation: vpRotation ?? this.vpRotation,
    backgroundKind: backgroundKind ?? this.backgroundKind,
  );
  Canvase copyWithCompanion(CanvasesCompanion data) {
    return Canvase(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      worldOriginX: data.worldOriginX.present
          ? data.worldOriginX.value
          : this.worldOriginX,
      worldOriginY: data.worldOriginY.present
          ? data.worldOriginY.value
          : this.worldOriginY,
      vpTx: data.vpTx.present ? data.vpTx.value : this.vpTx,
      vpTy: data.vpTy.present ? data.vpTy.value : this.vpTy,
      vpScale: data.vpScale.present ? data.vpScale.value : this.vpScale,
      vpRotation: data.vpRotation.present
          ? data.vpRotation.value
          : this.vpRotation,
      backgroundKind: data.backgroundKind.present
          ? data.backgroundKind.value
          : this.backgroundKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Canvase(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('isArchived: $isArchived, ')
          ..write('folderId: $folderId, ')
          ..write('worldOriginX: $worldOriginX, ')
          ..write('worldOriginY: $worldOriginY, ')
          ..write('vpTx: $vpTx, ')
          ..write('vpTy: $vpTy, ')
          ..write('vpScale: $vpScale, ')
          ..write('vpRotation: $vpRotation, ')
          ..write('backgroundKind: $backgroundKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    updatedAt,
    lastOpenedAt,
    thumbnailPath,
    isArchived,
    folderId,
    worldOriginX,
    worldOriginY,
    vpTx,
    vpTy,
    vpScale,
    vpRotation,
    backgroundKind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Canvase &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.thumbnailPath == this.thumbnailPath &&
          other.isArchived == this.isArchived &&
          other.folderId == this.folderId &&
          other.worldOriginX == this.worldOriginX &&
          other.worldOriginY == this.worldOriginY &&
          other.vpTx == this.vpTx &&
          other.vpTy == this.vpTy &&
          other.vpScale == this.vpScale &&
          other.vpRotation == this.vpRotation &&
          other.backgroundKind == this.backgroundKind);
}

class CanvasesCompanion extends UpdateCompanion<Canvase> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<String?> thumbnailPath;
  final Value<bool> isArchived;
  final Value<String?> folderId;
  final Value<double> worldOriginX;
  final Value<double> worldOriginY;
  final Value<double> vpTx;
  final Value<double> vpTy;
  final Value<double> vpScale;
  final Value<double> vpRotation;
  final Value<BackgroundKind> backgroundKind;
  final Value<int> rowid;
  const CanvasesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.folderId = const Value.absent(),
    this.worldOriginX = const Value.absent(),
    this.worldOriginY = const Value.absent(),
    this.vpTx = const Value.absent(),
    this.vpTy = const Value.absent(),
    this.vpScale = const Value.absent(),
    this.vpRotation = const Value.absent(),
    this.backgroundKind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasesCompanion.insert({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastOpenedAt = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.folderId = const Value.absent(),
    this.worldOriginX = const Value.absent(),
    this.worldOriginY = const Value.absent(),
    this.vpTx = const Value.absent(),
    this.vpTy = const Value.absent(),
    this.vpScale = const Value.absent(),
    this.vpRotation = const Value.absent(),
    this.backgroundKind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Canvase> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? thumbnailPath,
    Expression<bool>? isArchived,
    Expression<String>? folderId,
    Expression<double>? worldOriginX,
    Expression<double>? worldOriginY,
    Expression<double>? vpTx,
    Expression<double>? vpTy,
    Expression<double>? vpScale,
    Expression<double>? vpRotation,
    Expression<int>? backgroundKind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (isArchived != null) 'is_archived': isArchived,
      if (folderId != null) 'folder_id': folderId,
      if (worldOriginX != null) 'world_origin_x': worldOriginX,
      if (worldOriginY != null) 'world_origin_y': worldOriginY,
      if (vpTx != null) 'vp_tx': vpTx,
      if (vpTy != null) 'vp_ty': vpTy,
      if (vpScale != null) 'vp_scale': vpScale,
      if (vpRotation != null) 'vp_rotation': vpRotation,
      if (backgroundKind != null) 'background_kind': backgroundKind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<String?>? thumbnailPath,
    Value<bool>? isArchived,
    Value<String?>? folderId,
    Value<double>? worldOriginX,
    Value<double>? worldOriginY,
    Value<double>? vpTx,
    Value<double>? vpTy,
    Value<double>? vpScale,
    Value<double>? vpRotation,
    Value<BackgroundKind>? backgroundKind,
    Value<int>? rowid,
  }) {
    return CanvasesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isArchived: isArchived ?? this.isArchived,
      folderId: folderId ?? this.folderId,
      worldOriginX: worldOriginX ?? this.worldOriginX,
      worldOriginY: worldOriginY ?? this.worldOriginY,
      vpTx: vpTx ?? this.vpTx,
      vpTy: vpTy ?? this.vpTy,
      vpScale: vpScale ?? this.vpScale,
      vpRotation: vpRotation ?? this.vpRotation,
      backgroundKind: backgroundKind ?? this.backgroundKind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (worldOriginX.present) {
      map['world_origin_x'] = Variable<double>(worldOriginX.value);
    }
    if (worldOriginY.present) {
      map['world_origin_y'] = Variable<double>(worldOriginY.value);
    }
    if (vpTx.present) {
      map['vp_tx'] = Variable<double>(vpTx.value);
    }
    if (vpTy.present) {
      map['vp_ty'] = Variable<double>(vpTy.value);
    }
    if (vpScale.present) {
      map['vp_scale'] = Variable<double>(vpScale.value);
    }
    if (vpRotation.present) {
      map['vp_rotation'] = Variable<double>(vpRotation.value);
    }
    if (backgroundKind.present) {
      map['background_kind'] = Variable<int>(
        $CanvasesTable.$converterbackgroundKind.toSql(backgroundKind.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('isArchived: $isArchived, ')
          ..write('folderId: $folderId, ')
          ..write('worldOriginX: $worldOriginX, ')
          ..write('worldOriginY: $worldOriginY, ')
          ..write('vpTx: $vpTx, ')
          ..write('vpTy: $vpTy, ')
          ..write('vpScale: $vpScale, ')
          ..write('vpRotation: $vpRotation, ')
          ..write('backgroundKind: $backgroundKind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasElementsTable extends CanvasElements
    with TableInfo<$CanvasElementsTable, CanvasElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasElementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canvasIdMeta = const VerificationMeta(
    'canvasId',
  );
  @override
  late final GeneratedColumn<String> canvasId = GeneratedColumn<String>(
    'canvas_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvases (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ElementKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ElementKind>($CanvasElementsTable.$converterkind);
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _zIndexMeta = const VerificationMeta('zIndex');
  @override
  late final GeneratedColumn<double> zIndex = GeneratedColumn<double>(
    'z_index',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canvasId,
    kind,
    x,
    y,
    width,
    height,
    rotation,
    zIndex,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_elements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasElement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('canvas_id')) {
      context.handle(
        _canvasIdMeta,
        canvasId.isAcceptableOrUnknown(data['canvas_id']!, _canvasIdMeta),
      );
    } else if (isInserting) {
      context.missing(_canvasIdMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('z_index')) {
      context.handle(
        _zIndexMeta,
        zIndex.isAcceptableOrUnknown(data['z_index']!, _zIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_zIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CanvasElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasElement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      canvasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canvas_id'],
      )!,
      kind: $CanvasElementsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      zIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}z_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CanvasElementsTable createAlias(String alias) {
    return $CanvasElementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ElementKind, int, int> $converterkind =
      const EnumIndexConverter<ElementKind>(ElementKind.values);
}

class CanvasElement extends DataClass implements Insertable<CanvasElement> {
  final String id;
  final String canvasId;
  final ElementKind kind;

  /// World-space bounds — stored so the spatial index loads without
  /// decoding element payloads.
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  /// Fractional z-ordering within the canvas.
  final double zIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const CanvasElement({
    required this.id,
    required this.canvasId,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.zIndex,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['canvas_id'] = Variable<String>(canvasId);
    {
      map['kind'] = Variable<int>(
        $CanvasElementsTable.$converterkind.toSql(kind),
      );
    }
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['rotation'] = Variable<double>(rotation);
    map['z_index'] = Variable<double>(zIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CanvasElementsCompanion toCompanion(bool nullToAbsent) {
    return CanvasElementsCompanion(
      id: Value(id),
      canvasId: Value(canvasId),
      kind: Value(kind),
      x: Value(x),
      y: Value(y),
      width: Value(width),
      height: Value(height),
      rotation: Value(rotation),
      zIndex: Value(zIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory CanvasElement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasElement(
      id: serializer.fromJson<String>(json['id']),
      canvasId: serializer.fromJson<String>(json['canvasId']),
      kind: $CanvasElementsTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      rotation: serializer.fromJson<double>(json['rotation']),
      zIndex: serializer.fromJson<double>(json['zIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'canvasId': serializer.toJson<String>(canvasId),
      'kind': serializer.toJson<int>(
        $CanvasElementsTable.$converterkind.toJson(kind),
      ),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'rotation': serializer.toJson<double>(rotation),
      'zIndex': serializer.toJson<double>(zIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CanvasElement copyWith({
    String? id,
    String? canvasId,
    ElementKind? kind,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => CanvasElement(
    id: id ?? this.id,
    canvasId: canvasId ?? this.canvasId,
    kind: kind ?? this.kind,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    rotation: rotation ?? this.rotation,
    zIndex: zIndex ?? this.zIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CanvasElement copyWithCompanion(CanvasElementsCompanion data) {
    return CanvasElement(
      id: data.id.present ? data.id.value : this.id,
      canvasId: data.canvasId.present ? data.canvasId.value : this.canvasId,
      kind: data.kind.present ? data.kind.value : this.kind,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      zIndex: data.zIndex.present ? data.zIndex.value : this.zIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasElement(')
          ..write('id: $id, ')
          ..write('canvasId: $canvasId, ')
          ..write('kind: $kind, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('zIndex: $zIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canvasId,
    kind,
    x,
    y,
    width,
    height,
    rotation,
    zIndex,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasElement &&
          other.id == this.id &&
          other.canvasId == this.canvasId &&
          other.kind == this.kind &&
          other.x == this.x &&
          other.y == this.y &&
          other.width == this.width &&
          other.height == this.height &&
          other.rotation == this.rotation &&
          other.zIndex == this.zIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class CanvasElementsCompanion extends UpdateCompanion<CanvasElement> {
  final Value<String> id;
  final Value<String> canvasId;
  final Value<ElementKind> kind;
  final Value<double> x;
  final Value<double> y;
  final Value<double> width;
  final Value<double> height;
  final Value<double> rotation;
  final Value<double> zIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CanvasElementsCompanion({
    this.id = const Value.absent(),
    this.canvasId = const Value.absent(),
    this.kind = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotation = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasElementsCompanion.insert({
    required String id,
    required String canvasId,
    required ElementKind kind,
    required double x,
    required double y,
    required double width,
    required double height,
    this.rotation = const Value.absent(),
    required double zIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       canvasId = Value(canvasId),
       kind = Value(kind),
       x = Value(x),
       y = Value(y),
       width = Value(width),
       height = Value(height),
       zIndex = Value(zIndex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CanvasElement> custom({
    Expression<String>? id,
    Expression<String>? canvasId,
    Expression<int>? kind,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? width,
    Expression<double>? height,
    Expression<double>? rotation,
    Expression<double>? zIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canvasId != null) 'canvas_id': canvasId,
      if (kind != null) 'kind': kind,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotation != null) 'rotation': rotation,
      if (zIndex != null) 'z_index': zIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasElementsCompanion copyWith({
    Value<String>? id,
    Value<String>? canvasId,
    Value<ElementKind>? kind,
    Value<double>? x,
    Value<double>? y,
    Value<double>? width,
    Value<double>? height,
    Value<double>? rotation,
    Value<double>? zIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CanvasElementsCompanion(
      id: id ?? this.id,
      canvasId: canvasId ?? this.canvasId,
      kind: kind ?? this.kind,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (canvasId.present) {
      map['canvas_id'] = Variable<String>(canvasId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $CanvasElementsTable.$converterkind.toSql(kind.value),
      );
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (zIndex.present) {
      map['z_index'] = Variable<double>(zIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasElementsCompanion(')
          ..write('id: $id, ')
          ..write('canvasId: $canvasId, ')
          ..write('kind: $kind, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('zIndex: $zIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkStrokesTable extends InkStrokes
    with TableInfo<$InkStrokesTable, InkStroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkStrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _elementIdMeta = const VerificationMeta(
    'elementId',
  );
  @override
  late final GeneratedColumn<String> elementId = GeneratedColumn<String>(
    'element_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvas_elements (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<Uint8List> points = GeneratedColumn<Uint8List>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointCountMeta = const VerificationMeta(
    'pointCount',
  );
  @override
  late final GeneratedColumn<int> pointCount = GeneratedColumn<int>(
    'point_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeWidthMeta = const VerificationMeta(
    'strokeWidth',
  );
  @override
  late final GeneratedColumn<double> strokeWidth = GeneratedColumn<double>(
    'stroke_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StrokeTool, int> tool =
      GeneratedColumn<int>(
        'tool',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<StrokeTool>($InkStrokesTable.$convertertool);
  static const VerificationMeta _isHighlighterMeta = const VerificationMeta(
    'isHighlighter',
  );
  @override
  late final GeneratedColumn<bool> isHighlighter = GeneratedColumn<bool>(
    'is_highlighter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_highlighter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    elementId,
    points,
    pointCount,
    color,
    strokeWidth,
    tool,
    isHighlighter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<InkStroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('element_id')) {
      context.handle(
        _elementIdMeta,
        elementId.isAcceptableOrUnknown(data['element_id']!, _elementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_elementIdMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('point_count')) {
      context.handle(
        _pointCountMeta,
        pointCount.isAcceptableOrUnknown(data['point_count']!, _pointCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pointCountMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('stroke_width')) {
      context.handle(
        _strokeWidthMeta,
        strokeWidth.isAcceptableOrUnknown(
          data['stroke_width']!,
          _strokeWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokeWidthMeta);
    }
    if (data.containsKey('is_highlighter')) {
      context.handle(
        _isHighlighterMeta,
        isHighlighter.isAcceptableOrUnknown(
          data['is_highlighter']!,
          _isHighlighterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {elementId};
  @override
  InkStroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkStroke(
      elementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_id'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}points'],
      )!,
      pointCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_count'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      strokeWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stroke_width'],
      )!,
      tool: $InkStrokesTable.$convertertool.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}tool'],
        )!,
      ),
      isHighlighter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_highlighter'],
      )!,
    );
  }

  @override
  $InkStrokesTable createAlias(String alias) {
    return $InkStrokesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StrokeTool, int, int> $convertertool =
      const EnumIndexConverter<StrokeTool>(StrokeTool.values);
}

class InkStroke extends DataClass implements Insertable<InkStroke> {
  final String elementId;

  /// Packed `Float32List` `[x, y, pressure, ...]` with a leading
  /// 1-byte format version.
  final Uint8List points;
  final int pointCount;

  /// ARGB colour value.
  final int color;

  /// Logical stroke width.
  final double strokeWidth;
  final StrokeTool tool;
  final bool isHighlighter;
  const InkStroke({
    required this.elementId,
    required this.points,
    required this.pointCount,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    required this.isHighlighter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['element_id'] = Variable<String>(elementId);
    map['points'] = Variable<Uint8List>(points);
    map['point_count'] = Variable<int>(pointCount);
    map['color'] = Variable<int>(color);
    map['stroke_width'] = Variable<double>(strokeWidth);
    {
      map['tool'] = Variable<int>($InkStrokesTable.$convertertool.toSql(tool));
    }
    map['is_highlighter'] = Variable<bool>(isHighlighter);
    return map;
  }

  InkStrokesCompanion toCompanion(bool nullToAbsent) {
    return InkStrokesCompanion(
      elementId: Value(elementId),
      points: Value(points),
      pointCount: Value(pointCount),
      color: Value(color),
      strokeWidth: Value(strokeWidth),
      tool: Value(tool),
      isHighlighter: Value(isHighlighter),
    );
  }

  factory InkStroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkStroke(
      elementId: serializer.fromJson<String>(json['elementId']),
      points: serializer.fromJson<Uint8List>(json['points']),
      pointCount: serializer.fromJson<int>(json['pointCount']),
      color: serializer.fromJson<int>(json['color']),
      strokeWidth: serializer.fromJson<double>(json['strokeWidth']),
      tool: $InkStrokesTable.$convertertool.fromJson(
        serializer.fromJson<int>(json['tool']),
      ),
      isHighlighter: serializer.fromJson<bool>(json['isHighlighter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'elementId': serializer.toJson<String>(elementId),
      'points': serializer.toJson<Uint8List>(points),
      'pointCount': serializer.toJson<int>(pointCount),
      'color': serializer.toJson<int>(color),
      'strokeWidth': serializer.toJson<double>(strokeWidth),
      'tool': serializer.toJson<int>(
        $InkStrokesTable.$convertertool.toJson(tool),
      ),
      'isHighlighter': serializer.toJson<bool>(isHighlighter),
    };
  }

  InkStroke copyWith({
    String? elementId,
    Uint8List? points,
    int? pointCount,
    int? color,
    double? strokeWidth,
    StrokeTool? tool,
    bool? isHighlighter,
  }) => InkStroke(
    elementId: elementId ?? this.elementId,
    points: points ?? this.points,
    pointCount: pointCount ?? this.pointCount,
    color: color ?? this.color,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    tool: tool ?? this.tool,
    isHighlighter: isHighlighter ?? this.isHighlighter,
  );
  InkStroke copyWithCompanion(InkStrokesCompanion data) {
    return InkStroke(
      elementId: data.elementId.present ? data.elementId.value : this.elementId,
      points: data.points.present ? data.points.value : this.points,
      pointCount: data.pointCount.present
          ? data.pointCount.value
          : this.pointCount,
      color: data.color.present ? data.color.value : this.color,
      strokeWidth: data.strokeWidth.present
          ? data.strokeWidth.value
          : this.strokeWidth,
      tool: data.tool.present ? data.tool.value : this.tool,
      isHighlighter: data.isHighlighter.present
          ? data.isHighlighter.value
          : this.isHighlighter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkStroke(')
          ..write('elementId: $elementId, ')
          ..write('points: $points, ')
          ..write('pointCount: $pointCount, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('tool: $tool, ')
          ..write('isHighlighter: $isHighlighter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    elementId,
    $driftBlobEquality.hash(points),
    pointCount,
    color,
    strokeWidth,
    tool,
    isHighlighter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkStroke &&
          other.elementId == this.elementId &&
          $driftBlobEquality.equals(other.points, this.points) &&
          other.pointCount == this.pointCount &&
          other.color == this.color &&
          other.strokeWidth == this.strokeWidth &&
          other.tool == this.tool &&
          other.isHighlighter == this.isHighlighter);
}

class InkStrokesCompanion extends UpdateCompanion<InkStroke> {
  final Value<String> elementId;
  final Value<Uint8List> points;
  final Value<int> pointCount;
  final Value<int> color;
  final Value<double> strokeWidth;
  final Value<StrokeTool> tool;
  final Value<bool> isHighlighter;
  final Value<int> rowid;
  const InkStrokesCompanion({
    this.elementId = const Value.absent(),
    this.points = const Value.absent(),
    this.pointCount = const Value.absent(),
    this.color = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.tool = const Value.absent(),
    this.isHighlighter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkStrokesCompanion.insert({
    required String elementId,
    required Uint8List points,
    required int pointCount,
    required int color,
    required double strokeWidth,
    required StrokeTool tool,
    this.isHighlighter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : elementId = Value(elementId),
       points = Value(points),
       pointCount = Value(pointCount),
       color = Value(color),
       strokeWidth = Value(strokeWidth),
       tool = Value(tool);
  static Insertable<InkStroke> custom({
    Expression<String>? elementId,
    Expression<Uint8List>? points,
    Expression<int>? pointCount,
    Expression<int>? color,
    Expression<double>? strokeWidth,
    Expression<int>? tool,
    Expression<bool>? isHighlighter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (elementId != null) 'element_id': elementId,
      if (points != null) 'points': points,
      if (pointCount != null) 'point_count': pointCount,
      if (color != null) 'color': color,
      if (strokeWidth != null) 'stroke_width': strokeWidth,
      if (tool != null) 'tool': tool,
      if (isHighlighter != null) 'is_highlighter': isHighlighter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkStrokesCompanion copyWith({
    Value<String>? elementId,
    Value<Uint8List>? points,
    Value<int>? pointCount,
    Value<int>? color,
    Value<double>? strokeWidth,
    Value<StrokeTool>? tool,
    Value<bool>? isHighlighter,
    Value<int>? rowid,
  }) {
    return InkStrokesCompanion(
      elementId: elementId ?? this.elementId,
      points: points ?? this.points,
      pointCount: pointCount ?? this.pointCount,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (elementId.present) {
      map['element_id'] = Variable<String>(elementId.value);
    }
    if (points.present) {
      map['points'] = Variable<Uint8List>(points.value);
    }
    if (pointCount.present) {
      map['point_count'] = Variable<int>(pointCount.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (strokeWidth.present) {
      map['stroke_width'] = Variable<double>(strokeWidth.value);
    }
    if (tool.present) {
      map['tool'] = Variable<int>(
        $InkStrokesTable.$convertertool.toSql(tool.value),
      );
    }
    if (isHighlighter.present) {
      map['is_highlighter'] = Variable<bool>(isHighlighter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkStrokesCompanion(')
          ..write('elementId: $elementId, ')
          ..write('points: $points, ')
          ..write('pointCount: $pointCount, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('tool: $tool, ')
          ..write('isHighlighter: $isHighlighter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PdfDocumentsTable extends PdfDocuments
    with TableInfo<$PdfDocumentsTable, PdfDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PdfDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _elementIdMeta = const VerificationMeta(
    'elementId',
  );
  @override
  late final GeneratedColumn<String> elementId = GeneratedColumn<String>(
    'element_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvas_elements (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFilenameMeta = const VerificationMeta(
    'originalFilename',
  );
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
    'original_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropLeftMeta = const VerificationMeta(
    'cropLeft',
  );
  @override
  late final GeneratedColumn<double> cropLeft = GeneratedColumn<double>(
    'crop_left',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropTopMeta = const VerificationMeta(
    'cropTop',
  );
  @override
  late final GeneratedColumn<double> cropTop = GeneratedColumn<double>(
    'crop_top',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropRightMeta = const VerificationMeta(
    'cropRight',
  );
  @override
  late final GeneratedColumn<double> cropRight = GeneratedColumn<double>(
    'crop_right',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropBottomMeta = const VerificationMeta(
    'cropBottom',
  );
  @override
  late final GeneratedColumn<double> cropBottom = GeneratedColumn<double>(
    'crop_bottom',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importHashMeta = const VerificationMeta(
    'importHash',
  );
  @override
  late final GeneratedColumn<String> importHash = GeneratedColumn<String>(
    'import_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    elementId,
    filePath,
    originalFilename,
    pageNumber,
    totalPages,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    importHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pdf_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<PdfDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('element_id')) {
      context.handle(
        _elementIdMeta,
        elementId.isAcceptableOrUnknown(data['element_id']!, _elementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_elementIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
        _originalFilenameMeta,
        originalFilename.isAcceptableOrUnknown(
          data['original_filename']!,
          _originalFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPagesMeta);
    }
    if (data.containsKey('crop_left')) {
      context.handle(
        _cropLeftMeta,
        cropLeft.isAcceptableOrUnknown(data['crop_left']!, _cropLeftMeta),
      );
    }
    if (data.containsKey('crop_top')) {
      context.handle(
        _cropTopMeta,
        cropTop.isAcceptableOrUnknown(data['crop_top']!, _cropTopMeta),
      );
    }
    if (data.containsKey('crop_right')) {
      context.handle(
        _cropRightMeta,
        cropRight.isAcceptableOrUnknown(data['crop_right']!, _cropRightMeta),
      );
    }
    if (data.containsKey('crop_bottom')) {
      context.handle(
        _cropBottomMeta,
        cropBottom.isAcceptableOrUnknown(data['crop_bottom']!, _cropBottomMeta),
      );
    }
    if (data.containsKey('import_hash')) {
      context.handle(
        _importHashMeta,
        importHash.isAcceptableOrUnknown(data['import_hash']!, _importHashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {elementId};
  @override
  PdfDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PdfDocument(
      elementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      originalFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_filename'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      cropLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_left'],
      ),
      cropTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_top'],
      ),
      cropRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_right'],
      ),
      cropBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_bottom'],
      ),
      importHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_hash'],
      ),
    );
  }

  @override
  $PdfDocumentsTable createAlias(String alias) {
    return $PdfDocumentsTable(attachedDatabase, alias);
  }
}

class PdfDocument extends DataClass implements Insertable<PdfDocument> {
  final String elementId;

  /// Path of the PDF copied into the app documents directory.
  final String filePath;
  final String originalFilename;
  final int pageNumber;
  final int totalPages;

  /// Optional excerpt sub-region (fraction of the page).
  final double? cropLeft;
  final double? cropTop;
  final double? cropRight;
  final double? cropBottom;

  /// Content hash used to dedupe repeated imports.
  final String? importHash;
  const PdfDocument({
    required this.elementId,
    required this.filePath,
    required this.originalFilename,
    required this.pageNumber,
    required this.totalPages,
    this.cropLeft,
    this.cropTop,
    this.cropRight,
    this.cropBottom,
    this.importHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['element_id'] = Variable<String>(elementId);
    map['file_path'] = Variable<String>(filePath);
    map['original_filename'] = Variable<String>(originalFilename);
    map['page_number'] = Variable<int>(pageNumber);
    map['total_pages'] = Variable<int>(totalPages);
    if (!nullToAbsent || cropLeft != null) {
      map['crop_left'] = Variable<double>(cropLeft);
    }
    if (!nullToAbsent || cropTop != null) {
      map['crop_top'] = Variable<double>(cropTop);
    }
    if (!nullToAbsent || cropRight != null) {
      map['crop_right'] = Variable<double>(cropRight);
    }
    if (!nullToAbsent || cropBottom != null) {
      map['crop_bottom'] = Variable<double>(cropBottom);
    }
    if (!nullToAbsent || importHash != null) {
      map['import_hash'] = Variable<String>(importHash);
    }
    return map;
  }

  PdfDocumentsCompanion toCompanion(bool nullToAbsent) {
    return PdfDocumentsCompanion(
      elementId: Value(elementId),
      filePath: Value(filePath),
      originalFilename: Value(originalFilename),
      pageNumber: Value(pageNumber),
      totalPages: Value(totalPages),
      cropLeft: cropLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(cropLeft),
      cropTop: cropTop == null && nullToAbsent
          ? const Value.absent()
          : Value(cropTop),
      cropRight: cropRight == null && nullToAbsent
          ? const Value.absent()
          : Value(cropRight),
      cropBottom: cropBottom == null && nullToAbsent
          ? const Value.absent()
          : Value(cropBottom),
      importHash: importHash == null && nullToAbsent
          ? const Value.absent()
          : Value(importHash),
    );
  }

  factory PdfDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PdfDocument(
      elementId: serializer.fromJson<String>(json['elementId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      cropLeft: serializer.fromJson<double?>(json['cropLeft']),
      cropTop: serializer.fromJson<double?>(json['cropTop']),
      cropRight: serializer.fromJson<double?>(json['cropRight']),
      cropBottom: serializer.fromJson<double?>(json['cropBottom']),
      importHash: serializer.fromJson<String?>(json['importHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'elementId': serializer.toJson<String>(elementId),
      'filePath': serializer.toJson<String>(filePath),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'totalPages': serializer.toJson<int>(totalPages),
      'cropLeft': serializer.toJson<double?>(cropLeft),
      'cropTop': serializer.toJson<double?>(cropTop),
      'cropRight': serializer.toJson<double?>(cropRight),
      'cropBottom': serializer.toJson<double?>(cropBottom),
      'importHash': serializer.toJson<String?>(importHash),
    };
  }

  PdfDocument copyWith({
    String? elementId,
    String? filePath,
    String? originalFilename,
    int? pageNumber,
    int? totalPages,
    Value<double?> cropLeft = const Value.absent(),
    Value<double?> cropTop = const Value.absent(),
    Value<double?> cropRight = const Value.absent(),
    Value<double?> cropBottom = const Value.absent(),
    Value<String?> importHash = const Value.absent(),
  }) => PdfDocument(
    elementId: elementId ?? this.elementId,
    filePath: filePath ?? this.filePath,
    originalFilename: originalFilename ?? this.originalFilename,
    pageNumber: pageNumber ?? this.pageNumber,
    totalPages: totalPages ?? this.totalPages,
    cropLeft: cropLeft.present ? cropLeft.value : this.cropLeft,
    cropTop: cropTop.present ? cropTop.value : this.cropTop,
    cropRight: cropRight.present ? cropRight.value : this.cropRight,
    cropBottom: cropBottom.present ? cropBottom.value : this.cropBottom,
    importHash: importHash.present ? importHash.value : this.importHash,
  );
  PdfDocument copyWithCompanion(PdfDocumentsCompanion data) {
    return PdfDocument(
      elementId: data.elementId.present ? data.elementId.value : this.elementId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      cropLeft: data.cropLeft.present ? data.cropLeft.value : this.cropLeft,
      cropTop: data.cropTop.present ? data.cropTop.value : this.cropTop,
      cropRight: data.cropRight.present ? data.cropRight.value : this.cropRight,
      cropBottom: data.cropBottom.present
          ? data.cropBottom.value
          : this.cropBottom,
      importHash: data.importHash.present
          ? data.importHash.value
          : this.importHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PdfDocument(')
          ..write('elementId: $elementId, ')
          ..write('filePath: $filePath, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('totalPages: $totalPages, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom, ')
          ..write('importHash: $importHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    elementId,
    filePath,
    originalFilename,
    pageNumber,
    totalPages,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    importHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PdfDocument &&
          other.elementId == this.elementId &&
          other.filePath == this.filePath &&
          other.originalFilename == this.originalFilename &&
          other.pageNumber == this.pageNumber &&
          other.totalPages == this.totalPages &&
          other.cropLeft == this.cropLeft &&
          other.cropTop == this.cropTop &&
          other.cropRight == this.cropRight &&
          other.cropBottom == this.cropBottom &&
          other.importHash == this.importHash);
}

class PdfDocumentsCompanion extends UpdateCompanion<PdfDocument> {
  final Value<String> elementId;
  final Value<String> filePath;
  final Value<String> originalFilename;
  final Value<int> pageNumber;
  final Value<int> totalPages;
  final Value<double?> cropLeft;
  final Value<double?> cropTop;
  final Value<double?> cropRight;
  final Value<double?> cropBottom;
  final Value<String?> importHash;
  final Value<int> rowid;
  const PdfDocumentsCompanion({
    this.elementId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.importHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PdfDocumentsCompanion.insert({
    required String elementId,
    required String filePath,
    required String originalFilename,
    required int pageNumber,
    required int totalPages,
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.importHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : elementId = Value(elementId),
       filePath = Value(filePath),
       originalFilename = Value(originalFilename),
       pageNumber = Value(pageNumber),
       totalPages = Value(totalPages);
  static Insertable<PdfDocument> custom({
    Expression<String>? elementId,
    Expression<String>? filePath,
    Expression<String>? originalFilename,
    Expression<int>? pageNumber,
    Expression<int>? totalPages,
    Expression<double>? cropLeft,
    Expression<double>? cropTop,
    Expression<double>? cropRight,
    Expression<double>? cropBottom,
    Expression<String>? importHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (elementId != null) 'element_id': elementId,
      if (filePath != null) 'file_path': filePath,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (pageNumber != null) 'page_number': pageNumber,
      if (totalPages != null) 'total_pages': totalPages,
      if (cropLeft != null) 'crop_left': cropLeft,
      if (cropTop != null) 'crop_top': cropTop,
      if (cropRight != null) 'crop_right': cropRight,
      if (cropBottom != null) 'crop_bottom': cropBottom,
      if (importHash != null) 'import_hash': importHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PdfDocumentsCompanion copyWith({
    Value<String>? elementId,
    Value<String>? filePath,
    Value<String>? originalFilename,
    Value<int>? pageNumber,
    Value<int>? totalPages,
    Value<double?>? cropLeft,
    Value<double?>? cropTop,
    Value<double?>? cropRight,
    Value<double?>? cropBottom,
    Value<String?>? importHash,
    Value<int>? rowid,
  }) {
    return PdfDocumentsCompanion(
      elementId: elementId ?? this.elementId,
      filePath: filePath ?? this.filePath,
      originalFilename: originalFilename ?? this.originalFilename,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      importHash: importHash ?? this.importHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (elementId.present) {
      map['element_id'] = Variable<String>(elementId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (cropLeft.present) {
      map['crop_left'] = Variable<double>(cropLeft.value);
    }
    if (cropTop.present) {
      map['crop_top'] = Variable<double>(cropTop.value);
    }
    if (cropRight.present) {
      map['crop_right'] = Variable<double>(cropRight.value);
    }
    if (cropBottom.present) {
      map['crop_bottom'] = Variable<double>(cropBottom.value);
    }
    if (importHash.present) {
      map['import_hash'] = Variable<String>(importHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PdfDocumentsCompanion(')
          ..write('elementId: $elementId, ')
          ..write('filePath: $filePath, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('totalPages: $totalPages, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom, ')
          ..write('importHash: $importHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, Image> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _elementIdMeta = const VerificationMeta(
    'elementId',
  );
  @override
  late final GeneratedColumn<String> elementId = GeneratedColumn<String>(
    'element_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvas_elements (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intrinsicWidthMeta = const VerificationMeta(
    'intrinsicWidth',
  );
  @override
  late final GeneratedColumn<double> intrinsicWidth = GeneratedColumn<double>(
    'intrinsic_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intrinsicHeightMeta = const VerificationMeta(
    'intrinsicHeight',
  );
  @override
  late final GeneratedColumn<double> intrinsicHeight = GeneratedColumn<double>(
    'intrinsic_height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    elementId,
    filePath,
    intrinsicWidth,
    intrinsicHeight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<Image> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('element_id')) {
      context.handle(
        _elementIdMeta,
        elementId.isAcceptableOrUnknown(data['element_id']!, _elementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_elementIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('intrinsic_width')) {
      context.handle(
        _intrinsicWidthMeta,
        intrinsicWidth.isAcceptableOrUnknown(
          data['intrinsic_width']!,
          _intrinsicWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intrinsicWidthMeta);
    }
    if (data.containsKey('intrinsic_height')) {
      context.handle(
        _intrinsicHeightMeta,
        intrinsicHeight.isAcceptableOrUnknown(
          data['intrinsic_height']!,
          _intrinsicHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intrinsicHeightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {elementId};
  @override
  Image map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Image(
      elementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      intrinsicWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intrinsic_width'],
      )!,
      intrinsicHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}intrinsic_height'],
      )!,
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class Image extends DataClass implements Insertable<Image> {
  final String elementId;

  /// Path of the image copied into the app documents directory.
  final String filePath;

  /// Native pixel width of the source image, used to preserve aspect ratio.
  final double intrinsicWidth;

  /// Native pixel height of the source image, used to preserve aspect ratio.
  final double intrinsicHeight;
  const Image({
    required this.elementId,
    required this.filePath,
    required this.intrinsicWidth,
    required this.intrinsicHeight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['element_id'] = Variable<String>(elementId);
    map['file_path'] = Variable<String>(filePath);
    map['intrinsic_width'] = Variable<double>(intrinsicWidth);
    map['intrinsic_height'] = Variable<double>(intrinsicHeight);
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      elementId: Value(elementId),
      filePath: Value(filePath),
      intrinsicWidth: Value(intrinsicWidth),
      intrinsicHeight: Value(intrinsicHeight),
    );
  }

  factory Image.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Image(
      elementId: serializer.fromJson<String>(json['elementId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      intrinsicWidth: serializer.fromJson<double>(json['intrinsicWidth']),
      intrinsicHeight: serializer.fromJson<double>(json['intrinsicHeight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'elementId': serializer.toJson<String>(elementId),
      'filePath': serializer.toJson<String>(filePath),
      'intrinsicWidth': serializer.toJson<double>(intrinsicWidth),
      'intrinsicHeight': serializer.toJson<double>(intrinsicHeight),
    };
  }

  Image copyWith({
    String? elementId,
    String? filePath,
    double? intrinsicWidth,
    double? intrinsicHeight,
  }) => Image(
    elementId: elementId ?? this.elementId,
    filePath: filePath ?? this.filePath,
    intrinsicWidth: intrinsicWidth ?? this.intrinsicWidth,
    intrinsicHeight: intrinsicHeight ?? this.intrinsicHeight,
  );
  Image copyWithCompanion(ImagesCompanion data) {
    return Image(
      elementId: data.elementId.present ? data.elementId.value : this.elementId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      intrinsicWidth: data.intrinsicWidth.present
          ? data.intrinsicWidth.value
          : this.intrinsicWidth,
      intrinsicHeight: data.intrinsicHeight.present
          ? data.intrinsicHeight.value
          : this.intrinsicHeight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Image(')
          ..write('elementId: $elementId, ')
          ..write('filePath: $filePath, ')
          ..write('intrinsicWidth: $intrinsicWidth, ')
          ..write('intrinsicHeight: $intrinsicHeight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(elementId, filePath, intrinsicWidth, intrinsicHeight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Image &&
          other.elementId == this.elementId &&
          other.filePath == this.filePath &&
          other.intrinsicWidth == this.intrinsicWidth &&
          other.intrinsicHeight == this.intrinsicHeight);
}

class ImagesCompanion extends UpdateCompanion<Image> {
  final Value<String> elementId;
  final Value<String> filePath;
  final Value<double> intrinsicWidth;
  final Value<double> intrinsicHeight;
  final Value<int> rowid;
  const ImagesCompanion({
    this.elementId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.intrinsicWidth = const Value.absent(),
    this.intrinsicHeight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String elementId,
    required String filePath,
    required double intrinsicWidth,
    required double intrinsicHeight,
    this.rowid = const Value.absent(),
  }) : elementId = Value(elementId),
       filePath = Value(filePath),
       intrinsicWidth = Value(intrinsicWidth),
       intrinsicHeight = Value(intrinsicHeight);
  static Insertable<Image> custom({
    Expression<String>? elementId,
    Expression<String>? filePath,
    Expression<double>? intrinsicWidth,
    Expression<double>? intrinsicHeight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (elementId != null) 'element_id': elementId,
      if (filePath != null) 'file_path': filePath,
      if (intrinsicWidth != null) 'intrinsic_width': intrinsicWidth,
      if (intrinsicHeight != null) 'intrinsic_height': intrinsicHeight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? elementId,
    Value<String>? filePath,
    Value<double>? intrinsicWidth,
    Value<double>? intrinsicHeight,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
      elementId: elementId ?? this.elementId,
      filePath: filePath ?? this.filePath,
      intrinsicWidth: intrinsicWidth ?? this.intrinsicWidth,
      intrinsicHeight: intrinsicHeight ?? this.intrinsicHeight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (elementId.present) {
      map['element_id'] = Variable<String>(elementId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (intrinsicWidth.present) {
      map['intrinsic_width'] = Variable<double>(intrinsicWidth.value);
    }
    if (intrinsicHeight.present) {
      map['intrinsic_height'] = Variable<double>(intrinsicHeight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('elementId: $elementId, ')
          ..write('filePath: $filePath, ')
          ..write('intrinsicWidth: $intrinsicWidth, ')
          ..write('intrinsicHeight: $intrinsicHeight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasLinksTable extends CanvasLinks
    with TableInfo<$CanvasLinksTable, CanvasLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _elementIdMeta = const VerificationMeta(
    'elementId',
  );
  @override
  late final GeneratedColumn<String> elementId = GeneratedColumn<String>(
    'element_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvas_elements (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CanvasLinkKind, int> linkKind =
      GeneratedColumn<int>(
        'link_kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CanvasLinkKind>($CanvasLinksTable.$converterlinkKind);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetCanvasIdMeta = const VerificationMeta(
    'targetCanvasId',
  );
  @override
  late final GeneratedColumn<String> targetCanvasId = GeneratedColumn<String>(
    'target_canvas_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRectXMeta = const VerificationMeta(
    'targetRectX',
  );
  @override
  late final GeneratedColumn<double> targetRectX = GeneratedColumn<double>(
    'target_rect_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRectYMeta = const VerificationMeta(
    'targetRectY',
  );
  @override
  late final GeneratedColumn<double> targetRectY = GeneratedColumn<double>(
    'target_rect_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRectWidthMeta = const VerificationMeta(
    'targetRectWidth',
  );
  @override
  late final GeneratedColumn<double> targetRectWidth = GeneratedColumn<double>(
    'target_rect_width',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRectHeightMeta = const VerificationMeta(
    'targetRectHeight',
  );
  @override
  late final GeneratedColumn<double> targetRectHeight = GeneratedColumn<double>(
    'target_rect_height',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetVpTxMeta = const VerificationMeta(
    'targetVpTx',
  );
  @override
  late final GeneratedColumn<double> targetVpTx = GeneratedColumn<double>(
    'target_vp_tx',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetVpTyMeta = const VerificationMeta(
    'targetVpTy',
  );
  @override
  late final GeneratedColumn<double> targetVpTy = GeneratedColumn<double>(
    'target_vp_ty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetVpScaleMeta = const VerificationMeta(
    'targetVpScale',
  );
  @override
  late final GeneratedColumn<double> targetVpScale = GeneratedColumn<double>(
    'target_vp_scale',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetVpRotationMeta = const VerificationMeta(
    'targetVpRotation',
  );
  @override
  late final GeneratedColumn<double> targetVpRotation = GeneratedColumn<double>(
    'target_vp_rotation',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    elementId,
    linkKind,
    url,
    title,
    targetCanvasId,
    targetRectX,
    targetRectY,
    targetRectWidth,
    targetRectHeight,
    targetVpTx,
    targetVpTy,
    targetVpScale,
    targetVpRotation,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('element_id')) {
      context.handle(
        _elementIdMeta,
        elementId.isAcceptableOrUnknown(data['element_id']!, _elementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_elementIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('target_canvas_id')) {
      context.handle(
        _targetCanvasIdMeta,
        targetCanvasId.isAcceptableOrUnknown(
          data['target_canvas_id']!,
          _targetCanvasIdMeta,
        ),
      );
    }
    if (data.containsKey('target_rect_x')) {
      context.handle(
        _targetRectXMeta,
        targetRectX.isAcceptableOrUnknown(
          data['target_rect_x']!,
          _targetRectXMeta,
        ),
      );
    }
    if (data.containsKey('target_rect_y')) {
      context.handle(
        _targetRectYMeta,
        targetRectY.isAcceptableOrUnknown(
          data['target_rect_y']!,
          _targetRectYMeta,
        ),
      );
    }
    if (data.containsKey('target_rect_width')) {
      context.handle(
        _targetRectWidthMeta,
        targetRectWidth.isAcceptableOrUnknown(
          data['target_rect_width']!,
          _targetRectWidthMeta,
        ),
      );
    }
    if (data.containsKey('target_rect_height')) {
      context.handle(
        _targetRectHeightMeta,
        targetRectHeight.isAcceptableOrUnknown(
          data['target_rect_height']!,
          _targetRectHeightMeta,
        ),
      );
    }
    if (data.containsKey('target_vp_tx')) {
      context.handle(
        _targetVpTxMeta,
        targetVpTx.isAcceptableOrUnknown(
          data['target_vp_tx']!,
          _targetVpTxMeta,
        ),
      );
    }
    if (data.containsKey('target_vp_ty')) {
      context.handle(
        _targetVpTyMeta,
        targetVpTy.isAcceptableOrUnknown(
          data['target_vp_ty']!,
          _targetVpTyMeta,
        ),
      );
    }
    if (data.containsKey('target_vp_scale')) {
      context.handle(
        _targetVpScaleMeta,
        targetVpScale.isAcceptableOrUnknown(
          data['target_vp_scale']!,
          _targetVpScaleMeta,
        ),
      );
    }
    if (data.containsKey('target_vp_rotation')) {
      context.handle(
        _targetVpRotationMeta,
        targetVpRotation.isAcceptableOrUnknown(
          data['target_vp_rotation']!,
          _targetVpRotationMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {elementId};
  @override
  CanvasLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasLink(
      elementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_id'],
      )!,
      linkKind: $CanvasLinksTable.$converterlinkKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}link_kind'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      targetCanvasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_canvas_id'],
      ),
      targetRectX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_rect_x'],
      ),
      targetRectY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_rect_y'],
      ),
      targetRectWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_rect_width'],
      ),
      targetRectHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_rect_height'],
      ),
      targetVpTx: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_vp_tx'],
      ),
      targetVpTy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_vp_ty'],
      ),
      targetVpScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_vp_scale'],
      ),
      targetVpRotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_vp_rotation'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $CanvasLinksTable createAlias(String alias) {
    return $CanvasLinksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CanvasLinkKind, int, int> $converterlinkKind =
      const EnumIndexConverter<CanvasLinkKind>(CanvasLinkKind.values);
}

class CanvasLink extends DataClass implements Insertable<CanvasLink> {
  final String elementId;
  final CanvasLinkKind linkKind;
  final String? url;
  final String? title;
  final String? targetCanvasId;

  /// Optional target region rectangle in world space (legacy — unused; a
  /// region link stores its destination camera in the `target_vp_*` columns).
  final double? targetRectX;
  final double? targetRectY;
  final double? targetRectWidth;
  final double? targetRectHeight;

  /// Optional destination viewport — the camera the target canvas flies to on
  /// open. All four are non-null together (a region link) or all null (a plain
  /// canvas link), mirroring the `canvases.vp_*` column shape.
  final double? targetVpTx;
  final double? targetVpTy;
  final double? targetVpScale;
  final double? targetVpRotation;
  final String label;
  const CanvasLink({
    required this.elementId,
    required this.linkKind,
    this.url,
    this.title,
    this.targetCanvasId,
    this.targetRectX,
    this.targetRectY,
    this.targetRectWidth,
    this.targetRectHeight,
    this.targetVpTx,
    this.targetVpTy,
    this.targetVpScale,
    this.targetVpRotation,
    required this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['element_id'] = Variable<String>(elementId);
    {
      map['link_kind'] = Variable<int>(
        $CanvasLinksTable.$converterlinkKind.toSql(linkKind),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || targetCanvasId != null) {
      map['target_canvas_id'] = Variable<String>(targetCanvasId);
    }
    if (!nullToAbsent || targetRectX != null) {
      map['target_rect_x'] = Variable<double>(targetRectX);
    }
    if (!nullToAbsent || targetRectY != null) {
      map['target_rect_y'] = Variable<double>(targetRectY);
    }
    if (!nullToAbsent || targetRectWidth != null) {
      map['target_rect_width'] = Variable<double>(targetRectWidth);
    }
    if (!nullToAbsent || targetRectHeight != null) {
      map['target_rect_height'] = Variable<double>(targetRectHeight);
    }
    if (!nullToAbsent || targetVpTx != null) {
      map['target_vp_tx'] = Variable<double>(targetVpTx);
    }
    if (!nullToAbsent || targetVpTy != null) {
      map['target_vp_ty'] = Variable<double>(targetVpTy);
    }
    if (!nullToAbsent || targetVpScale != null) {
      map['target_vp_scale'] = Variable<double>(targetVpScale);
    }
    if (!nullToAbsent || targetVpRotation != null) {
      map['target_vp_rotation'] = Variable<double>(targetVpRotation);
    }
    map['label'] = Variable<String>(label);
    return map;
  }

  CanvasLinksCompanion toCompanion(bool nullToAbsent) {
    return CanvasLinksCompanion(
      elementId: Value(elementId),
      linkKind: Value(linkKind),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      targetCanvasId: targetCanvasId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCanvasId),
      targetRectX: targetRectX == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRectX),
      targetRectY: targetRectY == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRectY),
      targetRectWidth: targetRectWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRectWidth),
      targetRectHeight: targetRectHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRectHeight),
      targetVpTx: targetVpTx == null && nullToAbsent
          ? const Value.absent()
          : Value(targetVpTx),
      targetVpTy: targetVpTy == null && nullToAbsent
          ? const Value.absent()
          : Value(targetVpTy),
      targetVpScale: targetVpScale == null && nullToAbsent
          ? const Value.absent()
          : Value(targetVpScale),
      targetVpRotation: targetVpRotation == null && nullToAbsent
          ? const Value.absent()
          : Value(targetVpRotation),
      label: Value(label),
    );
  }

  factory CanvasLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasLink(
      elementId: serializer.fromJson<String>(json['elementId']),
      linkKind: $CanvasLinksTable.$converterlinkKind.fromJson(
        serializer.fromJson<int>(json['linkKind']),
      ),
      url: serializer.fromJson<String?>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      targetCanvasId: serializer.fromJson<String?>(json['targetCanvasId']),
      targetRectX: serializer.fromJson<double?>(json['targetRectX']),
      targetRectY: serializer.fromJson<double?>(json['targetRectY']),
      targetRectWidth: serializer.fromJson<double?>(json['targetRectWidth']),
      targetRectHeight: serializer.fromJson<double?>(json['targetRectHeight']),
      targetVpTx: serializer.fromJson<double?>(json['targetVpTx']),
      targetVpTy: serializer.fromJson<double?>(json['targetVpTy']),
      targetVpScale: serializer.fromJson<double?>(json['targetVpScale']),
      targetVpRotation: serializer.fromJson<double?>(json['targetVpRotation']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'elementId': serializer.toJson<String>(elementId),
      'linkKind': serializer.toJson<int>(
        $CanvasLinksTable.$converterlinkKind.toJson(linkKind),
      ),
      'url': serializer.toJson<String?>(url),
      'title': serializer.toJson<String?>(title),
      'targetCanvasId': serializer.toJson<String?>(targetCanvasId),
      'targetRectX': serializer.toJson<double?>(targetRectX),
      'targetRectY': serializer.toJson<double?>(targetRectY),
      'targetRectWidth': serializer.toJson<double?>(targetRectWidth),
      'targetRectHeight': serializer.toJson<double?>(targetRectHeight),
      'targetVpTx': serializer.toJson<double?>(targetVpTx),
      'targetVpTy': serializer.toJson<double?>(targetVpTy),
      'targetVpScale': serializer.toJson<double?>(targetVpScale),
      'targetVpRotation': serializer.toJson<double?>(targetVpRotation),
      'label': serializer.toJson<String>(label),
    };
  }

  CanvasLink copyWith({
    String? elementId,
    CanvasLinkKind? linkKind,
    Value<String?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> targetCanvasId = const Value.absent(),
    Value<double?> targetRectX = const Value.absent(),
    Value<double?> targetRectY = const Value.absent(),
    Value<double?> targetRectWidth = const Value.absent(),
    Value<double?> targetRectHeight = const Value.absent(),
    Value<double?> targetVpTx = const Value.absent(),
    Value<double?> targetVpTy = const Value.absent(),
    Value<double?> targetVpScale = const Value.absent(),
    Value<double?> targetVpRotation = const Value.absent(),
    String? label,
  }) => CanvasLink(
    elementId: elementId ?? this.elementId,
    linkKind: linkKind ?? this.linkKind,
    url: url.present ? url.value : this.url,
    title: title.present ? title.value : this.title,
    targetCanvasId: targetCanvasId.present
        ? targetCanvasId.value
        : this.targetCanvasId,
    targetRectX: targetRectX.present ? targetRectX.value : this.targetRectX,
    targetRectY: targetRectY.present ? targetRectY.value : this.targetRectY,
    targetRectWidth: targetRectWidth.present
        ? targetRectWidth.value
        : this.targetRectWidth,
    targetRectHeight: targetRectHeight.present
        ? targetRectHeight.value
        : this.targetRectHeight,
    targetVpTx: targetVpTx.present ? targetVpTx.value : this.targetVpTx,
    targetVpTy: targetVpTy.present ? targetVpTy.value : this.targetVpTy,
    targetVpScale: targetVpScale.present
        ? targetVpScale.value
        : this.targetVpScale,
    targetVpRotation: targetVpRotation.present
        ? targetVpRotation.value
        : this.targetVpRotation,
    label: label ?? this.label,
  );
  CanvasLink copyWithCompanion(CanvasLinksCompanion data) {
    return CanvasLink(
      elementId: data.elementId.present ? data.elementId.value : this.elementId,
      linkKind: data.linkKind.present ? data.linkKind.value : this.linkKind,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      targetCanvasId: data.targetCanvasId.present
          ? data.targetCanvasId.value
          : this.targetCanvasId,
      targetRectX: data.targetRectX.present
          ? data.targetRectX.value
          : this.targetRectX,
      targetRectY: data.targetRectY.present
          ? data.targetRectY.value
          : this.targetRectY,
      targetRectWidth: data.targetRectWidth.present
          ? data.targetRectWidth.value
          : this.targetRectWidth,
      targetRectHeight: data.targetRectHeight.present
          ? data.targetRectHeight.value
          : this.targetRectHeight,
      targetVpTx: data.targetVpTx.present
          ? data.targetVpTx.value
          : this.targetVpTx,
      targetVpTy: data.targetVpTy.present
          ? data.targetVpTy.value
          : this.targetVpTy,
      targetVpScale: data.targetVpScale.present
          ? data.targetVpScale.value
          : this.targetVpScale,
      targetVpRotation: data.targetVpRotation.present
          ? data.targetVpRotation.value
          : this.targetVpRotation,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasLink(')
          ..write('elementId: $elementId, ')
          ..write('linkKind: $linkKind, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('targetCanvasId: $targetCanvasId, ')
          ..write('targetRectX: $targetRectX, ')
          ..write('targetRectY: $targetRectY, ')
          ..write('targetRectWidth: $targetRectWidth, ')
          ..write('targetRectHeight: $targetRectHeight, ')
          ..write('targetVpTx: $targetVpTx, ')
          ..write('targetVpTy: $targetVpTy, ')
          ..write('targetVpScale: $targetVpScale, ')
          ..write('targetVpRotation: $targetVpRotation, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    elementId,
    linkKind,
    url,
    title,
    targetCanvasId,
    targetRectX,
    targetRectY,
    targetRectWidth,
    targetRectHeight,
    targetVpTx,
    targetVpTy,
    targetVpScale,
    targetVpRotation,
    label,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasLink &&
          other.elementId == this.elementId &&
          other.linkKind == this.linkKind &&
          other.url == this.url &&
          other.title == this.title &&
          other.targetCanvasId == this.targetCanvasId &&
          other.targetRectX == this.targetRectX &&
          other.targetRectY == this.targetRectY &&
          other.targetRectWidth == this.targetRectWidth &&
          other.targetRectHeight == this.targetRectHeight &&
          other.targetVpTx == this.targetVpTx &&
          other.targetVpTy == this.targetVpTy &&
          other.targetVpScale == this.targetVpScale &&
          other.targetVpRotation == this.targetVpRotation &&
          other.label == this.label);
}

class CanvasLinksCompanion extends UpdateCompanion<CanvasLink> {
  final Value<String> elementId;
  final Value<CanvasLinkKind> linkKind;
  final Value<String?> url;
  final Value<String?> title;
  final Value<String?> targetCanvasId;
  final Value<double?> targetRectX;
  final Value<double?> targetRectY;
  final Value<double?> targetRectWidth;
  final Value<double?> targetRectHeight;
  final Value<double?> targetVpTx;
  final Value<double?> targetVpTy;
  final Value<double?> targetVpScale;
  final Value<double?> targetVpRotation;
  final Value<String> label;
  final Value<int> rowid;
  const CanvasLinksCompanion({
    this.elementId = const Value.absent(),
    this.linkKind = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.targetCanvasId = const Value.absent(),
    this.targetRectX = const Value.absent(),
    this.targetRectY = const Value.absent(),
    this.targetRectWidth = const Value.absent(),
    this.targetRectHeight = const Value.absent(),
    this.targetVpTx = const Value.absent(),
    this.targetVpTy = const Value.absent(),
    this.targetVpScale = const Value.absent(),
    this.targetVpRotation = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasLinksCompanion.insert({
    required String elementId,
    required CanvasLinkKind linkKind,
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.targetCanvasId = const Value.absent(),
    this.targetRectX = const Value.absent(),
    this.targetRectY = const Value.absent(),
    this.targetRectWidth = const Value.absent(),
    this.targetRectHeight = const Value.absent(),
    this.targetVpTx = const Value.absent(),
    this.targetVpTy = const Value.absent(),
    this.targetVpScale = const Value.absent(),
    this.targetVpRotation = const Value.absent(),
    required String label,
    this.rowid = const Value.absent(),
  }) : elementId = Value(elementId),
       linkKind = Value(linkKind),
       label = Value(label);
  static Insertable<CanvasLink> custom({
    Expression<String>? elementId,
    Expression<int>? linkKind,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? targetCanvasId,
    Expression<double>? targetRectX,
    Expression<double>? targetRectY,
    Expression<double>? targetRectWidth,
    Expression<double>? targetRectHeight,
    Expression<double>? targetVpTx,
    Expression<double>? targetVpTy,
    Expression<double>? targetVpScale,
    Expression<double>? targetVpRotation,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (elementId != null) 'element_id': elementId,
      if (linkKind != null) 'link_kind': linkKind,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (targetCanvasId != null) 'target_canvas_id': targetCanvasId,
      if (targetRectX != null) 'target_rect_x': targetRectX,
      if (targetRectY != null) 'target_rect_y': targetRectY,
      if (targetRectWidth != null) 'target_rect_width': targetRectWidth,
      if (targetRectHeight != null) 'target_rect_height': targetRectHeight,
      if (targetVpTx != null) 'target_vp_tx': targetVpTx,
      if (targetVpTy != null) 'target_vp_ty': targetVpTy,
      if (targetVpScale != null) 'target_vp_scale': targetVpScale,
      if (targetVpRotation != null) 'target_vp_rotation': targetVpRotation,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasLinksCompanion copyWith({
    Value<String>? elementId,
    Value<CanvasLinkKind>? linkKind,
    Value<String?>? url,
    Value<String?>? title,
    Value<String?>? targetCanvasId,
    Value<double?>? targetRectX,
    Value<double?>? targetRectY,
    Value<double?>? targetRectWidth,
    Value<double?>? targetRectHeight,
    Value<double?>? targetVpTx,
    Value<double?>? targetVpTy,
    Value<double?>? targetVpScale,
    Value<double?>? targetVpRotation,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return CanvasLinksCompanion(
      elementId: elementId ?? this.elementId,
      linkKind: linkKind ?? this.linkKind,
      url: url ?? this.url,
      title: title ?? this.title,
      targetCanvasId: targetCanvasId ?? this.targetCanvasId,
      targetRectX: targetRectX ?? this.targetRectX,
      targetRectY: targetRectY ?? this.targetRectY,
      targetRectWidth: targetRectWidth ?? this.targetRectWidth,
      targetRectHeight: targetRectHeight ?? this.targetRectHeight,
      targetVpTx: targetVpTx ?? this.targetVpTx,
      targetVpTy: targetVpTy ?? this.targetVpTy,
      targetVpScale: targetVpScale ?? this.targetVpScale,
      targetVpRotation: targetVpRotation ?? this.targetVpRotation,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (elementId.present) {
      map['element_id'] = Variable<String>(elementId.value);
    }
    if (linkKind.present) {
      map['link_kind'] = Variable<int>(
        $CanvasLinksTable.$converterlinkKind.toSql(linkKind.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetCanvasId.present) {
      map['target_canvas_id'] = Variable<String>(targetCanvasId.value);
    }
    if (targetRectX.present) {
      map['target_rect_x'] = Variable<double>(targetRectX.value);
    }
    if (targetRectY.present) {
      map['target_rect_y'] = Variable<double>(targetRectY.value);
    }
    if (targetRectWidth.present) {
      map['target_rect_width'] = Variable<double>(targetRectWidth.value);
    }
    if (targetRectHeight.present) {
      map['target_rect_height'] = Variable<double>(targetRectHeight.value);
    }
    if (targetVpTx.present) {
      map['target_vp_tx'] = Variable<double>(targetVpTx.value);
    }
    if (targetVpTy.present) {
      map['target_vp_ty'] = Variable<double>(targetVpTy.value);
    }
    if (targetVpScale.present) {
      map['target_vp_scale'] = Variable<double>(targetVpScale.value);
    }
    if (targetVpRotation.present) {
      map['target_vp_rotation'] = Variable<double>(targetVpRotation.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasLinksCompanion(')
          ..write('elementId: $elementId, ')
          ..write('linkKind: $linkKind, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('targetCanvasId: $targetCanvasId, ')
          ..write('targetRectX: $targetRectX, ')
          ..write('targetRectY: $targetRectY, ')
          ..write('targetRectWidth: $targetRectWidth, ')
          ..write('targetRectHeight: $targetRectHeight, ')
          ..write('targetVpTx: $targetVpTx, ')
          ..write('targetVpTy: $targetVpTy, ')
          ..write('targetVpScale: $targetVpScale, ')
          ..write('targetVpRotation: $targetVpRotation, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RitualChecklistsTable extends RitualChecklists
    with TableInfo<$RitualChecklistsTable, RitualChecklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RitualChecklistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ritual_checklists';
  @override
  VerificationContext validateIntegrity(
    Insertable<RitualChecklist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RitualChecklist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RitualChecklist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $RitualChecklistsTable createAlias(String alias) {
    return $RitualChecklistsTable(attachedDatabase, alias);
  }
}

class RitualChecklist extends DataClass implements Insertable<RitualChecklist> {
  final String id;
  final String name;
  final bool isDefault;
  const RitualChecklist({
    required this.id,
    required this.name,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  RitualChecklistsCompanion toCompanion(bool nullToAbsent) {
    return RitualChecklistsCompanion(
      id: Value(id),
      name: Value(name),
      isDefault: Value(isDefault),
    );
  }

  factory RitualChecklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RitualChecklist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  RitualChecklist copyWith({String? id, String? name, bool? isDefault}) =>
      RitualChecklist(
        id: id ?? this.id,
        name: name ?? this.name,
        isDefault: isDefault ?? this.isDefault,
      );
  RitualChecklist copyWithCompanion(RitualChecklistsCompanion data) {
    return RitualChecklist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RitualChecklist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RitualChecklist &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDefault == this.isDefault);
}

class RitualChecklistsCompanion extends UpdateCompanion<RitualChecklist> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const RitualChecklistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RitualChecklistsCompanion.insert({
    required String id,
    required String name,
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<RitualChecklist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RitualChecklistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return RitualChecklistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RitualChecklistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RitualChecklistItemsTable extends RitualChecklistItems
    with TableInfo<$RitualChecklistItemsTable, RitualChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RitualChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checklistIdMeta = const VerificationMeta(
    'checklistId',
  );
  @override
  late final GeneratedColumn<String> checklistId = GeneratedColumn<String>(
    'checklist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ritual_checklists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    checklistId,
    label,
    position,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ritual_checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RitualChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checklist_id')) {
      context.handle(
        _checklistIdMeta,
        checklistId.isAcceptableOrUnknown(
          data['checklist_id']!,
          _checklistIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checklistIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RitualChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RitualChecklistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      checklistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $RitualChecklistItemsTable createAlias(String alias) {
    return $RitualChecklistItemsTable(attachedDatabase, alias);
  }
}

class RitualChecklistItem extends DataClass
    implements Insertable<RitualChecklistItem> {
  final String id;
  final String checklistId;
  final String label;

  /// Fractional ordering position.
  final double position;
  final bool isActive;
  const RitualChecklistItem({
    required this.id,
    required this.checklistId,
    required this.label,
    required this.position,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['checklist_id'] = Variable<String>(checklistId);
    map['label'] = Variable<String>(label);
    map['position'] = Variable<double>(position);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  RitualChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return RitualChecklistItemsCompanion(
      id: Value(id),
      checklistId: Value(checklistId),
      label: Value(label),
      position: Value(position),
      isActive: Value(isActive),
    );
  }

  factory RitualChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RitualChecklistItem(
      id: serializer.fromJson<String>(json['id']),
      checklistId: serializer.fromJson<String>(json['checklistId']),
      label: serializer.fromJson<String>(json['label']),
      position: serializer.fromJson<double>(json['position']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'checklistId': serializer.toJson<String>(checklistId),
      'label': serializer.toJson<String>(label),
      'position': serializer.toJson<double>(position),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  RitualChecklistItem copyWith({
    String? id,
    String? checklistId,
    String? label,
    double? position,
    bool? isActive,
  }) => RitualChecklistItem(
    id: id ?? this.id,
    checklistId: checklistId ?? this.checklistId,
    label: label ?? this.label,
    position: position ?? this.position,
    isActive: isActive ?? this.isActive,
  );
  RitualChecklistItem copyWithCompanion(RitualChecklistItemsCompanion data) {
    return RitualChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      checklistId: data.checklistId.present
          ? data.checklistId.value
          : this.checklistId,
      label: data.label.present ? data.label.value : this.label,
      position: data.position.present ? data.position.value : this.position,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RitualChecklistItem(')
          ..write('id: $id, ')
          ..write('checklistId: $checklistId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, checklistId, label, position, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RitualChecklistItem &&
          other.id == this.id &&
          other.checklistId == this.checklistId &&
          other.label == this.label &&
          other.position == this.position &&
          other.isActive == this.isActive);
}

class RitualChecklistItemsCompanion
    extends UpdateCompanion<RitualChecklistItem> {
  final Value<String> id;
  final Value<String> checklistId;
  final Value<String> label;
  final Value<double> position;
  final Value<bool> isActive;
  final Value<int> rowid;
  const RitualChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.checklistId = const Value.absent(),
    this.label = const Value.absent(),
    this.position = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RitualChecklistItemsCompanion.insert({
    required String id,
    required String checklistId,
    required String label,
    required double position,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       checklistId = Value(checklistId),
       label = Value(label),
       position = Value(position);
  static Insertable<RitualChecklistItem> custom({
    Expression<String>? id,
    Expression<String>? checklistId,
    Expression<String>? label,
    Expression<double>? position,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (checklistId != null) 'checklist_id': checklistId,
      if (label != null) 'label': label,
      if (position != null) 'position': position,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RitualChecklistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? checklistId,
    Value<String>? label,
    Value<double>? position,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return RitualChecklistItemsCompanion(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      label: label ?? this.label,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (checklistId.present) {
      map['checklist_id'] = Variable<String>(checklistId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RitualChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('checklistId: $checklistId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTextMeta = const VerificationMeta(
    'goalText',
  );
  @override
  late final GeneratedColumn<String> goalText = GeneratedColumn<String>(
    'goal_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preEnergyMeta = const VerificationMeta(
    'preEnergy',
  );
  @override
  late final GeneratedColumn<int> preEnergy = GeneratedColumn<int>(
    'pre_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postEnergyMeta = const VerificationMeta(
    'postEnergy',
  );
  @override
  late final GeneratedColumn<int> postEnergy = GeneratedColumn<int>(
    'post_energy',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TimerKind, int> timerKind =
      GeneratedColumn<int>(
        'timer_kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TimerKind>($FocusSessionsTable.$convertertimerKind);
  static const VerificationMeta _plannedDurationSecsMeta =
      const VerificationMeta('plannedDurationSecs');
  @override
  late final GeneratedColumn<int> plannedDurationSecs = GeneratedColumn<int>(
    'planned_duration_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualFocusSecsMeta = const VerificationMeta(
    'actualFocusSecs',
  );
  @override
  late final GeneratedColumn<int> actualFocusSecs = GeneratedColumn<int>(
    'actual_focus_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pomodoroWorkSecsMeta = const VerificationMeta(
    'pomodoroWorkSecs',
  );
  @override
  late final GeneratedColumn<int> pomodoroWorkSecs = GeneratedColumn<int>(
    'pomodoro_work_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pomodoroBreakSecsMeta = const VerificationMeta(
    'pomodoroBreakSecs',
  );
  @override
  late final GeneratedColumn<int> pomodoroBreakSecs = GeneratedColumn<int>(
    'pomodoro_break_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flowBreakRatioMeta = const VerificationMeta(
    'flowBreakRatio',
  );
  @override
  late final GeneratedColumn<double> flowBreakRatio = GeneratedColumn<double>(
    'flow_break_ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cyclesCompletedMeta = const VerificationMeta(
    'cyclesCompleted',
  );
  @override
  late final GeneratedColumn<int> cyclesCompleted = GeneratedColumn<int>(
    'cycles_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FocusSessionStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<FocusSessionStatus>($FocusSessionsTable.$converterstatus);
  static const VerificationMeta _runtimeStatusMeta = const VerificationMeta(
    'runtimeStatus',
  );
  @override
  late final GeneratedColumn<int> runtimeStatus = GeneratedColumn<int>(
    'runtime_status',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimePhaseMeta = const VerificationMeta(
    'runtimePhase',
  );
  @override
  late final GeneratedColumn<int> runtimePhase = GeneratedColumn<int>(
    'runtime_phase',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimePhaseStartedAtMeta =
      const VerificationMeta('runtimePhaseStartedAt');
  @override
  late final GeneratedColumn<DateTime> runtimePhaseStartedAt =
      GeneratedColumn<DateTime>(
        'runtime_phase_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _runtimeCarriedPhaseSecsMeta =
      const VerificationMeta('runtimeCarriedPhaseSecs');
  @override
  late final GeneratedColumn<int> runtimeCarriedPhaseSecs =
      GeneratedColumn<int>(
        'runtime_carried_phase_secs',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _runtimePhaseTargetSecsMeta =
      const VerificationMeta('runtimePhaseTargetSecs');
  @override
  late final GeneratedColumn<int> runtimePhaseTargetSecs = GeneratedColumn<int>(
    'runtime_phase_target_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeBankedFocusSecsMeta =
      const VerificationMeta('runtimeBankedFocusSecs');
  @override
  late final GeneratedColumn<int> runtimeBankedFocusSecs = GeneratedColumn<int>(
    'runtime_banked_focus_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _linkedCanvasIdMeta = const VerificationMeta(
    'linkedCanvasId',
  );
  @override
  late final GeneratedColumn<String> linkedCanvasId = GeneratedColumn<String>(
    'linked_canvas_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES canvases (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    goalText,
    preEnergy,
    postEnergy,
    timerKind,
    plannedDurationSecs,
    actualFocusSecs,
    pomodoroWorkSecs,
    pomodoroBreakSecs,
    flowBreakRatio,
    cyclesCompleted,
    status,
    runtimeStatus,
    runtimePhase,
    runtimePhaseStartedAt,
    runtimeCarriedPhaseSecs,
    runtimePhaseTargetSecs,
    runtimeBankedFocusSecs,
    linkedCanvasId,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('goal_text')) {
      context.handle(
        _goalTextMeta,
        goalText.isAcceptableOrUnknown(data['goal_text']!, _goalTextMeta),
      );
    } else if (isInserting) {
      context.missing(_goalTextMeta);
    }
    if (data.containsKey('pre_energy')) {
      context.handle(
        _preEnergyMeta,
        preEnergy.isAcceptableOrUnknown(data['pre_energy']!, _preEnergyMeta),
      );
    } else if (isInserting) {
      context.missing(_preEnergyMeta);
    }
    if (data.containsKey('post_energy')) {
      context.handle(
        _postEnergyMeta,
        postEnergy.isAcceptableOrUnknown(data['post_energy']!, _postEnergyMeta),
      );
    }
    if (data.containsKey('planned_duration_secs')) {
      context.handle(
        _plannedDurationSecsMeta,
        plannedDurationSecs.isAcceptableOrUnknown(
          data['planned_duration_secs']!,
          _plannedDurationSecsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedDurationSecsMeta);
    }
    if (data.containsKey('actual_focus_secs')) {
      context.handle(
        _actualFocusSecsMeta,
        actualFocusSecs.isAcceptableOrUnknown(
          data['actual_focus_secs']!,
          _actualFocusSecsMeta,
        ),
      );
    }
    if (data.containsKey('pomodoro_work_secs')) {
      context.handle(
        _pomodoroWorkSecsMeta,
        pomodoroWorkSecs.isAcceptableOrUnknown(
          data['pomodoro_work_secs']!,
          _pomodoroWorkSecsMeta,
        ),
      );
    }
    if (data.containsKey('pomodoro_break_secs')) {
      context.handle(
        _pomodoroBreakSecsMeta,
        pomodoroBreakSecs.isAcceptableOrUnknown(
          data['pomodoro_break_secs']!,
          _pomodoroBreakSecsMeta,
        ),
      );
    }
    if (data.containsKey('flow_break_ratio')) {
      context.handle(
        _flowBreakRatioMeta,
        flowBreakRatio.isAcceptableOrUnknown(
          data['flow_break_ratio']!,
          _flowBreakRatioMeta,
        ),
      );
    }
    if (data.containsKey('cycles_completed')) {
      context.handle(
        _cyclesCompletedMeta,
        cyclesCompleted.isAcceptableOrUnknown(
          data['cycles_completed']!,
          _cyclesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('runtime_status')) {
      context.handle(
        _runtimeStatusMeta,
        runtimeStatus.isAcceptableOrUnknown(
          data['runtime_status']!,
          _runtimeStatusMeta,
        ),
      );
    }
    if (data.containsKey('runtime_phase')) {
      context.handle(
        _runtimePhaseMeta,
        runtimePhase.isAcceptableOrUnknown(
          data['runtime_phase']!,
          _runtimePhaseMeta,
        ),
      );
    }
    if (data.containsKey('runtime_phase_started_at')) {
      context.handle(
        _runtimePhaseStartedAtMeta,
        runtimePhaseStartedAt.isAcceptableOrUnknown(
          data['runtime_phase_started_at']!,
          _runtimePhaseStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('runtime_carried_phase_secs')) {
      context.handle(
        _runtimeCarriedPhaseSecsMeta,
        runtimeCarriedPhaseSecs.isAcceptableOrUnknown(
          data['runtime_carried_phase_secs']!,
          _runtimeCarriedPhaseSecsMeta,
        ),
      );
    }
    if (data.containsKey('runtime_phase_target_secs')) {
      context.handle(
        _runtimePhaseTargetSecsMeta,
        runtimePhaseTargetSecs.isAcceptableOrUnknown(
          data['runtime_phase_target_secs']!,
          _runtimePhaseTargetSecsMeta,
        ),
      );
    }
    if (data.containsKey('runtime_banked_focus_secs')) {
      context.handle(
        _runtimeBankedFocusSecsMeta,
        runtimeBankedFocusSecs.isAcceptableOrUnknown(
          data['runtime_banked_focus_secs']!,
          _runtimeBankedFocusSecsMeta,
        ),
      );
    }
    if (data.containsKey('linked_canvas_id')) {
      context.handle(
        _linkedCanvasIdMeta,
        linkedCanvasId.isAcceptableOrUnknown(
          data['linked_canvas_id']!,
          _linkedCanvasIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      goalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_text'],
      )!,
      preEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pre_energy'],
      )!,
      postEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}post_energy'],
      ),
      timerKind: $FocusSessionsTable.$convertertimerKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}timer_kind'],
        )!,
      ),
      plannedDurationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_secs'],
      )!,
      actualFocusSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_focus_secs'],
      )!,
      pomodoroWorkSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pomodoro_work_secs'],
      ),
      pomodoroBreakSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pomodoro_break_secs'],
      ),
      flowBreakRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}flow_break_ratio'],
      ),
      cyclesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycles_completed'],
      )!,
      status: $FocusSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      runtimeStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_status'],
      ),
      runtimePhase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_phase'],
      ),
      runtimePhaseStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}runtime_phase_started_at'],
      ),
      runtimeCarriedPhaseSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_carried_phase_secs'],
      )!,
      runtimePhaseTargetSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_phase_target_secs'],
      ),
      runtimeBankedFocusSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_banked_focus_secs'],
      )!,
      linkedCanvasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_canvas_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TimerKind, int, int> $convertertimerKind =
      const EnumIndexConverter<TimerKind>(TimerKind.values);
  static JsonTypeConverter2<FocusSessionStatus, int, int> $converterstatus =
      const EnumIndexConverter<FocusSessionStatus>(FocusSessionStatus.values);
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String goalText;

  /// Self-rated energy on a 1–5 scale.
  final int preEnergy;
  final int? postEnergy;
  final TimerKind timerKind;
  final int plannedDurationSecs;

  /// Accumulated work time only (excludes breaks).
  final int actualFocusSecs;
  final int? pomodoroWorkSecs;
  final int? pomodoroBreakSecs;
  final double? flowBreakRatio;
  final int cyclesCompleted;
  final FocusSessionStatus status;

  /// Restorable runtime status from the live timer engine.
  final int? runtimeStatus;
  final int? runtimePhase;
  final DateTime? runtimePhaseStartedAt;
  final int runtimeCarriedPhaseSecs;
  final int? runtimePhaseTargetSecs;
  final int runtimeBankedFocusSecs;
  final String? linkedCanvasId;
  final String? notes;
  const FocusSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.goalText,
    required this.preEnergy,
    this.postEnergy,
    required this.timerKind,
    required this.plannedDurationSecs,
    required this.actualFocusSecs,
    this.pomodoroWorkSecs,
    this.pomodoroBreakSecs,
    this.flowBreakRatio,
    required this.cyclesCompleted,
    required this.status,
    this.runtimeStatus,
    this.runtimePhase,
    this.runtimePhaseStartedAt,
    required this.runtimeCarriedPhaseSecs,
    this.runtimePhaseTargetSecs,
    required this.runtimeBankedFocusSecs,
    this.linkedCanvasId,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['goal_text'] = Variable<String>(goalText);
    map['pre_energy'] = Variable<int>(preEnergy);
    if (!nullToAbsent || postEnergy != null) {
      map['post_energy'] = Variable<int>(postEnergy);
    }
    {
      map['timer_kind'] = Variable<int>(
        $FocusSessionsTable.$convertertimerKind.toSql(timerKind),
      );
    }
    map['planned_duration_secs'] = Variable<int>(plannedDurationSecs);
    map['actual_focus_secs'] = Variable<int>(actualFocusSecs);
    if (!nullToAbsent || pomodoroWorkSecs != null) {
      map['pomodoro_work_secs'] = Variable<int>(pomodoroWorkSecs);
    }
    if (!nullToAbsent || pomodoroBreakSecs != null) {
      map['pomodoro_break_secs'] = Variable<int>(pomodoroBreakSecs);
    }
    if (!nullToAbsent || flowBreakRatio != null) {
      map['flow_break_ratio'] = Variable<double>(flowBreakRatio);
    }
    map['cycles_completed'] = Variable<int>(cyclesCompleted);
    {
      map['status'] = Variable<int>(
        $FocusSessionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || runtimeStatus != null) {
      map['runtime_status'] = Variable<int>(runtimeStatus);
    }
    if (!nullToAbsent || runtimePhase != null) {
      map['runtime_phase'] = Variable<int>(runtimePhase);
    }
    if (!nullToAbsent || runtimePhaseStartedAt != null) {
      map['runtime_phase_started_at'] = Variable<DateTime>(
        runtimePhaseStartedAt,
      );
    }
    map['runtime_carried_phase_secs'] = Variable<int>(runtimeCarriedPhaseSecs);
    if (!nullToAbsent || runtimePhaseTargetSecs != null) {
      map['runtime_phase_target_secs'] = Variable<int>(runtimePhaseTargetSecs);
    }
    map['runtime_banked_focus_secs'] = Variable<int>(runtimeBankedFocusSecs);
    if (!nullToAbsent || linkedCanvasId != null) {
      map['linked_canvas_id'] = Variable<String>(linkedCanvasId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      goalText: Value(goalText),
      preEnergy: Value(preEnergy),
      postEnergy: postEnergy == null && nullToAbsent
          ? const Value.absent()
          : Value(postEnergy),
      timerKind: Value(timerKind),
      plannedDurationSecs: Value(plannedDurationSecs),
      actualFocusSecs: Value(actualFocusSecs),
      pomodoroWorkSecs: pomodoroWorkSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(pomodoroWorkSecs),
      pomodoroBreakSecs: pomodoroBreakSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(pomodoroBreakSecs),
      flowBreakRatio: flowBreakRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(flowBreakRatio),
      cyclesCompleted: Value(cyclesCompleted),
      status: Value(status),
      runtimeStatus: runtimeStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(runtimeStatus),
      runtimePhase: runtimePhase == null && nullToAbsent
          ? const Value.absent()
          : Value(runtimePhase),
      runtimePhaseStartedAt: runtimePhaseStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(runtimePhaseStartedAt),
      runtimeCarriedPhaseSecs: Value(runtimeCarriedPhaseSecs),
      runtimePhaseTargetSecs: runtimePhaseTargetSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(runtimePhaseTargetSecs),
      runtimeBankedFocusSecs: Value(runtimeBankedFocusSecs),
      linkedCanvasId: linkedCanvasId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedCanvasId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      goalText: serializer.fromJson<String>(json['goalText']),
      preEnergy: serializer.fromJson<int>(json['preEnergy']),
      postEnergy: serializer.fromJson<int?>(json['postEnergy']),
      timerKind: $FocusSessionsTable.$convertertimerKind.fromJson(
        serializer.fromJson<int>(json['timerKind']),
      ),
      plannedDurationSecs: serializer.fromJson<int>(
        json['plannedDurationSecs'],
      ),
      actualFocusSecs: serializer.fromJson<int>(json['actualFocusSecs']),
      pomodoroWorkSecs: serializer.fromJson<int?>(json['pomodoroWorkSecs']),
      pomodoroBreakSecs: serializer.fromJson<int?>(json['pomodoroBreakSecs']),
      flowBreakRatio: serializer.fromJson<double?>(json['flowBreakRatio']),
      cyclesCompleted: serializer.fromJson<int>(json['cyclesCompleted']),
      status: $FocusSessionsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      runtimeStatus: serializer.fromJson<int?>(json['runtimeStatus']),
      runtimePhase: serializer.fromJson<int?>(json['runtimePhase']),
      runtimePhaseStartedAt: serializer.fromJson<DateTime?>(
        json['runtimePhaseStartedAt'],
      ),
      runtimeCarriedPhaseSecs: serializer.fromJson<int>(
        json['runtimeCarriedPhaseSecs'],
      ),
      runtimePhaseTargetSecs: serializer.fromJson<int?>(
        json['runtimePhaseTargetSecs'],
      ),
      runtimeBankedFocusSecs: serializer.fromJson<int>(
        json['runtimeBankedFocusSecs'],
      ),
      linkedCanvasId: serializer.fromJson<String?>(json['linkedCanvasId']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'goalText': serializer.toJson<String>(goalText),
      'preEnergy': serializer.toJson<int>(preEnergy),
      'postEnergy': serializer.toJson<int?>(postEnergy),
      'timerKind': serializer.toJson<int>(
        $FocusSessionsTable.$convertertimerKind.toJson(timerKind),
      ),
      'plannedDurationSecs': serializer.toJson<int>(plannedDurationSecs),
      'actualFocusSecs': serializer.toJson<int>(actualFocusSecs),
      'pomodoroWorkSecs': serializer.toJson<int?>(pomodoroWorkSecs),
      'pomodoroBreakSecs': serializer.toJson<int?>(pomodoroBreakSecs),
      'flowBreakRatio': serializer.toJson<double?>(flowBreakRatio),
      'cyclesCompleted': serializer.toJson<int>(cyclesCompleted),
      'status': serializer.toJson<int>(
        $FocusSessionsTable.$converterstatus.toJson(status),
      ),
      'runtimeStatus': serializer.toJson<int?>(runtimeStatus),
      'runtimePhase': serializer.toJson<int?>(runtimePhase),
      'runtimePhaseStartedAt': serializer.toJson<DateTime?>(
        runtimePhaseStartedAt,
      ),
      'runtimeCarriedPhaseSecs': serializer.toJson<int>(
        runtimeCarriedPhaseSecs,
      ),
      'runtimePhaseTargetSecs': serializer.toJson<int?>(runtimePhaseTargetSecs),
      'runtimeBankedFocusSecs': serializer.toJson<int>(runtimeBankedFocusSecs),
      'linkedCanvasId': serializer.toJson<String?>(linkedCanvasId),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  FocusSession copyWith({
    String? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? goalText,
    int? preEnergy,
    Value<int?> postEnergy = const Value.absent(),
    TimerKind? timerKind,
    int? plannedDurationSecs,
    int? actualFocusSecs,
    Value<int?> pomodoroWorkSecs = const Value.absent(),
    Value<int?> pomodoroBreakSecs = const Value.absent(),
    Value<double?> flowBreakRatio = const Value.absent(),
    int? cyclesCompleted,
    FocusSessionStatus? status,
    Value<int?> runtimeStatus = const Value.absent(),
    Value<int?> runtimePhase = const Value.absent(),
    Value<DateTime?> runtimePhaseStartedAt = const Value.absent(),
    int? runtimeCarriedPhaseSecs,
    Value<int?> runtimePhaseTargetSecs = const Value.absent(),
    int? runtimeBankedFocusSecs,
    Value<String?> linkedCanvasId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => FocusSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    goalText: goalText ?? this.goalText,
    preEnergy: preEnergy ?? this.preEnergy,
    postEnergy: postEnergy.present ? postEnergy.value : this.postEnergy,
    timerKind: timerKind ?? this.timerKind,
    plannedDurationSecs: plannedDurationSecs ?? this.plannedDurationSecs,
    actualFocusSecs: actualFocusSecs ?? this.actualFocusSecs,
    pomodoroWorkSecs: pomodoroWorkSecs.present
        ? pomodoroWorkSecs.value
        : this.pomodoroWorkSecs,
    pomodoroBreakSecs: pomodoroBreakSecs.present
        ? pomodoroBreakSecs.value
        : this.pomodoroBreakSecs,
    flowBreakRatio: flowBreakRatio.present
        ? flowBreakRatio.value
        : this.flowBreakRatio,
    cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
    status: status ?? this.status,
    runtimeStatus: runtimeStatus.present
        ? runtimeStatus.value
        : this.runtimeStatus,
    runtimePhase: runtimePhase.present ? runtimePhase.value : this.runtimePhase,
    runtimePhaseStartedAt: runtimePhaseStartedAt.present
        ? runtimePhaseStartedAt.value
        : this.runtimePhaseStartedAt,
    runtimeCarriedPhaseSecs:
        runtimeCarriedPhaseSecs ?? this.runtimeCarriedPhaseSecs,
    runtimePhaseTargetSecs: runtimePhaseTargetSecs.present
        ? runtimePhaseTargetSecs.value
        : this.runtimePhaseTargetSecs,
    runtimeBankedFocusSecs:
        runtimeBankedFocusSecs ?? this.runtimeBankedFocusSecs,
    linkedCanvasId: linkedCanvasId.present
        ? linkedCanvasId.value
        : this.linkedCanvasId,
    notes: notes.present ? notes.value : this.notes,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      goalText: data.goalText.present ? data.goalText.value : this.goalText,
      preEnergy: data.preEnergy.present ? data.preEnergy.value : this.preEnergy,
      postEnergy: data.postEnergy.present
          ? data.postEnergy.value
          : this.postEnergy,
      timerKind: data.timerKind.present ? data.timerKind.value : this.timerKind,
      plannedDurationSecs: data.plannedDurationSecs.present
          ? data.plannedDurationSecs.value
          : this.plannedDurationSecs,
      actualFocusSecs: data.actualFocusSecs.present
          ? data.actualFocusSecs.value
          : this.actualFocusSecs,
      pomodoroWorkSecs: data.pomodoroWorkSecs.present
          ? data.pomodoroWorkSecs.value
          : this.pomodoroWorkSecs,
      pomodoroBreakSecs: data.pomodoroBreakSecs.present
          ? data.pomodoroBreakSecs.value
          : this.pomodoroBreakSecs,
      flowBreakRatio: data.flowBreakRatio.present
          ? data.flowBreakRatio.value
          : this.flowBreakRatio,
      cyclesCompleted: data.cyclesCompleted.present
          ? data.cyclesCompleted.value
          : this.cyclesCompleted,
      status: data.status.present ? data.status.value : this.status,
      runtimeStatus: data.runtimeStatus.present
          ? data.runtimeStatus.value
          : this.runtimeStatus,
      runtimePhase: data.runtimePhase.present
          ? data.runtimePhase.value
          : this.runtimePhase,
      runtimePhaseStartedAt: data.runtimePhaseStartedAt.present
          ? data.runtimePhaseStartedAt.value
          : this.runtimePhaseStartedAt,
      runtimeCarriedPhaseSecs: data.runtimeCarriedPhaseSecs.present
          ? data.runtimeCarriedPhaseSecs.value
          : this.runtimeCarriedPhaseSecs,
      runtimePhaseTargetSecs: data.runtimePhaseTargetSecs.present
          ? data.runtimePhaseTargetSecs.value
          : this.runtimePhaseTargetSecs,
      runtimeBankedFocusSecs: data.runtimeBankedFocusSecs.present
          ? data.runtimeBankedFocusSecs.value
          : this.runtimeBankedFocusSecs,
      linkedCanvasId: data.linkedCanvasId.present
          ? data.linkedCanvasId.value
          : this.linkedCanvasId,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('goalText: $goalText, ')
          ..write('preEnergy: $preEnergy, ')
          ..write('postEnergy: $postEnergy, ')
          ..write('timerKind: $timerKind, ')
          ..write('plannedDurationSecs: $plannedDurationSecs, ')
          ..write('actualFocusSecs: $actualFocusSecs, ')
          ..write('pomodoroWorkSecs: $pomodoroWorkSecs, ')
          ..write('pomodoroBreakSecs: $pomodoroBreakSecs, ')
          ..write('flowBreakRatio: $flowBreakRatio, ')
          ..write('cyclesCompleted: $cyclesCompleted, ')
          ..write('status: $status, ')
          ..write('runtimeStatus: $runtimeStatus, ')
          ..write('runtimePhase: $runtimePhase, ')
          ..write('runtimePhaseStartedAt: $runtimePhaseStartedAt, ')
          ..write('runtimeCarriedPhaseSecs: $runtimeCarriedPhaseSecs, ')
          ..write('runtimePhaseTargetSecs: $runtimePhaseTargetSecs, ')
          ..write('runtimeBankedFocusSecs: $runtimeBankedFocusSecs, ')
          ..write('linkedCanvasId: $linkedCanvasId, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    startedAt,
    endedAt,
    goalText,
    preEnergy,
    postEnergy,
    timerKind,
    plannedDurationSecs,
    actualFocusSecs,
    pomodoroWorkSecs,
    pomodoroBreakSecs,
    flowBreakRatio,
    cyclesCompleted,
    status,
    runtimeStatus,
    runtimePhase,
    runtimePhaseStartedAt,
    runtimeCarriedPhaseSecs,
    runtimePhaseTargetSecs,
    runtimeBankedFocusSecs,
    linkedCanvasId,
    notes,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.goalText == this.goalText &&
          other.preEnergy == this.preEnergy &&
          other.postEnergy == this.postEnergy &&
          other.timerKind == this.timerKind &&
          other.plannedDurationSecs == this.plannedDurationSecs &&
          other.actualFocusSecs == this.actualFocusSecs &&
          other.pomodoroWorkSecs == this.pomodoroWorkSecs &&
          other.pomodoroBreakSecs == this.pomodoroBreakSecs &&
          other.flowBreakRatio == this.flowBreakRatio &&
          other.cyclesCompleted == this.cyclesCompleted &&
          other.status == this.status &&
          other.runtimeStatus == this.runtimeStatus &&
          other.runtimePhase == this.runtimePhase &&
          other.runtimePhaseStartedAt == this.runtimePhaseStartedAt &&
          other.runtimeCarriedPhaseSecs == this.runtimeCarriedPhaseSecs &&
          other.runtimePhaseTargetSecs == this.runtimePhaseTargetSecs &&
          other.runtimeBankedFocusSecs == this.runtimeBankedFocusSecs &&
          other.linkedCanvasId == this.linkedCanvasId &&
          other.notes == this.notes);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> goalText;
  final Value<int> preEnergy;
  final Value<int?> postEnergy;
  final Value<TimerKind> timerKind;
  final Value<int> plannedDurationSecs;
  final Value<int> actualFocusSecs;
  final Value<int?> pomodoroWorkSecs;
  final Value<int?> pomodoroBreakSecs;
  final Value<double?> flowBreakRatio;
  final Value<int> cyclesCompleted;
  final Value<FocusSessionStatus> status;
  final Value<int?> runtimeStatus;
  final Value<int?> runtimePhase;
  final Value<DateTime?> runtimePhaseStartedAt;
  final Value<int> runtimeCarriedPhaseSecs;
  final Value<int?> runtimePhaseTargetSecs;
  final Value<int> runtimeBankedFocusSecs;
  final Value<String?> linkedCanvasId;
  final Value<String?> notes;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.goalText = const Value.absent(),
    this.preEnergy = const Value.absent(),
    this.postEnergy = const Value.absent(),
    this.timerKind = const Value.absent(),
    this.plannedDurationSecs = const Value.absent(),
    this.actualFocusSecs = const Value.absent(),
    this.pomodoroWorkSecs = const Value.absent(),
    this.pomodoroBreakSecs = const Value.absent(),
    this.flowBreakRatio = const Value.absent(),
    this.cyclesCompleted = const Value.absent(),
    this.status = const Value.absent(),
    this.runtimeStatus = const Value.absent(),
    this.runtimePhase = const Value.absent(),
    this.runtimePhaseStartedAt = const Value.absent(),
    this.runtimeCarriedPhaseSecs = const Value.absent(),
    this.runtimePhaseTargetSecs = const Value.absent(),
    this.runtimeBankedFocusSecs = const Value.absent(),
    this.linkedCanvasId = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String goalText,
    required int preEnergy,
    this.postEnergy = const Value.absent(),
    required TimerKind timerKind,
    required int plannedDurationSecs,
    this.actualFocusSecs = const Value.absent(),
    this.pomodoroWorkSecs = const Value.absent(),
    this.pomodoroBreakSecs = const Value.absent(),
    this.flowBreakRatio = const Value.absent(),
    this.cyclesCompleted = const Value.absent(),
    required FocusSessionStatus status,
    this.runtimeStatus = const Value.absent(),
    this.runtimePhase = const Value.absent(),
    this.runtimePhaseStartedAt = const Value.absent(),
    this.runtimeCarriedPhaseSecs = const Value.absent(),
    this.runtimePhaseTargetSecs = const Value.absent(),
    this.runtimeBankedFocusSecs = const Value.absent(),
    this.linkedCanvasId = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       goalText = Value(goalText),
       preEnergy = Value(preEnergy),
       timerKind = Value(timerKind),
       plannedDurationSecs = Value(plannedDurationSecs),
       status = Value(status);
  static Insertable<FocusSession> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? goalText,
    Expression<int>? preEnergy,
    Expression<int>? postEnergy,
    Expression<int>? timerKind,
    Expression<int>? plannedDurationSecs,
    Expression<int>? actualFocusSecs,
    Expression<int>? pomodoroWorkSecs,
    Expression<int>? pomodoroBreakSecs,
    Expression<double>? flowBreakRatio,
    Expression<int>? cyclesCompleted,
    Expression<int>? status,
    Expression<int>? runtimeStatus,
    Expression<int>? runtimePhase,
    Expression<DateTime>? runtimePhaseStartedAt,
    Expression<int>? runtimeCarriedPhaseSecs,
    Expression<int>? runtimePhaseTargetSecs,
    Expression<int>? runtimeBankedFocusSecs,
    Expression<String>? linkedCanvasId,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (goalText != null) 'goal_text': goalText,
      if (preEnergy != null) 'pre_energy': preEnergy,
      if (postEnergy != null) 'post_energy': postEnergy,
      if (timerKind != null) 'timer_kind': timerKind,
      if (plannedDurationSecs != null)
        'planned_duration_secs': plannedDurationSecs,
      if (actualFocusSecs != null) 'actual_focus_secs': actualFocusSecs,
      if (pomodoroWorkSecs != null) 'pomodoro_work_secs': pomodoroWorkSecs,
      if (pomodoroBreakSecs != null) 'pomodoro_break_secs': pomodoroBreakSecs,
      if (flowBreakRatio != null) 'flow_break_ratio': flowBreakRatio,
      if (cyclesCompleted != null) 'cycles_completed': cyclesCompleted,
      if (status != null) 'status': status,
      if (runtimeStatus != null) 'runtime_status': runtimeStatus,
      if (runtimePhase != null) 'runtime_phase': runtimePhase,
      if (runtimePhaseStartedAt != null)
        'runtime_phase_started_at': runtimePhaseStartedAt,
      if (runtimeCarriedPhaseSecs != null)
        'runtime_carried_phase_secs': runtimeCarriedPhaseSecs,
      if (runtimePhaseTargetSecs != null)
        'runtime_phase_target_secs': runtimePhaseTargetSecs,
      if (runtimeBankedFocusSecs != null)
        'runtime_banked_focus_secs': runtimeBankedFocusSecs,
      if (linkedCanvasId != null) 'linked_canvas_id': linkedCanvasId,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? goalText,
    Value<int>? preEnergy,
    Value<int?>? postEnergy,
    Value<TimerKind>? timerKind,
    Value<int>? plannedDurationSecs,
    Value<int>? actualFocusSecs,
    Value<int?>? pomodoroWorkSecs,
    Value<int?>? pomodoroBreakSecs,
    Value<double?>? flowBreakRatio,
    Value<int>? cyclesCompleted,
    Value<FocusSessionStatus>? status,
    Value<int?>? runtimeStatus,
    Value<int?>? runtimePhase,
    Value<DateTime?>? runtimePhaseStartedAt,
    Value<int>? runtimeCarriedPhaseSecs,
    Value<int?>? runtimePhaseTargetSecs,
    Value<int>? runtimeBankedFocusSecs,
    Value<String?>? linkedCanvasId,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      goalText: goalText ?? this.goalText,
      preEnergy: preEnergy ?? this.preEnergy,
      postEnergy: postEnergy ?? this.postEnergy,
      timerKind: timerKind ?? this.timerKind,
      plannedDurationSecs: plannedDurationSecs ?? this.plannedDurationSecs,
      actualFocusSecs: actualFocusSecs ?? this.actualFocusSecs,
      pomodoroWorkSecs: pomodoroWorkSecs ?? this.pomodoroWorkSecs,
      pomodoroBreakSecs: pomodoroBreakSecs ?? this.pomodoroBreakSecs,
      flowBreakRatio: flowBreakRatio ?? this.flowBreakRatio,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      status: status ?? this.status,
      runtimeStatus: runtimeStatus ?? this.runtimeStatus,
      runtimePhase: runtimePhase ?? this.runtimePhase,
      runtimePhaseStartedAt:
          runtimePhaseStartedAt ?? this.runtimePhaseStartedAt,
      runtimeCarriedPhaseSecs:
          runtimeCarriedPhaseSecs ?? this.runtimeCarriedPhaseSecs,
      runtimePhaseTargetSecs:
          runtimePhaseTargetSecs ?? this.runtimePhaseTargetSecs,
      runtimeBankedFocusSecs:
          runtimeBankedFocusSecs ?? this.runtimeBankedFocusSecs,
      linkedCanvasId: linkedCanvasId ?? this.linkedCanvasId,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (goalText.present) {
      map['goal_text'] = Variable<String>(goalText.value);
    }
    if (preEnergy.present) {
      map['pre_energy'] = Variable<int>(preEnergy.value);
    }
    if (postEnergy.present) {
      map['post_energy'] = Variable<int>(postEnergy.value);
    }
    if (timerKind.present) {
      map['timer_kind'] = Variable<int>(
        $FocusSessionsTable.$convertertimerKind.toSql(timerKind.value),
      );
    }
    if (plannedDurationSecs.present) {
      map['planned_duration_secs'] = Variable<int>(plannedDurationSecs.value);
    }
    if (actualFocusSecs.present) {
      map['actual_focus_secs'] = Variable<int>(actualFocusSecs.value);
    }
    if (pomodoroWorkSecs.present) {
      map['pomodoro_work_secs'] = Variable<int>(pomodoroWorkSecs.value);
    }
    if (pomodoroBreakSecs.present) {
      map['pomodoro_break_secs'] = Variable<int>(pomodoroBreakSecs.value);
    }
    if (flowBreakRatio.present) {
      map['flow_break_ratio'] = Variable<double>(flowBreakRatio.value);
    }
    if (cyclesCompleted.present) {
      map['cycles_completed'] = Variable<int>(cyclesCompleted.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $FocusSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (runtimeStatus.present) {
      map['runtime_status'] = Variable<int>(runtimeStatus.value);
    }
    if (runtimePhase.present) {
      map['runtime_phase'] = Variable<int>(runtimePhase.value);
    }
    if (runtimePhaseStartedAt.present) {
      map['runtime_phase_started_at'] = Variable<DateTime>(
        runtimePhaseStartedAt.value,
      );
    }
    if (runtimeCarriedPhaseSecs.present) {
      map['runtime_carried_phase_secs'] = Variable<int>(
        runtimeCarriedPhaseSecs.value,
      );
    }
    if (runtimePhaseTargetSecs.present) {
      map['runtime_phase_target_secs'] = Variable<int>(
        runtimePhaseTargetSecs.value,
      );
    }
    if (runtimeBankedFocusSecs.present) {
      map['runtime_banked_focus_secs'] = Variable<int>(
        runtimeBankedFocusSecs.value,
      );
    }
    if (linkedCanvasId.present) {
      map['linked_canvas_id'] = Variable<String>(linkedCanvasId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('goalText: $goalText, ')
          ..write('preEnergy: $preEnergy, ')
          ..write('postEnergy: $postEnergy, ')
          ..write('timerKind: $timerKind, ')
          ..write('plannedDurationSecs: $plannedDurationSecs, ')
          ..write('actualFocusSecs: $actualFocusSecs, ')
          ..write('pomodoroWorkSecs: $pomodoroWorkSecs, ')
          ..write('pomodoroBreakSecs: $pomodoroBreakSecs, ')
          ..write('flowBreakRatio: $flowBreakRatio, ')
          ..write('cyclesCompleted: $cyclesCompleted, ')
          ..write('status: $status, ')
          ..write('runtimeStatus: $runtimeStatus, ')
          ..write('runtimePhase: $runtimePhase, ')
          ..write('runtimePhaseStartedAt: $runtimePhaseStartedAt, ')
          ..write('runtimeCarriedPhaseSecs: $runtimeCarriedPhaseSecs, ')
          ..write('runtimePhaseTargetSecs: $runtimePhaseTargetSecs, ')
          ..write('runtimeBankedFocusSecs: $runtimeBankedFocusSecs, ')
          ..write('linkedCanvasId: $linkedCanvasId, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionRitualChecksTable extends FocusSessionRitualChecks
    with TableInfo<$FocusSessionRitualChecksTable, FocusSessionRitualCheck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionRitualChecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES focus_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ritual_checklist_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemLabelSnapshotMeta = const VerificationMeta(
    'itemLabelSnapshot',
  );
  @override
  late final GeneratedColumn<String> itemLabelSnapshot =
      GeneratedColumn<String>(
        'item_label_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wasCheckedMeta = const VerificationMeta(
    'wasChecked',
  );
  @override
  late final GeneratedColumn<bool> wasChecked = GeneratedColumn<bool>(
    'was_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    itemId,
    itemLabelSnapshot,
    wasChecked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_session_ritual_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSessionRitualCheck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('item_label_snapshot')) {
      context.handle(
        _itemLabelSnapshotMeta,
        itemLabelSnapshot.isAcceptableOrUnknown(
          data['item_label_snapshot']!,
          _itemLabelSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemLabelSnapshotMeta);
    }
    if (data.containsKey('was_checked')) {
      context.handle(
        _wasCheckedMeta,
        wasChecked.isAcceptableOrUnknown(data['was_checked']!, _wasCheckedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionRitualCheck map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionRitualCheck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      itemLabelSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_label_snapshot'],
      )!,
      wasChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_checked'],
      )!,
    );
  }

  @override
  $FocusSessionRitualChecksTable createAlias(String alias) {
    return $FocusSessionRitualChecksTable(attachedDatabase, alias);
  }
}

class FocusSessionRitualCheck extends DataClass
    implements Insertable<FocusSessionRitualCheck> {
  final String id;
  final String sessionId;
  final String? itemId;

  /// The item label as it read when the session started.
  final String itemLabelSnapshot;
  final bool wasChecked;
  const FocusSessionRitualCheck({
    required this.id,
    required this.sessionId,
    this.itemId,
    required this.itemLabelSnapshot,
    required this.wasChecked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['item_label_snapshot'] = Variable<String>(itemLabelSnapshot);
    map['was_checked'] = Variable<bool>(wasChecked);
    return map;
  }

  FocusSessionRitualChecksCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionRitualChecksCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      itemLabelSnapshot: Value(itemLabelSnapshot),
      wasChecked: Value(wasChecked),
    );
  }

  factory FocusSessionRitualCheck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionRitualCheck(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      itemLabelSnapshot: serializer.fromJson<String>(json['itemLabelSnapshot']),
      wasChecked: serializer.fromJson<bool>(json['wasChecked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'itemId': serializer.toJson<String?>(itemId),
      'itemLabelSnapshot': serializer.toJson<String>(itemLabelSnapshot),
      'wasChecked': serializer.toJson<bool>(wasChecked),
    };
  }

  FocusSessionRitualCheck copyWith({
    String? id,
    String? sessionId,
    Value<String?> itemId = const Value.absent(),
    String? itemLabelSnapshot,
    bool? wasChecked,
  }) => FocusSessionRitualCheck(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    itemId: itemId.present ? itemId.value : this.itemId,
    itemLabelSnapshot: itemLabelSnapshot ?? this.itemLabelSnapshot,
    wasChecked: wasChecked ?? this.wasChecked,
  );
  FocusSessionRitualCheck copyWithCompanion(
    FocusSessionRitualChecksCompanion data,
  ) {
    return FocusSessionRitualCheck(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemLabelSnapshot: data.itemLabelSnapshot.present
          ? data.itemLabelSnapshot.value
          : this.itemLabelSnapshot,
      wasChecked: data.wasChecked.present
          ? data.wasChecked.value
          : this.wasChecked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRitualCheck(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('itemId: $itemId, ')
          ..write('itemLabelSnapshot: $itemLabelSnapshot, ')
          ..write('wasChecked: $wasChecked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, itemId, itemLabelSnapshot, wasChecked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionRitualCheck &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.itemId == this.itemId &&
          other.itemLabelSnapshot == this.itemLabelSnapshot &&
          other.wasChecked == this.wasChecked);
}

class FocusSessionRitualChecksCompanion
    extends UpdateCompanion<FocusSessionRitualCheck> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> itemId;
  final Value<String> itemLabelSnapshot;
  final Value<bool> wasChecked;
  final Value<int> rowid;
  const FocusSessionRitualChecksCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemLabelSnapshot = const Value.absent(),
    this.wasChecked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionRitualChecksCompanion.insert({
    required String id,
    required String sessionId,
    this.itemId = const Value.absent(),
    required String itemLabelSnapshot,
    this.wasChecked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       itemLabelSnapshot = Value(itemLabelSnapshot);
  static Insertable<FocusSessionRitualCheck> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? itemId,
    Expression<String>? itemLabelSnapshot,
    Expression<bool>? wasChecked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (itemId != null) 'item_id': itemId,
      if (itemLabelSnapshot != null) 'item_label_snapshot': itemLabelSnapshot,
      if (wasChecked != null) 'was_checked': wasChecked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionRitualChecksCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? itemId,
    Value<String>? itemLabelSnapshot,
    Value<bool>? wasChecked,
    Value<int>? rowid,
  }) {
    return FocusSessionRitualChecksCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemId: itemId ?? this.itemId,
      itemLabelSnapshot: itemLabelSnapshot ?? this.itemLabelSnapshot,
      wasChecked: wasChecked ?? this.wasChecked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemLabelSnapshot.present) {
      map['item_label_snapshot'] = Variable<String>(itemLabelSnapshot.value);
    }
    if (wasChecked.present) {
      map['was_checked'] = Variable<bool>(wasChecked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRitualChecksCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('itemId: $itemId, ')
          ..write('itemLabelSnapshot: $itemLabelSnapshot, ')
          ..write('wasChecked: $wasChecked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DistractionsTable extends Distractions
    with TableInfo<$DistractionsTable, Distraction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES focus_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DistractionKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DistractionKind>($DistractionsTable.$converterkind);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedSecsMeta = const VerificationMeta(
    'elapsedSecs',
  );
  @override
  late final GeneratedColumn<int> elapsedSecs = GeneratedColumn<int>(
    'elapsed_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    capturedAt,
    kind,
    note,
    elapsedSecs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distractions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Distraction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('elapsed_secs')) {
      context.handle(
        _elapsedSecsMeta,
        elapsedSecs.isAcceptableOrUnknown(
          data['elapsed_secs']!,
          _elapsedSecsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedSecsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Distraction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Distraction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      kind: $DistractionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      elapsedSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_secs'],
      )!,
    );
  }

  @override
  $DistractionsTable createAlias(String alias) {
    return $DistractionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DistractionKind, int, int> $converterkind =
      const EnumIndexConverter<DistractionKind>(DistractionKind.values);
}

class Distraction extends DataClass implements Insertable<Distraction> {
  final String id;
  final String sessionId;
  final DateTime capturedAt;
  final DistractionKind kind;
  final String note;

  /// Seconds into the session — feeds "when do I drift" analysis.
  final int elapsedSecs;
  const Distraction({
    required this.id,
    required this.sessionId,
    required this.capturedAt,
    required this.kind,
    required this.note,
    required this.elapsedSecs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    {
      map['kind'] = Variable<int>(
        $DistractionsTable.$converterkind.toSql(kind),
      );
    }
    map['note'] = Variable<String>(note);
    map['elapsed_secs'] = Variable<int>(elapsedSecs);
    return map;
  }

  DistractionsCompanion toCompanion(bool nullToAbsent) {
    return DistractionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      capturedAt: Value(capturedAt),
      kind: Value(kind),
      note: Value(note),
      elapsedSecs: Value(elapsedSecs),
    );
  }

  factory Distraction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Distraction(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      kind: $DistractionsTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      note: serializer.fromJson<String>(json['note']),
      elapsedSecs: serializer.fromJson<int>(json['elapsedSecs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'kind': serializer.toJson<int>(
        $DistractionsTable.$converterkind.toJson(kind),
      ),
      'note': serializer.toJson<String>(note),
      'elapsedSecs': serializer.toJson<int>(elapsedSecs),
    };
  }

  Distraction copyWith({
    String? id,
    String? sessionId,
    DateTime? capturedAt,
    DistractionKind? kind,
    String? note,
    int? elapsedSecs,
  }) => Distraction(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    capturedAt: capturedAt ?? this.capturedAt,
    kind: kind ?? this.kind,
    note: note ?? this.note,
    elapsedSecs: elapsedSecs ?? this.elapsedSecs,
  );
  Distraction copyWithCompanion(DistractionsCompanion data) {
    return Distraction(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      note: data.note.present ? data.note.value : this.note,
      elapsedSecs: data.elapsedSecs.present
          ? data.elapsedSecs.value
          : this.elapsedSecs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Distraction(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('kind: $kind, ')
          ..write('note: $note, ')
          ..write('elapsedSecs: $elapsedSecs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, capturedAt, kind, note, elapsedSecs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Distraction &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.capturedAt == this.capturedAt &&
          other.kind == this.kind &&
          other.note == this.note &&
          other.elapsedSecs == this.elapsedSecs);
}

class DistractionsCompanion extends UpdateCompanion<Distraction> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<DateTime> capturedAt;
  final Value<DistractionKind> kind;
  final Value<String> note;
  final Value<int> elapsedSecs;
  final Value<int> rowid;
  const DistractionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.note = const Value.absent(),
    this.elapsedSecs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistractionsCompanion.insert({
    required String id,
    required String sessionId,
    required DateTime capturedAt,
    required DistractionKind kind,
    required String note,
    required int elapsedSecs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       capturedAt = Value(capturedAt),
       kind = Value(kind),
       note = Value(note),
       elapsedSecs = Value(elapsedSecs);
  static Insertable<Distraction> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<DateTime>? capturedAt,
    Expression<int>? kind,
    Expression<String>? note,
    Expression<int>? elapsedSecs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (kind != null) 'kind': kind,
      if (note != null) 'note': note,
      if (elapsedSecs != null) 'elapsed_secs': elapsedSecs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistractionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<DateTime>? capturedAt,
    Value<DistractionKind>? kind,
    Value<String>? note,
    Value<int>? elapsedSecs,
    Value<int>? rowid,
  }) {
    return DistractionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      capturedAt: capturedAt ?? this.capturedAt,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      elapsedSecs: elapsedSecs ?? this.elapsedSecs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $DistractionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (elapsedSecs.present) {
      map['elapsed_secs'] = Variable<int>(elapsedSecs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistractionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('kind: $kind, ')
          ..write('note: $note, ')
          ..write('elapsedSecs: $elapsedSecs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardsTable extends Boards with TableInfo<$BoardsTable, Board> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BoardType, int> boardType =
      GeneratedColumn<int>(
        'board_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<BoardType>($BoardsTable.$converterboardType);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, boardType, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Board> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Board map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Board(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardType: $BoardsTable.$converterboardType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}board_type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BoardsTable createAlias(String alias) {
    return $BoardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BoardType, int, int> $converterboardType =
      const EnumIndexConverter<BoardType>(BoardType.values);
}

class Board extends DataClass implements Insertable<Board> {
  final String id;
  final BoardType boardType;
  final String name;
  final DateTime createdAt;
  const Board({
    required this.id,
    required this.boardType,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['board_type'] = Variable<int>(
        $BoardsTable.$converterboardType.toSql(boardType),
      );
    }
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BoardsCompanion toCompanion(bool nullToAbsent) {
    return BoardsCompanion(
      id: Value(id),
      boardType: Value(boardType),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Board.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Board(
      id: serializer.fromJson<String>(json['id']),
      boardType: $BoardsTable.$converterboardType.fromJson(
        serializer.fromJson<int>(json['boardType']),
      ),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardType': serializer.toJson<int>(
        $BoardsTable.$converterboardType.toJson(boardType),
      ),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Board copyWith({
    String? id,
    BoardType? boardType,
    String? name,
    DateTime? createdAt,
  }) => Board(
    id: id ?? this.id,
    boardType: boardType ?? this.boardType,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Board copyWithCompanion(BoardsCompanion data) {
    return Board(
      id: data.id.present ? data.id.value : this.id,
      boardType: data.boardType.present ? data.boardType.value : this.boardType,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Board(')
          ..write('id: $id, ')
          ..write('boardType: $boardType, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, boardType, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Board &&
          other.id == this.id &&
          other.boardType == this.boardType &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class BoardsCompanion extends UpdateCompanion<Board> {
  final Value<String> id;
  final Value<BoardType> boardType;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BoardsCompanion({
    this.id = const Value.absent(),
    this.boardType = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardsCompanion.insert({
    required String id,
    required BoardType boardType,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boardType = Value(boardType),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Board> custom({
    Expression<String>? id,
    Expression<int>? boardType,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardType != null) 'board_type': boardType,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardsCompanion copyWith({
    Value<String>? id,
    Value<BoardType>? boardType,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BoardsCompanion(
      id: id ?? this.id,
      boardType: boardType ?? this.boardType,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardType.present) {
      map['board_type'] = Variable<int>(
        $BoardsTable.$converterboardType.toSql(boardType.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardsCompanion(')
          ..write('id: $id, ')
          ..write('boardType: $boardType, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardColumnsTable extends BoardColumns
    with TableInfo<$BoardColumnsTable, BoardColumn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardColumnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wipLimitMeta = const VerificationMeta(
    'wipLimit',
  );
  @override
  late final GeneratedColumn<int> wipLimit = GeneratedColumn<int>(
    'wip_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boardId,
    name,
    position,
    color,
    wipLimit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_columns';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardColumn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('wip_limit')) {
      context.handle(
        _wipLimitMeta,
        wipLimit.isAcceptableOrUnknown(data['wip_limit']!, _wipLimitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardColumn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardColumn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      wipLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wip_limit'],
      ),
    );
  }

  @override
  $BoardColumnsTable createAlias(String alias) {
    return $BoardColumnsTable(attachedDatabase, alias);
  }
}

class BoardColumn extends DataClass implements Insertable<BoardColumn> {
  final String id;
  final String boardId;
  final String name;

  /// Fractional ordering position.
  final double position;

  /// Optional ARGB colour for the column header.
  final int? color;
  final int? wipLimit;
  const BoardColumn({
    required this.id,
    required this.boardId,
    required this.name,
    required this.position,
    this.color,
    this.wipLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['board_id'] = Variable<String>(boardId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<double>(position);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || wipLimit != null) {
      map['wip_limit'] = Variable<int>(wipLimit);
    }
    return map;
  }

  BoardColumnsCompanion toCompanion(bool nullToAbsent) {
    return BoardColumnsCompanion(
      id: Value(id),
      boardId: Value(boardId),
      name: Value(name),
      position: Value(position),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      wipLimit: wipLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(wipLimit),
    );
  }

  factory BoardColumn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardColumn(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String>(json['boardId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<double>(json['position']),
      color: serializer.fromJson<int?>(json['color']),
      wipLimit: serializer.fromJson<int?>(json['wipLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String>(boardId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<double>(position),
      'color': serializer.toJson<int?>(color),
      'wipLimit': serializer.toJson<int?>(wipLimit),
    };
  }

  BoardColumn copyWith({
    String? id,
    String? boardId,
    String? name,
    double? position,
    Value<int?> color = const Value.absent(),
    Value<int?> wipLimit = const Value.absent(),
  }) => BoardColumn(
    id: id ?? this.id,
    boardId: boardId ?? this.boardId,
    name: name ?? this.name,
    position: position ?? this.position,
    color: color.present ? color.value : this.color,
    wipLimit: wipLimit.present ? wipLimit.value : this.wipLimit,
  );
  BoardColumn copyWithCompanion(BoardColumnsCompanion data) {
    return BoardColumn(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      color: data.color.present ? data.color.value : this.color,
      wipLimit: data.wipLimit.present ? data.wipLimit.value : this.wipLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardColumn(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('wipLimit: $wipLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, boardId, name, position, color, wipLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardColumn &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.name == this.name &&
          other.position == this.position &&
          other.color == this.color &&
          other.wipLimit == this.wipLimit);
}

class BoardColumnsCompanion extends UpdateCompanion<BoardColumn> {
  final Value<String> id;
  final Value<String> boardId;
  final Value<String> name;
  final Value<double> position;
  final Value<int?> color;
  final Value<int?> wipLimit;
  final Value<int> rowid;
  const BoardColumnsCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.wipLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardColumnsCompanion.insert({
    required String id,
    required String boardId,
    required String name,
    required double position,
    this.color = const Value.absent(),
    this.wipLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boardId = Value(boardId),
       name = Value(name),
       position = Value(position);
  static Insertable<BoardColumn> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<String>? name,
    Expression<double>? position,
    Expression<int>? color,
    Expression<int>? wipLimit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (color != null) 'color': color,
      if (wipLimit != null) 'wip_limit': wipLimit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardColumnsCompanion copyWith({
    Value<String>? id,
    Value<String>? boardId,
    Value<String>? name,
    Value<double>? position,
    Value<int?>? color,
    Value<int?>? wipLimit,
    Value<int>? rowid,
  }) {
    return BoardColumnsCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color ?? this.color,
      wipLimit: wipLimit ?? this.wipLimit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (wipLimit.present) {
      map['wip_limit'] = Variable<int>(wipLimit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardColumnsCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('wipLimit: $wipLimit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardCardsTable extends BoardCards
    with TableInfo<$BoardCardsTable, BoardCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnIdMeta = const VerificationMeta(
    'columnId',
  );
  @override
  late final GeneratedColumn<String> columnId = GeneratedColumn<String>(
    'column_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES board_columns (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    columnId,
    boardId,
    title,
    subtitle,
    position,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('column_id')) {
      context.handle(
        _columnIdMeta,
        columnId.isAcceptableOrUnknown(data['column_id']!, _columnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_columnIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      columnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BoardCardsTable createAlias(String alias) {
    return $BoardCardsTable(attachedDatabase, alias);
  }
}

class BoardCard extends DataClass implements Insertable<BoardCard> {
  final String id;
  final String columnId;
  final String boardId;
  final String title;
  final String? subtitle;

  /// Fractional ordering position within the column.
  final double position;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BoardCard({
    required this.id,
    required this.columnId,
    required this.boardId,
    required this.title,
    this.subtitle,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['column_id'] = Variable<String>(columnId);
    map['board_id'] = Variable<String>(boardId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['position'] = Variable<double>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BoardCardsCompanion toCompanion(bool nullToAbsent) {
    return BoardCardsCompanion(
      id: Value(id),
      columnId: Value(columnId),
      boardId: Value(boardId),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BoardCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardCard(
      id: serializer.fromJson<String>(json['id']),
      columnId: serializer.fromJson<String>(json['columnId']),
      boardId: serializer.fromJson<String>(json['boardId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      position: serializer.fromJson<double>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'columnId': serializer.toJson<String>(columnId),
      'boardId': serializer.toJson<String>(boardId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'position': serializer.toJson<double>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BoardCard copyWith({
    String? id,
    String? columnId,
    String? boardId,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    double? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BoardCard(
    id: id ?? this.id,
    columnId: columnId ?? this.columnId,
    boardId: boardId ?? this.boardId,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BoardCard copyWithCompanion(BoardCardsCompanion data) {
    return BoardCard(
      id: data.id.present ? data.id.value : this.id,
      columnId: data.columnId.present ? data.columnId.value : this.columnId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardCard(')
          ..write('id: $id, ')
          ..write('columnId: $columnId, ')
          ..write('boardId: $boardId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    columnId,
    boardId,
    title,
    subtitle,
    position,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardCard &&
          other.id == this.id &&
          other.columnId == this.columnId &&
          other.boardId == this.boardId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BoardCardsCompanion extends UpdateCompanion<BoardCard> {
  final Value<String> id;
  final Value<String> columnId;
  final Value<String> boardId;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<double> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BoardCardsCompanion({
    this.id = const Value.absent(),
    this.columnId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardCardsCompanion.insert({
    required String id,
    required String columnId,
    required String boardId,
    required String title,
    this.subtitle = const Value.absent(),
    required double position,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       columnId = Value(columnId),
       boardId = Value(boardId),
       title = Value(title),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BoardCard> custom({
    Expression<String>? id,
    Expression<String>? columnId,
    Expression<String>? boardId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<double>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (columnId != null) 'column_id': columnId,
      if (boardId != null) 'board_id': boardId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? columnId,
    Value<String>? boardId,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<double>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BoardCardsCompanion(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (columnId.present) {
      map['column_id'] = Variable<String>(columnId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardCardsCompanion(')
          ..write('id: $id, ')
          ..write('columnId: $columnId, ')
          ..write('boardId: $boardId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionCardDetailsTable extends RevisionCardDetails
    with TableInfo<$RevisionCardDetailsTable, RevisionCardDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionCardDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES board_cards (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MasteryFlag, int> masteryFlag =
      GeneratedColumn<int>(
        'mastery_flag',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MasteryFlag>(
        $RevisionCardDetailsTable.$convertermasteryFlag,
      );
  static const VerificationMeta _lastRevisedAtMeta = const VerificationMeta(
    'lastRevisedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRevisedAt =
      GeneratedColumn<DateTime>(
        'last_revised_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _revisionCountMeta = const VerificationMeta(
    'revisionCount',
  );
  @override
  late final GeneratedColumn<int> revisionCount = GeneratedColumn<int>(
    'revision_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    masteryFlag,
    lastRevisedAt,
    revisionCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_card_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionCardDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('last_revised_at')) {
      context.handle(
        _lastRevisedAtMeta,
        lastRevisedAt.isAcceptableOrUnknown(
          data['last_revised_at']!,
          _lastRevisedAtMeta,
        ),
      );
    }
    if (data.containsKey('revision_count')) {
      context.handle(
        _revisionCountMeta,
        revisionCount.isAcceptableOrUnknown(
          data['revision_count']!,
          _revisionCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  RevisionCardDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionCardDetail(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      masteryFlag: $RevisionCardDetailsTable.$convertermasteryFlag.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}mastery_flag'],
        )!,
      ),
      lastRevisedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_revised_at'],
      ),
      revisionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_count'],
      )!,
    );
  }

  @override
  $RevisionCardDetailsTable createAlias(String alias) {
    return $RevisionCardDetailsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MasteryFlag, int, int> $convertermasteryFlag =
      const EnumIndexConverter<MasteryFlag>(MasteryFlag.values);
}

class RevisionCardDetail extends DataClass
    implements Insertable<RevisionCardDetail> {
  final String cardId;
  final MasteryFlag masteryFlag;
  final DateTime? lastRevisedAt;
  final int revisionCount;
  const RevisionCardDetail({
    required this.cardId,
    required this.masteryFlag,
    this.lastRevisedAt,
    required this.revisionCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    {
      map['mastery_flag'] = Variable<int>(
        $RevisionCardDetailsTable.$convertermasteryFlag.toSql(masteryFlag),
      );
    }
    if (!nullToAbsent || lastRevisedAt != null) {
      map['last_revised_at'] = Variable<DateTime>(lastRevisedAt);
    }
    map['revision_count'] = Variable<int>(revisionCount);
    return map;
  }

  RevisionCardDetailsCompanion toCompanion(bool nullToAbsent) {
    return RevisionCardDetailsCompanion(
      cardId: Value(cardId),
      masteryFlag: Value(masteryFlag),
      lastRevisedAt: lastRevisedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRevisedAt),
      revisionCount: Value(revisionCount),
    );
  }

  factory RevisionCardDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionCardDetail(
      cardId: serializer.fromJson<String>(json['cardId']),
      masteryFlag: $RevisionCardDetailsTable.$convertermasteryFlag.fromJson(
        serializer.fromJson<int>(json['masteryFlag']),
      ),
      lastRevisedAt: serializer.fromJson<DateTime?>(json['lastRevisedAt']),
      revisionCount: serializer.fromJson<int>(json['revisionCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'masteryFlag': serializer.toJson<int>(
        $RevisionCardDetailsTable.$convertermasteryFlag.toJson(masteryFlag),
      ),
      'lastRevisedAt': serializer.toJson<DateTime?>(lastRevisedAt),
      'revisionCount': serializer.toJson<int>(revisionCount),
    };
  }

  RevisionCardDetail copyWith({
    String? cardId,
    MasteryFlag? masteryFlag,
    Value<DateTime?> lastRevisedAt = const Value.absent(),
    int? revisionCount,
  }) => RevisionCardDetail(
    cardId: cardId ?? this.cardId,
    masteryFlag: masteryFlag ?? this.masteryFlag,
    lastRevisedAt: lastRevisedAt.present
        ? lastRevisedAt.value
        : this.lastRevisedAt,
    revisionCount: revisionCount ?? this.revisionCount,
  );
  RevisionCardDetail copyWithCompanion(RevisionCardDetailsCompanion data) {
    return RevisionCardDetail(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      masteryFlag: data.masteryFlag.present
          ? data.masteryFlag.value
          : this.masteryFlag,
      lastRevisedAt: data.lastRevisedAt.present
          ? data.lastRevisedAt.value
          : this.lastRevisedAt,
      revisionCount: data.revisionCount.present
          ? data.revisionCount.value
          : this.revisionCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionCardDetail(')
          ..write('cardId: $cardId, ')
          ..write('masteryFlag: $masteryFlag, ')
          ..write('lastRevisedAt: $lastRevisedAt, ')
          ..write('revisionCount: $revisionCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cardId, masteryFlag, lastRevisedAt, revisionCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionCardDetail &&
          other.cardId == this.cardId &&
          other.masteryFlag == this.masteryFlag &&
          other.lastRevisedAt == this.lastRevisedAt &&
          other.revisionCount == this.revisionCount);
}

class RevisionCardDetailsCompanion extends UpdateCompanion<RevisionCardDetail> {
  final Value<String> cardId;
  final Value<MasteryFlag> masteryFlag;
  final Value<DateTime?> lastRevisedAt;
  final Value<int> revisionCount;
  final Value<int> rowid;
  const RevisionCardDetailsCompanion({
    this.cardId = const Value.absent(),
    this.masteryFlag = const Value.absent(),
    this.lastRevisedAt = const Value.absent(),
    this.revisionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionCardDetailsCompanion.insert({
    required String cardId,
    required MasteryFlag masteryFlag,
    this.lastRevisedAt = const Value.absent(),
    this.revisionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       masteryFlag = Value(masteryFlag);
  static Insertable<RevisionCardDetail> custom({
    Expression<String>? cardId,
    Expression<int>? masteryFlag,
    Expression<DateTime>? lastRevisedAt,
    Expression<int>? revisionCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (masteryFlag != null) 'mastery_flag': masteryFlag,
      if (lastRevisedAt != null) 'last_revised_at': lastRevisedAt,
      if (revisionCount != null) 'revision_count': revisionCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionCardDetailsCompanion copyWith({
    Value<String>? cardId,
    Value<MasteryFlag>? masteryFlag,
    Value<DateTime?>? lastRevisedAt,
    Value<int>? revisionCount,
    Value<int>? rowid,
  }) {
    return RevisionCardDetailsCompanion(
      cardId: cardId ?? this.cardId,
      masteryFlag: masteryFlag ?? this.masteryFlag,
      lastRevisedAt: lastRevisedAt ?? this.lastRevisedAt,
      revisionCount: revisionCount ?? this.revisionCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (masteryFlag.present) {
      map['mastery_flag'] = Variable<int>(
        $RevisionCardDetailsTable.$convertermasteryFlag.toSql(
          masteryFlag.value,
        ),
      );
    }
    if (lastRevisedAt.present) {
      map['last_revised_at'] = Variable<DateTime>(lastRevisedAt.value);
    }
    if (revisionCount.present) {
      map['revision_count'] = Variable<int>(revisionCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionCardDetailsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('masteryFlag: $masteryFlag, ')
          ..write('lastRevisedAt: $lastRevisedAt, ')
          ..write('revisionCount: $revisionCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalCardDetailsTable extends GoalCardDetails
    with TableInfo<$GoalCardDetailsTable, GoalCardDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalCardDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES board_cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusNoteMeta = const VerificationMeta(
    'statusNote',
  );
  @override
  late final GeneratedColumn<String> statusNote = GeneratedColumn<String>(
    'status_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [cardId, targetDate, statusNote];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_card_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalCardDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('status_note')) {
      context.handle(
        _statusNoteMeta,
        statusNote.isAcceptableOrUnknown(data['status_note']!, _statusNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  GoalCardDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalCardDetail(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      statusNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_note'],
      ),
    );
  }

  @override
  $GoalCardDetailsTable createAlias(String alias) {
    return $GoalCardDetailsTable(attachedDatabase, alias);
  }
}

class GoalCardDetail extends DataClass implements Insertable<GoalCardDetail> {
  final String cardId;
  final DateTime? targetDate;
  final String? statusNote;
  const GoalCardDetail({
    required this.cardId,
    this.targetDate,
    this.statusNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || statusNote != null) {
      map['status_note'] = Variable<String>(statusNote);
    }
    return map;
  }

  GoalCardDetailsCompanion toCompanion(bool nullToAbsent) {
    return GoalCardDetailsCompanion(
      cardId: Value(cardId),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      statusNote: statusNote == null && nullToAbsent
          ? const Value.absent()
          : Value(statusNote),
    );
  }

  factory GoalCardDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalCardDetail(
      cardId: serializer.fromJson<String>(json['cardId']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      statusNote: serializer.fromJson<String?>(json['statusNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'statusNote': serializer.toJson<String?>(statusNote),
    };
  }

  GoalCardDetail copyWith({
    String? cardId,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<String?> statusNote = const Value.absent(),
  }) => GoalCardDetail(
    cardId: cardId ?? this.cardId,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    statusNote: statusNote.present ? statusNote.value : this.statusNote,
  );
  GoalCardDetail copyWithCompanion(GoalCardDetailsCompanion data) {
    return GoalCardDetail(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      statusNote: data.statusNote.present
          ? data.statusNote.value
          : this.statusNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalCardDetail(')
          ..write('cardId: $cardId, ')
          ..write('targetDate: $targetDate, ')
          ..write('statusNote: $statusNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cardId, targetDate, statusNote);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalCardDetail &&
          other.cardId == this.cardId &&
          other.targetDate == this.targetDate &&
          other.statusNote == this.statusNote);
}

class GoalCardDetailsCompanion extends UpdateCompanion<GoalCardDetail> {
  final Value<String> cardId;
  final Value<DateTime?> targetDate;
  final Value<String?> statusNote;
  final Value<int> rowid;
  const GoalCardDetailsCompanion({
    this.cardId = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.statusNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalCardDetailsCompanion.insert({
    required String cardId,
    this.targetDate = const Value.absent(),
    this.statusNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId);
  static Insertable<GoalCardDetail> custom({
    Expression<String>? cardId,
    Expression<DateTime>? targetDate,
    Expression<String>? statusNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (targetDate != null) 'target_date': targetDate,
      if (statusNote != null) 'status_note': statusNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalCardDetailsCompanion copyWith({
    Value<String>? cardId,
    Value<DateTime?>? targetDate,
    Value<String?>? statusNote,
    Value<int>? rowid,
  }) {
    return GoalCardDetailsCompanion(
      cardId: cardId ?? this.cardId,
      targetDate: targetDate ?? this.targetDate,
      statusNote: statusNote ?? this.statusNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (statusNote.present) {
      map['status_note'] = Variable<String>(statusNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalCardDetailsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('targetDate: $targetDate, ')
          ..write('statusNote: $statusNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionTemplatesTable extends ReflectionTemplates
    with TableInfo<$ReflectionTemplatesTable, ReflectionTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _schemaJsonMeta = const VerificationMeta(
    'schemaJson',
  );
  @override
  late final GeneratedColumn<String> schemaJson = GeneratedColumn<String>(
    'schema_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    isBuiltin,
    schemaJson,
    createdAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflection_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReflectionTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    if (data.containsKey('schema_json')) {
      context.handle(
        _schemaJsonMeta,
        schemaJson.isAcceptableOrUnknown(data['schema_json']!, _schemaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_schemaJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReflectionTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReflectionTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      schemaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ReflectionTemplatesTable createAlias(String alias) {
    return $ReflectionTemplatesTable(attachedDatabase, alias);
  }
}

class ReflectionTemplate extends DataClass
    implements Insertable<ReflectionTemplate> {
  final String id;
  final String name;
  final String? description;
  final bool isBuiltin;

  /// Ordered prompt list as JSON: `[{key, label, hint, multiline}]`.
  final String schemaJson;
  final DateTime createdAt;

  /// Fractional ordering position.
  final double position;
  const ReflectionTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.isBuiltin,
    required this.schemaJson,
    required this.createdAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['schema_json'] = Variable<String>(schemaJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['position'] = Variable<double>(position);
    return map;
  }

  ReflectionTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ReflectionTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isBuiltin: Value(isBuiltin),
      schemaJson: Value(schemaJson),
      createdAt: Value(createdAt),
      position: Value(position),
    );
  }

  factory ReflectionTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReflectionTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      schemaJson: serializer.fromJson<String>(json['schemaJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      position: serializer.fromJson<double>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'schemaJson': serializer.toJson<String>(schemaJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'position': serializer.toJson<double>(position),
    };
  }

  ReflectionTemplate copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isBuiltin,
    String? schemaJson,
    DateTime? createdAt,
    double? position,
  }) => ReflectionTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    schemaJson: schemaJson ?? this.schemaJson,
    createdAt: createdAt ?? this.createdAt,
    position: position ?? this.position,
  );
  ReflectionTemplate copyWithCompanion(ReflectionTemplatesCompanion data) {
    return ReflectionTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      schemaJson: data.schemaJson.present
          ? data.schemaJson.value
          : this.schemaJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    isBuiltin,
    schemaJson,
    createdAt,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReflectionTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isBuiltin == this.isBuiltin &&
          other.schemaJson == this.schemaJson &&
          other.createdAt == this.createdAt &&
          other.position == this.position);
}

class ReflectionTemplatesCompanion extends UpdateCompanion<ReflectionTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isBuiltin;
  final Value<String> schemaJson;
  final Value<DateTime> createdAt;
  final Value<double> position;
  final Value<int> rowid;
  const ReflectionTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.schemaJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionTemplatesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    required String schemaJson,
    required DateTime createdAt,
    required double position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       schemaJson = Value(schemaJson),
       createdAt = Value(createdAt),
       position = Value(position);
  static Insertable<ReflectionTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isBuiltin,
    Expression<String>? schemaJson,
    Expression<DateTime>? createdAt,
    Expression<double>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (schemaJson != null) 'schema_json': schemaJson,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isBuiltin,
    Value<String>? schemaJson,
    Value<DateTime>? createdAt,
    Value<double>? position,
    Value<int>? rowid,
  }) {
    return ReflectionTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      schemaJson: schemaJson ?? this.schemaJson,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (schemaJson.present) {
      map['schema_json'] = Variable<String>(schemaJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionEntriesTable extends ReflectionEntries
    with TableInfo<$ReflectionEntriesTable, ReflectionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES board_cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reflection_templates (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _templateNameSnapshotMeta =
      const VerificationMeta('templateNameSnapshot');
  @override
  late final GeneratedColumn<String> templateNameSnapshot =
      GeneratedColumn<String>(
        'template_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _templateSchemaSnapshotJsonMeta =
      const VerificationMeta('templateSchemaSnapshotJson');
  @override
  late final GeneratedColumn<String> templateSchemaSnapshotJson =
      GeneratedColumn<String>(
        'template_schema_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    templateId,
    templateNameSnapshot,
    templateSchemaSnapshotJson,
    answersJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflection_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReflectionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('template_name_snapshot')) {
      context.handle(
        _templateNameSnapshotMeta,
        templateNameSnapshot.isAcceptableOrUnknown(
          data['template_name_snapshot']!,
          _templateNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateNameSnapshotMeta);
    }
    if (data.containsKey('template_schema_snapshot_json')) {
      context.handle(
        _templateSchemaSnapshotJsonMeta,
        templateSchemaSnapshotJson.isAcceptableOrUnknown(
          data['template_schema_snapshot_json']!,
          _templateSchemaSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateSchemaSnapshotJsonMeta);
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReflectionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReflectionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name_snapshot'],
      )!,
      templateSchemaSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_schema_snapshot_json'],
      )!,
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReflectionEntriesTable createAlias(String alias) {
    return $ReflectionEntriesTable(attachedDatabase, alias);
  }
}

class ReflectionEntry extends DataClass implements Insertable<ReflectionEntry> {
  final String id;
  final String cardId;

  /// Restrict deletion of a template while filled entries reference it.
  final String templateId;

  /// The template name as it read when this entry was created.
  final String templateNameSnapshot;

  /// The template schema JSON as it was when this entry was created.
  final String templateSchemaSnapshotJson;

  /// Answers as JSON: `{promptKey: text}`.
  final String answersJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReflectionEntry({
    required this.id,
    required this.cardId,
    required this.templateId,
    required this.templateNameSnapshot,
    required this.templateSchemaSnapshotJson,
    required this.answersJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['template_id'] = Variable<String>(templateId);
    map['template_name_snapshot'] = Variable<String>(templateNameSnapshot);
    map['template_schema_snapshot_json'] = Variable<String>(
      templateSchemaSnapshotJson,
    );
    map['answers_json'] = Variable<String>(answersJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReflectionEntriesCompanion toCompanion(bool nullToAbsent) {
    return ReflectionEntriesCompanion(
      id: Value(id),
      cardId: Value(cardId),
      templateId: Value(templateId),
      templateNameSnapshot: Value(templateNameSnapshot),
      templateSchemaSnapshotJson: Value(templateSchemaSnapshotJson),
      answersJson: Value(answersJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReflectionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReflectionEntry(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateNameSnapshot: serializer.fromJson<String>(
        json['templateNameSnapshot'],
      ),
      templateSchemaSnapshotJson: serializer.fromJson<String>(
        json['templateSchemaSnapshotJson'],
      ),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'templateId': serializer.toJson<String>(templateId),
      'templateNameSnapshot': serializer.toJson<String>(templateNameSnapshot),
      'templateSchemaSnapshotJson': serializer.toJson<String>(
        templateSchemaSnapshotJson,
      ),
      'answersJson': serializer.toJson<String>(answersJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReflectionEntry copyWith({
    String? id,
    String? cardId,
    String? templateId,
    String? templateNameSnapshot,
    String? templateSchemaSnapshotJson,
    String? answersJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReflectionEntry(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    templateId: templateId ?? this.templateId,
    templateNameSnapshot: templateNameSnapshot ?? this.templateNameSnapshot,
    templateSchemaSnapshotJson:
        templateSchemaSnapshotJson ?? this.templateSchemaSnapshotJson,
    answersJson: answersJson ?? this.answersJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReflectionEntry copyWithCompanion(ReflectionEntriesCompanion data) {
    return ReflectionEntry(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateNameSnapshot: data.templateNameSnapshot.present
          ? data.templateNameSnapshot.value
          : this.templateNameSnapshot,
      templateSchemaSnapshotJson: data.templateSchemaSnapshotJson.present
          ? data.templateSchemaSnapshotJson.value
          : this.templateSchemaSnapshotJson,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionEntry(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('templateId: $templateId, ')
          ..write('templateNameSnapshot: $templateNameSnapshot, ')
          ..write('templateSchemaSnapshotJson: $templateSchemaSnapshotJson, ')
          ..write('answersJson: $answersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    templateId,
    templateNameSnapshot,
    templateSchemaSnapshotJson,
    answersJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReflectionEntry &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.templateId == this.templateId &&
          other.templateNameSnapshot == this.templateNameSnapshot &&
          other.templateSchemaSnapshotJson == this.templateSchemaSnapshotJson &&
          other.answersJson == this.answersJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReflectionEntriesCompanion extends UpdateCompanion<ReflectionEntry> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<String> templateId;
  final Value<String> templateNameSnapshot;
  final Value<String> templateSchemaSnapshotJson;
  final Value<String> answersJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReflectionEntriesCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateNameSnapshot = const Value.absent(),
    this.templateSchemaSnapshotJson = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionEntriesCompanion.insert({
    required String id,
    required String cardId,
    required String templateId,
    required String templateNameSnapshot,
    required String templateSchemaSnapshotJson,
    required String answersJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       templateId = Value(templateId),
       templateNameSnapshot = Value(templateNameSnapshot),
       templateSchemaSnapshotJson = Value(templateSchemaSnapshotJson),
       answersJson = Value(answersJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReflectionEntry> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<String>? templateId,
    Expression<String>? templateNameSnapshot,
    Expression<String>? templateSchemaSnapshotJson,
    Expression<String>? answersJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (templateId != null) 'template_id': templateId,
      if (templateNameSnapshot != null)
        'template_name_snapshot': templateNameSnapshot,
      if (templateSchemaSnapshotJson != null)
        'template_schema_snapshot_json': templateSchemaSnapshotJson,
      if (answersJson != null) 'answers_json': answersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<String>? templateId,
    Value<String>? templateNameSnapshot,
    Value<String>? templateSchemaSnapshotJson,
    Value<String>? answersJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReflectionEntriesCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      templateId: templateId ?? this.templateId,
      templateNameSnapshot: templateNameSnapshot ?? this.templateNameSnapshot,
      templateSchemaSnapshotJson:
          templateSchemaSnapshotJson ?? this.templateSchemaSnapshotJson,
      answersJson: answersJson ?? this.answersJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateNameSnapshot.present) {
      map['template_name_snapshot'] = Variable<String>(
        templateNameSnapshot.value,
      );
    }
    if (templateSchemaSnapshotJson.present) {
      map['template_schema_snapshot_json'] = Variable<String>(
        templateSchemaSnapshotJson.value,
      );
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('templateId: $templateId, ')
          ..write('templateNameSnapshot: $templateNameSnapshot, ')
          ..write('templateSchemaSnapshotJson: $templateSchemaSnapshotJson, ')
          ..write('answersJson: $answersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ThemeModeSetting, int> themeMode =
      GeneratedColumn<int>(
        'theme_mode',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ThemeModeSetting>($AppSettingsTable.$converterthemeMode);
  static const VerificationMeta _defaultPomodoroWorkSecsMeta =
      const VerificationMeta('defaultPomodoroWorkSecs');
  @override
  late final GeneratedColumn<int> defaultPomodoroWorkSecs =
      GeneratedColumn<int>(
        'default_pomodoro_work_secs',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1500),
      );
  static const VerificationMeta _defaultPomodoroBreakSecsMeta =
      const VerificationMeta('defaultPomodoroBreakSecs');
  @override
  late final GeneratedColumn<int> defaultPomodoroBreakSecs =
      GeneratedColumn<int>(
        'default_pomodoro_break_secs',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(300),
      );
  static const VerificationMeta _defaultFlowBreakRatioMeta =
      const VerificationMeta('defaultFlowBreakRatio');
  @override
  late final GeneratedColumn<double> defaultFlowBreakRatio =
      GeneratedColumn<double>(
        'default_flow_break_ratio',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.2),
      );
  static const VerificationMeta _defaultSessionLengthSecsMeta =
      const VerificationMeta('defaultSessionLengthSecs');
  @override
  late final GeneratedColumn<int> defaultSessionLengthSecs =
      GeneratedColumn<int>(
        'default_session_length_secs',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(3000),
      );
  static const VerificationMeta _keepScreenOnInFocusMeta =
      const VerificationMeta('keepScreenOnInFocus');
  @override
  late final GeneratedColumn<bool> keepScreenOnInFocus = GeneratedColumn<bool>(
    'keep_screen_on_in_focus',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_screen_on_in_focus" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LibrarySort, int> librarySort =
      GeneratedColumn<int>(
        'library_sort',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<LibrarySort>($AppSettingsTable.$converterlibrarySort);
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dbSchemaSeededMeta = const VerificationMeta(
    'dbSchemaSeeded',
  );
  @override
  late final GeneratedColumn<bool> dbSchemaSeeded = GeneratedColumn<bool>(
    'db_schema_seeded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("db_schema_seeded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    defaultPomodoroWorkSecs,
    defaultPomodoroBreakSecs,
    defaultFlowBreakRatio,
    defaultSessionLengthSecs,
    keepScreenOnInFocus,
    librarySort,
    onboardingDone,
    dbSchemaSeeded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('default_pomodoro_work_secs')) {
      context.handle(
        _defaultPomodoroWorkSecsMeta,
        defaultPomodoroWorkSecs.isAcceptableOrUnknown(
          data['default_pomodoro_work_secs']!,
          _defaultPomodoroWorkSecsMeta,
        ),
      );
    }
    if (data.containsKey('default_pomodoro_break_secs')) {
      context.handle(
        _defaultPomodoroBreakSecsMeta,
        defaultPomodoroBreakSecs.isAcceptableOrUnknown(
          data['default_pomodoro_break_secs']!,
          _defaultPomodoroBreakSecsMeta,
        ),
      );
    }
    if (data.containsKey('default_flow_break_ratio')) {
      context.handle(
        _defaultFlowBreakRatioMeta,
        defaultFlowBreakRatio.isAcceptableOrUnknown(
          data['default_flow_break_ratio']!,
          _defaultFlowBreakRatioMeta,
        ),
      );
    }
    if (data.containsKey('default_session_length_secs')) {
      context.handle(
        _defaultSessionLengthSecsMeta,
        defaultSessionLengthSecs.isAcceptableOrUnknown(
          data['default_session_length_secs']!,
          _defaultSessionLengthSecsMeta,
        ),
      );
    }
    if (data.containsKey('keep_screen_on_in_focus')) {
      context.handle(
        _keepScreenOnInFocusMeta,
        keepScreenOnInFocus.isAcceptableOrUnknown(
          data['keep_screen_on_in_focus']!,
          _keepScreenOnInFocusMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    }
    if (data.containsKey('db_schema_seeded')) {
      context.handle(
        _dbSchemaSeededMeta,
        dbSchemaSeeded.isAcceptableOrUnknown(
          data['db_schema_seeded']!,
          _dbSchemaSeededMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      themeMode: $AppSettingsTable.$converterthemeMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}theme_mode'],
        )!,
      ),
      defaultPomodoroWorkSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_pomodoro_work_secs'],
      )!,
      defaultPomodoroBreakSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_pomodoro_break_secs'],
      )!,
      defaultFlowBreakRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_flow_break_ratio'],
      )!,
      defaultSessionLengthSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_session_length_secs'],
      )!,
      keepScreenOnInFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_screen_on_in_focus'],
      )!,
      librarySort: $AppSettingsTable.$converterlibrarySort.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}library_sort'],
        )!,
      ),
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      dbSchemaSeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}db_schema_seeded'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ThemeModeSetting, int, int> $converterthemeMode =
      const EnumIndexConverter<ThemeModeSetting>(ThemeModeSetting.values);
  static JsonTypeConverter2<LibrarySort, int, int> $converterlibrarySort =
      const EnumIndexConverter<LibrarySort>(LibrarySort.values);
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// Always the constant `'singleton'` — the only DB-side default in the
  /// schema, so the single settings row is trivial to upsert.
  final String id;
  final ThemeModeSetting themeMode;
  final int defaultPomodoroWorkSecs;
  final int defaultPomodoroBreakSecs;
  final double defaultFlowBreakRatio;
  final int defaultSessionLengthSecs;
  final bool keepScreenOnInFocus;
  final LibrarySort librarySort;
  final bool onboardingDone;
  final bool dbSchemaSeeded;
  const AppSetting({
    required this.id,
    required this.themeMode,
    required this.defaultPomodoroWorkSecs,
    required this.defaultPomodoroBreakSecs,
    required this.defaultFlowBreakRatio,
    required this.defaultSessionLengthSecs,
    required this.keepScreenOnInFocus,
    required this.librarySort,
    required this.onboardingDone,
    required this.dbSchemaSeeded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['theme_mode'] = Variable<int>(
        $AppSettingsTable.$converterthemeMode.toSql(themeMode),
      );
    }
    map['default_pomodoro_work_secs'] = Variable<int>(defaultPomodoroWorkSecs);
    map['default_pomodoro_break_secs'] = Variable<int>(
      defaultPomodoroBreakSecs,
    );
    map['default_flow_break_ratio'] = Variable<double>(defaultFlowBreakRatio);
    map['default_session_length_secs'] = Variable<int>(
      defaultSessionLengthSecs,
    );
    map['keep_screen_on_in_focus'] = Variable<bool>(keepScreenOnInFocus);
    {
      map['library_sort'] = Variable<int>(
        $AppSettingsTable.$converterlibrarySort.toSql(librarySort),
      );
    }
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['db_schema_seeded'] = Variable<bool>(dbSchemaSeeded);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      defaultPomodoroWorkSecs: Value(defaultPomodoroWorkSecs),
      defaultPomodoroBreakSecs: Value(defaultPomodoroBreakSecs),
      defaultFlowBreakRatio: Value(defaultFlowBreakRatio),
      defaultSessionLengthSecs: Value(defaultSessionLengthSecs),
      keepScreenOnInFocus: Value(keepScreenOnInFocus),
      librarySort: Value(librarySort),
      onboardingDone: Value(onboardingDone),
      dbSchemaSeeded: Value(dbSchemaSeeded),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<String>(json['id']),
      themeMode: $AppSettingsTable.$converterthemeMode.fromJson(
        serializer.fromJson<int>(json['themeMode']),
      ),
      defaultPomodoroWorkSecs: serializer.fromJson<int>(
        json['defaultPomodoroWorkSecs'],
      ),
      defaultPomodoroBreakSecs: serializer.fromJson<int>(
        json['defaultPomodoroBreakSecs'],
      ),
      defaultFlowBreakRatio: serializer.fromJson<double>(
        json['defaultFlowBreakRatio'],
      ),
      defaultSessionLengthSecs: serializer.fromJson<int>(
        json['defaultSessionLengthSecs'],
      ),
      keepScreenOnInFocus: serializer.fromJson<bool>(
        json['keepScreenOnInFocus'],
      ),
      librarySort: $AppSettingsTable.$converterlibrarySort.fromJson(
        serializer.fromJson<int>(json['librarySort']),
      ),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      dbSchemaSeeded: serializer.fromJson<bool>(json['dbSchemaSeeded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'themeMode': serializer.toJson<int>(
        $AppSettingsTable.$converterthemeMode.toJson(themeMode),
      ),
      'defaultPomodoroWorkSecs': serializer.toJson<int>(
        defaultPomodoroWorkSecs,
      ),
      'defaultPomodoroBreakSecs': serializer.toJson<int>(
        defaultPomodoroBreakSecs,
      ),
      'defaultFlowBreakRatio': serializer.toJson<double>(defaultFlowBreakRatio),
      'defaultSessionLengthSecs': serializer.toJson<int>(
        defaultSessionLengthSecs,
      ),
      'keepScreenOnInFocus': serializer.toJson<bool>(keepScreenOnInFocus),
      'librarySort': serializer.toJson<int>(
        $AppSettingsTable.$converterlibrarySort.toJson(librarySort),
      ),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'dbSchemaSeeded': serializer.toJson<bool>(dbSchemaSeeded),
    };
  }

  AppSetting copyWith({
    String? id,
    ThemeModeSetting? themeMode,
    int? defaultPomodoroWorkSecs,
    int? defaultPomodoroBreakSecs,
    double? defaultFlowBreakRatio,
    int? defaultSessionLengthSecs,
    bool? keepScreenOnInFocus,
    LibrarySort? librarySort,
    bool? onboardingDone,
    bool? dbSchemaSeeded,
  }) => AppSetting(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    defaultPomodoroWorkSecs:
        defaultPomodoroWorkSecs ?? this.defaultPomodoroWorkSecs,
    defaultPomodoroBreakSecs:
        defaultPomodoroBreakSecs ?? this.defaultPomodoroBreakSecs,
    defaultFlowBreakRatio: defaultFlowBreakRatio ?? this.defaultFlowBreakRatio,
    defaultSessionLengthSecs:
        defaultSessionLengthSecs ?? this.defaultSessionLengthSecs,
    keepScreenOnInFocus: keepScreenOnInFocus ?? this.keepScreenOnInFocus,
    librarySort: librarySort ?? this.librarySort,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    dbSchemaSeeded: dbSchemaSeeded ?? this.dbSchemaSeeded,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      defaultPomodoroWorkSecs: data.defaultPomodoroWorkSecs.present
          ? data.defaultPomodoroWorkSecs.value
          : this.defaultPomodoroWorkSecs,
      defaultPomodoroBreakSecs: data.defaultPomodoroBreakSecs.present
          ? data.defaultPomodoroBreakSecs.value
          : this.defaultPomodoroBreakSecs,
      defaultFlowBreakRatio: data.defaultFlowBreakRatio.present
          ? data.defaultFlowBreakRatio.value
          : this.defaultFlowBreakRatio,
      defaultSessionLengthSecs: data.defaultSessionLengthSecs.present
          ? data.defaultSessionLengthSecs.value
          : this.defaultSessionLengthSecs,
      keepScreenOnInFocus: data.keepScreenOnInFocus.present
          ? data.keepScreenOnInFocus.value
          : this.keepScreenOnInFocus,
      librarySort: data.librarySort.present
          ? data.librarySort.value
          : this.librarySort,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      dbSchemaSeeded: data.dbSchemaSeeded.present
          ? data.dbSchemaSeeded.value
          : this.dbSchemaSeeded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultPomodoroWorkSecs: $defaultPomodoroWorkSecs, ')
          ..write('defaultPomodoroBreakSecs: $defaultPomodoroBreakSecs, ')
          ..write('defaultFlowBreakRatio: $defaultFlowBreakRatio, ')
          ..write('defaultSessionLengthSecs: $defaultSessionLengthSecs, ')
          ..write('keepScreenOnInFocus: $keepScreenOnInFocus, ')
          ..write('librarySort: $librarySort, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('dbSchemaSeeded: $dbSchemaSeeded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    defaultPomodoroWorkSecs,
    defaultPomodoroBreakSecs,
    defaultFlowBreakRatio,
    defaultSessionLengthSecs,
    keepScreenOnInFocus,
    librarySort,
    onboardingDone,
    dbSchemaSeeded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.defaultPomodoroWorkSecs == this.defaultPomodoroWorkSecs &&
          other.defaultPomodoroBreakSecs == this.defaultPomodoroBreakSecs &&
          other.defaultFlowBreakRatio == this.defaultFlowBreakRatio &&
          other.defaultSessionLengthSecs == this.defaultSessionLengthSecs &&
          other.keepScreenOnInFocus == this.keepScreenOnInFocus &&
          other.librarySort == this.librarySort &&
          other.onboardingDone == this.onboardingDone &&
          other.dbSchemaSeeded == this.dbSchemaSeeded);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> id;
  final Value<ThemeModeSetting> themeMode;
  final Value<int> defaultPomodoroWorkSecs;
  final Value<int> defaultPomodoroBreakSecs;
  final Value<double> defaultFlowBreakRatio;
  final Value<int> defaultSessionLengthSecs;
  final Value<bool> keepScreenOnInFocus;
  final Value<LibrarySort> librarySort;
  final Value<bool> onboardingDone;
  final Value<bool> dbSchemaSeeded;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultPomodoroWorkSecs = const Value.absent(),
    this.defaultPomodoroBreakSecs = const Value.absent(),
    this.defaultFlowBreakRatio = const Value.absent(),
    this.defaultSessionLengthSecs = const Value.absent(),
    this.keepScreenOnInFocus = const Value.absent(),
    this.librarySort = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.dbSchemaSeeded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultPomodoroWorkSecs = const Value.absent(),
    this.defaultPomodoroBreakSecs = const Value.absent(),
    this.defaultFlowBreakRatio = const Value.absent(),
    this.defaultSessionLengthSecs = const Value.absent(),
    this.keepScreenOnInFocus = const Value.absent(),
    this.librarySort = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.dbSchemaSeeded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<String>? id,
    Expression<int>? themeMode,
    Expression<int>? defaultPomodoroWorkSecs,
    Expression<int>? defaultPomodoroBreakSecs,
    Expression<double>? defaultFlowBreakRatio,
    Expression<int>? defaultSessionLengthSecs,
    Expression<bool>? keepScreenOnInFocus,
    Expression<int>? librarySort,
    Expression<bool>? onboardingDone,
    Expression<bool>? dbSchemaSeeded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (defaultPomodoroWorkSecs != null)
        'default_pomodoro_work_secs': defaultPomodoroWorkSecs,
      if (defaultPomodoroBreakSecs != null)
        'default_pomodoro_break_secs': defaultPomodoroBreakSecs,
      if (defaultFlowBreakRatio != null)
        'default_flow_break_ratio': defaultFlowBreakRatio,
      if (defaultSessionLengthSecs != null)
        'default_session_length_secs': defaultSessionLengthSecs,
      if (keepScreenOnInFocus != null)
        'keep_screen_on_in_focus': keepScreenOnInFocus,
      if (librarySort != null) 'library_sort': librarySort,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (dbSchemaSeeded != null) 'db_schema_seeded': dbSchemaSeeded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? id,
    Value<ThemeModeSetting>? themeMode,
    Value<int>? defaultPomodoroWorkSecs,
    Value<int>? defaultPomodoroBreakSecs,
    Value<double>? defaultFlowBreakRatio,
    Value<int>? defaultSessionLengthSecs,
    Value<bool>? keepScreenOnInFocus,
    Value<LibrarySort>? librarySort,
    Value<bool>? onboardingDone,
    Value<bool>? dbSchemaSeeded,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      defaultPomodoroWorkSecs:
          defaultPomodoroWorkSecs ?? this.defaultPomodoroWorkSecs,
      defaultPomodoroBreakSecs:
          defaultPomodoroBreakSecs ?? this.defaultPomodoroBreakSecs,
      defaultFlowBreakRatio:
          defaultFlowBreakRatio ?? this.defaultFlowBreakRatio,
      defaultSessionLengthSecs:
          defaultSessionLengthSecs ?? this.defaultSessionLengthSecs,
      keepScreenOnInFocus: keepScreenOnInFocus ?? this.keepScreenOnInFocus,
      librarySort: librarySort ?? this.librarySort,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      dbSchemaSeeded: dbSchemaSeeded ?? this.dbSchemaSeeded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<int>(
        $AppSettingsTable.$converterthemeMode.toSql(themeMode.value),
      );
    }
    if (defaultPomodoroWorkSecs.present) {
      map['default_pomodoro_work_secs'] = Variable<int>(
        defaultPomodoroWorkSecs.value,
      );
    }
    if (defaultPomodoroBreakSecs.present) {
      map['default_pomodoro_break_secs'] = Variable<int>(
        defaultPomodoroBreakSecs.value,
      );
    }
    if (defaultFlowBreakRatio.present) {
      map['default_flow_break_ratio'] = Variable<double>(
        defaultFlowBreakRatio.value,
      );
    }
    if (defaultSessionLengthSecs.present) {
      map['default_session_length_secs'] = Variable<int>(
        defaultSessionLengthSecs.value,
      );
    }
    if (keepScreenOnInFocus.present) {
      map['keep_screen_on_in_focus'] = Variable<bool>(
        keepScreenOnInFocus.value,
      );
    }
    if (librarySort.present) {
      map['library_sort'] = Variable<int>(
        $AppSettingsTable.$converterlibrarySort.toSql(librarySort.value),
      );
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (dbSchemaSeeded.present) {
      map['db_schema_seeded'] = Variable<bool>(dbSchemaSeeded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultPomodoroWorkSecs: $defaultPomodoroWorkSecs, ')
          ..write('defaultPomodoroBreakSecs: $defaultPomodoroBreakSecs, ')
          ..write('defaultFlowBreakRatio: $defaultFlowBreakRatio, ')
          ..write('defaultSessionLengthSecs: $defaultSessionLengthSecs, ')
          ..write('keepScreenOnInFocus: $keepScreenOnInFocus, ')
          ..write('librarySort: $librarySort, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('dbSchemaSeeded: $dbSchemaSeeded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ZennoDatabase extends GeneratedDatabase {
  _$ZennoDatabase(QueryExecutor e) : super(e);
  $ZennoDatabaseManager get managers => $ZennoDatabaseManager(this);
  late final $CanvasFoldersTable canvasFolders = $CanvasFoldersTable(this);
  late final $CanvasesTable canvases = $CanvasesTable(this);
  late final $CanvasElementsTable canvasElements = $CanvasElementsTable(this);
  late final $InkStrokesTable inkStrokes = $InkStrokesTable(this);
  late final $PdfDocumentsTable pdfDocuments = $PdfDocumentsTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $CanvasLinksTable canvasLinks = $CanvasLinksTable(this);
  late final $RitualChecklistsTable ritualChecklists = $RitualChecklistsTable(
    this,
  );
  late final $RitualChecklistItemsTable ritualChecklistItems =
      $RitualChecklistItemsTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $FocusSessionRitualChecksTable focusSessionRitualChecks =
      $FocusSessionRitualChecksTable(this);
  late final $DistractionsTable distractions = $DistractionsTable(this);
  late final $BoardsTable boards = $BoardsTable(this);
  late final $BoardColumnsTable boardColumns = $BoardColumnsTable(this);
  late final $BoardCardsTable boardCards = $BoardCardsTable(this);
  late final $RevisionCardDetailsTable revisionCardDetails =
      $RevisionCardDetailsTable(this);
  late final $GoalCardDetailsTable goalCardDetails = $GoalCardDetailsTable(
    this,
  );
  late final $ReflectionTemplatesTable reflectionTemplates =
      $ReflectionTemplatesTable(this);
  late final $ReflectionEntriesTable reflectionEntries =
      $ReflectionEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxCanvasesFolderId = Index(
    'idx_canvases_folder_id',
    'CREATE INDEX idx_canvases_folder_id ON canvases (folder_id)',
  );
  late final Index idxCanvasesUpdatedAt = Index(
    'idx_canvases_updated_at',
    'CREATE INDEX idx_canvases_updated_at ON canvases (updated_at)',
  );
  late final Index idxCanvasElementsCanvasId = Index(
    'idx_canvas_elements_canvas_id',
    'CREATE INDEX idx_canvas_elements_canvas_id ON canvas_elements (canvas_id)',
  );
  late final Index idxCanvasElementsCanvasIdZIndex = Index(
    'idx_canvas_elements_canvas_id_z_index',
    'CREATE INDEX idx_canvas_elements_canvas_id_z_index ON canvas_elements (canvas_id, z_index)',
  );
  late final Index idxFocusSessionsStartedAt = Index(
    'idx_focus_sessions_started_at',
    'CREATE INDEX idx_focus_sessions_started_at ON focus_sessions (started_at)',
  );
  late final Index idxDistractionsSessionId = Index(
    'idx_distractions_session_id',
    'CREATE INDEX idx_distractions_session_id ON distractions (session_id)',
  );
  late final Index idxBoardColumnsBoardId = Index(
    'idx_board_columns_board_id',
    'CREATE INDEX idx_board_columns_board_id ON board_columns (board_id)',
  );
  late final Index idxBoardCardsColumnIdPosition = Index(
    'idx_board_cards_column_id_position',
    'CREATE INDEX idx_board_cards_column_id_position ON board_cards (column_id, position)',
  );
  late final Index idxBoardCardsBoardId = Index(
    'idx_board_cards_board_id',
    'CREATE INDEX idx_board_cards_board_id ON board_cards (board_id)',
  );
  late final Index idxReflectionEntriesCardId = Index(
    'idx_reflection_entries_card_id',
    'CREATE INDEX idx_reflection_entries_card_id ON reflection_entries (card_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    canvasFolders,
    canvases,
    canvasElements,
    inkStrokes,
    pdfDocuments,
    images,
    canvasLinks,
    ritualChecklists,
    ritualChecklistItems,
    focusSessions,
    focusSessionRitualChecks,
    distractions,
    boards,
    boardColumns,
    boardCards,
    revisionCardDetails,
    goalCardDetails,
    reflectionTemplates,
    reflectionEntries,
    appSettings,
    idxCanvasesFolderId,
    idxCanvasesUpdatedAt,
    idxCanvasElementsCanvasId,
    idxCanvasElementsCanvasIdZIndex,
    idxFocusSessionsStartedAt,
    idxDistractionsSessionId,
    idxBoardColumnsBoardId,
    idxBoardCardsColumnIdPosition,
    idxBoardCardsBoardId,
    idxReflectionEntriesCardId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvas_folders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvases',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvas_elements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvas_elements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ink_strokes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvas_elements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pdf_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvas_elements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('images', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvas_elements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvas_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ritual_checklists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ritual_checklist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'canvases',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('focus_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'focus_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('focus_session_ritual_checks', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ritual_checklist_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('focus_session_ritual_checks', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'focus_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('distractions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('board_columns', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'board_columns',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('board_cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('board_cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'board_cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('revision_card_details', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'board_cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('goal_card_details', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'board_cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reflection_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CanvasFoldersTableCreateCompanionBuilder =
    CanvasFoldersCompanion Function({
      required String id,
      required String name,
      required double position,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CanvasFoldersTableUpdateCompanionBuilder =
    CanvasFoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> position,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CanvasFoldersTableReferences
    extends BaseReferences<_$ZennoDatabase, $CanvasFoldersTable, CanvasFolder> {
  $$CanvasFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CanvasesTable, List<Canvase>> _canvasesRefsTable(
    _$ZennoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.canvases,
    aliasName: $_aliasNameGenerator(db.canvasFolders.id, db.canvases.folderId),
  );

  $$CanvasesTableProcessedTableManager get canvasesRefs {
    final manager = $$CanvasesTableTableManager(
      $_db,
      $_db.canvases,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canvasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CanvasFoldersTableFilterComposer
    extends Composer<_$ZennoDatabase, $CanvasFoldersTable> {
  $$CanvasFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> canvasesRefs(
    Expression<bool> Function($$CanvasesTableFilterComposer f) f,
  ) {
    final $$CanvasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableFilterComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasFoldersTableOrderingComposer
    extends Composer<_$ZennoDatabase, $CanvasFoldersTable> {
  $$CanvasFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CanvasFoldersTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $CanvasFoldersTable> {
  $$CanvasFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> canvasesRefs<T extends Object>(
    Expression<T> Function($$CanvasesTableAnnotationComposer a) f,
  ) {
    final $$CanvasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableAnnotationComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasFoldersTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $CanvasFoldersTable,
          CanvasFolder,
          $$CanvasFoldersTableFilterComposer,
          $$CanvasFoldersTableOrderingComposer,
          $$CanvasFoldersTableAnnotationComposer,
          $$CanvasFoldersTableCreateCompanionBuilder,
          $$CanvasFoldersTableUpdateCompanionBuilder,
          (CanvasFolder, $$CanvasFoldersTableReferences),
          CanvasFolder,
          PrefetchHooks Function({bool canvasesRefs})
        > {
  $$CanvasFoldersTableTableManager(
    _$ZennoDatabase db,
    $CanvasFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasFoldersCompanion(
                id: id,
                name: name,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double position,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CanvasFoldersCompanion.insert(
                id: id,
                name: name,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({canvasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (canvasesRefs) db.canvases],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (canvasesRefs)
                    await $_getPrefetchedData<
                      CanvasFolder,
                      $CanvasFoldersTable,
                      Canvase
                    >(
                      currentTable: table,
                      referencedTable: $$CanvasFoldersTableReferences
                          ._canvasesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CanvasFoldersTableReferences(
                            db,
                            table,
                            p0,
                          ).canvasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CanvasFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $CanvasFoldersTable,
      CanvasFolder,
      $$CanvasFoldersTableFilterComposer,
      $$CanvasFoldersTableOrderingComposer,
      $$CanvasFoldersTableAnnotationComposer,
      $$CanvasFoldersTableCreateCompanionBuilder,
      $$CanvasFoldersTableUpdateCompanionBuilder,
      (CanvasFolder, $$CanvasFoldersTableReferences),
      CanvasFolder,
      PrefetchHooks Function({bool canvasesRefs})
    >;
typedef $$CanvasesTableCreateCompanionBuilder =
    CanvasesCompanion Function({
      required String id,
      required String title,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastOpenedAt,
      Value<String?> thumbnailPath,
      Value<bool> isArchived,
      Value<String?> folderId,
      Value<double> worldOriginX,
      Value<double> worldOriginY,
      Value<double> vpTx,
      Value<double> vpTy,
      Value<double> vpScale,
      Value<double> vpRotation,
      Value<BackgroundKind> backgroundKind,
      Value<int> rowid,
    });
typedef $$CanvasesTableUpdateCompanionBuilder =
    CanvasesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastOpenedAt,
      Value<String?> thumbnailPath,
      Value<bool> isArchived,
      Value<String?> folderId,
      Value<double> worldOriginX,
      Value<double> worldOriginY,
      Value<double> vpTx,
      Value<double> vpTy,
      Value<double> vpScale,
      Value<double> vpRotation,
      Value<BackgroundKind> backgroundKind,
      Value<int> rowid,
    });

final class $$CanvasesTableReferences
    extends BaseReferences<_$ZennoDatabase, $CanvasesTable, Canvase> {
  $$CanvasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CanvasFoldersTable _folderIdTable(_$ZennoDatabase db) =>
      db.canvasFolders.createAlias(
        $_aliasNameGenerator(db.canvases.folderId, db.canvasFolders.id),
      );

  $$CanvasFoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$CanvasFoldersTableTableManager(
      $_db,
      $_db.canvasFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CanvasElementsTable, List<CanvasElement>>
  _canvasElementsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.canvasElements,
    aliasName: $_aliasNameGenerator(db.canvases.id, db.canvasElements.canvasId),
  );

  $$CanvasElementsTableProcessedTableManager get canvasElementsRefs {
    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.canvasId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canvasElementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FocusSessionsTable, List<FocusSession>>
  _focusSessionsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.focusSessions,
    aliasName: $_aliasNameGenerator(
      db.canvases.id,
      db.focusSessions.linkedCanvasId,
    ),
  );

  $$FocusSessionsTableProcessedTableManager get focusSessionsRefs {
    final manager = $$FocusSessionsTableTableManager(
      $_db,
      $_db.focusSessions,
    ).filter((f) => f.linkedCanvasId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CanvasesTableFilterComposer
    extends Composer<_$ZennoDatabase, $CanvasesTable> {
  $$CanvasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get worldOriginX => $composableBuilder(
    column: $table.worldOriginX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get worldOriginY => $composableBuilder(
    column: $table.worldOriginY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vpTx => $composableBuilder(
    column: $table.vpTx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vpTy => $composableBuilder(
    column: $table.vpTy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vpScale => $composableBuilder(
    column: $table.vpScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vpRotation => $composableBuilder(
    column: $table.vpRotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BackgroundKind, BackgroundKind, int>
  get backgroundKind => $composableBuilder(
    column: $table.backgroundKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$CanvasFoldersTableFilterComposer get folderId {
    final $$CanvasFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.canvasFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasFoldersTableFilterComposer(
            $db: $db,
            $table: $db.canvasFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> canvasElementsRefs(
    Expression<bool> Function($$CanvasElementsTableFilterComposer f) f,
  ) {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.canvasId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> focusSessionsRefs(
    Expression<bool> Function($$FocusSessionsTableFilterComposer f) f,
  ) {
    final $$FocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.linkedCanvasId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasesTableOrderingComposer
    extends Composer<_$ZennoDatabase, $CanvasesTable> {
  $$CanvasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get worldOriginX => $composableBuilder(
    column: $table.worldOriginX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get worldOriginY => $composableBuilder(
    column: $table.worldOriginY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vpTx => $composableBuilder(
    column: $table.vpTx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vpTy => $composableBuilder(
    column: $table.vpTy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vpScale => $composableBuilder(
    column: $table.vpScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vpRotation => $composableBuilder(
    column: $table.vpRotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backgroundKind => $composableBuilder(
    column: $table.backgroundKind,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasFoldersTableOrderingComposer get folderId {
    final $$CanvasFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.canvasFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.canvasFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasesTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $CanvasesTable> {
  $$CanvasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get worldOriginX => $composableBuilder(
    column: $table.worldOriginX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get worldOriginY => $composableBuilder(
    column: $table.worldOriginY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vpTx =>
      $composableBuilder(column: $table.vpTx, builder: (column) => column);

  GeneratedColumn<double> get vpTy =>
      $composableBuilder(column: $table.vpTy, builder: (column) => column);

  GeneratedColumn<double> get vpScale =>
      $composableBuilder(column: $table.vpScale, builder: (column) => column);

  GeneratedColumn<double> get vpRotation => $composableBuilder(
    column: $table.vpRotation,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BackgroundKind, int> get backgroundKind =>
      $composableBuilder(
        column: $table.backgroundKind,
        builder: (column) => column,
      );

  $$CanvasFoldersTableAnnotationComposer get folderId {
    final $$CanvasFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.canvasFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> canvasElementsRefs<T extends Object>(
    Expression<T> Function($$CanvasElementsTableAnnotationComposer a) f,
  ) {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.canvasId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> focusSessionsRefs<T extends Object>(
    Expression<T> Function($$FocusSessionsTableAnnotationComposer a) f,
  ) {
    final $$FocusSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.linkedCanvasId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasesTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $CanvasesTable,
          Canvase,
          $$CanvasesTableFilterComposer,
          $$CanvasesTableOrderingComposer,
          $$CanvasesTableAnnotationComposer,
          $$CanvasesTableCreateCompanionBuilder,
          $$CanvasesTableUpdateCompanionBuilder,
          (Canvase, $$CanvasesTableReferences),
          Canvase,
          PrefetchHooks Function({
            bool folderId,
            bool canvasElementsRefs,
            bool focusSessionsRefs,
          })
        > {
  $$CanvasesTableTableManager(_$ZennoDatabase db, $CanvasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<double> worldOriginX = const Value.absent(),
                Value<double> worldOriginY = const Value.absent(),
                Value<double> vpTx = const Value.absent(),
                Value<double> vpTy = const Value.absent(),
                Value<double> vpScale = const Value.absent(),
                Value<double> vpRotation = const Value.absent(),
                Value<BackgroundKind> backgroundKind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasesCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
                thumbnailPath: thumbnailPath,
                isArchived: isArchived,
                folderId: folderId,
                worldOriginX: worldOriginX,
                worldOriginY: worldOriginY,
                vpTx: vpTx,
                vpTy: vpTy,
                vpScale: vpScale,
                vpRotation: vpRotation,
                backgroundKind: backgroundKind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<double> worldOriginX = const Value.absent(),
                Value<double> worldOriginY = const Value.absent(),
                Value<double> vpTx = const Value.absent(),
                Value<double> vpTy = const Value.absent(),
                Value<double> vpScale = const Value.absent(),
                Value<double> vpRotation = const Value.absent(),
                Value<BackgroundKind> backgroundKind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasesCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
                thumbnailPath: thumbnailPath,
                isArchived: isArchived,
                folderId: folderId,
                worldOriginX: worldOriginX,
                worldOriginY: worldOriginY,
                vpTx: vpTx,
                vpTy: vpTy,
                vpScale: vpScale,
                vpRotation: vpRotation,
                backgroundKind: backgroundKind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                canvasElementsRefs = false,
                focusSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (canvasElementsRefs) db.canvasElements,
                    if (focusSessionsRefs) db.focusSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$CanvasesTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$CanvasesTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (canvasElementsRefs)
                        await $_getPrefetchedData<
                          Canvase,
                          $CanvasesTable,
                          CanvasElement
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasesTableReferences
                              ._canvasElementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasesTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasElementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.canvasId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (focusSessionsRefs)
                        await $_getPrefetchedData<
                          Canvase,
                          $CanvasesTable,
                          FocusSession
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasesTableReferences
                              ._focusSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasesTableReferences(
                                db,
                                table,
                                p0,
                              ).focusSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.linkedCanvasId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CanvasesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $CanvasesTable,
      Canvase,
      $$CanvasesTableFilterComposer,
      $$CanvasesTableOrderingComposer,
      $$CanvasesTableAnnotationComposer,
      $$CanvasesTableCreateCompanionBuilder,
      $$CanvasesTableUpdateCompanionBuilder,
      (Canvase, $$CanvasesTableReferences),
      Canvase,
      PrefetchHooks Function({
        bool folderId,
        bool canvasElementsRefs,
        bool focusSessionsRefs,
      })
    >;
typedef $$CanvasElementsTableCreateCompanionBuilder =
    CanvasElementsCompanion Function({
      required String id,
      required String canvasId,
      required ElementKind kind,
      required double x,
      required double y,
      required double width,
      required double height,
      Value<double> rotation,
      required double zIndex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CanvasElementsTableUpdateCompanionBuilder =
    CanvasElementsCompanion Function({
      Value<String> id,
      Value<String> canvasId,
      Value<ElementKind> kind,
      Value<double> x,
      Value<double> y,
      Value<double> width,
      Value<double> height,
      Value<double> rotation,
      Value<double> zIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$CanvasElementsTableReferences
    extends
        BaseReferences<_$ZennoDatabase, $CanvasElementsTable, CanvasElement> {
  $$CanvasElementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CanvasesTable _canvasIdTable(_$ZennoDatabase db) =>
      db.canvases.createAlias(
        $_aliasNameGenerator(db.canvasElements.canvasId, db.canvases.id),
      );

  $$CanvasesTableProcessedTableManager get canvasId {
    final $_column = $_itemColumn<String>('canvas_id')!;

    final manager = $$CanvasesTableTableManager(
      $_db,
      $_db.canvases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_canvasIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InkStrokesTable, List<InkStroke>>
  _inkStrokesRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.inkStrokes,
    aliasName: $_aliasNameGenerator(
      db.canvasElements.id,
      db.inkStrokes.elementId,
    ),
  );

  $$InkStrokesTableProcessedTableManager get inkStrokesRefs {
    final manager = $$InkStrokesTableTableManager(
      $_db,
      $_db.inkStrokes,
    ).filter((f) => f.elementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inkStrokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PdfDocumentsTable, List<PdfDocument>>
  _pdfDocumentsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.pdfDocuments,
    aliasName: $_aliasNameGenerator(
      db.canvasElements.id,
      db.pdfDocuments.elementId,
    ),
  );

  $$PdfDocumentsTableProcessedTableManager get pdfDocumentsRefs {
    final manager = $$PdfDocumentsTableTableManager(
      $_db,
      $_db.pdfDocuments,
    ).filter((f) => f.elementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pdfDocumentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImagesTable, List<Image>> _imagesRefsTable(
    _$ZennoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.images,
    aliasName: $_aliasNameGenerator(db.canvasElements.id, db.images.elementId),
  );

  $$ImagesTableProcessedTableManager get imagesRefs {
    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.elementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CanvasLinksTable, List<CanvasLink>>
  _canvasLinksRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.canvasLinks,
    aliasName: $_aliasNameGenerator(
      db.canvasElements.id,
      db.canvasLinks.elementId,
    ),
  );

  $$CanvasLinksTableProcessedTableManager get canvasLinksRefs {
    final manager = $$CanvasLinksTableTableManager(
      $_db,
      $_db.canvasLinks,
    ).filter((f) => f.elementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canvasLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CanvasElementsTableFilterComposer
    extends Composer<_$ZennoDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ElementKind, ElementKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasesTableFilterComposer get canvasId {
    final $$CanvasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableFilterComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inkStrokesRefs(
    Expression<bool> Function($$InkStrokesTableFilterComposer f) f,
  ) {
    final $$InkStrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkStrokes,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkStrokesTableFilterComposer(
            $db: $db,
            $table: $db.inkStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pdfDocumentsRefs(
    Expression<bool> Function($$PdfDocumentsTableFilterComposer f) f,
  ) {
    final $$PdfDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imagesRefs(
    Expression<bool> Function($$ImagesTableFilterComposer f) f,
  ) {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> canvasLinksRefs(
    Expression<bool> Function($$CanvasLinksTableFilterComposer f) f,
  ) {
    final $$CanvasLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasLinks,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasLinksTableFilterComposer(
            $db: $db,
            $table: $db.canvasLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasElementsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasesTableOrderingComposer get canvasId {
    final $$CanvasesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableOrderingComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasElementsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $CanvasElementsTable> {
  $$CanvasElementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ElementKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<double> get zIndex =>
      $composableBuilder(column: $table.zIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CanvasesTableAnnotationComposer get canvasId {
    final $$CanvasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableAnnotationComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inkStrokesRefs<T extends Object>(
    Expression<T> Function($$InkStrokesTableAnnotationComposer a) f,
  ) {
    final $$InkStrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkStrokes,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkStrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.inkStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pdfDocumentsRefs<T extends Object>(
    Expression<T> Function($$PdfDocumentsTableAnnotationComposer a) f,
  ) {
    final $$PdfDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> imagesRefs<T extends Object>(
    Expression<T> Function($$ImagesTableAnnotationComposer a) f,
  ) {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> canvasLinksRefs<T extends Object>(
    Expression<T> Function($$CanvasLinksTableAnnotationComposer a) f,
  ) {
    final $$CanvasLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasLinks,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanvasElementsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $CanvasElementsTable,
          CanvasElement,
          $$CanvasElementsTableFilterComposer,
          $$CanvasElementsTableOrderingComposer,
          $$CanvasElementsTableAnnotationComposer,
          $$CanvasElementsTableCreateCompanionBuilder,
          $$CanvasElementsTableUpdateCompanionBuilder,
          (CanvasElement, $$CanvasElementsTableReferences),
          CanvasElement,
          PrefetchHooks Function({
            bool canvasId,
            bool inkStrokesRefs,
            bool pdfDocumentsRefs,
            bool imagesRefs,
            bool canvasLinksRefs,
          })
        > {
  $$CanvasElementsTableTableManager(
    _$ZennoDatabase db,
    $CanvasElementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasElementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasElementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasElementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> canvasId = const Value.absent(),
                Value<ElementKind> kind = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<double> zIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasElementsCompanion(
                id: id,
                canvasId: canvasId,
                kind: kind,
                x: x,
                y: y,
                width: width,
                height: height,
                rotation: rotation,
                zIndex: zIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String canvasId,
                required ElementKind kind,
                required double x,
                required double y,
                required double width,
                required double height,
                Value<double> rotation = const Value.absent(),
                required double zIndex,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasElementsCompanion.insert(
                id: id,
                canvasId: canvasId,
                kind: kind,
                x: x,
                y: y,
                width: width,
                height: height,
                rotation: rotation,
                zIndex: zIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasElementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                canvasId = false,
                inkStrokesRefs = false,
                pdfDocumentsRefs = false,
                imagesRefs = false,
                canvasLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inkStrokesRefs) db.inkStrokes,
                    if (pdfDocumentsRefs) db.pdfDocuments,
                    if (imagesRefs) db.images,
                    if (canvasLinksRefs) db.canvasLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (canvasId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.canvasId,
                                    referencedTable:
                                        $$CanvasElementsTableReferences
                                            ._canvasIdTable(db),
                                    referencedColumn:
                                        $$CanvasElementsTableReferences
                                            ._canvasIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inkStrokesRefs)
                        await $_getPrefetchedData<
                          CanvasElement,
                          $CanvasElementsTable,
                          InkStroke
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasElementsTableReferences
                              ._inkStrokesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasElementsTableReferences(
                                db,
                                table,
                                p0,
                              ).inkStrokesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.elementId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pdfDocumentsRefs)
                        await $_getPrefetchedData<
                          CanvasElement,
                          $CanvasElementsTable,
                          PdfDocument
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasElementsTableReferences
                              ._pdfDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasElementsTableReferences(
                                db,
                                table,
                                p0,
                              ).pdfDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.elementId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imagesRefs)
                        await $_getPrefetchedData<
                          CanvasElement,
                          $CanvasElementsTable,
                          Image
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasElementsTableReferences
                              ._imagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasElementsTableReferences(
                                db,
                                table,
                                p0,
                              ).imagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.elementId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (canvasLinksRefs)
                        await $_getPrefetchedData<
                          CanvasElement,
                          $CanvasElementsTable,
                          CanvasLink
                        >(
                          currentTable: table,
                          referencedTable: $$CanvasElementsTableReferences
                              ._canvasLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanvasElementsTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.elementId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CanvasElementsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $CanvasElementsTable,
      CanvasElement,
      $$CanvasElementsTableFilterComposer,
      $$CanvasElementsTableOrderingComposer,
      $$CanvasElementsTableAnnotationComposer,
      $$CanvasElementsTableCreateCompanionBuilder,
      $$CanvasElementsTableUpdateCompanionBuilder,
      (CanvasElement, $$CanvasElementsTableReferences),
      CanvasElement,
      PrefetchHooks Function({
        bool canvasId,
        bool inkStrokesRefs,
        bool pdfDocumentsRefs,
        bool imagesRefs,
        bool canvasLinksRefs,
      })
    >;
typedef $$InkStrokesTableCreateCompanionBuilder =
    InkStrokesCompanion Function({
      required String elementId,
      required Uint8List points,
      required int pointCount,
      required int color,
      required double strokeWidth,
      required StrokeTool tool,
      Value<bool> isHighlighter,
      Value<int> rowid,
    });
typedef $$InkStrokesTableUpdateCompanionBuilder =
    InkStrokesCompanion Function({
      Value<String> elementId,
      Value<Uint8List> points,
      Value<int> pointCount,
      Value<int> color,
      Value<double> strokeWidth,
      Value<StrokeTool> tool,
      Value<bool> isHighlighter,
      Value<int> rowid,
    });

final class $$InkStrokesTableReferences
    extends BaseReferences<_$ZennoDatabase, $InkStrokesTable, InkStroke> {
  $$InkStrokesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CanvasElementsTable _elementIdTable(_$ZennoDatabase db) =>
      db.canvasElements.createAlias(
        $_aliasNameGenerator(db.inkStrokes.elementId, db.canvasElements.id),
      );

  $$CanvasElementsTableProcessedTableManager get elementId {
    final $_column = $_itemColumn<String>('element_id')!;

    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_elementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InkStrokesTableFilterComposer
    extends Composer<_$ZennoDatabase, $InkStrokesTable> {
  $$InkStrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StrokeTool, StrokeTool, int> get tool =>
      $composableBuilder(
        column: $table.tool,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isHighlighter => $composableBuilder(
    column: $table.isHighlighter,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasElementsTableFilterComposer get elementId {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableOrderingComposer
    extends Composer<_$ZennoDatabase, $InkStrokesTable> {
  $$InkStrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHighlighter => $composableBuilder(
    column: $table.isHighlighter,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasElementsTableOrderingComposer get elementId {
    final $$CanvasElementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableOrderingComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $InkStrokesTable> {
  $$InkStrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<StrokeTool, int> get tool =>
      $composableBuilder(column: $table.tool, builder: (column) => column);

  GeneratedColumn<bool> get isHighlighter => $composableBuilder(
    column: $table.isHighlighter,
    builder: (column) => column,
  );

  $$CanvasElementsTableAnnotationComposer get elementId {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $InkStrokesTable,
          InkStroke,
          $$InkStrokesTableFilterComposer,
          $$InkStrokesTableOrderingComposer,
          $$InkStrokesTableAnnotationComposer,
          $$InkStrokesTableCreateCompanionBuilder,
          $$InkStrokesTableUpdateCompanionBuilder,
          (InkStroke, $$InkStrokesTableReferences),
          InkStroke,
          PrefetchHooks Function({bool elementId})
        > {
  $$InkStrokesTableTableManager(_$ZennoDatabase db, $InkStrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InkStrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InkStrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InkStrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> elementId = const Value.absent(),
                Value<Uint8List> points = const Value.absent(),
                Value<int> pointCount = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> strokeWidth = const Value.absent(),
                Value<StrokeTool> tool = const Value.absent(),
                Value<bool> isHighlighter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkStrokesCompanion(
                elementId: elementId,
                points: points,
                pointCount: pointCount,
                color: color,
                strokeWidth: strokeWidth,
                tool: tool,
                isHighlighter: isHighlighter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String elementId,
                required Uint8List points,
                required int pointCount,
                required int color,
                required double strokeWidth,
                required StrokeTool tool,
                Value<bool> isHighlighter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkStrokesCompanion.insert(
                elementId: elementId,
                points: points,
                pointCount: pointCount,
                color: color,
                strokeWidth: strokeWidth,
                tool: tool,
                isHighlighter: isHighlighter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InkStrokesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({elementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (elementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.elementId,
                                referencedTable: $$InkStrokesTableReferences
                                    ._elementIdTable(db),
                                referencedColumn: $$InkStrokesTableReferences
                                    ._elementIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InkStrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $InkStrokesTable,
      InkStroke,
      $$InkStrokesTableFilterComposer,
      $$InkStrokesTableOrderingComposer,
      $$InkStrokesTableAnnotationComposer,
      $$InkStrokesTableCreateCompanionBuilder,
      $$InkStrokesTableUpdateCompanionBuilder,
      (InkStroke, $$InkStrokesTableReferences),
      InkStroke,
      PrefetchHooks Function({bool elementId})
    >;
typedef $$PdfDocumentsTableCreateCompanionBuilder =
    PdfDocumentsCompanion Function({
      required String elementId,
      required String filePath,
      required String originalFilename,
      required int pageNumber,
      required int totalPages,
      Value<double?> cropLeft,
      Value<double?> cropTop,
      Value<double?> cropRight,
      Value<double?> cropBottom,
      Value<String?> importHash,
      Value<int> rowid,
    });
typedef $$PdfDocumentsTableUpdateCompanionBuilder =
    PdfDocumentsCompanion Function({
      Value<String> elementId,
      Value<String> filePath,
      Value<String> originalFilename,
      Value<int> pageNumber,
      Value<int> totalPages,
      Value<double?> cropLeft,
      Value<double?> cropTop,
      Value<double?> cropRight,
      Value<double?> cropBottom,
      Value<String?> importHash,
      Value<int> rowid,
    });

final class $$PdfDocumentsTableReferences
    extends BaseReferences<_$ZennoDatabase, $PdfDocumentsTable, PdfDocument> {
  $$PdfDocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CanvasElementsTable _elementIdTable(_$ZennoDatabase db) =>
      db.canvasElements.createAlias(
        $_aliasNameGenerator(db.pdfDocuments.elementId, db.canvasElements.id),
      );

  $$CanvasElementsTableProcessedTableManager get elementId {
    final $_column = $_itemColumn<String>('element_id')!;

    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_elementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PdfDocumentsTableFilterComposer
    extends Composer<_$ZennoDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasElementsTableFilterComposer get elementId {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PdfDocumentsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasElementsTableOrderingComposer get elementId {
    final $$CanvasElementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableOrderingComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PdfDocumentsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cropLeft =>
      $composableBuilder(column: $table.cropLeft, builder: (column) => column);

  GeneratedColumn<double> get cropTop =>
      $composableBuilder(column: $table.cropTop, builder: (column) => column);

  GeneratedColumn<double> get cropRight =>
      $composableBuilder(column: $table.cropRight, builder: (column) => column);

  GeneratedColumn<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => column,
  );

  $$CanvasElementsTableAnnotationComposer get elementId {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PdfDocumentsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $PdfDocumentsTable,
          PdfDocument,
          $$PdfDocumentsTableFilterComposer,
          $$PdfDocumentsTableOrderingComposer,
          $$PdfDocumentsTableAnnotationComposer,
          $$PdfDocumentsTableCreateCompanionBuilder,
          $$PdfDocumentsTableUpdateCompanionBuilder,
          (PdfDocument, $$PdfDocumentsTableReferences),
          PdfDocument,
          PrefetchHooks Function({bool elementId})
        > {
  $$PdfDocumentsTableTableManager(_$ZennoDatabase db, $PdfDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PdfDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PdfDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PdfDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> elementId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> originalFilename = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<double?> cropLeft = const Value.absent(),
                Value<double?> cropTop = const Value.absent(),
                Value<double?> cropRight = const Value.absent(),
                Value<double?> cropBottom = const Value.absent(),
                Value<String?> importHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDocumentsCompanion(
                elementId: elementId,
                filePath: filePath,
                originalFilename: originalFilename,
                pageNumber: pageNumber,
                totalPages: totalPages,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                importHash: importHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String elementId,
                required String filePath,
                required String originalFilename,
                required int pageNumber,
                required int totalPages,
                Value<double?> cropLeft = const Value.absent(),
                Value<double?> cropTop = const Value.absent(),
                Value<double?> cropRight = const Value.absent(),
                Value<double?> cropBottom = const Value.absent(),
                Value<String?> importHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDocumentsCompanion.insert(
                elementId: elementId,
                filePath: filePath,
                originalFilename: originalFilename,
                pageNumber: pageNumber,
                totalPages: totalPages,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                importHash: importHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PdfDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({elementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (elementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.elementId,
                                referencedTable: $$PdfDocumentsTableReferences
                                    ._elementIdTable(db),
                                referencedColumn: $$PdfDocumentsTableReferences
                                    ._elementIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PdfDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $PdfDocumentsTable,
      PdfDocument,
      $$PdfDocumentsTableFilterComposer,
      $$PdfDocumentsTableOrderingComposer,
      $$PdfDocumentsTableAnnotationComposer,
      $$PdfDocumentsTableCreateCompanionBuilder,
      $$PdfDocumentsTableUpdateCompanionBuilder,
      (PdfDocument, $$PdfDocumentsTableReferences),
      PdfDocument,
      PrefetchHooks Function({bool elementId})
    >;
typedef $$ImagesTableCreateCompanionBuilder =
    ImagesCompanion Function({
      required String elementId,
      required String filePath,
      required double intrinsicWidth,
      required double intrinsicHeight,
      Value<int> rowid,
    });
typedef $$ImagesTableUpdateCompanionBuilder =
    ImagesCompanion Function({
      Value<String> elementId,
      Value<String> filePath,
      Value<double> intrinsicWidth,
      Value<double> intrinsicHeight,
      Value<int> rowid,
    });

final class $$ImagesTableReferences
    extends BaseReferences<_$ZennoDatabase, $ImagesTable, Image> {
  $$ImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CanvasElementsTable _elementIdTable(_$ZennoDatabase db) =>
      db.canvasElements.createAlias(
        $_aliasNameGenerator(db.images.elementId, db.canvasElements.id),
      );

  $$CanvasElementsTableProcessedTableManager get elementId {
    final $_column = $_itemColumn<String>('element_id')!;

    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_elementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImagesTableFilterComposer
    extends Composer<_$ZennoDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intrinsicWidth => $composableBuilder(
    column: $table.intrinsicWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intrinsicHeight => $composableBuilder(
    column: $table.intrinsicHeight,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasElementsTableFilterComposer get elementId {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableOrderingComposer
    extends Composer<_$ZennoDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intrinsicWidth => $composableBuilder(
    column: $table.intrinsicWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intrinsicHeight => $composableBuilder(
    column: $table.intrinsicHeight,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasElementsTableOrderingComposer get elementId {
    final $$CanvasElementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableOrderingComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<double> get intrinsicWidth => $composableBuilder(
    column: $table.intrinsicWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intrinsicHeight => $composableBuilder(
    column: $table.intrinsicHeight,
    builder: (column) => column,
  );

  $$CanvasElementsTableAnnotationComposer get elementId {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $ImagesTable,
          Image,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (Image, $$ImagesTableReferences),
          Image,
          PrefetchHooks Function({bool elementId})
        > {
  $$ImagesTableTableManager(_$ZennoDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> elementId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<double> intrinsicWidth = const Value.absent(),
                Value<double> intrinsicHeight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                elementId: elementId,
                filePath: filePath,
                intrinsicWidth: intrinsicWidth,
                intrinsicHeight: intrinsicHeight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String elementId,
                required String filePath,
                required double intrinsicWidth,
                required double intrinsicHeight,
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                elementId: elementId,
                filePath: filePath,
                intrinsicWidth: intrinsicWidth,
                intrinsicHeight: intrinsicHeight,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ImagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({elementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (elementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.elementId,
                                referencedTable: $$ImagesTableReferences
                                    ._elementIdTable(db),
                                referencedColumn: $$ImagesTableReferences
                                    ._elementIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $ImagesTable,
      Image,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (Image, $$ImagesTableReferences),
      Image,
      PrefetchHooks Function({bool elementId})
    >;
typedef $$CanvasLinksTableCreateCompanionBuilder =
    CanvasLinksCompanion Function({
      required String elementId,
      required CanvasLinkKind linkKind,
      Value<String?> url,
      Value<String?> title,
      Value<String?> targetCanvasId,
      Value<double?> targetRectX,
      Value<double?> targetRectY,
      Value<double?> targetRectWidth,
      Value<double?> targetRectHeight,
      Value<double?> targetVpTx,
      Value<double?> targetVpTy,
      Value<double?> targetVpScale,
      Value<double?> targetVpRotation,
      required String label,
      Value<int> rowid,
    });
typedef $$CanvasLinksTableUpdateCompanionBuilder =
    CanvasLinksCompanion Function({
      Value<String> elementId,
      Value<CanvasLinkKind> linkKind,
      Value<String?> url,
      Value<String?> title,
      Value<String?> targetCanvasId,
      Value<double?> targetRectX,
      Value<double?> targetRectY,
      Value<double?> targetRectWidth,
      Value<double?> targetRectHeight,
      Value<double?> targetVpTx,
      Value<double?> targetVpTy,
      Value<double?> targetVpScale,
      Value<double?> targetVpRotation,
      Value<String> label,
      Value<int> rowid,
    });

final class $$CanvasLinksTableReferences
    extends BaseReferences<_$ZennoDatabase, $CanvasLinksTable, CanvasLink> {
  $$CanvasLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CanvasElementsTable _elementIdTable(_$ZennoDatabase db) =>
      db.canvasElements.createAlias(
        $_aliasNameGenerator(db.canvasLinks.elementId, db.canvasElements.id),
      );

  $$CanvasElementsTableProcessedTableManager get elementId {
    final $_column = $_itemColumn<String>('element_id')!;

    final manager = $$CanvasElementsTableTableManager(
      $_db,
      $_db.canvasElements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_elementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CanvasLinksTableFilterComposer
    extends Composer<_$ZennoDatabase, $CanvasLinksTable> {
  $$CanvasLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CanvasLinkKind, CanvasLinkKind, int>
  get linkKind => $composableBuilder(
    column: $table.linkKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetCanvasId => $composableBuilder(
    column: $table.targetCanvasId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRectX => $composableBuilder(
    column: $table.targetRectX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRectY => $composableBuilder(
    column: $table.targetRectY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRectWidth => $composableBuilder(
    column: $table.targetRectWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRectHeight => $composableBuilder(
    column: $table.targetRectHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetVpTx => $composableBuilder(
    column: $table.targetVpTx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetVpTy => $composableBuilder(
    column: $table.targetVpTy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetVpScale => $composableBuilder(
    column: $table.targetVpScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetVpRotation => $composableBuilder(
    column: $table.targetVpRotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasElementsTableFilterComposer get elementId {
    final $$CanvasElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableFilterComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasLinksTableOrderingComposer
    extends Composer<_$ZennoDatabase, $CanvasLinksTable> {
  $$CanvasLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get linkKind => $composableBuilder(
    column: $table.linkKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetCanvasId => $composableBuilder(
    column: $table.targetCanvasId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRectX => $composableBuilder(
    column: $table.targetRectX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRectY => $composableBuilder(
    column: $table.targetRectY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRectWidth => $composableBuilder(
    column: $table.targetRectWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRectHeight => $composableBuilder(
    column: $table.targetRectHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetVpTx => $composableBuilder(
    column: $table.targetVpTx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetVpTy => $composableBuilder(
    column: $table.targetVpTy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetVpScale => $composableBuilder(
    column: $table.targetVpScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetVpRotation => $composableBuilder(
    column: $table.targetVpRotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasElementsTableOrderingComposer get elementId {
    final $$CanvasElementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableOrderingComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasLinksTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $CanvasLinksTable> {
  $$CanvasLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CanvasLinkKind, int> get linkKind =>
      $composableBuilder(column: $table.linkKind, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetCanvasId => $composableBuilder(
    column: $table.targetCanvasId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRectX => $composableBuilder(
    column: $table.targetRectX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRectY => $composableBuilder(
    column: $table.targetRectY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRectWidth => $composableBuilder(
    column: $table.targetRectWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRectHeight => $composableBuilder(
    column: $table.targetRectHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetVpTx => $composableBuilder(
    column: $table.targetVpTx,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetVpTy => $composableBuilder(
    column: $table.targetVpTy,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetVpScale => $composableBuilder(
    column: $table.targetVpScale,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetVpRotation => $composableBuilder(
    column: $table.targetVpRotation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$CanvasElementsTableAnnotationComposer get elementId {
    final $$CanvasElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.canvasElements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanvasLinksTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $CanvasLinksTable,
          CanvasLink,
          $$CanvasLinksTableFilterComposer,
          $$CanvasLinksTableOrderingComposer,
          $$CanvasLinksTableAnnotationComposer,
          $$CanvasLinksTableCreateCompanionBuilder,
          $$CanvasLinksTableUpdateCompanionBuilder,
          (CanvasLink, $$CanvasLinksTableReferences),
          CanvasLink,
          PrefetchHooks Function({bool elementId})
        > {
  $$CanvasLinksTableTableManager(_$ZennoDatabase db, $CanvasLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> elementId = const Value.absent(),
                Value<CanvasLinkKind> linkKind = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> targetCanvasId = const Value.absent(),
                Value<double?> targetRectX = const Value.absent(),
                Value<double?> targetRectY = const Value.absent(),
                Value<double?> targetRectWidth = const Value.absent(),
                Value<double?> targetRectHeight = const Value.absent(),
                Value<double?> targetVpTx = const Value.absent(),
                Value<double?> targetVpTy = const Value.absent(),
                Value<double?> targetVpScale = const Value.absent(),
                Value<double?> targetVpRotation = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasLinksCompanion(
                elementId: elementId,
                linkKind: linkKind,
                url: url,
                title: title,
                targetCanvasId: targetCanvasId,
                targetRectX: targetRectX,
                targetRectY: targetRectY,
                targetRectWidth: targetRectWidth,
                targetRectHeight: targetRectHeight,
                targetVpTx: targetVpTx,
                targetVpTy: targetVpTy,
                targetVpScale: targetVpScale,
                targetVpRotation: targetVpRotation,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String elementId,
                required CanvasLinkKind linkKind,
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> targetCanvasId = const Value.absent(),
                Value<double?> targetRectX = const Value.absent(),
                Value<double?> targetRectY = const Value.absent(),
                Value<double?> targetRectWidth = const Value.absent(),
                Value<double?> targetRectHeight = const Value.absent(),
                Value<double?> targetVpTx = const Value.absent(),
                Value<double?> targetVpTy = const Value.absent(),
                Value<double?> targetVpScale = const Value.absent(),
                Value<double?> targetVpRotation = const Value.absent(),
                required String label,
                Value<int> rowid = const Value.absent(),
              }) => CanvasLinksCompanion.insert(
                elementId: elementId,
                linkKind: linkKind,
                url: url,
                title: title,
                targetCanvasId: targetCanvasId,
                targetRectX: targetRectX,
                targetRectY: targetRectY,
                targetRectWidth: targetRectWidth,
                targetRectHeight: targetRectHeight,
                targetVpTx: targetVpTx,
                targetVpTy: targetVpTy,
                targetVpScale: targetVpScale,
                targetVpRotation: targetVpRotation,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({elementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (elementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.elementId,
                                referencedTable: $$CanvasLinksTableReferences
                                    ._elementIdTable(db),
                                referencedColumn: $$CanvasLinksTableReferences
                                    ._elementIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CanvasLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $CanvasLinksTable,
      CanvasLink,
      $$CanvasLinksTableFilterComposer,
      $$CanvasLinksTableOrderingComposer,
      $$CanvasLinksTableAnnotationComposer,
      $$CanvasLinksTableCreateCompanionBuilder,
      $$CanvasLinksTableUpdateCompanionBuilder,
      (CanvasLink, $$CanvasLinksTableReferences),
      CanvasLink,
      PrefetchHooks Function({bool elementId})
    >;
typedef $$RitualChecklistsTableCreateCompanionBuilder =
    RitualChecklistsCompanion Function({
      required String id,
      required String name,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$RitualChecklistsTableUpdateCompanionBuilder =
    RitualChecklistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isDefault,
      Value<int> rowid,
    });

final class $$RitualChecklistsTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $RitualChecklistsTable,
          RitualChecklist
        > {
  $$RitualChecklistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $RitualChecklistItemsTable,
    List<RitualChecklistItem>
  >
  _ritualChecklistItemsRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ritualChecklistItems,
        aliasName: $_aliasNameGenerator(
          db.ritualChecklists.id,
          db.ritualChecklistItems.checklistId,
        ),
      );

  $$RitualChecklistItemsTableProcessedTableManager
  get ritualChecklistItemsRefs {
    final manager = $$RitualChecklistItemsTableTableManager(
      $_db,
      $_db.ritualChecklistItems,
    ).filter((f) => f.checklistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ritualChecklistItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RitualChecklistsTableFilterComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistsTable> {
  $$RitualChecklistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ritualChecklistItemsRefs(
    Expression<bool> Function($$RitualChecklistItemsTableFilterComposer f) f,
  ) {
    final $$RitualChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ritualChecklistItems,
      getReferencedColumn: (t) => t.checklistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RitualChecklistItemsTableFilterComposer(
            $db: $db,
            $table: $db.ritualChecklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RitualChecklistsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistsTable> {
  $$RitualChecklistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RitualChecklistsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistsTable> {
  $$RitualChecklistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> ritualChecklistItemsRefs<T extends Object>(
    Expression<T> Function($$RitualChecklistItemsTableAnnotationComposer a) f,
  ) {
    final $$RitualChecklistItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ritualChecklistItems,
          getReferencedColumn: (t) => t.checklistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RitualChecklistItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.ritualChecklistItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RitualChecklistsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $RitualChecklistsTable,
          RitualChecklist,
          $$RitualChecklistsTableFilterComposer,
          $$RitualChecklistsTableOrderingComposer,
          $$RitualChecklistsTableAnnotationComposer,
          $$RitualChecklistsTableCreateCompanionBuilder,
          $$RitualChecklistsTableUpdateCompanionBuilder,
          (RitualChecklist, $$RitualChecklistsTableReferences),
          RitualChecklist,
          PrefetchHooks Function({bool ritualChecklistItemsRefs})
        > {
  $$RitualChecklistsTableTableManager(
    _$ZennoDatabase db,
    $RitualChecklistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RitualChecklistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RitualChecklistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RitualChecklistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RitualChecklistsCompanion(
                id: id,
                name: name,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RitualChecklistsCompanion.insert(
                id: id,
                name: name,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RitualChecklistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ritualChecklistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ritualChecklistItemsRefs) db.ritualChecklistItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ritualChecklistItemsRefs)
                    await $_getPrefetchedData<
                      RitualChecklist,
                      $RitualChecklistsTable,
                      RitualChecklistItem
                    >(
                      currentTable: table,
                      referencedTable: $$RitualChecklistsTableReferences
                          ._ritualChecklistItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RitualChecklistsTableReferences(
                            db,
                            table,
                            p0,
                          ).ritualChecklistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.checklistId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RitualChecklistsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $RitualChecklistsTable,
      RitualChecklist,
      $$RitualChecklistsTableFilterComposer,
      $$RitualChecklistsTableOrderingComposer,
      $$RitualChecklistsTableAnnotationComposer,
      $$RitualChecklistsTableCreateCompanionBuilder,
      $$RitualChecklistsTableUpdateCompanionBuilder,
      (RitualChecklist, $$RitualChecklistsTableReferences),
      RitualChecklist,
      PrefetchHooks Function({bool ritualChecklistItemsRefs})
    >;
typedef $$RitualChecklistItemsTableCreateCompanionBuilder =
    RitualChecklistItemsCompanion Function({
      required String id,
      required String checklistId,
      required String label,
      required double position,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$RitualChecklistItemsTableUpdateCompanionBuilder =
    RitualChecklistItemsCompanion Function({
      Value<String> id,
      Value<String> checklistId,
      Value<String> label,
      Value<double> position,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$RitualChecklistItemsTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $RitualChecklistItemsTable,
          RitualChecklistItem
        > {
  $$RitualChecklistItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RitualChecklistsTable _checklistIdTable(_$ZennoDatabase db) =>
      db.ritualChecklists.createAlias(
        $_aliasNameGenerator(
          db.ritualChecklistItems.checklistId,
          db.ritualChecklists.id,
        ),
      );

  $$RitualChecklistsTableProcessedTableManager get checklistId {
    final $_column = $_itemColumn<String>('checklist_id')!;

    final manager = $$RitualChecklistsTableTableManager(
      $_db,
      $_db.ritualChecklists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_checklistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FocusSessionRitualChecksTable,
    List<FocusSessionRitualCheck>
  >
  _focusSessionRitualChecksRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.focusSessionRitualChecks,
        aliasName: $_aliasNameGenerator(
          db.ritualChecklistItems.id,
          db.focusSessionRitualChecks.itemId,
        ),
      );

  $$FocusSessionRitualChecksTableProcessedTableManager
  get focusSessionRitualChecksRefs {
    final manager = $$FocusSessionRitualChecksTableTableManager(
      $_db,
      $_db.focusSessionRitualChecks,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _focusSessionRitualChecksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RitualChecklistItemsTableFilterComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistItemsTable> {
  $$RitualChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$RitualChecklistsTableFilterComposer get checklistId {
    final $$RitualChecklistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistId,
      referencedTable: $db.ritualChecklists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RitualChecklistsTableFilterComposer(
            $db: $db,
            $table: $db.ritualChecklists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> focusSessionRitualChecksRefs(
    Expression<bool> Function($$FocusSessionRitualChecksTableFilterComposer f)
    f,
  ) {
    final $$FocusSessionRitualChecksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.focusSessionRitualChecks,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FocusSessionRitualChecksTableFilterComposer(
                $db: $db,
                $table: $db.focusSessionRitualChecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RitualChecklistItemsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistItemsTable> {
  $$RitualChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$RitualChecklistsTableOrderingComposer get checklistId {
    final $$RitualChecklistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistId,
      referencedTable: $db.ritualChecklists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RitualChecklistsTableOrderingComposer(
            $db: $db,
            $table: $db.ritualChecklists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RitualChecklistItemsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $RitualChecklistItemsTable> {
  $$RitualChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$RitualChecklistsTableAnnotationComposer get checklistId {
    final $$RitualChecklistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistId,
      referencedTable: $db.ritualChecklists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RitualChecklistsTableAnnotationComposer(
            $db: $db,
            $table: $db.ritualChecklists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> focusSessionRitualChecksRefs<T extends Object>(
    Expression<T> Function($$FocusSessionRitualChecksTableAnnotationComposer a)
    f,
  ) {
    final $$FocusSessionRitualChecksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.focusSessionRitualChecks,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FocusSessionRitualChecksTableAnnotationComposer(
                $db: $db,
                $table: $db.focusSessionRitualChecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RitualChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $RitualChecklistItemsTable,
          RitualChecklistItem,
          $$RitualChecklistItemsTableFilterComposer,
          $$RitualChecklistItemsTableOrderingComposer,
          $$RitualChecklistItemsTableAnnotationComposer,
          $$RitualChecklistItemsTableCreateCompanionBuilder,
          $$RitualChecklistItemsTableUpdateCompanionBuilder,
          (RitualChecklistItem, $$RitualChecklistItemsTableReferences),
          RitualChecklistItem,
          PrefetchHooks Function({
            bool checklistId,
            bool focusSessionRitualChecksRefs,
          })
        > {
  $$RitualChecklistItemsTableTableManager(
    _$ZennoDatabase db,
    $RitualChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RitualChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RitualChecklistItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RitualChecklistItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> checklistId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RitualChecklistItemsCompanion(
                id: id,
                checklistId: checklistId,
                label: label,
                position: position,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String checklistId,
                required String label,
                required double position,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RitualChecklistItemsCompanion.insert(
                id: id,
                checklistId: checklistId,
                label: label,
                position: position,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RitualChecklistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({checklistId = false, focusSessionRitualChecksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (focusSessionRitualChecksRefs)
                      db.focusSessionRitualChecks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (checklistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.checklistId,
                                    referencedTable:
                                        $$RitualChecklistItemsTableReferences
                                            ._checklistIdTable(db),
                                    referencedColumn:
                                        $$RitualChecklistItemsTableReferences
                                            ._checklistIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (focusSessionRitualChecksRefs)
                        await $_getPrefetchedData<
                          RitualChecklistItem,
                          $RitualChecklistItemsTable,
                          FocusSessionRitualCheck
                        >(
                          currentTable: table,
                          referencedTable: $$RitualChecklistItemsTableReferences
                              ._focusSessionRitualChecksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RitualChecklistItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).focusSessionRitualChecksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RitualChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $RitualChecklistItemsTable,
      RitualChecklistItem,
      $$RitualChecklistItemsTableFilterComposer,
      $$RitualChecklistItemsTableOrderingComposer,
      $$RitualChecklistItemsTableAnnotationComposer,
      $$RitualChecklistItemsTableCreateCompanionBuilder,
      $$RitualChecklistItemsTableUpdateCompanionBuilder,
      (RitualChecklistItem, $$RitualChecklistItemsTableReferences),
      RitualChecklistItem,
      PrefetchHooks Function({
        bool checklistId,
        bool focusSessionRitualChecksRefs,
      })
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String goalText,
      required int preEnergy,
      Value<int?> postEnergy,
      required TimerKind timerKind,
      required int plannedDurationSecs,
      Value<int> actualFocusSecs,
      Value<int?> pomodoroWorkSecs,
      Value<int?> pomodoroBreakSecs,
      Value<double?> flowBreakRatio,
      Value<int> cyclesCompleted,
      required FocusSessionStatus status,
      Value<int?> runtimeStatus,
      Value<int?> runtimePhase,
      Value<DateTime?> runtimePhaseStartedAt,
      Value<int> runtimeCarriedPhaseSecs,
      Value<int?> runtimePhaseTargetSecs,
      Value<int> runtimeBankedFocusSecs,
      Value<String?> linkedCanvasId,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> goalText,
      Value<int> preEnergy,
      Value<int?> postEnergy,
      Value<TimerKind> timerKind,
      Value<int> plannedDurationSecs,
      Value<int> actualFocusSecs,
      Value<int?> pomodoroWorkSecs,
      Value<int?> pomodoroBreakSecs,
      Value<double?> flowBreakRatio,
      Value<int> cyclesCompleted,
      Value<FocusSessionStatus> status,
      Value<int?> runtimeStatus,
      Value<int?> runtimePhase,
      Value<DateTime?> runtimePhaseStartedAt,
      Value<int> runtimeCarriedPhaseSecs,
      Value<int?> runtimePhaseTargetSecs,
      Value<int> runtimeBankedFocusSecs,
      Value<String?> linkedCanvasId,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$FocusSessionsTableReferences
    extends BaseReferences<_$ZennoDatabase, $FocusSessionsTable, FocusSession> {
  $$FocusSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CanvasesTable _linkedCanvasIdTable(_$ZennoDatabase db) =>
      db.canvases.createAlias(
        $_aliasNameGenerator(db.focusSessions.linkedCanvasId, db.canvases.id),
      );

  $$CanvasesTableProcessedTableManager? get linkedCanvasId {
    final $_column = $_itemColumn<String>('linked_canvas_id');
    if ($_column == null) return null;
    final manager = $$CanvasesTableTableManager(
      $_db,
      $_db.canvases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedCanvasIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $FocusSessionRitualChecksTable,
    List<FocusSessionRitualCheck>
  >
  _focusSessionRitualChecksRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.focusSessionRitualChecks,
        aliasName: $_aliasNameGenerator(
          db.focusSessions.id,
          db.focusSessionRitualChecks.sessionId,
        ),
      );

  $$FocusSessionRitualChecksTableProcessedTableManager
  get focusSessionRitualChecksRefs {
    final manager = $$FocusSessionRitualChecksTableTableManager(
      $_db,
      $_db.focusSessionRitualChecks,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _focusSessionRitualChecksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DistractionsTable, List<Distraction>>
  _distractionsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.distractions,
    aliasName: $_aliasNameGenerator(
      db.focusSessions.id,
      db.distractions.sessionId,
    ),
  );

  $$DistractionsTableProcessedTableManager get distractionsRefs {
    final manager = $$DistractionsTableTableManager(
      $_db,
      $_db.distractions,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_distractionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FocusSessionsTableFilterComposer
    extends Composer<_$ZennoDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalText => $composableBuilder(
    column: $table.goalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preEnergy => $composableBuilder(
    column: $table.preEnergy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postEnergy => $composableBuilder(
    column: $table.postEnergy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TimerKind, TimerKind, int> get timerKind =>
      $composableBuilder(
        column: $table.timerKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get plannedDurationSecs => $composableBuilder(
    column: $table.plannedDurationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualFocusSecs => $composableBuilder(
    column: $table.actualFocusSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pomodoroWorkSecs => $composableBuilder(
    column: $table.pomodoroWorkSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pomodoroBreakSecs => $composableBuilder(
    column: $table.pomodoroBreakSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get flowBreakRatio => $composableBuilder(
    column: $table.flowBreakRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cyclesCompleted => $composableBuilder(
    column: $table.cyclesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FocusSessionStatus, FocusSessionStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get runtimeStatus => $composableBuilder(
    column: $table.runtimeStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimePhase => $composableBuilder(
    column: $table.runtimePhase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get runtimePhaseStartedAt => $composableBuilder(
    column: $table.runtimePhaseStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeCarriedPhaseSecs => $composableBuilder(
    column: $table.runtimeCarriedPhaseSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimePhaseTargetSecs => $composableBuilder(
    column: $table.runtimePhaseTargetSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeBankedFocusSecs => $composableBuilder(
    column: $table.runtimeBankedFocusSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$CanvasesTableFilterComposer get linkedCanvasId {
    final $$CanvasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedCanvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableFilterComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> focusSessionRitualChecksRefs(
    Expression<bool> Function($$FocusSessionRitualChecksTableFilterComposer f)
    f,
  ) {
    final $$FocusSessionRitualChecksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.focusSessionRitualChecks,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FocusSessionRitualChecksTableFilterComposer(
                $db: $db,
                $table: $db.focusSessionRitualChecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> distractionsRefs(
    Expression<bool> Function($$DistractionsTableFilterComposer f) f,
  ) {
    final $$DistractionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.distractions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DistractionsTableFilterComposer(
            $db: $db,
            $table: $db.distractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalText => $composableBuilder(
    column: $table.goalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preEnergy => $composableBuilder(
    column: $table.preEnergy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postEnergy => $composableBuilder(
    column: $table.postEnergy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerKind => $composableBuilder(
    column: $table.timerKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDurationSecs => $composableBuilder(
    column: $table.plannedDurationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualFocusSecs => $composableBuilder(
    column: $table.actualFocusSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pomodoroWorkSecs => $composableBuilder(
    column: $table.pomodoroWorkSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pomodoroBreakSecs => $composableBuilder(
    column: $table.pomodoroBreakSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get flowBreakRatio => $composableBuilder(
    column: $table.flowBreakRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cyclesCompleted => $composableBuilder(
    column: $table.cyclesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeStatus => $composableBuilder(
    column: $table.runtimeStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimePhase => $composableBuilder(
    column: $table.runtimePhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get runtimePhaseStartedAt => $composableBuilder(
    column: $table.runtimePhaseStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeCarriedPhaseSecs => $composableBuilder(
    column: $table.runtimeCarriedPhaseSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimePhaseTargetSecs => $composableBuilder(
    column: $table.runtimePhaseTargetSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeBankedFocusSecs => $composableBuilder(
    column: $table.runtimeBankedFocusSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$CanvasesTableOrderingComposer get linkedCanvasId {
    final $$CanvasesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedCanvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableOrderingComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get goalText =>
      $composableBuilder(column: $table.goalText, builder: (column) => column);

  GeneratedColumn<int> get preEnergy =>
      $composableBuilder(column: $table.preEnergy, builder: (column) => column);

  GeneratedColumn<int> get postEnergy => $composableBuilder(
    column: $table.postEnergy,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TimerKind, int> get timerKind =>
      $composableBuilder(column: $table.timerKind, builder: (column) => column);

  GeneratedColumn<int> get plannedDurationSecs => $composableBuilder(
    column: $table.plannedDurationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualFocusSecs => $composableBuilder(
    column: $table.actualFocusSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pomodoroWorkSecs => $composableBuilder(
    column: $table.pomodoroWorkSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pomodoroBreakSecs => $composableBuilder(
    column: $table.pomodoroBreakSecs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get flowBreakRatio => $composableBuilder(
    column: $table.flowBreakRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cyclesCompleted => $composableBuilder(
    column: $table.cyclesCompleted,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FocusSessionStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get runtimeStatus => $composableBuilder(
    column: $table.runtimeStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimePhase => $composableBuilder(
    column: $table.runtimePhase,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get runtimePhaseStartedAt => $composableBuilder(
    column: $table.runtimePhaseStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeCarriedPhaseSecs => $composableBuilder(
    column: $table.runtimeCarriedPhaseSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimePhaseTargetSecs => $composableBuilder(
    column: $table.runtimePhaseTargetSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeBankedFocusSecs => $composableBuilder(
    column: $table.runtimeBankedFocusSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$CanvasesTableAnnotationComposer get linkedCanvasId {
    final $$CanvasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedCanvasId,
      referencedTable: $db.canvases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasesTableAnnotationComposer(
            $db: $db,
            $table: $db.canvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> focusSessionRitualChecksRefs<T extends Object>(
    Expression<T> Function($$FocusSessionRitualChecksTableAnnotationComposer a)
    f,
  ) {
    final $$FocusSessionRitualChecksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.focusSessionRitualChecks,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FocusSessionRitualChecksTableAnnotationComposer(
                $db: $db,
                $table: $db.focusSessionRitualChecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> distractionsRefs<T extends Object>(
    Expression<T> Function($$DistractionsTableAnnotationComposer a) f,
  ) {
    final $$DistractionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.distractions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DistractionsTableAnnotationComposer(
            $db: $db,
            $table: $db.distractions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (FocusSession, $$FocusSessionsTableReferences),
          FocusSession,
          PrefetchHooks Function({
            bool linkedCanvasId,
            bool focusSessionRitualChecksRefs,
            bool distractionsRefs,
          })
        > {
  $$FocusSessionsTableTableManager(
    _$ZennoDatabase db,
    $FocusSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> goalText = const Value.absent(),
                Value<int> preEnergy = const Value.absent(),
                Value<int?> postEnergy = const Value.absent(),
                Value<TimerKind> timerKind = const Value.absent(),
                Value<int> plannedDurationSecs = const Value.absent(),
                Value<int> actualFocusSecs = const Value.absent(),
                Value<int?> pomodoroWorkSecs = const Value.absent(),
                Value<int?> pomodoroBreakSecs = const Value.absent(),
                Value<double?> flowBreakRatio = const Value.absent(),
                Value<int> cyclesCompleted = const Value.absent(),
                Value<FocusSessionStatus> status = const Value.absent(),
                Value<int?> runtimeStatus = const Value.absent(),
                Value<int?> runtimePhase = const Value.absent(),
                Value<DateTime?> runtimePhaseStartedAt = const Value.absent(),
                Value<int> runtimeCarriedPhaseSecs = const Value.absent(),
                Value<int?> runtimePhaseTargetSecs = const Value.absent(),
                Value<int> runtimeBankedFocusSecs = const Value.absent(),
                Value<String?> linkedCanvasId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                goalText: goalText,
                preEnergy: preEnergy,
                postEnergy: postEnergy,
                timerKind: timerKind,
                plannedDurationSecs: plannedDurationSecs,
                actualFocusSecs: actualFocusSecs,
                pomodoroWorkSecs: pomodoroWorkSecs,
                pomodoroBreakSecs: pomodoroBreakSecs,
                flowBreakRatio: flowBreakRatio,
                cyclesCompleted: cyclesCompleted,
                status: status,
                runtimeStatus: runtimeStatus,
                runtimePhase: runtimePhase,
                runtimePhaseStartedAt: runtimePhaseStartedAt,
                runtimeCarriedPhaseSecs: runtimeCarriedPhaseSecs,
                runtimePhaseTargetSecs: runtimePhaseTargetSecs,
                runtimeBankedFocusSecs: runtimeBankedFocusSecs,
                linkedCanvasId: linkedCanvasId,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String goalText,
                required int preEnergy,
                Value<int?> postEnergy = const Value.absent(),
                required TimerKind timerKind,
                required int plannedDurationSecs,
                Value<int> actualFocusSecs = const Value.absent(),
                Value<int?> pomodoroWorkSecs = const Value.absent(),
                Value<int?> pomodoroBreakSecs = const Value.absent(),
                Value<double?> flowBreakRatio = const Value.absent(),
                Value<int> cyclesCompleted = const Value.absent(),
                required FocusSessionStatus status,
                Value<int?> runtimeStatus = const Value.absent(),
                Value<int?> runtimePhase = const Value.absent(),
                Value<DateTime?> runtimePhaseStartedAt = const Value.absent(),
                Value<int> runtimeCarriedPhaseSecs = const Value.absent(),
                Value<int?> runtimePhaseTargetSecs = const Value.absent(),
                Value<int> runtimeBankedFocusSecs = const Value.absent(),
                Value<String?> linkedCanvasId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                goalText: goalText,
                preEnergy: preEnergy,
                postEnergy: postEnergy,
                timerKind: timerKind,
                plannedDurationSecs: plannedDurationSecs,
                actualFocusSecs: actualFocusSecs,
                pomodoroWorkSecs: pomodoroWorkSecs,
                pomodoroBreakSecs: pomodoroBreakSecs,
                flowBreakRatio: flowBreakRatio,
                cyclesCompleted: cyclesCompleted,
                status: status,
                runtimeStatus: runtimeStatus,
                runtimePhase: runtimePhase,
                runtimePhaseStartedAt: runtimePhaseStartedAt,
                runtimeCarriedPhaseSecs: runtimeCarriedPhaseSecs,
                runtimePhaseTargetSecs: runtimePhaseTargetSecs,
                runtimeBankedFocusSecs: runtimeBankedFocusSecs,
                linkedCanvasId: linkedCanvasId,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FocusSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                linkedCanvasId = false,
                focusSessionRitualChecksRefs = false,
                distractionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (focusSessionRitualChecksRefs)
                      db.focusSessionRitualChecks,
                    if (distractionsRefs) db.distractions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (linkedCanvasId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.linkedCanvasId,
                                    referencedTable:
                                        $$FocusSessionsTableReferences
                                            ._linkedCanvasIdTable(db),
                                    referencedColumn:
                                        $$FocusSessionsTableReferences
                                            ._linkedCanvasIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (focusSessionRitualChecksRefs)
                        await $_getPrefetchedData<
                          FocusSession,
                          $FocusSessionsTable,
                          FocusSessionRitualCheck
                        >(
                          currentTable: table,
                          referencedTable: $$FocusSessionsTableReferences
                              ._focusSessionRitualChecksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FocusSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).focusSessionRitualChecksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (distractionsRefs)
                        await $_getPrefetchedData<
                          FocusSession,
                          $FocusSessionsTable,
                          Distraction
                        >(
                          currentTable: table,
                          referencedTable: $$FocusSessionsTableReferences
                              ._distractionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FocusSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).distractionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (FocusSession, $$FocusSessionsTableReferences),
      FocusSession,
      PrefetchHooks Function({
        bool linkedCanvasId,
        bool focusSessionRitualChecksRefs,
        bool distractionsRefs,
      })
    >;
typedef $$FocusSessionRitualChecksTableCreateCompanionBuilder =
    FocusSessionRitualChecksCompanion Function({
      required String id,
      required String sessionId,
      Value<String?> itemId,
      required String itemLabelSnapshot,
      Value<bool> wasChecked,
      Value<int> rowid,
    });
typedef $$FocusSessionRitualChecksTableUpdateCompanionBuilder =
    FocusSessionRitualChecksCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String?> itemId,
      Value<String> itemLabelSnapshot,
      Value<bool> wasChecked,
      Value<int> rowid,
    });

final class $$FocusSessionRitualChecksTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $FocusSessionRitualChecksTable,
          FocusSessionRitualCheck
        > {
  $$FocusSessionRitualChecksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FocusSessionsTable _sessionIdTable(_$ZennoDatabase db) =>
      db.focusSessions.createAlias(
        $_aliasNameGenerator(
          db.focusSessionRitualChecks.sessionId,
          db.focusSessions.id,
        ),
      );

  $$FocusSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$FocusSessionsTableTableManager(
      $_db,
      $_db.focusSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RitualChecklistItemsTable _itemIdTable(_$ZennoDatabase db) =>
      db.ritualChecklistItems.createAlias(
        $_aliasNameGenerator(
          db.focusSessionRitualChecks.itemId,
          db.ritualChecklistItems.id,
        ),
      );

  $$RitualChecklistItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$RitualChecklistItemsTableTableManager(
      $_db,
      $_db.ritualChecklistItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FocusSessionRitualChecksTableFilterComposer
    extends Composer<_$ZennoDatabase, $FocusSessionRitualChecksTable> {
  $$FocusSessionRitualChecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemLabelSnapshot => $composableBuilder(
    column: $table.itemLabelSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasChecked => $composableBuilder(
    column: $table.wasChecked,
    builder: (column) => ColumnFilters(column),
  );

  $$FocusSessionsTableFilterComposer get sessionId {
    final $$FocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RitualChecklistItemsTableFilterComposer get itemId {
    final $$RitualChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.ritualChecklistItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RitualChecklistItemsTableFilterComposer(
            $db: $db,
            $table: $db.ritualChecklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionRitualChecksTableOrderingComposer
    extends Composer<_$ZennoDatabase, $FocusSessionRitualChecksTable> {
  $$FocusSessionRitualChecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemLabelSnapshot => $composableBuilder(
    column: $table.itemLabelSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasChecked => $composableBuilder(
    column: $table.wasChecked,
    builder: (column) => ColumnOrderings(column),
  );

  $$FocusSessionsTableOrderingComposer get sessionId {
    final $$FocusSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RitualChecklistItemsTableOrderingComposer get itemId {
    final $$RitualChecklistItemsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.ritualChecklistItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RitualChecklistItemsTableOrderingComposer(
                $db: $db,
                $table: $db.ritualChecklistItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FocusSessionRitualChecksTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $FocusSessionRitualChecksTable> {
  $$FocusSessionRitualChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemLabelSnapshot => $composableBuilder(
    column: $table.itemLabelSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasChecked => $composableBuilder(
    column: $table.wasChecked,
    builder: (column) => column,
  );

  $$FocusSessionsTableAnnotationComposer get sessionId {
    final $$FocusSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RitualChecklistItemsTableAnnotationComposer get itemId {
    final $$RitualChecklistItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.ritualChecklistItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RitualChecklistItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.ritualChecklistItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FocusSessionRitualChecksTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $FocusSessionRitualChecksTable,
          FocusSessionRitualCheck,
          $$FocusSessionRitualChecksTableFilterComposer,
          $$FocusSessionRitualChecksTableOrderingComposer,
          $$FocusSessionRitualChecksTableAnnotationComposer,
          $$FocusSessionRitualChecksTableCreateCompanionBuilder,
          $$FocusSessionRitualChecksTableUpdateCompanionBuilder,
          (FocusSessionRitualCheck, $$FocusSessionRitualChecksTableReferences),
          FocusSessionRitualCheck,
          PrefetchHooks Function({bool sessionId, bool itemId})
        > {
  $$FocusSessionRitualChecksTableTableManager(
    _$ZennoDatabase db,
    $FocusSessionRitualChecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionRitualChecksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FocusSessionRitualChecksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FocusSessionRitualChecksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String> itemLabelSnapshot = const Value.absent(),
                Value<bool> wasChecked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionRitualChecksCompanion(
                id: id,
                sessionId: sessionId,
                itemId: itemId,
                itemLabelSnapshot: itemLabelSnapshot,
                wasChecked: wasChecked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                Value<String?> itemId = const Value.absent(),
                required String itemLabelSnapshot,
                Value<bool> wasChecked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionRitualChecksCompanion.insert(
                id: id,
                sessionId: sessionId,
                itemId: itemId,
                itemLabelSnapshot: itemLabelSnapshot,
                wasChecked: wasChecked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FocusSessionRitualChecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$FocusSessionRitualChecksTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$FocusSessionRitualChecksTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$FocusSessionRitualChecksTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$FocusSessionRitualChecksTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FocusSessionRitualChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $FocusSessionRitualChecksTable,
      FocusSessionRitualCheck,
      $$FocusSessionRitualChecksTableFilterComposer,
      $$FocusSessionRitualChecksTableOrderingComposer,
      $$FocusSessionRitualChecksTableAnnotationComposer,
      $$FocusSessionRitualChecksTableCreateCompanionBuilder,
      $$FocusSessionRitualChecksTableUpdateCompanionBuilder,
      (FocusSessionRitualCheck, $$FocusSessionRitualChecksTableReferences),
      FocusSessionRitualCheck,
      PrefetchHooks Function({bool sessionId, bool itemId})
    >;
typedef $$DistractionsTableCreateCompanionBuilder =
    DistractionsCompanion Function({
      required String id,
      required String sessionId,
      required DateTime capturedAt,
      required DistractionKind kind,
      required String note,
      required int elapsedSecs,
      Value<int> rowid,
    });
typedef $$DistractionsTableUpdateCompanionBuilder =
    DistractionsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<DateTime> capturedAt,
      Value<DistractionKind> kind,
      Value<String> note,
      Value<int> elapsedSecs,
      Value<int> rowid,
    });

final class $$DistractionsTableReferences
    extends BaseReferences<_$ZennoDatabase, $DistractionsTable, Distraction> {
  $$DistractionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FocusSessionsTable _sessionIdTable(_$ZennoDatabase db) =>
      db.focusSessions.createAlias(
        $_aliasNameGenerator(db.distractions.sessionId, db.focusSessions.id),
      );

  $$FocusSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$FocusSessionsTableTableManager(
      $_db,
      $_db.focusSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DistractionsTableFilterComposer
    extends Composer<_$ZennoDatabase, $DistractionsTable> {
  $$DistractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DistractionKind, DistractionKind, int>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedSecs => $composableBuilder(
    column: $table.elapsedSecs,
    builder: (column) => ColumnFilters(column),
  );

  $$FocusSessionsTableFilterComposer get sessionId {
    final $$FocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DistractionsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $DistractionsTable> {
  $$DistractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedSecs => $composableBuilder(
    column: $table.elapsedSecs,
    builder: (column) => ColumnOrderings(column),
  );

  $$FocusSessionsTableOrderingComposer get sessionId {
    final $$FocusSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DistractionsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $DistractionsTable> {
  $$DistractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DistractionKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get elapsedSecs => $composableBuilder(
    column: $table.elapsedSecs,
    builder: (column) => column,
  );

  $$FocusSessionsTableAnnotationComposer get sessionId {
    final $$FocusSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DistractionsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $DistractionsTable,
          Distraction,
          $$DistractionsTableFilterComposer,
          $$DistractionsTableOrderingComposer,
          $$DistractionsTableAnnotationComposer,
          $$DistractionsTableCreateCompanionBuilder,
          $$DistractionsTableUpdateCompanionBuilder,
          (Distraction, $$DistractionsTableReferences),
          Distraction,
          PrefetchHooks Function({bool sessionId})
        > {
  $$DistractionsTableTableManager(_$ZennoDatabase db, $DistractionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistractionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistractionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistractionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DistractionKind> kind = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> elapsedSecs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DistractionsCompanion(
                id: id,
                sessionId: sessionId,
                capturedAt: capturedAt,
                kind: kind,
                note: note,
                elapsedSecs: elapsedSecs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required DateTime capturedAt,
                required DistractionKind kind,
                required String note,
                required int elapsedSecs,
                Value<int> rowid = const Value.absent(),
              }) => DistractionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                capturedAt: capturedAt,
                kind: kind,
                note: note,
                elapsedSecs: elapsedSecs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DistractionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$DistractionsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$DistractionsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DistractionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $DistractionsTable,
      Distraction,
      $$DistractionsTableFilterComposer,
      $$DistractionsTableOrderingComposer,
      $$DistractionsTableAnnotationComposer,
      $$DistractionsTableCreateCompanionBuilder,
      $$DistractionsTableUpdateCompanionBuilder,
      (Distraction, $$DistractionsTableReferences),
      Distraction,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$BoardsTableCreateCompanionBuilder =
    BoardsCompanion Function({
      required String id,
      required BoardType boardType,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BoardsTableUpdateCompanionBuilder =
    BoardsCompanion Function({
      Value<String> id,
      Value<BoardType> boardType,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BoardsTableReferences
    extends BaseReferences<_$ZennoDatabase, $BoardsTable, Board> {
  $$BoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BoardColumnsTable, List<BoardColumn>>
  _boardColumnsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.boardColumns,
    aliasName: $_aliasNameGenerator(db.boards.id, db.boardColumns.boardId),
  );

  $$BoardColumnsTableProcessedTableManager get boardColumnsRefs {
    final manager = $$BoardColumnsTableTableManager(
      $_db,
      $_db.boardColumns,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_boardColumnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BoardCardsTable, List<BoardCard>>
  _boardCardsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.boardCards,
    aliasName: $_aliasNameGenerator(db.boards.id, db.boardCards.boardId),
  );

  $$BoardCardsTableProcessedTableManager get boardCardsRefs {
    final manager = $$BoardCardsTableTableManager(
      $_db,
      $_db.boardCards,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_boardCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardsTableFilterComposer
    extends Composer<_$ZennoDatabase, $BoardsTable> {
  $$BoardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BoardType, BoardType, int> get boardType =>
      $composableBuilder(
        column: $table.boardType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> boardColumnsRefs(
    Expression<bool> Function($$BoardColumnsTableFilterComposer f) f,
  ) {
    final $$BoardColumnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableFilterComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> boardCardsRefs(
    Expression<bool> Function($$BoardCardsTableFilterComposer f) f,
  ) {
    final $$BoardCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableFilterComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $BoardsTable> {
  $$BoardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boardType => $composableBuilder(
    column: $table.boardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $BoardsTable> {
  $$BoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BoardType, int> get boardType =>
      $composableBuilder(column: $table.boardType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> boardColumnsRefs<T extends Object>(
    Expression<T> Function($$BoardColumnsTableAnnotationComposer a) f,
  ) {
    final $$BoardColumnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> boardCardsRefs<T extends Object>(
    Expression<T> Function($$BoardCardsTableAnnotationComposer a) f,
  ) {
    final $$BoardCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $BoardsTable,
          Board,
          $$BoardsTableFilterComposer,
          $$BoardsTableOrderingComposer,
          $$BoardsTableAnnotationComposer,
          $$BoardsTableCreateCompanionBuilder,
          $$BoardsTableUpdateCompanionBuilder,
          (Board, $$BoardsTableReferences),
          Board,
          PrefetchHooks Function({bool boardColumnsRefs, bool boardCardsRefs})
        > {
  $$BoardsTableTableManager(_$ZennoDatabase db, $BoardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BoardType> boardType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion(
                id: id,
                boardType: boardType,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BoardType boardType,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion.insert(
                id: id,
                boardType: boardType,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({boardColumnsRefs = false, boardCardsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (boardColumnsRefs) db.boardColumns,
                    if (boardCardsRefs) db.boardCards,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (boardColumnsRefs)
                        await $_getPrefetchedData<
                          Board,
                          $BoardsTable,
                          BoardColumn
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._boardColumnsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).boardColumnsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (boardCardsRefs)
                        await $_getPrefetchedData<
                          Board,
                          $BoardsTable,
                          BoardCard
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._boardCardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).boardCardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoardsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $BoardsTable,
      Board,
      $$BoardsTableFilterComposer,
      $$BoardsTableOrderingComposer,
      $$BoardsTableAnnotationComposer,
      $$BoardsTableCreateCompanionBuilder,
      $$BoardsTableUpdateCompanionBuilder,
      (Board, $$BoardsTableReferences),
      Board,
      PrefetchHooks Function({bool boardColumnsRefs, bool boardCardsRefs})
    >;
typedef $$BoardColumnsTableCreateCompanionBuilder =
    BoardColumnsCompanion Function({
      required String id,
      required String boardId,
      required String name,
      required double position,
      Value<int?> color,
      Value<int?> wipLimit,
      Value<int> rowid,
    });
typedef $$BoardColumnsTableUpdateCompanionBuilder =
    BoardColumnsCompanion Function({
      Value<String> id,
      Value<String> boardId,
      Value<String> name,
      Value<double> position,
      Value<int?> color,
      Value<int?> wipLimit,
      Value<int> rowid,
    });

final class $$BoardColumnsTableReferences
    extends BaseReferences<_$ZennoDatabase, $BoardColumnsTable, BoardColumn> {
  $$BoardColumnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$ZennoDatabase db) => db.boards
      .createAlias($_aliasNameGenerator(db.boardColumns.boardId, db.boards.id));

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BoardCardsTable, List<BoardCard>>
  _boardCardsRefsTable(_$ZennoDatabase db) => MultiTypedResultKey.fromTable(
    db.boardCards,
    aliasName: $_aliasNameGenerator(db.boardColumns.id, db.boardCards.columnId),
  );

  $$BoardCardsTableProcessedTableManager get boardCardsRefs {
    final manager = $$BoardCardsTableTableManager(
      $_db,
      $_db.boardCards,
    ).filter((f) => f.columnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_boardCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardColumnsTableFilterComposer
    extends Composer<_$ZennoDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wipLimit => $composableBuilder(
    column: $table.wipLimit,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> boardCardsRefs(
    Expression<bool> Function($$BoardCardsTableFilterComposer f) f,
  ) {
    final $$BoardCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableFilterComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardColumnsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wipLimit => $composableBuilder(
    column: $table.wipLimit,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BoardColumnsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $BoardColumnsTable> {
  $$BoardColumnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get wipLimit =>
      $composableBuilder(column: $table.wipLimit, builder: (column) => column);

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> boardCardsRefs<T extends Object>(
    Expression<T> Function($$BoardCardsTableAnnotationComposer a) f,
  ) {
    final $$BoardCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardColumnsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $BoardColumnsTable,
          BoardColumn,
          $$BoardColumnsTableFilterComposer,
          $$BoardColumnsTableOrderingComposer,
          $$BoardColumnsTableAnnotationComposer,
          $$BoardColumnsTableCreateCompanionBuilder,
          $$BoardColumnsTableUpdateCompanionBuilder,
          (BoardColumn, $$BoardColumnsTableReferences),
          BoardColumn,
          PrefetchHooks Function({bool boardId, bool boardCardsRefs})
        > {
  $$BoardColumnsTableTableManager(_$ZennoDatabase db, $BoardColumnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardColumnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardColumnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardColumnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int?> wipLimit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardColumnsCompanion(
                id: id,
                boardId: boardId,
                name: name,
                position: position,
                color: color,
                wipLimit: wipLimit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boardId,
                required String name,
                required double position,
                Value<int?> color = const Value.absent(),
                Value<int?> wipLimit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardColumnsCompanion.insert(
                id: id,
                boardId: boardId,
                name: name,
                position: position,
                color: color,
                wipLimit: wipLimit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BoardColumnsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false, boardCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (boardCardsRefs) db.boardCards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boardId,
                                referencedTable: $$BoardColumnsTableReferences
                                    ._boardIdTable(db),
                                referencedColumn: $$BoardColumnsTableReferences
                                    ._boardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (boardCardsRefs)
                    await $_getPrefetchedData<
                      BoardColumn,
                      $BoardColumnsTable,
                      BoardCard
                    >(
                      currentTable: table,
                      referencedTable: $$BoardColumnsTableReferences
                          ._boardCardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BoardColumnsTableReferences(
                            db,
                            table,
                            p0,
                          ).boardCardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.columnId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BoardColumnsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $BoardColumnsTable,
      BoardColumn,
      $$BoardColumnsTableFilterComposer,
      $$BoardColumnsTableOrderingComposer,
      $$BoardColumnsTableAnnotationComposer,
      $$BoardColumnsTableCreateCompanionBuilder,
      $$BoardColumnsTableUpdateCompanionBuilder,
      (BoardColumn, $$BoardColumnsTableReferences),
      BoardColumn,
      PrefetchHooks Function({bool boardId, bool boardCardsRefs})
    >;
typedef $$BoardCardsTableCreateCompanionBuilder =
    BoardCardsCompanion Function({
      required String id,
      required String columnId,
      required String boardId,
      required String title,
      Value<String?> subtitle,
      required double position,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BoardCardsTableUpdateCompanionBuilder =
    BoardCardsCompanion Function({
      Value<String> id,
      Value<String> columnId,
      Value<String> boardId,
      Value<String> title,
      Value<String?> subtitle,
      Value<double> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BoardCardsTableReferences
    extends BaseReferences<_$ZennoDatabase, $BoardCardsTable, BoardCard> {
  $$BoardCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardColumnsTable _columnIdTable(_$ZennoDatabase db) =>
      db.boardColumns.createAlias(
        $_aliasNameGenerator(db.boardCards.columnId, db.boardColumns.id),
      );

  $$BoardColumnsTableProcessedTableManager get columnId {
    final $_column = $_itemColumn<String>('column_id')!;

    final manager = $$BoardColumnsTableTableManager(
      $_db,
      $_db.boardColumns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_columnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoardsTable _boardIdTable(_$ZennoDatabase db) => db.boards
      .createAlias($_aliasNameGenerator(db.boardCards.boardId, db.boards.id));

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $RevisionCardDetailsTable,
    List<RevisionCardDetail>
  >
  _revisionCardDetailsRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.revisionCardDetails,
        aliasName: $_aliasNameGenerator(
          db.boardCards.id,
          db.revisionCardDetails.cardId,
        ),
      );

  $$RevisionCardDetailsTableProcessedTableManager get revisionCardDetailsRefs {
    final manager = $$RevisionCardDetailsTableTableManager(
      $_db,
      $_db.revisionCardDetails,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _revisionCardDetailsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalCardDetailsTable, List<GoalCardDetail>>
  _goalCardDetailsRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.goalCardDetails,
        aliasName: $_aliasNameGenerator(
          db.boardCards.id,
          db.goalCardDetails.cardId,
        ),
      );

  $$GoalCardDetailsTableProcessedTableManager get goalCardDetailsRefs {
    final manager = $$GoalCardDetailsTableTableManager(
      $_db,
      $_db.goalCardDetails,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _goalCardDetailsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReflectionEntriesTable, List<ReflectionEntry>>
  _reflectionEntriesRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reflectionEntries,
        aliasName: $_aliasNameGenerator(
          db.boardCards.id,
          db.reflectionEntries.cardId,
        ),
      );

  $$ReflectionEntriesTableProcessedTableManager get reflectionEntriesRefs {
    final manager = $$ReflectionEntriesTableTableManager(
      $_db,
      $_db.reflectionEntries,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reflectionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardCardsTableFilterComposer
    extends Composer<_$ZennoDatabase, $BoardCardsTable> {
  $$BoardCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardColumnsTableFilterComposer get columnId {
    final $$BoardColumnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableFilterComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> revisionCardDetailsRefs(
    Expression<bool> Function($$RevisionCardDetailsTableFilterComposer f) f,
  ) {
    final $$RevisionCardDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.revisionCardDetails,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RevisionCardDetailsTableFilterComposer(
            $db: $db,
            $table: $db.revisionCardDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalCardDetailsRefs(
    Expression<bool> Function($$GoalCardDetailsTableFilterComposer f) f,
  ) {
    final $$GoalCardDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalCardDetails,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalCardDetailsTableFilterComposer(
            $db: $db,
            $table: $db.goalCardDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reflectionEntriesRefs(
    Expression<bool> Function($$ReflectionEntriesTableFilterComposer f) f,
  ) {
    final $$ReflectionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflectionEntries,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.reflectionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardCardsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $BoardCardsTable> {
  $$BoardCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardColumnsTableOrderingComposer get columnId {
    final $$BoardColumnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableOrderingComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BoardCardsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $BoardCardsTable> {
  $$BoardCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BoardColumnsTableAnnotationComposer get columnId {
    final $$BoardColumnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.boardColumns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardColumnsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardColumns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> revisionCardDetailsRefs<T extends Object>(
    Expression<T> Function($$RevisionCardDetailsTableAnnotationComposer a) f,
  ) {
    final $$RevisionCardDetailsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.revisionCardDetails,
          getReferencedColumn: (t) => t.cardId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RevisionCardDetailsTableAnnotationComposer(
                $db: $db,
                $table: $db.revisionCardDetails,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> goalCardDetailsRefs<T extends Object>(
    Expression<T> Function($$GoalCardDetailsTableAnnotationComposer a) f,
  ) {
    final $$GoalCardDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalCardDetails,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalCardDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.goalCardDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reflectionEntriesRefs<T extends Object>(
    Expression<T> Function($$ReflectionEntriesTableAnnotationComposer a) f,
  ) {
    final $$ReflectionEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reflectionEntries,
          getReferencedColumn: (t) => t.cardId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReflectionEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.reflectionEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BoardCardsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $BoardCardsTable,
          BoardCard,
          $$BoardCardsTableFilterComposer,
          $$BoardCardsTableOrderingComposer,
          $$BoardCardsTableAnnotationComposer,
          $$BoardCardsTableCreateCompanionBuilder,
          $$BoardCardsTableUpdateCompanionBuilder,
          (BoardCard, $$BoardCardsTableReferences),
          BoardCard,
          PrefetchHooks Function({
            bool columnId,
            bool boardId,
            bool revisionCardDetailsRefs,
            bool goalCardDetailsRefs,
            bool reflectionEntriesRefs,
          })
        > {
  $$BoardCardsTableTableManager(_$ZennoDatabase db, $BoardCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> columnId = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardCardsCompanion(
                id: id,
                columnId: columnId,
                boardId: boardId,
                title: title,
                subtitle: subtitle,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String columnId,
                required String boardId,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                required double position,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BoardCardsCompanion.insert(
                id: id,
                columnId: columnId,
                boardId: boardId,
                title: title,
                subtitle: subtitle,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BoardCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                columnId = false,
                boardId = false,
                revisionCardDetailsRefs = false,
                goalCardDetailsRefs = false,
                reflectionEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (revisionCardDetailsRefs) db.revisionCardDetails,
                    if (goalCardDetailsRefs) db.goalCardDetails,
                    if (reflectionEntriesRefs) db.reflectionEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (columnId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.columnId,
                                    referencedTable: $$BoardCardsTableReferences
                                        ._columnIdTable(db),
                                    referencedColumn:
                                        $$BoardCardsTableReferences
                                            ._columnIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$BoardCardsTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn:
                                        $$BoardCardsTableReferences
                                            ._boardIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (revisionCardDetailsRefs)
                        await $_getPrefetchedData<
                          BoardCard,
                          $BoardCardsTable,
                          RevisionCardDetail
                        >(
                          currentTable: table,
                          referencedTable: $$BoardCardsTableReferences
                              ._revisionCardDetailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardCardsTableReferences(
                                db,
                                table,
                                p0,
                              ).revisionCardDetailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalCardDetailsRefs)
                        await $_getPrefetchedData<
                          BoardCard,
                          $BoardCardsTable,
                          GoalCardDetail
                        >(
                          currentTable: table,
                          referencedTable: $$BoardCardsTableReferences
                              ._goalCardDetailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardCardsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalCardDetailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reflectionEntriesRefs)
                        await $_getPrefetchedData<
                          BoardCard,
                          $BoardCardsTable,
                          ReflectionEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BoardCardsTableReferences
                              ._reflectionEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardCardsTableReferences(
                                db,
                                table,
                                p0,
                              ).reflectionEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoardCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $BoardCardsTable,
      BoardCard,
      $$BoardCardsTableFilterComposer,
      $$BoardCardsTableOrderingComposer,
      $$BoardCardsTableAnnotationComposer,
      $$BoardCardsTableCreateCompanionBuilder,
      $$BoardCardsTableUpdateCompanionBuilder,
      (BoardCard, $$BoardCardsTableReferences),
      BoardCard,
      PrefetchHooks Function({
        bool columnId,
        bool boardId,
        bool revisionCardDetailsRefs,
        bool goalCardDetailsRefs,
        bool reflectionEntriesRefs,
      })
    >;
typedef $$RevisionCardDetailsTableCreateCompanionBuilder =
    RevisionCardDetailsCompanion Function({
      required String cardId,
      required MasteryFlag masteryFlag,
      Value<DateTime?> lastRevisedAt,
      Value<int> revisionCount,
      Value<int> rowid,
    });
typedef $$RevisionCardDetailsTableUpdateCompanionBuilder =
    RevisionCardDetailsCompanion Function({
      Value<String> cardId,
      Value<MasteryFlag> masteryFlag,
      Value<DateTime?> lastRevisedAt,
      Value<int> revisionCount,
      Value<int> rowid,
    });

final class $$RevisionCardDetailsTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $RevisionCardDetailsTable,
          RevisionCardDetail
        > {
  $$RevisionCardDetailsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BoardCardsTable _cardIdTable(_$ZennoDatabase db) =>
      db.boardCards.createAlias(
        $_aliasNameGenerator(db.revisionCardDetails.cardId, db.boardCards.id),
      );

  $$BoardCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$BoardCardsTableTableManager(
      $_db,
      $_db.boardCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RevisionCardDetailsTableFilterComposer
    extends Composer<_$ZennoDatabase, $RevisionCardDetailsTable> {
  $$RevisionCardDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<MasteryFlag, MasteryFlag, int>
  get masteryFlag => $composableBuilder(
    column: $table.masteryFlag,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastRevisedAt => $composableBuilder(
    column: $table.lastRevisedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionCount => $composableBuilder(
    column: $table.revisionCount,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardCardsTableFilterComposer get cardId {
    final $$BoardCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableFilterComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevisionCardDetailsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $RevisionCardDetailsTable> {
  $$RevisionCardDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get masteryFlag => $composableBuilder(
    column: $table.masteryFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRevisedAt => $composableBuilder(
    column: $table.lastRevisedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionCount => $composableBuilder(
    column: $table.revisionCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardCardsTableOrderingComposer get cardId {
    final $$BoardCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableOrderingComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevisionCardDetailsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $RevisionCardDetailsTable> {
  $$RevisionCardDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<MasteryFlag, int> get masteryFlag =>
      $composableBuilder(
        column: $table.masteryFlag,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get lastRevisedAt => $composableBuilder(
    column: $table.lastRevisedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revisionCount => $composableBuilder(
    column: $table.revisionCount,
    builder: (column) => column,
  );

  $$BoardCardsTableAnnotationComposer get cardId {
    final $$BoardCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RevisionCardDetailsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $RevisionCardDetailsTable,
          RevisionCardDetail,
          $$RevisionCardDetailsTableFilterComposer,
          $$RevisionCardDetailsTableOrderingComposer,
          $$RevisionCardDetailsTableAnnotationComposer,
          $$RevisionCardDetailsTableCreateCompanionBuilder,
          $$RevisionCardDetailsTableUpdateCompanionBuilder,
          (RevisionCardDetail, $$RevisionCardDetailsTableReferences),
          RevisionCardDetail,
          PrefetchHooks Function({bool cardId})
        > {
  $$RevisionCardDetailsTableTableManager(
    _$ZennoDatabase db,
    $RevisionCardDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionCardDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevisionCardDetailsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RevisionCardDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<MasteryFlag> masteryFlag = const Value.absent(),
                Value<DateTime?> lastRevisedAt = const Value.absent(),
                Value<int> revisionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionCardDetailsCompanion(
                cardId: cardId,
                masteryFlag: masteryFlag,
                lastRevisedAt: lastRevisedAt,
                revisionCount: revisionCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cardId,
                required MasteryFlag masteryFlag,
                Value<DateTime?> lastRevisedAt = const Value.absent(),
                Value<int> revisionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionCardDetailsCompanion.insert(
                cardId: cardId,
                masteryFlag: masteryFlag,
                lastRevisedAt: lastRevisedAt,
                revisionCount: revisionCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RevisionCardDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable:
                                    $$RevisionCardDetailsTableReferences
                                        ._cardIdTable(db),
                                referencedColumn:
                                    $$RevisionCardDetailsTableReferences
                                        ._cardIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RevisionCardDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $RevisionCardDetailsTable,
      RevisionCardDetail,
      $$RevisionCardDetailsTableFilterComposer,
      $$RevisionCardDetailsTableOrderingComposer,
      $$RevisionCardDetailsTableAnnotationComposer,
      $$RevisionCardDetailsTableCreateCompanionBuilder,
      $$RevisionCardDetailsTableUpdateCompanionBuilder,
      (RevisionCardDetail, $$RevisionCardDetailsTableReferences),
      RevisionCardDetail,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$GoalCardDetailsTableCreateCompanionBuilder =
    GoalCardDetailsCompanion Function({
      required String cardId,
      Value<DateTime?> targetDate,
      Value<String?> statusNote,
      Value<int> rowid,
    });
typedef $$GoalCardDetailsTableUpdateCompanionBuilder =
    GoalCardDetailsCompanion Function({
      Value<String> cardId,
      Value<DateTime?> targetDate,
      Value<String?> statusNote,
      Value<int> rowid,
    });

final class $$GoalCardDetailsTableReferences
    extends
        BaseReferences<_$ZennoDatabase, $GoalCardDetailsTable, GoalCardDetail> {
  $$GoalCardDetailsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BoardCardsTable _cardIdTable(_$ZennoDatabase db) =>
      db.boardCards.createAlias(
        $_aliasNameGenerator(db.goalCardDetails.cardId, db.boardCards.id),
      );

  $$BoardCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$BoardCardsTableTableManager(
      $_db,
      $_db.boardCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalCardDetailsTableFilterComposer
    extends Composer<_$ZennoDatabase, $GoalCardDetailsTable> {
  $$GoalCardDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardCardsTableFilterComposer get cardId {
    final $$BoardCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableFilterComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalCardDetailsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $GoalCardDetailsTable> {
  $$GoalCardDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardCardsTableOrderingComposer get cardId {
    final $$BoardCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableOrderingComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalCardDetailsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $GoalCardDetailsTable> {
  $$GoalCardDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => column,
  );

  $$BoardCardsTableAnnotationComposer get cardId {
    final $$BoardCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalCardDetailsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $GoalCardDetailsTable,
          GoalCardDetail,
          $$GoalCardDetailsTableFilterComposer,
          $$GoalCardDetailsTableOrderingComposer,
          $$GoalCardDetailsTableAnnotationComposer,
          $$GoalCardDetailsTableCreateCompanionBuilder,
          $$GoalCardDetailsTableUpdateCompanionBuilder,
          (GoalCardDetail, $$GoalCardDetailsTableReferences),
          GoalCardDetail,
          PrefetchHooks Function({bool cardId})
        > {
  $$GoalCardDetailsTableTableManager(
    _$ZennoDatabase db,
    $GoalCardDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalCardDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalCardDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalCardDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String?> statusNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalCardDetailsCompanion(
                cardId: cardId,
                targetDate: targetDate,
                statusNote: statusNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cardId,
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String?> statusNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalCardDetailsCompanion.insert(
                cardId: cardId,
                targetDate: targetDate,
                statusNote: statusNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalCardDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable:
                                    $$GoalCardDetailsTableReferences
                                        ._cardIdTable(db),
                                referencedColumn:
                                    $$GoalCardDetailsTableReferences
                                        ._cardIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalCardDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $GoalCardDetailsTable,
      GoalCardDetail,
      $$GoalCardDetailsTableFilterComposer,
      $$GoalCardDetailsTableOrderingComposer,
      $$GoalCardDetailsTableAnnotationComposer,
      $$GoalCardDetailsTableCreateCompanionBuilder,
      $$GoalCardDetailsTableUpdateCompanionBuilder,
      (GoalCardDetail, $$GoalCardDetailsTableReferences),
      GoalCardDetail,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$ReflectionTemplatesTableCreateCompanionBuilder =
    ReflectionTemplatesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<bool> isBuiltin,
      required String schemaJson,
      required DateTime createdAt,
      required double position,
      Value<int> rowid,
    });
typedef $$ReflectionTemplatesTableUpdateCompanionBuilder =
    ReflectionTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> isBuiltin,
      Value<String> schemaJson,
      Value<DateTime> createdAt,
      Value<double> position,
      Value<int> rowid,
    });

final class $$ReflectionTemplatesTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $ReflectionTemplatesTable,
          ReflectionTemplate
        > {
  $$ReflectionTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ReflectionEntriesTable, List<ReflectionEntry>>
  _reflectionEntriesRefsTable(_$ZennoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reflectionEntries,
        aliasName: $_aliasNameGenerator(
          db.reflectionTemplates.id,
          db.reflectionEntries.templateId,
        ),
      );

  $$ReflectionEntriesTableProcessedTableManager get reflectionEntriesRefs {
    final manager = $$ReflectionEntriesTableTableManager(
      $_db,
      $_db.reflectionEntries,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reflectionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReflectionTemplatesTableFilterComposer
    extends Composer<_$ZennoDatabase, $ReflectionTemplatesTable> {
  $$ReflectionTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reflectionEntriesRefs(
    Expression<bool> Function($$ReflectionEntriesTableFilterComposer f) f,
  ) {
    final $$ReflectionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflectionEntries,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.reflectionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReflectionTemplatesTableOrderingComposer
    extends Composer<_$ZennoDatabase, $ReflectionTemplatesTable> {
  $$ReflectionTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReflectionTemplatesTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $ReflectionTemplatesTable> {
  $$ReflectionTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> reflectionEntriesRefs<T extends Object>(
    Expression<T> Function($$ReflectionEntriesTableAnnotationComposer a) f,
  ) {
    final $$ReflectionEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reflectionEntries,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReflectionEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.reflectionEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ReflectionTemplatesTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $ReflectionTemplatesTable,
          ReflectionTemplate,
          $$ReflectionTemplatesTableFilterComposer,
          $$ReflectionTemplatesTableOrderingComposer,
          $$ReflectionTemplatesTableAnnotationComposer,
          $$ReflectionTemplatesTableCreateCompanionBuilder,
          $$ReflectionTemplatesTableUpdateCompanionBuilder,
          (ReflectionTemplate, $$ReflectionTemplatesTableReferences),
          ReflectionTemplate,
          PrefetchHooks Function({bool reflectionEntriesRefs})
        > {
  $$ReflectionTemplatesTableTableManager(
    _$ZennoDatabase db,
    $ReflectionTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionTemplatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReflectionTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<String> schemaJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionTemplatesCompanion(
                id: id,
                name: name,
                description: description,
                isBuiltin: isBuiltin,
                schemaJson: schemaJson,
                createdAt: createdAt,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                required String schemaJson,
                required DateTime createdAt,
                required double position,
                Value<int> rowid = const Value.absent(),
              }) => ReflectionTemplatesCompanion.insert(
                id: id,
                name: name,
                description: description,
                isBuiltin: isBuiltin,
                schemaJson: schemaJson,
                createdAt: createdAt,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReflectionTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reflectionEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (reflectionEntriesRefs) db.reflectionEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reflectionEntriesRefs)
                    await $_getPrefetchedData<
                      ReflectionTemplate,
                      $ReflectionTemplatesTable,
                      ReflectionEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ReflectionTemplatesTableReferences
                          ._reflectionEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ReflectionTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).reflectionEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReflectionTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $ReflectionTemplatesTable,
      ReflectionTemplate,
      $$ReflectionTemplatesTableFilterComposer,
      $$ReflectionTemplatesTableOrderingComposer,
      $$ReflectionTemplatesTableAnnotationComposer,
      $$ReflectionTemplatesTableCreateCompanionBuilder,
      $$ReflectionTemplatesTableUpdateCompanionBuilder,
      (ReflectionTemplate, $$ReflectionTemplatesTableReferences),
      ReflectionTemplate,
      PrefetchHooks Function({bool reflectionEntriesRefs})
    >;
typedef $$ReflectionEntriesTableCreateCompanionBuilder =
    ReflectionEntriesCompanion Function({
      required String id,
      required String cardId,
      required String templateId,
      required String templateNameSnapshot,
      required String templateSchemaSnapshotJson,
      required String answersJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReflectionEntriesTableUpdateCompanionBuilder =
    ReflectionEntriesCompanion Function({
      Value<String> id,
      Value<String> cardId,
      Value<String> templateId,
      Value<String> templateNameSnapshot,
      Value<String> templateSchemaSnapshotJson,
      Value<String> answersJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReflectionEntriesTableReferences
    extends
        BaseReferences<
          _$ZennoDatabase,
          $ReflectionEntriesTable,
          ReflectionEntry
        > {
  $$ReflectionEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BoardCardsTable _cardIdTable(_$ZennoDatabase db) =>
      db.boardCards.createAlias(
        $_aliasNameGenerator(db.reflectionEntries.cardId, db.boardCards.id),
      );

  $$BoardCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$BoardCardsTableTableManager(
      $_db,
      $_db.boardCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ReflectionTemplatesTable _templateIdTable(_$ZennoDatabase db) =>
      db.reflectionTemplates.createAlias(
        $_aliasNameGenerator(
          db.reflectionEntries.templateId,
          db.reflectionTemplates.id,
        ),
      );

  $$ReflectionTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$ReflectionTemplatesTableTableManager(
      $_db,
      $_db.reflectionTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReflectionEntriesTableFilterComposer
    extends Composer<_$ZennoDatabase, $ReflectionEntriesTable> {
  $$ReflectionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateSchemaSnapshotJson => $composableBuilder(
    column: $table.templateSchemaSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardCardsTableFilterComposer get cardId {
    final $$BoardCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableFilterComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReflectionTemplatesTableFilterComposer get templateId {
    final $$ReflectionTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.reflectionTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.reflectionTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionEntriesTableOrderingComposer
    extends Composer<_$ZennoDatabase, $ReflectionEntriesTable> {
  $$ReflectionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateSchemaSnapshotJson => $composableBuilder(
    column: $table.templateSchemaSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardCardsTableOrderingComposer get cardId {
    final $$BoardCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableOrderingComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReflectionTemplatesTableOrderingComposer get templateId {
    final $$ReflectionTemplatesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateId,
          referencedTable: $db.reflectionTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReflectionTemplatesTableOrderingComposer(
                $db: $db,
                $table: $db.reflectionTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReflectionEntriesTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $ReflectionEntriesTable> {
  $$ReflectionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateSchemaSnapshotJson => $composableBuilder(
    column: $table.templateSchemaSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BoardCardsTableAnnotationComposer get cardId {
    final $$BoardCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.boardCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boardCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReflectionTemplatesTableAnnotationComposer get templateId {
    final $$ReflectionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateId,
          referencedTable: $db.reflectionTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReflectionTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.reflectionTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReflectionEntriesTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $ReflectionEntriesTable,
          ReflectionEntry,
          $$ReflectionEntriesTableFilterComposer,
          $$ReflectionEntriesTableOrderingComposer,
          $$ReflectionEntriesTableAnnotationComposer,
          $$ReflectionEntriesTableCreateCompanionBuilder,
          $$ReflectionEntriesTableUpdateCompanionBuilder,
          (ReflectionEntry, $$ReflectionEntriesTableReferences),
          ReflectionEntry,
          PrefetchHooks Function({bool cardId, bool templateId})
        > {
  $$ReflectionEntriesTableTableManager(
    _$ZennoDatabase db,
    $ReflectionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReflectionEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> templateNameSnapshot = const Value.absent(),
                Value<String> templateSchemaSnapshotJson = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionEntriesCompanion(
                id: id,
                cardId: cardId,
                templateId: templateId,
                templateNameSnapshot: templateNameSnapshot,
                templateSchemaSnapshotJson: templateSchemaSnapshotJson,
                answersJson: answersJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required String templateId,
                required String templateNameSnapshot,
                required String templateSchemaSnapshotJson,
                required String answersJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReflectionEntriesCompanion.insert(
                id: id,
                cardId: cardId,
                templateId: templateId,
                templateNameSnapshot: templateNameSnapshot,
                templateSchemaSnapshotJson: templateSchemaSnapshotJson,
                answersJson: answersJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReflectionEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false, templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable:
                                    $$ReflectionEntriesTableReferences
                                        ._cardIdTable(db),
                                referencedColumn:
                                    $$ReflectionEntriesTableReferences
                                        ._cardIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable:
                                    $$ReflectionEntriesTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$ReflectionEntriesTableReferences
                                        ._templateIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReflectionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $ReflectionEntriesTable,
      ReflectionEntry,
      $$ReflectionEntriesTableFilterComposer,
      $$ReflectionEntriesTableOrderingComposer,
      $$ReflectionEntriesTableAnnotationComposer,
      $$ReflectionEntriesTableCreateCompanionBuilder,
      $$ReflectionEntriesTableUpdateCompanionBuilder,
      (ReflectionEntry, $$ReflectionEntriesTableReferences),
      ReflectionEntry,
      PrefetchHooks Function({bool cardId, bool templateId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<ThemeModeSetting> themeMode,
      Value<int> defaultPomodoroWorkSecs,
      Value<int> defaultPomodoroBreakSecs,
      Value<double> defaultFlowBreakRatio,
      Value<int> defaultSessionLengthSecs,
      Value<bool> keepScreenOnInFocus,
      Value<LibrarySort> librarySort,
      Value<bool> onboardingDone,
      Value<bool> dbSchemaSeeded,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<ThemeModeSetting> themeMode,
      Value<int> defaultPomodoroWorkSecs,
      Value<int> defaultPomodoroBreakSecs,
      Value<double> defaultFlowBreakRatio,
      Value<int> defaultSessionLengthSecs,
      Value<bool> keepScreenOnInFocus,
      Value<LibrarySort> librarySort,
      Value<bool> onboardingDone,
      Value<bool> dbSchemaSeeded,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$ZennoDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ThemeModeSetting, ThemeModeSetting, int>
  get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get defaultPomodoroWorkSecs => $composableBuilder(
    column: $table.defaultPomodoroWorkSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultPomodoroBreakSecs => $composableBuilder(
    column: $table.defaultPomodoroBreakSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultFlowBreakRatio => $composableBuilder(
    column: $table.defaultFlowBreakRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultSessionLengthSecs => $composableBuilder(
    column: $table.defaultSessionLengthSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get keepScreenOnInFocus => $composableBuilder(
    column: $table.keepScreenOnInFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LibrarySort, LibrarySort, int>
  get librarySort => $composableBuilder(
    column: $table.librarySort,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dbSchemaSeeded => $composableBuilder(
    column: $table.dbSchemaSeeded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$ZennoDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultPomodoroWorkSecs => $composableBuilder(
    column: $table.defaultPomodoroWorkSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultPomodoroBreakSecs => $composableBuilder(
    column: $table.defaultPomodoroBreakSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultFlowBreakRatio => $composableBuilder(
    column: $table.defaultFlowBreakRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultSessionLengthSecs => $composableBuilder(
    column: $table.defaultSessionLengthSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get keepScreenOnInFocus => $composableBuilder(
    column: $table.keepScreenOnInFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get librarySort => $composableBuilder(
    column: $table.librarySort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dbSchemaSeeded => $composableBuilder(
    column: $table.dbSchemaSeeded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$ZennoDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ThemeModeSetting, int> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get defaultPomodoroWorkSecs => $composableBuilder(
    column: $table.defaultPomodoroWorkSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultPomodoroBreakSecs => $composableBuilder(
    column: $table.defaultPomodoroBreakSecs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultFlowBreakRatio => $composableBuilder(
    column: $table.defaultFlowBreakRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultSessionLengthSecs => $composableBuilder(
    column: $table.defaultSessionLengthSecs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get keepScreenOnInFocus => $composableBuilder(
    column: $table.keepScreenOnInFocus,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LibrarySort, int> get librarySort =>
      $composableBuilder(
        column: $table.librarySort,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dbSchemaSeeded => $composableBuilder(
    column: $table.dbSchemaSeeded,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$ZennoDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$ZennoDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$ZennoDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ThemeModeSetting> themeMode = const Value.absent(),
                Value<int> defaultPomodoroWorkSecs = const Value.absent(),
                Value<int> defaultPomodoroBreakSecs = const Value.absent(),
                Value<double> defaultFlowBreakRatio = const Value.absent(),
                Value<int> defaultSessionLengthSecs = const Value.absent(),
                Value<bool> keepScreenOnInFocus = const Value.absent(),
                Value<LibrarySort> librarySort = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> dbSchemaSeeded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                themeMode: themeMode,
                defaultPomodoroWorkSecs: defaultPomodoroWorkSecs,
                defaultPomodoroBreakSecs: defaultPomodoroBreakSecs,
                defaultFlowBreakRatio: defaultFlowBreakRatio,
                defaultSessionLengthSecs: defaultSessionLengthSecs,
                keepScreenOnInFocus: keepScreenOnInFocus,
                librarySort: librarySort,
                onboardingDone: onboardingDone,
                dbSchemaSeeded: dbSchemaSeeded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ThemeModeSetting> themeMode = const Value.absent(),
                Value<int> defaultPomodoroWorkSecs = const Value.absent(),
                Value<int> defaultPomodoroBreakSecs = const Value.absent(),
                Value<double> defaultFlowBreakRatio = const Value.absent(),
                Value<int> defaultSessionLengthSecs = const Value.absent(),
                Value<bool> keepScreenOnInFocus = const Value.absent(),
                Value<LibrarySort> librarySort = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> dbSchemaSeeded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                defaultPomodoroWorkSecs: defaultPomodoroWorkSecs,
                defaultPomodoroBreakSecs: defaultPomodoroBreakSecs,
                defaultFlowBreakRatio: defaultFlowBreakRatio,
                defaultSessionLengthSecs: defaultSessionLengthSecs,
                keepScreenOnInFocus: keepScreenOnInFocus,
                librarySort: librarySort,
                onboardingDone: onboardingDone,
                dbSchemaSeeded: dbSchemaSeeded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZennoDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$ZennoDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $ZennoDatabaseManager {
  final _$ZennoDatabase _db;
  $ZennoDatabaseManager(this._db);
  $$CanvasFoldersTableTableManager get canvasFolders =>
      $$CanvasFoldersTableTableManager(_db, _db.canvasFolders);
  $$CanvasesTableTableManager get canvases =>
      $$CanvasesTableTableManager(_db, _db.canvases);
  $$CanvasElementsTableTableManager get canvasElements =>
      $$CanvasElementsTableTableManager(_db, _db.canvasElements);
  $$InkStrokesTableTableManager get inkStrokes =>
      $$InkStrokesTableTableManager(_db, _db.inkStrokes);
  $$PdfDocumentsTableTableManager get pdfDocuments =>
      $$PdfDocumentsTableTableManager(_db, _db.pdfDocuments);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$CanvasLinksTableTableManager get canvasLinks =>
      $$CanvasLinksTableTableManager(_db, _db.canvasLinks);
  $$RitualChecklistsTableTableManager get ritualChecklists =>
      $$RitualChecklistsTableTableManager(_db, _db.ritualChecklists);
  $$RitualChecklistItemsTableTableManager get ritualChecklistItems =>
      $$RitualChecklistItemsTableTableManager(_db, _db.ritualChecklistItems);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$FocusSessionRitualChecksTableTableManager get focusSessionRitualChecks =>
      $$FocusSessionRitualChecksTableTableManager(
        _db,
        _db.focusSessionRitualChecks,
      );
  $$DistractionsTableTableManager get distractions =>
      $$DistractionsTableTableManager(_db, _db.distractions);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db, _db.boards);
  $$BoardColumnsTableTableManager get boardColumns =>
      $$BoardColumnsTableTableManager(_db, _db.boardColumns);
  $$BoardCardsTableTableManager get boardCards =>
      $$BoardCardsTableTableManager(_db, _db.boardCards);
  $$RevisionCardDetailsTableTableManager get revisionCardDetails =>
      $$RevisionCardDetailsTableTableManager(_db, _db.revisionCardDetails);
  $$GoalCardDetailsTableTableManager get goalCardDetails =>
      $$GoalCardDetailsTableTableManager(_db, _db.goalCardDetails);
  $$ReflectionTemplatesTableTableManager get reflectionTemplates =>
      $$ReflectionTemplatesTableTableManager(_db, _db.reflectionTemplates);
  $$ReflectionEntriesTableTableManager get reflectionEntries =>
      $$ReflectionEntriesTableTableManager(_db, _db.reflectionEntries);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
