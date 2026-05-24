import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart';
import '../../core/di/dependency_injection.dart';
import '../../data/models/health_model.dart';
import '../bloc/health_dashboard/health_dashboard_bloc.dart';
import '../bloc/health_dashboard/health_dashboard_event.dart';
import '../bloc/health_dashboard/health_dashboard_state.dart';
// import '../widgets/section_title.dart';
// import '../widgets/metric_card.dart';
import '../widgets/connect_device_card.dart';
import 'package:aparna/l10n/app_localizations.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HealthDashboardBloc(),
      child: const _HealthDashboardView(),
    );
  }
}

class _HealthDashboardView extends StatefulWidget {
  const _HealthDashboardView();

  @override
  State<_HealthDashboardView> createState() => _HealthDashboardViewState();
}

class _HealthDashboardViewState extends State<_HealthDashboardView> {
  bool _didLoadInitial = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_didLoadInitial) {
      _didLoadInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HealthDashboardBloc>().add(LoadHealthData());
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthDashboard),
        // making the title text color to primary color
        foregroundColor: AppTheme.primaryColor,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryColor),
        elevation: 0,
      ),
      body: BlocConsumer<HealthDashboardBloc, HealthDashboardState>(
        listener: (context, state) {
          if (state is HealthDashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state is HealthDashboardScanning) {
            return const _ScanningUI();
          }
          if (state is HealthDashboardNoDevicesFound) {
            return const _NoDevicesFoundUI();
          }
          if (state is HealthDashboardDeviceList) {
            return _DeviceListUI(devices: state.devices);
          }
          if (state is HealthDashboardConnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.connecting),
                ],
              ),
            );
          }
          if (state is HealthDashboardNotConnected || state is HealthDashboardError) {
            return _ConnectUI(
              isError: state is HealthDashboardError,
              onConnect: () =>
                  context.read<HealthDashboardBloc>().add(ConnectDevice()),
            );
          }
          if (state is HealthDashboardConnected) {
            return _ConnectedUI(healthData: state.healthData);
          }
          return _ConnectUI(
            onConnect: () =>
                context.read<HealthDashboardBloc>().add(ConnectDevice()),
          );
        },
      ),
    );
  }
}

class _ConnectUI extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isError;

  const _ConnectUI({required this.onConnect, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.watch,
              size: 80,
              color: isError ? Colors.red.shade300 : AppTheme.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.connectYourWearable,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.syncHealthData,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.connectDevice,
              style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningUI extends StatelessWidget {
  const _ScanningUI();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Scanning for devices...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your device is nearby and Bluetooth is enabled',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeviceListUI extends StatelessWidget {
  final List<WearableDevice> devices;

  const _DeviceListUI({required this.devices});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Select your device',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on your wearable device to connect',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getDeviceIcon(device.icon),
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        device.type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                    onTap: () {
                      context.read<HealthDashboardBloc>().add(
                            SelectDevice(device),
                          );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String icon) {
    switch (icon) {
      case 'watch':
        return Icons.watch;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.devices;
    }
  }
}

class _NoDevicesFoundUI extends StatelessWidget {
  const _NoDevicesFoundUI();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noDevicesFound,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noDevicesFoundMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<HealthDashboardBloc>().add(ConnectDevice());
                },
                icon: const Icon(Icons.refresh,
                color: Colors.white,
                ),
                label: Text(l10n.scanAgain,
                style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedUI extends StatefulWidget {
  final HealthModel healthData;

  const _ConnectedUI({required this.healthData});

  @override
  State<_ConnectedUI> createState() => _ConnectedUIState();
}

class _ConnectedUIState extends State<_ConnectedUI> {
  void _showWaterLogSheet() {
    int glasses = 0;
    int bottles = 0;
    int largeBottles = 0;
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            int totalMl = glasses * 250 + bottles * 500 + largeBottles * 750;
            final customText = customController.text.trim();
            if (customText.isNotEmpty) {
              totalMl += int.tryParse(customText) ?? 0;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log water',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: totalMl > 0
                            ? () => _saveWaterLog(ctx, totalMl)
                            : null,
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: totalMl > 0
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _waterOption('Glass', '250 ml', glasses,
                      (v) => setSheetState(() => glasses = v)),
                  const SizedBox(height: 12),
                  _waterOption('Bottle', '500 ml', bottles,
                      (v) => setSheetState(() => bottles = v)),
                  const SizedBox(height: 12),
                  _waterOption('Large bottle', '750 ml', largeBottles,
                      (v) => setSheetState(() => largeBottles = v)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Custom amount (ml)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (totalMl > 0) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Total: $totalMl ml',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _waterOption(
      String label, String subtitle, int count, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        Text('$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        _counterButton(
            Icons.remove, count > 0 ? () => onChanged(count - 1) : null),
        const SizedBox(width: 6),
        _counterButton(Icons.add, () => onChanged(count + 1)),
      ],
    );
  }

  Widget _counterButton(IconData icon, VoidCallback? onPressed) {
    return SizedBox(
      width: 38,
      height: 38,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              onPressed != null ? AppTheme.primaryColor : Colors.grey[300],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _saveWaterLog(BuildContext ctx, int totalMl) async {
    Navigator.pop(ctx);
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    final success =
        await DependencyInjection.healthService.logWaterIntake(totalMl, userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Logged $totalMl ml of water'
                : 'Could not save water — please try again',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        context.read<HealthDashboardBloc>().add(LoadHealthData());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.healthData;
    final h = d.healthDataHistory;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HealthDashboardBloc>().add(LoadHealthData());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConnectDeviceCard(
            deviceName: d.deviceName,
            deviceType: d.deviceType,
            lastUpdated: d.lastUpdated,
          ),
          if (d.heartRate == 0 || d.activityRecognition.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pull down to sync. Heart rate & activity sync when wearing device.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          
          // ═══ VITALS ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              l10n.vitals,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          _buildMetricGrid([
            _buildMetricBox(l10n.heartRate, d.heartRate > 0 ? '${d.heartRate}' : '—', 'bpm', Icons.favorite),
            _buildMetricBox(l10n.intensity, d.activityIntensity.isNotEmpty ? d.activityIntensity : '—', '', Icons.flash_on),
          ]),
          
          const SizedBox(height: 16),
          
          // ═══ ACTIVITY ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              l10n.activity,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          _buildMetricGrid([
            _buildMetricBox(l10n.steps, '${h.steps}', 'steps', Icons.directions_walk),
            _buildMetricBox(l10n.calories, '${h.calories}', 'kcal', Icons.local_fire_department),
            _buildMetricBox(l10n.distance, _formatDistance(h.distance), '', Icons.map),
            _buildMetricBox(l10n.activityType, d.activityRecognition.isNotEmpty ? d.activityRecognition : '—', '', Icons.sports_soccer),
          ]),
          
          const SizedBox(height: 16),
          
          // ═══ WELLNESS ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              l10n.wellness,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          _buildSleepCard(l10n, h.sleepHours),
          const SizedBox(height: 10),
          _buildWaterCard(l10n, h.waterIntake),
          
          const SizedBox(height: 16),
          
          // ═══ LOCATION ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              'Location',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          _buildMetricBox(l10n.lastKnownLocation, d.location.isNotEmpty ? d.location : 'Unknown', '', Icons.location_on),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(List<Widget> items) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: items,
    );
  }

  Widget _buildMetricBox(String label, String value, String unit, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: Colors.grey.shade400),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSleepHours(double hours) {
    if (hours <= 0) return '—';
    if (hours < 1) return '${(hours * 60).round()} min';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatDistance(double km) {
    if (km <= 0) return '0 km';
    return '${km.toStringAsFixed(1)} km';
  }

  Widget _buildSleepCard(AppLocalizations l10n, double sleepHours) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.nights_stay, color: Colors.indigo.shade400, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.sleep,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatSleepHours(sleepHours),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (sleepHours <= 0)
                        Text(
                          'Tap Log to add',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showSleepLogSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepLogSheet() {
    double hours = 7.0;
    int minutes = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final totalHours = hours + (minutes / 60.0);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log sleep',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: totalHours > 0
                            ? () => _saveSleepLog(ctx, totalHours)
                            : null,
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: totalHours > 0
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Sleep Duration',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hours',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '${hours.toInt()}',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                setSheetState(() {
                                  hours = double.tryParse(val) ?? 7.0;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Minutes',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '$minutes',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                setSheetState(() {
                                  minutes = int.tryParse(val) ?? 0;
                                  if (minutes > 59) minutes = 59;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${totalHours.toStringAsFixed(1)} hours',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSleepLog(BuildContext ctx, double totalHours) async {
    Navigator.pop(ctx);
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    final success = await DependencyInjection.healthService
        .logSleepHours(totalHours, userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Logged ${totalHours.toStringAsFixed(1)} hours of sleep'
                : 'Could not save sleep — please try again',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        context.read<HealthDashboardBloc>().add(LoadHealthData());
      }
    }
  }

  Widget _buildWaterCard(AppLocalizations l10n, int waterMl) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue.shade400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.waterIntake,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    '$waterMl ml',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (waterMl == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap Log to add water — most wearables don\'t sync water',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _showWaterLogSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
