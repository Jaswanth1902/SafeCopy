import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Secure File Printing System - Owner Windows Application
// Main entry point for the Flutter desktop application

void main() {
  runApp(const SecurePrintOwnerApp());
}

class SecurePrintOwnerApp extends StatelessWidget {
  const SecurePrintOwnerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecurePrint - Owner',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const OwnerDashboard(title: 'SecurePrint - Print Management'),
    );
  }
}

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  // Placeholder pages
  final List<Widget> _pages = const <Widget>[
    DashboardPage(),
    PrintJobsPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.indigo[700],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.print),
                label: Text('Print Jobs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          // Main Content
          Expanded(
            child: _pages.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

// Placeholder pages - To be implemented

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.dashboard, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'Welcome to SecurePrint Owner Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage your print jobs securely',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(
                title: 'Pending Jobs',
                value: '0',
                icon: Icons.pending_actions,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Completed Today',
                value: '0',
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Total Pages',
                value: '0',
                icon: Icons.description,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrintJobsPage extends StatelessWidget {
  const PrintJobsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.print, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'Print Jobs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pending print jobs will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.history, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'Print History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your print job history will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.settings, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Printer and security settings coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Reusable Statistics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
