class Breadcrumb {
  final String type;

  final String message;

  final DateTime timestamp;

  final Map<String, dynamic> data;

  const Breadcrumb({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "timeStamp": timestamp,
      "message": message,
      "data": data,
    };
  }

  @override
  String toString() {
    return '[${timestamp.hour}:'
        '${timestamp.minute}:'
        '${timestamp.second}] '
        '$type: $message';
  }
}
