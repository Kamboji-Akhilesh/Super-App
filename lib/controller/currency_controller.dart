import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_app/models/currency_model.dart';
import 'package:super_app/models/latest_rates_model.dart';
import 'package:super_app/repos/currency_repo.dart';

final currencyControllerProvider = Provider(
    (ref) => CurrencyController(currencyRepo: ref.watch(currencyRepoProvider)));

class CurrencyController {
  final CurrencyRepo _currencyRepo;

  CurrencyController({required CurrencyRepo currencyRepo})
      : _currencyRepo = currencyRepo;

  Future<List<CurrencyModel>> getLatestCurrencyRatesAndNames(
      {String from = "INR"}) async {
    final currencyRatesResponse =
        await _currencyRepo.getLatestCurrencyRates(from: from);
    final currencyRatesData = jsonDecode(currencyRatesResponse.body);
    LatestRatesModel currencyRates =
        LatestRatesModel.fromJSON(currencyRatesData);

    final currencyNamesResponse = await _currencyRepo.getCurrencyNames();
    Map<String, dynamic> currencyNamesData =
        jsonDecode(currencyNamesResponse.body);

    List<CurrencyModel> currencyRatesAndNames = [];
    currencyRates.rates?.forEach((key, value) {
      currencyRatesAndNames.add(CurrencyModel(
          symbol: key,
          name: currencyNamesData[key],
          valueWrtInr: value.toDouble()));
    });

    return currencyRatesAndNames;
  }
}
