import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_errors.dart';
import '../absence_api.dart';

/// Mark a child absent (today, tomorrow or a date) and see / cancel
/// upcoming absences. The driver is told immediately for today.
class AbsenceSheet extends StatefulWidget {
  final String kidId;
  final String kidName;
  const AbsenceSheet({super.key, required this.kidId, required this.kidName});

  static Future<void> show(BuildContext context, {required String kidId, required String kidName}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AbsenceSheet(kidId: kidId, kidName: kidName),
    );
  }

  @override
  State<AbsenceSheet> createState() => _AbsenceSheetState();
}

class _AbsenceSheetState extends State<AbsenceSheet> {
  static const _navy = Color(0xFF1B3B69);

  DateTime _date = DateTime.now();
  String _tripType = 'both';
  final _note = TextEditingController();
  List<Absence> _upcoming = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AbsenceApi.list(widget.kidId);
      if (mounted) setState(() => _upcoming = list);
    } catch (_) {
      // list is optional; marking still works
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AbsenceApi.create(kidId: widget.kidId, date: _date, tripType: _tripType, note: _note.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.kidName} marked absent for ${DateFormat('EEE d MMM').format(_date)}. The driver has been told.'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e, fallback: 'Could not save. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel(Absence a) async {
    try {
      await AbsenceApi.cancel(a.id);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e, fallback: 'Could not cancel.'));
    }
  }

  String _tripLabel(String t) => t == 'pick' ? 'Morning pickup' : t == 'drop' ? 'Afternoon drop' : 'Whole day';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.kidName} won\'t ride',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _isSameDay(_date, today),
                    onSelected: (_) => setState(() => _date = today),
                  ),
                  ChoiceChip(
                    label: const Text('Tomorrow'),
                    selected: _isSameDay(_date, tomorrow),
                    onSelected: (_) => setState(() => _date = tomorrow),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 16),
                    label: Text(_isSameDay(_date, today) || _isSameDay(_date, tomorrow)
                        ? 'Other date'
                        : DateFormat('EEE d MMM').format(_date)),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'both', label: Text('Whole day')),
                  ButtonSegment(value: 'pick', label: Text('Pickup')),
                  ButtonSegment(value: 'drop', label: Text('Drop')),
                ],
                selected: {_tripType},
                onSelectionChanged: (s) => setState(() => _tripType = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Note for the driver (optional)',
                  hintText: 'e.g. Sick today',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFE53935))),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Mark absent'),
                ),
              ),
              if (_upcoming.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Upcoming absences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ..._upcoming.map((a) {
                  final d = DateTime.tryParse(a.date);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy, color: Color(0xFF8A94A6)),
                    title: Text(d == null ? a.date : DateFormat('EEE d MMM').format(d)),
                    subtitle: Text([_tripLabel(a.tripType), if (a.note != null) a.note!].join(' · ')),
                    trailing: TextButton(onPressed: () => _cancel(a), child: const Text('Cancel')),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
