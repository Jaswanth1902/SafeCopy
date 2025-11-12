import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/print_screen.dart';
import 'services/decryption_service.dart';
import 'services/printer_service.dart';
import 'services/api_service.dart';

// Secure File Printing System - Owner Desktop Application
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SecurePrint - Print Files Securely'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Initialize services
  late final DecryptionService _decryptionService;
  late final PrinterService _printerService;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _decryptionService = DecryptionService();
    _printerService = PrinterService();
    _apiService = ApiService(baseUrl: 'http://localhost:5000');
  }

  // Pages
  late final List<Widget> _pages = <Widget>[
    HomePage(),
    MultiProvider(
      providers: [
        Provider<DecryptionService>.value(value: _decryptionService),
        Provider<PrinterService>.value(value: _printerService),
        Provider<ApiService>.value(value: _apiService),
      ],
      child: const PrintScreen(),
    ),
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
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print),
            label: 'Print',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ========================================
// HOME PAGE
// ========================================

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 32),
          const Text(
            'Welcome to SecurePrint',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Securely receive and print files from your team',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How It Works:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStep(
                  '1',
                  'Receive File ID',
                  'Get a unique file ID from team member',
                ),
                const SizedBox(height: 12),
                _buildStep(
                  '2',
                  'Download & Decrypt',
                  'Files are decrypted locally on your device',
                ),
                const SizedBox(height: 12),
                _buildStep(
                  '3',
                  'Print Securely',
                  'Print to your local printer',
                ),
                const SizedBox(height: 12),
                _buildStep(
                  '4',
                  'Auto-Delete',
                  'Files automatically deleted from server',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================
// HISTORY PAGE
// ========================================

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.history, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Print History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ========================================
// SETTINGS PAGE
// ========================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.settings, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Settings coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
