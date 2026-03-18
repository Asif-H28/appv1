import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'note_card.dart';
import 'create_note_sheet.dart';
import 'edit_note_sheet.dart';

class ClassroomNotesTab extends StatefulWidget {
  final String classId;
  const ClassroomNotesTab({required this.classId});

  @override
  _ClassroomNotesTabState createState() => _ClassroomNotesTabState();
}

class _ClassroomNotesTabState extends State<ClassroomNotesTab> {
  static const Color _accent = Colors.teal;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _notes = [];
  String _teacherName = '';
  String _orgId = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('teacherName') ?? 'Teacher';
      _orgId = prefs.getString('orgId') ?? '';
    });
    await _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://appv1backend.onrender.com/api/notes/class/${widget.classId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['notes'] != null)
          raw = body['notes'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;

        setState(() {
          _notes = raw.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteNote(String notesId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://appv1backend.onrender.com/api/notes/$notesId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _notes.removeAt(index));
        _showSnackBar('Note deleted.', Colors.green[600]!);
      } else {
        _showSnackBar('Failed to delete.', Colors.red[600]!);
      }
    } catch (_) {
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  Future<void> _deleteAllNotes() async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://appv1backend.onrender.com/api/notes/class/${widget.classId}/all',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _notes.clear());
        _showSnackBar('All notes deleted.', Colors.green[600]!);
      } else {
        _showSnackBar('Failed to delete all notes.', Colors.red[600]!);
      }
    } catch (_) {
      _showSnackBar('No internet connection.', Colors.red[600]!);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmDelete(String notesId, String title, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red[600],
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Delete Note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        content: Text(
          'Delete "$title"? This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteNote(notesId, index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red[600],
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Delete All Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ALL notes for this classroom?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteAllNotes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete All',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateNoteSheet(
        classId: widget.classId,
        orgId: _orgId,
        sharedBy: _teacherName,
        onCreated: _fetchNotes,
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditNoteSheet(note: note, onUpdated: _fetchNotes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Action bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openCreateSheet,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Add Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              _actionIconBtn(
                Icons.refresh_rounded,
                _accent,
                _fetchNotes,
                tooltip: 'Refresh',
              ),
              SizedBox(width: 6),
              _actionIconBtn(
                Icons.delete_sweep_rounded,
                Colors.red[600]!,
                _confirmDeleteAll,
                tooltip: 'Delete all',
              ),
            ],
          ),
        ),
        SizedBox(height: 10),

        // ── Notes count chip ──
        if (!_isLoading && !_hasError && _notes.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 14, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Text(
                  '${_notes.length} note${_notes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        // ── Body ──
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2.5,
                  ),
                )
              : _hasError
              ? _buildError()
              : _notes.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchNotes,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 40),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final notesId =
                          note['notesId']?.toString() ??
                          note['_id']?.toString() ??
                          '';
                      return NoteCard(
                        note: note,
                        onEdit: () => _openEditSheet(note),
                        onDelete: () => _confirmDelete(
                          notesId,
                          note['title']?.toString() ?? 'Note',
                          index,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _actionIconBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
      icon: Icon(icon, color: color, size: 18),
      onPressed: onTap,
      tooltip: tooltip,
      constraints: BoxConstraints(minWidth: 38, minHeight: 38),
      padding: EdgeInsets.all(8),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            'Could not load notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _fetchNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.refresh, size: 14),
              label: Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.1),
            ),
            child: Icon(Icons.description_outlined, color: _accent, size: 30),
          ),
          SizedBox(height: 14),
          Text(
            'No Notes Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "Add Note" to share notes with students.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
