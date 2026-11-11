import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'services/api_service.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({
    super.key,
    required this.endpoint,
    this.apiService,
  });

  final Uri endpoint;
  final ApiService? apiService;

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final ApiService _apiService = widget.apiService ?? ApiService();
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Vui lòng bật dịch vụ vị trí trên thiết bị.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showMessage('Ứng dụng chưa được cấp quyền truy cập vị trí.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage('Hãy bật quyền vị trí cho ứng dụng trong Cài đặt.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } on LocationServiceDisabledException {
      _showMessage('Vui lòng bật dịch vụ vị trí trên thiết bị.');
    } on PermissionDeniedException {
      _showMessage('Ứng dụng chưa được cấp quyền truy cập vị trí.');
    } catch (error, stackTrace) {
      debugPrint('Không thể lấy GPS: $error\n$stackTrace');
      _showMessage('Không thể lấy vị trí hiện tại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Vui lòng nhập mô tả sự cố.');
      return;
    }
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) {
      _showMessage('Vui lòng lấy vị trí hiện tại trước khi gửi.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _apiService.postJson(
        path: widget.endpoint.toString(),
        data: {
          'description': _descriptionController.text.trim(),
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (!mounted) return;
      _showMessage('Đã gửi báo cáo sự cố thành công.');
    } on DioException catch (error, stackTrace) {
      debugPrint(
        'Gửi báo cáo thất bại (HTTP ${error.response?.statusCode}): '
        '$error\n$stackTrace',
      );
      if (!mounted) return;
      _showMessage('Không thể gửi báo cáo. Vui lòng thử lại.');
    } catch (error, stackTrace) {
      debugPrint('Lỗi gửi báo cáo: $error\n$stackTrace');
      if (!mounted) return;
      _showMessage('Đã xảy ra lỗi khi gửi báo cáo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latitude = _latitude;
    final longitude = _longitude;
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo sự cố')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả sự cố',
                hintText: 'Nhập nội dung sự cố',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập mô tả sự cố'
                  : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _gettingLocation || _submitting ? null : _getLocation,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _gettingLocation ? 'Đang lấy vị trí...' : 'Lấy vị trí hiện tại',
              ),
            ),
            if (latitude != null && longitude != null) ...[
              const SizedBox(height: 8),
              Text('Vĩ độ: $latitude\nKinh độ: $longitude'),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting || _gettingLocation ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}
