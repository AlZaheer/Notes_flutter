import 'package:flutter/material.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final Color color;
  final String category;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.color,
    required this.category,
  });
}
