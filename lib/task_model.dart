class Task {
  int? id;
  String description;
  bool isCompleted;
  DateTime creationDate;

  Task({
    this.id,
    required this.description,
    this.isCompleted = false,
    required this.creationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'creationDate': creationDate.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      description: map['description'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      creationDate: DateTime.fromMillisecondsSinceEpoch(map['creationDate'] as int),
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, description: $description, isCompleted: $isCompleted, creationDate: $creationDate}';
  }
}
