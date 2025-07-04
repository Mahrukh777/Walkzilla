import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class HeartRateScreen extends StatelessWidget {
  final int currentBpm;
  final int lowestBpm;
  final int highestBpm;
  final int yesterdayBpm;
  final int challengeProgress; // percent

  const HeartRateScreen({
    super.key,
    this.currentBpm = 80,
    this.lowestBpm = 65,
    this.highestBpm = 110,
    this.yesterdayBpm = 82,
    this.challengeProgress = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Heart Rate',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Heart Rate Circular Indicator
              Center(
                child: CircularPercentIndicator(
                  radius: 85.0,
                  lineWidth: 10.0,
                  percent: ((currentBpm - 40) / 120)
                      .clamp(0.0, 1.0), // Clamp to [0.0, 1.0]
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.redAccent, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        currentBpm.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        'BPM',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.redAccent,
                  backgroundColor: const Color(0xFFE0E0E0),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
              const SizedBox(height: 24),
              // Today's Range Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  // No border for a cleaner look
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Range",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lowest
                        Padding(
                          padding: const EdgeInsets.only(left: 36.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Positioned(
                                top: 8.0,
                                left: -15.0,
                                child: Icon(Icons.trending_down,
                                    color: Colors.green, size: 25),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lowest',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ' $lowestBpm BPM',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Highest
                        Padding(
                          padding: const EdgeInsets.only(right: 36.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Positioned(
                                top: 8.0,
                                left: -15.0,
                                child: Icon(Icons.trending_up,
                                    color: Colors.orange, size: 25),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Highest',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ' $highestBpm BPM',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Heart Health Tip Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lightbulb,
                          color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Tip',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Staying hydrated helps regulate your heart rate naturally.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Mini Challenge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Mini Challenge',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.035,
                        vertical: MediaQuery.of(context).size.width * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Do 5 minutes of deep breathing exercises!',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.038,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // BPM Comparison
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                            left: 8, top: 4, bottom: 4, right: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            const Text('Today',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 0),
                            Text('$currentBpm BPM',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                            right: 8, top: 4, bottom: 4, left: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            const Text('Yesterday',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 0),
                            Text('$yesterdayBpm BPM',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Fun Fact Card
              Container(
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
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_border_rounded,
                          color: Colors.redAccent, size: 18),
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
                            'The average heart beats about 100,000 times every day!',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
