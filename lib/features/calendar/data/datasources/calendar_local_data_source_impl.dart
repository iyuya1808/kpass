import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';

/// Implementation of CalendarLocalDataSource using file system
class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  static const String _eventsFileName = 'calendar_events_cache.json';
  static const String _metadataFileName = 'calendar_metadata.json';
  static const Duration _defaultCacheExpiry = Duration(hours: 2);

  @override
  Future<List<CalendarEvent>> getCachedCalendarEvents() async {
    try {
      final file = await _getEventsFile();
      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final eventsJson = jsonData['events'] as List?;

      if (eventsJson == null) {
        return [];
      }

      return eventsJson
          .map((eventJson) => CalendarEvent.fromJson(eventJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCachedCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final events = await getCachedCalendarEvents();
      return events.where((event) {
        return event.startTime.isAfter(startDate) && 
               event.startTime.isBefore(endDate);
      }).toList();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached calendar events in range: ${e.toString()}',
      );
    }
  }

  @override
  Future<CalendarEvent?> getCachedCalendarEvent(String eventId) async {
    try {
      final events = await getCachedCalendarEvents();
      return events.where((event) => event.id == eventId).firstOrNull;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached calendar event $eventId: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheCalendarEvents(List<CalendarEvent> events) async {
    try {
      final file = await _getEventsFile();
      final cacheData = {
        'events': events.map((event) => event.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(cacheData));

      // Update metadata
      final metadata = CacheMetadata(
        lastUpdated: DateTime.now(),
        itemCount: events.length,
      );
      await updateCacheMetadata(metadata);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheCalendarEvent(CalendarEvent event) async {
    try {
      final events = await getCachedCalendarEvents();
      final existingIndex = events.indexWhere((e) => e.id == event.id);
      
      if (existingIndex >= 0) {
        events[existingIndex] = event;
      } else {
        events.add(event);
      }

      await cacheCalendarEvents(events);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache calendar event ${event.id}: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> removeCachedCalendarEvent(String eventId) async {
    try {
      final events = await getCachedCalendarEvents();
      final updatedEvents = events.where((event) => event.id != eventId).toList();
      
      await cacheCalendarEvents(updatedEvents);
    } catch (e) {
      throw CacheException(
        message: 'Failed to remove cached calendar event $eventId: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final eventsFile = await _getEventsFile();
      final metadataFile = await _getMetadataFile();

      if (await eventsFile.exists()) {
        await eventsFile.delete();
      }

      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<CacheMetadata> getCacheMetadata() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) {
        return CacheMetadata(
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
          itemCount: 0,
        );
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return CacheMetadata.fromJson(jsonData);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cache metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateCacheMetadata(CacheMetadata metadata) async {
    try {
      final file = await _getMetadataFile();
      await file.writeAsString(json.encode(metadata.toJson()));
    } catch (e) {
      throw CacheException(
        message: 'Failed to update cache metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isCacheExpired() async {
    try {
      final metadata = await getCacheMetadata();
      return metadata.isExpired(maxAge: _defaultCacheExpiry);
    } catch (e) {
      return true; // Consider cache expired if we can't read metadata
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      final eventsFile = await _getEventsFile();
      final metadataFile = await _getMetadataFile();

      int size = 0;
      if (await eventsFile.exists()) {
        size += await eventsFile.length();
      }
      if (await metadataFile.exists()) {
        size += await metadataFile.length();
      }

      return size;
    } catch (e) {
      return 0;
    }
  }

  Future<File> _getEventsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_eventsFileName');
  }

  Future<File> _getMetadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_metadataFileName');
  }
}