import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/features/background_sync/presentation/providers/sync_frequency_provider.dart';
import 'package:kpass/features/background_sync/domain/services/sync_frequency_manager.dart';
import 'package:kpass/core/constants/app_dimensions.dart';
import 'package:kpass/shared/widgets/loading_widget.dart';
import 'package:kpass/shared/widgets/error_widget.dart';

class SyncFrequencySettingsScreen extends StatefulWidget {
  const SyncFrequencySettingsScreen({super.key});

  @override
  State<SyncFrequencySettingsScreen> createState() => _SyncFrequencySettingsScreenState();
}

class _SyncFrequencySettingsScreenState extends State<SyncFrequencySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncFrequencyProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Frequency Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SyncFrequencyProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<SyncFrequencyProvider>(
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
                _buildCurrentStatusCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildFrequencySettingsCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildAdaptiveSettingsCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildRecommendationCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildStatisticsCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildHistoryCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildSystemStatusCard(context, provider),
                const SizedBox(height: AppDimensions.largePadding),
                _buildAdvancedActionsCard(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatusCard(BuildContext context, SyncFrequencyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Sync Interval'),
              subtitle: Text(provider.getSyncIntervalText(provider.currentInterval)),
            ),
            FutureBuilder<DateTime>(
              future: provider.getNextSyncTime(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final nextSync = snapshot.data!;
                  final timeUntilSync = nextSync.difference(DateTime.now());
                  final isOverdue = timeUntilSync.isNegative;
                  
                  return ListTile(
                    leading: Icon(
                      isOverdue ? Icons.warning : Icons.access_time,
                      color: isOverdue ? Colors.orange : null,
                    ),
                    title: const Text('Next Sync'),
                    subtitle: Text(
                      isOverdue 
                          ? 'Overdue by ${_formatDuration(timeUntilSync.abs())}'
                          : 'In ${_formatDuration(timeUntilSync)}',
                    ),
                  );
                }
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Calculating next sync...'),
                );
              },
            ),
            FutureBuilder<bool>(
              future: provider.shouldSyncNow(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final shouldSync = snapshot.data!;
                  return ListTile(
                    leading: Icon(
                      shouldSync ? Icons.sync : Icons.sync_disabled,
                      color: shouldSync ? Colors.green : Colors.grey,
                    ),
                    title: const Text('Sync Status'),
                    subtitle: Text(
                      shouldSync 
                          ? 'Ready to sync now'
                          : 'Waiting for next sync window',
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySettingsCard(BuildContext context, SyncFrequencyProvider provider) {
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
            ...provider.availableIntervals.map((interval) {
              return RadioListTile<Duration>(
                title: Text(provider.getSyncIntervalText(interval)),
                subtitle: _getIntervalDescription(interval),
                value: interval,
                groupValue: provider.currentInterval,
                onChanged: (value) => provider.setSyncInterval(value!),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveSettingsCard(BuildContext context, SyncFrequencyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adaptive Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            SwitchListTile(
              title: const Text('Adaptive Frequency'),
              subtitle: const Text('Automatically adjust sync frequency based on conditions'),
              value: provider.isAdaptiveFrequencyEnabled,
              onChanged: provider.toggleAdaptiveFrequency,
            ),
            SwitchListTile(
              title: const Text('Battery Optimization'),
              subtitle: const Text('Reduce sync frequency on low battery'),
              value: provider.isBatteryOptimizedSyncEnabled,
              onChanged: provider.toggleBatteryOptimizedSync,
            ),
            SwitchListTile(
              title: const Text('WiFi Only Sync'),
              subtitle: const Text('Only sync when connected to WiFi'),
              value: provider.isWifiOnlySyncEnabled,
              onChanged: provider.toggleWifiOnlySync,
            ),
            if (provider.isAdaptiveFrequencyEnabled) ...[
              const Divider(),
              FutureBuilder<Duration>(
                future: provider.getAdaptedSyncInterval(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final adaptedInterval = snapshot.data!;
                    final isAdapted = adaptedInterval != provider.currentInterval;
                    
                    return ListTile(
                      leading: Icon(
                        isAdapted ? Icons.auto_fix_high : Icons.check_circle,
                        color: isAdapted ? Colors.orange : Colors.green,
                      ),
                      title: const Text('Current Adapted Interval'),
                      subtitle: Text(
                        provider.getSyncIntervalText(adaptedInterval) +
                        (isAdapted ? ' (adapted from ${provider.getSyncIntervalText(provider.currentInterval)})' : ''),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, SyncFrequencyProvider provider) {
    final recommendation = provider.recommendation;
    
    if (recommendation == null || !recommendation.shouldChange) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: AppDimensions.smallPadding),
                Text(
                  'Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            Text(
              'Based on your usage patterns and current conditions, we recommend changing your sync interval.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current: ${provider.getSyncIntervalText(recommendation.currentInterval)}'),
                      Text('Recommended: ${provider.getSyncIntervalText(recommendation.recommendedInterval)}'),
                      Text('Reason: ${recommendation.reason}'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => provider.applyRecommendedFrequency(),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, SyncFrequencyProvider provider) {
    final stats = provider.statistics;
    
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Syncs',
                    '${stats.totalSyncs}',
                    Icons.sync,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Success Rate',
                    '${(stats.successRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    color: stats.successRate > 0.8 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Last 24h',
                    '${stats.syncsLast24Hours}',
                    Icons.today,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Duration',
                    '${stats.averageDuration.inSeconds}s',
                    Icons.timer,
                  ),
                ),
              ],
            ),
            if (stats.lastSyncTime != null) ...[
              const SizedBox(height: AppDimensions.defaultPadding),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last Sync'),
                subtitle: Text(_formatDateTime(stats.lastSyncTime!)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: AppDimensions.smallPadding),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, SyncFrequencyProvider provider) {
    final history = provider.recentHistory;
    
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Sync History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showFullHistory(context, provider),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ...history.take(5).map((record) => _buildHistoryItem(context, record)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, SyncRecord record) {
    return ListTile(
      leading: Icon(
        record.success ? Icons.check_circle : Icons.error,
        color: record.success ? Colors.green : Colors.red,
        size: 20,
      ),
      title: Text(
        _formatDateTime(record.timestamp),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: record.duration != null
          ? Text('Duration: ${record.duration!.inSeconds}s')
          : record.error != null
              ? Text('Error: ${record.error}', style: const TextStyle(color: Colors.red))
              : null,
      dense: true,
    );
  }

  Widget _buildSystemStatusCard(BuildContext context, SyncFrequencyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            FutureBuilder<Map<String, dynamic>>(
              future: provider.getSystemStatus(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final status = snapshot.data!;
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.battery_std),
                        title: const Text('Battery Level'),
                        subtitle: Text('${status['battery_level']}% (${status['battery_state']})'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.wifi),
                        title: const Text('Connectivity'),
                        subtitle: Text(status['connectivity']),
                      ),
                      ListTile(
                        leading: Icon(
                          status['can_sync_now'] ? Icons.sync : Icons.sync_disabled,
                          color: status['can_sync_now'] ? Colors.green : Colors.grey,
                        ),
                        title: const Text('Can Sync Now'),
                        subtitle: Text(status['can_sync_now'] ? 'Yes' : 'No'),
                      ),
                    ],
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedActionsCard(BuildContext context, SyncFrequencyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showClearHistoryConfirmation(context, provider),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear History'),
                  ),
                ),
                const SizedBox(width: AppDimensions.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResetConfirmation(context, provider),
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Defaults'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getIntervalDescription(Duration interval) {
    String description;
    if (interval.inMinutes <= 30) {
      description = 'High frequency - may impact battery';
    } else if (interval.inHours <= 1) {
      description = 'Recommended for active use';
    } else if (interval.inHours <= 6) {
      description = 'Balanced performance and battery';
    } else {
      description = 'Low frequency - best battery life';
    }
    
    return Text(description, style: const TextStyle(fontSize: 12));
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFullHistory(BuildContext context, SyncFrequencyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Sync History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: provider.recentHistory.length,
            itemBuilder: (context, index) {
              final record = provider.recentHistory[index];
              return _buildHistoryItem(context, record);
            },
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

  void _showClearHistoryConfirmation(BuildContext context, SyncFrequencyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync History'),
        content: const Text(
          'This will permanently delete all sync history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.clearSyncHistory();
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SyncFrequencyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all sync frequency settings to their default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}