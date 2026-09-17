import 'package:flutter/material.dart';

import '../services/earnings_summary_service.dart';

class EarningsDashboard extends StatefulWidget {
  const EarningsDashboard({super.key, this.service});

  final EarningsSummaryService? service;

  @override
  State<EarningsDashboard> createState() => _EarningsDashboardState();
}

class _EarningsDashboardState extends State<EarningsDashboard> {
  late final EarningsSummaryService _service;
  String _selectedPeriod = 'monthly';
  EarningsSummary? _summary;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? EarningsSummaryService();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _service.fetchSummary(period: _selectedPeriod);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPeriod(String period) async {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    await _loadSummary();
  }

  @override
  void dispose() {
    if (widget.service == null) {
      _service.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_summary == null || _summary!.trips.isEmpty)
              _buildEmptyState()
            else
              _buildSummaryContent(_summary!),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['monthly', 'weekly'].map((period) {
        final selected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              period == 'monthly' ? 'This Month' : 'This Week',
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            selected: selected,
            selectedColor: const Color(0xFF16213E),
            onSelected: (_) => _selectPeriod(period),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryContent(EarningsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(
          gross: summary.totalGross,
          net: summary.netEarnings,
          deductions: summary.totalDeductions,
          tripCount: summary.tripCount,
        ),
        const SizedBox(height: 16),
        _BrokerSavingsCard(savingsPercent: summary.brokerSavingsPercent),
        const SizedBox(height: 16),
        const Text(
          'Trip Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...summary.trips.map((trip) => _TripCard(trip: trip)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black45),
          SizedBox(height: 12),
          Text(
            'No completed trips yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text('Completed trips for this period will appear here.'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.black45),
          const SizedBox(height: 12),
          const Text(
            'Could not load earnings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.gross,
    required this.net,
    required this.deductions,
    required this.tripCount,
  });

  final double gross;
  final double net;
  final double deductions;
  final int tripCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '₹${net.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const Text('Net Earnings', style: TextStyle(color: Colors.white70)),
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Gross',
                  value: '₹${gross.toStringAsFixed(0)}',
                  color: Colors.white,
                ),
                _StatItem(
                  label: 'Deductions',
                  value: '₹${deductions.toStringAsFixed(0)}',
                  color: Colors.redAccent,
                ),
                _StatItem(
                  label: 'Trips',
                  value: '$tripCount',
                  color: Colors.lightBlueAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _BrokerSavingsCard extends StatelessWidget {
  const _BrokerSavingsCard({required this.savingsPercent});

  final int savingsPercent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F3460),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined, color: Colors.greenAccent, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You saved $savingsPercent% vs broker commission this period!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TripEarning trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF16213E),
          child: Text(
            '${trip.distance}km',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        title: Text(
          '₹${trip.net.toStringAsFixed(0)} net',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Gross ₹${trip.gross.toStringAsFixed(0)} · Deductions ₹${trip.deductions.toStringAsFixed(0)}\n'
          '${_formatDate(trip.date)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
