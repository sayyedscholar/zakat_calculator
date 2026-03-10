class MetalRates {
  final double goldRatePerGram;
  final double silverRatePerGram;
  final String currency;
  final DateTime lastUpdated;
  final String? location; // City/location this rate applies to

  MetalRates({
    required this.goldRatePerGram,
    required this.silverRatePerGram,
    this.currency = 'INR',
    DateTime? lastUpdated,
    this.location,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'goldRatePerGram': goldRatePerGram,
      'silverRatePerGram': silverRatePerGram,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
      'location': location,
    };
  }

  factory MetalRates.fromJson(Map<String, dynamic> json) {
    return MetalRates(
      goldRatePerGram: json['goldRatePerGram']?.toDouble() ?? 0.0,
      silverRatePerGram: json['silverRatePerGram']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      location: json['location'],
    );
  }

  // Current offline default rates (March 2026)
  factory MetalRates.defaultRates() {
    return MetalRates(
      goldRatePerGram: 16100.0,
      silverRatePerGram: 290.0,
      currency: 'INR',
    );
  }
}