import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/services/csv_export_service.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvExportService Unit Tests', () {
    test('builds RFC-4180 compliant CSV with required column headers in exact order', () {
      final rows = [
        const RegistrationRow(
          userId: 'u1',
          studentName: 'Aisha Sharma',
          studentId: 'STU2026041',
          rollNo: '70012026041',
          programme: 'B.Tech',
          branch: 'Computer Engineering (CE)',
          academicYear: 'Third Year',
          collegeEmail: 'aisha.sharma@college.edu.example',
          registrationStatus: 'registered',
          attendanceStatus: AttendanceStatus.registered,
          attendedAt: null,
        ),
        RegistrationRow(
          userId: 'u2',
          studentName: 'Karan Mehta',
          studentId: 'STU2026042',
          rollNo: '70012026042',
          programme: 'B.Tech',
          branch: 'Information Technology (IT)',
          academicYear: 'Second Year',
          collegeEmail: 'karan.mehta@college.edu.example',
          registrationStatus: 'registered',
          attendanceStatus: AttendanceStatus.attended,
          attendedAt: DateTime(2026, 2, 20, 10, 15),
        ),
        const RegistrationRow(
          userId: 'u3',
          studentName: 'Patel, Raj "Ace"',
          studentId: 'STU2026043',
          rollNo: '70012026043',
          programme: 'MBA Tech',
          branch: 'Computer Engineering (CE)',
          academicYear: 'First Year',
          collegeEmail: 'raj.patel@college.edu.example',
          registrationStatus: 'registered',
          attendanceStatus: AttendanceStatus.registered,
          attendedAt: null,
        ),
      ];

      final csv = CsvExportService.buildStudentListCsv(registrations: rows);
      final lines = csv.trim().split('\n').map((l) => l.trim()).toList();

      expect(lines.length, 4); // 1 header + 3 rows

      // 1. Header row
      expect(
        lines[0],
        'Full Name,Student ID,Roll No,Programme,Branch,Academic Year,College Email,Registration Status,Attended,Attended At',
      );

      // 2. Not attended student (Aisha) -> Attended: No, Attended At: (blank)
      expect(
        lines[1],
        'Aisha Sharma,STU2026041,70012026041,B.Tech,Computer Engineering (CE),Third Year,aisha.sharma@college.edu.example,registered,No,',
      );

      // 3. Attended student (Karan) -> Attended: Yes, Attended At: formatted timestamp
      expect(
        lines[2],
        'Karan Mehta,STU2026042,70012026042,B.Tech,Information Technology (IT),Second Year,karan.mehta@college.edu.example,registered,Yes,2026-02-20 10:15',
      );

      // 4. Escaped student name with comma and quotes
      expect(
        lines[3],
        '"Patel, Raj ""Ace""",STU2026043,70012026043,MBA Tech,Computer Engineering (CE),First Year,raj.patel@college.edu.example,registered,No,',
      );
    });

    test('sanitizes event filename cleanly', () {
      final dt = DateTime(2026, 8, 30);
      final filename1 = CsvExportService.sanitizeFileName('AI & ML Workshop 2026!', dt);
      expect(filename1, 'ai_ml_workshop_2026_students_20260830.csv');

      final filename2 = CsvExportService.sanitizeFileName('   ', dt);
      expect(filename2, 'event_students_20260830.csv');
    });

    test('Demo Mode: Organizer and Admin can fetch registrations with attended and not-attended records', () async {
      DemoDataStore.instance.resetForTests();
      final orgRepo = DemoOrganizerRepository();
      final adminRepo = DemoAdminRepository();

      final orgResult = await orgRepo.registrationsFor('evt-1');
      expect(orgResult.isOk, isTrue);
      final orgRegs = orgResult.valueOrNull!;
      expect(orgRegs.length, 3);

      final aisha = orgRegs.firstWhere((r) => r.studentName == 'Aisha Sharma');
      expect(aisha.attendanceStatus, AttendanceStatus.registered);
      expect(aisha.attendedAt, isNull);
      expect(aisha.studentId, 'STU2026041');
      expect(aisha.rollNo, '70012026041');
      expect(aisha.programme, 'B.Tech');
      expect(aisha.branch, 'Computer Engineering (CE)');

      final karan = orgRegs.firstWhere((r) => r.studentName == 'Karan Mehta');
      expect(karan.attendanceStatus, AttendanceStatus.attended);
      expect(karan.attendedAt, DateTime(2026, 2, 20, 10, 15));

      final adminResult = await adminRepo.registrationsFor('evt-1');
      expect(adminResult.isOk, isTrue);
      final adminRegs = adminResult.valueOrNull!;
      expect(adminRegs.length, 3);

      final demoCsv = CsvExportService.buildStudentListCsv(registrations: orgRegs);
      expect(demoCsv.contains('Full Name,Student ID,Roll No,Programme,Branch,Academic Year,College Email,Registration Status,Attended,Attended At'), isTrue);
      expect(demoCsv.contains('Aisha Sharma,STU2026041,70012026041,B.Tech,Computer Engineering (CE),Third Year,demo.student@college.edu.example,registered,No,'), isTrue);
      expect(demoCsv.contains('Karan Mehta,STU2026042,70012026042,B.Tech,Information Technology (IT),Second Year,karan.mehta@college.edu.example,registered,Yes,2026-02-20 10:15'), isTrue);
    });
  });
}
