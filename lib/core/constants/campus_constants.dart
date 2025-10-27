/// 慶應義塾大学のキャンパス情報と時限設定
class CampusConstants {
  /// 利用可能なキャンパス一覧
  static const List<KeioCampus> availableCampuses = [
    KeioCampus.hiyoshi,
    KeioCampus.mita,
    KeioCampus.sfc,
    KeioCampus.shinanomachi,
  ];

  /// キャンパス名の日本語表示
  static String getCampusDisplayName(KeioCampus campus) {
    switch (campus) {
      case KeioCampus.hiyoshi:
        return '日吉キャンパス';
      case KeioCampus.mita:
        return '三田キャンパス';
      case KeioCampus.sfc:
        return '湘南藤沢キャンパス';
      case KeioCampus.shinanomachi:
        return '信濃町キャンパス';
    }
  }

  /// キャンパス名の英語表示
  static String getCampusEnglishName(KeioCampus campus) {
    switch (campus) {
      case KeioCampus.hiyoshi:
        return 'Hiyoshi Campus';
      case KeioCampus.mita:
        return 'Mita Campus';
      case KeioCampus.sfc:
        return 'SFC Campus';
      case KeioCampus.shinanomachi:
        return 'Shinanomachi Campus';
    }
  }
}

/// 慶應義塾大学のキャンパス
enum KeioCampus {
  hiyoshi, // 日吉キャンパス
  mita, // 三田キャンパス
  sfc, // 湘南藤沢キャンパス
  shinanomachi, // 信濃町キャンパス
}

/// キャンパスごとの時限設定
class CampusPeriodSchedule {
  /// 日吉キャンパスの時限設定（一般的な大学の標準時限）
  static const Map<int, PeriodTime> hiyoshiPeriods = {
    1: PeriodTime(start: '09:00', end: '10:30'),
    2: PeriodTime(start: '10:45', end: '12:15'),
    3: PeriodTime(start: '13:00', end: '14:30'),
    4: PeriodTime(start: '14:45', end: '16:15'),
    5: PeriodTime(start: '16:30', end: '18:00'),
    6: PeriodTime(start: '18:15', end: '19:45'),
    7: PeriodTime(start: '20:00', end: '21:30'),
  };

  /// 三田キャンパスの時限設定（少し早めの開始）
  static const Map<int, PeriodTime> mitaPeriods = {
    1: PeriodTime(start: '08:50', end: '10:20'),
    2: PeriodTime(start: '10:35', end: '12:05'),
    3: PeriodTime(start: '12:50', end: '14:20'),
    4: PeriodTime(start: '14:35', end: '16:05'),
    5: PeriodTime(start: '16:20', end: '17:50'),
    6: PeriodTime(start: '18:05', end: '19:35'),
    7: PeriodTime(start: '19:50', end: '21:20'),
  };

  /// 湘南藤沢キャンパスの時限設定（SFC独自の時間割）
  static const Map<int, PeriodTime> sfcPeriods = {
    1: PeriodTime(start: '09:00', end: '10:30'),
    2: PeriodTime(start: '10:40', end: '12:10'),
    3: PeriodTime(start: '13:00', end: '14:30'),
    4: PeriodTime(start: '14:40', end: '16:10'),
    5: PeriodTime(start: '16:20', end: '17:50'),
    6: PeriodTime(start: '18:00', end: '19:30'),
    7: PeriodTime(start: '19:40', end: '21:10'),
  };

  /// 信濃町キャンパスの時限設定（医学部の時間割）
  static const Map<int, PeriodTime> shinanomachiPeriods = {
    1: PeriodTime(start: '09:00', end: '10:30'),
    2: PeriodTime(start: '10:45', end: '12:15'),
    3: PeriodTime(start: '13:00', end: '14:30'),
    4: PeriodTime(start: '14:45', end: '16:15'),
    5: PeriodTime(start: '16:30', end: '18:00'),
    6: PeriodTime(start: '18:15', end: '19:45'),
    7: PeriodTime(start: '20:00', end: '21:30'),
  };

  /// キャンパスに応じた時限設定を取得
  static Map<int, PeriodTime>? getScheduleForCampus(KeioCampus campus) {
    switch (campus) {
      case KeioCampus.hiyoshi:
        return hiyoshiPeriods;
      case KeioCampus.mita:
        return mitaPeriods;
      case KeioCampus.sfc:
        return sfcPeriods;
      case KeioCampus.shinanomachi:
        return shinanomachiPeriods;
    }
  }
}

/// 時限時間を表現するクラス
class PeriodTime {
  final String start;
  final String end;

  const PeriodTime({required this.start, required this.end});

  @override
  String toString() {
    return '$start-$end';
  }
}
