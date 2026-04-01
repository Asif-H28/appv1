import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'achievement_create_page.dart';

/// All build/widget helpers for AchievementCreatePage.
/// Receives the state via constructor to call methods and read fields.
class AchievementCreateBody extends StatelessWidget {
  final AchievementCreatePageState state;

  const AchievementCreateBody({super.key, required this.state});

  // shorthand getters
  bool get _isEdit => state.isEdit;
  bool get _submitting => state.submitting;
  bool get _uploadingImage => state.uploadingImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEdit) ...[
                    _sectionLabel('SELECT CLASS'),
                    const SizedBox(height: 8),
                    _buildClassSelector(context),
                    const SizedBox(height: 20),
                    _sectionLabel('IMAGES'),
                    const SizedBox(height: 8),
                    _buildImagePicker(context),
                    const SizedBox(height: 20),
                  ],
                  _sectionLabel('CAPTION'),
                  const SizedBox(height: 8),
                  _buildCaptionField(),
                  const SizedBox(height: 20),
                  _sectionLabel('TAG STUDENTS'),
                  const SizedBox(height: 8),
                  _buildTagPicker(),
                  const SizedBox(height: 28),
                  if (!_isEdit) ...[
                    _buildPreviewBtn(),
                    const SizedBox(height: 10),
                  ],
                  _buildSubmitBtn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Achievement' : 'New Achievement',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _isEdit
                          ? state.selectedClassName
                          : 'Fill in the details below',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Class selector ───────────────────────────────

  Widget _buildClassSelector(BuildContext context) {
    if (state.classesLoading) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[200]!),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.teal,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading classes...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (state.allClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.class_outlined,
                color: Colors.teal,
                size: 13,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              state.selectedClassName.isNotEmpty
                  ? state.selectedClassName
                  : 'No class assigned',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              state.selectedClassId.isNotEmpty &&
                  state.allClasses.any(
                    (c) => c['classId']?.toString() == state.selectedClassId,
                  )
              ? state.selectedClassId
              : null,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Select a class',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.teal,
              size: 20,
            ),
          ),
          borderRadius: BorderRadius.circular(8),
          items: state.allClasses.map((c) {
            final cId = c['classId']?.toString() ?? '';
            final cName = c['className']?.toString() ?? '';
            final studentCount = (c['studentIds'] as List? ?? []).length;
            final subjectCount = (c['subjects'] as List? ?? []).length;
            return DropdownMenuItem<String>(
              value: cId,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Icon(
                        Icons.class_outlined,
                        color: Colors.teal,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$studentCount student${studentCount == 1 ? '' : 's'}  ·  '
                            '$subjectCount subject${subjectCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            final cls = state.allClasses.firstWhere((c) => c['classId'] == val);
            state.setState(() {
              state.selectedClassId = val;
              state.selectedClassName = cls['className']?.toString() ?? '';
            });
            state.loadStudents(val);
          },
        ),
      ),
    );
  }

  // ── Image picker ─────────────────────────────────

  Widget _buildImagePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.uploadedUrls.isNotEmpty) ...[
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.uploadedUrls.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      image: DecorationImage(
                        image: NetworkImage(state.uploadedUrls[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => state.removeImage(i),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _uploadingImage ? null : state.pickAndUploadImage,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.teal.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: _uploadingImage
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Image',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Caption ──────────────────────────────────────

  Widget _buildCaptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: state.captionCtrl,
        maxLines: 4,
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Write about this achievement... 🏆',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          contentPadding: const EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── Tag picker ───────────────────────────────────

  Widget _buildTagPicker() {
    if (state.studentsLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.teal,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (state.allStudents.isEmpty) {
      return Text(
        'No students in class',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: state.allStudents.map((s) {
        final id = s['studentId'].toString();
        final name = s['name']?.toString() ?? '';
        final isTagged = state.taggedStudents.any((t) => t['studentId'] == id);
        return GestureDetector(
          onTap: () => state.toggleTag(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTagged ? Colors.teal : Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isTagged ? Colors.teal : Colors.grey[300]!,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isTagged ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Buttons ──────────────────────────────────────

  Widget _sectionLabel(String t) => Text(
    t,
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );

  Widget _buildPreviewBtn() {
    return GestureDetector(
      onTap: state.showPreview,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.teal),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.visibility_outlined, color: Colors.teal, size: 17),
            SizedBox(width: 8),
            Text(
              'Preview Post',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return GestureDetector(
      onTap: _submitting ? null : state.submit,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: _submitting ? Colors.teal.withOpacity(0.6) : Colors.teal,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isEdit ? 'Save Changes' : 'Post Achievement',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
