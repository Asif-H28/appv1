import 'package:appv1/core/constants/api_constants.dart';
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
  final bool isAdmin; // â† already exists, no change needed

  const AchievementCreatePage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    required this.orgId,
    required this.orgName,
    this.existingPost,
    this.isAdmin = false,
  });

  @override
  State<AchievementCreatePage> createState() => AchievementCreatePageState();
}

class AchievementCreatePageState extends State<AchievementCreatePage> {
  final captionCtrl = TextEditingController();
  bool isEdit = false;

  String resolvedTeacherId = '';
  String resolvedTeacherName = '';
  String resolvedOrgId = '';
  String resolvedOrgName = '';

  List<Map<String, dynamic>> allClasses = [];
  String selectedClassId = '';
  String selectedClassName = '';
  bool classesLoading = false;

  final List<String> uploadedUrls = [];
  final List<String> uploadedPublicIds = [];
  bool uploadingImage = false;

  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> taggedStudents = [];
  bool studentsLoading = false;

  bool submitting = false;

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

  // â”€â”€ Resolve identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _resolveIdentityAndLoadClasses() async {
    final prefs = await SharedPreferences.getInstance();

    // â”€â”€ Admin: read userId from prefs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // â”€â”€ Teacher: read teacherId from prefs â”€â”€â”€â”€â”€â”€â”€
    final tId = widget.isAdmin
        ? (prefs.getString('userId') ?? widget.teacherId)
        : (prefs.getString('teacherId') ?? widget.teacherId);

    final tName = widget.isAdmin
        ? (prefs.getString('adminName') ??
              prefs.getString('userName') ??
              widget.teacherName)
        : (prefs.getString('teacherName') ?? widget.teacherName);

    final oId = prefs.getString('orgId') ?? widget.orgId;
    final oName =
        prefs.getString('orgName') ??
        prefs.getString('userOrg') ??
        widget.orgName;
    final cId = prefs.getString('classId') ?? widget.classId;
    final cName = prefs.getString('className') ?? widget.className;

    debugPrint('[INIT] â”€â”€ resolved identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€');
    debugPrint('[INIT] isAdmin      = ${widget.isAdmin}');
    debugPrint('[INIT] teacherId    = $tId');
    debugPrint('[INIT] teacherName  = $tName');
    debugPrint('[INIT] orgId        = $oId');
    debugPrint('[INIT] orgName      = $oName');
    debugPrint('[INIT] classId      = $cId');
    debugPrint('[INIT] className    = $cName');
    debugPrint('[INIT] â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€');

    if (!mounted) return;
    setState(() {
      resolvedTeacherId = tId;
      resolvedTeacherName = tName;
      resolvedOrgId = oId;
      resolvedOrgName = oName;
      if (!isEdit) {
        if (cId.isNotEmpty) selectedClassId = cId;
        if (cName.isNotEmpty) selectedClassName = cName;
      }
    });

    // â”€â”€ Admin skips class/student loading â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (widget.isAdmin) return;

    loadClasses(prefs: prefs);
  }

  // â”€â”€ Load classes (teacher only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> loadClasses({SharedPreferences? prefs}) async {
    // Admin never calls this
    if (widget.isAdmin) return;

    setState(() => classesLoading = true);
    try {
      prefs ??= await SharedPreferences.getInstance();
      final orgId = resolvedOrgId.isNotEmpty
          ? resolvedOrgId
          : (prefs.getString('orgId') ?? widget.orgId);

      final url = '${ApiConstants.apiBaseUrl}/classroom/org/$orgId';
      debugPrint('[CLASS] GET $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final all = (body['classrooms'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

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

          if (selectedClassId.isNotEmpty) loadStudents(selectedClassId);
        });
      } else {
        setState(() => classesLoading = false);
        _fallbackClass();
      }
    } catch (e, st) {
      debugPrint('[CLASS] âŒ exception: $e\n$st');
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

  // â”€â”€ Load students (teacher only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> loadStudents(String classId) async {
    if (classId.isEmpty || widget.isAdmin) return;

    setState(() {
      studentsLoading = true;
      taggedStudents = [];
      allStudents = [];
    });
    final url = '${ApiConstants.apiBaseUrl}/student/class/$classId';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final list = (body['students'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        setState(() {
          allStudents = list;
          studentsLoading = false;
        });
      } else {
        setState(() => studentsLoading = false);
      }
    } catch (e, st) {
      debugPrint('[STUDENTS] âŒ exception: $e\n$st');
      if (mounted) setState(() => studentsLoading = false);
    }
  }

  // â”€â”€ Image upload â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => uploadingImage = true);
    const url = '${ApiConstants.apiBaseUrl}/upload/image';
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.files.add(await http.MultipartFile.fromPath('file', picked.path));
      final stream = await req.send();
      final res = await http.Response.fromStream(stream);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final file = body['file'] as Map;
        setState(() {
          uploadedUrls.add(file['url'].toString());
          uploadedPublicIds.add(file['publicId'].toString());
        });
      }
    } catch (e, st) {
      debugPrint('[UPLOAD] âŒ exception: $e\n$st');
    }
    if (mounted) setState(() => uploadingImage = false);
  }

  Future<void> removeImage(int index) async {
    final existingCount = widget.existingPost?['images']?.length as int? ?? 0;
    if (!isEdit || index >= existingCount) {
      final pubIdIndex = isEdit ? index - existingCount : index;
      if (pubIdIndex >= 0 && pubIdIndex < uploadedPublicIds.length) {
        final pubId = uploadedPublicIds[pubIdIndex];
        try {
          await http.post(
            Uri.parse('${ApiConstants.apiBaseUrl}/upload/delete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'publicId': pubId, 'resourceType': 'image'}),
          );
        } catch (e) {
          debugPrint('[DELETE_IMG] exception: $e');
        }
        uploadedPublicIds.removeAt(pubIdIndex);
      }
    }
    setState(() => uploadedUrls.removeAt(index));
  }

  // â”€â”€ Tags â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void toggleTag(Map<String, dynamic> student) {
    final id = student['studentId'].toString();
    setState(() {
      if (taggedStudents.any((s) => s['studentId'] == id)) {
        taggedStudents.removeWhere((s) => s['studentId'] == id);
      } else {
        taggedStudents.add({
          'studentId': id,
          'studentName': student['name']?.toString() ?? '',
        });
      }
    });
  }

  // â”€â”€ Preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Submit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        // â”€â”€ EDIT (same for both admin and teacher) â”€â”€
        final achId = widget.existingPost!['achievementId'].toString();
        final url = '${ApiConstants.apiBaseUrl}/achievement/$achId';
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
        // â”€â”€ CREATE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        final prefs = await SharedPreferences.getInstance();

        final orgId = resolvedOrgId.isNotEmpty
            ? resolvedOrgId
            : (prefs.getString('orgId') ?? widget.orgId);
        final orgName = resolvedOrgName.isNotEmpty
            ? resolvedOrgName
            : (prefs.getString('orgName') ??
                  prefs.getString('userOrg') ??
                  widget.orgName);

        if (orgId.isEmpty) {
          debugPrint('[SUBMIT] âŒ orgId is empty â€” cannot create post');
          if (mounted) {
            setState(() => submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Session error: missing orgId. Please log out and log back in.',
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }
          return;
        }

        const url = '${ApiConstants.apiBaseUrl}/achievement/create';

        // â”€â”€ Admin payload: only orgId + isAdmin = true â”€â”€
        // â”€â”€ Teacher payload: full fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        final Map<String, dynamic> bodyMap;

        if (widget.isAdmin) {
          bodyMap = {
            'isAdmin': true,
            'orgId': orgId,
            if (orgName.isNotEmpty) 'orgName': orgName,
            'caption': captionCtrl.text.trim(),
            'images': uploadedUrls,
            'taggedStudents': taggedStudents,
          };
        } else {
          final teacherId = resolvedTeacherId.isNotEmpty
              ? resolvedTeacherId
              : (prefs.getString('teacherId') ?? widget.teacherId);

          final teacherName = resolvedTeacherName.isNotEmpty
              ? resolvedTeacherName
              : (prefs.getString('teacherName') ?? widget.teacherName);

          final classId = selectedClassId.isNotEmpty
              ? selectedClassId
              : (prefs.getString('classId') ?? widget.classId);

          final className = selectedClassName.isNotEmpty
              ? selectedClassName
              : (prefs.getString('className') ?? widget.className);

          // Teacher validation
          final missing = <String>[];
          if (teacherId.isEmpty) missing.add('teacherId');
          if (teacherName.isEmpty) missing.add('teacherName');
          if (orgId.isEmpty) missing.add('orgId');
          if (classId.isEmpty) missing.add('classId');
          if (className.isEmpty) missing.add('className');

          if (missing.isNotEmpty) {
            debugPrint('[SUBMIT] âŒ Still missing: $missing');
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
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }
            return;
          }

          bodyMap = {
            'teacherId': teacherId,
            'teacherName': teacherName,
            'classId': classId,
            'className': className,
            'orgId': orgId,
            if (orgName.isNotEmpty) 'orgName': orgName,
            'caption': captionCtrl.text.trim(),
            'images': uploadedUrls,
            'taggedStudents': taggedStudents,
          };
        }

        final bodyJson = jsonEncode(bodyMap);
        debugPrint('[CREATE] POST $url');
        debugPrint('[CREATE] isAdmin=${widget.isAdmin}  body=$bodyJson');

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
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('[SUBMIT] âŒ exception: $e\n$st');
      if (mounted) {
        setState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AchievementCreateBody(state: this);
}

