import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/di/dependency_injection.dart';
import '../bloc/cycle_history/cycle_history_bloc.dart';
import '../bloc/cycle_history/cycle_history_event.dart';
import '../bloc/cycle_history/cycle_history_state.dart';

class CycleHistoryScreen extends StatelessWidget {
  const CycleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DependencyInjection.createCycleHistoryBloc()..add(LoadCycleHistory()),
      child: const _CycleHistoryView(),
    );
  }
}

class _CycleHistoryView extends StatelessWidget {
  const _CycleHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.pink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cycle History',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocListener<CycleHistoryBloc, CycleHistoryState>(
        listener: (context, state) {
          if (state is CycleHistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CycleHistoryBloc, CycleHistoryState>(
          buildWhen: (previous, current) =>
              current is CycleHistoryLoading ||
              current is CycleHistoryLoaded ||
              current is CycleHistoryError ||
              current is CycleHistoryInitial,
          builder: (context, state) {
            if (state is CycleHistoryLoading || state is CycleHistoryInitial) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.pink));
            }
            if (state is CycleHistoryLoaded) {
              if (state.history.isEmpty) {
                return const Center(child: Text('No cycles recorded yet.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CycleHistoryBloc>().add(LoadCycleHistory());
                },
                color: Colors.pink,
                child: CycleHistoryTimeline(history: state.history),
              );
            }
            if (state is CycleHistoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () =>
                          context.read<CycleHistoryBloc>().add(LoadCycleHistory()),
                      icon: const Icon(Icons.refresh, color: Colors.pink),
                      label: const Text('Retry', style: TextStyle(color: Colors.pink)),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class CycleHistoryTimeline extends StatelessWidget {
  final List<dynamic> history;

  const CycleHistoryTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final cycle = history[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineIndicator(
                  context, index == 0, index == history.length - 1),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: CycleHistoryCard(cycle: cycle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIndicator(
      BuildContext context, bool isFirst, bool isLast) {
    return Column(
      children: [
        Container(
          width: 2,
          height: 10,
          color: isFirst ? Colors.transparent : Colors.grey.shade200,
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.pink.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: 2,
            color: isLast ? Colors.transparent : Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class CycleHistoryCard extends StatelessWidget {
  final dynamic cycle;

  const CycleHistoryCard({super.key, required this.cycle});

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.parse(cycle['period_start_date'].toString());
    final mensesLength = _toInt(cycle['menses_length']) ?? 3;
    final moodScore = _toInt(cycle['mood_score']);
    final flowLevel = _toInt(cycle['flow_level']);
    final emotions = (cycle['emotions'] as List<dynamic>?) ?? [];

    final fullDate = _formatFullDate(startDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fullDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (moodScore != null)
                Text(_getMoodEmoji(moodScore),
                    style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateRange(startDate, mensesLength),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Flow: ',
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              Text(
                _getFlowLabel(flowLevel, mensesLength),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDayStrip(flowLevel ?? _inferFlowFromDays(mensesLength)),
          const SizedBox(height: 16),
          if (emotions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  emotions.map((e) => _buildSymptomChip(e.toString())).toList(),
            ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final monthYear = DateFormat('MMMM yyyy').format(date);
    return '${_ordinal(date.day)} $monthYear';
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _formatDateRange(DateTime startDate, int mensesLength) {
    final endDate = startDate.add(Duration(days: mensesLength - 1));
    final startStr = _formatFullDate(startDate);
    final endStr = _formatFullDate(endDate);
    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      return '${_ordinal(startDate.day)} – ${_ordinal(endDate.day)} ${DateFormat('MMMM yyyy').format(startDate)}';
    }
    return '$startStr – $endStr';
  }

  Widget _buildDayStrip(int flowLevel) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = index < flowLevel;
        return Expanded(
          child: Container(
            height: 12,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.pink.shade200 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSymptomChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.pink.shade300,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _getMoodEmoji(int score) {
    const emojis = ['😫', '😟', '😐', '😊', '😁'];
    if (score < 1) return emojis[0];
    if (score > 5) return emojis[4];
    return emojis[score - 1];
  }

  static String _getFlowLabel(int? flowLevel, int days) {
    if (flowLevel != null) {
      if (flowLevel <= 2) return 'Light';
      if (flowLevel <= 4) return 'Medium';
      return 'Heavy';
    }
    if (days <= 3) return 'Light';
    if (days <= 5) return 'Medium';
    return 'Heavy';
  }

  static int _inferFlowFromDays(int days) {
    if (days <= 3) return 2;
    if (days <= 5) return 4;
    return 5;
  }
}
