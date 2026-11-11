import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.tripId,
    this.vehiclePlate,
    this.destination,
    this.pickupTime,
  });

  final String tripId;
  final String? vehiclePlate;
  final String? destination;
  final String? pickupTime;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _startFormKey = GlobalKey<FormState>();
  final _endFormKey = GlobalKey<FormState>();
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  double? _startedAtKm;
  bool _isFinished = false;

  @override
  void dispose() {
    _startKmController.dispose();
    _endKmController.dispose();
    super.dispose();
  }

  String? _validateKilometers(String? value) {
    final km = double.tryParse(value?.trim() ?? '');
    if (km == null || !km.isFinite || km < 0) {
      return 'Vui lòng nhập số km hợp lệ';
    }
    return null;
  }

  void _startTrip() {
    if (!_startFormKey.currentState!.validate()) return;
    setState(() => _startedAtKm = double.parse(_startKmController.text.trim()));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã bắt đầu chuyến đi.')));
  }

  void _finishTrip() {
    if (!_endFormKey.currentState!.validate()) return;
    final startKm = _startedAtKm;
    if (startKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số KM đầu và bắt đầu chuyến.'),
        ),
      );
      return;
    }

    final endKm = double.parse(_endKmController.text.trim());
    if (endKm <= startKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số KM cuối chuyến phải lớn hơn số KM đầu chuyến.'),
        ),
      );
      return;
    }

    setState(() => _isFinished = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã kết thúc chuyến đi.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chuyến đi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID chuyến đi: ${widget.tripId}'),
                  if (widget.vehiclePlate != null)
                    Text('Biển số xe: ${widget.vehiclePlate}'),
                  if (widget.destination != null)
                    Text('Điểm đến: ${widget.destination}'),
                  if (widget.pickupTime != null)
                    Text('Giờ nhận: ${widget.pickupTime}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _startFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _startKmController,
                  enabled: _startedAtKm == null,
                  decoration: const InputDecoration(
                    labelText: 'Số KM đầu chuyến',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validateKilometers,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _startedAtKm == null ? _startTrip : null,
                  child: Text(
                    _startedAtKm == null ? 'Bắt đầu chuyến' : 'Đã bắt đầu',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _endFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _endKmController,
                  enabled: !_isFinished,
                  decoration: const InputDecoration(
                    labelText: 'Số KM cuối chuyến',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validateKilometers,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isFinished ? null : _finishTrip,
                  child: Text(_isFinished ? 'Đã kết thúc' : 'Kết thúc chuyến'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
