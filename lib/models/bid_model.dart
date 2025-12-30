class BidModel {
  final String orderId;
  final String workerId;
  final int etaMinutes;
  final double score;

  BidModel({
    required this.orderId,
    required this.workerId,
    required this.etaMinutes,
    required this.score,
  });

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      orderId: map['orderId'] as String,
      workerId: map['workerId'] as String,
      etaMinutes: (map['etaMinutes'] as num).toInt(),
      score: (map['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'workerId': workerId,
      'etaMinutes': etaMinutes,
      'score': score,
    };
  }
}
