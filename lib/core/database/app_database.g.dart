// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backgroundTypeMeta =
      const VerificationMeta('backgroundType');
  @override
  late final GeneratedColumn<String> backgroundType = GeneratedColumn<String>(
      'background_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backgroundValueMeta =
      const VerificationMeta('backgroundValue');
  @override
  late final GeneratedColumn<String> backgroundValue = GeneratedColumn<String>(
      'background_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fontFamilyMeta =
      const VerificationMeta('fontFamily');
  @override
  late final GeneratedColumn<String> fontFamily = GeneratedColumn<String>(
      'font_family', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lineSpacingMeta =
      const VerificationMeta('lineSpacing');
  @override
  late final GeneratedColumn<double> lineSpacing = GeneratedColumn<double>(
      'line_spacing', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.5));
  static const VerificationMeta _marginHorizontalMeta =
      const VerificationMeta('marginHorizontal');
  @override
  late final GeneratedColumn<double> marginHorizontal = GeneratedColumn<double>(
      'margin_horizontal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(16.0));
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        backgroundType,
        backgroundValue,
        fontFamily,
        lineSpacing,
        marginHorizontal,
        isCustom
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<Template> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('background_type')) {
      context.handle(
          _backgroundTypeMeta,
          backgroundType.isAcceptableOrUnknown(
              data['background_type']!, _backgroundTypeMeta));
    } else if (isInserting) {
      context.missing(_backgroundTypeMeta);
    }
    if (data.containsKey('background_value')) {
      context.handle(
          _backgroundValueMeta,
          backgroundValue.isAcceptableOrUnknown(
              data['background_value']!, _backgroundValueMeta));
    } else if (isInserting) {
      context.missing(_backgroundValueMeta);
    }
    if (data.containsKey('font_family')) {
      context.handle(
          _fontFamilyMeta,
          fontFamily.isAcceptableOrUnknown(
              data['font_family']!, _fontFamilyMeta));
    }
    if (data.containsKey('line_spacing')) {
      context.handle(
          _lineSpacingMeta,
          lineSpacing.isAcceptableOrUnknown(
              data['line_spacing']!, _lineSpacingMeta));
    }
    if (data.containsKey('margin_horizontal')) {
      context.handle(
          _marginHorizontalMeta,
          marginHorizontal.isAcceptableOrUnknown(
              data['margin_horizontal']!, _marginHorizontalMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      backgroundType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}background_type'])!,
      backgroundValue: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}background_value'])!,
      fontFamily: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}font_family']),
      lineSpacing: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}line_spacing'])!,
      marginHorizontal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}margin_horizontal'])!,
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  /// Unique template identifier (e.g., 'template_minimalist_white')
  final String id;

  /// Human-readable template name
  final String name;

  /// Template background style: 'color', 'paper_texture', 'grid', 'lined'
  final String backgroundType;

  /// Value for background: hex color code (e.g., '#FFFFFF') or asset key
  final String backgroundValue;

  /// Font family (null defaults to system font)
  final String? fontFamily;

  /// Line height multiplier (e.g., 1.5, 1.8)
  final double lineSpacing;

  /// Horizontal page margins in logical pixels
  final double marginHorizontal;

  /// Flag indicating user-customized template vs system preset
  final bool isCustom;
  const Template(
      {required this.id,
      required this.name,
      required this.backgroundType,
      required this.backgroundValue,
      this.fontFamily,
      required this.lineSpacing,
      required this.marginHorizontal,
      required this.isCustom});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['background_type'] = Variable<String>(backgroundType);
    map['background_value'] = Variable<String>(backgroundValue);
    if (!nullToAbsent || fontFamily != null) {
      map['font_family'] = Variable<String>(fontFamily);
    }
    map['line_spacing'] = Variable<double>(lineSpacing);
    map['margin_horizontal'] = Variable<double>(marginHorizontal);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      backgroundType: Value(backgroundType),
      backgroundValue: Value(backgroundValue),
      fontFamily: fontFamily == null && nullToAbsent
          ? const Value.absent()
          : Value(fontFamily),
      lineSpacing: Value(lineSpacing),
      marginHorizontal: Value(marginHorizontal),
      isCustom: Value(isCustom),
    );
  }

  factory Template.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      backgroundType: serializer.fromJson<String>(json['backgroundType']),
      backgroundValue: serializer.fromJson<String>(json['backgroundValue']),
      fontFamily: serializer.fromJson<String?>(json['fontFamily']),
      lineSpacing: serializer.fromJson<double>(json['lineSpacing']),
      marginHorizontal: serializer.fromJson<double>(json['marginHorizontal']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'backgroundType': serializer.toJson<String>(backgroundType),
      'backgroundValue': serializer.toJson<String>(backgroundValue),
      'fontFamily': serializer.toJson<String?>(fontFamily),
      'lineSpacing': serializer.toJson<double>(lineSpacing),
      'marginHorizontal': serializer.toJson<double>(marginHorizontal),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  Template copyWith(
          {String? id,
          String? name,
          String? backgroundType,
          String? backgroundValue,
          Value<String?> fontFamily = const Value.absent(),
          double? lineSpacing,
          double? marginHorizontal,
          bool? isCustom}) =>
      Template(
        id: id ?? this.id,
        name: name ?? this.name,
        backgroundType: backgroundType ?? this.backgroundType,
        backgroundValue: backgroundValue ?? this.backgroundValue,
        fontFamily: fontFamily.present ? fontFamily.value : this.fontFamily,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        marginHorizontal: marginHorizontal ?? this.marginHorizontal,
        isCustom: isCustom ?? this.isCustom,
      );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      backgroundType: data.backgroundType.present
          ? data.backgroundType.value
          : this.backgroundType,
      backgroundValue: data.backgroundValue.present
          ? data.backgroundValue.value
          : this.backgroundValue,
      fontFamily:
          data.fontFamily.present ? data.fontFamily.value : this.fontFamily,
      lineSpacing:
          data.lineSpacing.present ? data.lineSpacing.value : this.lineSpacing,
      marginHorizontal: data.marginHorizontal.present
          ? data.marginHorizontal.value
          : this.marginHorizontal,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('backgroundType: $backgroundType, ')
          ..write('backgroundValue: $backgroundValue, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('marginHorizontal: $marginHorizontal, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, backgroundType, backgroundValue,
      fontFamily, lineSpacing, marginHorizontal, isCustom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.name == this.name &&
          other.backgroundType == this.backgroundType &&
          other.backgroundValue == this.backgroundValue &&
          other.fontFamily == this.fontFamily &&
          other.lineSpacing == this.lineSpacing &&
          other.marginHorizontal == this.marginHorizontal &&
          other.isCustom == this.isCustom);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> backgroundType;
  final Value<String> backgroundValue;
  final Value<String?> fontFamily;
  final Value<double> lineSpacing;
  final Value<double> marginHorizontal;
  final Value<bool> isCustom;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.backgroundType = const Value.absent(),
    this.backgroundValue = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.marginHorizontal = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String name,
    required String backgroundType,
    required String backgroundValue,
    this.fontFamily = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.marginHorizontal = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        backgroundType = Value(backgroundType),
        backgroundValue = Value(backgroundValue);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? backgroundType,
    Expression<String>? backgroundValue,
    Expression<String>? fontFamily,
    Expression<double>? lineSpacing,
    Expression<double>? marginHorizontal,
    Expression<bool>? isCustom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (backgroundType != null) 'background_type': backgroundType,
      if (backgroundValue != null) 'background_value': backgroundValue,
      if (fontFamily != null) 'font_family': fontFamily,
      if (lineSpacing != null) 'line_spacing': lineSpacing,
      if (marginHorizontal != null) 'margin_horizontal': marginHorizontal,
      if (isCustom != null) 'is_custom': isCustom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? backgroundType,
      Value<String>? backgroundValue,
      Value<String?>? fontFamily,
      Value<double>? lineSpacing,
      Value<double>? marginHorizontal,
      Value<bool>? isCustom,
      Value<int>? rowid}) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundValue: backgroundValue ?? this.backgroundValue,
      fontFamily: fontFamily ?? this.fontFamily,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      marginHorizontal: marginHorizontal ?? this.marginHorizontal,
      isCustom: isCustom ?? this.isCustom,
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
    if (backgroundType.present) {
      map['background_type'] = Variable<String>(backgroundType.value);
    }
    if (backgroundValue.present) {
      map['background_value'] = Variable<String>(backgroundValue.value);
    }
    if (fontFamily.present) {
      map['font_family'] = Variable<String>(fontFamily.value);
    }
    if (lineSpacing.present) {
      map['line_spacing'] = Variable<double>(lineSpacing.value);
    }
    if (marginHorizontal.present) {
      map['margin_horizontal'] = Variable<double>(marginHorizontal.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('backgroundType: $backgroundType, ')
          ..write('backgroundValue: $backgroundValue, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('marginHorizontal: $marginHorizontal, ')
          ..write('isCustom: $isCustom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotebooksTable extends Notebooks
    with TableInfo<$NotebooksTable, Notebook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _defaultTemplateIdMeta =
      const VerificationMeta('defaultTemplateId');
  @override
  late final GeneratedColumn<String> defaultTemplateId =
      GeneratedColumn<String>('default_template_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, defaultTemplateId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks';
  @override
  VerificationContext validateIntegrity(Insertable<Notebook> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('default_template_id')) {
      context.handle(
          _defaultTemplateIdMeta,
          defaultTemplateId.isAcceptableOrUnknown(
              data['default_template_id']!, _defaultTemplateIdMeta));
    } else if (isInserting) {
      context.missing(_defaultTemplateIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notebook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notebook(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      defaultTemplateId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_template_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NotebooksTable createAlias(String alias) {
    return $NotebooksTable(attachedDatabase, alias);
  }
}

class Notebook extends DataClass implements Insertable<Notebook> {
  /// Unique notebook UUID or system ID
  final String id;

  /// Notebook display title
  final String title;

  /// Default template used for new entries in this notebook
  final String defaultTemplateId;

  /// Creation timestamp
  final DateTime createdAt;
  const Notebook(
      {required this.id,
      required this.title,
      required this.defaultTemplateId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['default_template_id'] = Variable<String>(defaultTemplateId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      title: Value(title),
      defaultTemplateId: Value(defaultTemplateId),
      createdAt: Value(createdAt),
    );
  }

  factory Notebook.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notebook(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      defaultTemplateId: serializer.fromJson<String>(json['defaultTemplateId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'defaultTemplateId': serializer.toJson<String>(defaultTemplateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Notebook copyWith(
          {String? id,
          String? title,
          String? defaultTemplateId,
          DateTime? createdAt}) =>
      Notebook(
        id: id ?? this.id,
        title: title ?? this.title,
        defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
        createdAt: createdAt ?? this.createdAt,
      );
  Notebook copyWithCompanion(NotebooksCompanion data) {
    return Notebook(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      defaultTemplateId: data.defaultTemplateId.present
          ? data.defaultTemplateId.value
          : this.defaultTemplateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notebook(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, defaultTemplateId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notebook &&
          other.id == this.id &&
          other.title == this.title &&
          other.defaultTemplateId == this.defaultTemplateId &&
          other.createdAt == this.createdAt);
}

class NotebooksCompanion extends UpdateCompanion<Notebook> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> defaultTemplateId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.defaultTemplateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotebooksCompanion.insert({
    required String id,
    required String title,
    required String defaultTemplateId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        defaultTemplateId = Value(defaultTemplateId);
  static Insertable<Notebook> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? defaultTemplateId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (defaultTemplateId != null) 'default_template_id': defaultTemplateId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotebooksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? defaultTemplateId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return NotebooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (defaultTemplateId.present) {
      map['default_template_id'] = Variable<String>(defaultTemplateId.value);
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
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<String> notebookId = GeneratedColumn<String>(
      'notebook_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentDeltaMeta =
      const VerificationMeta('contentDelta');
  @override
  late final GeneratedColumn<String> contentDelta = GeneratedColumn<String>(
      'content_delta', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plainTextMeta =
      const VerificationMeta('plainText');
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
      'plain_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
      'mood', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weatherMeta =
      const VerificationMeta('weather');
  @override
  late final GeneratedColumn<String> weather = GeneratedColumn<String>(
      'weather', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isWeeklyReviewMeta =
      const VerificationMeta('isWeeklyReview');
  @override
  late final GeneratedColumn<bool> isWeeklyReview = GeneratedColumn<bool>(
      'is_weekly_review', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_weekly_review" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _weekNumberMeta =
      const VerificationMeta('weekNumber');
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
      'week_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unlockAtMeta =
      const VerificationMeta('unlockAt');
  @override
  late final GeneratedColumn<DateTime> unlockAt = GeneratedColumn<DateTime>(
      'unlock_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        notebookId,
        templateId,
        title,
        contentDelta,
        plainText,
        entryDate,
        mood,
        weather,
        isWeeklyReview,
        weekNumber,
        unlockAt,
        createdAt,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<Entry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content_delta')) {
      context.handle(
          _contentDeltaMeta,
          contentDelta.isAcceptableOrUnknown(
              data['content_delta']!, _contentDeltaMeta));
    } else if (isInserting) {
      context.missing(_contentDeltaMeta);
    }
    if (data.containsKey('plain_text')) {
      context.handle(_plainTextMeta,
          plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta));
    } else if (isInserting) {
      context.missing(_plainTextMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('weather')) {
      context.handle(_weatherMeta,
          weather.isAcceptableOrUnknown(data['weather']!, _weatherMeta));
    }
    if (data.containsKey('is_weekly_review')) {
      context.handle(
          _isWeeklyReviewMeta,
          isWeeklyReview.isAcceptableOrUnknown(
              data['is_weekly_review']!, _isWeeklyReviewMeta));
    }
    if (data.containsKey('week_number')) {
      context.handle(
          _weekNumberMeta,
          weekNumber.isAcceptableOrUnknown(
              data['week_number']!, _weekNumberMeta));
    }
    if (data.containsKey('unlock_at')) {
      context.handle(_unlockAtMeta,
          unlockAt.isAcceptableOrUnknown(data['unlock_at']!, _unlockAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notebook_id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      contentDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_delta'])!,
      plainText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plain_text'])!,
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}entry_date'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood']),
      weather: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weather']),
      isWeeklyReview: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_weekly_review'])!,
      weekNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}week_number']),
      unlockAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlock_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  /// Unique entry UUID
  final String id;

  /// Foreign key referencing the parent notebook
  final String notebookId;

  /// Foreign key referencing the visual template (presentation layer)
  final String templateId;

  /// Optional entry title
  final String? title;

  /// Rich text semantic content encoded as Flutter Quill Delta JSON
  final String contentDelta;

  /// Plain text representation extracted from Delta, used for full-text search indexing
  final String plainText;

  /// User-selected date for this diary entry (stored as DateTime epoch)
  final DateTime entryDate;

  /// Mood rating (scale 1 to 5)
  final int? mood;

  /// Weather indicator string/tag
  final String? weather;

  /// Whether this entry is flagged as a weekly review
  final bool isWeeklyReview;

  /// ISO week number when entry is a weekly review
  final int? weekNumber;

  /// Timestamp when Time Capsule locks expire (null if immediately accessible)
  final DateTime? unlockAt;

  /// Record creation timestamp
  final DateTime createdAt;

  /// Record last-modified timestamp
  final DateTime updatedAt;

  /// Soft delete flag (0 = active, 1 = in 30-day trash bin)
  final bool isDeleted;
  const Entry(
      {required this.id,
      required this.notebookId,
      required this.templateId,
      this.title,
      required this.contentDelta,
      required this.plainText,
      required this.entryDate,
      this.mood,
      this.weather,
      required this.isWeeklyReview,
      this.weekNumber,
      this.unlockAt,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notebook_id'] = Variable<String>(notebookId);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content_delta'] = Variable<String>(contentDelta);
    map['plain_text'] = Variable<String>(plainText);
    map['entry_date'] = Variable<DateTime>(entryDate);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || weather != null) {
      map['weather'] = Variable<String>(weather);
    }
    map['is_weekly_review'] = Variable<bool>(isWeeklyReview);
    if (!nullToAbsent || weekNumber != null) {
      map['week_number'] = Variable<int>(weekNumber);
    }
    if (!nullToAbsent || unlockAt != null) {
      map['unlock_at'] = Variable<DateTime>(unlockAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      templateId: Value(templateId),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      contentDelta: Value(contentDelta),
      plainText: Value(plainText),
      entryDate: Value(entryDate),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      weather: weather == null && nullToAbsent
          ? const Value.absent()
          : Value(weather),
      isWeeklyReview: Value(isWeeklyReview),
      weekNumber: weekNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(weekNumber),
      unlockAt: unlockAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      notebookId: serializer.fromJson<String>(json['notebookId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      title: serializer.fromJson<String?>(json['title']),
      contentDelta: serializer.fromJson<String>(json['contentDelta']),
      plainText: serializer.fromJson<String>(json['plainText']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      mood: serializer.fromJson<int?>(json['mood']),
      weather: serializer.fromJson<String?>(json['weather']),
      isWeeklyReview: serializer.fromJson<bool>(json['isWeeklyReview']),
      weekNumber: serializer.fromJson<int?>(json['weekNumber']),
      unlockAt: serializer.fromJson<DateTime?>(json['unlockAt']),
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
      'notebookId': serializer.toJson<String>(notebookId),
      'templateId': serializer.toJson<String>(templateId),
      'title': serializer.toJson<String?>(title),
      'contentDelta': serializer.toJson<String>(contentDelta),
      'plainText': serializer.toJson<String>(plainText),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'mood': serializer.toJson<int?>(mood),
      'weather': serializer.toJson<String?>(weather),
      'isWeeklyReview': serializer.toJson<bool>(isWeeklyReview),
      'weekNumber': serializer.toJson<int?>(weekNumber),
      'unlockAt': serializer.toJson<DateTime?>(unlockAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Entry copyWith(
          {String? id,
          String? notebookId,
          String? templateId,
          Value<String?> title = const Value.absent(),
          String? contentDelta,
          String? plainText,
          DateTime? entryDate,
          Value<int?> mood = const Value.absent(),
          Value<String?> weather = const Value.absent(),
          bool? isWeeklyReview,
          Value<int?> weekNumber = const Value.absent(),
          Value<DateTime?> unlockAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      Entry(
        id: id ?? this.id,
        notebookId: notebookId ?? this.notebookId,
        templateId: templateId ?? this.templateId,
        title: title.present ? title.value : this.title,
        contentDelta: contentDelta ?? this.contentDelta,
        plainText: plainText ?? this.plainText,
        entryDate: entryDate ?? this.entryDate,
        mood: mood.present ? mood.value : this.mood,
        weather: weather.present ? weather.value : this.weather,
        isWeeklyReview: isWeeklyReview ?? this.isWeeklyReview,
        weekNumber: weekNumber.present ? weekNumber.value : this.weekNumber,
        unlockAt: unlockAt.present ? unlockAt.value : this.unlockAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      contentDelta: data.contentDelta.present
          ? data.contentDelta.value
          : this.contentDelta,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      mood: data.mood.present ? data.mood.value : this.mood,
      weather: data.weather.present ? data.weather.value : this.weather,
      isWeeklyReview: data.isWeeklyReview.present
          ? data.isWeeklyReview.value
          : this.isWeeklyReview,
      weekNumber:
          data.weekNumber.present ? data.weekNumber.value : this.weekNumber,
      unlockAt: data.unlockAt.present ? data.unlockAt.value : this.unlockAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('contentDelta: $contentDelta, ')
          ..write('plainText: $plainText, ')
          ..write('entryDate: $entryDate, ')
          ..write('mood: $mood, ')
          ..write('weather: $weather, ')
          ..write('isWeeklyReview: $isWeeklyReview, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('unlockAt: $unlockAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      notebookId,
      templateId,
      title,
      contentDelta,
      plainText,
      entryDate,
      mood,
      weather,
      isWeeklyReview,
      weekNumber,
      unlockAt,
      createdAt,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.contentDelta == this.contentDelta &&
          other.plainText == this.plainText &&
          other.entryDate == this.entryDate &&
          other.mood == this.mood &&
          other.weather == this.weather &&
          other.isWeeklyReview == this.isWeeklyReview &&
          other.weekNumber == this.weekNumber &&
          other.unlockAt == this.unlockAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<String> notebookId;
  final Value<String> templateId;
  final Value<String?> title;
  final Value<String> contentDelta;
  final Value<String> plainText;
  final Value<DateTime> entryDate;
  final Value<int?> mood;
  final Value<String?> weather;
  final Value<bool> isWeeklyReview;
  final Value<int?> weekNumber;
  final Value<DateTime?> unlockAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.contentDelta = const Value.absent(),
    this.plainText = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.mood = const Value.absent(),
    this.weather = const Value.absent(),
    this.isWeeklyReview = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.unlockAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String notebookId,
    required String templateId,
    this.title = const Value.absent(),
    required String contentDelta,
    required String plainText,
    required DateTime entryDate,
    this.mood = const Value.absent(),
    this.weather = const Value.absent(),
    this.isWeeklyReview = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.unlockAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        notebookId = Value(notebookId),
        templateId = Value(templateId),
        contentDelta = Value(contentDelta),
        plainText = Value(plainText),
        entryDate = Value(entryDate);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<String>? notebookId,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<String>? contentDelta,
    Expression<String>? plainText,
    Expression<DateTime>? entryDate,
    Expression<int>? mood,
    Expression<String>? weather,
    Expression<bool>? isWeeklyReview,
    Expression<int>? weekNumber,
    Expression<DateTime>? unlockAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (contentDelta != null) 'content_delta': contentDelta,
      if (plainText != null) 'plain_text': plainText,
      if (entryDate != null) 'entry_date': entryDate,
      if (mood != null) 'mood': mood,
      if (weather != null) 'weather': weather,
      if (isWeeklyReview != null) 'is_weekly_review': isWeeklyReview,
      if (weekNumber != null) 'week_number': weekNumber,
      if (unlockAt != null) 'unlock_at': unlockAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? notebookId,
      Value<String>? templateId,
      Value<String?>? title,
      Value<String>? contentDelta,
      Value<String>? plainText,
      Value<DateTime>? entryDate,
      Value<int?>? mood,
      Value<String?>? weather,
      Value<bool>? isWeeklyReview,
      Value<int?>? weekNumber,
      Value<DateTime?>? unlockAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return EntriesCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      contentDelta: contentDelta ?? this.contentDelta,
      plainText: plainText ?? this.plainText,
      entryDate: entryDate ?? this.entryDate,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      isWeeklyReview: isWeeklyReview ?? this.isWeeklyReview,
      weekNumber: weekNumber ?? this.weekNumber,
      unlockAt: unlockAt ?? this.unlockAt,
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
    if (notebookId.present) {
      map['notebook_id'] = Variable<String>(notebookId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contentDelta.present) {
      map['content_delta'] = Variable<String>(contentDelta.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (weather.present) {
      map['weather'] = Variable<String>(weather.value);
    }
    if (isWeeklyReview.present) {
      map['is_weekly_review'] = Variable<bool>(isWeeklyReview.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (unlockAt.present) {
      map['unlock_at'] = Variable<DateTime>(unlockAt.value);
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
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('contentDelta: $contentDelta, ')
          ..write('plainText: $plainText, ')
          ..write('entryDate: $entryDate, ')
          ..write('mood: $mood, ')
          ..write('weather: $weather, ')
          ..write('isWeeklyReview: $isWeeklyReview, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('unlockAt: $unlockAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAttachmentsTable extends MediaAttachments
    with TableInfo<$MediaAttachmentsTable, MediaAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrTextMeta =
      const VerificationMeta('ocrText');
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
      'ocr_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entryId, mediaType, relativePath, thumbnailPath, ocrText, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_attachments';
  @override
  VerificationContext validateIntegrity(Insertable<MediaAttachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('ocr_text')) {
      context.handle(_ocrTextMeta,
          ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAttachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      ocrText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaAttachmentsTable createAlias(String alias) {
    return $MediaAttachmentsTable(attachedDatabase, alias);
  }
}

class MediaAttachment extends DataClass implements Insertable<MediaAttachment> {
  /// Unique media attachment UUID
  final String id;

  /// Foreign key referencing the parent entry
  final String entryId;

  /// Media type: 'image', 'video'
  final String mediaType;

  /// Strictly relative sandboxed path (e.g., 'media/3fa85f64-5717-4562-b3fc-2c963f66afa6.webp')
  final String relativePath;

  /// Optional relative path to generated low-res thumbnail
  final String? thumbnailPath;

  /// Extracted offline OCR text (if processed)
  final String? ocrText;

  /// Attachment creation timestamp
  final DateTime createdAt;
  const MediaAttachment(
      {required this.id,
      required this.entryId,
      required this.mediaType,
      required this.relativePath,
      this.thumbnailPath,
      this.ocrText,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['media_type'] = Variable<String>(mediaType);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MediaAttachmentsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      mediaType: Value(mediaType),
      relativePath: Value(relativePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      createdAt: Value(createdAt),
    );
  }

  factory MediaAttachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAttachment(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'mediaType': serializer.toJson<String>(mediaType),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'ocrText': serializer.toJson<String?>(ocrText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaAttachment copyWith(
          {String? id,
          String? entryId,
          String? mediaType,
          String? relativePath,
          Value<String?> thumbnailPath = const Value.absent(),
          Value<String?> ocrText = const Value.absent(),
          DateTime? createdAt}) =>
      MediaAttachment(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        mediaType: mediaType ?? this.mediaType,
        relativePath: relativePath ?? this.relativePath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        ocrText: ocrText.present ? ocrText.value : this.ocrText,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaAttachment copyWithCompanion(MediaAttachmentsCompanion data) {
    return MediaAttachment(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAttachment(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('mediaType: $mediaType, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('ocrText: $ocrText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entryId, mediaType, relativePath, thumbnailPath, ocrText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAttachment &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.mediaType == this.mediaType &&
          other.relativePath == this.relativePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.ocrText == this.ocrText &&
          other.createdAt == this.createdAt);
}

class MediaAttachmentsCompanion extends UpdateCompanion<MediaAttachment> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> mediaType;
  final Value<String> relativePath;
  final Value<String?> thumbnailPath;
  final Value<String?> ocrText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MediaAttachmentsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAttachmentsCompanion.insert({
    required String id,
    required String entryId,
    required String mediaType,
    required String relativePath,
    this.thumbnailPath = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entryId = Value(entryId),
        mediaType = Value(mediaType),
        relativePath = Value(relativePath);
  static Insertable<MediaAttachment> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? mediaType,
    Expression<String>? relativePath,
    Expression<String>? thumbnailPath,
    Expression<String>? ocrText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (mediaType != null) 'media_type': mediaType,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (ocrText != null) 'ocr_text': ocrText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? entryId,
      Value<String>? mediaType,
      Value<String>? relativePath,
      Value<String?>? thumbnailPath,
      Value<String?>? ocrText,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MediaAttachmentsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      mediaType: mediaType ?? this.mediaType,
      relativePath: relativePath ?? this.relativePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      ocrText: ocrText ?? this.ocrText,
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
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
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
    return (StringBuffer('MediaAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('mediaType: $mediaType, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('ocrText: $ocrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $NotebooksTable notebooks = $NotebooksTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $MediaAttachmentsTable mediaAttachments =
      $MediaAttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [templates, notebooks, entries, mediaAttachments];
}

typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String name,
  required String backgroundType,
  required String backgroundValue,
  Value<String?> fontFamily,
  Value<double> lineSpacing,
  Value<double> marginHorizontal,
  Value<bool> isCustom,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> backgroundType,
  Value<String> backgroundValue,
  Value<String?> fontFamily,
  Value<double> lineSpacing,
  Value<double> marginHorizontal,
  Value<bool> isCustom,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundType => $composableBuilder(
      column: $table.backgroundType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundValue => $composableBuilder(
      column: $table.backgroundValue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lineSpacing => $composableBuilder(
      column: $table.lineSpacing, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get marginHorizontal => $composableBuilder(
      column: $table.marginHorizontal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundType => $composableBuilder(
      column: $table.backgroundType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundValue => $composableBuilder(
      column: $table.backgroundValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lineSpacing => $composableBuilder(
      column: $table.lineSpacing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get marginHorizontal => $composableBuilder(
      column: $table.marginHorizontal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
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

  GeneratedColumn<String> get backgroundType => $composableBuilder(
      column: $table.backgroundType, builder: (column) => column);

  GeneratedColumn<String> get backgroundValue => $composableBuilder(
      column: $table.backgroundValue, builder: (column) => column);

  GeneratedColumn<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => column);

  GeneratedColumn<double> get lineSpacing => $composableBuilder(
      column: $table.lineSpacing, builder: (column) => column);

  GeneratedColumn<double> get marginHorizontal => $composableBuilder(
      column: $table.marginHorizontal, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);
}

class $$TemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDatabase, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()> {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> backgroundType = const Value.absent(),
            Value<String> backgroundValue = const Value.absent(),
            Value<String?> fontFamily = const Value.absent(),
            Value<double> lineSpacing = const Value.absent(),
            Value<double> marginHorizontal = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion(
            id: id,
            name: name,
            backgroundType: backgroundType,
            backgroundValue: backgroundValue,
            fontFamily: fontFamily,
            lineSpacing: lineSpacing,
            marginHorizontal: marginHorizontal,
            isCustom: isCustom,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String backgroundType,
            required String backgroundValue,
            Value<String?> fontFamily = const Value.absent(),
            Value<double> lineSpacing = const Value.absent(),
            Value<double> marginHorizontal = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion.insert(
            id: id,
            name: name,
            backgroundType: backgroundType,
            backgroundValue: backgroundValue,
            fontFamily: fontFamily,
            lineSpacing: lineSpacing,
            marginHorizontal: marginHorizontal,
            isCustom: isCustom,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDatabase, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()>;
typedef $$NotebooksTableCreateCompanionBuilder = NotebooksCompanion Function({
  required String id,
  required String title,
  required String defaultTemplateId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$NotebooksTableUpdateCompanionBuilder = NotebooksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> defaultTemplateId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$NotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultTemplateId => $composableBuilder(
      column: $table.defaultTemplateId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultTemplateId => $composableBuilder(
      column: $table.defaultTemplateId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableAnnotationComposer({
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

  GeneratedColumn<String> get defaultTemplateId => $composableBuilder(
      column: $table.defaultTemplateId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotebooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotebooksTable,
    Notebook,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
    Notebook,
    PrefetchHooks Function()> {
  $$NotebooksTableTableManager(_$AppDatabase db, $NotebooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> defaultTemplateId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotebooksCompanion(
            id: id,
            title: title,
            defaultTemplateId: defaultTemplateId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String defaultTemplateId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotebooksCompanion.insert(
            id: id,
            title: title,
            defaultTemplateId: defaultTemplateId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotebooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotebooksTable,
    Notebook,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
    Notebook,
    PrefetchHooks Function()>;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  required String id,
  required String notebookId,
  required String templateId,
  Value<String?> title,
  required String contentDelta,
  required String plainText,
  required DateTime entryDate,
  Value<int?> mood,
  Value<String?> weather,
  Value<bool> isWeeklyReview,
  Value<int?> weekNumber,
  Value<DateTime?> unlockAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<String> id,
  Value<String> notebookId,
  Value<String> templateId,
  Value<String?> title,
  Value<String> contentDelta,
  Value<String> plainText,
  Value<DateTime> entryDate,
  Value<int?> mood,
  Value<String?> weather,
  Value<bool> isWeeklyReview,
  Value<int?> weekNumber,
  Value<DateTime?> unlockAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentDelta => $composableBuilder(
      column: $table.contentDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weather => $composableBuilder(
      column: $table.weather, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWeeklyReview => $composableBuilder(
      column: $table.isWeeklyReview,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get unlockAt => $composableBuilder(
      column: $table.unlockAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentDelta => $composableBuilder(
      column: $table.contentDelta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weather => $composableBuilder(
      column: $table.weather, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWeeklyReview => $composableBuilder(
      column: $table.isWeeklyReview,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockAt => $composableBuilder(
      column: $table.unlockAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get contentDelta => $composableBuilder(
      column: $table.contentDelta, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => column);

  GeneratedColumn<bool> get isWeeklyReview => $composableBuilder(
      column: $table.isWeeklyReview, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockAt =>
      $composableBuilder(column: $table.unlockAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$EntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
    Entry,
    PrefetchHooks Function()> {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> notebookId = const Value.absent(),
            Value<String> templateId = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> contentDelta = const Value.absent(),
            Value<String> plainText = const Value.absent(),
            Value<DateTime> entryDate = const Value.absent(),
            Value<int?> mood = const Value.absent(),
            Value<String?> weather = const Value.absent(),
            Value<bool> isWeeklyReview = const Value.absent(),
            Value<int?> weekNumber = const Value.absent(),
            Value<DateTime?> unlockAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesCompanion(
            id: id,
            notebookId: notebookId,
            templateId: templateId,
            title: title,
            contentDelta: contentDelta,
            plainText: plainText,
            entryDate: entryDate,
            mood: mood,
            weather: weather,
            isWeeklyReview: isWeeklyReview,
            weekNumber: weekNumber,
            unlockAt: unlockAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String notebookId,
            required String templateId,
            Value<String?> title = const Value.absent(),
            required String contentDelta,
            required String plainText,
            required DateTime entryDate,
            Value<int?> mood = const Value.absent(),
            Value<String?> weather = const Value.absent(),
            Value<bool> isWeeklyReview = const Value.absent(),
            Value<int?> weekNumber = const Value.absent(),
            Value<DateTime?> unlockAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesCompanion.insert(
            id: id,
            notebookId: notebookId,
            templateId: templateId,
            title: title,
            contentDelta: contentDelta,
            plainText: plainText,
            entryDate: entryDate,
            mood: mood,
            weather: weather,
            isWeeklyReview: isWeeklyReview,
            weekNumber: weekNumber,
            unlockAt: unlockAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntriesTable,
    Entry,
    $$EntriesTableFilterComposer,
    $$EntriesTableOrderingComposer,
    $$EntriesTableAnnotationComposer,
    $$EntriesTableCreateCompanionBuilder,
    $$EntriesTableUpdateCompanionBuilder,
    (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
    Entry,
    PrefetchHooks Function()>;
typedef $$MediaAttachmentsTableCreateCompanionBuilder
    = MediaAttachmentsCompanion Function({
  required String id,
  required String entryId,
  required String mediaType,
  required String relativePath,
  Value<String?> thumbnailPath,
  Value<String?> ocrText,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MediaAttachmentsTableUpdateCompanionBuilder
    = MediaAttachmentsCompanion Function({
  Value<String> id,
  Value<String> entryId,
  Value<String> mediaType,
  Value<String> relativePath,
  Value<String?> thumbnailPath,
  Value<String?> ocrText,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MediaAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAttachmentsTable> {
  $$MediaAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MediaAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAttachmentsTable> {
  $$MediaAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAttachmentsTable> {
  $$MediaAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaAttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaAttachmentsTable,
    MediaAttachment,
    $$MediaAttachmentsTableFilterComposer,
    $$MediaAttachmentsTableOrderingComposer,
    $$MediaAttachmentsTableAnnotationComposer,
    $$MediaAttachmentsTableCreateCompanionBuilder,
    $$MediaAttachmentsTableUpdateCompanionBuilder,
    (
      MediaAttachment,
      BaseReferences<_$AppDatabase, $MediaAttachmentsTable, MediaAttachment>
    ),
    MediaAttachment,
    PrefetchHooks Function()> {
  $$MediaAttachmentsTableTableManager(
      _$AppDatabase db, $MediaAttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entryId = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAttachmentsCompanion(
            id: id,
            entryId: entryId,
            mediaType: mediaType,
            relativePath: relativePath,
            thumbnailPath: thumbnailPath,
            ocrText: ocrText,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entryId,
            required String mediaType,
            required String relativePath,
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String?> ocrText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAttachmentsCompanion.insert(
            id: id,
            entryId: entryId,
            mediaType: mediaType,
            relativePath: relativePath,
            thumbnailPath: thumbnailPath,
            ocrText: ocrText,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaAttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaAttachmentsTable,
    MediaAttachment,
    $$MediaAttachmentsTableFilterComposer,
    $$MediaAttachmentsTableOrderingComposer,
    $$MediaAttachmentsTableAnnotationComposer,
    $$MediaAttachmentsTableCreateCompanionBuilder,
    $$MediaAttachmentsTableUpdateCompanionBuilder,
    (
      MediaAttachment,
      BaseReferences<_$AppDatabase, $MediaAttachmentsTable, MediaAttachment>
    ),
    MediaAttachment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db, _db.notebooks);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$MediaAttachmentsTableTableManager get mediaAttachments =>
      $$MediaAttachmentsTableTableManager(_db, _db.mediaAttachments);
}
