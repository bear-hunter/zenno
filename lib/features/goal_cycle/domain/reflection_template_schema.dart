/// The reflective-framework schema model: an ordered list of prompts that a
/// reflection template asks the user to fill in.
///
/// Pure Dart — no Flutter, no Drift, no codegen. It is the in-memory shape of
/// the `reflection_templates.schema_json` TEXT column (and of the schema
/// snapshot stored on every `reflection_entries` row), parsed with
/// `dart:convert`.
library;

import 'dart:convert';

/// One labelled question inside a [ReflectionTemplateSchema].
///
/// Mirrors a single `{key, label, hint, multiline}` object in the JSON array.
/// [key] is the stable identifier an answer is keyed by; [label] is the visible
/// field caption; [hint] is optional placeholder text; [multiline] flags a
/// long-form field.
class ReflectionPrompt {
  /// Creates a prompt.
  const ReflectionPrompt({
    required this.key,
    required this.label,
    this.hint = '',
    this.multiline = true,
  });

  /// Builds a prompt from one decoded JSON object.
  ///
  /// Missing or wrong-typed fields fall back to safe defaults so a slightly
  /// malformed (or older) schema still parses rather than throwing.
  factory ReflectionPrompt.fromJson(Map<String, dynamic> json) {
    return ReflectionPrompt(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      hint: (json['hint'] as String?) ?? '',
      multiline: (json['multiline'] as bool?) ?? true,
    );
  }

  /// Stable identifier — an answer in `answers_json` is keyed by this.
  final String key;

  /// Visible field caption shown above the input.
  final String label;

  /// Optional placeholder / helper text.
  final String hint;

  /// Whether the answer field should be a multi-line text area.
  final bool multiline;

  /// Encodes this prompt back to its JSON-object form.
  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'hint': hint,
    'multiline': multiline,
  };

  /// Returns a copy with the given fields replaced.
  ReflectionPrompt copyWith({
    String? key,
    String? label,
    String? hint,
    bool? multiline,
  }) {
    return ReflectionPrompt(
      key: key ?? this.key,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      multiline: multiline ?? this.multiline,
    );
  }
}

/// The full ordered prompt list of a reflection template.
///
/// Constructed by parsing a `schema_json` string, and serialised back when a
/// custom template is saved or when an entry snapshots its template.
class ReflectionTemplateSchema {
  /// Creates a schema from an ordered [prompts] list.
  const ReflectionTemplateSchema({required this.prompts});

  /// An empty schema — a convenient starting point for a new custom template.
  static const ReflectionTemplateSchema empty = ReflectionTemplateSchema(
    prompts: [],
  );

  /// Parses a `schema_json` TEXT value (a JSON array of prompt objects).
  ///
  /// An empty or blank string yields [empty]. A value that is not a JSON
  /// array, or whose elements are not objects, is treated as empty rather
  /// than throwing — the UI then simply shows no prompts.
  factory ReflectionTemplateSchema.fromJsonString(String source) {
    if (source.trim().isEmpty) return empty;

    final decoded = jsonDecode(source);
    if (decoded is! List) return empty;

    return ReflectionTemplateSchema(
      prompts: [
        for (final item in decoded)
          if (item is Map<String, dynamic>) ReflectionPrompt.fromJson(item),
      ],
    );
  }

  /// The prompts, in display order.
  final List<ReflectionPrompt> prompts;

  /// Whether this schema has no prompts.
  bool get isEmpty => prompts.isEmpty;

  /// Encodes the schema to its `schema_json` TEXT representation.
  String toJsonString() {
    return jsonEncode([for (final p in prompts) p.toJson()]);
  }

  /// Returns a copy with a different [prompts] list.
  ReflectionTemplateSchema copyWith({List<ReflectionPrompt>? prompts}) {
    return ReflectionTemplateSchema(prompts: prompts ?? this.prompts);
  }
}

/// Decodes an `answers_json` TEXT value (`{promptKey: text}`) to a map.
///
/// A blank string, a non-object payload, or non-string values are tolerated:
/// the result only ever contains `String → String` pairs, defaulting to an
/// empty map. Pure-Dart helper kept beside the schema model it pairs with.
Map<String, String> reflectionAnswersFromJsonString(String source) {
  if (source.trim().isEmpty) return <String, String>{};

  final decoded = jsonDecode(source);
  if (decoded is! Map) return <String, String>{};

  return {
    for (final entry in decoded.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

/// Encodes an `{promptKey: text}` answer map to its `answers_json` TEXT form.
String reflectionAnswersToJsonString(Map<String, String> answers) {
  return jsonEncode(answers);
}
