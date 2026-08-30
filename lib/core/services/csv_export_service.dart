import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:intl/intl.dart';

/// RFC-4180 compliant CSV generator for event attendee lists.
class CsvExportService {
  CsvExportService._();

  /// Generates the complete CSV string for [registrations] adhering strictly
  /// to the column specification:
  /// 1. Full Name
  /// 2. Student ID
  /// 3. Roll No
  /// 4. Programme
  /// 5. Branch
  /// 6. Academic Year
  /// 7. College Email
  /// 8. Registration Status
  /// 9. Attended (Yes/No)
  /// 10. Attended At (formatted timestamp or blank)
  static String buildStudentListCsv({
    required List<RegistrationRow> registrations,
    DateFormat? attendedAtFormatter,
  }) {
    final fmt = attendedAtFormatter ?? DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer();

    // 1. Header row
    final headers = [
      'Full Name',
      'Student ID',
      'Roll No',
      'Programme',
      'Branch',
      'Academic Year',
      'College Email',
      'Registration Status',
      'Attended',
      'Attended At',
    ];
    buffer.writeln(headers.map(_escapeCsvValue).join(','));

    // 2. Data rows
    for (final reg in registrations) {
      final isAttended = reg.attendanceStatus == AttendanceStatus.attended;
      final attendedStr = isAttended ? 'Yes' : 'No';
      final attendedAtStr = (isAttended && reg.attendedAt != null)
          ? fmt.format(reg.attendedAt!)
          : '';

      final row = [
        reg.studentName,
        reg.studentId,
        reg.rollNo,
        reg.programme,
        reg.branch,
        reg.academicYear,
        reg.collegeEmail,
        reg.registrationStatus,
        attendedStr,
        attendedAtStr,
      ];
      buffer.writeln(row.map(_escapeCsvValue).join(','));
    }

    return buffer.toString();
  }

  /// Sanitizes an event title and generates a file name formatted as:
  /// `<event_name>_students_<yyyyMMdd>.csv`
  static String sanitizeFileName(String eventTitle, DateTime date) {
    final cleanTitle = eventTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safePrefix = cleanTitle.isEmpty ? 'event' : cleanTitle;
    final dateStr = DateFormat('yyyyMMdd').format(date);
    return '${safePrefix}_students_$dateStr.csv';
  }

  /// Escapes CSV values according to RFC-4180.
  static String _escapeCsvValue(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
