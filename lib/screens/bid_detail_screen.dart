import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/bid_model.dart';
import 'edit_bid_screen.dart'; // Connects to the new edit screen

class BidDetailScreen extends StatefulWidget {
  final Bid bid;

  const BidDetailScreen({Key? key, required this.bid}) : super(key: key);

  @override
  _BidDetailScreenState createState() => _BidDetailScreenState();
}

class _BidDetailScreenState extends State<BidDetailScreen> {
  // Updates the database when you click a checkbox OR delete an item
  void _updateProgress() {
    final box = Hive.box<Bid>('bidsBox');
    box.put(widget.bid.key, widget.bid);
    setState(() {}); // Refreshes the UI progress bar
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.bid.progress == 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bid.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // --- NEW EDIT BUTTON ---
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Bid',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBidScreen(bid: widget.bid),
                ),
              ).then((_) {
                // When we return from the edit screen, refresh this page to show the new data!
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.event, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat(
                        'EEEE, MMM dd, yyyy - hh:mm a',
                      ).format(widget.bid.deadline),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.alarm, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Alert: ${widget.bid.reminderMinutesBefore == 0 ? "At deadline time" : "${widget.bid.reminderMinutesBefore} mins before"}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: widget.bid.progress,
                      backgroundColor: Colors.grey[300],
                      color: isFinished ? Colors.teal : Colors.blueAccent,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFinished
                          ? 'All requirements met!'
                          : '${(widget.bid.progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFinished ? Colors.teal : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- HEADER WITH HINT TEXT ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Required Documents',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Slide right to delete ➔',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Divider(),

            // --- CHECKLIST AREA WITH SLIDE-TO-DELETE ---
            Expanded(
              child: ListView.builder(
                itemCount: widget.bid.requirements.length,
                itemBuilder: (context, index) {
                  final req = widget.bid.requirements[index];

                  return Dismissible(
                    // Unique key based on requirement name and index
                    key: ValueKey('${req.name}_$index'),

                    // Force swipe to be left-to-right
                    direction: DismissDirection.startToEnd,

                    // Red background revealed on swipe
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Triggered when swipe is complete
                    onDismissed: (direction) {
                      setState(() {
                        // 1. Remove from the list
                        widget.bid.requirements.removeAt(index);
                      });

                      // 2. Save to Hive and update progress bar
                      _updateProgress();

                      // 3. Show confirmation popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${req.name} removed'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },

                    // Your existing UI inside the Dismissible
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        title: Text(
                          req.name,
                          style: TextStyle(
                            decoration: req.isUploaded
                                ? TextDecoration.lineThrough
                                : null,
                            color: req.isUploaded ? Colors.grey : Colors.black,
                          ),
                        ),
                        value: req.isUploaded,
                        activeColor: Colors.teal,
                        onChanged: (bool? value) {
                          setState(() {
                            req.isUploaded = value ?? false;
                          });
                          _updateProgress();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
