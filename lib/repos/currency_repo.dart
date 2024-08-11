import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final currencyRepoProvider = Provider((ref) => CurrencyRepo());

class CurrencyRepo {
  Future<http.Response> getLatestCurrencyRates({required String from}) async {
    final url = Uri.parse("https://api.frankfurter.app/latest?from=$from");
    final response = await http.get(url);
    return response;
  }

  Future<http.Response> getCurrencyNames() async {
    final url = Uri.parse("https://api.frankfurter.app/currencies");
    final response = await http.get(url);
    return response;
  }
}
