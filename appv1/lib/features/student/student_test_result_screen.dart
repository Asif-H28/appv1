import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:appv1/core/constants/api_constants.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

const Color _accent = Colors.teal;

// ── Language enum ──────────────────────────────────────────

enum _Lang { english, kannada }

// ── Kannada translations ───────────────────────────────────
const Map<String, String> _kn = {
  'overview': 'ಸಾರಾಂಶ',
  'strengths': 'ಬಲಗಳು',
  'improve': 'ಸುಧಾರಿಸಬೇಕಾದ ಕ್ಷೇತ್ರಗಳು',
  'recommendations': 'ಶಿಫಾರಸುಗಳು',
  'ai_summary_title': 'AI ಕಾರ್ಯಕ್ಷಮತೆ ಸಾರಾಂಶ',
  'powered_by': 'Gemini AI ನಿಂದ ನಿರ್ವಹಿಸಲ್ಪಡುತ್ತದೆ',
  'no_summary': 'ಇನ್ನೂ AI ಸಾರಾಂಶ ಇಲ್ಲ',
  'generate_desc':
      'ನಿಮ್ಮ ಕಾರ್ಯಕ್ಷಮತೆಯ ವೈಯಕ್ತಿಕ AI-ಚಾಲಿತ ವಿಶ್ಲೇಷಣೆ ರಚಿಸಿ.',
  'generate_btn': 'AI ಸಾರಾಂಶ ರಚಿಸಿ',
  'generating': 'ರಚಿಸಲಾಗುತ್ತಿದೆ...',
  'generated_on': 'ರಚಿಸಲಾದ ದಿನಾಂಕ',
  'checking': 'AI ಸಾರಾಂಶ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
  'scholastic': 'ಶೈಕ್ಷಣಿಕ ಕ್ಷೇತ್ರಗಳು',
  'co_scholastic': 'ಸಹ-ಶೈಕ್ಷಣಿಕ ಚಟುವಟಿಕೆಗಳು',
  'overall': 'ಒಟ್ಟು ಕಾರ್ಯಕ್ಷಮತೆ',
  'total': 'ಒಟ್ಟು',
  'subject': 'ವಿಷಯ',
  'marks': 'ಅಂಕಗಳು',
  'grade': 'ದರ್ಜೆ',
  'activity': 'ಚಟುವಟಿಕೆ',
  'result_not_published': 'ಫಲಿತಾಂಶ ಪ್ರಕಟಿಸಲಾಗಿಲ್ಲ',
  'result_not_published_desc':
      'ನಿಮ್ಮ ಶಿಕ್ಷಕರು ಇನ್ನೂ ಈ ಮೌಲ್ಯಮಾಪನಕ್ಕಾಗಿ ನಿಮ್ಮ ಫಲಿತಾಂಶ ಪ್ರಕಟಿಸಿಲ್ಲ.',
  'published_by': 'ಪ್ರಕಟಿಸಿದ',
  'my_result': 'ನನ್ನ ಫಲಿತಾಂಶ',
  'download_report': 'ವರದಿ ಡೌನ್‌ಲೋಡ್',
};

String _t(String key, _Lang lang) =>
    lang == _Lang.kannada ? (_kn[key] ?? key) : _en(key);

String _en(String key) {
  const en = {
    'overview': 'Overview',
    'strengths': 'Strengths',
    'improve': 'Areas to Improve',
    'recommendations': 'Recommendations',
    'ai_summary_title': 'AI Performance Summary',
    'powered_by': 'Powered by Gemini AI',
    'no_summary': 'No AI Summary Yet',
    'generate_desc':
        'Generate a personalised AI-powered analysis of your performance — strengths, areas to improve, and recommendations.',
    'generate_btn': 'Generate AI Summary',
    'generating': 'Generating...',
    'generated_on': 'Generated on',
    'checking': 'Checking for AI summary...',
    'scholastic': 'SCHOLASTIC AREAS',
    'co_scholastic': 'CO-SCHOLASTIC ACTIVITIES',
    'overall': 'Overall Performance',
    'total': 'Total',
    'subject': 'SUBJECT',
    'marks': 'MARKS',
    'grade': 'GRADE',
    'activity': 'ACTIVITY',
    'result_not_published': 'Result Not Published',
    'result_not_published_desc':
        'Your teacher has not published your result for this assessment yet.',
    'published_by': 'Published by',
    'my_result': 'My Result',
    'download_report': 'Download Report',
  };
  return en[key] ?? key;
}

// ──────────────────────────────────────────────────────────
class StudentTestResultScreen extends StatefulWidget {
  final Map<String, dynamic> test;
  const StudentTestResultScreen({required this.test});

  @override
  _StudentTestResultScreenState createState() =>
      _StudentTestResultScreenState();
}

class _StudentTestResultScreenState extends State<StudentTestResultScreen> {
  // ── Result state ───────────────────────────────────────
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _result;
  String _studentId = '';

  // ── AI Summary state ───────────────────────────────────
  bool _summaryLoading = true;
  bool _generating = false;
  bool _summaryGenerated = false;
  Map<String, dynamic>? _summary;

  // ── Language / PDF state ───────────────────────────────
  _Lang _lang = _Lang.english;
  bool _downloading = false;

  // ── Student/school info from SharedPreferences ─────────
  String _studentName = '';
  String _className = '';
  String _orgName = '';
  String _orgId = '';
  String _orgAddress = '';
  String _studentEmail = '';

  String get _testId =>
      widget.test['assessmentId']?.toString() ??
      widget.test['_id']?.toString() ??
      '';
  String get _title => widget.test['title']?.toString() ?? 'Assessment';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('studentId') ?? '';
    _studentName = prefs.getString('name') ?? '';
    _className = prefs.getString('className') ?? '';
    _orgName = prefs.getString('orgName') ?? '';
    _orgId = prefs.getString('orgId') ?? '';
    _studentEmail = prefs.getString('email') ?? '';
    await _fetchOrgDetails();
    await Future.wait([_fetchResult(), _fetchSummary()]);
  }

  Future<void> _fetchOrgDetails() async {
    if (_orgId.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/org/school/$_orgId/public'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _orgName = body['data']['schoolName']?.toString() ?? _orgName;
            _orgAddress = body['data']['address']?.toString() ?? '';
          });
        }
      }
    } catch (_) {}
  }

  // ── Fetch result ───────────────────────────────────────

  Future<void> _fetchResult() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    if (_studentId.isEmpty) {
      setState(() {
        _error = 'Student ID not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConstants.apiBaseUrl}/comprehensive-result/assessment/$_testId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body['data'] != null) {
          raw = body['data'] as List;
        }

        final match = raw
            .cast<Map<String, dynamic>>()
            .where((r) => r['studentId']?.toString() == _studentId)
            .toList();

        setState(() {
          _result = match.isNotEmpty ? match.first : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load result.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  // ── Fetch existing AI summary (GET) ───────────────────

  Future<void> _fetchSummary() async {
    if (_studentId.isEmpty || _testId.isEmpty) {
      setState(() => _summaryLoading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConstants.apiBaseUrl}/comprehensive-result/summary/$_studentId/$_testId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final s = body['summary'] as Map<String, dynamic>?;
        setState(() {
          _summary = s;
          _summaryGenerated = s != null;
          _summaryLoading = false;
        });
      } else {
        setState(() {
          _summary = null;
          _summaryGenerated = false;
          _summaryLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  // ── Generate AI summary (POST) ────────────────────────

  Future<void> _generateSummary() async {
    if (_generating || _summaryGenerated) return;
    setState(() => _generating = true);

    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConstants.apiBaseUrl}/comprehensive-result/summary/$_studentId/$_testId'),
        headers: await ApiService.getHeaders(),
      );
      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 409) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        Map<String, dynamic>? s = body['summary'] as Map<String, dynamic>?;
        if (s == null) {
          await _fetchSummary();
          setState(() => _generating = false);
          return;
        }
        setState(() {
          _summary = s;
          _summaryGenerated = true;
          _generating = false;
        });
      } else {
        setState(() => _generating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate summary. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── PDF Generation & Download ─────────────────────────

  Future<void> _downloadReport() async {
    if (_result == null) return;
    setState(() => _downloading = true);

    try {
      if (Platform.isAndroid) {
        // Just request it for older Android versions. 
        // On Android 13+ it may return denied, but scoped storage allows writing to Downloads anyway.
        await Permission.storage.request();
      }

      final pdfBytes = await _buildPdf();
      final fileName =
          'Report_${_studentName.replaceAll(' ', '_')}_${_title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      String savePath;
      if (Platform.isAndroid) {
        savePath = '/storage/emulated/0/Download/$fileName';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName';
      }

      final file = File(savePath);
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;
      setState(() => _downloading = false);
      _showSnack('Report saved to Downloads!', isError: false);

      // Open immediately
      await OpenFile.open(savePath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      _showSnack('Failed to download: $e', isError: true);
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final result = _result!;
    final scholastic = result['scholasticResults'] as List? ?? [];
    final coScholastic = result['coScholasticResults'] as List? ?? [];

    double totalScored = 0;
    double totalMax = 0;
    for (final s in scholastic) {
      totalScored += (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
      final subName = s['subjectName']?.toString();
      final assessmentSubjects =
          widget.test['scholasticSubjects'] as List? ?? [];
      final assessmentSub = assessmentSubjects.firstWhere(
        (as) => as['subjectName'] == subName,
        orElse: () => null,
      );
      if (assessmentSub != null) {
        final iMax =
            (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
        final eMax =
            (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
        totalMax += iMax + eMax;
      }
    }

    final teal = PdfColor.fromHex('#00897B');
    final darkTeal = PdfColor.fromHex('#004D40');
    final lightTeal = PdfColor.fromHex('#E0F2F1');
    final grey50 = PdfColor.fromHex('#FAFAFA');
    final grey200 = PdfColor.fromHex('#EEEEEE');
    final grey600 = PdfColor.fromHex('#757575');
    final black = PdfColors.black;
    final white = PdfColors.white;

    // Fonts
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    String dateNow() {
      final d = DateTime.now();
      return '${d.day}/${d.month}/${d.year}';
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          children: [
            // ── School header ──
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: black, width: 2)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _orgName.isNotEmpty ? _orgName : 'School Name',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 22,
                      color: black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (_orgAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _orgAddress,
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 11,
                        color: grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'COMPREHENSIVE ASSESSMENT REPORT',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 12,
                      color: black,
                      letterSpacing: 1.2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Student details ──
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: grey50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: grey200, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfKV('Student', _studentName, bold, regular, black),
                      pw.SizedBox(height: 4),
                      _pdfKV('Class', _className, bold, regular, black),
                      if (_studentEmail.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        _pdfKV(
                            'Email', _studentEmail, bold, regular, grey600),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _pdfKV(
                          'Assessment', _title, bold, regular, black),
                      pw.SizedBox(height: 4),
                      _pdfKV('Date', dateNow(), bold, regular, grey600),
                      pw.SizedBox(height: 4),
                      _pdfKV(
                          'Total',
                          '${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                          bold,
                          bold,
                          black),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (ctx) => [
          // ── Scholastic ──
          if (scholastic.isNotEmpty) ...[
            _pdfSectionLabel('SCHOLASTIC AREAS', bold, black),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: grey200, width: 1),
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: grey200),
                  children: [
                    _pdfCell('Subject', bold, black, isHeader: true),
                    _pdfCell('Internal', bold, black, isHeader: true),
                    _pdfCell('External', bold, black, isHeader: true),
                    _pdfCell('Total', bold, black, isHeader: true),
                    _pdfCell('Grade', bold, black, isHeader: true),
                  ],
                ),
                // Subject rows
                ...scholastic.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value as Map<String, dynamic>;
                  final subName = s['subjectName']?.toString() ?? '';
                  final internal = (s['internalMarksScored'] as num?)
                          ?.toStringAsFixed(0) ??
                      '-';
                  final external = (s['externalMarksScored'] as num?)
                          ?.toStringAsFixed(0) ??
                      '-';
                  final scored = (s['totalMarksScored'] as num?)
                          ?.toStringAsFixed(0) ??
                      '-';
                  final grade = s['grade']?.toString() ?? '-';
                  final bg = i.isEven ? white : grey50;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _pdfCell(subName, bold, black),
                      _pdfCell(internal, regular, black,
                          align: pw.TextAlign.center),
                      _pdfCell(external, regular, black,
                          align: pw.TextAlign.center),
                      _pdfCell(scored, bold, black,
                          align: pw.TextAlign.center),
                      _pdfCell(grade, bold, black,
                          align: pw.TextAlign.center),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: grey200),
                  children: [
                    _pdfCell('TOTAL', bold, black),
                    _pdfCell('', regular, black),
                    _pdfCell('', regular, black),
                    _pdfCell(
                        '${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                        bold,
                        black,
                        align: pw.TextAlign.center),
                    _pdfCell('', regular, black),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Co-scholastic ──
          if (coScholastic.isNotEmpty) ...[
            _pdfSectionLabel('CO-SCHOLASTIC ACTIVITIES', bold, black),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: grey200, width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: grey200),
                  children: [
                    _pdfCell('Activity', bold, black, isHeader: true),
                    _pdfCell('Grade', bold, black, isHeader: true),
                  ],
                ),
                ...coScholastic.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value as Map<String, dynamic>;
                  final name = c['activityName']?.toString() ?? '';
                  final grade = c['grade']?.toString() ?? '-';
                  final bg = i.isEven ? white : grey50;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _pdfCell(name, bold, black),
                      _pdfCell(grade, bold, black,
                          align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── AI Summary ──
          if (_summary != null) ...[
            _pdfSectionLabel('AI PERFORMANCE SUMMARY', bold, black),
            pw.SizedBox(height: 8),
            _buildPdfSummarySection(_summary!, bold, regular, black, black,
                black, grey50, grey50),
          ],

          // ── Footer note ──
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: grey50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: grey200, width: 0.5),
            ),
            child: pw.Text(
              'This report was auto-generated by SchoolSync on ${dateNow()}. Powered by Gemini AI.',
              style: pw.TextStyle(
                font: regular,
                fontSize: 8,
                color: grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPdfSummarySection(
    Map<String, dynamic> s,
    pw.Font bold,
    pw.Font regular,
    PdfColor black,
    PdfColor teal,
    PdfColor darkTeal,
    PdfColor lightTeal,
    PdfColor grey50,
  ) {
    final langKey = _lang == _Lang.kannada ? 'kannada' : 'english';
    final data = s[langKey] as Map<String, dynamic>? ?? s;
    
    final overallSummary = data['overallSummary']?.toString() ?? '';
    final strengths = (data['strengths'] as List?)?.cast<String>() ?? [];
    final improvements =
        (data['areasForImprovement'] as List?)?.cast<String>() ?? [];
    final recommendations =
        (data['recommendations'] as List?)?.cast<String>() ?? [];
    final motivationalNote = data['motivationalNote']?.toString() ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (overallSummary.isNotEmpty) ...[
          _pdfSummaryBlock(
              'Overview', overallSummary, bold, regular, teal, lightTeal,
              isBullet: false),
          pw.SizedBox(height: 8),
        ],
        if (strengths.isNotEmpty) ...[
          _pdfSummaryBlock(
              'Strengths', strengths.join('\n'), bold, regular, teal, lightTeal,
              bullets: strengths),
          pw.SizedBox(height: 8),
        ],
        if (improvements.isNotEmpty) ...[
          _pdfSummaryBlock('Areas to Improve', '', bold, regular, teal,
              lightTeal,
              bullets: improvements),
          pw.SizedBox(height: 8),
        ],
        if (recommendations.isNotEmpty) ...[
          _pdfSummaryBlock('Recommendations', '', bold, regular, teal,
              lightTeal,
              bullets: recommendations),
          pw.SizedBox(height: 8),
        ],
        if (motivationalNote.isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FAFAFA'),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColor.fromHex('#EEEEEE'), width: 1),
            ),
            child: pw.Text(
              '"$motivationalNote"',
              style: pw.TextStyle(
                font: regular,
                fontSize: 10,
                color: PdfColors.black,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _pdfSummaryBlock(
    String title,
    String text,
    pw.Font bold,
    pw.Font regular,
    PdfColor borderColor,
    PdfColor bgColor, {
    bool isBullet = true,
    List<String> bullets = const [],
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#EEEEEE'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FAFAFA')),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            width: double.infinity,
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Container(height: 1, color: PdfColor.fromHex('#EEEEEE')),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: bullets.isNotEmpty
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: bullets
                        .map((b) => pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('• ',
                                      style: pw.TextStyle(
                                          font: bold,
                                          fontSize: 10,
                                          color: PdfColors.black)),
                                  pw.Expanded(
                                    child: pw.Text(b,
                                        style: pw.TextStyle(
                                            font: regular, fontSize: 10)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  )
                : pw.Text(text,
                    style: pw.TextStyle(font: regular, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, pw.Font font, PdfColor color,
      {bool isHeader = false,
      pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 10,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _pdfKV(String key, String value, pw.Font bold, pw.Font regular,
      PdfColor valueColor) {
    return pw.Row(
      children: [
        pw.Text('$key: ',
            style: pw.TextStyle(font: bold, fontSize: 9)),
        pw.Text(value,
            style: pw.TextStyle(
                font: regular, fontSize: 9, color: valueColor)),
      ],
    );
  }

  pw.Widget _pdfSectionLabel(
      String label, pw.Font bold, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 14, color: color),
        pw.SizedBox(width: 8),
        pw.Text(
          label,
          style: pw.TextStyle(font: bold, fontSize: 11, color: color),
        ),
      ],
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // ── Gradient header ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      // Back
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Icon
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _t('my_result', _lang),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Download button ──
                      if (_result != null)
                        GestureDetector(
                          onTap: _downloading ? null : _downloadReport,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                  _downloading ? 0.1 : 0.22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: _downloading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.download_rounded,
                                          color: Colors.white,
                                          size: 16),
                                      const SizedBox(width: 5),
                                      Text(
                                        _t('download_report', _lang),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error.isNotEmpty
                      ? _buildError()
                      : _result == null
                          ? _buildNoResult()
                          : _buildResult(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
      child: Column(
        children: [
          _resultCard(_result!),
          const SizedBox(height: 20),
          _buildAiSummarySection(),
        ],
      ),
    );
  }

  // ── AI Summary section ─────────────────────────────────

  Widget _buildAiSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header with language toggle ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('ai_summary_title', _lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t('powered_by', _lang),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Language toggle ──
                if (_summary != null)
                  _buildLangToggle(),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: _summaryLoading
                ? _buildSummaryLoader()
                : _summary != null
                    ? _buildSummaryContent(_summary!)
                    : _buildGenerateButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLangToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTab('EN', _Lang.english),
          _langTab('ಕನ್ನಡ', _Lang.kannada),
        ],
      ),
    );
  }

  Widget _langTab(String label, _Lang lang) {
    final isSelected = _lang == lang;
    return GestureDetector(
      onTap: () => setState(() => _lang = lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t('checking', _lang),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFA5D6A7), width: 1.5),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF2E7D32),
            size: 30,
          ),
        ),
        Text(
          _t('no_summary', _lang),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t('generate_desc', _lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                (_generating || _summaryGenerated) ? null : _generateSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _generating
                  ? _t('generating', _lang)
                  : _t('generate_btn', _lang),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(Map<String, dynamic> s) {
    final langKey = _lang == _Lang.kannada ? 'kannada' : 'english';
    final data = s[langKey] as Map<String, dynamic>? ?? s;
    
    final overallSummary = data['overallSummary']?.toString() ?? '';
    final strengths = (data['strengths'] as List?)?.cast<String>() ?? [];
    final improvements =
        (data['areasForImprovement'] as List?)?.cast<String>() ?? [];
    final recommendations =
        (data['recommendations'] as List?)?.cast<String>() ?? [];
    final motivationalNote = data['motivationalNote']?.toString() ?? '';
    final generatedAt = s['generatedAt']?.toString() ?? '';

    String dateStr = '';
    if (generatedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(generatedAt).toLocal();
        dateStr =
            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overallSummary.isNotEmpty) ...[
          _summaryBlock(
            icon: Icons.summarize_rounded,
            label: _t('overview', _lang),
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
            child: Text(
              overallSummary,
              style: const TextStyle(
                  fontSize: 13, height: 1.6, color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (strengths.isNotEmpty) ...[
          _summaryBlock(
            icon: Icons.emoji_events_rounded,
            label: _t('strengths', _lang),
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
            child: Column(
              children: strengths
                  .map((s) => _bulletItem(s, const Color(0xFF2E7D32)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (improvements.isNotEmpty) ...[
          _summaryBlock(
            icon: Icons.trending_up_rounded,
            label: _t('improve', _lang),
            color: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            child: Column(
              children: improvements
                  .map((s) => _bulletItem(s, const Color(0xFFE65100)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (recommendations.isNotEmpty) ...[
          _summaryBlock(
            icon: Icons.lightbulb_rounded,
            label: _t('recommendations', _lang),
            color: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            child: Column(
              children: recommendations
                  .map((s) => _bulletItem(s, const Color(0xFF6A1B9A)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (motivationalNote.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motivationalNote,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 13, color: Color(0xFF2E7D32)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                dateStr.isNotEmpty
                    ? '${_t('generated_on', _lang)}: $dateStr'
                    : 'Summary generated',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryBlock({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: color.withOpacity(0.15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result card ────────────────────────────────────────

  Widget _resultCard(Map<String, dynamic> result) {
    final scholastic = result['scholasticResults'] as List? ?? [];
    final coScholastic = result['coScholasticResults'] as List? ?? [];

    double totalScored = 0;
    double totalMax = 0;

    for (final s in scholastic) {
      totalScored += (s['totalMarksScored'] as num?)?.toDouble() ?? 0;
      final subName = s['subjectName']?.toString();
      final assessmentSubjects =
          widget.test['scholasticSubjects'] as List? ?? [];
      final assessmentSub = assessmentSubjects.firstWhere(
        (as) => as['subjectName'] == subName,
        orElse: () => null,
      );
      if (assessmentSub != null) {
        final internalMax =
            (assessmentSub['internalMaximumScore'] as num?)?.toDouble() ?? 0;
        final externalMax =
            (assessmentSub['externalMaximumScore'] as num?)?.toDouble() ?? 0;
        totalMax += (internalMax + externalMax);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
              border:
                  Border(bottom: BorderSide(color: Colors.teal.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Icon(Icons.stars_rounded,
                      color: Colors.teal[600], size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('overall', _lang),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.teal[900]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_t('total', _lang)}: ${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.teal[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scholastic.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        _t('scholastic', _lang),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(_t('subject', _lang),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                        letterSpacing: 0.5)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_t('marks', _lang),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                        letterSpacing: 0.5)),
                              ),
                              Expanded(
                                child: Text(_t('grade', _lang),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        ...scholastic.map((s) {
                          final subName =
                              s['subjectName']?.toString() ?? '';
                          final scored = (s['totalMarksScored'] as num?)
                                  ?.toDouble() ??
                              0;
                          final grade = s['grade']?.toString() ?? '-';

                          final assessmentSubjects =
                              widget.test['scholasticSubjects'] as List? ??
                                  [];
                          final assessmentSub =
                              assessmentSubjects.firstWhere(
                            (as) => as['subjectName'] == subName,
                            orElse: () => null,
                          );
                          double max = 0;
                          if (assessmentSub != null) {
                            final iM = (assessmentSub[
                                            'internalMaximumScore']
                                        as num?)
                                    ?.toDouble() ??
                                0;
                            final eM = (assessmentSub[
                                            'externalMaximumScore']
                                        as num?)
                                    ?.toDouble() ??
                                0;
                            max = iM + eM;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(subName,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800])),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                      '${scored.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal[800])),
                                ),
                                Expanded(
                                  child: Text(grade,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal[700])),
                                ),
                              ],
                            ),
                          );
                        }),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(_t('total', _lang),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900])),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '${totalScored.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.teal[900])),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (coScholastic.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.palette_rounded,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        _t('co_scholastic', _lang),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(_t('activity', _lang),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                        letterSpacing: 0.5)),
                              ),
                              Expanded(
                                child: Text(_t('grade', _lang),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        ...coScholastic.map((c) {
                          final name =
                              c['activityName']?.toString() ?? '';
                          final grade = c['grade']?.toString() ?? '-';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(name,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800])),
                                ),
                                Expanded(
                                  child: Text(grade,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal[700])),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_t('published_by', _lang)} ${result['publishedBy'] ?? 'Teacher'}',
                      style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loader / Error / No Result ─────────────────────────

  Widget _buildLoader() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'Loading your result...',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchResult,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildNoResult() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.orange[600],
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t('result_not_published', _lang),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('result_not_published_desc', _lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
}
