class LatestRatesModel {
  double? amount;
  String? base;
  String? date;
  Map<String, dynamic>? rates;

  LatestRatesModel(
      {required this.amount,
      required this.base,
      required this.date,
      required this.rates});

  LatestRatesModel.fromJSON(Map<String, dynamic> json) {
    amount = json['amount'];
    base = json['base'];
    date = json['date'];
    rates = json['rates'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['base'] = base;
    data['date'] = date;
    data['rates'] = rates;
    return data;
  }
}
