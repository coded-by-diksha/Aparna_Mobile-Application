import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/cycle_service.dart';

class CyclePredictionScreen extends StatefulWidget {
  const CyclePredictionScreen({super.key});

  @override
  State<CyclePredictionScreen> createState() => _CyclePredictionScreenState();
}

class _CyclePredictionScreenState extends State<CyclePredictionScreen> {
  final CycleService _cycleService = CycleService();
  bool _isLoading = true;
  List<dynamic> _history = [];
  Map<String, dynamic>? _predictionData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final history = await _cycleService.fetchHistory();
      // Only fetch prediction if user has cycles
      Map<String, dynamic>? prediction;
      if (history.isNotEmpty) {
        prediction = await _cycleService.fetchPrediction();
      }
      if (mounted) {
        setState(() {
          _history = history;
          _predictionData = prediction;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addPeriod() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade300,
              onPrimary: Colors.white,
              onSurface: Colors.pink.shade900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final moodData = await _showMoodDialog();
      if (moodData != null) {
        final days = moodData['mensesLength'] as int? ?? 5;
        final success = await _cycleService.recordPeriod(
          startDate: picked.toIso8601String().split('T')[0],
          mensesLength: days,
          moodScore: moodData['score'],
          emotions: moodData['emotions'],
        );
        if (success) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Period and mood recorded!'), backgroundColor: Colors.green),
            );
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showMoodDialog() async {
    int selectedScore = 3;
    int periodDays = 5;
    final List<String> emotions = ['Cramps', 'Headache', 'Mood Swings', 'Fatigue', 'Bloating', 'Acne'];
    final List<String> selectedEmotions = [];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('How are you feeling today?', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How many days does your period last?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Days:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: periodDays.clamp(1, 10),
                      items: List.generate(10, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d'))).toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => periodDays = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Mood (1=Sad, 5=Happy)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Slider(
                  value: selectedScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.pink,
                  label: selectedScore.toString(),
                  onChanged: (value) => setDialogState(() => selectedScore = value.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('😫'), const Text('😐'), const Text('😊')],
                ),
                const SizedBox(height: 20),
                const Text('Select up to 3 Emotions/Symptoms:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: emotions.map((emotion) {
                    final isSelected = selectedEmotions.contains(emotion);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(emotion),
                      selectedColor: Colors.pink.shade100,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            if (selectedEmotions.length < 3) selectedEmotions.add(emotion);
                          } else {
                            selectedEmotions.remove(emotion);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
              onPressed: () => Navigator.pop(context, {'score': selectedScore, 'emotions': selectedEmotions, 'mensesLength': periodDays}),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cycle & Health Analysis', style: TextStyle(color: Color.fromARGB(255, 224, 92, 92), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show prediction if user has cycles
                    if (_history.isNotEmpty) ...[
                      _buildPredictionCard(),
                      const SizedBox(height: 12),
                      _buildAIStatusBadge(),
                      const SizedBox(height: 20),
                      _buildAnalysisSection(),
                      const SizedBox(height: 20),
                    ] else ...[
                      _buildNoCyclesMessage(),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      'Past Cycles',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF880E4F)),
                    ),
                    const SizedBox(height: 10),
                    _buildHistoryList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPeriod,
        backgroundColor: Colors.pink.shade300,
        label: const Text('Log Period', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAIStatusBadge() {
    final status = _predictionData?['status'] ?? 'generic';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              status == 'smart_prediction' ? 'Smart Prediction Active (RandomForest)' : 'Personalized Analysis',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCyclesMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade300, Colors.pink.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Start Tracking Your Cycle',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log your first period to get personalized predictions and insights',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    final predictions = _predictionData?['predictedDates'] as List?;
    final status = _predictionData?['status'] as String?;
    final nextDate = predictions != null && predictions.isNotEmpty ? predictions[0]['date'] : null;
    final parsedNextDate = nextDate != null ? DateTime.tryParse(nextDate) : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Determine display text based on status
    String titleText = 'Expected Next Period';
    String mainText = 'Log a period to start';
    String subtitleText = 'Optimized by FYP Dataset Model';
    
    if (parsedNextDate != null) {
      final predDateOnly = DateTime(parsedNextDate.year, parsedNextDate.month, parsedNextDate.day);
      
      if (status == 'pending_verification') {
        // Show dynamic message during day-by-day shifting
        titleText = 'Verifying Prediction';
        mainText = 'Your period may start today or tomorrow';
        if (predDateOnly.isAfter(tomorrow)) {
          mainText = 'Your period may start ${DateFormat('MMM dd').format(predDateOnly)}';
        }
        subtitleText = 'Log your period when it starts';
      } else if (predDateOnly.isBefore(today)) {
        // Fallback: show tomorrow
        mainText = DateFormat('MMMM dd, yyyy').format(tomorrow);
        subtitleText = 'Optimized by FYP Dataset Model';
      } else {
        mainText = DateFormat('MMMM dd, yyyy').format(parsedNextDate);
        subtitleText = 'Optimized by FYP Dataset Model';
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade300, Colors.pink.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                titleText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                mainText,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (nextDate != null)
                Text(
                  subtitleText,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection() {
    final analysis = _predictionData?['analysis'] as Map<String, dynamic>?;
    if (analysis == null) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.pink),
                SizedBox(width: 10),
                Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildAnalysisRow('Average Cycle Length', '${analysis['userAverageCycle']} days', '${analysis['globalAverageCycle']} days'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Regularity:', style: TextStyle(color: Colors.grey)),
                Text(
                  analysis['regularityScore'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: analysis['regularityScore'] == 'Irregular' ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String userValue, String globalValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(userValue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                ],
              ),
            ),
            const Icon(Icons.compare_arrows, size: 16, color: Colors.grey),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Global Benchmark', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(globalValue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text('No history yet.', style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final cycle = _history[index];
        final startDate = DateTime.parse(cycle['period_start_date']);
        final mood = cycle['mood_score'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink.shade50,
              child: Text(mood != null ? _getMoodEmoji(mood) : '🩸'),
            ),
            title: Text(DateFormat('MMM dd, yyyy').format(startDate), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Cycle: ${cycle['cycle_length'] ?? "--"} days • Mood: ${mood ?? "--"}/5'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _confirmDelete(cycle['id']),
            ),
          ),
        );
      },
    );
  }

  String _getMoodEmoji(int score) {
    if (score == 1) return '😫';
    if (score == 2) return '😟';
    if (score == 3) return '😐';
    if (score == 4) return '😊';
    return '😁';
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      if (await _cycleService.deletePeriod(id)) _loadData();
    }
  }
}
