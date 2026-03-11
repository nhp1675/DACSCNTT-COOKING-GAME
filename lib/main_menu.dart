import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';
import 'game_screen.dart';
import 'sub_screens.dart';
import 'admin_screen.dart'; // Import màn hình Admin

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int coins = 0, stations = 2, burnLevel = 0, maxHearts = 3, unlockedIngredients = 0, cookSpeedLevel = 0;
  int maxLevel = 1; 
  bool isSoundOn = true; 
  bool isAdmin = false; // 🌟 Biến kiểm tra quyền admin
  String playerName = "Đang tải...";
  String playerAvatar = "👨‍🍳";
  String bgMusic = "bgm1.mp3";

  int dailyServes = 0, dailyEarnings = 0, dailyGames = 0;
  bool claimedQ1 = false, claimedQ2 = false, claimedQ3 = false;
  int totalServes = 0, totalEarnings = 0, totalGames = 0, totalFires = 0;
  bool ach1 = false, ach2 = false, ach3 = false, ach4 = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      String today = DateTime.now().toIso8601String().substring(0, 10); 

      if (doc.exists) {
        if (doc.data()?['lastLoginDate'] != today) {
          await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
            'lastLoginDate': today, 'dailyServes': 0, 'dailyEarnings': 0, 'dailyGames': 0,
            'claimedQ1': false, 'claimedQ2': false, 'claimedQ3': false,
          }, SetOptions(merge: true));
          _loadData(); return;
        }

        if (mounted) {
          setState(() {
            isAdmin = doc.data()?['role'] == 'admin'; // 🌟 Đọc role từ Firebase
            
            coins = doc.data()?['coins'] ?? 0;
            stations = doc.data()?['stations'] ?? 2;
            burnLevel = doc.data()?['burnLevel'] ?? 0;
            maxHearts = doc.data()?['maxHearts'] ?? 3;
            unlockedIngredients = doc.data()?['unlockedIngredients'] ?? 0; 
            cookSpeedLevel = doc.data()?['cookSpeedLevel'] ?? 0; 
            maxLevel = doc.data()?['maxLevel'] ?? 1; 
            isSoundOn = doc.data()?['isSoundOn'] ?? true; 
            
            playerName = doc.data()?['playerName'] ?? u.email!.split('@')[0];
            playerAvatar = doc.data()?['playerAvatar'] ?? "👨‍🍳";
            bgMusic = doc.data()?['bgMusic'] ?? "bgm1.mp3";

            dailyServes = doc.data()?['dailyServes'] ?? 0;
            dailyEarnings = doc.data()?['dailyEarnings'] ?? 0;
            dailyGames = doc.data()?['dailyGames'] ?? 0;
            claimedQ1 = doc.data()?['claimedQ1'] ?? false;
            claimedQ2 = doc.data()?['claimedQ2'] ?? false;
            claimedQ3 = doc.data()?['claimedQ3'] ?? false;

            totalServes = doc.data()?['totalServes'] ?? 0;
            totalEarnings = doc.data()?['totalEarnings'] ?? 0;
            totalGames = doc.data()?['totalGames'] ?? 0;
            totalFires = doc.data()?['totalFires'] ?? 0;
            ach1 = doc.data()?['ach1'] ?? false;
            ach2 = doc.data()?['ach2'] ?? false;
            ach3 = doc.data()?['ach3'] ?? false;
            ach4 = doc.data()?['ach4'] ?? false;
          });
        }
      }
    }
  }

  void _toggleSound() async {
    setState(() => isSoundOn = !isSoundOn);
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'isSoundOn': isSoundOn}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(playerAvatar, style: const TextStyle(fontSize: 60)),
                  Text('Xin chào, $playerName!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  const Text('🐾 NHÀ HÀNG THÚ CƯNG 🐾', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green)),
                  const SizedBox(height: 10),
                  Text('💰 Tiền: $coins \$', style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _btn(context, 'CHẾ ĐỘ CÀY ẢI', Icons.map, Colors.green, LevelSelectScreen(maxLevel: maxLevel, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, isSoundOn: isSoundOn, bgMusic: bgMusic, playerName: playerName, playerAvatar: playerAvatar)),
                  const SizedBox(height: 12),
                  _btn(context, 'CHẾ ĐỘ VÔ TẬN', Icons.all_inclusive, Colors.redAccent, GameScreen(isEndless: true, level: maxLevel, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, isSoundOn: isSoundOn, bgMusic: bgMusic, playerName: playerName, playerAvatar: playerAvatar)),
                  const SizedBox(height: 12),
                  
                  _btn(context, 'NHIỆM VỤ', Icons.task_alt, Colors.deepPurple, QuestScreen(dailyServes: dailyServes, dailyEarnings: dailyEarnings, dailyGames: dailyGames, claimedQ1: claimedQ1, claimedQ2: claimedQ2, claimedQ3: claimedQ3, coins: coins, onUpdate: _loadData)),
                  const SizedBox(height: 12),
                  _btn(context, 'THÀNH TỰU', Icons.emoji_events_outlined, Colors.orangeAccent, AchievementScreen(totalServes: totalServes, totalEarnings: totalEarnings, totalGames: totalGames, totalFires: totalFires, ach1: ach1, ach2: ach2, ach3: ach3, ach4: ach4, coins: coins, onUpdate: _loadData)),
                  const SizedBox(height: 12),
                  _btn(context, 'CỬA HÀNG', Icons.storefront, Colors.blueAccent, ShopScreen(coins: coins, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, onUpdate: _loadData)),
                  const SizedBox(height: 12),
                  _btn(context, 'XẾP HẠNG', Icons.emoji_events, Colors.amber, const LeaderboardScreen()),
                  const SizedBox(height: 12),
                  _btn(context, 'HƯỚNG DẪN', Icons.help_outline, Colors.teal, const TutorialScreen()),
                  const SizedBox(height: 12),
                  _btn(context, 'CÀI ĐẶT', Icons.settings, Colors.blueGrey, SettingsScreen(currentName: playerName, currentAvatar: playerAvatar, currentBgm: bgMusic, onUpdate: _loadData)),
                  const SizedBox(height: 12),

                  // 🌟 NÚT HIỂN THỊ DÀNH RIÊNG CHO ADMIN
                  if (isAdmin) ...[
                    _btn(context, 'QUẢN LÝ (ADMIN)', Icons.admin_panel_settings, Colors.red, const AdminScreen()),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white), 
                    label: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, 
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.6 > 350 ? 350 : MediaQuery.of(context).size.width * 0.6, 45), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white, width: 2))
                    ),
                    onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen())))
                  )
                ]),
              ),
            ),
            Positioned(top: 10, right: 10, child: IconButton(icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off, size: 35, color: isSoundOn ? Colors.green : Colors.grey), onPressed: _toggleSound)),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData icon, Color c, Widget p) {
    double btnWidth = MediaQuery.of(context).size.width * 0.6;
    if (btnWidth > 350) btnWidth = 350; 

    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(t, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: c, 
        minimumSize: Size(btnWidth, 45), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
          side: const BorderSide(color: Colors.white, width: 2)
        )
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => p)).then((_) => _loadData()),
    );
  }
}