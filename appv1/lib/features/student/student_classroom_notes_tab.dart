import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_note_card.dart';

const Color _accent = Colors.teal;

class StudentClassroomNotesTab extends StatefulWidget {
  @override
  _StudentClassroomNotesTabState createState() =>
      _StudentClassroomNotesTabState();
}

class _StudentClassroomNotesTabState extends State<StudentClassroomNotesTab> {
  bool _isLoading = true;
  String _error = '';
  String _selectedTeacher = 'All';
  String _searchQuery = '';
  bool _showSearch = false;

  List<Map<String, dynamic>> _notes = [];
  List<String> _teacherList = [];

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final classId = prefs.getString('classId') ?? '';

    if (classId.isEmpty) {
      setState(() {
        _error = 'No classroom assigned.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/notes/class/$classId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List)
          raw = body;
        else if (body['notes'] != null)
          raw = body['notes'] as List;
        else if (body['data'] != null)
          raw = body['data'] as List;

        final notes = raw.map((e) => e as Map<String, dynamic>).toList();

        // ── Build unique teacher list ──
        final teachers = <String>{};
        for (final n in notes) {
          final t = n['notesSharedBy']?.toString() ?? '';
          if (t.isNotEmpty) teachers.add(t);
        }

        setState(() {
          _notes = notes;
          _teacherList = teachers.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load notes.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  // ── Filtered notes ────────────────────────────────────

  List<Map<String, dynamic>> get _filtered {
    return _notes.where((note) {
      // Teacher filter
      if (_selectedTeacher != 'All') {
        final t = note['notesSharedBy']?.toString() ?? '';
        if (t != _selectedTeacher) return false;
      }

      // Search filter — by title or attachment file name
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = note['title']?.toString().toLowerCase() ?? '';
        if (title.contains(q)) return true;

        // also search attachment file names
        final attachments = note['attachments'] as List<dynamic>? ?? [];
        for (final att in attachments) {
          final name =
              (att['name']?.toString() ??
                      att['fileName']?.toString() ??
                      att['originalName']?.toString() ??
                      '')
                  .toLowerCase();
          if (name.contains(q)) return true;
        }
        return false;
      }

      return true;
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_error.isNotEmpty) return _buildError();
    if (_notes.isEmpty) return _buildEmpty();

    final filtered = _filtered;

    return Column(
      children: [
        // ── Top bar: search toggle + result count ──
        _buildTopBar(),

        // ── Search field ──
        if (_showSearch) _buildSearchField(),

        // ── Teacher filter chips ──
        if (_teacherList.isNotEmpty) _buildTeacherChips(),

        // ── Notes list ──
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResults()
              : RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetchNotes,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      12,
                      14,
                      40 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (_, i) => NoteCard(note: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────

  Widget _buildTopBar() {
    final count = _filtered.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          Text(
            '$count note${count != 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showSearch
                    ? _accent.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: _showSearch
                      ? _accent.withOpacity(0.3)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    size: 14,
                    color: _showSearch ? _accent : AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _showSearch ? 'Close' : 'Search',
                    style: TextStyle(
                      color: _showSearch ? _accent : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field ──────────────────────────────────────

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        cursorColor: _accent,
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search by file name...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: _accent, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: _accent.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Teacher filter chips ──────────────────────────────

  Widget _buildTeacherChips() {
    final all = ['All', ..._teacherList];
    return Container(
      height: 44,
      margin: EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14),
        itemCount: all.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (_, i) {
          final name = all[i];
          final isSelected = _selectedTeacher == name;
          return GestureDetector(
            onTap: () => setState(() => _selectedTeacher = name),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected ? _accent : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name != 'All') ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : _accent.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                  ],
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── States ────────────────────────────────────────────

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text(
          'Loading notes...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[400],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchNotes,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.08),
            ),
            child: Icon(Icons.notes_rounded, color: _accent, size: 30),
          ),
          SizedBox(height: 14),
          Text(
            'No Notes Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your teacher has not uploaded any notes yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildNoResults() => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100]!,
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: Colors.grey[400],
              size: 30,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'No Results Found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different search term or filter.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

