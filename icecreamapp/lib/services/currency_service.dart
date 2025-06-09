import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icecreamapp/models/currency_model.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';


class CurrencyService {
  Future<CurrencyRates?> getExchangeRates({String fromCurrency = 'IDR', List<String> toCurrencies = const ['USD', 'JPY', 'EUR']}) async {
    final symbols = toCurrencies.join(',');
    final url = Uri.parse('${ApiService.frankfurterApiUrl}/latest?from=$fromCurrency&to=$symbols');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return CurrencyRates.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to load exchange rates: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return null;
    }
  }

  String formatCurrency(double amount, String currencyCode, CurrencyRates? rates, {String originalCurrency = 'IDR'}) {
    if (rates != null && rates.rates.containsKey(currencyCode)) {
      double convertedAmount = amount * (rates.rates[currencyCode]!);
      // Gunakan NumberFormat dari package intl
      switch (currencyCode) {
        case 'USD':
          return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(convertedAmount);
        case 'JPY':
          return NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(convertedAmount);
        case 'EUR':
          return NumberFormat.currency(locale: 'de_DE', symbol: '€').format(convertedAmount); // Euro bisa pakai locale Eropa mana saja
        default: // Termasuk IDR jika currencyCode adalah IDR dan tidak ada di rates (karena from=IDR)
          return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(amount);
      }
    }
    // Fallback jika tidak ada rate atau currency tidak didukung (tampilkan dalam IDR)
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(amount);
  }

  // Fungsi untuk mengkonversi nilai dari IDR ke mata uang lain
  double convertFromIDR(double amountIDR, String toCurrencyCode, CurrencyRates? rates) {
    if (rates != null && rates.base == 'IDR' && rates.rates.containsKey(toCurrencyCode)) {
      return amountIDR * rates.rates[toCurrencyCode]!;
    }
    return amountIDR; // Return original amount if conversion not possible
  }
}