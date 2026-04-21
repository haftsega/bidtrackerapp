import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/bid_model.dart';
import 'bid_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your bids. You cannot undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Hive.box<Bid>('bidsBox').clear();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Bid Tracker Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Reset All Data',
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Bid>('bidsBox').listenable(),
        builder: (context, Box<Bid> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No bids tracked yet. Tap + to add!'),
            );
          }

          int completedBids = box.values
              .where((bid) => bid.progress == 1.0)
              .length;
          int pendingBids = box.values.length - completedBids;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSummaryCard(
                      'Pending',
                      pendingBids,
                      Colors.orangeAccent,
                      Icons.hourglass_empty,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      'Finished',
                      completedBids,
                      Colors.teal,
                      Icons.check_circle_outline,
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        const Text(
                          'Overall Task Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 35,
                              sections: [
                                if (completedBids > 0)
                                  PieChartSectionData(
                                    color: Colors.teal,
                                    value: completedBids.toDouble(),
                                    title: '$completedBids\nDone',
                                    radius: 65,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (pendingBids > 0)
                                  PieChartSectionData(
                                    color: Colors.orangeAccent,
                                    value: pendingBids.toDouble(),
                                    title: '$pendingBids\nPending',
                                    radius: 65,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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

                const SizedBox(height: 20),

                const Text(
                  'Registered Bids',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final bid = box.getAt(index)!;
                    final isFinished = bid.progress == 1.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BidDetailScreen(bid: bid),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isFinished
                                ? Colors.teal.withOpacity(0.2)
                                : Colors.orangeAccent.withOpacity(0.2),
                            child: Icon(
                              isFinished ? Icons.check : Icons.assignment,
                              color: isFinished
                                  ? Colors.teal
                                  : Colors.orangeAccent,
                            ),
                          ),
                          title: Text(
                            bid.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(bid.deadline),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isFinished
                                    ? 'Finished'
                                    : '${(bid.progress * 100).toInt()}% Docs',
                                style: TextStyle(
                                  color: isFinished
                                      ? Colors.teal
                                      : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Bid?'),
                                      content: Text(
                                        'Are you sure you want to delete "${bid.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            box.deleteAt(index);
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),

      // --- FIX: PADDING WRAPPER TO REMOVE UNNECESSARY GAP ---
      floatingActionButton: Transform.translate(
        // Adjust the '16' up or down to get the exact pixel spacing you want!
        offset: const Offset(0, 16),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New Bid'),
          onPressed: () => Navigator.pushNamed(context, '/add_bid'),
        ),
      ),

      // ------------------------------------------------------
      bottomNavigationBar: SafeArea(
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
          ),
        ),
      ),
    );
  }
}
