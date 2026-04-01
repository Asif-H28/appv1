// achievement_create_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import 'achievement_preview_sheet.dart';
import 'achievement_create_widgets.dart';

class AchievementCreatePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String classId;
  final String className;
  final String orgId;
  final String orgName;
  final Map<String, dynamic>? existingPost;

  const AchievementCreatePage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    required this.orgId,
    required this.orgName,
    this.existingPost,
  });

  @override
  State<AchievementCreatePage> createState() => AchievementCreatePageState();
}

class AchievementCreatePageState extends State<AchievementCreatePage> {
  final captionCtrl = TextEditingController();
  bool isEdit = false;

  // ── Resolved identity fields (from prefs + widget fallback) ──
  String resolvedTeacherId = '';
  String resolvedTeacherName = '';
  String resolvedOrgId = '';
  String resolvedOrgName = '';

  // ── Class selection ──────────────────────────────
  List<Map<String, dynamic>> allClasses = [];
  String selectedClassId = '';
  String selectedClassName = '';
  bool classesLoading = false;

  // ── Images ───────────────────────────────────────
  final List<String> uploadedUrls = [];
  final List<String> uploadedPublicIds = [];
  bool uploadingImage = false;

  // ── Tags ─────────────────────────────────────────
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> taggedStudents = [];
  bool studentsLoading = false;

  bool submitting = false;

  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    isEdit = widget.existingPost != null;
    selectedClassId = widget.classId;
    selectedClassName = widget.className;

    if (isEdit) {
      captionCtrl.text = widget.existingPost?['caption']?.toString() ?? '';
      taggedStudents = ((widget.existingPost?['taggedStudents'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      uploadedUrls.addAll(
        (widget.existingPost?['images'] as List? ?? []).cast<String>(),
      );
      selectedClassId =
          widget.existingPost?['classId']?.toString() ?? widget.classId;
      selectedClassName =
          widget.existingPost?['className']?.toString() ?? widget.className;
    }

    _resolveIdentityAndLoadClasses();
  }

  @override
  void dispose() {
    captionCtrl.dispose();
    super.dispose();
  }

  // ── Resolve teacher/org identity from prefs ──────
  //   SharedPreferences is the source of truth.
  //   widget.* is only a fallback for when prefs are missing.

  Future<void> _resolveIdentityAndLoadClasses() async {
    final prefs = await SharedPreferences.getInstance();

    final tId = prefs.getString('teacherId') ?? widget.teacherId;
    final tName = prefs.getString('teacherName') ?? widget.teacherName;
    final oId = prefs.getString('orgId') ?? widget.orgId;
    final oName = prefs.getString('orgName') ?? widget.orgName;
    final cId = prefs.getString('classId') ?? widget.classId;
    final cName = prefs.getString('className') ?? widget.className;

    debugPrint('[INIT] ── resolved identity ──────────');
    debugPrint('[INIT] teacherId   = $tId');
    debugPrint('[INIT] teacherName = $tName');
    debugPrint('[INIT] orgId       = $oId');
    debugPrint('[INIT] orgName     = $oName');
    debugPrint('[INIT] classId     = $cId');
    debugPrint('[INIT] className   = $cName');
    debugPrint('[INIT] ────────────────────────────────');

    if (tId.isEmpty || oId.isEmpty) {
      debugPrint(
        '[INIT] ⚠️  teacherId or orgId is STILL empty after prefs lookup!',
      );
      debugPrint(
        '[INIT]     Check that login stores these keys in SharedPreferences.',
      );
    }

    if (!mounted) return;
    setState(() {
      resolvedTeacherId = tId;
      resolvedTeacherName = tName;
      resolvedOrgId = oId;
      resolvedOrgName = oName;
      // Also update selectedClass from prefs if not already set by existingPost
      if (!isEdit) {
        if (cId.isNotEmpty) selectedClassId = cId;
        if (cName.isNotEmpty) selectedClassName = cName;
      }
    });

    loadClasses(prefs: prefs);
  }

  // ── Load classes ─────────────────────────────────

  Future<void> loadClasses({SharedPreferences? prefs}) async {
    setState(() => classesLoading = true);
    try {
      prefs ??= await SharedPreferences.getInstance();
      final orgId = resolvedOrgId.isNotEmpty
          ? resolvedOrgId
          : (prefs.getString('orgId') ?? widget.orgId);

      final url = 'https://appv1backend.onrender.com/api/classroom/org/$orgId';
      debugPrint('[CLASS] GET $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      debugPrint('[CLASS] status=${res.statusCode}');
      debugPrint('[CLASS] body=${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final all = (body['classrooms'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        debugPrint('[CLASS] count=${all.length}');

        setState(() {
          allClasses = all;
          classesLoading = false;

          final savedClassId = resolvedTeacherId.isNotEmpty
              ? (prefs!.getString('classId') ?? widget.classId)
              : widget.classId;

          final match = all.firstWhere(
            (c) => c['classId']?.toString() == savedClassId,
            orElse: () => <String, dynamic>{},
          );

          if (match.isNotEmpty) {
            selectedClassId = match['classId']?.toString() ?? '';
            selectedClassName = match['className']?.toString() ?? '';
          } else if (all.isNotEmpty) {
            selectedClassId = all.first['classId']?.toString() ?? '';
            selectedClassName = all.first['className']?.toString() ?? '';
          }
          debugPrint('[CLASS] selected: $selectedClassId / $selectedClassName');
          if (selectedClassId.isNotEmpty) loadStudents(selectedClassId);
        });
      } else {
        debugPrint('[CLASS] ❌ error body=${res.body}');
        setState(() => classesLoading = false);
        _fallbackClass();
      }
    } catch (e, st) {
      debugPrint('[CLASS] ❌ exception: $e\n$st');
      if (mounted) {
        setState(() => classesLoading = false);
        _fallbackClass();
      }
    }
  }

  void _fallbackClass() {
    if (widget.classId.isNotEmpty) {
      setState(() {
        selectedClassId = widget.classId;
        selectedClassName = widget.className;
      });
      loadStudents(widget.classId);
    }
  }

  // ── Load students ────────────────────────────────

  Future<void> loadStudents(String classId) async {
    if (classId.isEmpty) return;
    setState(() {
      studentsLoading = true;
      taggedStudents = [];
      allStudents = [];
    });
    final url = 'https://appv1backend.onrender.com/api/student/class/$classId';
    debugPrint('[STUDENTS] GET $url');
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      debugPrint('[STUDENTS] status=${res.statusCode}');
      debugPrint('[STUDENTS] body=${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final list = (body['students'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        debugPrint('[STUDENTS] count=${list.length}');
        setState(() {
          allStudents = list;
          studentsLoading = false;
        });
      } else {
        debugPrint('[STUDENTS] ❌ error body=${res.body}');
        setState(() => studentsLoading = false);
      }
    } catch (e, st) {
      debugPrint('[STUDENTS] ❌ exception: $e\n$st');
      if (mounted) setState(() => studentsLoading = false);
    }
  }

  // ── Image upload ─────────────────────────────────

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => uploadingImage = true);
    const url = 'https://appv1backend.onrender.com/api/upload/image';
    debugPrint('[UPLOAD] POST $url  file=${picked.path}');
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.files.add(await http.MultipartFile.fromPath('file', picked.path));
      final stream = await req.send();
      final res = await http.Response.fromStream(stream);
      if (!mounted) return;

      debugPrint('[UPLOAD] status=${res.statusCode}');
      debugPrint('[UPLOAD] body=${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final file = body['file'] as Map;
        setState(() {
          uploadedUrls.add(file['url'].toString());
          uploadedPublicIds.add(file['publicId'].toString());
        });
        debugPrint('[UPLOAD] ✅ url=${file['url']}');
      } else {
        debugPrint('[UPLOAD] ❌ failed body=${res.body}');
      }
    } catch (e, st) {
      debugPrint('[UPLOAD] ❌ exception: $e\n$st');
    }
    if (mounted) setState(() => uploadingImage = false);
  }

  Future<void> removeImage(int index) async {
    final existingCount = widget.existingPost?['images']?.length as int? ?? 0;
    if (!isEdit || index >= existingCount) {
      final pubIdIndex = isEdit ? index - existingCount : index;
      if (pubIdIndex >= 0 && pubIdIndex < uploadedPublicIds.length) {
        final pubId = uploadedPublicIds[pubIdIndex];
        debugPrint('[DELETE_IMG] publicId=$pubId');
        try {
          final res = await http.post(
            Uri.parse('https://appv1backend.onrender.com/api/upload/delete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'publicId': pubId, 'resourceType': 'image'}),
          );
          debugPrint('[DELETE_IMG] status=${res.statusCode} body=${res.body}');
        } catch (e) {
          debugPrint('[DELETE_IMG] exception: $e');
        }
        uploadedPublicIds.removeAt(pubIdIndex);
      }
    }
    setState(() => uploadedUrls.removeAt(index));
  }

  // ── Tags ─────────────────────────────────────────

  void toggleTag(Map<String, dynamic> student) {
    final id = student['studentId'].toString();
    setState(() {
      if (taggedStudents.any((s) => s['studentId'] == id)) {
        taggedStudents.removeWhere((s) => s['studentId'] == id);
        debugPrint('[TAG] removed: $id');
      } else {
        taggedStudents.add({
          'studentId': id,
          'studentName': student['name']?.toString() ?? '',
        });
        debugPrint('[TAG] added: $id / ${student['name']}');
      }
    });
  }

  // ── Preview ──────────────────────────────────────

  void showPreview() {
    if (captionCtrl.text.trim().isEmpty && uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption or image to preview')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementPreviewSheet(
        teacherName: resolvedTeacherName,
        className: selectedClassName,
        caption: captionCtrl.text.trim(),
        images: List.from(uploadedUrls),
        taggedStudents: List.from(taggedStudents),
        onConfirm: () {
          Navigator.pop(context);
          submit();
        },
      ),
    );
  }

  // ── Submit ───────────────────────────────────────

  Future<void> submit() async {
    if (captionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a caption')));
      return;
    }

    setState(() => submitting = true);

    try {
      if (isEdit) {
        // ── EDIT ────────────────────────────────────────
        final achId = widget.existingPost!['achievementId'].toString();
        final url = 'https://appv1backend.onrender.com/api/achievement/$achId';
        final payload = jsonEncode({
          'caption': captionCtrl.text.trim(),
          'taggedStudents': taggedStudents,
        });
        debugPrint('[EDIT] PUT $url  payload=$payload');

        final res = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
        debugPrint('[EDIT] status=${res.statusCode} body=${res.body}');

        if (res.statusCode != 200) {
          throw Exception('Edit failed: ${res.statusCode} ${res.body}');
        }
      } else {
        // ── CREATE ──────────────────────────────────────
        final prefs = await SharedPreferences.getInstance();

        // ── Dump all prefs for debugging ──
        debugPrint('[SUBMIT] ══ SharedPreferences dump ══');
        final allKeys = prefs.getKeys();
        if (allKeys.isEmpty) {
          debugPrint(
            '[SUBMIT] ⚠️  Prefs is EMPTY — login never saved anything!',
          );
        } else {
          for (final k in allKeys) {
            debugPrint('[SUBMIT]   $k = ${prefs.get(k)}');
          }
        }
        debugPrint('[SUBMIT] ═════════════════════════════');

        // ── Resolve: state variable → prefs → widget ──
        final teacherId = resolvedTeacherId.isNotEmpty
            ? resolvedTeacherId
            : (prefs.getString('teacherId') ?? widget.teacherId);

        final teacherName = resolvedTeacherName.isNotEmpty
            ? resolvedTeacherName
            : (prefs.getString('teacherName') ?? widget.teacherName);

        final orgId = resolvedOrgId.isNotEmpty
            ? resolvedOrgId
            : (prefs.getString('orgId') ?? widget.orgId);

        // orgName is optional — send empty string if not available
        final orgName = resolvedOrgName.isNotEmpty
            ? resolvedOrgName
            : (prefs.getString('orgName') ?? widget.orgName);

        final classId = selectedClassId.isNotEmpty
            ? selectedClassId
            : (prefs.getString('classId') ?? widget.classId);

        final className = selectedClassName.isNotEmpty
            ? selectedClassName
            : (prefs.getString('className') ?? widget.className);

        // ── Log final resolved values ──
        debugPrint('[SUBMIT] ── final resolved payload ──');
        debugPrint('[SUBMIT] teacherId   = "$teacherId"');
        debugPrint('[SUBMIT] teacherName = "$teacherName"');
        debugPrint('[SUBMIT] orgId       = "$orgId"');
        debugPrint('[SUBMIT] orgName     = "$orgName" (optional)');
        debugPrint('[SUBMIT] classId     = "$classId"');
        debugPrint('[SUBMIT] className   = "$className"');
        debugPrint('[SUBMIT] caption     = "${captionCtrl.text.trim()}"');
        debugPrint('[SUBMIT] images      = $uploadedUrls');
        debugPrint('[SUBMIT] tagged      = $taggedStudents');
        debugPrint('[SUBMIT] ─────────────────────────────');

        // ── Hard block — only required fields checked (orgName excluded) ──
        final missing = <String>[];
        if (teacherId.isEmpty) missing.add('teacherId');
        if (teacherName.isEmpty) missing.add('teacherName');
        if (orgId.isEmpty) missing.add('orgId');
        if (classId.isEmpty) missing.add('classId');
        if (className.isEmpty) missing.add('className');

        if (missing.isNotEmpty) {
          debugPrint('[SUBMIT] ❌ Still missing after all fallbacks: $missing');
          if (mounted) {
            setState(() => submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Session error: missing ${missing.join(', ')}. '
                  'Please log out and log back in.',
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
          return;
        }

        // ── Fire the request ──
        const url = 'https://appv1backend.onrender.com/api/achievement/create';

        final bodyJson = jsonEncode({
          'teacherId': teacherId,
          'teacherName': teacherName,
          'classId': classId,
          'className': className,
          'orgId': orgId,
          if (orgName.isNotEmpty) 'orgName': orgName, // optional field
          'caption': captionCtrl.text.trim(),
          'images': uploadedUrls,
          'taggedStudents': taggedStudents,
        });

        debugPrint('[CREATE] POST $url');
        debugPrint('[CREATE] body=$bodyJson');

        final res = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: bodyJson,
        );

        debugPrint('[CREATE] status=${res.statusCode}');
        debugPrint('[CREATE] response=${res.body}');

        if (res.statusCode != 200 && res.statusCode != 201) {
          throw Exception('Create failed: ${res.statusCode} ${res.body}');
        }

        final resBody = jsonDecode(res.body) as Map;
        debugPrint(
          '[CREATE] ✅ achievementId='
          '${resBody['achievement']?['achievementId']}',
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('[SUBMIT] ❌ exception: $e\n$st');
      if (mounted) {
        setState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AchievementCreateBody(state: this);
}
