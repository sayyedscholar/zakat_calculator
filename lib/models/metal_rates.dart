class MetalRates {
  final double goldRatePerGram;
  final double silverRatePerGram;
  final String currency;
  final DateTime lastUpdated;

  MetalRates({
    required this.goldRatePerGram,
    required this.silverRatePerGram,
    this.currency = 'INR',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'goldRatePerGram': goldRatePerGram,
      'silverRatePerGram': silverRatePerGram,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory MetalRates.fromJson(Map<String, dynamic> json) {
    return MetalRates(
      goldRatePerGram: json['goldRatePerGram']?.toDouble() ?? 0.0,
      silverRatePerGram: json['silverRatePerGram']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  factory MetalRates.defaultRates() {
    return MetalRates(
      goldRatePerGram: 6500.0,
      silverRatePerGram: 80.0,
      currency: 'INR',
    );
  }
}