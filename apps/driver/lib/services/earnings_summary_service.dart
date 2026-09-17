import 'api_client.dart';

class TripEarning {
  const TripEarning({
    required this.id,
    required this.date,
    required this.gross,
    required this.net,
    required this.deductions,
    required this.distance,
  });

  final String id;
  final DateTime date;
  final double gross;
  final double net;
  final double deductions;
  final int distance;

  factory TripEarning.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');
    if (parsedDate == null) {
      throw FormatException('Invalid trip date: $rawDate');
    }

    return TripEarning(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      gross: _toDouble(json['gross']),
      net: _toDouble(json['net']),
      deductions: _toDouble(json['deductions']),
      distance: _toInt(json['distance']),
    );
  }
}

class EarningsSummary {
  const EarningsSummary({
    required this.period,
    required this.driverId,
    required this.totalGross,
    required this.totalDeductions,
    required this.netEarnings,
    required this.tripCount,
    required this.brokerSavingsPercent,
    required this.trips,
  });

  final String period;
  final String driverId;
  final double totalGross;
  final double totalDeductions;
  final double netEarnings;
  final int tripCount;
  final int brokerSavingsPercent;
  final List<TripEarning> trips;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final rawTrips = json['trips'];
    if (rawTrips != null && rawTrips is! List) {
      throw const FormatException('Invalid earnings trips payload');
    }

    final trips = (rawTrips as List? ?? const [])
        .map((trip) {
          if (trip is! Map) {
            throw const FormatException('Invalid earnings trip item');
          }
          return TripEarning.fromJson(Map<String, dynamic>.from(trip));
        })
        .toList(growable: false);

    return EarningsSummary(
      period: json['period']?.toString() ?? 'monthly',
      driverId: json['driverId']?.toString() ?? '',
      totalGross: _toDouble(json['totalGross']),
      totalDeductions: _toDouble(json['totalDeductions']),
      netEarnings: _toDouble(json['netEarnings']),
      tripCount: _toInt(json['tripCount']),
      brokerSavingsPercent: _toInt(json['brokerSavingsPercent']),
      trips: trips,
    );
  }
}

class EarningsSummaryService {
  EarningsSummaryService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EarningsSummary> fetchSummary({required String period}) async {
    if (period != 'weekly' && period != 'monthly') {
      throw ArgumentError.value(period, 'period', 'Must be weekly or monthly');
    }

    final response = await _apiClient.get(
      '/api/earnings/summary?period=$period',
    );

    if (response is! Map) {
      throw const FormatException('Invalid earnings summary response');
    }

    final payload = Map<String, dynamic>.from(response);
    if (payload['success'] != true) {
      throw const FormatException('Earnings summary request was unsuccessful');
    }

    final data = payload['data'];
    if (data is! Map) {
      throw const FormatException('Missing earnings summary data');
    }

    return EarningsSummary.fromJson(Map<String, dynamic>.from(data));
  }

  void dispose() => _apiClient.close();
}

double _toDouble(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : 0;
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
