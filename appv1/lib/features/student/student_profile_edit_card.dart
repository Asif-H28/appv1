import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'student_theme_manager.dart';

class StudentProfileEditCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final String? selectedGender;
  final bool isSaving;
  final void Function(String?) onGenderChange;
  final VoidCallback onSave;

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  const StudentProfileEditCard({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.selectedGender,
    required this.isSaving,
    required this.onGenderChange,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StudentThemeConfig>(
      valueListenable: StudentThemeManager.themeNotifier,
      builder: (context, theme, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Personal Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 12,
                            color: theme.primary,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Only the fields you fill will be updated.',
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),

                    // Full Name
                    _label('Full Name', theme),
                    SizedBox(height: 6),
                    _field(
                      theme: theme,
                      controller: nameCtrl,
                      hint: 'Enter your full name',
                      icon: Icons.person_rounded,
                      inputType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16),

                    // Phone
                    _label('Phone Number', theme),
                    SizedBox(height: 6),
                    _field(
                      theme: theme,
                      controller: phoneCtrl,
                      hint: 'Enter 10-digit phone number',
                      icon: Icons.phone_rounded,
                      inputType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    SizedBox(height: 16),

                    // Gender
                    _label('Gender', theme),
                    SizedBox(height: 6),
                    Row(
                      children: _genders.map((g) {
                        final isSelected = selectedGender == g;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: g != _genders.last ? 8 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  onGenderChange(isSelected ? null : g),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 180),
                                padding: EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.primary
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primary
                                        : theme.dividerColor,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      g == 'Male'
                                          ? Icons.male_rounded
                                          : g == 'Female'
                                          ? Icons.female_rounded
                                          : Icons.transgender_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : theme.textSecondary,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      g,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : theme.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),

                    // Address
                    _label('Address', theme),
                    SizedBox(height: 6),
                    _field(
                      theme: theme,
                      controller: addressCtrl,
                      hint: 'Enter your full address',
                      icon: Icons.location_on_rounded,
                      maxLines: 3,
                      capitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: 22),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: theme.primary.withOpacity(
                            0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  Widget _label(String text, StudentThemeConfig theme) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: theme.textSecondary,
    ),
  );

  Widget _field({
    required StudentThemeConfig theme,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        textCapitalization: capitalization,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(fontSize: 13, color: theme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.textSecondary, fontSize: 12.5),
          prefixIcon: Icon(icon, size: 16, color: theme.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          counterText: '',
        ),
      ),
    );
  }
}
