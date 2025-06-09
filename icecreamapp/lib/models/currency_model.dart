class CurrencyRates {
  final String base;
  final DateTime date;
  final Map<String, double> rates; // e.g., {"USD": 0.000063, "JPY": 0.0099, "EUR": 0.000058}

  CurrencyRates({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    return CurrencyRates(
      base: json['base'],
      date: DateTime.parse(json['date']),
      rates: Map<String, double>.from(json['rates'].map((key, value) => MapEntry(key, (value as num).toDouble()))),
    );
  }
}