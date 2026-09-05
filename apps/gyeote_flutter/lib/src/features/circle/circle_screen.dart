import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_bridge.dart';
import '../../core/location/location_models.dart';
import '../../core/location/place_alert_geofence_sync.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({
    super.key,
    this.circleRepository,
    this.invitationRepository,
    this.placeAlertRepository,
    this.checkInRepository,
    this.locationBridge,
  });

  final CircleRepository? circleRepository;
  final InvitationRepository? invitationRepository;
  final PlaceAlertRepository? placeAlertRepository;
  final CheckInRepository? checkInRepository;
  final LocationBridge? locationBridge;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  List<_CircleMember> _demoMembers(AppL10n l10n) => [
    _CircleMember(
        name: _l10n.demoNameGuardian, role: _l10n.roleGuardian, status: _l10n.sharingPreciseShort, tone: GyeoteTone.brand),
    _CircleMember(
        name: _l10n.demoNameChild, role: _l10n.roleChild, status: _l10n.companionWaiting, tone: GyeoteTone.move),
    _CircleMember(
        name: _l10n.demoNameFriend, role: _l10n.roleFriend, status: _l10n.sharingBalancedShort, tone: GyeoteTone.warm),
    _CircleMember(
        name: _l10n.demoNameElder, role: _l10n.roleCare, status: _l10n.precisionArea, tone: GyeoteTone.alert),
  ];

  List<CircleSummary> _circles = const [];
  List<PlaceAlertRule> _placeAlerts = const [];
  List<CheckInEvent> _checkIns = const [];
  final Set<String> _busyPlaceAlertIds = {};
  final _inviteInputController = TextEditingController();
  InviteCreationResult? _inviteResult;
  String? _statusMessage;

  AppL10n get _l10n => AppL10n.of(context);

  /// 오류 색을 문구 내용으로 추측하지 않는다.
  bool _statusIsError = false;
  String? _placeAlertMessage;
  bool _placeAlertIsError = false;
  bool _placeAlertIsPending = false;
  String? _checkInMessage;
  bool _isLoadingCircles = false;
  bool _isLoadingPlaceAlerts = false;
  bool _isLoadingCheckIns = false;
  bool _isCreatingInvite = false;
  bool _isAcceptingInvite = false;

  bool get _hasBackend =>
      widget.circleRepository != null && widget.invitationRepository != null;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  @override
  void dispose() {
    _inviteInputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CircleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circleRepository != widget.circleRepository ||
        oldWidget.invitationRepository != widget.invitationRepository ||
        oldWidget.placeAlertRepository != widget.placeAlertRepository ||
        oldWidget.checkInRepository != widget.checkInRepository ||
        oldWidget.locationBridge != widget.locationBridge) {
      _circles = const [];
      _placeAlerts = const [];
      _checkIns = const [];
      _busyPlaceAlertIds.clear();
      _inviteResult = null;
      _statusMessage = null;
      _statusIsError = false;
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
      _checkInMessage = null;
      _loadCircles();
    }
  }

  Future<void> _loadCircles() async {
    final repository = widget.circleRepository;
    if (repository == null) {
      return;
    }

    setState(() {
      _isLoadingCircles = true;
      _isLoadingPlaceAlerts = false;
      _isLoadingCheckIns = false;
      _statusMessage = null;
      _statusIsError = false;
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
      _checkInMessage = null;
    });

    try {
      final circles = await repository.listCircles();
      if (!mounted) {
        return;
      }
      setState(() {
        _circles = circles;
        _isLoadingCircles = false;
      });
      if (circles.isNotEmpty) {
        await _loadPlaceAlerts(circles.first.id);
        await _loadCheckIns(circles.first.id);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCircles = false;
        _statusMessage = _l10n.circleLoadFailed;
        _statusIsError = true;
      });
    }
  }

  Future<void> _loadPlaceAlerts(String circleId) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      if (mounted) {
        setState(() => _placeAlerts = const []);
      }
      return;
    }

    setState(() {
      _isLoadingPlaceAlerts = true;
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
    });

    try {
      final alerts = await repository.listPlaceAlerts(circleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlerts = alerts;
        _isLoadingPlaceAlerts = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlerts = const [];
        _isLoadingPlaceAlerts = false;
        _placeAlertMessage = _l10n.placeAlertLoadFailed;
        _placeAlertIsError = true;
      });
    }
  }

  Future<void> _loadCheckIns(String circleId) async {
    final repository = widget.checkInRepository;
    if (repository == null) {
      if (mounted) {
        setState(() => _checkIns = const []);
      }
      return;
    }

    setState(() {
      _isLoadingCheckIns = true;
      _checkInMessage = null;
    });

    try {
      final events = await repository.listRecentCheckIns(
        circleId: circleId,
        limit: 5,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _checkIns = events;
        _isLoadingCheckIns = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checkIns = const [];
        _isLoadingCheckIns = false;
        _checkInMessage = _l10n.checkInLoadFailed;
      });
    }
  }

  Future<CircleSummary> _ensureCircle() async {
    if (_circles.isNotEmpty) {
      return _circles.first;
    }

    final repository = widget.circleRepository;
    if (repository == null) {
      throw StateError('Circle repository is not configured.');
    }

    final circle = await repository.createCircle(name: _l10n.privacyCircleFamily);
    if (mounted) {
      setState(() => _circles = [circle]);
      await _loadPlaceAlerts(circle.id);
      await _loadCheckIns(circle.id);
    }
    return circle;
  }

  Future<void> _createInvite() async {
    if (!_hasBackend) {
      setState(() {
      _statusMessage = _l10n.inviteNeedsBackend;
      _statusIsError = true;
    });
      return;
    }

    setState(() {
      _isCreatingInvite = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      final circle = await _ensureCircle();
      final invite = await widget.invitationRepository!.createInvite(
        circleId: circle.id,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _inviteResult = invite;
        _statusMessage = _l10n.inviteCreated;
        _statusIsError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
      _statusMessage = _l10n.inviteCreateFailed;
      _statusIsError = true;
    });
    } finally {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
      }
    }
  }

  Future<void> _copyInviteLink() async {
    final invite = _inviteResult;
    if (invite == null) {
      return;
    }

    await Clipboard.setData(
        ClipboardData(text: invite.rawInviteUrl.toString()));
    if (mounted) {
      setState(() {
      _statusMessage = _l10n.inviteCopied;
      _statusIsError = false;
    });
    }
  }

  Future<void> _acceptInvite() async {
    final repository = widget.invitationRepository;
    final rawInput = _inviteInputController.text.trim();

    if (repository == null) {
      setState(() {
      _statusMessage = _l10n.inviteAcceptNeedsBackend;
      _statusIsError = true;
    });
      return;
    }

    final token = _inviteTokenFromInput(rawInput);
    if (token == null) {
      setState(() {
      _statusMessage = _l10n.inviteTokenRequired;
      _statusIsError = true;
    });
      return;
    }

    setState(() {
      _isAcceptingInvite = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      await repository.acceptInvite(rawInviteToken: token);
      _inviteInputController.clear();
      await _loadCircles();
      if (!mounted) {
        return;
      }
      setState(() {
      _statusMessage = _l10n.inviteAccepted;
      _statusIsError = false;
    });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
      _statusMessage = _l10n.inviteAcceptFailed;
      _statusIsError = true;
    });
    } finally {
      if (mounted) {
        setState(() => _isAcceptingInvite = false);
      }
    }
  }

  Future<void> _setPlaceAlertEnabled(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() {
      _placeAlertMessage = _l10n.placeAlertChangeNeedsBackend;
      _placeAlertIsError = true;
    });
      return;
    }

    final nextEnabled = !alert.enabled;
    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
    });

    try {
      await repository.setPlaceAlertEnabled(
        alertId: alert.id,
        enabled: nextEnabled,
      );
      await _loadPlaceAlerts(alert.circleId);
      final synced = await _syncPlaceAlertGeofences(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _placeAlertMessage = synced
            ? (nextEnabled ? _l10n.placeAlertResumed : _l10n.placeAlertPaused)
            : _l10n.placeAlertServerOnlyUpdate;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
      _placeAlertMessage = _l10n.placeAlertToggleFailed;
      _placeAlertIsError = true;
    });
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<void> _cyclePlaceAlertQuietHours(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() {
      _placeAlertMessage = _l10n.quietHoursNeedsBackend;
      _placeAlertIsError = true;
    });
      return;
    }

    final nextQuietHours = _nextPlaceAlertQuietHours(_l10n, alert.quietHours);
    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
    });

    try {
      await repository.setPlaceAlertQuietHours(
        alertId: alert.id,
        quietHours: nextQuietHours,
      );
      await _loadPlaceAlerts(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() =>
          _placeAlertMessage = _l10n.quietHoursChanged(nextQuietHours.summary(_l10n)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
      _placeAlertMessage = _l10n.quietHoursChangeFailed;
      _placeAlertIsError = true;
    });
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<void> _confirmDeletePlaceAlert(PlaceAlertRule alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.placeAlertDeleteTitle),
        content:
            Text(_l10n.placeAlertDeleteConfirm(alert.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.sosCancel),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(_l10n.privacyDataDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePlaceAlert(alert);
    }
  }

  Future<void> _deletePlaceAlert(PlaceAlertRule alert) async {
    final repository = widget.placeAlertRepository;
    if (repository == null) {
      setState(() {
      _placeAlertMessage = _l10n.placeAlertDeleteNeedsBackend;
      _placeAlertIsError = true;
    });
      return;
    }

    setState(() {
      _busyPlaceAlertIds.add(alert.id);
      _placeAlertMessage = null;
      _placeAlertIsError = false;
      _placeAlertIsPending = false;
    });

    try {
      await repository.deletePlaceAlert(alert.id);
      await _loadPlaceAlerts(alert.circleId);
      final synced = await _syncPlaceAlertGeofences(alert.circleId);
      if (!mounted) {
        return;
      }
      setState(() => _placeAlertMessage =
          synced ? _l10n.placeAlertDeleted : _l10n.placeAlertServerOnlyDelete);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
      _placeAlertMessage = _l10n.placeAlertDeleteFailed;
      _placeAlertIsError = true;
    });
    } finally {
      if (mounted) {
        setState(() => _busyPlaceAlertIds.remove(alert.id));
      }
    }
  }

  Future<bool> _syncPlaceAlertGeofences(String circleId) async {
    final repository = widget.placeAlertRepository;
    final bridge = widget.locationBridge;
    if (repository == null || bridge == null) {
      return true;
    }

    try {
      await syncPlaceAlertGeofences(
        repository: repository,
        locationBridge: bridge,
        circleId: circleId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _inviteTokenFromInput(String value) {
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    final token = uri?.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      return token;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final activeCircle = _circles.isEmpty ? null : _circles.first;
    final memberCount = activeCircle == null || activeCircle.memberCount == 0
        ? 1
        : activeCircle.memberCount;
    final title = activeCircle?.name ?? l10n.privacyCircleFamily;
    final subtitle = _isLoadingCircles
        ? l10n.circleSyncing
        : activeCircle == null
            ? l10n.circleCreateFirstBody
            : l10n.circleSummary(memberCount);
    final statusColor = _statusIsError ? palette.alert : palette.brand;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(color: palette.muted)),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(_statusMessage!,
                        style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _isCreatingInvite
                  ? null
                  : () async {
                      await _createInvite();
                    },
              icon: _isCreatingInvite
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: Text(activeCircle == null ? l10n.circleCreate : l10n.inviteCreate),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InviteCard(
          inviteResult: _inviteResult,
          onCreateInvite: _isCreatingInvite ? null : _createInvite,
          onCopyInvite: _inviteResult == null ? null : _copyInviteLink,
        ),
        const SizedBox(height: 12),
        _InviteAcceptCard(
          controller: _inviteInputController,
          isLoading: _isAcceptingInvite,
          onAccept: _acceptInvite,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.memberFallbackName,
          trailing: TextButton(
            onPressed: activeCircle == null && _hasBackend ? null : () {},
            child: Text(l10n.circleManageMembers),
          ),
          child: activeCircle == null && _hasBackend
              ? const _EmptyMembersState()
              : Column(
                  children: [
                    for (final member in _demoMembers(l10n))
                      _MemberRow(member: member),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const _CompanionRequestCard(),
        const SizedBox(height: 12),
        _CheckInStatusCard(
          events: _hasBackend ? _checkIns : null,
          hasCircle: activeCircle != null,
          isLoading: _isLoadingCheckIns,
          message: _checkInMessage,
        ),
        const SizedBox(height: 12),
        _PlaceAlertCard(
          alerts: _hasBackend ? _placeAlerts : null,
          hasCircle: activeCircle != null,
          isLoading: _isLoadingPlaceAlerts,
          message: _placeAlertMessage,
          isError: _placeAlertIsError,
          isPending: _placeAlertIsPending,
          busyAlertIds: _busyPlaceAlertIds,
          onToggleEnabled: _setPlaceAlertEnabled,
          onCycleQuietHours: _cyclePlaceAlertQuietHours,
          onDelete: _confirmDeletePlaceAlert,
        ),
      ],
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.brandSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.circleNoMembers, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(l10n.circleNoMembersBody,
              style: TextStyle(color: palette.muted)),
        ],
      ),
    );
  }
}

class _InviteAcceptCard extends StatelessWidget {
  const _InviteAcceptCard({
    required this.controller,
    required this.isLoading,
    required this.onAccept,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return _SectionCard(
      title: l10n.inviteJoin,
      trailing: _StatusChip(text: l10n.inviteVerifyToken),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.inviteTokenLabel,
              prefixIcon: const Icon(Icons.link_outlined),
            ),
            onSubmitted: (_) async {
              if (!isLoading) {
                await onAccept();
              }
            },
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    await onAccept();
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(l10n.inviteAccept),
          ),
        ],
      ),
    );
  }
}

class _CircleMember {
  const _CircleMember({
    required this.name,
    required this.role,
    required this.status,
    required this.tone,
  });

  final String name;
  final String role;
  final String status;
  final GyeoteTone tone;
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.inviteResult,
    required this.onCreateInvite,
    required this.onCopyInvite,
  });

  final InviteCreationResult? inviteResult;
  final Future<void> Function()? onCreateInvite;
  final Future<void> Function()? onCopyInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final invite = inviteResult?.invite;
    final rawInviteUrl = inviteResult?.rawInviteUrl.toString();

    return _SectionCard(
      title: l10n.inviteLink,
      trailing: _StatusChip(text: invite == null ? l10n.privacyRetention24Hours : invite.codeHint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invite == null ? 'GYE-42K' : invite.codeHint,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0),
          ),
          const SizedBox(height: 6),
          Text(
            rawInviteUrl ?? l10n.inviteSafetyNote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(text: l10n.inviteVerifyInviter),
              _StatusChip(text: l10n.adNotice),
              _StatusChip(text: l10n.inviteConsentLocation),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreateInvite == null
                      ? null
                      : () async {
                          await onCreateInvite!();
                        },
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text(l10n.inviteNewLink),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCopyInvite == null
                      ? null
                      : () async {
                          await onCopyInvite!();
                        },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.inviteCopy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final _CircleMember member;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: member.tone.resolveSoft(palette),
            child: Text(
              member.name.characters.first,
              style: TextStyle(
                  color: member.tone.resolve(palette),
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(member.role,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
          _StatusChip(text: member.status),
        ],
      ),
    );
  }
}

class _CompanionRequestCard extends StatelessWidget {
  const _CompanionRequestCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return _SectionCard(
      title: l10n.companionRequest,
      trailing: _StatusChip(text: l10n.mutualConsent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.companionRequestDemo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l10n.companionRequestBody,
              style: TextStyle(color: palette.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {}, child: Text(l10n.companionLater))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton(
                      onPressed: () {}, child: Text(l10n.companionAllow))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckInStatusCard extends StatelessWidget {
  const _CheckInStatusCard({
    required this.events,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
  });

  final List<CheckInEvent>? events;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final items = events;
    final countLabel = items == null ? l10n.sampleLabel : l10n.itemCount(items.length);

    return _SectionCard(
      title: l10n.checkInSectionTitle,
      trailing: _StatusChip(text: isLoading ? l10n.syncLabel : countLabel),
      child: _CheckInStatusBody(
        events: items,
        hasCircle: hasCircle,
        isLoading: isLoading,
        message: message,
      ),
    );
  }
}

class _CheckInStatusBody extends StatelessWidget {
  const _CheckInStatusBody({
    required this.events,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
  });

  final List<CheckInEvent>? events;
  final bool hasCircle;
  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (isLoading) {
      return _InlineLoadingState(text: l10n.checkInLoading);
    }

    if (message != null) {
      return _InlineEmptyState(
        icon: Icons.sync_problem_outlined,
        title: l10n.checkInSyncFailed,
        body: message!,
      );
    }

    final items = events;
    if (items == null) {
      return Column(
        children: [
          _CheckInRow(
            name: l10n.demoNameChild,
            status: l10n.checkInSafeArrived,
            body: l10n.checkInDemoDetail,
          ),
          _CheckInRow(
            name: l10n.demoNameElder,
            status: l10n.checkInWeakSignal,
            body: l10n.checkInTroubleshoot,
          ),
        ],
      );
    }

    if (!hasCircle) {
      return _InlineEmptyState(
        icon: Icons.verified_user_outlined,
        title: l10n.circleCreateFirst,
        body: l10n.checkInNote,
      );
    }

    if (items.isEmpty) {
      return _InlineEmptyState(
        icon: Icons.check_circle_outline,
        title: l10n.checkInNoneRecent,
        body: l10n.checkInEmptyBody,
      );
    }

    return Column(
      children: [
        for (final event in items)
          _CheckInRow(
            name: event.displayName.isEmpty
                ? l10n.memberFallbackName
                : event.displayName,
            status: _checkInStatusLabel(l10n, event.status),
            body:
                l10n.checkInDetailLine(
      _sharingModeLabel(l10n, event.sharingMode),
      _relativeTimeLabel(l10n, event.createdAt),
    ),
          ),
      ],
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({
    required this.name,
    required this.status,
    required this.body,
  });

  final String name;
  final String status;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 20, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name · $status',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceAlertCard extends StatelessWidget {
  const _PlaceAlertCard({
    required this.alerts,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
    required this.isError,
    required this.isPending,
    required this.busyAlertIds,
    required this.onToggleEnabled,
    required this.onCycleQuietHours,
    required this.onDelete,
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;
  final bool isError;
  final bool isPending;
  final Set<String> busyAlertIds;
  final ValueChanged<PlaceAlertRule> onToggleEnabled;
  final ValueChanged<PlaceAlertRule> onCycleQuietHours;
  final ValueChanged<PlaceAlertRule> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final rules = alerts;
    final countLabel = rules == null ? l10n.sampleLabel : l10n.itemCount(rules.length);

    return _SectionCard(
      title: l10n.placeAlertSectionTitle,
      trailing: _StatusChip(text: isLoading ? l10n.syncLabel : countLabel),
      child: _PlaceAlertCardBody(
        alerts: rules,
        hasCircle: hasCircle,
        isLoading: isLoading,
        message: message,
        isError: isError,
        isPending: isPending,
        busyAlertIds: busyAlertIds,
        onToggleEnabled: onToggleEnabled,
        onCycleQuietHours: onCycleQuietHours,
        onDelete: onDelete,
      ),
    );
  }
}

class _PlaceAlertCardBody extends StatelessWidget {
  const _PlaceAlertCardBody({
    required this.alerts,
    required this.hasCircle,
    required this.isLoading,
    required this.message,
    required this.isError,
    required this.isPending,
    required this.busyAlertIds,
    required this.onToggleEnabled,
    required this.onCycleQuietHours,
    required this.onDelete,
  });

  final List<PlaceAlertRule>? alerts;
  final bool hasCircle;
  final bool isLoading;
  final String? message;
  final bool isError;
  final bool isPending;
  final Set<String> busyAlertIds;
  final ValueChanged<PlaceAlertRule> onToggleEnabled;
  final ValueChanged<PlaceAlertRule> onCycleQuietHours;
  final ValueChanged<PlaceAlertRule> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (isLoading) {
      return _InlineLoadingState(text: l10n.placeAlertLoading);
    }

    final rules = alerts;
    final messageBanner = message == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InlineNoticeState(
              icon: _placeAlertMessageIcon(
                isError: isError,
                isPending: isPending,
              ),
              title: _placeAlertMessageTitle(
                l10n,
                isError: isError,
                isPending: isPending,
              ),
              body: message!,
              isError: isError || isPending,
            ),
          );

    if (rules == null) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          _AlertRule(
              title: l10n.placeSchool, body: l10n.placeAlertDemoRule),
          _AlertRule(title: l10n.placeHome, body: l10n.checkInDemoScope),
          _AlertRule(title: l10n.placeClinic, body: l10n.checkInDemoLongStay),
        ],
      );
    }

    if (!hasCircle) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          _InlineEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: l10n.circleCreateFirst,
            body: l10n.placeAlertNoneBody,
          ),
        ],
      );
    }

    if (rules.isEmpty) {
      return Column(
        children: [
          if (messageBanner != null) messageBanner,
          _InlineEmptyState(
            icon: Icons.notifications_none_outlined,
            title: l10n.placeAlertNone,
            body: l10n.placeAlertHint,
          ),
        ],
      );
    }

    return Column(
      children: [
        if (messageBanner != null) messageBanner,
        for (final alert in rules)
          _AlertRule(
            title: alert.name,
            body: _placeAlertBody(l10n, alert),
            enabled: alert.enabled,
            isBusy: busyAlertIds.contains(alert.id),
            onToggleEnabled: () => onToggleEnabled(alert),
            onCycleQuietHours: () => onCycleQuietHours(alert),
            onDelete: () => onDelete(alert),
          ),
      ],
    );
  }
}

class _InlineNoticeState extends StatelessWidget {
  const _InlineNoticeState({
    required this.icon,
    required this.title,
    required this.body,
    required this.isError,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final color = isError ? palette.alert : palette.brand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRule extends StatelessWidget {
  const _AlertRule({
    required this.title,
    required this.body,
    this.enabled = true,
    this.isBusy = false,
    this.onToggleEnabled,
    this.onCycleQuietHours,
    this.onDelete,
  });

  final String title;
  final String body;
  final bool enabled;
  final bool isBusy;
  final VoidCallback? onToggleEnabled;
  final VoidCallback? onCycleQuietHours;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final iconColor = enabled ? palette.warm : palette.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (isBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      if (!enabled) _StatusChip(text: l10n.pauseLabel),
                      if (onToggleEnabled != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: enabled ? l10n.pauseLabel : l10n.resumeLabel,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(enabled
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline),
                            onPressed: onToggleEnabled,
                          ),
                        ),
                      ],
                      if (onCycleQuietHours != null) ...[
                        const SizedBox(width: 2),
                        Tooltip(
                          message: l10n.quietHoursChange,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.bedtime_outlined),
                            onPressed: onCycleQuietHours,
                          ),
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(width: 2),
                        Tooltip(
                          message: l10n.privacyDataDelete,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            color: palette.alert,
                            onPressed: onDelete,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoadingState extends StatelessWidget {
  const _InlineLoadingState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: palette.muted)),
        ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surfaceAlt,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.brand, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(
                        color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _placeAlertBody(AppL10n l10n, PlaceAlertRule alert) {
  final events = [
    if (alert.notifyOnArrival) l10n.placeRuleArrival,
    if (alert.notifyOnDeparture) l10n.placeRuleDeparture,
    if (alert.notifyOnLate) l10n.placeRuleLate,
    if (alert.notifyOnLongStay) l10n.placeRuleLongStay,
  ];
  final quietHoursLabel =
      alert.quietHours.enabled ? l10n.quietHoursSummary(alert.quietHours.summary(l10n)) : null;
  final targetLabel =
      alert.targetCount == 0 ? l10n.targetsUnset : l10n.targetCount(alert.targetCount);
  final eventLabel = events.isEmpty ? l10n.rulesNone : events.join('/');
  return [
    targetLabel,
    l10n.radiusMeters(alert.radiusM),
    eventLabel,
    if (quietHoursLabel != null) quietHoursLabel,
  ].join(' · ');
}

/// 다음 방해 금지 프리셋.
///
/// 저장된 `label` 을 번역 문구와 비교한다. 라벨은 만든 사람의 언어로 DB 에 굳기
/// 때문에, 다른 언어를 쓰는 멤버가 순환시키면 첫 프리셋으로 되돌아간다. 제대로
/// 고치려면 라벨 대신 프리셋 키를 저장해야 하고, 그건 스키마 변경이다.
/// `timeZone` 이 서울로 고정된 것도 같은 자리에서 함께 고쳐야 한다.
PlaceAlertQuietHours _nextPlaceAlertQuietHours(
  AppL10n l10n,
  PlaceAlertQuietHours current,
) {
  if (!current.enabled) {
    return PlaceAlertQuietHours(
      enabled: true,
      start: '22:00',
      end: '07:00',
      timeZone: 'Asia/Seoul',
      label: l10n.quietHoursNight,
    );
  }

  if (current.label == l10n.quietHoursNight) {
    return PlaceAlertQuietHours(
      enabled: true,
      start: '09:00',
      end: '17:00',
      timeZone: 'Asia/Seoul',
      label: l10n.quietHoursClassOrWork,
    );
  }

  return const PlaceAlertQuietHours.none();
}

/// 상태는 문구를 훑어 추측하지 않고 호출부가 넘긴다.
/// 예전에는 '못했습니다'/'대기 중' 부분 문자열로 판별해서 번역과 함께 깨졌다.
IconData _placeAlertMessageIcon({required bool isError, required bool isPending}) {
  if (isPending) return Icons.sync_problem_outlined;
  if (isError) return Icons.error_outline;
  return Icons.check_circle_outline;
}

String _placeAlertMessageTitle(
  AppL10n l10n, {
  required bool isError,
  required bool isPending,
}) {
  if (isPending) return l10n.deviceSyncPending;
  if (isError) return l10n.placeAlertUpdateFailed;
  return l10n.placeAlertUpdating;
}

String _checkInStatusLabel(AppL10n l10n, CheckInStatus status) {
  switch (status) {
    case CheckInStatus.safeArrived:
      return l10n.checkInSafeArrived;
    case CheckInStatus.needsCheck:
      return l10n.checkInNeedsCheck;
    case CheckInStatus.signalWeak:
      return l10n.checkInWeakSignal;
  }
}

String _sharingModeLabel(AppL10n l10n, SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return l10n.sharingModePrecise;
    case SharingMode.balanced:
      return l10n.sharingModeBalanced;
    case SharingMode.area:
      return l10n.sharingModeArea;
    case SharingMode.hidden:
      return l10n.sharingModeHidden;
    case SharingMode.sosOnly:
      return l10n.sharingModeSosOnly;
  }
}

String _relativeTimeLabel(AppL10n l10n, DateTime recordedAt) {
  final diff = DateTime.now().difference(recordedAt);
  if (diff.inSeconds < 60) {
    return l10n.agoJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.agoMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.agoHours(diff.inHours);
  }
  return l10n.agoDays(diff.inDays);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(8),
        color: palette.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(6),
        color: palette.surfaceAlt,
      ),
      child: Text(
        text,
        style: TextStyle(
            color: palette.brand,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
