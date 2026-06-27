class CorrectionModel {
  int? id;

  String correctionType;

  String? societyId;
  String? machineId;
  String? machineType;

  String channel;

  double? fat;
  double? snf;
  double? clr;
  double? protein;
  double? temp;
  double? water;

  String createdAt;

  int synced;

  CorrectionModel({
    this.id,
    required this.correctionType,
    this.societyId,
    this.machineId,
    this.machineType,
    required this.channel,
    this.fat,
    this.snf,
    this.clr,
    this.protein,
    this.temp,
    this.water,
    required this.createdAt,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'correctionType': correctionType,
      'societyId': societyId,
      'machineId': machineId,
      'machineType': machineType,
      'channel': channel,
      'fat': fat,
      'snf': snf,
      'clr': clr,
      'protein': protein,
      'temp': temp,
      'water': water,
      'createdAt': createdAt,
      'synced': synced,
    };
  }

  factory CorrectionModel.fromMap(Map<String, dynamic> map) {
    return CorrectionModel(
      id: map['id'],
      correctionType: map['correctionType'],
      societyId: map['societyId'],
      machineId: map['machineId'],
      machineType: map['machineType'],
      channel: map['channel'],
      fat: map['fat'],
      snf: map['snf'],
      clr: map['clr'],
      protein: map['protein'],
      temp: map['temp'],
      water: map['water'],
      createdAt: map['createdAt'],
      synced: map['synced'],
    );
  }
}