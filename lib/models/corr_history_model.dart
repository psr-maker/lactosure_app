class CorrectionHistory {
  final int id;
  final String societyId;
  final String machineId;
  final String machineType;
  final String backupDateTime;

  final String? ch1;
  final String? fat1;
  final String? snf1;
  final String? clr1;
  final String? t1;
  final String? w1;
  final String? p1;

  final String? ch2;
  final String? fat2;
  final String? snf2;
  final String? clr2;
  final String? t2;
  final String? w2;
  final String? p2;

  final String? ch3;
  final String? fat3;
  final String? snf3;
  final String? clr3;
  final String? t3;
  final String? w3;
  final String? p3;

  CorrectionHistory({
    required this.id,
    required this.societyId,
    required this.machineId,
    required this.machineType,
    required this.backupDateTime,

    this.ch1,
    this.fat1,
    this.snf1,
    this.clr1,
    this.t1,
    this.w1,
    this.p1,

    this.ch2,
    this.fat2,
    this.snf2,
    this.clr2,
    this.t2,
    this.w2,
    this.p2,

    this.ch3,
    this.fat3,
    this.snf3,
    this.clr3,
    this.t3,
    this.w3,
    this.p3,
  });

  factory CorrectionHistory.fromJson(Map<String, dynamic> json) {
    return CorrectionHistory(
      id: json['id'] ?? 0,
      societyId: json['societyID']?.toString() ?? '',
      machineId: json['machineId']?.toString() ?? '',
      machineType: json['machineType']?.toString() ?? '',
      backupDateTime: json['backupDateTime']?.toString() ?? '',

      ch1: json['ch1']?.toString(),
      fat1: json['fat1']?.toString(),
      snf1: json['snf1']?.toString(),
      clr1: json['clr1']?.toString(),
      t1: json['t1']?.toString(),
      w1: json['w1']?.toString(),
      p1: json['p1']?.toString(),

      ch2: json['ch2']?.toString(),
      fat2: json['fat2']?.toString(),
      snf2: json['snf2']?.toString(),
      clr2: json['clr2']?.toString(),
      t2: json['t2']?.toString(),
      w2: json['w2']?.toString(),
      p2: json['p2']?.toString(),

      ch3: json['ch3']?.toString(),
      fat3: json['fat3']?.toString(),
      snf3: json['snf3']?.toString(),
      clr3: json['clr3']?.toString(),
      t3: json['t3']?.toString(),
      w3: json['w3']?.toString(),
      p3: json['p3']?.toString(),
    );
  }
}