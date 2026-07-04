class AdmissionFormTemplateField {
  final String id;
  final String title;
  final String placeholder;

  AdmissionFormTemplateField({
    required this.id,
    required this.title,
    required this.placeholder,
  });

  factory AdmissionFormTemplateField.fromJson(Map<String, dynamic> json) {
    return AdmissionFormTemplateField(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      placeholder: json['placeholder'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'placeholder': placeholder,
    };
  }
}

class CustomFieldWithValue {
  final String id;
  final String title;
  final String value;

  CustomFieldWithValue({
    required this.id,
    required this.title,
    required this.value,
  });

  factory CustomFieldWithValue.fromJson(Map<String, dynamic> json) {
    return CustomFieldWithValue(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
    };
  }
}

class AdmissionForm {
  final String id;
  final String orgId;
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String country;
  final String admissionDate;
  final String schoolName;
  final String studentClass;
  final String dateOfBirth;
  final List<CustomFieldWithValue> customFields;
  final String? feeTitle;
  final int? feeAmount;
  final String? upiTitle;
  final String? upiBankingName;
  final String? upiId;
  final String? filledByUserId;
  final String? filledByRole;
  final String createdAt;
  final String? tutorId;
  final String? tutorName;

  AdmissionForm({
    required this.id,
    required this.orgId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.admissionDate,
    required this.schoolName,
    required this.studentClass,
    required this.dateOfBirth,
    required this.customFields,
    this.feeTitle,
    this.feeAmount,
    this.upiTitle,
    this.upiBankingName,
    this.upiId,
    this.filledByUserId,
    this.filledByRole,
    required this.createdAt,
    this.tutorId,
    this.tutorName,
  });

  factory AdmissionForm.fromJson(Map<String, dynamic> json) {
    return AdmissionForm(
      id: json['_id'] ?? '',
      orgId: json['orgId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
      schoolName: json['schoolName'] ?? '',
      studentClass: json['studentClass'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      customFields: (json['customFields'] as List<dynamic>?)
              ?.map((e) => CustomFieldWithValue.fromJson(e))
              .toList() ??
          [],
      feeTitle: json['feeTitle'],
      feeAmount: json['feeAmount'],
      upiTitle: json['upiTitle'],
      upiBankingName: json['upiBankingName'],
      upiId: json['upiId'],
      filledByUserId: json['filledByUserId'],
      filledByRole: json['filledByRole'],
      createdAt: json['createdAt'] ?? '',
      tutorId: json['tutorId'],
      tutorName: json['tutorName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'email': email,
      'phoneNumber': phoneNumber,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'admissionDate': admissionDate,
      'schoolName': schoolName,
      'studentClass': studentClass,
      'dateOfBirth': dateOfBirth,
      'customFields': customFields.map((e) => e.toJson()).toList(),
      if (feeTitle != null) 'feeTitle': feeTitle,
      if (feeAmount != null) 'feeAmount': feeAmount,
      if (upiTitle != null) 'upiTitle': upiTitle,
      if (upiBankingName != null) 'upiBankingName': upiBankingName,
      if (upiId != null) 'upiId': upiId,
      if (tutorId != null) 'tutorId': tutorId,
      if (tutorName != null) 'tutorName': tutorName,
    };
  }
}
