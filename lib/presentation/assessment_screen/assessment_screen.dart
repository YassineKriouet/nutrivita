import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './widgets/assessment_overview_widget.dart';
import './widgets/questionnaire_tab_widget.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  String _currentView =
      'overview'; // 'overview', 'questionnaire' (quiz removed)

  void _navigateToQuestionnaire() {
    setState(() {
      _currentView = 'questionnaire';
    });
  }

  void _navigateToOverview() {
    setState(() {
      _currentView = 'overview';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentView == 'overview' ? 'Valutazione' : 'Questionari Clinici',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: _currentView != 'overview'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateToOverview,
              )
            : null,
      ),
      body: SafeArea(
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'questionnaire':
        return QuestionnaireTabWidget();
      case 'overview':
      default:
        return AssessmentOverviewWidget(
          userId: '',
          onNavigateToQuestionnaire: _navigateToQuestionnaire,
        );
    }
  }
}
