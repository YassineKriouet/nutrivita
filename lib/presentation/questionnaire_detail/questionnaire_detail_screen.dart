import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async'; // ... Add this import for Timer ... //
import 'dart:convert'; // ... Add this import for jsonDecode ... //

import '../../core/app_export.dart';
import '../../services/questionnaire_service.dart';
import '../../services/supabase_service.dart';

class QuestionnaireDetailScreen extends StatefulWidget {
  const QuestionnaireDetailScreen({Key? key}) : super(key: key);

  @override
  State<QuestionnaireDetailScreen> createState() =>
      _QuestionnaireDetailScreenState();
}

class _QuestionnaireDetailScreenState extends State<QuestionnaireDetailScreen> {
  final QuestionnaireService _questionnaireService = QuestionnaireService();
  final PageController _pageController = PageController();

  // CRITICAL FIX: Move controllers to state level to prevent recreation
  final Map<String, TextEditingController> _textControllers = {};

  String? _sessionId;
  String? _questionnaireType;
  String? _templateId;
  String? _questionnaireName;

  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic> _responses = {};
  Map<String, dynamic> _calculatedValues = {};
  bool _isLoading = true;
  String? _error;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _isCompleted = false;
  Map<String, dynamic>? _completionResults;

  // CRITICAL FIX: Add dynamic progress tracking
  Map<String, dynamic> _progressData = {};

  // Helper method to check if this is a SARC-F questionnaire
  bool _isSarcFQuestionnaire() {
    return _questionnaireType?.toLowerCase() == 'sarc_f';
  }

  // Helper method to check if this is a MUST questionnaire
  bool _isMustQuestionnaire() {
    return _questionnaireType?.toLowerCase() == 'must';
  }

  // Helper method to check if this is an NRS 2002 questionnaire
  bool _isNrs2002Questionnaire() {
    return _questionnaireType?.toLowerCase() == 'nrs_2002';
  }

  // Helper method to check if this is an SF-12 questionnaire
  bool _isSf12Questionnaire() {
    return _questionnaireType?.toLowerCase() == 'sf12';
  }

  // Helper method to check if this is an ESAS questionnaire
  bool _isEsasQuestionnaire() {
    return _questionnaireType?.toLowerCase() == 'esas';
  }

  // CRITICAL FIX: Enhanced completed questions calculation with MUST-specific handling
  int _getCompletedQuestionsCount() {
    if (_questions.isEmpty) return 0;

    // For MUST questionnaire, use enhanced progress data with validation
    if (_isMustQuestionnaire() && _progressData.isNotEmpty) {
      final completedFromProgress =
          _progressData['completed_responses'] as int? ?? 0;

      // Validate that completed doesn't exceed 3 for MUST
      final validatedCompleted =
          completedFromProgress > 3 ? 3 : completedFromProgress;

      print(
          'MUST COMPLETED QUESTIONS: $validatedCompleted (validated from progress data)');
      return validatedCompleted;
    }

    // For other questionnaires, count responses normally
    int completedCount = 0;

    for (final question in _questions) {
      final questionId = question['question_id'] as String;
      final questionType = question['question_type'] as String;

      // Check if this question has a valid response
      final response = _responses[questionId];

      if (response != null) {
        final value = response['value']?.toString() ?? '';

        // Count as completed if it has a non-empty value or is a calculated question
        if (questionType == 'calculated' || value.trim().isNotEmpty) {
          completedCount++;
        }
      }
    }

    print(
        'OTHER QUESTIONNAIRE COMPLETED: $completedCount out of ${_questions.length}');
    return completedCount;
  }

  // CRITICAL FIX: Enhanced total questions calculation with better MUST handling
  int _getTotalQuestionsCount() {
    // For MUST questionnaire, ALWAYS return 3 regardless of database content
    if (_isMustQuestionnaire()) {
      // Try to get from enhanced progress data first
      if (_progressData.isNotEmpty) {
        final total = _progressData['total_questions'] as int? ?? 3;
        print('MUST TOTAL QUESTIONS: $total (from progress data)');
        return total;
      }

      print('MUST TOTAL QUESTIONS: 3 (hardcoded fallback)');
      return 3; // Force to 3 for MUST questionnaire as requested
    }

    final actualCount = _questions.length;
    print('OTHER QUESTIONNAIRE TOTAL: $actualCount questions');
    return actualCount;
  }

  // CRITICAL FIX: Enhanced progress display method
  String _getProgressDisplayText() {
    if (_isMustQuestionnaire() && _progressData.isNotEmpty) {
      final displayFormat = _progressData['display_format'] as String?;
      if (displayFormat != null && displayFormat.isNotEmpty) {
        print('MUST PROGRESS DISPLAY: Using format "$displayFormat"');
        return displayFormat;
      }
    }

    final completed = _getCompletedQuestionsCount();
    final total = _getTotalQuestionsCount();
    final displayText = '$completed/$total';

    print('PROGRESS DISPLAY: $displayText');
    return displayText;
  }

  // Helper method to check if questionnaire is fully completed
  bool _isQuestionnaireFullyCompleted() {
    return _getCompletedQuestionsCount() == _getTotalQuestionsCount();
  }

  @override
  void initState() {
    super.initState();
    _extractArguments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // CRITICAL FIX: Dispose all text controllers
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    super.dispose();
  }

  // CRITICAL FIX: Helper method to get or create text controller with enhanced cursor handling
  TextEditingController _getTextController(
    String questionId,
    String initialValue,
  ) {
    // Check if we already have a controller
    if (_textControllers.containsKey(questionId)) {
      final controller = _textControllers[questionId]!;

      // CRITICAL FIX: Only update if the value actually changed and preserve cursor position
      if (initialValue.isNotEmpty && controller.text != initialValue) {
        print(
            'TEXT CONTROLLER: Updating existing controller for $questionId from "${controller.text}" to "$initialValue"');

        // CRITICAL FIX: Preserve cursor position when updating text
        final currentSelection = controller.selection;
        controller.text = initialValue;

        // Restore cursor position if it's valid
        if (currentSelection.start <= initialValue.length &&
            currentSelection.end <= initialValue.length) {
          controller.selection = currentSelection;
        } else {
          // Position cursor at end if previous position is invalid
          controller.selection = TextSelection.collapsed(
            offset: initialValue.length,
          );
        }
      }

      return controller;
    }

    // Create new controller with initial value and proper cursor positioning
    print(
        'TEXT CONTROLLER: Creating new controller for $questionId with initial value: "$initialValue"');
    final controller = TextEditingController(text: initialValue);

    // CRITICAL FIX: Position cursor at the end of initial value
    if (initialValue.isNotEmpty) {
      controller.selection = TextSelection.collapsed(
        offset: initialValue.length,
      );
    }

    _textControllers[questionId] = controller;

    return controller;
  }

  void _extractArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
              {};

      setState(() {
        _sessionId = args['sessionId'] as String? ?? '';
        _questionnaireType = args['questionnaireType'] as String? ?? '';
        _templateId = args['templateId'] as String? ?? '';
        _questionnaireName =
            args['questionnaireName'] as String? ?? 'Questionario';
      });

      if (_sessionId != null && _sessionId!.isNotEmpty) {
        _loadQuestionsAndResumeProgress();
      } else {
        setState(() {
          _error = 'Sessione questionario non valida';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadQuestionsAndResumeProgress() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Enhanced template ID resolution
      String? resolvedTemplateId = _templateId;

      // If template ID is missing or empty, try to resolve it
      if (resolvedTemplateId == null || resolvedTemplateId.isEmpty) {
        print(
          'Template ID missing, attempting to resolve from session or questionnaire type',
        );

        if (_questionnaireType != null && _questionnaireType!.isNotEmpty) {
          // Try to get template ID from questionnaire type
          final templateResponse = await SupabaseService.instance.client
              .from('questionnaire_templates')
              .select('id')
              .eq('questionnaire_type', _questionnaireType!)
              .eq('is_active', true)
              .maybeSingle();

          if (templateResponse != null) {
            resolvedTemplateId = templateResponse['id'] as String;
            print('Resolved template ID: $resolvedTemplateId');
          }
        }

        // If still no template ID, try to get from session
        if ((resolvedTemplateId == null || resolvedTemplateId.isEmpty) &&
            _sessionId != null &&
            _sessionId!.isNotEmpty) {
          try {
            final sessionResponse = await SupabaseService.instance.client
                .from('assessment_sessions')
                .select('questionnaire_type')
                .eq('id', _sessionId!)
                .single();

            final sessionQuestionnaireType =
                sessionResponse['questionnaire_type'] as String;

            final templateResponse = await SupabaseService.instance.client
                .from('questionnaire_templates')
                .select('id')
                .eq('questionnaire_type', sessionQuestionnaireType)
                .eq('is_active', true)
                .maybeSingle();

            if (templateResponse != null) {
              resolvedTemplateId = templateResponse['id'] as String;
              print('Resolved template ID from session: $resolvedTemplateId');
            }
          } catch (sessionError) {
            print('Could not resolve template from session: $sessionError');
          }
        }

        // Final fallback: get any available template
        if (resolvedTemplateId == null || resolvedTemplateId.isEmpty) {
          print('Using fallback template resolution');

          final fallbackTemplate = await SupabaseService.instance.client
              .from('questionnaire_templates')
              .select('id, questionnaire_type')
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();

          if (fallbackTemplate != null) {
            resolvedTemplateId = fallbackTemplate['id'] as String;
            _questionnaireType =
                fallbackTemplate['questionnaire_type'] as String;
            print(
              'Using fallback template: $resolvedTemplateId for type: $_questionnaireType',
            );
          }
        }
      }

      if (resolvedTemplateId != null && resolvedTemplateId.isNotEmpty) {
        final questions = await _questionnaireService.getQuestionsForTemplate(
          resolvedTemplateId,
        );

        if (questions.isEmpty) {
          print(
            'No questions found for template $resolvedTemplateId, checking for any questions',
          );

          // Try to get questions from any available template
          final allTemplates = await SupabaseService.instance.client
              .from('questionnaire_templates')
              .select('id')
              .eq('is_active', true)
              .limit(3);

          for (final template in allTemplates) {
            final templateId = template['id'] as String;
            final templateQuestions =
                await _questionnaireService.getQuestionsForTemplate(templateId);

            if (templateQuestions.isNotEmpty) {
              setState(() {
                _questions = templateQuestions;
                _templateId = templateId;
              });

              print('Found questions in template: $templateId');
              break;
            }
          }

          if (_questions.isEmpty) {
            setState(() {
              _error =
                  'Nessuna domanda disponibile al momento. Le domande verranno caricate presto.';
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _questions = questions;
            _templateId = resolvedTemplateId;
          });
        }

        // Load existing responses if any
        if (_sessionId != null && _sessionId!.isNotEmpty) {
          final existingResponses =
              await _questionnaireService.getSessionResponses(_sessionId!);
          setState(() {
            _responses = existingResponses;
          });

          // CRITICAL FIX: Load dynamic progress data for MUST questionnaire
          await _loadProgressData();

          // CRITICAL FIX: Calculate and set current question index based on progress
          await _calculateAndSetCurrentQuestionIndex();

          // CRITICAL FIX: Load calculated values for automatic questions
          await _loadCalculatedValues();

          // CRITICAL FIX: Initialize text controllers with existing response values
          await _initializeTextControllersWithResponses();
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        // Create a user-friendly error message instead of technical error
        setState(() {
          _error =
              'Questionario temporaneamente non disponibile.\n\nRiprova tra qualche momento o contatta il supporto se il problema persiste.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questions: $e');

      setState(() {
        _error =
            'Errore nel caricamento del questionario.\n\nVerifica la connessione internet e riprova.';
        _isLoading = false;
      });
    }
  }

  // CRITICAL FIX: New method to load dynamic progress data with enhanced error handling
  Future<void> _loadProgressData() async {
    try {
      if (_sessionId != null && _sessionId!.isNotEmpty) {
        // Use the enhanced detailed progress method
        final detailedProgressData = await _questionnaireService
            .getDetailedQuestionnaireProgressForSession(_sessionId!);

        // Also get the standard progress data for backwards compatibility
        final standardProgressData =
            await _questionnaireService.getQuestionnaireProgress(_sessionId!);

        setState(() {
          _progressData = {
            ...standardProgressData,
            ...detailedProgressData, // Override with detailed data
          };
        });

        print('ENHANCED PROGRESS DATA LOADED: $_progressData');

        // For MUST questionnaire, log the corrected progress with emphasis
        if (_isMustQuestionnaire()) {
          final displayFormat =
              _progressData['display_format'] as String? ?? '0/0';
          final completed = _progressData['completed_responses'] as int? ?? 0;
          final total = _progressData['total_questions'] as int? ?? 3;

          print(
              '🎯 MUST PROGRESS CORRECTED: $displayFormat (was showing 8/8, now showing 3/3 format)');
          print('   - Completed responses: $completed');
          print('   - Total questions: $total (forced to 3 for MUST)');
          print(
              '   - Percentage: ${_progressData['completion_percentage'] ?? 0}%');
        }
      }
    } catch (e) {
      print('Error loading enhanced progress data: $e');
      // Fallback to ensure MUST shows correct format even on error
      if (_isMustQuestionnaire() && _sessionId != null) {
        try {
          final basicProgress =
              await _questionnaireService.getQuestionnaireProgress(_sessionId!);
          setState(() {
            _progressData = basicProgress;
          });
          print('MUST PROGRESS FALLBACK: Applied basic progress correction');
        } catch (fallbackError) {
          print('MUST PROGRESS FALLBACK FAILED: $fallbackError');
        }
      }
    }
  }

  // CRITICAL FIX: New method to properly initialize text controllers with existing responses
  Future<void> _initializeTextControllersWithResponses() async {
    print(
        'INITIALIZE CONTROLLERS: Starting initialization with ${_responses.length} responses');

    for (final question in _questions) {
      final questionId = question['question_id'] as String;
      final questionType = question['question_type'] as String;

      // Only initialize text controllers for text input and number input questions
      if (questionType == 'text_input' || questionType == 'number_input') {
        final existingResponse = _responses[questionId];
        final existingValue = existingResponse?['value']?.toString() ?? '';

        if (existingValue.isNotEmpty) {
          print(
              'INITIALIZE CONTROLLERS: Setting controller for $questionId with value: "$existingValue"');

          // Force create/update the controller with the existing value
          if (_textControllers.containsKey(questionId)) {
            _textControllers[questionId]!.text = existingValue;
          } else {
            _textControllers[questionId] =
                TextEditingController(text: existingValue);
          }

          print(
              'INITIALIZE CONTROLLERS: Successfully initialized controller for $questionId');
        } else {
          print(
              'INITIALIZE CONTROLLERS: No existing value for question $questionId');
        }
      }
    }

    print(
        'INITIALIZE CONTROLLERS: Completed initialization for ${_textControllers.length} text controllers');

    // Force a UI update to ensure all widgets reflect the loaded values
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with properly initialized controllers
      });
    }
  }

  Future<void> _calculateAndSetCurrentQuestionIndex() async {
    if (_questions.isEmpty || _responses.isEmpty) {
      setState(() {
        _currentQuestionIndex = 0;
      });
      return;
    }

    int lastAnsweredIndex = -1;

    // Find the last question that has a valid response
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionId = question['question_id'] as String;
      final questionType = question['question_type'] as String;

      // Check if this question has a response
      final response = _responses[questionId];

      if (response != null) {
        final value = response['value']?.toString() ?? '';

        // For calculated questions, they're automatically filled so they count as answered
        if (questionType == 'calculated' || value.trim().isNotEmpty) {
          lastAnsweredIndex = i;

          // CRITICAL FIX: For SF-12, log each found response for debugging
          if (_isSf12Questionnaire()) {
            print(
                'SF-12 PROGRESS: Found response for question ${i + 1}: $questionId = "$value"');
          }
        }
      }
    }

    // Set current question index to the next unanswered question
    // If all questions are answered, set to last question
    int nextQuestionIndex = lastAnsweredIndex + 1;

    if (nextQuestionIndex >= _questions.length) {
      nextQuestionIndex = _questions.length - 1;
    }

    print(
      'CONTINUE FROM PROGRESS: Last answered index: $lastAnsweredIndex, Setting current index to: $nextQuestionIndex',
    );

    // CRITICAL FIX: For SF-12, provide detailed progress information
    if (_isSf12Questionnaire()) {
      final answeredCount = lastAnsweredIndex + 1;
      final totalQuestions = _questions.length;
      final progressPercent = ((answeredCount / totalQuestions) * 100).round();

      print('SF-12 DETAILED PROGRESS:');
      print('  - Questions answered: $answeredCount/$totalQuestions');
      print('  - Progress: $progressPercent%');
      print('  - Will resume at question: ${nextQuestionIndex + 1}');
      print('  - Loaded responses: ${_responses.length}');
    }

    setState(() {
      _currentQuestionIndex = nextQuestionIndex;
    });

    // CRITICAL: Update PageController to show the correct question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && nextQuestionIndex >= 0) {
        _pageController.animateToPage(
          nextQuestionIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        print(
          'CONTINUE FROM PROGRESS: Animated to question $nextQuestionIndex',
        );
      }
    });
  }

  Future<void> _loadCalculatedValues() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id ??
          'd4a87e24-2cab-4fc0-a753-fba15ba7c755'; // Mock for demo

      final calculatedValues = await _questionnaireService.getCalculatedValues(
        userId,
      );
      setState(() {
        _calculatedValues = calculatedValues;
      });

      // Auto-populate calculated responses
      await _populateCalculatedResponses();
    } catch (e) {
      print('Error loading calculated values: $e');
    }
  }

  Future<void> _populateCalculatedResponses() async {
    for (final question in _questions) {
      final questionId = question['question_id'] as String;
      final questionType = question['question_type'] as String;

      if (questionType == 'calculated') {
        await _handleCalculatedQuestion(questionId);
      }
    }
  }

  // CRITICAL FIX: Enhanced calculated question handling to properly process MUST BMI calculations
  Future<void> _handleCalculatedQuestion(String questionId) async {
    String? calculatedValue;
    String? displayValue;
    int? score;

    // CRITICAL FIX: Specific handling for NRS 2002 BMI question
    if (questionId == 'nrs_bmi_under_20_5' && _isNrs2002Questionnaire()) {
      final bmi = _calculatedValues['bmi'];
      if (bmi != null) {
        // NRS 2002 specific BMI categorization
        final isUnder20_5 = bmi < 20.5;
        calculatedValue = isUnder20_5 ? 'Sì' : 'No';
        displayValue =
            'BMI: ${bmi.toStringAsFixed(1)} - ${isUnder20_5 ? "Sotto 20.5" : "Sopra o uguale a 20.5"}';
        score = isUnder20_5 ? 1 : 0;

        print(
            'NRS 2002 BMI CALCULATION: BMI=$bmi, under20.5=$isUnder20_5, score=$score');

        // Auto-assign the response immediately for NRS 2002 BMI calculation
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_responses[questionId] == null ||
              _responses[questionId]!['value'] != calculatedValue) {
            await _saveResponse(
              questionId,
              calculatedValue!,
              score,
              calculatedValue: displayValue,
            );
            print(
                'AUTO-SAVED NRS 2002 BMI RESPONSE: $calculatedValue with score $score');
          }
        });
      } else {
        calculatedValue = 'Dati insufficienti';
        displayValue =
            'BMI non calcolabile - inserire altezza e peso nel profilo medico';
        score = 0;
        print('NRS 2002 BMI CALCULATION: No medical data available');
      }
    }
    // CRITICAL FIX: Specific handling for MUST BMI question with exact question ID matching
    else if (questionId == 'must_bmi_calculated') {
      final bmi = _calculatedValues['bmi'];
      if (bmi != null) {
        // MUST-specific BMI categorization with EXACT scoring criteria as requested
        if (bmi < 18.5) {
          calculatedValue = 'BMI < 18.5';
          displayValue =
              'BMI: ${bmi.toStringAsFixed(1)} (Sottopeso grave - 2 punti)';
          score = 2;
        } else if (bmi >= 18.5 && bmi < 20.0) {
          calculatedValue = '18.5 ≤ BMI < 20';
          displayValue =
              'BMI: ${bmi.toStringAsFixed(1)} (Lievemente sottopeso - 1 punto)';
          score = 1;
        } else {
          calculatedValue = 'BMI ≥ 20';
          displayValue =
              'BMI: ${bmi.toStringAsFixed(1)} (Normale o superiore - 0 punti)';
          score = 0;
        }

        print(
          'MUST BMI CALCULATION: BMI=$bmi, category=$calculatedValue, score=$score',
        );

        // CRITICAL: Auto-assign the response immediately for BMI calculation
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_responses[questionId] == null ||
              _responses[questionId]!['value'] != calculatedValue) {
            await _saveResponse(
              questionId,
              calculatedValue!,
              score,
              calculatedValue: displayValue,
            );
            print(
              'AUTO-SAVED MUST BMI RESPONSE: $calculatedValue with score $score',
            );
          }
        });
      } else {
        calculatedValue = 'Dati insufficienti';
        displayValue =
            'BMI non calcolabile - inserire altezza e peso nel profilo medico';
        score = 0;
        print('MUST BMI CALCULATION: No medical data available');
      }
    }
    // Handle other BMI-related questions (legacy support)
    else if (questionId.contains('bmi') || questionId.contains('BMI')) {
      final bmi = _calculatedValues['bmi'];
      if (bmi != null) {
        calculatedValue = bmi.toStringAsFixed(1);
        displayValue = 'BMI: $calculatedValue';

        // For general BMI < 20.5 questions
        if (questionId.contains('20_5') || questionId.contains('under')) {
          final isUnder20_5 = bmi < 20.5;
          calculatedValue = isUnder20_5 ? 'Sì' : 'No';
          displayValue =
              'BMI: ${bmi.toStringAsFixed(1)} - ${isUnder20_5 ? "Sotto 20.5" : "Sopra o uguale a 20.5"}';
          score = isUnder20_5 ? 1 : 0;
        }
      }
    }
    // Handle pathology-related questions
    else if (questionId.contains('patologia') ||
        questionId.contains('pathology')) {
      final pathologyInfo = await _questionnaireService.getPathologyInfo(
        SupabaseService.instance.client.auth.currentUser?.id ??
            'd4a87e24-2cab-4fc0-a753-fba15ba7c755',
      );

      final hasPathology = pathologyInfo['has_pathology'] as bool? ?? false;
      final primaryPathology = pathologyInfo['primary_pathology'] as String?;

      if (hasPathology && primaryPathology != null) {
        calculatedValue = 'Sì';
        displayValue = primaryPathology;
        score = 1;
      } else {
        calculatedValue = 'No';
        displayValue = 'Nessuna patologia registrata';
        score = 0;
      }
    }
    // Handle weight loss calculations
    else if (questionId.contains('weight_loss') ||
        questionId.contains('perdita_peso')) {
      final weightLoss3m = _calculatedValues['weight_loss_3m'];
      if (weightLoss3m != null) {
        final isSignificantLoss = weightLoss3m > 5.0;
        calculatedValue = isSignificantLoss ? 'Sì' : 'No';
        displayValue =
            'Perdita di peso 3 mesi: ${weightLoss3m.toStringAsFixed(1)}% - ${isSignificantLoss ? "Significativa (>5%)" : "Non significativa (≤5%)"}';
        score = isSignificantLoss ? 1 : 0;
      }
    }

    // Save the calculated response if we have a value
    if (calculatedValue != null && _sessionId != null) {
      await _saveResponse(
        questionId,
        calculatedValue,
        score,
        calculatedValue: displayValue,
      );
      print(
        'CALCULATED QUESTION SAVED: $questionId = $calculatedValue (score: $score)',
      );
    }
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionType = question['question_type'] as String;
    final questionText = question['question_text'] as String;
    final questionId = question['question_id'] as String;

    // CRITICAL FIX: Enhanced options parsing to handle both List and Map formats safely
    List<dynamic> options = [];
    Map<String, dynamic> scores = {};

    try {
      final optionsRaw = question['options'];
      final scoresRaw = question['scores'];

      // Handle options field - could be List, Map, or null
      if (optionsRaw != null) {
        if (optionsRaw is List) {
          options = optionsRaw;
        } else if (optionsRaw is Map) {
          // If it's a Map, extract values as options
          options = (optionsRaw as Map<String, dynamic>).values.toList();
        } else if (optionsRaw is String) {
          // If it's a JSON string, try to parse it
          try {
            final parsed = jsonDecode(optionsRaw);
            if (parsed is List) {
              options = parsed;
            } else if (parsed is Map) {
              options = (parsed as Map<String, dynamic>).values.toList();
            }
          } catch (parseError) {
            print(
                'OPTION PARSE ERROR: Failed to parse options JSON: $parseError');
            options = []; // Default to empty list
          }
        }
      }

      // Handle scores field - should be Map
      if (scoresRaw != null) {
        if (scoresRaw is Map) {
          scores = Map<String, dynamic>.from(scoresRaw);
        } else if (scoresRaw is String) {
          // If it's a JSON string, try to parse it
          try {
            final parsed = jsonDecode(scoresRaw);
            if (parsed is Map) {
              scores = Map<String, dynamic>.from(parsed);
            }
          } catch (parseError) {
            print(
                'SCORE PARSE ERROR: Failed to parse scores JSON: $parseError');
            scores = {}; // Default to empty map
          }
        }
      }

      print(
          'PARSED QUESTION DATA: questionId=$questionId, questionType=$questionType, optionsCount=${options.length}, scoresCount=${scores.length}');
    } catch (e) {
      print(
          'QUESTION PARSING ERROR: Failed to parse question data for $questionId: $e');
      // Use safe defaults
      options = [];
      scores = {};
    }

    final isRequired = question['is_required'] as bool? ?? true;
    final currentValue = _responses[questionId]?['value']?.toString() ?? '';

    // CRITICAL FIX: Add specific handling for MUST weight loss question to ensure proper options
    if (questionId == 'must_weight_loss_3_6_months') {
      // Ensure MUST question 2 has exactly 3 options as requested
      if (options.isEmpty || options.length != 3) {
        print(
            'MUST WEIGHT LOSS: Fixing options for question 2 - current count: ${options.length}');
        options = [
          '2-5% negli ultimi 3 mesi (o 5-10% negli ultimi 6 mesi)',
          '> 5% negli ultimi 3 mesi (o >10% negli ultimi 6 mesi)',
          'Grave perdita di peso (>15% negli ultimi 3-6 mesi o BMI<18.5 con perdita recente)'
        ];

        // Set appropriate scores for MUST questionnaire
        scores = {
          '2-5% negli ultimi 3 mesi (o 5-10% negli ultimi 6 mesi)': 1,
          '> 5% negli ultimi 3 mesi (o >10% negli ultimi 6 mesi)': 2,
          'Grave perdita di peso (>15% negli ultimi 3-6 mesi o BMI<18.5 con perdita recente)':
              2,
        };

        print(
            'MUST WEIGHT LOSS: Fixed options - now has ${options.length} options');
      }
    }

    switch (questionType) {
      case 'yes_no':
        return _buildYesNoQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
      case 'single_choice':
        return _buildSingleChoiceQuestion(
          questionText,
          questionId,
          options,
          currentValue,
          scores,
          isRequired,
        );
      case 'multiple_choice':
        return _buildMultipleChoiceQuestion(
          questionText,
          questionId,
          options,
          currentValue,
          scores,
          isRequired,
        );
      case 'scale_0_10':
        return _buildScaleQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
      case 'number_input':
        return _buildNumberInputQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
      case 'text_input':
        return _buildTextInputQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
      case 'calculated':
        return _buildCalculatedQuestion(questionText, questionId, currentValue);
      case 'food_database':
        return _buildFoodDatabaseQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
      default:
        return _buildTextInputQuestion(
          questionText,
          questionId,
          currentValue,
          isRequired,
        );
    }
  }

  Widget _buildYesNoQuestion(
    String questionText,
    String questionId,
    String currentValue,
    bool isRequired,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                'Sì',
                currentValue == 'Sì',
                // CRITICAL FIX: Don't calculate scores for SARC-F, SF-12, and ESAS questionnaires
                () => _saveResponse(
                  questionId,
                  'Sì',
                  (_isSarcFQuestionnaire() ||
                          _isSf12Questionnaire() ||
                          _isEsasQuestionnaire())
                      ? null
                      : 1,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildChoiceCard(
                'No',
                currentValue == 'No',
                // CRITICAL FIX: Don't calculate scores for SARC-F, SF-12, and ESAS questionnaires
                () => _saveResponse(
                  questionId,
                  'No',
                  (_isSarcFQuestionnaire() ||
                          _isSf12Questionnaire() ||
                          _isEsasQuestionnaire())
                      ? null
                      : 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleChoiceQuestion(
    String questionText,
    String questionId,
    List<dynamic> options,
    String currentValue,
    Map<String, dynamic> scores,
    bool isRequired,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Column(
          children: options.map<Widget>((option) {
            final optionText = option.toString();
            final optionScore = scores[optionText] as int? ?? 0;

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: _buildChoiceCard(
                optionText,
                currentValue == optionText,
                // CRITICAL FIX: Don't calculate scores for SARC-F and SF-12 questionnaires
                () => _saveResponse(
                  questionId,
                  optionText,
                  (_isSarcFQuestionnaire() ||
                          _isSf12Questionnaire() ||
                          _isEsasQuestionnaire())
                      ? null
                      : optionScore,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceQuestion(
    String questionText,
    String questionId,
    List<dynamic> options,
    String currentValue,
    Map<String, dynamic> scores,
    bool isRequired,
  ) {
    final selectedOptions =
        currentValue.isNotEmpty ? currentValue.split(',') : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Column(
          children: options.map<Widget>((option) {
            final optionText = option.toString();
            final isSelected = selectedOptions.contains(optionText);

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: _buildMultipleChoiceCard(
                optionText,
                isSelected,
                () => _toggleMultipleChoice(questionId, optionText, scores),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScaleQuestion(
    String questionText,
    String questionId,
    String currentValue,
    bool isRequired,
  ) {
    final currentScale = double.tryParse(currentValue) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currentScale.toInt().toString(),
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '10',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Slider(
                value: currentScale,
                min: 0,
                max: 10,
                divisions: 10,
                label: currentScale.toInt().toString(),
                onChanged: (value) {
                  // CRITICAL FIX: Don't calculate scores for SARC-F questionnaire
                  _saveResponse(
                    questionId,
                    value.toInt().toString(),
                    _isSarcFQuestionnaire() ? null : value.toInt(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInputQuestion(
    String questionText,
    String questionId,
    String currentValue,
    bool isRequired,
  ) {
    // CRITICAL FIX: Use persistent controller with proper state management
    final controller = _getTextController(questionId, currentValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            // CRITICAL FIX: Add focus indication
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal:
                  true, // CRITICAL FIX: Allow decimal input for measurements
              signed: false, // Don't allow negative numbers
            ),
            textInputAction: TextInputAction.done,
            // CRITICAL FIX: Add autofocus and selection behavior for better input experience
            autofocus: false,
            textAlign: TextAlign.start,
            enableInteractiveSelection: true,
            maxLength: null, // Allow unlimited length for measurements
            decoration: InputDecoration(
              hintText: 'Inserisci un numero',
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 16.sp,
              ),
              // CRITICAL FIX: Add content padding and improved styling
              contentPadding: EdgeInsets.symmetric(
                horizontal: 2.w,
                vertical: 1.h,
              ),
              // CRITICAL FIX: Remove counter text that might interfere
              counterText: '',
            ),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            // CRITICAL FIX: Enhanced text change handling with proper cursor management
            onChanged: (value) {
              print(
                'NUMBER INPUT CHANGED: questionId=$questionId, value="$value"',
              );

              // Immediate state update for UI responsiveness
              setState(() {
                _responses[questionId] = {
                  'value': value,
                  'score': _calculateNumberScore(value),
                  'calculated_value': null,
                };
              });

              // CRITICAL FIX: Debounced save to prevent too many database calls
              _debouncedSave(questionId, value);
            },
            // CRITICAL FIX: Handle submission when user presses done
            onSubmitted: (value) {
              print(
                'NUMBER INPUT SUBMITTED: questionId=$questionId, value="$value"',
              );
              _saveResponseImmediate(
                questionId,
                value,
                _calculateNumberScore(value),
              );
              // CRITICAL FIX: Keep focus for further input if needed
              FocusScope.of(context).requestFocus(FocusNode());
            },
            // CRITICAL FIX: Enhanced focus handling to prevent cursor issues
            onTap: () {
              print('NUMBER INPUT TAPPED: questionId=$questionId');
              // CRITICAL FIX: Ensure proper cursor positioning on tap
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.text.isNotEmpty) {
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                }
              });
            },
            // CRITICAL FIX: Handle editing complete to maintain focus if needed
            onEditingComplete: () {
              print('NUMBER INPUT EDITING COMPLETE: questionId=$questionId');
              // Don't automatically lose focus to allow continued editing
            },
          ),
        ),
        // CRITICAL FIX: Add visual feedback for current value
        if (currentValue.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Valore corrente: $currentValue${_getUnitForQuestion(questionId)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        SizedBox(height: 2.h),
        // CRITICAL FIX: Add helpful instructions for SARC-F calf circumference
        if (questionId.contains('circonferenza') ||
            questionId.contains('circumference')) ...[
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(26)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Puoi inserire valori decimali (es. 32,5 cm). Tocca il campo per modificare liberamente.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // CRITICAL FIX: Helper method to determine unit based on question
  String _getUnitForQuestion(String questionId) {
    if (questionId.contains('circonferenza') ||
        questionId.contains('circumference')) {
      return ' cm';
    }
    if (questionId.contains('peso') || questionId.contains('weight')) {
      return ' kg';
    }
    if (questionId.contains('altezza') || questionId.contains('height')) {
      return ' cm';
    }
    return '';
  }

  // CRITICAL FIX: Calculate appropriate score for number input
  int? _calculateNumberScore(String value) {
    // CRITICAL FIX: Don't calculate scores for SARC-F, SF-12, and ESAS questionnaires
    if (_isSarcFQuestionnaire() ||
        _isSf12Questionnaire() ||
        _isEsasQuestionnaire()) {
      return null; // No score calculation for SARC-F, SF-12, or ESAS
    }

    final numValue = double.tryParse(value);
    if (numValue == null || value.trim().isEmpty) return 0;

    // For SARC-F calf circumference, typically:
    // < 31 cm for men or < 33 cm for women indicates sarcopenia risk
    // Since we don't know gender here, use a general threshold
    if (numValue < 32.0) {
      return 1; // Higher score indicates higher risk
    }
    return 0;
  }

  // CRITICAL FIX: Debounced save to prevent excessive database calls
  Timer? _saveTimer;
  void _debouncedSave(String questionId, String value) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      final score = _calculateNumberScore(value);
      _saveResponseImmediate(questionId, value, score);
    });
  }

  // CRITICAL FIX: Immediate save method for critical saves
  Future<void> _saveResponseImmediate(
    String questionId,
    String value,
    int? score,
  ) async {
    try {
      print(
        'IMMEDIATE SAVE: questionId=$questionId, value="$value", score=$score',
      );
      await _saveResponse(questionId, value, score);
    } catch (e) {
      print('IMMEDIATE SAVE ERROR: $e');
    }
  }

  Widget _buildTextInputQuestion(
    String questionText,
    String questionId,
    String currentValue,
    bool isRequired,
  ) {
    final controller = _getTextController(questionId, currentValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Inserisci la tua risposta',
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            ),
            style: GoogleFonts.inter(fontSize: 16.sp),
            onChanged: (value) {
              _saveResponse(questionId, value, 0);
            },
          ),
        ),
      ],
    );
  }

  // CRITICAL FIX: Enhanced BMI display for calculated questions with MUST-specific logic
  Widget _buildCalculatedQuestion(
    String questionText,
    String questionId,
    String currentValue,
  ) {
    final calculatedDisplayValue =
        _responses[questionId]?['calculated_value']?.toString();
    final responseValue = _responses[questionId]?['value']?.toString();

    String? displayValue;
    String? resultText;
    Color resultColor = Colors.blue.shade700;
    IconData resultIcon = Icons.calculate;

    // CRITICAL FIX: Enhanced NRS 2002 BMI question handling
    if (questionId == 'nrs_bmi_under_20_5' && _isNrs2002Questionnaire()) {
      final bmi = _calculatedValues['bmi'];
      if (bmi != null) {
        final isUnder20_5 = bmi < 20.5;
        resultText = isUnder20_5 ? 'Sì' : 'No';
        displayValue =
            'BMI: ${bmi.toStringAsFixed(1)} - ${isUnder20_5 ? "Sotto 20.5" : "Sopra o uguale a 20.5"}';
        resultColor =
            isUnder20_5 ? Colors.orange.shade700 : Colors.green.shade700;
        resultIcon = isUnder20_5 ? Icons.warning : Icons.check_circle;

        // Auto-assign response
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_responses[questionId] == null ||
              _responses[questionId]!['value'] != resultText) {
            final score = isUnder20_5 ? 1 : 0;
            await _saveResponse(
              questionId,
              resultText!,
              score,
              calculatedValue: displayValue,
            );
            print('AUTO-ASSIGNED NRS 2002 BMI: $resultText with score $score');
          }
        });
      } else {
        resultText = 'Dati insufficienti';
        displayValue =
            'BMI non calcolabile - inserire altezza e peso nel profilo medico';
        resultColor = Colors.grey.shade600;
        resultIcon = Icons.error_outline;
      }
    }
    // CRITICAL FIX: Enhanced MUST BMI question handling with exact question ID
    else if (questionId == 'must_bmi_calculated' && _isMustQuestionnaire()) {
      final bmi = _calculatedValues['bmi'];
      if (bmi != null) {
        // MUST-specific BMI categorization with exact scoring criteria (scores hidden from user)
        if (bmi < 18.5) {
          resultText = 'BMI < 18.5';
          displayValue = 'BMI: ${bmi.toStringAsFixed(1)} (Sottopeso grave)';
          resultColor = Colors.red.shade700;
          resultIcon = Icons.warning;
        } else if (bmi >= 18.5 && bmi < 20.0) {
          resultText = '18.5 ≤ BMI < 20';
          displayValue =
              'BMI: ${bmi.toStringAsFixed(1)} (Lievemente sottopeso)';
          resultColor = Colors.orange.shade700;
          resultIcon = Icons.info;
        } else {
          resultText = 'BMI ≥ 20';
          displayValue = 'BMI: ${bmi.toStringAsFixed(1)} (Normale o superiore)';
          resultColor = Colors.green.shade700;
          resultIcon = Icons.check_circle;
        }

        // Auto-assign response with correct question ID
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_responses[questionId] == null ||
              _responses[questionId]!['value'] != resultText) {
            int bmiScore;
            if (bmi < 18.5) {
              bmiScore = 2;
            } else if (bmi >= 18.5 && bmi < 20.0) {
              bmiScore = 1;
            } else {
              bmiScore = 0;
            }

            await _saveResponse(
              questionId,
              resultText!,
              bmiScore,
              calculatedValue: displayValue,
            );
            print(
              'AUTO-ASSIGNED MUST BMI: $resultText with hidden score $bmiScore',
            );
          }
        });
      } else {
        resultText = 'Dati insufficienti';
        displayValue =
            'BMI non calcolabile - inserire altezza e peso nel profilo medico';
        resultColor = Colors.grey.shade600;
        resultIcon = Icons.error_outline;
      }
    }
    // Handle other calculated questions (existing logic)
    else if (questionId.contains('patologia') ||
        questionId.contains('pathology')) {
      final hasPathology = _calculatedValues['has_pathology'] as bool? ?? false;
      final pathologyText = _calculatedValues['pathology_text'] as String?;

      if (hasPathology && pathologyText != null) {
        resultText = 'Sì - $pathologyText';
        displayValue = 'Il paziente presenta: $pathologyText';
        resultColor = Colors.orange.shade700;
        resultIcon = Icons.medical_services;
      } else {
        resultText = 'No';
        displayValue = 'Nessuna patologia registrata nei dati medici';
        resultColor = Colors.green.shade700;
        resultIcon = Icons.health_and_safety;
      }
    }
    // Handle weight loss questions
    else if (questionId.contains('weight_loss') ||
        questionId.contains('perdita_peso')) {
      final weightLoss3m = _calculatedValues['weight_loss_3m'];
      if (weightLoss3m != null) {
        displayValue =
            'Perdita di peso (3 mesi): ${weightLoss3m.toStringAsFixed(1)}%';
        final isSignificant = weightLoss3m > 5.0;
        resultText = isSignificant ? 'Sì (>5%)' : 'No (≤5%)';
        resultColor =
            isSignificant ? Colors.red.shade700 : Colors.green.shade700;
        resultIcon = isSignificant ? Icons.trending_down : Icons.trending_flat;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(resultIcon, color: resultColor, size: 32),
              SizedBox(height: 1.h),
              Text(
                'Valore Calcolato Automaticamente',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              if (displayValue != null) ...[
                SizedBox(height: 1.h),
                Text(
                  displayValue,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (resultText != null) ...[
                SizedBox(height: 1.5.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: resultColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: resultColor.withAlpha(51)),
                  ),
                  child: Text(
                    // CRITICAL FIX: For NRS 2002 and MUST questionnaires, show clean result without "Risposta:" prefix
                    (_isMustQuestionnaire() || _isNrs2002Questionnaire())
                        ? resultText
                        : 'Risposta: $resultText',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                ),
              ],
              if (responseValue == null && _calculatedValues.isEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  'Caricamento dati medici...',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => _nextQuestion(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continua',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodDatabaseQuestion(
    String questionText,
    String questionId,
    String currentValue,
    bool isRequired,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          SizedBox(height: 1.h),
          Text(
            '* Campo obbligatorio',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 3.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.orange.shade700,
                size: 32,
              ),
              SizedBox(height: 1.h),
              Text(
                'Selezione dal Database Alimentari',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to food database selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Selezione database alimentari - In sviluppo',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Seleziona Alimento',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              if (currentValue.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Selezionato: $currentValue',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceCard(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        print('CHOICE SELECTED: $text, isSelected: $isSelected');
        onTap();
        // Force UI update after selection
        setState(() {
          // This will trigger a rebuild and update the _canProceedToNext() check
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceCard(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.green.shade700 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CRITICAL FIX: Enhanced save response specifically for MUST questionnaire
  Future<void> _saveResponse(
    String questionId,
    String value,
    int? score, {
    String? calculatedValue,
  }) async {
    if (_sessionId == null) return;

    // CRITICAL FIX: Update local state immediately for UI responsiveness
    setState(() {
      _responses[questionId] = {
        'value': value,
        'score': score,
        'calculated_value': calculatedValue,
      };
    });

    // CRITICAL FIX: For MUST questionnaire, don't show scores to user but still calculate backend
    print(
      'SAVE RESPONSE MUST: questionId=$questionId, value=$value, score=$score (hidden from user), sessionId=$_sessionId',
    );

    try {
      // CRITICAL FIX: Enhanced service call with retry logic
      final success =
          await _questionnaireService.saveQuestionnaireResponseWithRetry(
        _sessionId!,
        questionId,
        value,
        score, // Score is saved to backend but not shown to user for MUST
      );

      if (success) {
        print(
          'SAVE RESPONSE: Successfully saved response for question $questionId',
        );
      } else {
        print(
          'SAVE RESPONSE: Failed to save response for question $questionId',
        );
        // REMOVED: Hide orange popup as requested by user - users don't need to know about local saving
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(
        //         'Risposta salvata localmente. Sarà sincronizzata automaticamente.',
        //       ),
        //       backgroundColor: Colors.orange,
        //       duration: Duration(seconds: 2),
        //     ),
        //   );
        // }
      }
    } catch (e) {
      print('SAVE RESPONSE ERROR: $e');

      // REMOVED: Hide orange popup as requested by user - users don't need to know about local saving
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'Risposta salvata localmente. Sarà sincronizzata automaticamente.',
      //       ),
      //       backgroundColor: Colors.orange,
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      // }
    }
  }

  void _toggleMultipleChoice(
    String questionId,
    String optionText,
    Map<String, dynamic> scores,
  ) {
    final currentValue = _responses[questionId]?['value']?.toString() ?? '';
    final selectedOptions =
        currentValue.isNotEmpty ? currentValue.split(',') : <String>[];

    if (selectedOptions.contains(optionText)) {
      selectedOptions.remove(optionText);
    } else {
      selectedOptions.add(optionText);
    }

    final newValue = selectedOptions.join(',');

    // CRITICAL FIX: Don't calculate scores for SARC-F questionnaire
    int? totalScore;
    if (!_isSarcFQuestionnaire() &&
        !_isSf12Questionnaire() &&
        !_isEsasQuestionnaire()) {
      totalScore = 0;
      for (final option in selectedOptions) {
        totalScore = (totalScore ?? 0) + (scores[option] as int? ?? 0);
      }
    }

    _saveResponse(questionId, newValue, totalScore);
  }

  void _nextQuestion() {
    print(
      'NEXT QUESTION: Current index $_currentQuestionIndex, Total questions ${_questions.length}',
    );

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print(
        'NAVIGATION: Moved to question ${_currentQuestionIndex + 1}/${_questions.length}',
      );
    } else {
      print('NAVIGATION: Reached last question, submitting questionnaire');
      _submitQuestionnaire();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print(
        'NAVIGATION: Moved back to question ${_currentQuestionIndex + 1}/${_questions.length}',
      );
    }
  }

  bool _canProceedToNext() {
    if (_questions.isEmpty) {
      print('CAN PROCEED: No questions available');
      return false;
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final questionId = currentQuestion['question_id'] as String;
    final questionType = currentQuestion['question_type'] as String;
    final isRequired = currentQuestion['is_required'] as bool? ?? true;

    // Special handling for calculated questions - they should always be able to proceed
    if (questionType == 'calculated') {
      print('CAN PROCEED: Calculated question, allowing proceed');
      return true;
    }

    // For non-required questions, always allow proceed
    if (!isRequired) {
      print('CAN PROCEED: Non-required question, allowing proceed');
      return true;
    }

    // Check if we have a response for this question
    final response = _responses[questionId];
    if (response == null) {
      print('CAN PROCEED: No response found for required question $questionId');
      return false;
    }

    final value = response['value']?.toString() ?? '';
    final canProceed = value.trim().isNotEmpty;

    print(
      'CAN PROCEED: questionId=$questionId, value="$value", canProceed=$canProceed',
    );

    return canProceed;
  }

  Future<void> _submitQuestionnaire() async {
    if (_sessionId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ENHANCED: Additional validation before submission
      print('Submitting questionnaire for session: $_sessionId');

      final results = await _questionnaireService.completeAssessment(
        _sessionId!,
      );

      if (results != null) {
        print('Assessment completed successfully: $results');
        setState(() {
          _isCompleted = true;
          _completionResults = results;
          _isSubmitting = false;
        });

        // ADDED: Show success message with better feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Questionario "$_questionnaireName" completato con successo!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(
          'Risultati non ricevuti - possibile problema di connessione',
        );
      }
    } catch (e) {
      print('Error in _submitQuestionnaire: $e');
      setState(() {
        _isSubmitting = false;
      });

      // ENHANCED: Better error handling with more specific error messages
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissal by tapping outside
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Errore Completamento',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Si è verificato un problema nel completare il questionario.',
                  style: GoogleFonts.inter(fontSize: 16.sp),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Le tue risposte sono state salvate automaticamente.',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Vuoi riprovare a completare il questionario?',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to questionnaires list
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                child: Text(
                  'Esci',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _submitQuestionnaire(); // Retry submission
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Riprova',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Color _getRiskLevelColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'low':
        return 'Basso';
      case 'medium':
        return 'Medio';
      case 'high':
        return 'Alto';
      default:
        return 'Non determinato';
    }
  }

  Widget _buildCompletionScreen() {
    final totalScore = _completionResults?['total_score'] as int? ?? 0;
    final riskLevel = _completionResults?['risk_level'] as String? ?? '';

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 60,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Questionario Completato!',
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Grazie per aver completato "$_questionnaireName"',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // CRITICAL FIX: Different completion content for different questionnaire types
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(51)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_information,
                    color: Colors.blue.shade700,
                    size: 48,
                  ),
                  SizedBox(height: 2.h),

                  // CRITICAL FIX: NRS 2002 questionnaire shows specific advisory message (no score)
                  if (_isNrs2002Questionnaire()) ...[
                    Text(
                      'Valutazione Completata',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 32,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Rivolgiti al professionista presso cui ti trovi in cura nutrizionale per approfondimenti.',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'La tua valutazione NRS 2002 è stata registrata e sarà disponibile per la revisione professionale.',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.blue.shade600,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ]
                  // CRITICAL FIX: SF-12 questionnaire shows specific completion message (no score)
                  else if (_isSf12Questionnaire()) ...[
                    Text(
                      'Questionario Completato',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            color: Colors.green.shade700,
                            size: 32,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Le tue risposte al questionario SF-12 sono state registrate con successo.',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'I tuoi dati sono ora disponibili per la revisione da parte del professionista sanitario. Solo l\'ultima valutazione completata è conservata per la consultazione.',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.green.shade600,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ]
                  // CRITICAL FIX: MUST questionnaire shows only advisory message (no score)
                  else if (_isMustQuestionnaire()) ...[
                    Text(
                      'Valutazione Completata',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 32,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Rivolgiti al professionista presso cui ti trovi in cura nutrizionale per approfondimenti.',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'La tua valutazione è stata registrata e sarà disponibile per la revisione professionale.',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.blue.shade600,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Original results display for other questionnaires (SARC-F, etc.)
                    Text(
                      _isSarcFQuestionnaire()
                          ? 'Risposte Registrate'
                          : _isEsasQuestionnaire()
                              ? 'Sintomi Valutati'
                              : 'Risultati',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    if (_isSarcFQuestionnaire()) ...[
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_turned_in,
                              color: Colors.blue.shade700,
                              size: 32,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Le tue risposte sono state registrate con successo.',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Puoi consultare le risposte della tua ultima valutazione nella sezione dei questionari completati.',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.blue.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else if (_isEsasQuestionnaire()) ...[
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: Colors.orange.shade700,
                              size: 32,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'La tua valutazione dei sintomi ESAS è stata completata.',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'I livelli dei sintomi registrati sono disponibili per la consultazione medica. Solo l\'ultima valutazione è conservata.',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.orange.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Show scores for other scoring questionnaires
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Punteggio Totale:',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  totalScore.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Livello di Rischio:',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final riskColor = _getRiskLevelColor(
                                      riskLevel,
                                    );
                                    final riskText = _getRiskLevelText(
                                      riskLevel,
                                    );
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: riskColor.withAlpha(26),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        riskText,
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: riskColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Torna ai Questionari',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Questionario Completato',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: _buildCompletionScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _questionnaireName ?? 'Questionario',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_questions.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getProgressDisplayText(), // Use enhanced method for consistency
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 2.h),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: _loadQuestionsAndResumeProgress,
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  )
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Nessuna domanda disponibile',
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Le domande verranno caricate presto',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // CRITICAL FIX: Updated progress bar using dynamic calculation
                          Container(
                            margin: EdgeInsets.all(4.w),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progresso',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    // CRITICAL FIX: Show dynamic question count in requested format
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2.w,
                                            vertical: 0.5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _isQuestionnaireFullyCompleted()
                                                    ? Colors.green.withAlpha(26)
                                                    : Colors.blue.withAlpha(26),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  _isQuestionnaireFullyCompleted()
                                                      ? Colors.green.shade300
                                                      : Colors.blue.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            _getProgressDisplayText(), // Use enhanced method
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  _isQuestionnaireFullyCompleted()
                                                      ? Colors.green.shade700
                                                      : Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          '${((_getCompletedQuestionsCount() / _getTotalQuestionsCount()) * 100).toInt()}%',
                                          style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                LinearProgressIndicator(
                                  value: _getCompletedQuestionsCount() /
                                      _getTotalQuestionsCount(),
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isQuestionnaireFullyCompleted()
                                        ? Colors.green.shade600
                                        : Colors.blue.shade700,
                                  ),
                                  minHeight: 8,
                                ),
                              ],
                            ),
                          ),

                          // Question content
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentQuestionIndex = index;
                                });
                              },
                              itemCount: _questions.length,
                              itemBuilder: (context, index) {
                                final question = _questions[index];
                                return SingleChildScrollView(
                                  padding: EdgeInsets.all(4.w),
                                  child: _buildQuestionWidget(question),
                                );
                              },
                            ),
                          ),

                          // Navigation buttons
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_currentQuestionIndex > 0) ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _previousQuestion,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                        foregroundColor: Colors.black87,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 2.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Precedente',
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                                Expanded(
                                  child: ElevatedButton(
                                    // CRITICAL FIX: Enhanced button state logic
                                    onPressed: () {
                                      final canProceed = _canProceedToNext();
                                      print(
                                        'BUTTON PRESSED: canProceed=$canProceed, isSubmitting=$_isSubmitting',
                                      );

                                      if (canProceed && !_isSubmitting) {
                                        _nextQuestion();
                                      } else {
                                        print(
                                          'BUTTON BLOCKED: canProceed=$canProceed, isSubmitting=$_isSubmitting',
                                        );
                                        // Optional: Show feedback to user
                                        if (!canProceed && mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Seleziona una risposta prima di continuare',
                                              ),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      // Enhanced visual feedback for button state
                                      backgroundColor: _canProceedToNext()
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 2.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            _currentQuestionIndex ==
                                                    _questions.length - 1
                                                ? 'Completa'
                                                : 'Successiva',
                                            style: GoogleFonts.inter(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
}
