import 'package:flutter/material.dart';

import 'fuel_receipt_screen.dart';
import 'incident_report_screen.dart';
import 'services/api_service.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService _apiService;
  late Future<List<AssignedTrip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _tripsFuture = _loadTrips();
  }

  Future<List<AssignedTrip>> _loadTrips() async {
    final response = await _apiService.getList(path: '/trips/assigned');
    final payload = response.data;
    final dynamic rawTrips;
    if (payload is List) {
      rawTrips = payload;
    } else if (payload is Map) {
      rawTrips = payload['data'] ?? payload['trips'];
    } else {
      rawTrips = null;
    }

    if (rawTrips is! List) {
      throw const FormatException(
        'Expected a list or an object containing data/trips.',
      );
    }

    return rawTrips.map((item) {
      if (item is! Map) {
        throw const FormatException('Trip record must be an object.');
      }
      return AssignedTrip.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  void _retry() {
    setState(() => _tripsFuture = _loadTrips());
  }

  Future<void> _openFuelReceipt() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FuelReceiptScreen(
          endpoint: Uri.parse('${ApiConfig.baseUrl}fuel-receipts'),
        ),
      ),
    );
  }

  Future<void> _openIncidentReport() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IncidentReportScreen(
          endpoint: Uri.parse('${ApiConfig.baseUrl}incidents'),
          apiService: _apiService,
        ),
      ),
    );
  }

  void _openTrip(AssignedTrip trip) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(
          tripId: trip.id,
          vehiclePlate: trip.vehiclePlate,
          destination: trip.destination,
          pickupTime: trip.pickupTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến đi được phân công'),
        actions: [
          IconButton(
            tooltip: 'Phiếu nhiên liệu',
            onPressed: _openFuelReceipt,
            icon: const Icon(Icons.local_gas_station_outlined),
          ),
          IconButton(
            tooltip: 'Báo cáo sự cố',
            onPressed: _openIncidentReport,
            icon: const Icon(Icons.warning_amber_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<AssignedTrip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải danh sách chuyến đi.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final trips = snapshot.data!;
          if (trips.isEmpty) {
            return const Center(
              child: Text('Chưa có chuyến đi nào được phân công.'),
            );
          }
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(trip.vehiclePlate),
                subtitle: Text(
                  'Điểm đến: ${trip.destination}\nGiờ nhận: ${trip.pickupTime}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTrip(trip),
              );
            },
          );
        },
      ),
    );
  }
}

class AssignedTrip {
  const AssignedTrip({
    required this.id,
    required this.vehiclePlate,
    required this.destination,
    required this.pickupTime,
  });

  final String id;
  final String vehiclePlate;
  final String destination;
  final String pickupTime;

  factory AssignedTrip.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final vehiclePlate = json['vehicle_plate'] ?? json['vehiclePlate'];
    final destination = json['destination'];
    final pickupTime = json['pickup_time'] ?? json['pickupTime'];
    if (id == null ||
        vehiclePlate == null ||
        destination == null ||
        pickupTime == null) {
      throw const FormatException(
        'Trip requires id, vehicle_plate, destination and pickup_time.',
      );
    }
    return AssignedTrip(
      id: id.toString(),
      vehiclePlate: vehiclePlate.toString(),
      destination: destination.toString(),
      pickupTime: pickupTime.toString(),
    );
  }
}
