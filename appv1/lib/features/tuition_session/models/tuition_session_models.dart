class TeacherDTO {
  final String teacherId;
  final String name;
  final String email;
  final String gender;
  final bool verified;

  TeacherDTO({
    required this.teacherId,
    required this.name,
    required this.email,
    required this.gender,
    required this.verified,
  });

  factory TeacherDTO.fromJson(Map<String, dynamic> json) {
    return TeacherDTO(
      teacherId: json['teacherId'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}

class SessionSummaryDTO {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String status;
  final bool forcedCheckIn;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int durationMinutes;

  SessionSummaryDTO({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.forcedCheckIn,
    this.checkInTime,
    this.checkOutTime,
    required this.durationMinutes,
  });

  factory SessionSummaryDTO.fromJson(Map<String, dynamic> json) {
    return SessionSummaryDTO(
      id: json['_id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      status: json['status'] ?? 'pending',
      forcedCheckIn: json['forcedCheckIn'] ?? false,
      checkInTime: json['checkInTime'] != null ? DateTime.tryParse(json['checkInTime'])?.toLocal() : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.tryParse(json['checkOutTime'])?.toLocal() : null,
      durationMinutes: json['durationMinutes'] ?? 0,
    );
  }
}

class SessionDetailDTO extends SessionSummaryDTO {
  final String? forcedCheckInReason;
  final Map<String, dynamic>? checkInLocation;
  final Map<String, dynamic>? checkOutLocation;
  final Map<String, dynamic>? activity;

  SessionDetailDTO({
    required String id,
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String teacherId,
    required String teacherName,
    required String status,
    required bool forcedCheckIn,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    required int durationMinutes,
    this.forcedCheckInReason,
    this.checkInLocation,
    this.checkOutLocation,
    this.activity,
  }) : super(
          id: id,
          assignmentId: assignmentId,
          studentId: studentId,
          studentName: studentName,
          teacherId: teacherId,
          teacherName: teacherName,
          status: status,
          forcedCheckIn: forcedCheckIn,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          durationMinutes: durationMinutes,
        );

  factory SessionDetailDTO.fromJson(Map<String, dynamic> json) {
    return SessionDetailDTO(
      id: json['_id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      status: json['status'] ?? 'pending',
      forcedCheckIn: json['forcedCheckIn'] ?? false,
      checkInTime: json['checkInTime'] != null ? DateTime.tryParse(json['checkInTime'])?.toLocal() : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.tryParse(json['checkOutTime'])?.toLocal() : null,
      durationMinutes: json['durationMinutes'] ?? 0,
      forcedCheckInReason: json['forcedCheckInReason'],
      checkInLocation: json['checkInLocation'],
      checkOutLocation: json['checkOutLocation'],
      activity: json['activity'],
    );
  }
}
