import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'home.dart';
import 'widgets/steps_goal_card.dart';
import 'package:provider/provider.dart';
import 'providers/step_goal_provider.dart';

class StepsScreen extends StatefulWidget {
  final int currentSteps;
  final int goalSteps;

  const StepsScreen({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
  });

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  String _selectedPeriod = 'Week';
  int _monthOffset = 0;
  int _dayOffset = 0;
  int _weekOffset = 0;
  int _yearOffset = 0;
  DateTime _currentViewDate = DateTime.now();
  int? _selectedBarIndex;
  double? _selectedBarValue;
  int _selectedIndex = 1; // Health section selected by default
  bool _isGoalEnabled = true;

  // Simulated data for the week - matching home.dart and health_dashboard.dart
  final List<Map<String, dynamic>> _weeklyData = [
    {'steps': 1200, 'calories': 120.5, 'heartRate': 72},
    {'steps': 1500, 'calories': 150.2, 'heartRate': 75},
    {'steps': 1800, 'calories': 180.7, 'heartRate': 68},
    {'steps': 2000, 'calories': 200.8, 'heartRate': 82},
    {'steps': 2500, 'calories': 250.3, 'heartRate': 76},
    {'steps': 3000, 'calories': 300.5, 'heartRate': 65},
    {'steps': 1200, 'calories': 120.8, 'heartRate': 70},
  ];

  List<double> _generateDayData() {
    final todaySteps = _weeklyData.last['steps'] as int; // 1200
    final pattern = [
      0.04,
      0.03,
      0.02,
      0.01,
      0.02,
      0.04,
      0.06,
      0.08,
      0.05,
      0.04,
      0.05,
      0.05,
      0.07,
      0.06,
      0.04,
      0.05,
      0.05,
      0.07,
      0.06,
      0.05,
      0.04,
      0.03,
      0.02,
      0.01
    ];
    final sum = pattern.reduce((a, b) => a + b);
    return pattern.map((v) => todaySteps * v / sum).toList();
  }

  List<double> _generateWeekData() {
    // Use the weekly data directly from _weeklyData
    return _weeklyData.map((day) => (day['steps'] as int).toDouble()).toList();
  }

  List<double> _generateMonthData() {
    final random = math.Random(42); // Fixed seed for consistency
    return List.generate(30, (index) {
      // Simulate a realistic pattern: weekdays lower, weekends higher, plus some noise
      final isWeekend = (index % 7 == 5) || (index % 7 == 6);
      final base = isWeekend ? 2500 : 1400; // weekends much higher
      final trend =
          (index > 14) ? 200 : 0; // second half of month slightly higher
      final noise = random.nextInt(600) - 300; // -300 to +300
      return (base + trend + noise).clamp(900, 4000).toDouble();
    });
  }

  List<double> _generateYearData() {
    final random = math.Random(99); // Fixed seed for consistency
    return List.generate(12, (index) {
      // Stronger seasonal variation: much more steps in summer (months 4-8)
      final seasonBoost = (index >= 4 && index <= 8) ? 2000 : 0;
      final base = 2200 + seasonBoost;
      final trend = (index >= 9) ? -300 : 0; // last quarter slightly lower
      final noise = random.nextInt(1200) - 600; // -600 to +600
      // Each month is the average of 30 days
      return (base + trend + noise).clamp(1200, 7000).toDouble();
    });
  }

  // Sample data for different periods
  final Map<String, List<double>> periodData = {
    'Day': [], // Will be populated in initState
    'Week': [], // Will be populated in initState
    'Month': [], // Will be populated in initState
    'Year': [], // Will be populated in initState
  };

  @override
  void initState() {
    super.initState();
    periodData['Day'] = _generateDayData();
    periodData['Week'] = _generateWeekData();
    periodData['Month'] = _generateMonthData();
    periodData['Year'] = _generateYearData();
  }

  @override
  void didUpdateWidget(StepsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    periodData['Day'] = _generateDayData();
    periodData['Week'] = _generateWeekData();
    periodData['Month'] = _generateMonthData();
    periodData['Year'] = _generateYearData();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _getMonthNameFromIndex(int index) {
    final months = [
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
      'Jan',
      'Feb',
      'Mar',
      'Apr'
    ];
    return months[index];
  }

  String _getYearFromIndex(int index) {
    final currentDate =
        DateTime.now().subtract(Duration(days: _yearOffset * 365));
    final year = currentDate.year;
    // If index is after December (7), it's the next year
    return index > 7 ? (year + 1).toString() : year.toString();
  }

  // Helper function to format step counts
  String _formatSteps(double steps) {
    return NumberFormat('#,###').format(steps.round());
  }

  // Calculate total steps for current day
  double getDayTotal() {
    if (_selectedPeriod == 'Day') {
      final dayData = periodData['Day']!;
      return dayData.reduce((sum, value) => sum + value);
    }
    return 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_selectedPeriod == 'Month') {
      if (details.primaryVelocity! < 0) {
        // Swipe left - go to next month
        setState(() {
          _monthOffset++;
          _currentViewDate =
              DateTime.now().subtract(Duration(days: _monthOffset * 30));
        });
      } else if (details.primaryVelocity! > 0) {
        // Swipe right - go to previous month
        if (_monthOffset > 0) {
          setState(() {
            _monthOffset--;
            _currentViewDate =
                DateTime.now().subtract(Duration(days: _monthOffset * 30));
          });
        }
      }
    } else if (_selectedPeriod == 'Day') {
      if (details.primaryVelocity! < 0) {
        // Swipe left - go forward in time
        if (_dayOffset > 0) {
          setState(() {
            _dayOffset--;
            _currentViewDate =
                DateTime.now().subtract(Duration(days: _dayOffset));
          });
        }
      } else if (details.primaryVelocity! > 0) {
        // Swipe right - go back in time
        setState(() {
          _dayOffset++;
          _currentViewDate =
              DateTime.now().subtract(Duration(days: _dayOffset));
        });
      }
    } else if (_selectedPeriod == 'Week') {
      if (details.primaryVelocity! < 0) {
        // Swipe left - go forward in time
        if (_weekOffset > 0) {
          setState(() {
            _weekOffset--;
            _currentViewDate =
                DateTime.now().subtract(Duration(days: _weekOffset * 7));
          });
        }
      } else if (details.primaryVelocity! > 0) {
        // Swipe right - go back in time
        setState(() {
          _weekOffset++;
          _currentViewDate =
              DateTime.now().subtract(Duration(days: _weekOffset * 7));
        });
      }
    } else if (_selectedPeriod == 'Year') {
      if (details.primaryVelocity! < 0) {
        // Swipe left - go forward in time
        if (_yearOffset > 0) {
          setState(() {
            _yearOffset--;
            _currentViewDate =
                DateTime.now().subtract(Duration(days: _yearOffset * 365));
          });
        }
      } else if (details.primaryVelocity! > 0) {
        // Swipe right - go back in time
        setState(() {
          _yearOffset++;
          _currentViewDate =
              DateTime.now().subtract(Duration(days: _yearOffset * 365));
        });
      }
    }
  }

  // Reset offsets when changing periods
  void updatePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      if (period != 'Month') _monthOffset = 0;
      if (period != 'Day') _dayOffset = 0;
      if (period != 'Week') _weekOffset = 0;
      if (period != 'Year') _yearOffset = 0;
      _currentViewDate = DateTime.now();
      _selectedBarIndex = null;
      _selectedBarValue = null;
    });
  }

  String getAverageText() {
    switch (_selectedPeriod) {
      case 'Day':
        final viewDate = DateTime.now().subtract(Duration(days: _dayOffset));
        final formatter = DateFormat('d MMM yyyy');
        return 'TOTAL\n${_formatSteps(getDayTotal())}\n${formatter.format(viewDate)}';
      case 'Week':
        if (_selectedBarIndex != null && _selectedBarValue != null) {
          return 'DAILY AVERAGE\n${_formatSteps(_selectedBarValue!)}\nsteps';
        } else {
          final endDate =
              DateTime.now().subtract(Duration(days: _weekOffset * 7));
          final startDate = endDate.subtract(const Duration(days: 6));
          final formatter = DateFormat('d MMM');
          final yearFormatter = DateFormat('yyyy');
          final startText = formatter.format(startDate);
          final endText =
              '${formatter.format(endDate)} ${yearFormatter.format(endDate)}';

          // Calculate weekly average from periodData['Week']
          final weekData = periodData['Week']!;
          final average = weekData.reduce((a, b) => a + b) / weekData.length;

          return 'AVERAGE\n${_formatSteps(average)}\n$startText–$endText';
        }
      case 'Month':
        final endDate = _currentViewDate;
        final startDate = endDate.subtract(const Duration(days: 29));
        final monthData = periodData['Month']!;
        final average = monthData.reduce((a, b) => a + b) / monthData.length;
        return 'AVERAGE\n${_formatSteps(average)} steps\n${startDate.day} ${_getMonthName(startDate.month)}–${endDate.day} ${_getMonthName(endDate.month)} ${endDate.year}';
      case 'Year':
        if (_selectedBarIndex != null && _selectedBarValue != null) {
          final monthName = _getMonthNameFromIndex(_selectedBarIndex!);
          final year = _getYearFromIndex(_selectedBarIndex!);
          return 'DAILY AVERAGE\n${_formatSteps(_selectedBarValue!)}\n$monthName $year';
        } else {
          final yearStart =
              DateTime.now().subtract(Duration(days: _yearOffset * 365));
          final yearEnd = yearStart.add(const Duration(days: 364));
          final formatter = DateFormat('MMM yyyy');
          final yearData = periodData['Year']!;
          final average = yearData.reduce((a, b) => a + b) / yearData.length;
          return 'DAILY AVERAGE\n${_formatSteps(average)}\n${formatter.format(yearStart)}–${formatter.format(yearEnd)}';
        }
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Steps',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBarIndex = null;
            _selectedBarValue = null;
          });
        },
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPeriodSelector(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.only(
                    top: 85, left: 20, right: 20, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: 360,
                clipBehavior: Clip.none,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_selectedBarIndex == null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -70,
                        child: Column(
                          children: [
                            Text(
                              _selectedPeriod == 'Day' ? 'TOTAL' : 'AVERAGE',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _selectedPeriod == 'Day'
                                      ? _formatSteps(periodData['Day']!
                                          .reduce((a, b) => a + b))
                                      : _formatSteps(periodData['Week']!
                                              .reduce((a, b) => a + b) /
                                          7),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'steps',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedPeriod == 'Day')
                              Column(
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    () {
                                      final date = DateTime.now()
                                          .subtract(Duration(days: _dayOffset));
                                      final today = DateTime.now();
                                      if (date.year == today.year &&
                                          date.month == today.month &&
                                          date.day == today.day) {
                                        return 'Today';
                                      } else if (date.year ==
                                              today
                                                  .subtract(
                                                      const Duration(days: 1))
                                                  .year &&
                                          date.month ==
                                              today
                                                  .subtract(
                                                      const Duration(days: 1))
                                                  .month &&
                                          date.day ==
                                              today
                                                  .subtract(
                                                      const Duration(days: 1))
                                                  .day) {
                                        return 'Yesterday';
                                      } else {
                                        final formatter = DateFormat('EEEE');
                                        return formatter.format(date);
                                      }
                                    }(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (DateTime.now()
                                          .subtract(Duration(days: _dayOffset))
                                          .day !=
                                      DateTime.now().day)
                                    Column(
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          () {
                                            final date = DateTime.now()
                                                .subtract(
                                                    Duration(days: _dayOffset));
                                            final dateFormatter =
                                                DateFormat('d MMM yyyy');
                                            return dateFormatter.format(date);
                                          }(),
                                          style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  () {
                                    if (_selectedPeriod == 'Month') {
                                      final endDate = DateTime.now().subtract(
                                          Duration(days: _monthOffset * 30));
                                      final startDate = endDate
                                          .subtract(const Duration(days: 29));

                                      // If the date range is within the same month and year
                                      if (startDate.month == endDate.month &&
                                          startDate.year == endDate.year) {
                                        return DateFormat('MMMM yyyy')
                                            .format(startDate);
                                      }

                                      // If the date range spans across months
                                      return '${startDate.day} ${DateFormat('MMM').format(startDate)} - ${endDate.day} ${DateFormat('MMM yyyy').format(endDate)}';
                                    } else if (_selectedPeriod == 'Year') {
                                      final endDate = DateTime.now().subtract(
                                          Duration(days: _yearOffset * 365));
                                      final startDate = endDate
                                          .subtract(const Duration(days: 364));

                                      // If it's the current year
                                      if (_yearOffset == 0) {
                                        return 'Year ${endDate.year}';
                                      }

                                      // For past years showing range
                                      return '${DateFormat('MMM yyyy').format(startDate)} - ${DateFormat('MMM yyyy').format(endDate)}';
                                    } else {
                                      final endDate = DateTime.now().subtract(
                                          Duration(days: _weekOffset * 7));
                                      final startDate = endDate
                                          .subtract(const Duration(days: 6));
                                      final formatter = DateFormat('d MMM');
                                      final yearFormatter = DateFormat('yyyy');
                                      final startText =
                                          formatter.format(startDate);
                                      final endText =
                                          '${formatter.format(endDate)} ${yearFormatter.format(endDate)}';
                                      return '$startText–$endText';
                                    }
                                  }(),
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 20,
                      bottom: 0,
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            backgroundColor: Colors.white,
                            alignment: BarChartAlignment.spaceAround,
                            maxY: getMaxY(),
                            minY: 0,
                            groupsSpace: 12,
                            titlesData: FlTitlesData(
                              show: true,
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (_selectedPeriod == 'Day') {
                                      if ([0, 2000, 4000, 6000]
                                          .contains(value)) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            value >= 1000
                                                ? '${(value / 1000).toStringAsFixed(0)}k'
                                                : value.toStringAsFixed(0),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (_selectedPeriod == 'Week') {
                                      final maxY = meta.max;
                                      if (maxY <= 6000) {
                                        if ([0, 2000, 4000, 6000]
                                            .contains(value)) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Text(
                                              value == 0
                                                  ? '0'
                                                  : '${(value / 1000).toStringAsFixed(0)}k',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }
                                      } else if (maxY <= 10000) {
                                        if ([0, 5000, 10000].contains(value)) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Text(
                                              value == 0
                                                  ? '0'
                                                  : '${(value / 1000).toStringAsFixed(0)}k',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if ([0, 5000, 10000, 15000]
                                            .contains(value)) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Text(
                                              value == 0
                                                  ? '0'
                                                  : '${(value / 1000).toStringAsFixed(0)}k',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else if (_selectedPeriod == 'Month') {
                                      if ([0, 5000, 10000, 15000]
                                          .contains(value)) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            value == 0
                                                ? '0'
                                                : '${(value / 1000).toStringAsFixed(0)}k',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (_selectedPeriod == 'Year') {
                                      if ([0, 2000, 4000, 6000]
                                          .contains(value)) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            value == 0
                                                ? '0'
                                                : '${(value / 1000).toStringAsFixed(0)}k',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (_selectedPeriod == 'Month') {
                                      final labels = getBottomTitles();
                                      if (index >= 0 &&
                                          index < labels.length &&
                                          labels[index].isNotEmpty) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            labels[index],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (_selectedPeriod == 'Week') {
                                      if (index >= 0 && index < 7) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            getBottomTitles()[index],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (_selectedPeriod == 'Day') {
                                      String text = '';
                                      if (index == 0) {
                                        text = '12 AM';
                                      } else if (index == 6) {
                                        text = '6';
                                      } else if (index == 12) {
                                        text = '12 PM';
                                      } else if (index == 18) {
                                        text = '6';
                                      }
                                      if (text.isNotEmpty) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (_selectedPeriod == 'Year') {
                                      if (index >= 0 && index < 12) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            getBottomTitles()[index],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: getYAxisInterval(),
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.1),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipRoundedRadius: 8,
                                tooltipMargin: 0,
                                tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                tooltipBorder:
                                    const BorderSide(color: Colors.transparent),
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()} steps',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event,
                                  BarTouchResponse? response) {
                                if (event is FlTapUpEvent &&
                                    response != null &&
                                    response.spot != null) {
                                  final index =
                                      response.spot!.touchedBarGroupIndex;
                                  final value = _selectedPeriod == 'Year'
                                      ? periodData['Year']![index]
                                      : _selectedPeriod == 'Month'
                                          ? periodData['Month']![index]
                                          : _selectedPeriod == 'Week'
                                              ? periodData['Week']![index]
                                              : periodData['Day']![index];
                                  setState(() {
                                    _selectedBarIndex = index;
                                    _selectedBarValue = value;
                                  });
                                }
                              },
                            ),
                            barGroups: _selectedPeriod == 'Month'
                                ? List.generate(
                                    30,
                                    (index) => BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: periodData['Month']![index],
                                          color: _selectedBarIndex == index
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFF2E7D32)
                                                  .withOpacity(0.7),
                                          width: 6,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ],
                                    ),
                                  )
                                : _selectedPeriod == 'Week'
                                    ? List.generate(
                                        7,
                                        (index) => BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: periodData['Week']![index],
                                              color: _selectedBarIndex == index
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFF2E7D32)
                                                      .withOpacity(0.7),
                                              width: 20,
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ],
                                        ),
                                      )
                                    : _selectedPeriod == 'Year'
                                        ? List.generate(
                                            12,
                                            (index) => BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: periodData['Year']![
                                                      index % 12],
                                                  color: _selectedBarIndex ==
                                                          index
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFF2E7D32)
                                                          .withOpacity(0.7),
                                                  width: 20,
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                              ],
                                            ),
                                          )
                                        : List.generate(
                                            24,
                                            (index) => BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: index <
                                                          periodData['Day']!
                                                              .length
                                                      ? periodData['Day']![
                                                          index]
                                                      : 0,
                                                  color: _selectedBarIndex ==
                                                          index
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFF2E7D32)
                                                          .withOpacity(0.7),
                                                  width: 8,
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                              ],
                                            ),
                                          ),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedBarIndex != null && _selectedBarValue != null)
                      Positioned(
                        left: () {
                          final barWidth = _selectedPeriod == 'Week' ||
                                  _selectedPeriod == 'Year'
                              ? 20.0
                              : _selectedPeriod == 'Month'
                                  ? 6.0
                                  : 8.0;
                          final chartWidth =
                              MediaQuery.of(context).size.width - 72.0;
                          final barsCount = _selectedPeriod == 'Month'
                              ? 30
                              : _selectedPeriod == 'Week'
                                  ? 7
                                  : _selectedPeriod == 'Year'
                                      ? 12
                                      : 24;

                          final basePosition =
                              (_selectedBarIndex! * chartWidth / barsCount) +
                                  36.0 +
                                  (barWidth / 2.0);

                          const tooltipWidth = 120.0;

                          const minLeft = 8.0;
                          final maxLeft =
                              chartWidth + 36.0 - tooltipWidth - 8.0;

                          return (basePosition - tooltipWidth / 2.0)
                              .clamp(minLeft, maxLeft);
                        }(),
                        top: -70,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    () {
                                      if (_selectedPeriod == 'Week') {
                                        return 'TOTAL';
                                      }
                                      if (_selectedPeriod == 'Month') {
                                        return 'TOTAL';
                                      }
                                      if (_selectedPeriod == 'Day') {
                                        return 'TOTAL';
                                      }
                                      return 'AVERAGE';
                                    }(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatSteps(_selectedBarValue!),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'steps',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedPeriod == 'Month' ||
                                      _selectedPeriod == 'Year' ||
                                      _selectedPeriod == 'Week' ||
                                      _selectedPeriod == 'Day')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        () {
                                          if (_selectedPeriod == 'Week') {
                                            final days = [
                                              'Sunday',
                                              'Monday',
                                              'Tuesday',
                                              'Wednesday',
                                              'Thursday',
                                              'Friday',
                                              'Saturday'
                                            ];
                                            return days[_selectedBarIndex!];
                                          }
                                          if (_selectedPeriod == 'Year') {
                                            return _getMonthNameFromIndex(
                                                _selectedBarIndex!);
                                          }
                                          if (_selectedPeriod == 'Month') {
                                            final date = DateTime.now()
                                                .subtract(Duration(
                                                    days: _monthOffset * 30))
                                                .subtract(Duration(
                                                    days: 29 -
                                                        _selectedBarIndex!));
                                            return DateFormat('d MMM yyyy')
                                                .format(date);
                                          }
                                          if (_selectedPeriod == 'Day') {
                                            final hour = _selectedBarIndex!;
                                            final nextHour = (hour + 1) % 24;
                                            final period =
                                                hour < 12 ? 'AM' : 'PM';
                                            final nextPeriod =
                                                nextHour < 12 ? 'AM' : 'PM';
                                            final displayHour = hour == 0
                                                ? 12
                                                : hour > 12
                                                    ? hour - 12
                                                    : hour;
                                            final displayNextHour =
                                                nextHour == 0
                                                    ? 12
                                                    : nextHour > 12
                                                        ? nextHour - 12
                                                        : nextHour;
                                            return '$displayHour-$displayNextHour ${hour == 11 && nextHour == 12 ? "$period-$nextPeriod" : period}';
                                          }
                                          final endDate = DateTime.now()
                                              .subtract(Duration(
                                                  days: _monthOffset * 30));
                                          final startDate = endDate.subtract(
                                              const Duration(days: 29));

                                          // If the date range is within the same month and year
                                          if (startDate.month ==
                                                  endDate.month &&
                                              startDate.year == endDate.year) {
                                            return DateFormat('MMMM yyyy')
                                                .format(startDate);
                                          }

                                          // If the date range spans across months
                                          return '${startDate.day} ${DateFormat('MMM').format(startDate)} - ${endDate.day} ${DateFormat('MMM yyyy').format(endDate)}';
                                        }(),
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Column(
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '21.4km',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[200],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 2),
                        const Text(
                          '1,200',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Steps',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[200],
                    ),
                    const Column(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '2h, 14m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Colors.blue[600],
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                              Text(
                                'Last Week',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '1,200',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.01),
                                  Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.028,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Best from last week',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.025,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Colors.green[600],
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                              Text(
                                'Progress',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '1,200',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.01),
                                  Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.028,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Higher than last week',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.025,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                color: Colors.orange[600],
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
                              Text(
                                'Target',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '1,200',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.01),
                                  Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.028,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '2,500 steps to your target',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.025,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDailyTip(),
              const SizedBox(height: 16),
              StepsGoalCard(
                currentSteps: widget.currentSteps,
                goalSteps: context.watch<StepGoalProvider>().goalSteps,
                isGoalEnabled: _isGoalEnabled,
                isEditable: true,
                onEdit: _showStepGoalDialog,
                onToggle: (value) => setState(() => _isGoalEnabled = value),
              ),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              // Fun Fact Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star_border_rounded,
                            color: Colors.blue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fun Fact',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Did you know? Walking 10,000 steps a day can help improve your heart health and boost your mood!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue[400],
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline_rounded),
                  activeIcon: Icon(Icons.favorite_rounded),
                  label: 'Health',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group_rounded),
                  label: 'Friends',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPeriodButton('D'),
          _buildPeriodButton('W'),
          _buildPeriodButton('M'),
          _buildPeriodButton('Y'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = (_selectedPeriod == 'Day' && period == 'D') ||
        (_selectedPeriod == 'Week' && period == 'W') ||
        (_selectedPeriod == 'Month' && period == 'M') ||
        (_selectedPeriod == 'Year' && period == 'Y');

    return Expanded(
      child: GestureDetector(
        onTap: () => updatePeriod(period == 'D'
            ? 'Day'
            : period == 'W'
                ? 'Week'
                : period == 'M'
                    ? 'Month'
                    : period == 'Y'
                        ? 'Year'
                        : 'Month'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildStatCard('Distance', '2.1', 'km')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Calories', '180', 'kcal')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Duration', '35', 'min')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Avg. Pace', '17', 'min/km')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tips_and_updates,
              color: Colors.blue[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try taking the stairs instead of the elevator to increase your daily step count.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateYearlyAverage() {
    if (_selectedPeriod == 'Year' && periodData['Year'] != null) {
      final yearData = periodData['Year']!;
      return yearData.reduce((a, b) => a + b) / yearData.length;
    }
    return 0;
  }

  List<int> _calculateMonthLabelPositions(int currentDay, int daysInMonth) {
    final positions = <int>[];
    final targetDays = [7, 16, 23, 31];
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    for (int i = 0; i < 30; i++) {
      final date = startDate.add(Duration(days: i));
      final day = date.day;
      if (targetDays.contains(day)) {
        positions.add(i);
      }
    }
    return positions;
  }

  double getMaxY() {
    switch (_selectedPeriod) {
      case 'Day':
        return 6000;
      case 'Week':
        final weekData = periodData['Week']!;
        final maxSteps =
            weekData.reduce((max, value) => max > value ? max : value);
        if (maxSteps <= 6000) return 6000;
        if (maxSteps <= 10000) return 10000;
        return 15000;
      case 'Month':
        final monthData = periodData['Month']!;
        final maxSteps =
            monthData.reduce((max, value) => max > value ? max : value);
        return maxSteps <= 10000 ? 10000 : 15000;
      case 'Year':
        final yearData = periodData['Year']!;
        final maxSteps =
            yearData.reduce((max, value) => max > value ? max : value);
        return maxSteps <= 4000 ? 4000 : 6000;
    }
    return 4000;
  }

  double getYAxisInterval() {
    if (_selectedPeriod == 'Day') {
      return 2000;
    } else if (_selectedPeriod == 'Week') {
      final maxY = getMaxY();
      if (maxY <= 6000) return 2000;
      if (maxY <= 10000) return 5000;
      return 5000;
    } else if (_selectedPeriod == 'Month') {
      return 5000;
    } else if (_selectedPeriod == 'Year') {
      return 2000;
    }
    return 200;
  }

  List<String> getBottomTitles() {
    switch (_selectedPeriod) {
      case 'Day':
        return [
          '12 AM',
          '',
          '',
          '',
          '',
          '',
          '6',
          '',
          '',
          '',
          '',
          '',
          '12 PM',
          '',
          '',
          '',
          '',
          '',
          '6',
          '',
          '',
          '',
          '',
          ''
        ];
      case 'Week':
        return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      case 'Month':
        List<String> dates = List.filled(30, '');
        final endDate = _currentViewDate;
        final startDate = endDate.subtract(const Duration(days: 29));
        final positions = _calculateMonthLabelPositions(
            endDate.day, DateTime(endDate.year, endDate.month + 1, 0).day);
        for (int i = 0; i < 30; i++) {
          if (positions.contains(i)) {
            final date = startDate.add(Duration(days: i));
            dates[i] = date.day.toString();
          }
        }
        return dates;
      case 'Year':
        return ['M', 'J', 'J', 'A', 'S', 'O', 'N', 'D', 'J', 'F', 'M', 'A'];
    }
    return [];
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showStepGoalDialog() {
    final stepGoalProvider = context.read<StepGoalProvider>();
    int tempGoalSteps = stepGoalProvider.goalSteps;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set Step Goal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (tempGoalSteps > 1000) {
                              setState(() => tempGoalSteps -= 1000);
                            }
                          },
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$tempGoalSteps steps',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => tempGoalSteps += 1000);
                          },
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          stepGoalProvider.setGoal(tempGoalSteps);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Step goal updated!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Set Goal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
