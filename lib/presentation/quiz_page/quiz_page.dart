import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  double _progressValue = 0.0;
  String? _currentCategory; // Changed to nullable - no default category
  int _overallProgress = 0;
  bool _showCategorySelection = true; // Start with category selection

  // Quiz Categories with comprehensive questions
  final List<Map<String, dynamic>> _quizCategories = [
    {
      'id': 'nutritional_knowledge',
      'title': 'Conoscenze Nutrizionali',
      'description': 'Domande fondamentali sulla nutrizione oncologica',
      'icon': Icons.school,
      'color': Colors.blue,
      'estimatedTime': '10-12 min',
      'difficulty': 'Intermedio',
      'questions': [
        {
          'id': 'nk_1',
          'question':
              'Qual è la funzione principale delle proteine nell\'organismo di un paziente oncologico?',
          'options': [
            'Fornire energia immediata',
            'Riparare e costruire tessuti',
            'Regolare la temperatura corporea',
            'Migliorare l\'appetito',
          ],
          'correct_answer': 'Riparare e costruire tessuti',
          'explanation':
              'Le proteine sono essenziali per riparare i tessuti danneggiati dalle terapie oncologiche e mantenere la massa muscolare.',
        },
        {
          'id': 'nk_2',
          'question': 'Quale macronutriente fornisce più energia per grammo?',
          'options': ['Proteine', 'Carboidrati', 'Grassi', 'Vitamine'],
          'correct_answer': 'Grassi',
          'explanation':
              'I grassi forniscono 9 kcal per grammo, più del doppio di proteine e carboidrati (4 kcal/g).',
        },
        {
          'id': 'nk_3',
          'question': 'I "supercibi" possono prevenire il cancro?',
          'options': [
            'Sì, completamente',
            'No, non esistono evidenze',
            'Solo alcuni tipi',
            'Dipende dalla dose',
          ],
          'correct_answer': 'No, non esistono evidenze',
          'explanation':
              'Nonostante abbiano proprietà benefiche, nessun alimento da solo può prevenire il cancro. È importante una dieta equilibrata.',
        },
      ],
    },
    {
      'id': 'treatment_understanding',
      'title': 'Comprensione del Trattamento',
      'description': 'Nutrizione durante le terapie oncologiche',
      'icon': Icons.healing,
      'color': Colors.green,
      'estimatedTime': '8-10 min',
      'difficulty': 'Avanzato',
      'questions': [
        {
          'id': 'tu_1',
          'question':
              'Perché è importante affrontare l\'intervento chirurgico in uno stato nutrizionale ottimale?',
          'options': [
            'Riduce il rischio di complicanze postoperatorie',
            'Migliora l\'estetica',
            'Accelera l\'anestesia',
            'Non ha importanza',
          ],
          'correct_answer': 'Riduce il rischio di complicanze postoperatorie',
          'explanation':
              'Una buona nutrizione preoperatoria migliora la cicatrizzazione e riduce le complicanze.',
        },
        {
          'id': 'tu_2',
          'question': 'Cosa fare in caso di bocca secca durante le terapie?',
          'options': [
            'Evitare di bere',
            'Mangiare cibi secchi',
            'Bere liquidi frequentemente',
            'Usare solo collutori',
          ],
          'correct_answer': 'Bere liquidi frequentemente',
          'explanation':
              'La bocca secca richiede idratazione costante con piccoli sorsi frequenti.',
        },
        {
          'id': 'tu_3',
          'question':
              'Gli alimenti ultraprocessati sono sicuri durante le terapie?',
          'options': [
            'Sì, sempre',
            'No, mai',
            'Da limitare',
            'Solo quelli biologici',
          ],
          'correct_answer': 'Da limitare',
          'explanation':
              'Gli alimenti ultraprocessati andrebbero limitati a favore di cibi freschi e meno elaborati.',
        },
      ],
    },
    {
      'id': 'symptom_awareness',
      'title': 'Consapevolezza dei Sintomi',
      'description': 'Riconoscimento e gestione dei sintomi',
      'icon': Icons.monitor_heart,
      'color': Colors.red,
      'estimatedTime': '12-15 min',
      'difficulty': 'Intermedio',
      'questions': [
        {
          'id': 'sa_1',
          'question': 'Qual è il segno più evidente di malnutrizione?',
          'options': [
            'Aumento di peso',
            'Perdita di peso involontaria',
            'Cambiamento del colore dei capelli',
            'Aumento dell\'appetito',
          ],
          'correct_answer': 'Perdita di peso involontaria',
          'explanation':
              'La perdita di peso non intenzionale è il primo indicatore di possibile malnutrizione.',
        },
        {
          'id': 'sa_2',
          'question': 'Come si può gestire la nausea durante i pasti?',
          'options': [
            'Non mangiare',
            'Mangiare velocemente',
            'Piccoli pasti frequenti',
            'Solo liquidi',
          ],
          'correct_answer': 'Piccoli pasti frequenti',
          'explanation':
              'Pasti piccoli e frequenti riducono la sensazione di nausea e facilitano la digestione.',
        },
        {
          'id': 'sa_3',
          'question': 'Quando consultare il nutrizionista?',
          'options': [
            'Solo se c\'è perdita di peso >10%',
            'Al primo sintomo nutrizionale',
            'Solo su indicazione medica',
            'Mai durante le terapie',
          ],
          'correct_answer': 'Al primo sintomo nutrizionale',
          'explanation':
              'È importante consultare precocemente per prevenire il peggioramento dello stato nutrizionale.',
        },
      ],
    },
    {
      'id': 'lifestyle_factors',
      'title': 'Fattori dello Stile di Vita',
      'description': 'Alimentazione e stile di vita sano',
      'icon': Icons.fitness_center,
      'color': Colors.purple,
      'estimatedTime': '6-8 min',
      'difficulty': 'Base',
      'questions': [
        {
          'id': 'lf_1',
          'question': 'Quale attività fisica è consigliata durante le terapie?',
          'options': [
            'Nessuna attività',
            'Solo riposo a letto',
            'Attività leggera e graduale',
            'Sport intensi',
          ],
          'correct_answer': 'Attività leggera e graduale',
          'explanation':
              'L\'attività fisica leggera aiuta a mantenere la forza e migliora il benessere generale.',
        },
        {
          'id': 'lf_2',
          'question': 'È importante mangiare in compagnia?',
          'options': [
            'No, meglio da soli',
            'Sì, migliora l\'appetito',
            'Solo in ospedale',
            'Dipende dal tipo di cibo',
          ],
          'correct_answer': 'Sì, migliora l\'appetito',
          'explanation':
              'Mangiare in compagnia può stimolare l\'appetito e migliorare il piacere del cibo.',
        },
        {
          'id': 'lf_3',
          'question': 'Come gestire i cambiamenti del gusto?',
          'options': [
            'Smettere di mangiare',
            'Sperimentare nuovi sapori',
            'Mangiare solo cibi insipidi',
            'Usare solo condimenti forti',
          ],
          'correct_answer': 'Sperimentare nuovi sapori',
          'explanation':
              'Provare nuovi sapori e combinazioni può aiutare ad adattarsi ai cambiamenti del gusto.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _currentQuestions {
    if (_currentCategory == null) return [];
    final category = _quizCategories.firstWhere(
      (cat) => cat['id'] == _currentCategory,
      orElse: () => _quizCategories.first,
    );
    return List<Map<String, dynamic>>.from(category['questions']);
  }

  Map<String, dynamic>? get _currentCategoryData {
    if (_currentCategory == null) return null;
    return _quizCategories.firstWhere(
      (cat) => cat['id'] == _currentCategory,
      orElse: () => _quizCategories.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _calculateOverallProgress();
  }

  void _updateProgress() {
    final questions = _currentQuestions;
    setState(() {
      _progressValue =
          questions.isEmpty
              ? 0
              : (_currentQuestionIndex + 1) / questions.length;
    });
    _calculateOverallProgress();
  }

  void _calculateOverallProgress() {
    int totalAnswered = 0;
    int totalQuestions = 0;

    for (final category in _quizCategories) {
      final questions = List<Map<String, dynamic>>.from(category['questions']);
      totalQuestions += questions.length;

      for (int i = 0; i < questions.length; i++) {
        final key = '${category['id']}_$i';
        if (_answers.containsKey(key)) {
          totalAnswered++;
        }
      }
    }

    setState(() {
      // UPDATED: Quiz progress contributes 50% to overall assessment progress
      // This ensures that quiz completion shows as max 50% of total assessment
      _overallProgress =
          totalQuestions > 0
              ? ((totalAnswered / totalQuestions) * 50)
                  .round() // Max 50% for Quiz Educativi
              : 0;
    });
  }

  void _selectAnswer(dynamic answer) {
    if (_currentCategory == null) return;
    final key = '${_currentCategory}_$_currentQuestionIndex';
    setState(() {
      _answers[key] = answer;
    });
    _calculateOverallProgress();
  }

  void _nextQuestion() {
    final questions = _currentQuestions;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _updateProgress();
      });
    } else {
      _showCategoryComplete();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _updateProgress();
      });
    }
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _currentCategory = categoryId;
      _currentQuestionIndex = 0;
      _showCategorySelection = false; // Hide category selection
      _updateProgress();
    });
  }

  void _goBackToCategorySelection() {
    setState(() {
      _showCategorySelection = true;
      _currentCategory = null;
    });
  }

  void _showCategoryComplete() {
    final questions = _currentQuestions;
    int correctAnswers = 0;

    if (_currentCategory == null) return;

    for (int i = 0; i < questions.length; i++) {
      final key = '${_currentCategory}_$i';
      if (_answers.containsKey(key)) {
        final question = questions[i];
        final userAnswer = _answers[key];
        final correctAnswer = question['correct_answer'];
        final selectedOption = question['options'][userAnswer];

        if (selectedOption == correctAnswer) {
          correctAnswers++;
        }
      }
    }

    final percentage = (correctAnswers / questions.length * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                percentage >= 80
                    ? Icons.star
                    : percentage >= 60
                    ? Icons.thumb_up
                    : Icons.info,
                color:
                    percentage >= 80
                        ? Colors.amber
                        : percentage >= 60
                        ? Colors.green
                        : Colors.orange,
                size: 28,
              ),
              SizedBox(width: 2.w),
              Expanded(child: Text('Categoria Completata!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color:
                      percentage >= 80
                          ? Colors.green.withAlpha(26)
                          : percentage >= 60
                          ? Colors.blue.withAlpha(26)
                          : Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: GoogleFonts.inter(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            percentage >= 80
                                ? Colors.green
                                : percentage >= 60
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    ),
                    Text(
                      'Punteggio',
                      style: GoogleFonts.inter(fontSize: 14.sp),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '$correctAnswers/${questions.length} corrette',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _getRecommendation(percentage),
                style: GoogleFonts.inter(fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetCurrentCategory();
              },
              child: const Text('Riprova'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _goBackToCategorySelection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Altre Categorie'),
            ),
          ],
        );
      },
    );
  }

  String _getRecommendation(int percentage) {
    if (percentage >= 80) {
      return 'Eccellente! Hai una solida comprensione di questo argomento.';
    } else if (percentage >= 60) {
      return 'Buon lavoro! Potresti rivedere alcuni concetti per migliorare.';
    } else {
      return 'Ti consigliamo di studiare di più questo argomento e consultare il tuo team medico.';
    }
  }

  void _resetCurrentCategory() {
    if (_currentCategory == null) return;
    setState(() {
      _currentQuestionIndex = 0;
      // Remove answers for current category
      _answers.removeWhere(
        (key, value) => key.toString().startsWith(_currentCategory!),
      );
      _updateProgress();
    });
  }

  bool _isCategoryCompleted(String categoryId) {
    final category = _quizCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
    );
    final questions = List<Map<String, dynamic>>.from(category['questions']);

    for (int i = 0; i < questions.length; i++) {
      final key = '${categoryId}_$i';
      if (!_answers.containsKey(key)) {
        return false;
      }
    }
    return true;
  }

  double _getCategoryProgress(String categoryId) {
    final category = _quizCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
    );
    final questions = List<Map<String, dynamic>>.from(category['questions']);
    int answered = 0;

    for (int i = 0; i < questions.length; i++) {
      final key = '${categoryId}_$i';
      if (_answers.containsKey(key)) {
        answered++;
      }
    }

    return questions.isEmpty ? 0 : (answered / questions.length) * 100;
  }

  void _showQuestionExplanation() {
    final questions = _currentQuestions;
    final categoryData = _currentCategoryData;
    if (_currentQuestionIndex < questions.length && categoryData != null) {
      final question = questions[_currentQuestionIndex];
      final explanation =
          question['explanation'] ?? 'Spiegazione non disponibile';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: categoryData['color']),
                SizedBox(width: 2.w),
                Expanded(child: Text('Spiegazione')),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                explanation,
                style: GoogleFonts.inter(fontSize: 16.sp),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ho capito!'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCategorySelection) {
      return _buildCategorySelectionScreen();
    }

    final questions = _currentQuestions;
    final categoryData = _currentCategoryData;

    if (_currentCategory == null || categoryData == null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Quiz Educativi',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(child: Text('Seleziona una categoria per iniziare')),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final questionKey = '${_currentCategory}_$_currentQuestionIndex';
    final hasAnswer = _answers.containsKey(questionKey);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quiz Educativi',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToCategorySelection,
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: categoryData['color'].withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Quiz: $_overallProgress%', // UPDATED: Label to show this is quiz progress
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: categoryData['color'],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: categoryData['color'].withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryData['color'].withAlpha(51),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryData['color'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            categoryData['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryData['title'],
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: categoryData['color'],
                                ),
                              ),
                              Text(
                                categoryData['description'],
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Progress Bar
                  Row(
                    children: [
                      Text(
                        'Domanda ${_currentQuestionIndex + 1} di ${questions.length}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: categoryData['color'],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(_progressValue * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: categoryData['color'],
                        ),
                      ),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: _showQuestionExplanation,
                        child: Icon(
                          Icons.help_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      categoryData['color'],
                    ),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            // Question Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion['question'],
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentQuestion['options'].length,
                        separatorBuilder:
                            (context, index) => SizedBox(height: 1.h),
                        itemBuilder: (context, index) {
                          final isSelected = _answers[questionKey] == index;
                          return InkWell(
                            onTap: () => _selectAnswer(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? categoryData['color'].withAlpha(26)
                                        : Colors.grey[50],
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? categoryData['color']
                                          : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          isSelected
                                              ? categoryData['color']
                                              : Colors.transparent,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? categoryData['color']
                                                : Colors.grey,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                            : null,
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      currentQuestion['options'][index],
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? categoryData['color']
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation Buttons
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const CustomIconWidget(
                        iconName: 'arrow_back',
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text('Precedente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton.icon(
                    onPressed: hasAnswer ? _nextQuestion : null,
                    icon: CustomIconWidget(
                      iconName:
                          _currentQuestionIndex == questions.length - 1
                              ? 'check'
                              : 'arrow_forward',
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      _currentQuestionIndex == questions.length - 1
                          ? 'Completa'
                          : 'Successiva',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasAnswer ? categoryData['color'] : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
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

  Widget _buildCategorySelectionScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quiz Educativi',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.quiz, size: 48, color: Colors.blue.shade700),
                    SizedBox(height: 2.h),
                    Text(
                      'Seleziona una Categoria Quiz',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Scegli l\'area che vuoi esplorare e testa le tue conoscenze',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Progresso Complessivo: $_overallProgress%',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              Text(
                'Categorie Disponibili',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 2.h),

              // Categories Grid
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quizCategories.length,
                separatorBuilder: (context, index) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final category = _quizCategories[index];
                  final isCompleted = _isCategoryCompleted(category['id']);
                  final progress = _getCategoryProgress(category['id']);

                  return InkWell(
                    onTap: () => _selectCategory(category['id']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: category['color'].withAlpha(51),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: category['color'],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              category['icon'],
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['title'],
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: category['color'],
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  category['description'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            category['estimatedTime'],
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bar_chart,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            category['difficulty'],
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (isCompleted)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                )
                              else
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      category['color'],
                                    ),
                                    strokeWidth: 3,
                                  ),
                                ),
                              SizedBox(height: 0.5.h),
                              Text(
                                '${progress.round()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isCompleted
                                          ? Colors.green
                                          : category['color'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
