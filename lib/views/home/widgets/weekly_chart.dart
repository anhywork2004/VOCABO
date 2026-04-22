import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyChart extends StatelessWidget {

  final List<int> data;

  const WeeklyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    List<String> days = ["T2","T3","T4","T5","T6","T7","CN"];

    double maxY = data.isEmpty
        ? 10
        : (data.reduce((a,b)=>a>b?a:b)).toDouble() + 5;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 20),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: cs.surface,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            "Hoạt động tuần",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 15),

          Expanded(

            child: BarChart(

              BarChartData(

                maxY: maxY,

                borderData: FlBorderData(show: false),

                gridData: FlGridData(show: false),

                titlesData: FlTitlesData(

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  bottomTitles: AxisTitles(

                    sideTitles: SideTitles(

                      showTitles: true,

                      getTitlesWidget: (value, meta) {

                        int index = value.toInt();

                        if(index < 0 || index >= days.length){
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: List.generate(data.length, (i){

                  return BarChartGroupData(

                    x: i,

                    barRods: [

                      BarChartRodData(

                        toY: data[i].toDouble(),

                        width: 16,

                        borderRadius: BorderRadius.circular(6),

                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff42A5F5),
                            Color(0xff1E88E5),
                          ],
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}