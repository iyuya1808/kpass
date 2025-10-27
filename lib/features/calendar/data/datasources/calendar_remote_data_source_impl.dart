import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'calendar_remote_data_source.dart';

/// Implementation of CalendarRemoteDataSource using Canvas API
class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final CanvasApiClient _apiClient;

  const CalendarRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    try {
      final response = await _apiClient.get('/api/v1/calendar_events', queryParameters: {
        'per_page': '100',
        'include[]': ['assignment'],
      });

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for calendar events',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch calendar events: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiClient.get('/api/v1/calendar_events', queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'per_page': '100',
        'include[]': ['assignment'],
      });

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for calendar events in range',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch calendar events in range: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<CalendarEvent> getCalendarEvent(String eventId) async {
    try {
      final response = await _apiClient.get('/api/v1/calendar_events/$eventId', queryParameters: {
        'include[]': ['assignment'],
      });

      if (response.isSuccess && response.valueOrNull is Map<String, dynamic>) {
        return CalendarEvent.fromJson(response.valueOrNull as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Invalid response format for calendar event',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch calendar event $eventId: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEventsWithPagination({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiClient.get('/api/v1/calendar_events', queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'include[]': ['assignment'],
      });

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for calendar events with pagination',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch calendar events with pagination: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEventsForContexts(
    List<String> contextCodes,
  ) async {
    try {
      final response = await _apiClient.get('/api/v1/calendar_events', queryParameters: {
        'context_codes[]': contextCodes,
        'per_page': '100',
        'include[]': ['assignment'],
      });

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for calendar events for contexts',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch calendar events for contexts: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    try {
      final response = await _apiClient.post('/api/v1/calendar_events', data: {
        'calendar_event': {
          'title': event.title,
          'description': event.description,
          'start_at': event.startTime.toIso8601String(),
          'end_at': event.endTime?.toIso8601String(),
          'location_name': event.location,
          'context_code': event.contextCode,
        },
      });

      if (response.isSuccess && response.valueOrNull is Map<String, dynamic>) {
        return CalendarEvent.fromJson(response.valueOrNull as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Invalid response format for created calendar event',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to create calendar event: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event) async {
    try {
      final response = await _apiClient.put('/api/v1/calendar_events/${event.id}', data: {
        'calendar_event': {
          'title': event.title,
          'description': event.description,
          'start_at': event.startTime.toIso8601String(),
          'end_at': event.endTime?.toIso8601String(),
          'location_name': event.location,
        },
      });

      if (response.isSuccess && response.valueOrNull is Map<String, dynamic>) {
        return CalendarEvent.fromJson(response.valueOrNull as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Invalid response format for updated calendar event',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to update calendar event ${event.id}: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _apiClient.delete('/api/v1/calendar_events/$eventId');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to delete calendar event $eventId: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}