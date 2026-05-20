import 'dart:convert';

enum NoteType {
  plain,
  checklist,
  reminder,
  pinned,
  temporary;

  String toJson() => name;
  static NoteType fromJson(String value) {
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.plain,
    );
  }
}

class ChecklistItem {
  final String id;
  final String noteId;
  final String text;
  final bool checked;
  final int indent;

  ChecklistItem({
    required this.id,
    required this.noteId,
    required this.text,
    required this.checked,
    this.indent = 0,
  });

  ChecklistItem copyWith({
    String? id,
    String? noteId,
    String? text,
    bool? checked,
    int? indent,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      text: text ?? this.text,
      checked: checked ?? this.checked,
      indent: indent ?? this.indent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'text': text,
      'checked': checked ? 1 : 0,
      'indent': indent,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      text: map['text'] as String,
      checked: (map['checked'] as int) == 1,
      indent: map['indent'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory ChecklistItem.fromJson(String source) =>
      ChecklistItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Note {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final String color;
  final String icon;
  final double opacity;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final bool isDocked;
  final bool isLocked;
  final int bubbleSize;
  final String bubbleShape;
  final String folder;
  final int createdAt;
  final int updatedAt;
  final List<ChecklistItem> checklistItems;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.color,
    required this.icon,
    required this.opacity,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.isDocked,
    required this.isLocked,
    this.bubbleSize = 60,
    this.bubbleShape = 'circle',
    this.folder = '',
    required this.createdAt,
    required this.updatedAt,
    this.checklistItems = const [],
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    String? color,
    String? icon,
    double? opacity,
    double? posX,
    double? posY,
    double? width,
    double? height,
    bool? isDocked,
    bool? isLocked,
    int? bubbleSize,
    String? bubbleShape,
    String? folder,
    int? createdAt,
    int? updatedAt,
    List<ChecklistItem>? checklistItems,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      opacity: opacity ?? this.opacity,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      isDocked: isDocked ?? this.isDocked,
      isLocked: isLocked ?? this.isLocked,
      bubbleSize: bubbleSize ?? this.bubbleSize,
      bubbleShape: bubbleShape ?? this.bubbleShape,
      folder: folder ?? this.folder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toJson(),
      'color': color,
      'icon': icon,
      'opacity': opacity,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
      'isDocked': isDocked ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'bubbleSize': bubbleSize,
      'bubbleShape': bubbleShape,
      'folder': folder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, {List<ChecklistItem> checklistItems = const []}) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      type: NoteType.fromJson(map['type'] as String),
      color: map['color'] as String,
      icon: map['icon'] as String,
      opacity: (map['opacity'] as num).toDouble(),
      posX: (map['posX'] as num).toDouble(),
      posY: (map['posY'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      isDocked: (map['isDocked'] as int) == 1,
      isLocked: (map['isLocked'] as int) == 1,
      bubbleSize: map['bubbleSize'] as int? ?? 60,
      bubbleShape: map['bubbleShape'] as String? ?? 'circle',
      folder: map['folder'] as String? ?? '',
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      checklistItems: checklistItems,
    );
  }

  String toJson() => json.encode(toMap());
}
