import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum Days { thirty, sixty, ninety }

class Converter extends StatefulWidget {
  const Converter({super.key});

  @override
  State<Converter> createState() => _ConverterState();
}

class _ConverterState extends State<Converter> {
  final TextEditingController colorController = TextEditingController();
  Days _day = Days.thirty;
  Widget customRadioButton(
      {required String title, required Days value, required Days groupValue}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _day = value;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: value == groupValue ? 24 : 18,
              height: value == groupValue ? 24 : 18,
              margin: value == groupValue ? null : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: value == groupValue
                    ? Border.all(
                        width: 6,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : Border.all(
                        width: 2,
                        color: Colors.grey,
                      ),
                boxShadow: value == groupValue
                    ? [
                        BoxShadow(
                          spreadRadius: 0.25,
                          blurRadius: 25,
                          color: Theme.of(context).colorScheme.secondary,
                          blurStyle: BlurStyle.outer,
                        )
                      ]
                    : null,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: value == groupValue
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 3:
        text = 'Jun 17';
        break;
      case 15:
        text = 'Jul 2';
        break;
      case 30:
        text = 'Jul 16';
        break;
      default:
        return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffc9c9c9)),
              ),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: "250",
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(0)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 0, 0),
                      child: Text(
                        "USD",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: "USD",
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: "INR", child: Text("INR")),
                      DropdownMenuItem(value: "USD", child: Text("USD")),
                      DropdownMenuItem(value: "RUB", child: Text("RUB")),
                      DropdownMenuItem(value: "EUR", child: Text("EUR")),
                    ],
                    icon: const Icon(Icons.keyboard_arrow_down),
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onChanged: (String? value) {},
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text("to"),
                    Icon(
                      Icons.repeat,
                      size: 68,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: "EUR",
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: "INR", child: Text("INR")),
                      DropdownMenuItem(value: "USD", child: Text("USD")),
                      DropdownMenuItem(value: "RUB", child: Text("RUB")),
                      DropdownMenuItem(value: "EUR", child: Text("EUR")),
                    ],
                    icon: const Icon(Icons.keyboard_arrow_down),
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onChanged: (String? value) {},
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    elevation: 20,
                    shadowColor: Theme.of(context).colorScheme.secondary,
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text("GO"),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              children: [
                Text(
                  "229.59 EUR",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: Text(
                    "1 USD = 0.92 EUR",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Text(
              'Historical Data',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                customRadioButton(
                  title: '30 days',
                  value: Days.thirty,
                  groupValue: _day,
                ),
                customRadioButton(
                  title: '60 days',
                  value: Days.sixty,
                  groupValue: _day,
                ),
                customRadioButton(
                  title: '90 days',
                  value: Days.ninety,
                  groupValue: _day,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: Text(
              "Value of 1 USD in EUR for the past 30 days",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 32, 0),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      show: true,
                      spots: const [
                        FlSpot(3, 0.931),
                        FlSpot(6, 0.932),
                        FlSpot(9, 0.927),
                        FlSpot(12, 0.933),
                        FlSpot(15, 0.931),
                        FlSpot(18, 0.924),
                        FlSpot(21, 0.925),
                        FlSpot(24, 0.923),
                        FlSpot(27, 0.915),
                        FlSpot(30, 0.920),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.error,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                      isCurved: true,
                      barWidth: 8,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      dotData: const FlDotData(show: false),
                      isStrokeCapRound: true,
                    ),
                  ],
                  gridData: const FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    border: const Border.symmetric(
                      horizontal: BorderSide(color: Colors.grey),
                      vertical: BorderSide.none,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      axisNameSize: 20,
                      axisNameWidget: Text("Currency in EUR"),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitleWidgets,
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(
                    touchTooltipData: LineTouchTooltipData(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
