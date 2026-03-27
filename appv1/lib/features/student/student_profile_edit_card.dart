import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.edit_rounded, size: 15, color: _accent),
                    SizedBox(width: 5),
                    Text(
                      'Edit Personal Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Info banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _accent.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: _accent,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Only the fields you fill will be updated.',
                          style: TextStyle(color: _accent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),

                // Full Name
                _label('Full Name'),
                SizedBox(height: 6),
                _field(
                  controller: nameCtrl,
                  hint: 'Enter your full name',
                  icon: Icons.person_rounded,
                  inputType: TextInputType.name,
                  capitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),

                // Phone
                _label('Phone Number'),
                SizedBox(height: 6),
                _field(
                  controller: phoneCtrl,
                  hint: 'Enter 10-digit phone number',
                  icon: Icons.phone_rounded,
                  inputType: TextInputType.phone,
                  maxLength: 10,
                ),
                SizedBox(height: 16),

                // Gender
                _label('Gender'),
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
                          onTap: () => onGenderChange(isSelected ? null : g),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected ? _accent : Colors.grey[50],
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: isSelected ? _accent : Colors.grey[200]!,
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
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  g,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
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
                _label('Address'),
                SizedBox(height: 6),
                _field(
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
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
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
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppColors.textSecondary,
    ),
  );

  Widget _field({
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        textCapitalization: capitalization,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          prefixIcon: Icon(icon, size: 16, color: _accent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          counterText: '',
        ),
      ),
    );
  }
}
