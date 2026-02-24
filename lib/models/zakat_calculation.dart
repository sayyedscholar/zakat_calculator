class ZakatCalculation {
  final double cashInHand;
  final double goldWeight;
  final double silverWeight;
  final double businessAssets;
  final double investmentProperties;
  final double sharesSecurities;
  final double receivableLoans;
  final double otherZakatable;
  final double payableLoans;
  final double outstandingBills;
  final double goldRatePerGram;
  final double silverRatePerGram;
  final double goldPurity; // 1.0 for 24K, 0.916 for 22K, etc.
  final double silverPurity;
  final String location;
  final DateTime calculationDate;

  ZakatCalculation({
    this.cashInHand = 0,
    this.goldWeight = 0,
    this.silverWeight = 0,
    this.goldPurity = 1.0,
    this.silverPurity = 1.0,
    this.businessAssets = 0,
    this.investmentProperties = 0,
    this.sharesSecurities = 0,
    this.receivableLoans = 0,
    this.otherZakatable = 0,
    this.payableLoans = 0,
    this.outstandingBills = 0,
    required this.goldRatePerGram,
    required this.silverRatePerGram,
    required this.location,
    DateTime? calculationDate,
  }) : calculationDate = calculationDate ?? DateTime.now();

  static const double nisabSilverGrams = 612.36; // 52.5 tola
  static const double nisabGoldGrams = 87.48; // 7.5 tola
  static const double zakatRate = 0.025;

  double get totalAssets {
    return cashInHand +
        (goldWeight * goldPurity * goldRatePerGram) +
        (silverWeight * silverPurity * silverRatePerGram) +
        businessAssets +
        investmentProperties +
        sharesSecurities +
        receivableLoans +
        otherZakatable;
  }

  double get totalLiabilities {
    return payableLoans + outstandingBills;
  }

  double get netZakatableWealth {
    final net = totalAssets - totalLiabilities;
    return net > 0 ? net : 0;
  }

  double get nisabThreshold {
    return nisabSilverGrams * silverRatePerGram;
  }

  double get nisabThresholdGold {
    return nisabGoldGrams * goldRatePerGram;
  }

  bool get isEligible {
    return netZakatableWealth >= nisabThreshold;
  }

  double get zakatDue {
    if (!isEligible) return 0;
    return netZakatableWealth * zakatRate;
  }

  Map<String, dynamic> toJson() {
    return {
      'cashInHand': cashInHand,
      'goldWeight': goldWeight,
      'silverWeight': silverWeight,
      'goldPurity': goldPurity,
      'silverPurity': silverPurity,
      'businessAssets': businessAssets,
      'investmentProperties': investmentProperties,
      'sharesSecurities': sharesSecurities,
      'receivableLoans': receivableLoans,
      'otherZakatable': otherZakatable,
      'payableLoans': payableLoans,
      'outstandingBills': outstandingBills,
      'goldRatePerGram': goldRatePerGram,
      'silverRatePerGram': silverRatePerGram,
      'location': location,
      'calculationDate': calculationDate.toIso8601String(),
    };
  }

  factory ZakatCalculation.fromJson(Map<String, dynamic> json) {
    return ZakatCalculation(
      cashInHand: json['cashInHand']?.toDouble() ?? 0,
      goldWeight: json['goldWeight']?.toDouble() ?? 0,
      silverWeight: json['silverWeight']?.toDouble() ?? 0,
      goldPurity: json['goldPurity']?.toDouble() ?? 1.0,
      silverPurity: json['silverPurity']?.toDouble() ?? 1.0,
      businessAssets: json['businessAssets']?.toDouble() ?? 0,
      investmentProperties: json['investmentProperties']?.toDouble() ?? 0,
      sharesSecurities: json['sharesSecurities']?.toDouble() ?? 0,
      receivableLoans: json['receivableLoans']?.toDouble() ?? 0,
      otherZakatable: json['otherZakatable']?.toDouble() ?? 0,
      payableLoans: json['payableLoans']?.toDouble() ?? 0,
      outstandingBills: json['outstandingBills']?.toDouble() ?? 0,
      goldRatePerGram: json['goldRatePerGram']?.toDouble() ?? 0,
      silverRatePerGram: json['silverRatePerGram']?.toDouble() ?? 0,
      location: json['location'] ?? '',
      calculationDate: DateTime.parse(json['calculationDate']),
    );
  }
}
