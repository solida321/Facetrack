import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/location_api.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/location_model.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/bloom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/primary_button.dart';

/// Where a shift happens. A location is a point on the map plus a radius:
/// employees can only check in while their phone is inside that circle.
class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await LocationApi.getAll();
      if (!mounted) return;
      setState(() {
        _locations = items;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = apiErrorMessage(e, fallback: 'Could not load locations.');
      });
    }
  }

  Future<void> _openForm({LocationModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _LocationFormSheet(existing: existing, onSaved: _load),
    );
  }

  Future<void> _delete(LocationModel location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text(
          'Delete "${location.name}"? This only works if no schedule uses it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.absent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await LocationApi.delete(location.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      // The server explains why, e.g. "still used by 2 schedule(s)".
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: 'Could not delete this location.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Where shifts happen.', style: AppTextStyles.headline),
            Text('${_locations.length} locations', style: AppTextStyles.bodySoft),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Add location',
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () => _openForm(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _loadError != null
                  ? _message(_loadError!, Icons.error_outline_rounded)
                  : _locations.isEmpty
                      ? _message('No locations yet. Tap + to add your first one.', Icons.place_outlined)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: _locations.length,
                          itemBuilder: (context, i) {
                            final l = _locations[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: BloomCard(
                                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.place_rounded,
                                          color: AppColors.primaryDeep, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.name,
                                            style: const TextStyle(
                                              fontFamily: 'Sora',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}',
                                            style: AppTextStyles.bodySoft,
                                          ),
                                          Text(
                                            '${l.allowedRadiusMeters} m radius',
                                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _openForm(existing: l),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.absent),
                                      onPressed: () => _delete(l),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }

  Widget _message(String text, IconData icon) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        EmptyState(message: text, icon: icon),
      ],
    );
  }
}

class _LocationFormSheet extends StatefulWidget {
  final LocationModel? existing;
  final VoidCallback onSaved;
  const _LocationFormSheet({this.existing, required this.onSaved});

  @override
  State<_LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<_LocationFormSheet> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  bool _isSaving = false;
  bool _isLocating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _latController.text = e.latitude.toString();
      _lngController.text = e.longitude.toString();
      _radiusController.text = e.allowedRadiusMeters.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  /// Fills latitude/longitude from the phone's GPS — stand in the doorway of
  /// the workplace, tap this, and the coordinates are exact.
  Future<void> _useMyLocation() async {
    setState(() {
      _isLocating = true;
      _error = null;
    });
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _isLocating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _error = apiErrorMessage(e, fallback: 'Could not get your location.');
      });
    }
  }

  double? _parseDouble(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lat = _parseDouble(_latController.text);
    final lng = _parseDouble(_lngController.text);
    final radius = int.tryParse(_radiusController.text.trim());

    // Check everything on the phone first so mistakes show instantly.
    String? problem;
    if (name.isEmpty) {
      problem = 'Please enter a name.';
    } else if (lat == null || lat < -90 || lat > 90) {
      problem = 'Latitude must be a number between -90 and 90.';
    } else if (lng == null || lng < -180 || lng > 180) {
      problem = 'Longitude must be a number between -180 and 180.';
    } else if (radius == null || radius <= 0) {
      problem = 'Radius must be a whole number of meters, greater than 0.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final location = LocationModel(
        id: widget.existing?.id ?? 0,
        name: name,
        latitude: lat!,
        longitude: lng!,
        allowedRadiusMeters: radius!,
      );
      if (widget.existing != null) {
        await LocationApi.update(widget.existing!.id, location);
      } else {
        await LocationApi.create(location);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = apiErrorMessage(e, fallback: 'Could not save this location.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true, signed: true);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? 'Edit location' : 'New location',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name (e.g. Head Office)',
              controller: _nameController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Latitude',
                    controller: _latController,
                    keyboardType: numberKeyboard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Longitude',
                    controller: _lngController,
                    keyboardType: numberKeyboard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isLocating ? null : _useMyLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Use my current location'),
              ),
            ),
            const SizedBox(height: 4),
            AppTextField(
              label: 'Allowed radius (meters)',
              controller: _radiusController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            Text(
              'Employees must be within this distance to check in.',
              style: AppTextStyles.bodySoft,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.absent, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}