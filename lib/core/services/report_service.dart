import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/ocr_service.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<void> generateAndSavePdf({
    required String userName,
    required OcrResult ocrResult,
    required List<Map<String, dynamic>> examResults, // Updated to accept multiple exams
  }) async {
    final pdf = pw.Document();

    int totalEligible = 0;
    int totalIneligible = 0;
    for (var r in examResults) {
      if (r['isEligible'] == true) totalEligible++;
      else totalIneligible++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header ─────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'YOGYA',
                        style: pw.TextStyle(
                          color: PdfColors.blue800,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Advanced Eligibility Assessment',
                        style: const pw.TextStyle(
                          color: PdfColors.grey600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // ── Candidate Info ─────────────────────────────
            pw.Text(
              'Candidate Profile',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.blue800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildInfoRow('Name', userName),
            _buildInfoRow('Category', ocrResult.stream.isNotEmpty ? ocrResult.stream : 'General'),
            _buildInfoRow('DOB', ocrResult.dateOfBirth.isNotEmpty ? ocrResult.dateOfBirth : 'N/A'),
            _buildInfoRow('Highest Qualification', ocrResult.docType.isNotEmpty ? ocrResult.docType : 'N/A'),
            _buildInfoRow('Percentage / CGPA', ocrResult.aggregate.isNotEmpty ? ocrResult.aggregate : 'N/A'),

            pw.SizedBox(height: 30),

            // ── Summary ────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryBox('Total Exams', '${examResults.length}', PdfColors.blue800),
                  _buildSummaryBox('Eligible', '$totalEligible', PdfColors.green700),
                  _buildSummaryBox('Not Eligible', '$totalIneligible', PdfColors.red700),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // ── Exam Assessment Details ────────────────────
            pw.Text(
              'Detailed Exam Breakdown',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.blue800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),

            ...examResults.map((result) {
              final examName = result['examName'] as String;
              final isEligible = result['isEligible'] as bool;
              final missing = result['missingCriteria'] as List<String>;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: isEligible ? PdfColors.green50 : PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: isEligible ? PdfColors.green300 : PdfColors.red300,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      examName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Status: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          isEligible ? 'ELIGIBLE' : 'INELIGIBLE',
                          style: pw.TextStyle(
                            color: isEligible ? PdfColors.green700 : PdfColors.red700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (!isEligible && missing.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Missing Requirements:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.red800,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      ...missing.map((m) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2, left: 8),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• ', style: const pw.TextStyle(color: PdfColors.red800)),
                                pw.Expanded(
                                  child: pw.Text(
                                    m,
                                    style: const pw.TextStyle(color: PdfColors.red800, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 30),
            
            // ── Strategic Steps ────────────────────────────────
            pw.Text(
              'Strategic Next Steps',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.blue800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            if (totalEligible > 0)
              pw.Text(
                'Focus on preparing for the $totalEligible exams you qualify for. Review their syllabi and start practicing mock tests immediately.',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              )
            else
              pw.Text(
                'Currently, you do not meet the core requirements for these selected exams. Please verify your age limits carefully, explore state-level exams, or look out for category-specific age relaxations if applicable.',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              ),

            pw.Spacer(),

            // ── Footer ─────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'This is an auto-generated report by Yogya App\nNot for official verification purposes.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  color: PdfColors.grey500,
                  fontSize: 10,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save and print/share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${userName.replaceAll(' ', '_')}_Yogya_Advanced_Report.pdf',
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String label, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
