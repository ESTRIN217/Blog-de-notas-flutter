import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

class ChecklistItem {
  final String id;
  String text;
  bool isChecked;

  ChecklistItem({
    required this.id,
    this.text = '',
    this.isChecked = false,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      text: json['text'] ?? '',
      isChecked: json['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
    };
  }

  Document get document {
    try {
       if (text.trim().startsWith('[') && text.trim().endsWith(']')) {
        final decoded = jsonDecode(text);
        if (decoded is List) {
            return Document.fromJson(decoded);
        } 
      }
    } catch (e) {
      // Not a valid JSON, treat as plain text.
    }
    return Document()..insert(0, text);
  }
}
