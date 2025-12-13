class AttendanceRecord {
  final int id;
  final int userId;
  final String status;
  final String type;
  final String attendanceDate;
  final String attendanceTime;
  final String? photoPath;
  final String? photoUrl;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.status,
    required this.type,
    required this.attendanceDate,
    required this.attendanceTime,
    this.photoPath,
    this.photoUrl,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? '',
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceTime: json['attendance_time'] as String? ?? '',
      photoPath: json['photo_path'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'type': type,
      'attendance_date': attendanceDate,
      'attendance_time': attendanceTime,
      'photo_path': photoPath,
      'photo_url': photoUrl,
    };
  }
}
