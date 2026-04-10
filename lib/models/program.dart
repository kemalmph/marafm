enum Day { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class Program {
  final String startTime; // HH:mm
  final String endTime;   // HH:mm
  final List<Day> days;
  final String show;
  final String host;
  final String genre;
  final int priority;

  const Program({
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.show,
    required this.host,
    required this.genre,
    this.priority = 0,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => Day.values.firstWhere((d) => d.toString().split('.').last == e))
          .toList(),
      show: json['show'] as String,
      host: json['host'] as String,
      genre: json['genre'] as String,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'days': days.map((e) => e.toString().split('.').last).toList(),
      'show': show,
      'host': host,
      'genre': genre,
      'priority': priority,
    };
  }

  bool isActive(DateTime now) {
    final day = getDayFromDateTime(now);
    if (!days.contains(day)) return false;

    final currentTime = now.hour * 60 + now.minute;
    final startH = int.parse(startTime.split(RegExp(r'[.:]'))[0]);
    final startM = int.parse(startTime.split(RegExp(r'[.:]'))[1]);
    final endH = int.parse(endTime.split(RegExp(r'[.:]'))[0]);
    final endM = int.parse(endTime.split(RegExp(r'[.:]'))[1]);

    final startMinutes = startH * 60 + startM;
    var endMinutes = endH * 60 + endM;
    
    if (endH == 0 && endMinutes == 0) endMinutes = 24 * 60;
    if (endH == 24) endMinutes = 24 * 60;

    return currentTime >= startMinutes && currentTime < endMinutes;
  }

  String get timeRangeText => '$startTime - $endTime WIB';

  int get startMinutes {
    final startH = int.parse(startTime.split(RegExp(r'[.:]'))[0]);
    final startM = int.parse(startTime.split(RegExp(r'[.:]'))[1]);
    return startH * 60 + startM;
  }
}

Day getDayFromDateTime(DateTime dt) {
  switch (dt.weekday) {
    case DateTime.monday: return Day.monday;
    case DateTime.tuesday: return Day.tuesday;
    case DateTime.wednesday: return Day.wednesday;
    case DateTime.thursday: return Day.thursday;
    case DateTime.friday: return Day.friday;
    case DateTime.saturday: return Day.saturday;
    case DateTime.sunday: return Day.sunday;
    default: return Day.monday;
  }
}
