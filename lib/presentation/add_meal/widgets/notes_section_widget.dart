import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotesSectionWidget extends StatefulWidget {
  final String notes;
  final Function(String) onNotesChanged;
  final bool saveAsFavorite;
  final Function(bool) onSaveAsFavoriteChanged;
  final bool shareWithProvider;
  final Function(bool) onShareWithProviderChanged;

  const NotesSectionWidget({
    Key? key,
    required this.notes,
    required this.onNotesChanged,
    required this.saveAsFavorite,
    required this.onSaveAsFavoriteChanged,
    required this.shareWithProvider,
    required this.onShareWithProviderChanged,
  }) : super(key: key);

  @override
  State<NotesSectionWidget> createState() => _NotesSectionWidgetState();
}

class _NotesSectionWidgetState extends State<NotesSectionWidget> {
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();
  bool _isExpanded = false;
  static const int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.notes;
    _notesController.addListener(() {
      widget.onNotesChanged(_notesController.text);
    });

    _notesFocusNode.addListener(() {
      setState(() {
        _isExpanded =
            _notesFocusNode.hasFocus || _notesController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'note_add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Note aggiuntive',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildNotesField(),
          SizedBox(height: 3.h),
          _buildOptionsSection(),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    final characterCount = _notesController.text.length;
    final isOverLimit = characterCount > _maxCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _notesFocusNode.hasFocus
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
              width: _notesFocusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            focusNode: _notesFocusNode,
            maxLines: _isExpanded ? 6 : 3,
            minLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Aggiungi osservazioni correlate al trattamento, sintomi o preferenze dietetiche...',
              hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(3.w),
            ),
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textInputAction: TextInputAction.newline,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Note correlate al trattamento aiutano il team sanitario',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '$characterCount/$_maxCharacters',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: isOverLimit
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                fontWeight: isOverLimit ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
        if (isOverLimit) ...[
          SizedBox(height: 0.5.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                'Limite di caratteri superato',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        _buildOptionTile(
          icon: 'favorite_border',
          title: 'Salva come ricetta preferita',
          subtitle: 'Accesso rapido per futuri pasti registrati',
          value: widget.saveAsFavorite,
          onChanged: widget.onSaveAsFavoriteChanged,
          iconColor: AppTheme.lightTheme.colorScheme.secondary,
        ),
        SizedBox(height: 2.h),
        _buildOptionTile(
          icon: 'share',
          title: 'Condividi con operatore sanitario',
          subtitle: 'Includi nel prossimo report per revisione medica',
          value: widget.shareWithProvider,
          onChanged: widget.onShareWithProviderChanged,
          iconColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: value
            ? iconColor.withValues(alpha: 0.1)
            : AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.3)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: value
                  ? iconColor.withValues(alpha: 0.2)
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: value
                    ? (icon == 'favorite_border' ? 'favorite' : icon)
                    : icon,
                color:
                    value ? iconColor : AppTheme.lightTheme.colorScheme.outline,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: value
                        ? iconColor
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.lightTheme.colorScheme.outline,
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
