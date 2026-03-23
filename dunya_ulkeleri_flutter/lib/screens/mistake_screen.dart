import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user.service.dart';

class MistakeScreen extends StatefulWidget {
  const MistakeScreen({super.key});

  @override
  _MistakeScreenState createState() => _MistakeScreenState();
}

class _MistakeScreenState extends State<MistakeScreen> {
  final UserService _userService = UserService();
  List<dynamic> _mistakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      final data = await _userService.getMistakes(token);
      setState(() {
        _mistakes = data;
        _isLoading = false;
      });
    }
  }

  void _removeMistake(int questionId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    bool success = await _userService.removeMistake(token!, questionId);
    if (success) {
      setState(() {
        _mistakes.removeWhere((item) => item['id'] == questionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Harika! Bu ülkeyi öğrendiniz. ✅"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📓 Hata Defterim"), centerTitle: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : _mistakes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _mistakes.length,
              itemBuilder: (context, index) {
                final item = _mistakes[index];
                return Card(
                  color: Colors.grey[900],
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      child: Icon(Icons.priority_high, color: Colors.redAccent),
                    ),
                    title: Text(
                      item['countryName'] ?? "Bilinmiyor",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "Başkent: ${item['capitalName']}\nKıta: ${item['continent']}",
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 30,
                      ),
                      tooltip: "Bunu Öğrendim",
                      onPressed: () => _removeMistake(item['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          SizedBox(height: 20),
          Text(
            "Hata Defterin Bomboş!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Şu an her şeyi mükemmel biliyorsun.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
