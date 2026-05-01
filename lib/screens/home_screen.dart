import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'section1_screen.dart';
import 'section2_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  String _expiry = '';
  int _todayMinutes = 0;
  DateTime? _trainingStartTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _expiry = prefs.getString('expiry') ?? '';
      final today = _formatDate(DateTime.now());
      _todayMinutes = (prefs.getInt('training_$today') ?? 0) ~/ 60000;
    });
    _checkExpiry();
    _syncTrainingFromCloud();
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _checkExpiry() async {
    if (_isExpired(_expiry)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  bool _isExpired(String expiry) {
    if (expiry.isEmpty) return true;
    if (expiry == '永久') return false;
    try {
      final fmt = expiry.length > 10 ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd';
      final expiryDate = DateTime.parse(expiry);
      return expiryDate.isBefore(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  String _getDaysLeft() {
    if (_expiry == '永久') return '永久';
    if (_expiry.isEmpty) return '已过期';
    try {
      final fmt = _expiry.length > 10 ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd';
      final expiryDate = DateTime.parse(_expiry);
      final diff = expiryDate.difference(DateTime.now()).inDays;
      if (diff > 0) return '$diff天';
      if (diff == 0) return '今天到期';
      return '已过期';
    } catch (_) {
      return '已过期';
    }
  }

  Future<void> _syncTrainingFromCloud() async {
    if (_username.isEmpty) return;
    final today = _formatDate(DateTime.now());
    final cloudTotal = await ApiService.fetchTraining(_username, today);
    if (cloudTotal > 0 && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getInt('training_$today') ?? 0;
      if (cloudTotal > local) {
        await prefs.setInt('training_$today', cloudTotal);
        setState(() => _todayMinutes = cloudTotal ~/ 60000);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视力训练'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '剩余时间: ${_getDaysLeft()}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('今日训练时长', style: TextStyle(fontSize: 16, color: Colors.purple)),
                  const SizedBox(height: 8),
                  Text(
                    '$_todayMinutes 分钟',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  _buildButton(
                    '光栅训练',
                    '视光训练模块',
                    Icons.pattern,
                    Colors.pink,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Section1Screen())),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    '在线播放器',
                    '动画片播放',
                    Icons.play_circle,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Section2Screen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onPause() {
    super.onPause();
    _stopTraining();
  }

  @override
  void onResume() {
    super.onResume();
    _startTraining();
  }

  void _startTraining() {
    _trainingStartTime = DateTime.now();
  }

  Future<void> _stopTraining() async {
    if (_trainingStartTime != null) {
      final duration = DateTime.now().difference(_trainingStartTime!).inMilliseconds;
      final today = _formatDate(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getInt('training_$today') ?? 0;
      await prefs.setInt('training_$today', existing + duration);
      await ApiService.syncTraining(_username, today, duration);
      _trainingStartTime = null;
      if (mounted) setState(() => _todayMinutes = (existing + duration) ~/ 60000);
    }
  }
}