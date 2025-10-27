import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/features/background_sync/presentation/providers/background_sync_provider.dart';
import 'package:kpass/core/constants/app_dimensions.dart';
import 'package:kpass/shared/widgets/loading_widget.dart';
import 'package:kpass/shared/widgets/error_widget.dart';

class BackgroundSyncSettingsScreen extends StatefulWidget {
  const BackgroundSyncSettingsScreen({super.key});

  @override
  State<BackgroundSyncSettingsScreen> createState() => _BackgroundSyncSettingsScreenState();
}

class _BackgroundSyncSettingsScreenState extends State<BackgroundSyncSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackgroundSyncProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Sync Settings'),
        elevation: 0,
      ),
      body: Consumer<BackgroundSyncProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Loading sync settings...');
          }

          if (provider.error != null) {
            return ErrorDisplayWidget(
              error: provider.error!,
              onRetry: () => provider.initialize(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSyncStatusCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildSyncSettingsCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildSyncIntervalCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildBatteryOptimizationCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildSyncActionsCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildAdvancedSettingsCard(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ListTile(
              leading: Icon(
                provider.isEnabled ? Icons.sync : Icons.sync_disabled,
                color: provider.isEnabled ? Colors.green : Colors.grey,
              ),
              title: Text(
                provider.isEnabled ? 'Background Sync Enabled' : 'Background Sync Disabled',
              ),
              subtitle: Text(
                provider.isEnabled
                    ? 'Automatically syncing every ${provider.getSyncIntervalText(provider.syncInterval)}'
                    : 'Enable to automatically sync assignments in the background',
              ),
            ),
            if (provider.lastSync != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last Sync'),
                subtitle: FutureBuilder<String?>(
                  future: provider.getTimeSinceLastSyncText(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(snapshot.data!);
                    }
                    return const Text('Unknown');
                  },
                ),
              ),
            ],
            if (!provider.isBackgroundSyncSupported) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Limited Support'),
                subtitle: const Text(
                  'Background sync may be limited on this device or platform',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            SwitchListTile(
              title: const Text('Enable Background Sync'),
              subtitle: const Text(
                'Automatically check for new assignments and updates',
              ),
              value: provider.isEnabled,
              onChanged: (value) async {
                if (value) {
                  await provider.enableBackgroundSync();
                } else {
                  await provider.disableBackgroundSync();
                }
              },
            ),
            if (provider.isEnabled) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.network_check),
                title: const Text('Network Connectivity'),
                subtitle: const Text('Requires internet connection for sync'),
                trailing: FutureBuilder<bool>(
                  future: provider.checkNetworkConnectivity(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Icon(
                        snapshot.data! ? Icons.check_circle : Icons.error,
                        color: snapshot.data! ? Colors.green : Colors.red,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIntervalCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            Text(
              'Choose how often to check for new assignments',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppDimensions.defaultPadding),
            ...provider.availableSyncIntervals.map((interval) {
              return RadioListTile<Duration>(
                title: Text(provider.getSyncIntervalText(interval)),
                subtitle: _getSyncIntervalDescription(interval),
                value: interval,
                groupValue: provider.syncInterval,
                onChanged: provider.isEnabled
                    ? (value) => provider.updateSyncInterval(value!)
                    : null,
              );
            }),
            if (!provider.isEnabled)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.smallPadding),
                child: Text(
                  'Enable background sync to configure frequency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _getSyncIntervalDescription(Duration interval) {
    String description;
    if (interval.inMinutes <= 30) {
      description = 'High frequency - may impact battery life';
    } else if (interval.inHours <= 1) {
      description = 'Recommended - balanced performance and battery';
    } else if (interval.inHours <= 6) {
      description = 'Moderate frequency - good battery life';
    } else {
      description = 'Low frequency - best battery life';
    }
    
    return Text(description);
  }

  Widget _buildBatteryOptimizationCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battery Optimization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ListTile(
              leading: Icon(
                provider.batteryOptimizationDisabled 
                    ? Icons.battery_full 
                    : Icons.battery_alert,
                color: provider.batteryOptimizationDisabled 
                    ? Colors.green 
                    : Colors.orange,
              ),
              title: Text(
                provider.batteryOptimizationDisabled
                    ? 'Battery Optimization Disabled'
                    : 'Battery Optimization Enabled',
              ),
              subtitle: Text(
                provider.batteryOptimizationDisabled
                    ? 'Background sync will work reliably'
                    : 'May prevent background sync from working',
              ),
            ),
            if (!provider.batteryOptimizationDisabled) ...[
              const SizedBox(height: AppDimensions.smallPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
                child: Text(
                  provider.getBatteryOptimizationGuidance(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppDimensions.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBatteryOptimizationDialog(context, provider),
                      child: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallPadding),
                  Expanded(
                    child: TextButton(
                      onPressed: () => provider.markBatteryOptimizationDisabled(),
                      child: const Text('Mark as Done'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActionsCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isEnabled
                        ? () => provider.performImmediateSync()
                        : null,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
                const SizedBox(width: AppDimensions.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.refreshStatus(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            FutureBuilder<bool>(
              future: provider.shouldPerformSync(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListTile(
                    leading: Icon(
                      snapshot.data! ? Icons.schedule : Icons.check_circle,
                      color: snapshot.data! ? Colors.orange : Colors.green,
                    ),
                    title: Text(
                      snapshot.data! ? 'Sync Needed' : 'Up to Date',
                    ),
                    subtitle: Text(
                      snapshot.data!
                          ? 'It\'s time for the next scheduled sync'
                          : 'Next sync will occur automatically',
                    ),
                  );
                }
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Checking sync status...'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsCard(BuildContext context, BackgroundSyncProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sync Status Details'),
              subtitle: const Text('View detailed sync information'),
              onTap: () => _showSyncStatusDialog(context, provider),
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: const Text('Recommended Settings'),
              subtitle: Text(
                'Use ${provider.getSyncIntervalText(provider.getRecommendedSyncInterval())} interval',
              ),
              onTap: () => provider.updateSyncInterval(provider.getRecommendedSyncInterval()),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Troubleshooting'),
              subtitle: const Text('Common issues and solutions'),
              onTap: () => _showTroubleshootingDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatteryOptimizationDialog(BuildContext context, BackgroundSyncProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battery Optimization'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.getBatteryOptimizationGuidance()),
              const SizedBox(height: 16),
              const Text(
                'Steps to disable battery optimization:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Open device Settings'),
              const Text('2. Go to Battery or Power Management'),
              const Text('3. Find Battery Optimization or App Power Management'),
              const Text('4. Find KPass in the list'),
              const Text('5. Select "Don\'t optimize" or "No restrictions"'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.markBatteryOptimizationDisabled();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSyncStatusDialog(BuildContext context, BackgroundSyncProvider provider) {
    final status = provider.getSyncStatusSummary();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow('Enabled', status['is_enabled'].toString()),
              _buildStatusRow('Sync Interval', status['sync_interval']),
              _buildStatusRow('Last Sync', status['last_sync'] ?? 'Never'),
              _buildStatusRow('Battery Optimization', 
                  status['battery_optimization_disabled'] ? 'Disabled' : 'Enabled'),
              _buildStatusRow('Platform', status['platform'] ?? 'Unknown'),
              if (status['has_error'])
                _buildStatusRow('Error', status['error'], isError: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Common Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Background sync not working'),
              Text('  - Check battery optimization settings'),
              Text('  - Ensure network connectivity'),
              Text('  - Verify sync is enabled'),
              SizedBox(height: 12),
              Text('• Sync taking too long'),
              Text('  - Check internet connection speed'),
              Text('  - Try immediate sync to test'),
              SizedBox(height: 12),
              Text('• Battery drain'),
              Text('  - Increase sync interval'),
              Text('  - Use recommended settings'),
              SizedBox(height: 12),
              Text('• Notifications not appearing'),
              Text('  - Check notification permissions'),
              Text('  - Verify notification settings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}