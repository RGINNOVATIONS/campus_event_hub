// supabase/functions/generate-event-report-docx/index_test.ts
//
// Tests that generate-event-report-docx correctly parses the Round 1 events.guests
// JSONB column and passes populated guest data into buildReportDocx() to produce
// an official Word document with a populated guest table.
// Imports directly from report_helpers.ts without touching the Deno.serve entry point.

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { Table, TableRow } from 'https://esm.sh/docx@8.5.0';
import {
  buildReportDocx,
  createGuestsTable,
  parseGuests,
} from './report_helpers.ts';

Deno.test('parseGuests: parses Round 1 JSONB array of guest objects', () => {
  const round1GuestsJson = [
    {
      name: 'Dr. Jane Smith',
      designation: 'Keynote Speaker & AI Scientist',
      organization: 'DeepMind Robotics',
    },
    {
      name: 'Prof. Rajesh Sharma',
      designation: 'Department Head',
      organization: 'IIT Bombay',
    },
  ];

  const guests = parseGuests(round1GuestsJson);
  assertEquals(guests.length, 2);
  assertEquals(guests[0], {
    name: 'Dr. Jane Smith',
    designation: 'Keynote Speaker & AI Scientist',
    organization: 'DeepMind Robotics',
  });
  assertEquals(guests[1], {
    name: 'Prof. Rajesh Sharma',
    designation: 'Department Head',
    organization: 'IIT Bombay',
  });
});

Deno.test('parseGuests: parses stringified JSONB column value', () => {
  const serialized = JSON.stringify([
    {
      name: '  Ms. Anita Roy  ',
      designation: '  Product VP  ',
      organization: '  Google  ',
    },
  ]);

  const guests = parseGuests(serialized);
  assertEquals(guests.length, 1);
  assertEquals(guests[0], {
    name: 'Ms. Anita Roy',
    designation: 'Product VP',
    organization: 'Google',
  });
});

Deno.test('parseGuests: safely returns empty list on null, undefined, or empty array', () => {
  assertEquals(parseGuests(null), []);
  assertEquals(parseGuests(undefined), []);
  assertEquals(parseGuests([]), []);
  assertEquals(parseGuests(''), []);
  assertEquals(parseGuests('not-valid-json'), []);
});

Deno.test('buildReportDocx: event WITH guests in Round 1 guests column passes populated data and produces table', async () => {
  // 1. Simulating event row from PostgreSQL with Round 1 guests JSONB column
  const eventRow = {
    id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    title: 'National AI & Robotics Symposium 2026',
    full_description: 'Two-day symposium featuring keynote lectures and student project showcases.',
    club_id: 'club-robotics-001',
    status: 'completed',
    start_at: '2026-09-20T09:00:00Z',
    end_at: '2026-09-21T17:00:00Z',
    venue: 'Main Auditorium & CS Labs',
    guests: [
      {
        name: 'Dr. Jane Smith',
        designation: 'Director of AI Research',
        organization: 'RoboTech Labs',
      },
      {
        name: 'Mr. Rajesh Verma',
        designation: 'Principal Systems Architect',
        organization: 'Intel AI',
      },
    ],
    categories: { name: 'Technical' },
    clubs: { name: 'Robotics & Automation Club', contact_email: 'robotics@nmims.edu' },
  };

  // 2. Parse guests directly from event.guests (matching index.ts Step 8)
  const parsedGuests = parseGuests(eventRow.guests);

  // 3. Assemble data passed into buildReportDocx (matching index.ts Step 11)
  const reportDocxData = {
    event: eventRow,
    report: {
      id: 'rep-001',
      event_id: eventRow.id,
      status: 'confirmed',
      confirmed_at: '2026-09-22T10:30:00Z',
      objectives: '• Educate attendees on autonomous robotics architectures.\n• Showcase state-of-the-art edge AI prototypes.',
      outcomes: '• 120 attendees completed hands-on simulation labs.\n• 15 functional robotics prototypes reviewed by industry jury.',
      feedback_narrative: 'Student participants commended the keynote speakers and practical laboratory sessions.',
    },
    registrationsCount: 150,
    attendanceCount: 120,
    attendancePercentage: '80.0',
    programmeBreakdown: [{ label: 'B.Tech', count: 120, pct: '100.0' }],
    branchBreakdown: [{ label: 'Computer Engineering', count: 120, pct: '100.0' }],
    yearBreakdown: [{ label: 'Third Year', count: 120, pct: '100.0' }],
    guests: parsedGuests, // <-- Data actually passed into buildReportDocx()
    avgRating: '4.9',
    reviewCount: 42,
    ratingDist: { 5: 38, 4: 4, 3: 0, 2: 0, 1: 0 },
    confirmedByName: 'Dr. Swapnil Mahajan',
  };

  // 4. Verify the data ACTUALLY passed into buildReportDocx() has the populated guest records
  assertEquals(reportDocxData.guests.length, 2);
  assertEquals(reportDocxData.guests[0].name, 'Dr. Jane Smith');
  assertEquals(reportDocxData.guests[0].designation, 'Director of AI Research');
  assertEquals(reportDocxData.guests[0].organization, 'RoboTech Labs');
  assertEquals(reportDocxData.guests[1].name, 'Mr. Rajesh Verma');
  assertEquals(reportDocxData.guests[1].designation, 'Principal Systems Architect');
  assertEquals(reportDocxData.guests[1].organization, 'Intel AI');

  // 5. Verify createGuestsTable builds a Table with header row + 2 guest rows = 3 TableRow items
  const guestTable = createGuestsTable(reportDocxData.guests);
  assert(guestTable instanceof Table);
  const rows = (guestTable as any).root.filter((child: any) => child instanceof TableRow);
  assertEquals(rows.length, 3);

  // 6. Verify buildReportDocx runs and outputs a valid .docx binary (starts with PK zip header)
  const docxBytes = await buildReportDocx(reportDocxData);
  assert(docxBytes instanceof Uint8Array);
  assert(docxBytes.length > 5000);
  // PK\x03\x04 zip signature
  assertEquals(docxBytes[0], 0x50);
  assertEquals(docxBytes[1], 0x4B);
  assertEquals(docxBytes[2], 0x03);
  assertEquals(docxBytes[3], 0x04);
});

Deno.test('buildReportDocx: event with EMPTY guests produces docx without table error', async () => {
  const eventRow = {
    id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    title: 'Internal Club Orientation',
    full_description: 'Welcome session for junior members.',
    club_id: 'club-robotics-001',
    status: 'completed',
    start_at: '2026-09-15T15:00:00Z',
    end_at: '2026-09-15T17:00:00Z',
    venue: 'Room 204',
    guests: [],
    categories: { name: 'Orientation' },
    clubs: { name: 'Robotics & Automation Club', contact_email: 'robotics@nmims.edu' },
  };

  const guests = parseGuests(eventRow.guests);
  assertEquals(guests.length, 0);

  const reportDocxData = {
    event: eventRow,
    report: {
      id: 'rep-002',
      event_id: eventRow.id,
      status: 'confirmed',
      confirmed_at: '2026-09-16T10:00:00Z',
      objectives: '• Introduce club charter and semester roadmap.',
      outcomes: '• 40 new members onboarded.',
      feedback_narrative: 'Positive onboarding reception.',
    },
    registrationsCount: 45,
    attendanceCount: 40,
    attendancePercentage: '88.9',
    programmeBreakdown: [{ label: 'B.Tech', count: 40, pct: '100.0' }],
    branchBreakdown: [{ label: 'Information Technology', count: 40, pct: '100.0' }],
    yearBreakdown: [{ label: 'First Year', count: 40, pct: '100.0' }],
    guests,
    avgRating: '4.5',
    reviewCount: 10,
    ratingDist: { 5: 6, 4: 3, 3: 1, 2: 0, 1: 0 },
    confirmedByName: 'Dr. Swapnil Mahajan',
  };

  const docxBytes = await buildReportDocx(reportDocxData);
  assert(docxBytes instanceof Uint8Array);
  assert(docxBytes.length > 5000);
  assertEquals(docxBytes[0], 0x50);
  assertEquals(docxBytes[1], 0x4B);
  assertEquals(docxBytes[2], 0x03);
  assertEquals(docxBytes[3], 0x04);
});
