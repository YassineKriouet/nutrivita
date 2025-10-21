import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/questionnaire_service.dart';

class AssessmentOverviewWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onNavigateToQuestionnaire;

  const AssessmentOverviewWidget({
    super.key,
    required this.userId,
    this.onNavigateToQuestionnaire,
  });

  @override
  State<AssessmentOverviewWidget> createState() =>
      _AssessmentOverviewWidgetState();
}

class _AssessmentOverviewWidgetState extends State<AssessmentOverviewWidget> {
  final QuestionnaireService _questionnaireService = QuestionnaireService();
  Map<String, dynamic> progressData = {};
  bool isLoading = true;
  String? errorMessage;

  Future<void> _handleNavigationAndTracking(
      String navigationType, VoidCallback? callback) async {
    // Track the interaction before navigation
    try {
      await DashboardService.instance.trackAssessmentNavigation(navigationType);
    } catch (e) {
      print('Failed to track navigation: $e');
    }

    // Execute the navigation callback
    callback?.call();
  }

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _questionnaireService.getRealProgressData();

      if (!mounted) return;

      setState(() {
        progressData = data;
        isLoading = false;

        // Check if there was an error in the data or if fallback was used
        if (data.containsKey('error')) {
          if (data.containsKey('fallback_used')) {
            // Fallback was used - show data but with info message
            errorMessage =
                null; // Don't show error, just show reduced functionality
          } else {
            errorMessage = 'Errore nel caricamento dei dati di progresso';
          }
        }
      });
    } catch (e) {
      print('Error loading progress data: $e');
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Errore di connessione. Riprova più tardi.';
        progressData = {
          'overall': {
            'completed': 0,
            'total': 0,
            'percentage': 0,
            'completed_questionnaires': 0,
            'total_questionnaires': 0,
          },
          'categories': {},
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main progress overview container
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 2.w,
                  offset: Offset(0, 1.w),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Panoramica Valutazioni',
                      style: GoogleFonts.inter(
                        fontSize: 4.5.w,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : _loadProgressData,
                      icon: Icon(
                        Icons.refresh,
                        size: 5.w,
                        color:
                            isLoading ? Colors.grey : const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.w),

                if (isLoading)
                  _buildLoadingState()
                else if (errorMessage != null)
                  _buildErrorState()
                else
                  _buildProgressContent(),

                // Show info if fallback was used
                if (!isLoading &&
                    errorMessage == null &&
                    progressData.containsKey('fallback_used') &&
                    progressData['fallback_used'] == true) ...[
                  SizedBox(height: 3.w),
                  _buildFallbackInfoCard(),
                ],
              ],
            ),
          ),

          SizedBox(height: 6.w),

          // Navigation buttons section
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inizia la tua valutazione',
          style: GoogleFonts.inter(
            fontSize: 4.5.w,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 3.w),
        Text(
          'Completa i questionari clinici per una valutazione approfondita della tua salute nutrizionale:',
          style: GoogleFonts.inter(
            fontSize: 3.2.w,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.w),

        // Only Questionnaire button remains
        _buildNavigationCard(
          title: 'Questionari Clinici',
          subtitle: 'Valutazioni approfondite per la tua salute nutrizionale',
          icon: Icons.assignment_outlined,
          color: const Color(0xFF3498DB),
          onTap: () => _handleNavigationAndTracking(
              'questionnaire', widget.onNavigateToQuestionnaire),
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: color.withAlpha(51)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 2.w,
              offset: Offset(0, 1.w),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Icon(
                icon,
                size: 6.w,
                color: color,
              ),
            ),
            SizedBox(width: 4.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 4.w,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 1.w),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 3.w,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 4.w,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 30.w,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              strokeWidth: 0.8.w,
            ),
            SizedBox(height: 3.w),
            Text(
              'Caricamento dati...',
              style: GoogleFonts.inter(
                fontSize: 3.5.w,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 20.w,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 6.w, color: Colors.red[400]),
            SizedBox(height: 2.w),
            Text(
              errorMessage!,
              style: GoogleFonts.inter(fontSize: 3.5.w, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.w),
            ElevatedButton(
              onPressed: _loadProgressData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              ),
              child: Text('Riprova', style: GoogleFonts.inter(fontSize: 3.w)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInfoCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Color(0xFFF39C12).withAlpha(26),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: Color(0xFFF39C12).withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 4.w,
            color: Color(0xFFF39C12),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Modalità semplificata attiva. Alcuni dettagli potrebbero non essere disponibili.',
              style: GoogleFonts.inter(fontSize: 3.w, color: Color(0xFF2C3E50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent() {
    final overall = progressData['overall'] as Map<String, dynamic>? ?? {};
    final categories =
        progressData['categories'] as Map<String, Map<String, int>>? ?? {};

    final overallPercentage = overall['percentage'] as int? ?? 0;
    final completedQuestionnaires =
        overall['completed_questionnaires'] as int? ?? 0;
    final totalQuestionnaires = overall['total_questionnaires'] as int? ?? 0;
    final completedQuestions = overall['completed'] as int? ?? 0;
    final totalQuestions = overall['total'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall progress section
        _buildOverallProgressCard(
          overallPercentage,
          completedQuestionnaires,
          totalQuestionnaires,
          completedQuestions,
          totalQuestions,
        ),

        SizedBox(height: 4.w),

        // Category breakdown
        if (categories.isNotEmpty) ...[
          Text(
            'Progresso per Categoria',
            style: GoogleFonts.inter(
              fontSize: 4.w,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 3.w),
          ...categories.entries
              .map(
                (entry) => _buildCategoryProgress(
                  entry.key,
                  entry.value['completed'] ?? 0,
                  entry.value['total'] ?? 0,
                ),
              )
              .toList(),
        ],

        // Information about duplicate prevention
        if (overallPercentage > 0) ...[SizedBox(height: 4.w), _buildInfoCard()],
      ],
    );
  }

  Widget _buildOverallProgressCard(
    int percentage,
    int completedQuestionnaires,
    int totalQuestionnaires,
    int completedQuestions,
    int totalQuestions,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso Totale',
                style: GoogleFonts.inter(
                  fontSize: 4.w,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  '${percentage}%',
                  style: GoogleFonts.inter(
                    fontSize: 4.5.w,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.w),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(1.w),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              backgroundColor: Colors.white.withAlpha(77),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 2.w,
            ),
          ),

          SizedBox(height: 3.w),

          // Stats breakdown - showing only questionnaires completed
          Center(
            child: _buildStatItem(
              'Questionari Completati',
              '$completedQuestionnaires/$totalQuestionnaires',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 3.w,
            color: Colors.white.withAlpha(230),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 3.5.w,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(String category, int completed, int total) {
    final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 3.5.w,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
              Text(
                '$completed/$total',
                style: GoogleFonts.inter(
                  fontSize: 3.w,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(1.w),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              minHeight: 1.5.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Color(0xFF3498DB).withAlpha(26),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: Color(0xFF3498DB).withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 4.w, color: Color(0xFF3498DB)),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'I questionari completati non possono essere ripetuti. Il progresso mostrato è accurato e non include duplicati.',
              style: GoogleFonts.inter(fontSize: 3.w, color: Color(0xFF2C3E50)),
            ),
          ),
        ],
      ),
    );
  }
}
