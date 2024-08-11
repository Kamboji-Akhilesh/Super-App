class CurrencyModel {
  String? symbol;
  String? name;
  double? valueWrtInr;

  CurrencyModel(
      {required this.symbol, required this.name, required this.valueWrtInr});

  CurrencyModel.fromJson(Map<String, dynamic> json) {
    symbol = json['symbol'];
    name = json['name'];
    valueWrtInr = json['valueWrtInr'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['symbol'] = symbol;
    data['name'] = name;
    data['valueWrtInr'] = valueWrtInr;
    return data;
  }
}
