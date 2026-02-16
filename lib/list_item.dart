import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'checklist_item.dart';

enum SortMethod { custom, alphabetical, byDate }

class ListItem {
  final String id;
  final String title;
  final String summary;
  final DateTime lastModified;
  final List<ChecklistItem> checklist;
  final int? backgroundColor;
  final String? backgroundImagePath;

  ListItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.lastModified,
    this.checklist = const [],
    this.backgroundColor,
    this.backgroundImagePath,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'],
      title: json['title'],
      summary: json['summary'] ?? '',
      lastModified: DateTime.parse(json['lastModified']),
      checklist: (json['checklist'] as List?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      backgroundColor: json['backgroundColor'],
      backgroundImagePath: json['backgroundImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'lastModified': lastModified.toIso8601String(),
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'backgroundColor': backgroundColor,
      'backgroundImagePath': backgroundImagePath,
    };
  }

  // Helper to get a Quill Document from the summary string
  Document get document {
    try {
      if (summary.trim().startsWith('[') && summary.trim().endsWith(']')) {
        final decoded = jsonDecode(summary);
        if (decoded is List) {
            // The delta is already a list of maps, so we can pass it directly
            return Document.fromJson(decoded);
        } 
      }
    } catch (e) {
      // Not a valid JSON, so treat it as plain text.
    } 
    // For plain text summaries or errors in JSON parsing, create a simple delta.
    return Document()..insert(0, summary);
  }
}
