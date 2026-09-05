import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/gyeote_theme.dart';

/// 약속을 만들 때 고른 값.
typedef MeetupComposition = ({String name, DateTime meetAt});

/// 약속 만들기 시트.
///
/// 날짜 선택기를 쓰지 않는다. 이 앱의 약속은 "오늘, 곧"이 거의 전부다 —
/// 며칠 뒤 일정은 달력 앱이 이미 잘한다. 여기서 필요한 것은 몇 시간 안에
/// 모이자는 합의이고, 그건 버튼 세 개면 끝난다.
Future<MeetupComposition?> showMeetupComposer(
  BuildContext context, {
  String? placeLabel,
}) {
  return showModalBottomSheet<MeetupComposition>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: _MeetupComposer(placeLabel: placeLabel),
    ),
  );
}

class _MeetupComposer extends StatefulWidget {
  const _MeetupComposer({this.placeLabel});

  final String? placeLabel;

  @override
  State<_MeetupComposer> createState() => _MeetupComposerState();
}

class _MeetupComposerState extends State<_MeetupComposer> {
  final _name = TextEditingController();
  Duration _offset = const Duration(minutes: 30);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit(AppL10n l10n) {
    final name = _name.text.trim();
    Navigator.of(context).pop((
      name: name.isEmpty ? l10n.meetupNameHint : name,
      meetAt: DateTime.now().add(_offset),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    final options = <(String, Duration)>[
      (l10n.meetupIn30, const Duration(minutes: 30)),
      (l10n.meetupIn1h, const Duration(hours: 1)),
      (l10n.meetupIn2h, const Duration(hours: 2)),
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.meetupCreate,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.placeLabel ?? l10n.meetupPlaceHint,
              style: TextStyle(fontSize: 12.5, color: palette.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(l10n),
              decoration: InputDecoration(
                labelText: l10n.meetupNameLabel,
                hintText: l10n.meetupNameHint,
                filled: true,
                fillColor: palette.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GyeoteRadius.small),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, offset) in options)
                  ChoiceChip(
                    label: Text(label),
                    selected: _offset == offset,
                    onSelected: (_) => setState(() => _offset = offset),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submit(l10n),
                child: Text(l10n.meetupSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
