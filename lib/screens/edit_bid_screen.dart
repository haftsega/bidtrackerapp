import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/bid_model.dart';
import '../services/notification_service.dart'; // Required for updating the alarm

class EditBidScreen extends StatefulWidget {
  final Bid bid;

  const EditBidScreen({Key? key, required this.bid}) : super(key: key);

  @override
  _EditBidScreenState createState() => _EditBidScreenState();
}

class _EditBidScreenState extends State<EditBidScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  final _newDocController = TextEditingController();

  late DateTime _selectedDeadline;
  late int _reminderMinutes;
  late List<Requirement> _requirements;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bid.title);
    _selectedDeadline = widget.bid.deadline;
    _reminderMinutes = widget.bid.reminderMinutesBefore;

    _requirements = widget.bid.requirements
        .map((req) => Requirement(name: req.name, isUploaded: req.isUploaded))
        .toList();
  }

  void _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      );
      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addCustomDocument() {
    String newDocName = _newDocController.text.trim();
    if (newDocName.isNotEmpty) {
      bool isDuplicate = _requirements.any(
        (req) => req.name.toLowerCase() == newDocName.toLowerCase(),
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This document is already in the list!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _requirements.add(Requirement(name: newDocName, isUploaded: false));
        _newDocController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _updateBid() async {
    if (_formKey.currentState!.validate()) {
      String newTitle = _titleController.text.trim();
      final box = Hive.box<Bid>('bidsBox');

      bool titleExists = box.values.any(
        (b) =>
            b.key != widget.bid.key &&
            b.title.toLowerCase() == newTitle.toLowerCase(),
      );

      if (titleExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Another bid with this name already exists!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Update the Bid object
      widget.bid.title = newTitle;
      widget.bid.deadline = _selectedDeadline;
      widget.bid.reminderMinutesBefore = _reminderMinutes;
      widget.bid.requirements = _requirements;

      // Save to Hive Database
      widget.bid.save();

      // Overwrite the old notification with the new updated time/details
      await NotificationService.scheduleDeadlineAlert(
        widget.bid.key as int,
        widget.bid.title,
        widget.bid.deadline,
        widget.bid.reminderMinutesBefore,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Bid',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Bid Title / Project Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(_selectedDeadline),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<int>(
                      value: _reminderMinutes,
                      decoration: InputDecoration(
                        labelText: 'Notification Reminder Alert',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.alarm,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('At deadline time'),
                        ),
                        DropdownMenuItem(
                          value: 15,
                          child: Text('15 minutes before'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('1 hour before'),
                        ),
                        DropdownMenuItem(
                          value: 1440,
                          child: Text('1 day before'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _reminderMinutes = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Required Documents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _requirements.length,
                      itemBuilder: (context, index) {
                        final req = _requirements[index];

                        return Dismissible(
                          key: ValueKey('${req.name}_$index'),
                          direction: DismissDirection.startToEnd,
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
                          onDismissed: (direction) {
                            setState(() {
                              _requirements.removeAt(index);
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              title: Text(
                                req.name,
                                style: TextStyle(
                                  decoration: req.isUploaded
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: req.isUploaded
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              value: req.isUploaded,
                              activeColor: Colors.teal,
                              onChanged: (bool? value) {
                                setState(() {
                                  req.isUploaded = value ?? false;
                                });
                              },
                              secondary: const Icon(
                                Icons.swipe_right,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    const Divider(thickness: 2),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newDocController,
                            decoration: InputDecoration(
                              hintText: 'Add extra document...',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blueAccent,
                            size: 40,
                          ),
                          onPressed: _addCustomDocument,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- SafeArea keeps the button above Android's home navigation gestures ---
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.update),
                  label: const Text(
                    'Update Bid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _updateBid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
