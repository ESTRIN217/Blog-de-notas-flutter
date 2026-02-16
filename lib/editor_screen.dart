import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'list_item.dart';
import 'checklist_item.dart';

class EditorScreen extends StatefulWidget {
  final ListItem item;

  const EditorScreen({super.key, required this.item});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  late List<ChecklistItem> _checklistItems;
  final Map<String, quill.QuillController> _checklistControllers = {};

  int? _backgroundColorValue;
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = quill.QuillController(
      document: widget.item.document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _checklistItems = widget.item.checklist.map((item) => 
        ChecklistItem(id: item.id, text: item.text, isChecked: item.isChecked)
    ).toList();

    _backgroundColorValue = widget.item.backgroundColor;
    _backgroundImagePath = widget.item.backgroundImagePath;

    for (var item in _checklistItems) {
      _checklistControllers[item.id] = quill.QuillController(
        document: item.document,
        selection: const TextSelection.collapsed(offset: 0),
      )..addListener(() => _onChecklistItemChanged(item.id));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (var controller in _checklistControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChecklistItemChanged(String itemId) {
    final controller = _checklistControllers[itemId];
    final item = _checklistItems.firstWhere((i) => i.id == itemId);
    if (controller != null) {
      item.text = jsonEncode(controller.document.toDelta().toJson());
    }
  }

  void _saveAndExit() {
    if (!mounted) return;
    final summaryJson = jsonEncode(_contentController.document.toDelta().toJson());

    final updatedItem = ListItem(
      id: widget.item.id,
      title: _titleController.text,
      summary: summaryJson,
      lastModified: DateTime.now(),
      checklist: _checklistItems,
      backgroundColor: _backgroundColorValue,
      backgroundImagePath: _backgroundImagePath,
    );
    Navigator.pop(context, updatedItem);
  }

  void _shareItem() {
    final title = _titleController.text;
    final summary = _contentController.document.toPlainText();
    final checklistText = _checklistItems.map((item) => '[${item.isChecked ? 'x' : ' '}] ${item.document.toPlainText()}').join('\n');
    SharePlus.instance.share(
        ShareParams(
            text: '$title\n\n$summary\n\n$checklistText',
            subject: title,
        ),
    );
  }

  void _deleteItem() {
    if (!mounted) return;
    Navigator.pop(context, "DELETE");
  }

  void _addChecklistItem() {
    setState(() {
      final newItem = ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString());
      _checklistItems.add(newItem);
      _checklistControllers[newItem.id] = quill.QuillController.basic()
        ..addListener(() => _onChecklistItemChanged(newItem.id));
    });
  }

  void _deleteChecklistItem(String id) {
    setState(() {
        final controller = _checklistControllers.remove(id);
        controller?.dispose();
        _checklistItems.removeWhere((item) => item.id == id);
    });
  }

  void _showEditorMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(children: <Widget>[
          ListTile(leading: const Icon(Icons.share), title: const Text('Share'), onTap: () { Navigator.pop(ctx); _shareItem(); }),
          ListTile(leading: const Icon(Icons.delete), title: const Text('Delete'), onTap: () { Navigator.pop(ctx); _deleteItem(); }),
        ]);
      },
    );
  }

  void _showAddContentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(children: <Widget>[
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text('Checklist Item'),
            onTap: () {
              Navigator.pop(ctx);
              _addChecklistItem();
            },
          ),
        ]);
      },
    );
  }

  void _showBackgroundSheet() {
    final colors = [
      null, // Default
      Colors.blueGrey[100]!.toARGB32(),
      Colors.amber[200]!.toARGB32(),
      Colors.deepOrange[200]!.toARGB32(),
      Colors.lightGreen[200]!.toARGB32(),
      Colors.teal[100]!.toARGB32(),
      Colors.purple[100]!.toARGB32(),
    ];

    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    final colorValue = colors[index];
                    final isSelected = _backgroundColorValue == colorValue;

                    return GestureDetector(
                      onTap: () {
                        _changeBackgroundColor(colorValue);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorValue != null ? Color(colorValue) : Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: colorValue == null
                            ? const Icon(Icons.format_color_reset)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Image from gallery'),
                onTap: () {
                  _pickImage();
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        });
  }
  
  void _changeBackgroundColor(int? colorValue) {
    setState(() {
      _backgroundColorValue = colorValue;
      _backgroundImagePath = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _backgroundImagePath = pickedFile.path;
        _backgroundColorValue = null;
      });
    }
  }

  bool _isColorDark(int? colorValue) {
    if (colorValue == null) return Theme.of(context).brightness == Brightness.dark;
    return Color(colorValue).computeLuminance() < 0.5;
  }

  Widget _buildChecklistItem(ChecklistItem item, Color textColor) {
    final controller = _checklistControllers[item.id];
    if (controller == null) return Container(key: ValueKey(item.id));

    final quillEditor = quill.QuillEditor.basic(
      controller: controller,
    );

    return Row(
        key: ValueKey(item.id),
        children: [
          Checkbox(
            value: item.isChecked,
            onChanged: (bool? value) {
              if (value != null) {
                setState(() {
                  item.isChecked = value;
                });
              }
            },
            activeColor: textColor,
            checkColor: _backgroundColorValue != null ? Color(_backgroundColorValue!) : null,
          ),
          Expanded(child: quillEditor),
          IconButton(icon: Icon(Icons.clear, color: textColor), onPressed: () => _deleteChecklistItem(item.id)),
        ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isColorDark(_backgroundColorValue);
    final textColor = isDark ? Colors.white : Colors.black;
    final _ = isDark ? Colors.white70 : Colors.black54;
    final appBarColor = _backgroundColorValue != null ? Color(_backgroundColorValue!) : null;

    BoxDecoration? backgroundDecoration;
    if (_backgroundImagePath != null) {
      backgroundDecoration = BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(_backgroundImagePath!)),
          fit: BoxFit.cover,
        ),
      );
    } else if (_backgroundColorValue != null) {
      backgroundDecoration = BoxDecoration(color: Color(_backgroundColorValue!));
    }

   return PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (bool didPop, Object? result) async {
    if (didPop) return;
    _saveAndExit();
  },

      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: _saveAndExit),
          backgroundColor: appBarColor,
          elevation: _backgroundColorValue != null ? 0 : null,
          title: null,
          actions: [
            IconButton(icon: Icon(Icons.more_vert, color: textColor), onPressed: _showEditorMenu),
          ],
        ),
        body: Container(
          decoration: backgroundDecoration,
          child: Column(
            children: [
              quill.QuillSimpleToolbar(controller: _contentController),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: quill.QuillEditor.basic(
                    controller: _contentController,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _checklistItems.length,
                  itemBuilder: (context, index) {
                    return _buildChecklistItem(_checklistItems[index], textColor);
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(icon: Icon(Icons.add, color: textColor), onPressed: _showAddContentSheet),
              IconButton(icon: Icon(Icons.palette_outlined, color: textColor), onPressed: _showBackgroundSheet),
            ],
          ),
        ),
      ),
    );
  }
}
