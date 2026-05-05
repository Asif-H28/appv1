import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';
import 'package:appv1/core/constants/app_colors.dart';

class AssessmentResultsPage extends StatefulWidget {
  final String assessmentId;
  final String assessmentTitle;

  const AssessmentResultsPage({
    super.key,
    required this.assessmentId,
    required this.assessmentTitle,
  });

  @override
  State<AssessmentResultsPage> createState() => _AssessmentResultsPageState();
}

class _AssessmentResultsPageState extends State<AssessmentResultsPage> {
  bool _isLoading = true;
  List<dynamic> _results = [];
  List<dynamic> _filteredResults = [];
  String _errorMessage = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchResults();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredResults = _results.where((r) {
        final name = r['studentName']?.toString().toLowerCase() ?? '';
        final id = r['studentId']?.toString().toLowerCase() ?? '';
        final query = _searchController.text.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final result = await ApiService.fetchAssessmentResults(widget.assessmentId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _results = result['data'] is List ? result['data'] : (result['data']['results'] ?? []);
          _filteredResults = _results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load results';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _errorMessage.isNotEmpty
                    ? _buildError()
                    : _filteredResults.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredResults.length,
                            itemBuilder: (context, index) => _buildExpandableResultCard(_filteredResults[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assessmentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'Student results & performance',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.teal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search student by name or ID...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableResultCard(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.teal.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            result['studentName'] ?? 'Unknown Student',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
          ),
          subtitle: const Text(
            'Tap to view full result',
            style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  result['overallGrade'] ?? '-',
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 20),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24),
                  // Scholastic Section
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 14, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Scholastic Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScholasticTable(result['scholasticResults'] as List? ?? []),
                  
                  const SizedBox(height: 20),

                  // Co-Scholastic Section
                  if ((result['coScholasticResults'] as List? ?? []).isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Co-Scholastic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCoScholasticList(result['coScholasticResults'] as List? ?? []),
                    const SizedBox(height: 20),
                  ],

                  // Stats Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _footerStat('Percentage', '${result['percentage']}%'),
                        _footerStat('Total Marks', '${result['overallTotalScored']}/${result['overallTotalMaximum']}'),
                        _footerStat('Status', result['overallStatus']?.toString().toUpperCase() ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholasticTable(List scholastic) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.withOpacity(0.1)))),
          children: [
            _tableHeader('Subject'),
            _tableHeader('Marks'),
            _tableHeader('Grade'),
          ],
        ),
        ...scholastic.map((s) => TableRow(
          children: [
            _tableCell(s['subjectName'] ?? '-'),
            _tableCell('${s['totalMarksScored'] ?? '-'}'),
            _tableCell(s['grade'] ?? '-'),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildCoScholasticList(List coScholastic) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: coScholastic.map((cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.teal.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '${cs['activityName']}: ${cs['grade']}',
          style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.w500),
        ),
      )).toList(),
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal[700])),
  );

  Widget _tableCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF2D3142))),
  );

  Widget _footerStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.teal[400])),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.teal),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.teal), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchResults,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No students found.', style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );
}
