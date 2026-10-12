import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A plot the farmer tracks over a season.
class FarmField {
  const FarmField({
    required this.id,
    required this.name,
    required this.crop,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String crop;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'crop': crop,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FarmField.fromJson(Map<String, dynamic> json) => FarmField(
        id: json['id'] as String,
        name: json['name'] as String,
        crop: json['crop'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// One check of a field: the photo plus what the diagnosis said about it.
class FieldEntry {
  const FieldEntry({
    required this.id,
    required this.fieldId,
    required this.timestamp,
    this.photoName,
    this.problem,
    this.confidence,
  });

  final String id;
  final String fieldId;
  final DateTime timestamp;

  /// File name inside the photos directory, or null for a Lite-mode check
  /// saved without a photo. Stored relative, not absolute: iOS moves the
  /// app container between updates.
  final String? photoName;
  final String? problem;

  /// 'low' / 'medium' / 'high', when the diagnosis gave one.
  final String? confidence;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fieldId': fieldId,
        'timestamp': timestamp.toIso8601String(),
        'photoName': photoName,
        'problem': problem,
        'confidence': confidence,
      };

  factory FieldEntry.fromJson(Map<String, dynamic> json) => FieldEntry(
        id: json['id'] as String,
        fieldId: json['fieldId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        photoName: json['photoName'] as String?,
        problem: json['problem'] as String?,
        confidence: json['confidence'] as String?,
      );
}

/// On-device store for fields and their photo history. Never synced: field
/// names and photos could identify a farmer, so they stay on the phone.
class FieldStore extends ChangeNotifier {
  FieldStore._();
  static final FieldStore instance = FieldStore._();

  final List<FarmField> _fields = [];
  final List<FieldEntry> _entries = [];
  late final Directory _photoDir;
  late final File _file;
  bool _loaded = false;

  /// Fields, most recently active first.
  List<FarmField> get fields {
    DateTime lastActivity(FarmField f) =>
        latestEntry(f.id)?.timestamp ?? f.createdAt;
    return [..._fields]..sort((a, b) => lastActivity(b).compareTo(lastActivity(a)));
  }

  FarmField? field(String id) {
    for (final f in _fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// A field's checks, oldest first.
  List<FieldEntry> entriesFor(String fieldId) =>
      _entries.where((e) => e.fieldId == fieldId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  FieldEntry? latestEntry(String fieldId) {
    final entries = entriesFor(fieldId);
    return entries.isEmpty ? null : entries.last;
  }

  File? photoFile(FieldEntry entry) => entry.photoName == null
      ? null
      : File('${_photoDir.path}/${entry.photoName}');

  /// The field's checks that have photos, oldest first — for "then and now".
  List<FieldEntry> photoEntriesFor(String fieldId) =>
      entriesFor(fieldId).where((e) => e.photoName != null).toList();

  Future<void> load() async {
    if (_loaded) return;
    final docs = await getApplicationDocumentsDirectory();
    _photoDir = Directory('${docs.path}/field_photos');
    await _photoDir.create(recursive: true);
    _file = File('${docs.path}/fields.json');
    if (await _file.exists()) {
      try {
        final raw = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
        _fields.addAll((raw['fields'] as List)
            .map((e) => FarmField.fromJson(e as Map<String, dynamic>)));
        _entries.addAll((raw['entries'] as List)
            .map((e) => FieldEntry.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Corrupt file: start empty rather than crash the app.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _file.writeAsString(jsonEncode({
      'fields': _fields.map((f) => f.toJson()).toList(),
      'entries': _entries.map((e) => e.toJson()).toList(),
    }));
    notifyListeners();
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<FarmField> addField({required String name, required String crop}) async {
    final field = FarmField(
      id: _newId(),
      name: name.trim(),
      crop: crop.trim(),
      createdAt: DateTime.now(),
    );
    _fields.add(field);
    await _save();
    return field;
  }

  Future<void> deleteField(String fieldId) async {
    for (final entry in entriesFor(fieldId)) {
      final photo = photoFile(entry);
      if (photo != null && await photo.exists()) await photo.delete();
    }
    _entries.removeWhere((e) => e.fieldId == fieldId);
    _fields.removeWhere((f) => f.id == fieldId);
    await _save();
  }

  Future<FieldEntry> addEntry({
    required String fieldId,
    Uint8List? photo,
    String? problem,
    String? confidence,
    DateTime? timestamp,
  }) async {
    final id = _newId();
    final entry = FieldEntry(
      id: id,
      fieldId: fieldId,
      timestamp: timestamp ?? DateTime.now(),
      photoName: photo == null ? null : '$id.jpg',
      problem: problem,
      confidence: confidence,
    );
    if (photo != null) await photoFile(entry)!.writeAsBytes(photo);
    _entries.add(entry);
    await _save();
    return entry;
  }
}
