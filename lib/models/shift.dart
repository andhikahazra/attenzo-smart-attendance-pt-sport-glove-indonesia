class Shift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int earlyCheckinTolerance;
  final int lateTolerance;
  final int earlyLeaveTolerance;
  final int maxCheckinHours;
  final int maxCheckoutHours;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.earlyCheckinTolerance,
    required this.lateTolerance,
    required this.earlyLeaveTolerance,
    required this.maxCheckinHours,
    required this.maxCheckoutHours,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      earlyCheckinTolerance: json['early_checkin_tolerance'] as int,
      lateTolerance: json['late_tolerance'] as int,
      earlyLeaveTolerance: json['early_leave_tolerance'] as int,
      maxCheckinHours: json['max_checkin_hours'] as int,
      maxCheckoutHours: json['max_checkout_hours'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'early_checkin_tolerance': earlyCheckinTolerance,
      'late_tolerance': lateTolerance,
      'early_leave_tolerance': earlyLeaveTolerance,
      'max_checkin_hours': maxCheckinHours,
      'max_checkout_hours': maxCheckoutHours,
    };
  }

  /// Calculate early check-in time (start_time - early_checkin_tolerance)
  DateTime getEarlyCheckinTime(DateTime date) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var checkinTime = DateTime(date.year, date.month, date.day, hour, minute);
    return checkinTime.subtract(Duration(minutes: earlyCheckinTolerance));
  }

  /// Calculate max check-in time (start_time + max_checkin_hours)
  DateTime getMaxCheckinTime(DateTime date) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var checkinTime = DateTime(date.year, date.month, date.day, hour, minute);
    return checkinTime.add(Duration(hours: maxCheckinHours));
  }

  /// Calculate early check-out time (end_time - early_leave_tolerance)
  DateTime getEarlyCheckoutTime(DateTime date) {
    final parts = endTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var checkoutTime = DateTime(date.year, date.month, date.day, hour, minute);
    return checkoutTime.subtract(Duration(minutes: earlyLeaveTolerance));
  }

  /// Calculate max check-out time (end_time + max_checkout_hours)
  DateTime getMaxCheckoutTime(DateTime date) {
    final parts = endTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var checkoutTime = DateTime(date.year, date.month, date.day, hour, minute);
    return checkoutTime.add(Duration(hours: maxCheckoutHours));
  }

  /// Format time string to display format (HH:mm)
  String formatTime(String time) {
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }
}
