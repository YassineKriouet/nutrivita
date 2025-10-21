import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/questionnaire_service.dart';

class QuestionnaireTabWidget extends StatefulWidget {
  const QuestionnaireTabWidget({super.key});

  @override
  State<QuestionnaireTabWidget> createState() => _QuestionnaireTabWidgetState();
}

class _QuestionnaireTabWidgetState extends State<QuestionnaireTabWidget> {
  final QuestionnaireService _questionnaireService = QuestionnaireService();
  List<Map<String, dynamic>> questionnaires = [];
  Map<String, dynamic> progressData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaires();
  }

  Future<void> _loadQuestionnaires() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final [templates, detailedProgress] = await Future.wait([
        _questionnaireService.getQuestionnaireTemplates(),
        _questionnaireService.getDetailedQuestionnaireProgress(),
      ]);

      if (mounted) {
        setState(() {
          questionnaires = templates as List<Map<String, dynamic>>;
          progressData = detailedProgress as Map<String, dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questionnaires: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Errore nel caricamento dei questionari';
          questionnaires = [];
          progressData = {};
        });
      }
    }
  }

  Future<void> _refreshQuestionnaireProgress(String sessionId) async {
    try {
      final sessionProgress =
          await _questionnaireService.getQuestionnaireProgress(sessionId);

      // Update the progress data for this specific questionnaire
      final questionnaireType = sessionProgress['questionnaire_type'];
      if (questionnaireType != null && mounted) {
        setState(() {
          progressData[questionnaireType] = {
            ...progressData[questionnaireType] ?? {},
            'total_questions': sessionProgress['total_questions'],
            'completed_responses': sessionProgress['answered_questions'],
            'completion_percentage': sessionProgress['progress_percentage'],
            'is_completed': sessionProgress['is_complete'],
          };
        });
      }

      print(
          'Updated progress for $questionnaireType: ${sessionProgress['answered_questions']}/${sessionProgress['total_questions']}');
    } catch (e) {
      print('Error refreshing progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (questionnaires.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadQuestionnaires,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: questionnaires.length,
        itemBuilder: (context, index) {
          final questionnaire = questionnaires[index];
          final questionnaireType =
              questionnaire['questionnaire_type'] as String;
          final progress =
              progressData[questionnaireType] as Map<String, dynamic>?;

          return _buildQuestionnaireCard(questionnaire, progress);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
          ),
          SizedBox(height: 4.w),
          Text(
            'Caricamento questionari...',
            style: GoogleFonts.inter(
              fontSize: 4.w,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 15.w,
            color: Colors.red[400],
          ),
          SizedBox(height: 4.w),
          Text(
            errorMessage!,
            style: GoogleFonts.inter(
              fontSize: 4.w,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.w),
          ElevatedButton(
            onPressed: _loadQuestionnaires,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF27AE60),
              foregroundColor: Colors.white,
            ),
            child: Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 15.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 4.w),
          Text(
            'Nessun questionario disponibile',
            style: GoogleFonts.inter(
              fontSize: 4.w,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Build questionnaire card with retaking functionality
  Widget _buildQuestionnaireCard(
    Map<String, dynamic> questionnaire,
    Map<String, dynamic>? progress,
  ) {
    final title = questionnaire['title'] as String? ?? 'Questionario';
    final description = questionnaire['description'] as String? ?? '';
    final category = questionnaire['category'] as String? ?? 'Generale';
    final questionnaireType = questionnaire['questionnaire_type'] as String;

    final isCompleted = progress?['is_completed'] as bool? ?? false;
    final completionPercentage =
        progress?['completion_percentage'] as int? ?? 0;
    final completedResponses = progress?['completed_responses'] as int? ?? 0;
    final totalQuestions = progress?['total_questions'] as int? ?? 0;
    final canRetake = progress?['can_retake'] as bool? ?? true; // Now enabled
    final completedAt = progress?['completed_at'] as String?;

    // FIXED: Display correct progress for completed questionnaires
    // When questionnaire is completed, show full completion (totalQuestions/totalQuestions)
    final displayCompletedResponses =
        isCompleted ? totalQuestions : completedResponses;
    final displayProgressValue = isCompleted
        ? 1.0
        : (totalQuestions > 0 ? completedResponses / totalQuestions : 0.0);

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    String statusText = 'Non iniziato';
    Color statusColor = Colors.grey[600]!;
    IconData statusIcon = Icons.radio_button_unchecked;

    if (isCompleted) {
      cardColor = Color(0xFF27AE60).withAlpha(13);
      borderColor = Color(0xFF27AE60).withAlpha(77);
      statusText = 'Completato';
      statusColor = Color(0xFF27AE60);
      statusIcon = Icons.check_circle;
    } else if (completionPercentage > 0) {
      cardColor = Color(0xFFF39C12).withAlpha(13);
      borderColor = Color(0xFFF39C12).withAlpha(77);
      statusText = 'In corso ($completionPercentage%)';
      statusColor = Color(0xFFF39C12);
      statusIcon = Icons.access_time;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 4.w),
      child: Card(
        elevation: 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: Color(0xFF3498DB).withAlpha(26),
                        borderRadius: BorderRadius.circular(1.5.w),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 3.w,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3498DB),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 4.w,
                        color: statusColor,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 3.w,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 3.w),

              // Title and description
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 4.5.w,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),

              if (description.isNotEmpty) ...[
                SizedBox(height: 2.w),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 3.5.w,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],

              SizedBox(height: 3.w),

              // FIXED: Progress indicator showing correct completion
              if (totalQuestions > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1.w),
                        child: LinearProgressIndicator(
                          value: displayProgressValue,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? Color(0xFF27AE60) : Color(0xFFF39C12),
                          ),
                          minHeight: 2.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '$displayCompletedResponses/$totalQuestions',
                      style: GoogleFonts.inter(
                        fontSize: 3.w,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.w),
              ],

              // Completion information
              if (isCompleted && completedAt != null) ...[
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Color(0xFF27AE60).withAlpha(26),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(color: Color(0xFF27AE60).withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 4.w,
                        color: Color(0xFF27AE60),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Completato il ${_formatDate(completedAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 3.w,
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.w),
              ],

              // Action buttons - UPDATED with retaking functionality
              Row(
                children: [
                  if (isCompleted) ...[
                    // Show retake button for completed questionnaires
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _retakeQuestionnaire(questionnaire),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 3.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 4.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Rifai',
                              style: GoogleFonts.inter(
                                fontSize: 3.5.w,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    // View results button
                    ElevatedButton(
                      onPressed: () => _viewResults(questionnaire, progress),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 3.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      child: Text(
                        'Visualizza',
                        style: GoogleFonts.inter(
                          fontSize: 3.5.w,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Start or continue button for incomplete questionnaires
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _startQuestionnaire(questionnaire),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 3.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                        ),
                        child: Text(
                          completionPercentage > 0 ? 'Continua' : 'Inizia',
                          style: GoogleFonts.inter(
                            fontSize: 4.w,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data non disponibile';
    }
  }

  // UPDATED: Start questionnaire - now works for both new and continuing questionnaires
  Future<void> _startQuestionnaire(Map<String, dynamic> questionnaire) async {
    try {
      final sessionId = await _questionnaireService.startAssessmentSession(
        questionnaire['questionnaire_type'],
      );

      if (sessionId != null && mounted) {
        // Refresh progress for this questionnaire
        await _refreshQuestionnaireProgress(sessionId);

        // Navigate to questionnaire detail screen
        Navigator.pushNamed(
          context,
          AppRoutes.questionnaireDetail,
          arguments: {
            'sessionId': sessionId,
            'questionnaire': questionnaire,
          },
        ).then((_) {
          // Refresh data when returning
          _loadQuestionnaires();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'avvio del questionario. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error starting questionnaire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'avvio del questionario. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Retake questionnaire with progress reset
  Future<void> _retakeQuestionnaire(Map<String, dynamic> questionnaire) async {
    final questionnaireType = questionnaire['questionnaire_type'] as String;
    final title = questionnaire['title'] as String;

    try {
      // Show confirmation dialog
      final shouldRetake = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Ripeti Questionario',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 10.w,
                color: Color(0xFFF39C12),
              ),
              SizedBox(height: 3.w),
              Text(
                'Sei sicuro di voler ripetere "$title"?',
                style: GoogleFonts.inter(
                  fontSize: 4.w,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.w),
              Text(
                'Questo cancellerà tutti i progressi precedenti e dovrai ricompilare il questionario da capo.',
                style: GoogleFonts.inter(
                  fontSize: 3.5.w,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Annulla',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF27AE60),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Ripeti',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

      if (shouldRetake == true) {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text('Ripristino in corso...'),
                ],
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Reset progress and start new session
        final sessionId = await _questionnaireService.retakeQuestionnaire(
          questionnaireType,
        );

        if (sessionId != null && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progresso ripristinato. Inizia di nuovo!'),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to questionnaire detail screen
          Navigator.pushNamed(
            context,
            AppRoutes.questionnaireDetail,
            arguments: {
              'sessionId': sessionId,
              'questionnaire': questionnaire,
            },
          ).then((_) {
            // Refresh data when returning
            _loadQuestionnaires();
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nel ripristino. Riprova.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error retaking questionnaire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel ripristino del questionario. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UPDATED: View results for completed questionnaires with enhanced SARC-F visualization
  void _viewResults(
      Map<String, dynamic> questionnaire, Map<String, dynamic>? progress) {
    final isCompleted = progress?['is_completed'] as bool? ?? false;
    final sessionId = progress?['session_id'] as String;
    final questionnaireType = questionnaire['questionnaire_type'] as String;

    if (isCompleted && questionnaireType == 'sarc_f') {
      // Navigate to detailed SARC-F answer visualization
      _showDetailedSarcFAnswers(sessionId, questionnaire);
    } else {
      // Show basic results dialog for other questionnaires or incomplete ones
      _showBasicResults(questionnaire, progress);
    }
  }

  // NEW: Show detailed SARC-F answers in a comprehensive dialog
  Future<void> _showDetailedSarcFAnswers(
      String sessionId, Map<String, dynamic> questionnaire) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
                ),
                SizedBox(height: 3.w),
                Text(
                  'Caricamento risposte...',
                  style: GoogleFonts.inter(
                    fontSize: 3.5.w,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Get detailed answers
      final detailedData = await _questionnaireService
          .getDetailedQuestionnaireAnswers(sessionId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (detailedData.isNotEmpty && mounted) {
        _showSarcFAnswersDialog(detailedData, questionnaire);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle risposte dettagliate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading detailed SARC-F answers: $e');

      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle risposte dettagliate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Show comprehensive SARC-F answers dialog
  void _showSarcFAnswersDialog(
      Map<String, dynamic> detailedData, Map<String, dynamic> questionnaire) {
    final answers = detailedData['detailed_answers'] as List<dynamic>? ?? [];
    final completedAt = detailedData['completed_at'] as String?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(4.w),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 80.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Color(0xFF3498DB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3.w),
                    topRight: Radius.circular(3.w),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risposte SARC-F',
                            style: GoogleFonts.inter(
                              fontSize: 4.5.w,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (completedAt != null)
                            Text(
                              'Completato il ${_formatDate(completedAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 3.w,
                                color: Colors.white.withAlpha(230),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner for SARC-F (no score calculation)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        margin: EdgeInsets.only(bottom: 4.w),
                        decoration: BoxDecoration(
                          color: Color(0xFF27AE60).withAlpha(26),
                          borderRadius: BorderRadius.circular(2.w),
                          border: Border.all(
                              color: Color(0xFF27AE60).withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF27AE60),
                              size: 5.w,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                'Visualizzazione delle risposte del tuo ultimo tentativo completato. Nessun punteggio calcolato per questo questionario.',
                                style: GoogleFonts.inter(
                                  fontSize: 3.2.w,
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Answers list
                      ...answers.map<Widget>((answerData) {
                        final questionText =
                            answerData['question_text'] as String? ??
                                'Domanda non disponibile';
                        final responseValue =
                            answerData['response_value'] as String? ??
                                'Non risposto';
                        final displayValue =
                            answerData['display_value'] as String? ??
                                responseValue;
                        final questionType =
                            answerData['question_type'] as String? ?? 'unknown';

                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 3.w),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3.w),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question
                              Text(
                                questionText,
                                style: GoogleFonts.inter(
                                  fontSize: 3.8.w,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 2.w),

                              // Question type indicator
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 1.w),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3498DB).withAlpha(26),
                                  borderRadius: BorderRadius.circular(1.5.w),
                                ),
                                child: Text(
                                  _getQuestionTypeLabel(questionType),
                                  style: GoogleFonts.inter(
                                    fontSize: 2.5.w,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3498DB),
                                  ),
                                ),
                              ),
                              SizedBox(height: 3.w),

                              // Answer
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: Color(0xFF27AE60).withAlpha(13),
                                  borderRadius: BorderRadius.circular(2.w),
                                  border: Border.all(
                                      color: Color(0xFF27AE60).withAlpha(51)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Color(0xFF27AE60),
                                          size: 4.w,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          'Risposta:',
                                          style: GoogleFonts.inter(
                                            fontSize: 3.w,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF27AE60),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.w),
                                    Text(
                                      displayValue,
                                      style: GoogleFonts.inter(
                                        fontSize: 3.5.w,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(3.w),
                    bottomRight: Radius.circular(3.w),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                  child: Text(
                    'Chiudi',
                    style: GoogleFonts.inter(
                      fontSize: 4.w,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Get question type label for display
  String _getQuestionTypeLabel(String questionType) {
    switch (questionType) {
      case 'yes_no':
        return 'Sì/No';
      case 'single_choice':
        return 'Scelta singola';
      case 'multiple_choice':
        return 'Scelta multipla';
      case 'scale_0_10':
        return 'Scala 0-10';
      case 'number_input':
        return 'Numero';
      case 'text_input':
        return 'Testo';
      case 'calculated':
        return 'Calcolato automaticamente';
      default:
        return 'Risposta';
    }
  }

  // NEW: Show basic results dialog for non-SARC-F questionnaires
  void _showBasicResults(
      Map<String, dynamic> questionnaire, Map<String, dynamic>? progress) {
    final isCompleted = progress?['is_completed'] as bool? ?? false;
    final totalQuestions = progress?['total_questions'] as int? ?? 0;
    final completedResponses = progress?['completed_responses'] as int? ?? 0;
    final questionnaireType = questionnaire['questionnaire_type'] as String;

    // Show correct completion when questionnaire is completed
    final displayCompletedResponses =
        isCompleted ? totalQuestions : completedResponses;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Risultati',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionnaire['title'] as String,
              style: GoogleFonts.inter(
                fontSize: 4.w,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 3.w),
            if (progress != null) ...[
              Text('Completamento: ${progress['completion_percentage']}%'),
              Text('Risposte: $displayCompletedResponses/$totalQuestions'),
              if (progress['completed_at'] != null)
                Text(
                    'Data completamento: ${_formatDate(progress['completed_at'])}'),
              SizedBox(height: 2.w),

              // Special handling for different questionnaire types
              if (questionnaireType == 'sarc_f') ...[
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Color(0xFF27AE60).withAlpha(26),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(color: Color(0xFF27AE60).withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 4.w,
                        color: Color(0xFF27AE60),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Nessun punteggio calcolato per questo questionario. Le risposte sono disponibili per la consultazione.',
                          style: GoogleFonts.inter(
                            fontSize: 3.w,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Color(0xFF3498DB).withAlpha(26),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(color: Color(0xFF3498DB).withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 4.w,
                        color: Color(0xFF3498DB),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Puoi ripetere questo questionario usando il pulsante "Rifai"',
                          style: GoogleFonts.inter(
                            fontSize: 3.w,
                            color: Color(0xFF3498DB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}

extension _WidgetExtensions on Widget {
  Widget expand() => Expanded(child: this);
}