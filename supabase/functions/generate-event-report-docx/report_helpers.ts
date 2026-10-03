// supabase/functions/generate-event-report-docx/report_helpers.ts
//
// Pure, testable helper functions and docx builders for generate-event-report-docx.
// Contains zero server/request-handling code or test-conditional branching.

import {
  AlignmentType,
  BorderStyle,
  Document,
  HeadingLevel,
  ImageRun,
  Packer,
  Paragraph,
  Table,
  TableCell,
  TableRow,
  TextRun,
  WidthType,
} from 'https://esm.sh/docx@8.5.0';
import { NMIMS_LOGO_BASE64 } from './logo.ts';

export interface ReportGuest {
  name: string;
  designation: string;
  organization: string;
}

export interface ReportDocxData {
  event: any;
  report: any;
  registrationsCount: number;
  attendanceCount: number;
  attendancePercentage: string;
  programmeBreakdown: Array<{ label: string; count: number; pct: string }>;
  branchBreakdown: Array<{ label: string; count: number; pct: string }>;
  yearBreakdown: Array<{ label: string; count: number; pct: string }>;
  guests: Array<{ name: string; designation: string; organization: string }>;
  avgRating: string;
  reviewCount: number;
  ratingDist: Record<number, number>;
  confirmedByName: string;
}

export function parseGuests(rawGuestsInput: unknown): ReportGuest[] {
  let list: unknown[] = [];
  if (Array.isArray(rawGuestsInput)) {
    list = rawGuestsInput;
  } else if (typeof rawGuestsInput === 'string' && rawGuestsInput.trim().length > 0) {
    try {
      const parsed = JSON.parse(rawGuestsInput);
      if (Array.isArray(parsed)) {
        list = parsed;
      }
    } catch {
      list = [];
    }
  }

  return list
    .filter((item): item is Record<string, unknown> => typeof item === 'object' && item !== null)
    .map((g) => ({
      name: String(g.name ?? '').trim(),
      designation: String(g.designation ?? '').trim(),
      organization: String(g.organization ?? '').trim(),
    }))
    .filter((g) => g.name.length > 0 || g.designation.length > 0 || g.organization.length > 0);
}

export function computeBreakdown(rawItems: Array<string | null | undefined>): Array<{ label: string; count: number; pct: string }> {
  const counts: Record<string, number> = {};
  let total = 0;
  for (const item of rawItems) {
    const key = (item ?? '').trim() || 'N/A';
    counts[key] = (counts[key] ?? 0) + 1;
    total++;
  }
  return Object.entries(counts).map(([label, count]) => ({
    label,
    count,
    pct: total > 0 ? ((count / total) * 100).toFixed(1) : '0.0',
  }));
}

export async function buildReportDocx(data: ReportDocxData): Promise<Uint8Array> {
  const logoBytes = Uint8Array.from(atob(NMIMS_LOGO_BASE64), (c) => c.charCodeAt(0));
  const docIdRef = `REF: EVT-${data.event.id.slice(0, 8).toUpperCase()}`;
  const confirmedAtDate = data.report.confirmed_at ? new Date(data.report.confirmed_at).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }) : 'N/A';

  const doc = new Document({
    styles: {
      default: {
        document: {
          run: {
            font: 'Arial',
            size: 22, // 11pt
            color: '2D3748',
          },
        },
      },
    },
    sections: [
      {
        properties: {
          page: {
            margin: {
              top: 1440, // 1 inch
              bottom: 1440,
              left: 1440,
              right: 1440,
            },
          },
        },
        children: [
          // Header Table: Logo on Left, Institutional Titles on Right
          new Table({
            width: { size: 100, type: WidthType.PERCENTAGE },
            borders: {
              top: { style: BorderStyle.NONE },
              bottom: { style: BorderStyle.SINGLE, size: 6, color: 'CBD5E0' },
              left: { style: BorderStyle.NONE },
              right: { style: BorderStyle.NONE },
              insideHorizontal: { style: BorderStyle.NONE },
              insideVertical: { style: BorderStyle.NONE },
            },
            rows: [
              new TableRow({
                children: [
                  new TableCell({
                    width: { size: 30, type: WidthType.PERCENTAGE },
                    children: [
                      new Paragraph({
                        children: [
                          new ImageRun({
                            data: logoBytes,
                            transformation: { width: 140, height: 59 },
                          }),
                        ],
                      }),
                    ],
                  }),
                  new TableCell({
                    width: { size: 70, type: WidthType.PERCENTAGE },
                    children: [
                      new Paragraph({
                        alignment: AlignmentType.RIGHT,
                        children: [
                          new TextRun({
                            text: 'OFFICIAL POST-EVENT REPORT',
                            bold: true,
                            size: 26, // 13pt
                            color: '1A202C',
                          }),
                        ],
                      }),
                      new Paragraph({
                        alignment: AlignmentType.RIGHT,
                        children: [
                          new TextRun({
                            text: 'Submitted to College Leadership & Office of the Dean',
                            size: 18,
                            color: '718096',
                          }),
                        ],
                      }),
                      new Paragraph({
                        alignment: AlignmentType.RIGHT,
                        children: [
                          new TextRun({
                            text: `${docIdRef} · Confirmed: ${confirmedAtDate}`,
                            bold: true,
                            size: 16,
                            color: '2B6CB0',
                          }),
                        ],
                      }),
                    ],
                  }),
                ],
              }),
            ],
          }),

          new Paragraph({ spacing: { before: 240, after: 120 } }),

          // Document Title
          new Paragraph({
            heading: HeadingLevel.TITLE,
            children: [
              new TextRun({
                text: data.event.title,
                bold: true,
                size: 32, // 16pt
                color: '1A365D',
              }),
            ],
          }),

          new Paragraph({
            children: [
              new TextRun({
                text: `Organized by ${data.event.clubs?.name ?? 'Student Club'} · Category: ${data.event.categories?.name ?? 'College Event'}`,
                italics: true,
                size: 20,
                color: '4A5568',
              }),
            ],
            spacing: { after: 280 },
          }),

          // 1. Event Overview Table
          createSectionHeading('1. Event Overview'),
          createKeyValueTable([
            ['Event ID / Reference', docIdRef],
            ['Event Title', data.event.title],
            ['Organizing Club', data.event.clubs?.name ?? 'N/A'],
            ['Category', data.event.categories?.name ?? 'N/A'],
            ['Venue', data.event.venue ?? 'N/A'],
          ]),

          // 2. Event Description
          createSectionHeading('2. Event Description'),
          new Paragraph({
            children: [
              new TextRun({
                text: data.event.full_description || 'No detailed description provided.',
              }),
            ],
            spacing: { after: 240 },
          }),

          // 3. Event Schedule
          createSectionHeading('3. Event Schedule'),
          createKeyValueTable([
            ['Start Date & Time', formatDateTime(data.event.start_at)],
            ['End Date & Time', formatDateTime(data.event.end_at)],
          ]),

          // 4. Participation Summary
          createSectionHeading('4. Participation Summary'),
          createKeyValueTable([
            ['Total Registered Students', `${data.registrationsCount}`],
            ['Verified Attendees (Marked Present)', `${data.attendanceCount}`],
            ['Overall Attendance Rate', `${data.attendancePercentage}%`],
          ]),

          // 5. Participant Statistics
          createSectionHeading('5. Participant Demographics (Attended Students)'),
          new Paragraph({
            children: [
              new TextRun({
                text: 'Demographic breakdown of students who completed attendance verification:',
                italics: true,
                size: 18,
                color: '718096',
              }),
            ],
            spacing: { after: 120 },
          }),
          createBreakdownTable('Programme Breakdown', data.programmeBreakdown),
          new Paragraph({ spacing: { after: 120 } }),
          createBreakdownTable('Branch Breakdown', data.branchBreakdown),
          new Paragraph({ spacing: { after: 120 } }),
          createBreakdownTable('Academic Year Breakdown', data.yearBreakdown),
          new Paragraph({ spacing: { after: 240 } }),

          // 6. Guest / Speaker Details
          createSectionHeading('6. Guests & Resource Persons'),
          ...(data.guests.length === 0
            ? [
                new Paragraph({
                  children: [new TextRun({ text: 'No external guests or speakers were recorded for this event.', italics: true })],
                  spacing: { after: 240 },
                }),
              ]
            : [createGuestsTable(data.guests)]),

          // 7. Event Objectives & Outcomes
          createSectionHeading('7. Event Objectives & Key Outcomes'),
          new Paragraph({
            children: [
              new TextRun({ text: 'Event Objectives (Intended Goals):', bold: true, size: 22, color: '2B6CB0' }),
            ],
            spacing: { before: 80, after: 60 },
          }),
          ...formatBulletPoints(data.report.objectives),
          new Paragraph({
            children: [
              new TextRun({ text: 'Key Outcomes & Impact Achieved:', bold: true, size: 22, color: '2B6CB0' }),
            ],
            spacing: { before: 160, after: 60 },
          }),
          ...formatBulletPoints(data.report.outcomes),
          new Paragraph({ spacing: { after: 240 } }),

          // 8. Feedback Summary & Narrative
          createSectionHeading('8. Student Feedback & Narrative Analysis'),
          createKeyValueTable([
            ['Average Rating', `${data.avgRating} / 5.0 Stars`],
            ['Total Submitted Reviews', `${data.reviewCount} student review(s)`],
            [
              'Rating Distribution',
              `5★: ${data.ratingDist[5]}   |   4★: ${data.ratingDist[4]}   |   3★: ${data.ratingDist[3]}   |   2★: ${data.ratingDist[2]}   |   1★: ${data.ratingDist[1]}`,
            ],
          ]),
          new Paragraph({
            children: [
              new TextRun({ text: 'Feedback Narrative (Executive Summary):', bold: true, size: 22 }),
            ],
            spacing: { before: 120, after: 60 },
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: data.report.feedback_narrative || 'No written feedback comments submitted.',
              }),
            ],
            spacing: { after: 240 },
          }),

          // 9. Organizer Details & Institutional Sign-off
          createSectionHeading('9. Organizer Details & Institutional Verification'),
          createKeyValueTable([
            ['Organizing Club', data.event.clubs?.name ?? 'N/A'],
            ['Official Contact Email', data.event.clubs?.contact_email ?? 'N/A'],
            ['Report Confirmed By', `${data.confirmedByName} (Verified Organizer)`],
            ['Confirmation Date', confirmedAtDate],
          ]),
          new Paragraph({ spacing: { before: 360, after: 120 } }),

          // Formal Signature Block
          new Table({
            width: { size: 100, type: WidthType.PERCENTAGE },
            borders: {
              top: { style: BorderStyle.NONE },
              bottom: { style: BorderStyle.NONE },
              left: { style: BorderStyle.NONE },
              right: { style: BorderStyle.NONE },
              insideHorizontal: { style: BorderStyle.NONE },
              insideVertical: { style: BorderStyle.NONE },
            },
            rows: [
              new TableRow({
                children: [
                  new TableCell({
                    width: { size: 33, type: WidthType.PERCENTAGE },
                    children: [
                      new Paragraph({ children: [new TextRun({ text: '_________________________', bold: true })] }),
                      new Paragraph({ children: [new TextRun({ text: 'Club Event Lead / Organizer', bold: true, size: 18 })] }),
                      new Paragraph({ children: [new TextRun({ text: data.confirmedByName, size: 16, color: '718096' })] }),
                    ],
                  }),
                  new TableCell({
                    width: { size: 34, type: WidthType.PERCENTAGE },
                    children: [
                      new Paragraph({ children: [new TextRun({ text: '_________________________', bold: true })] }),
                      new Paragraph({ children: [new TextRun({ text: 'Faculty Coordinator', bold: true, size: 18 })] }),
                      new Paragraph({ children: [new TextRun({ text: 'Faculty In-Charge', size: 16, color: '718096' })] }),
                    ],
                  }),
                  new TableCell({
                    width: { size: 33, type: WidthType.PERCENTAGE },
                    children: [
                      new Paragraph({ children: [new TextRun({ text: '_________________________', bold: true })] }),
                      new Paragraph({ children: [new TextRun({ text: 'Dean / Institutional Lead', bold: true, size: 18 })] }),
                      new Paragraph({ children: [new TextRun({ text: 'Office of Academic Affairs', size: 16, color: '718096' })] }),
                    ],
                  }),
                ],
              }),
            ],
          }),
        ],
      },
    ],
  });

  const buffer = await Packer.toBuffer(doc);
  return new Uint8Array(buffer);
}

export function createSectionHeading(text: string): Paragraph {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    children: [
      new TextRun({
        text,
        bold: true,
        size: 24, // 12pt
        color: '1A365D',
      }),
    ],
    spacing: { before: 240, after: 120 },
    border: {
      bottom: { style: BorderStyle.SINGLE, size: 4, color: 'E2E8F0' },
    },
  });
}

export function createKeyValueTable(rows: [string, string][]): Table {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
      left: { style: BorderStyle.NONE },
      right: { style: BorderStyle.NONE },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'EDF2F7' },
      insideVertical: { style: BorderStyle.NONE },
    },
    rows: rows.map(
      ([key, value]) =>
        new TableRow({
          children: [
            new TableCell({
              width: { size: 32, type: WidthType.PERCENTAGE },
              children: [
                new Paragraph({
                  children: [new TextRun({ text: key, bold: true, size: 19, color: '4A5568' })],
                }),
              ],
            }),
            new TableCell({
              width: { size: 68, type: WidthType.PERCENTAGE },
              children: [
                new Paragraph({
                  children: [new TextRun({ text: value || 'N/A', size: 20 })],
                }),
              ],
            }),
          ],
        }),
    ),
  });
}

export function createBreakdownTable(title: string, items: Array<{ label: string; count: number; pct: string }>): Table {
  const rows = [
    new TableRow({
      children: [
        new TableCell({
          width: { size: 60, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: title, bold: true, size: 18 })] })],
        }),
        new TableCell({
          width: { size: 20, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: 'Count', bold: true, size: 18 })] })],
        }),
        new TableCell({
          width: { size: 20, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: 'Percentage', bold: true, size: 18 })] })],
        }),
      ],
    }),
  ];

  if (items.length === 0) {
    rows.push(
      new TableRow({
        children: [
          new TableCell({
            columnSpan: 3,
            children: [new Paragraph({ children: [new TextRun({ text: 'No demographic records found.', italics: true })] })],
          }),
        ],
      }),
    );
  } else {
    for (const item of items) {
      rows.push(
        new TableRow({
          children: [
            new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: item.label, size: 18 })] })] }),
            new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: `${item.count}`, size: 18 })] })] }),
            new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: `${item.pct}%`, size: 18 })] })] }),
          ],
        }),
      );
    }
  }

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      left: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      right: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
      insideVertical: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
    },
    rows,
  });
}

export function createGuestsTable(guests: Array<{ name: string; designation: string; organization: string }>): Table {
  const rows = [
    new TableRow({
      children: [
        new TableCell({
          width: { size: 35, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: 'Guest Name', bold: true, size: 18 })] })],
        }),
        new TableCell({
          width: { size: 35, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: 'Designation', bold: true, size: 18 })] })],
        }),
        new TableCell({
          width: { size: 30, type: WidthType.PERCENTAGE },
          shading: { fill: 'EDF2F7' },
          children: [new Paragraph({ children: [new TextRun({ text: 'Organization', bold: true, size: 18 })] })],
        }),
      ],
    }),
  ];

  for (const g of guests) {
    rows.push(
      new TableRow({
        children: [
          new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: g.name, bold: true, size: 18 })] })] }),
          new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: g.designation, size: 18 })] })] }),
          new TableCell({ children: [new Paragraph({ children: [new TextRun({ text: g.organization, size: 18 })] })] }),
        ],
      }),
    );
  }

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      left: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      right: { style: BorderStyle.SINGLE, size: 2, color: 'CBD5E0' },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
      insideVertical: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
    },
    rows,
  });
}

export function formatBulletPoints(text: string | null | undefined): Paragraph[] {
  if (!text || text.trim().length === 0) {
    return [new Paragraph({ children: [new TextRun({ text: 'None recorded.', italics: true })] })];
  }

  const lines = text
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  return lines.map((line) => {
    const cleanLine = line.replace(/^[•\-\*]\s*/, '');
    return new Paragraph({
      bullet: { level: 0 },
      children: [new TextRun({ text: cleanLine, size: 20 })],
      spacing: { before: 40, after: 40 },
    });
  });
}

export function formatDateTime(isoString: string | null | undefined): string {
  if (!isoString) return 'N/A';
  try {
    const d = new Date(isoString);
    return d.toLocaleDateString('en-IN', {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return isoString;
  }
}
