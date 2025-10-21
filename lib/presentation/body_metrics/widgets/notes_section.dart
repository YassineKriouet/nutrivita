import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotesSection extends StatefulWidget {
  final String notes;
  final Function(String) onNotesChanged;

  const NotesSection({
    Key? key,
    required this.notes,
    required this.onNotesChanged,
  }) : super(key: key);

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late TextEditingController _notesController;
  bool _isExpanded = false;
  final int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.lightTheme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'note_add',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sintomi e Note',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (!_isExpanded && _notesController.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 0.5.h),
                              child: Text(
                                _notesController.text.length > 50
                                    ? '${_notesController.text.substring(0, 50)}...'
                                    : _notesController.text,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: CustomIconWidget(
                        iconName: 'expand_more',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child:
                _isExpanded
                    ? Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 5,
                              maxLength: _maxCharacters,
                              onChanged: widget.onNotesChanged,
                              decoration: InputDecoration(
                                hintText:
                                    'Registra sintomi, effetti collaterali o osservazioni...',
                                hintStyle: AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(3.w),
                                counterStyle: AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onSurface,
                                  ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          _buildSuggestionChips(),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Affaticamento',
      'Nausea',
      'Perdita di appetito',
      'Aumento di peso',
      'Perdita di peso',
      'Gonfiore',
      'Dolore',
      'Buona energia',
      'Appetito normale',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggerimenti rapidi:',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children:
              suggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    final currentText = _notesController.text;
                    final newText =
                        currentText.isEmpty
                            ? suggestion
                            : '$currentText, $suggestion';

                    if (newText.length <= _maxCharacters) {
                      _notesController.text = newText;
                      widget.onNotesChanged(newText);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.w,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
