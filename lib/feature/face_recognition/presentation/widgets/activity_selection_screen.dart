import 'package:flutter/material.dart';

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({super.key});

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select an Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Recent activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActivityChip(label: 'Potions', color: Colors.red),
              ActivityChip(label: 'Charms', color: Colors.lightBlue),
              ActivityChip(label: 'Divination', color: Colors.purple),
              ActivityChip(label: 'Herbology', color: Colors.green),
            ],
          ),
          SizedBox(height: 16),
          Text('All activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              children: [
                ListTile(title: Text('Charms')),
                ListTile(title: Text('Divination')),
                ListTile(title: Text('Herbology')),
                ListTile(title: Text('Potions')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityChip extends StatelessWidget {
  final String label;
  final Color color;

  const ActivityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
