import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';

class FuelReceiptScreen extends StatefulWidget {
  const FuelReceiptScreen({super.key, required this.endpoint, this.httpClient});

  final Uri endpoint;
  final http.Client? httpClient;

  @override
  State<FuelReceiptScreen> createState() => _FuelReceiptScreenState();
}

class _FuelReceiptScreenState extends State<FuelReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _amountController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _receiptImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _litersController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập thông tin này';
    final number = double.tryParse(text);
    if (number == null || !number.isFinite || number < 0) {
      return 'Vui lòng nhập số không âm hợp lệ';
    }
    return null;
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      setState(() => _receiptImage = image);
    } catch (error, stackTrace) {
      debugPrint('Không thể chụp ảnh hóa đơn: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở camera. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final client = widget.httpClient ?? http.Client();
    final closeClient = widget.httpClient == null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(ApiService.tokenKey);
      final request = http.MultipartRequest('POST', widget.endpoint)
        ..fields['liters'] = _litersController.text.trim()
        ..fields['amount'] = _amountController.text.trim();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final image = _receiptImage;
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('receipt', image.path),
        );
      }

      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Fuel API returned HTTP ${response.statusCode}',
          uri: widget.endpoint,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi phiếu nhiên liệu.')));
    } catch (error, stackTrace) {
      debugPrint('Gửi phiếu nhiên liệu thất bại: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi phiếu. Vui lòng thử lại.')),
      );
    } finally {
      if (closeClient) client.close();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu nhiên liệu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _litersController,
              decoration: const InputDecoration(
                labelText: 'Số lít đổ',
                suffixText: 'lít',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                suffixText: '₫',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Chụp ảnh hóa đơn'),
            ),
            if (_receiptImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_receiptImage!.path),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gửi phiếu'),
            ),
          ],
        ),
      ),
    );
  }
}
