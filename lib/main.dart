import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'firebase_options.dart'; 
import 'dart:async';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Lỗi Firebase: $e");
  }
  runApp(const HappyPetShopApp());
}

class HappyPetShopApp extends StatelessWidget {
  const HappyPetShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Comic Sans MS',
        scaffoldBackgroundColor: const Color(0xFFE8F5E9), 
      ),
      home: FirebaseAuth.instance.currentUser == null ? const AuthScreen() : const MainMenu(),
    );
  }
}

// --- MÀN HÌNH ĐĂNG NHẬP ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool isLogin = true;

  Future<void> _auth() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'playerName': 'Đầu Bếp ${Random().nextInt(9999)}',
          'playerAvatar': '👨‍🍳',
          'bgMusic': 'bgm1.mp3'
        }, SetOptions(merge: true));
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
        );
        UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);
        
        if (cred.additionalUserInfo?.isNewUser ?? false) {
           await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'playerName': cred.user!.displayName ?? 'Đầu Bếp',
            'playerAvatar': '👨‍🍳',
            'bgMusic': 'bgm1.mp3'
          }, SetOptions(merge: true));
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi Google Login: $e"), backgroundColor: Colors.red));
    }
  }  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFFFCA28)])),
        child: Center(
          child: SingleChildScrollView( 
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🐾 NHÀ HÀNG THÚ CƯNG', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _auth, icon: Icon(isLogin ? Icons.login : Icons.person_add, color: Colors.white),
                    label: Text(isLogin ? 'MỞ CỬA TIỆM' : 'ĐĂNG KÝ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 45)), 
                  ),
                  TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập')),
                  const Divider(thickness: 1, color: Colors.grey),
                  const Text("HOẶC", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 30),
                    label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.white),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- MENU CHÍNH ---
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int coins = 0, stations = 2, burnLevel = 0, maxHearts = 3, unlockedIngredients = 0, cookSpeedLevel = 0;
  bool isSoundOn = true; 
  String playerName = "Đang tải...";
  String playerAvatar = "👨‍🍳";
  String bgMusic = "bgm1.mp3";

  // Nhiệm vụ ngày
  int dailyServes = 0, dailyEarnings = 0, dailyGames = 0;
  bool claimedQ1 = false, claimedQ2 = false, claimedQ3 = false;

  // Thành Tựu
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
            coins = doc.data()?['coins'] ?? 0;
            stations = doc.data()?['stations'] ?? 2;
            burnLevel = doc.data()?['burnLevel'] ?? 0;
            maxHearts = doc.data()?['maxHearts'] ?? 3;
            unlockedIngredients = doc.data()?['unlockedIngredients'] ?? 0; 
            cookSpeedLevel = doc.data()?['cookSpeedLevel'] ?? 0; 
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
    if (u != null) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'isSoundOn': isSoundOn}, SetOptions(merge: true));
    }
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
                  
                  _btn(context, 'BẮT ĐẦU', Icons.play_arrow, Colors.green, LevelSelectScreen(stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, isSoundOn: isSoundOn, bgMusic: bgMusic, playerName: playerName, playerAvatar: playerAvatar)),
                  const SizedBox(height: 12),
                  
                  _btn(context, 'NHIỆM VỤ', Icons.task_alt, Colors.deepPurple, QuestScreen(
                    dailyServes: dailyServes, dailyEarnings: dailyEarnings, dailyGames: dailyGames,
                    claimedQ1: claimedQ1, claimedQ2: claimedQ2, claimedQ3: claimedQ3, coins: coins, onUpdate: _loadData
                  )),
                  const SizedBox(height: 12),

                  _btn(context, 'THÀNH TỰU', Icons.emoji_events_outlined, Colors.orangeAccent, AchievementScreen(
                    totalServes: totalServes, totalEarnings: totalEarnings, totalGames: totalGames, totalFires: totalFires,
                    ach1: ach1, ach2: ach2, ach3: ach3, ach4: ach4, coins: coins, onUpdate: _loadData
                  )),
                  const SizedBox(height: 12),
                  
                  _btn(context, 'CỬA HÀNG', Icons.storefront, Colors.blueAccent, ShopScreen(coins: coins, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, onUpdate: _loadData)),
                  const SizedBox(height: 12),
                  
                  _btn(context, 'XẾP HẠNG', Icons.emoji_events, Colors.amber, const LeaderboardScreen()),
                  const SizedBox(height: 12),

                  _btn(context, 'HƯỚNG DẪN', Icons.help_outline, Colors.teal, const TutorialScreen()),
                  const SizedBox(height: 12),
                  
                  _btn(context, 'CÀI ĐẶT', Icons.settings, Colors.blueGrey, SettingsScreen(currentName: playerName, currentAvatar: playerAvatar, currentBgm: bgMusic, onUpdate: _loadData)),
                  const SizedBox(height: 20),
                  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white), label: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen())))
                  )
                ]),
              ),
            ),
            
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off, size: 35, color: isSoundOn ? Colors.green : Colors.grey),
                onPressed: _toggleSound,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData icon, Color c, Widget p) => ElevatedButton.icon(
    icon: Icon(icon, color: Colors.white),
    label: Text(t, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(backgroundColor: c, minimumSize: const Size(280, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white, width: 2))),
    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => p)).then((_) => _loadData()),
  );
}

// --- MÀN HÌNH CÀI ĐẶT ---
class SettingsScreen extends StatefulWidget {
  final String currentName;
  final String currentAvatar;
  final String currentBgm;
  final VoidCallback onUpdate;

  const SettingsScreen({super.key, required this.currentName, required this.currentAvatar, required this.currentBgm, required this.onUpdate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late String _selectedAvatar;
  late String _selectedBgm;

  final List<String> _avatars = ['👨‍🍳', '👩‍🍳', '🐼', '🦊', '🐱', '🐶', '🐯', '🐰', '🐸'];
  final List<Map<String, String>> _musicTracks = [
    {'name': 'Nhạc Vui Nhộn 1', 'file': 'bgm1.mp3'},
    {'name': 'Nhạc Thư Giãn 2', 'file': 'bgm2.mp3'},
    {'name': 'Nhạc Sôi Động 3', 'file': 'bgm3.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedAvatar = widget.currentAvatar;
    _selectedBgm = widget.currentBgm;
  }

  void _saveSettings() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'playerName': _nameController.text.trim().isEmpty ? "Đầu Bếp" : _nameController.text.trim(),
        'playerAvatar': _selectedAvatar,
        'bgMusic': _selectedBgm,
      }, SetOptions(merge: true));
      
      widget.onUpdate(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu cài đặt! ✅"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CÀI ĐẶT HỒ SƠ'), backgroundColor: Colors.blueGrey),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ĐỔI TÊN HIỂN THỊ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.person),
            ),
            maxLength: 15,
          ),
          const SizedBox(height: 20),

          const Text("CHỌN AVATAR:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _avatars.map((av) => GestureDetector(
              onTap: () => setState(() => _selectedAvatar = av),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _selectedAvatar == av ? Colors.amberAccent : Colors.white,
                  border: Border.all(color: _selectedAvatar == av ? Colors.orange : Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(av, style: const TextStyle(fontSize: 32)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 30),

          const Text("CHỌN NHẠC NỀN:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBgm,
                isExpanded: true,
                items: _musicTracks.map((track) {
                  return DropdownMenuItem<String>(
                    value: track['file'],
                    child: Text(track['name']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBgm = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('LƯU CÀI ĐẶT', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }
}

// --- MÀN HÌNH HƯỚNG DẪN ---
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HƯỚNG DẪN CHƠI'), 
        backgroundColor: Colors.teal,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _guideCard('🍳 1. CÁCH NẤU ĂN', 'Kéo thả nguyên liệu từ thực đơn bên dưới lên các "Đĩa trống" để nấu. Đợi đến khi món ăn báo "✨ CHÍN!" thì kéo món ăn đó đưa cho bé thú cưng đang yêu cầu.'),
          _guideCard('🗑️ 2. BỎ ĐỒ CHÁY', 'Nếu bạn quên lấy đồ ăn ra, nó sẽ bị khét ("💥 VỨT ĐI!"). Lúc này, đĩa bị kẹt và bạn phải kéo đĩa đồ ăn hỏng đó bỏ vào Thùng Rác (🗑️) để dọn chỗ nấu món mới.'),
          _guideCard('🧯 3. DẬP LỬA', 'Nếu để đồ ăn khét trên bếp quá lâu, bếp sẽ bốc cháy (🔥). Nhanh tay kéo Bình Chữa Cháy (🧯) thả vào bếp, hoặc nhấn chạm vào bếp đang cháy để dập lửa trước khi mất mạng!'),
          _guideCard('👑 4. KHÁCH VIP & COMBO', 'Phục vụ khách hàng liên tục không nghỉ để kích hoạt thanh COMBO, giúp nhân 2, nhân 3 số tiền nhận được. Đặc biệt lưu ý Khách VIP (có vương miện 👑) trả cực kỳ nhiều tiền nhưng họ hết kiên nhẫn rất nhanh.'),
          _guideCard('❤️ 5. SINH MỆNH (TIM)', 'Bạn có số lượng Tim giới hạn. Mỗi lần để khách bỏ đi vì đợi quá lâu, đưa sai món ăn, hoặc để bếp cháy rụi không dập lửa kịp, bạn sẽ bị trừ 1 Tim. Hết Tim là kết thúc ca làm việc!'),
          const SizedBox(height: 20),
          const Center(
            child: Text('Chúc bạn kinh doanh hồng phát! 🐾', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          )
        ],
      ),
    );
  }

  Widget _guideCard(String title, String desc) {
    return Card(
      elevation: 4, 
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.teal, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH NHIỆM VỤ NGÀY ---
class QuestScreen extends StatelessWidget {
  final int dailyServes, dailyEarnings, dailyGames, coins;
  final bool claimedQ1, claimedQ2, claimedQ3;
  final VoidCallback onUpdate;

  const QuestScreen({super.key, required this.dailyServes, required this.dailyEarnings, required this.dailyGames, required this.claimedQ1, required this.claimedQ2, required this.claimedQ3, required this.coins, required this.onUpdate});

  void _claimReward(BuildContext context, String claimField, int reward) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'coins': coins + reward,
      claimField: true,
    }, SetOptions(merge: true));
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhận thành công $reward \$! 🥳"), backgroundColor: Colors.green));
    onUpdate();
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NHIỆM VỤ HÀNG NGÀY'), backgroundColor: Colors.deepPurple,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Hoàn thành nhiệm vụ mỗi ngày để nhận thưởng lớn nhé!", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _questCard(context, 'Phục vụ 15 vị khách', dailyServes, 15, 100, claimedQ1, 'claimedQ1'),
          _questCard(context, 'Kiếm được 1000 \$', dailyEarnings, 1000, 150, claimedQ2, 'claimedQ2'),
          _questCard(context, 'Chơi hoàn thành 3 ván', dailyGames, 3, 50, claimedQ3, 'claimedQ3'),
        ],
      ),
    );
  }

  Widget _questCard(BuildContext context, String title, int current, int target, int reward, bool isClaimed, String claimField) {
    double progress = (current / target).clamp(0.0, 1.0);
    bool isCompleted = current >= target;

    return Card(
      elevation: 4, margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCompleted && !isClaimed ? Colors.amber : Colors.transparent, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('🎁 $reward \$', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    color: isCompleted ? Colors.green : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${current > target ? target : current} / $target', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isCompleted && !isClaimed) ? () => _claimReward(context, claimField, reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed ? Colors.grey : (isCompleted ? Colors.amber : Colors.blueGrey),
                ),
                child: Text(isClaimed ? 'ĐÃ NHẬN' : (isCompleted ? 'NHẬN THƯỞNG' : 'CHƯA HOÀN THÀNH'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH THÀNH TỰU VĨNH VIỄN ---
class AchievementScreen extends StatelessWidget {
  final int totalServes, totalEarnings, totalGames, totalFires, coins;
  final bool ach1, ach2, ach3, ach4;
  final VoidCallback onUpdate;

  const AchievementScreen({super.key, required this.totalServes, required this.totalEarnings, required this.totalGames, required this.totalFires, required this.ach1, required this.ach2, required this.ach3, required this.ach4, required this.coins, required this.onUpdate});

  void _claimReward(BuildContext context, String claimField, int reward) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'coins': coins + reward,
      claimField: true,
    }, SetOptions(merge: true));
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chúc mừng! Nhận $reward \$! 🎉"), backgroundColor: Colors.orange));
    onUpdate();
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 THÀNH TỰU'), backgroundColor: Colors.orangeAccent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Các thành tựu này tích lũy vĩnh viễn trong suốt quá trình chơi. Cố lên nhé!", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _achieveCard(context, '🥉 Người Mới Bắt Đầu', 'Chơi tổng cộng 10 ván.', totalGames, 10, 500, ach1, 'ach1', Colors.brown[300]!),
          _achieveCard(context, '🥈 Đầu Bếp Chăm Chỉ', 'Phục vụ tổng cộng 100 khách.', totalServes, 100, 1500, ach2, 'ach2', Colors.blueGrey[300]!),
          _achieveCard(context, '🥇 Đại Gia Thú Cưng', 'Kiếm tổng cộng 10,000 \$', totalEarnings, 10000, 3000, ach3, 'ach3', Colors.amber),
          _achieveCard(context, '🧯 Lính Cứu Hỏa', 'Dập lửa thành công 20 lần.', totalFires, 20, 2000, ach4, 'ach4', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _achieveCard(BuildContext context, String title, String desc, int current, int target, int reward, bool isClaimed, String claimField, Color themeColor) {
    double progress = (current / target).clamp(0.0, 1.0);
    bool isCompleted = current >= target;

    return Card(
      elevation: 4, margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCompleted && !isClaimed ? themeColor : Colors.transparent, width: 3)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor)),
                Text('💎 $reward \$', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 5),
            Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    color: isCompleted ? themeColor : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${current > target ? target : current} / $target', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isCompleted && !isClaimed) ? () => _claimReward(context, claimField, reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed ? Colors.grey : (isCompleted ? themeColor : Colors.grey[400]),
                ),
                child: Text(isClaimed ? 'ĐÃ NHẬN' : (isCompleted ? 'NHẬN HUY CHƯƠNG' : 'CHƯA HOÀN THÀNH'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- CỬA HÀNG NÂNG CẤP (SHOP) ---
class ShopScreen extends StatelessWidget {
  final int coins, stations, burnLevel, maxHearts, unlockedIngredients, cookSpeedLevel;
  final VoidCallback onUpdate;
  const ShopScreen({super.key, required this.coins, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.cookSpeedLevel, required this.onUpdate});

  void _buy(BuildContext context, String field, int cost, int currentValue, int maxValue) async {
    if (currentValue >= maxValue) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nâng cấp tối đa!")));
      return;
    }
    if (coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn không đủ tiền!"), backgroundColor: Colors.red));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'coins': coins - cost,
      field: currentValue + 1,
    }, SetOptions(merge: true));
    onUpdate();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nâng cấp thành công! 🥳"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CỬA HÀNG (💰 $coins \$)'), backgroundColor: Colors.blueAccent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _shopCard(context, '📦 Thêm Bàn Chuẩn Bị', 'Phục vụ nhiều khách cùng lúc.', stations, 4, 1000, () => _buy(context, 'stations', 1000, stations, 4)),
        _shopCard(context, '🔥 Bếp Lò Siêu Tốc', 'Giúp thức ăn chín nhanh hơn.', cookSpeedLevel, 5, 1100, () => _buy(context, 'cookSpeedLevel', 1100, cookSpeedLevel, 5)),
        _shopCard(context, '🍳 Chảo Chống Dính', 'Kéo dài thời gian trước khi đồ ăn bị cháy.', burnLevel, 5, 800, () => _buy(context, 'burnLevel', 800, burnLevel, 5)),
        _shopCard(context, '❤️ Tăng Tim Tối Đa', 'Tăng số lần được phép mắc lỗi.', maxHearts, 6, 1500, () => _buy(context, 'maxHearts', 1500, maxHearts, 6)),
        _shopCard(context, '🛒 Thực Đơn Phong Phú', 'Mở khóa gà, tôm, sữa, trái cây...', unlockedIngredients, 4, 1200, () => _buy(context, 'unlockedIngredients', 1200, unlockedIngredients, 4)),
      ]),
    );
  }

  Widget _shopCard(BuildContext ctx, String title, String desc, int current, int max, int cost, VoidCallback onTap) {
    return Card(
      elevation: 4, margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$desc\nCấp hiện tại: $current / $max'),
        isThreeLine: true,
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.shopping_cart, size: 18),
          label: Text(current >= max ? 'MAX' : '$cost \$'),
          onPressed: current >= max ? null : onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
      ),
    );
  }
}

// --- BẢNG XẾP HẠNG ---
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOP ĐẦU BẾP'), backgroundColor: Colors.amber,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('leaderboard').orderBy('score', descending: true).limit(10).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              String name = data.containsKey('name') ? data['name'] : 'Khách';
              String avatar = data.containsKey('avatar') ? data['avatar'] : '👨‍🍳';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i == 0 ? Colors.amber : (i == 1 ? Colors.grey[300] : (i == 2 ? Colors.orange[200] : Colors.blue[100])), 
                    child: Text(i < 3 ? ['🥇','🥈','🥉'][i] : '${i + 1}')
                  ),
                  title: Row(
                    children: [
                      Text(avatar, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Text('${data['score']} \$', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- CHỌN CẤP ĐỘ ---
class LevelSelectScreen extends StatelessWidget {
  final int stations, burnLevel, maxHearts, unlockedIngredients, cookSpeedLevel; 
  final bool isSoundOn; 
  final String bgMusic, playerName, playerAvatar;
  
  const LevelSelectScreen({super.key, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.cookSpeedLevel, required this.isSoundOn, required this.bgMusic, required this.playerName, required this.playerAvatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHỌN MÀN CHƠI'), backgroundColor: Colors.green),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
        itemCount: 6,
        itemBuilder: (ctx, i) => InkWell(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (c) => GameScreen(
            level: i + 1, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, 
            unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, 
            isSoundOn: isSoundOn, bgMusic: bgMusic, playerName: playerName, playerAvatar: playerAvatar
          ))),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.greenAccent, width: 3)),
            child: Center(child: Text('LEVEL ${i + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))),
          ),
        ),
      ),
    );
  }
}

// --- MODELS TỐI ƯU ---
class PetClient {
  String itemWanted;
  String avatarAssetPath; 
  double patience = 1.0;
  bool isVip; 
  PetClient(this.itemWanted, this.avatarAssetPath, {this.isVip = false});
}

class PetItem {
  String name;
  double progress = 0;
  bool isRuined = false; 
  int ruinedTicks = 0; 
  bool isOnFire = false; 
  PetItem(this.name);
}

class FloatingScore {
  int petIndex; 
  double yOffset; 
  double opacity; 
  String text;
  Color color;
  FloatingScore(this.petIndex, this.yOffset, this.opacity, this.text, this.color);
}

// --- MÀN HÌNH GAME CHÍNH TÍCH HỢP TẤT CẢ ---
class GameScreen extends StatefulWidget {
  final int level, stations, burnLevel, maxHearts, unlockedIngredients, cookSpeedLevel; 
  final bool isSoundOn; 
  final String bgMusic, playerName, playerAvatar;
  
  const GameScreen({super.key, required this.level, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.cookSpeedLevel, required this.isSoundOn, required this.bgMusic, required this.playerName, required this.playerAvatar});
  
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  late int hearts; 
  List<PetClient?> pets = [null, null, null];
  late List<PetItem?> prepStations; 
  Timer? timer;
  
  final AudioPlayer _audio = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  bool isPaused = false; 
  int comboCount = 1; 
  double comboTimeLeft = 0.0; 
  List<FloatingScore> floatingScores = [];

  int localServes = 0;
  int localFires = 0;

  final List<String> allSupplies = ['🦴', '🐟', '🥕', '🌻', '🥩', '🥦', '🍗', '🥛', '🍤', '🍎']; 
  late List<String> activeMenu; 
  
  // MỚI: Sử dụng mảng danh sách các file ảnh thực tế của bạn
  final List<String> petAvatars = [
    'assets/images/cat.png',
    'assets/images/dog.png',
    'assets/images/elephant.png',
    'assets/images/fox.png',
    'assets/images/koala.png',
    'assets/images/zebra.png'
  ];

  @override
  void initState() {
    super.initState();
    hearts = widget.maxHearts; 
    prepStations = List.filled(widget.stations, null); 
    
    int menuSize = min(widget.level + 2 + widget.unlockedIngredients, allSupplies.length);
    activeMenu = allSupplies.sublist(0, menuSize);

    _playBGM();
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) => _gameLoop());
  }

  void _playBGM() async {
    if (widget.isSoundOn) {
      try {
        _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(AssetSource('audio/${widget.bgMusic}')); 
      } catch (e) {
        debugPrint("Thiếu file nhạc nền, bỏ qua lỗi...");
      }
    }
  }

  void _play(String file) async {
    if (!widget.isSoundOn) return; 
    try {
      if (_audio.state == PlayerState.playing) await _audio.stop();
      await _audio.play(AssetSource('audio/$file')); 
    } catch (e) {
      debugPrint("Thiếu file âm thanh, bỏ qua lỗi...");
    }
  }

  Future<void> _updateProgressToFirebase() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      var userDoc = FirebaseFirestore.instance.collection('users').doc(u.uid);
      var snap = await userDoc.get();
      int currentCoins = snap.exists ? (snap.data()?['coins'] ?? 0) : 0;
      
      await userDoc.set({
        'coins': currentCoins + score,
        'dailyServes': FieldValue.increment(localServes),
        'dailyEarnings': FieldValue.increment(score),
        'dailyGames': FieldValue.increment(1),
        'totalServes': FieldValue.increment(localServes),
        'totalEarnings': FieldValue.increment(score),
        'totalGames': FieldValue.increment(1),
        'totalFires': FieldValue.increment(localFires),
      }, SetOptions(merge: true));

      if (score > 0) {
        await FirebaseFirestore.instance.collection('leaderboard').add({
          'name': widget.playerName,
          'avatar': widget.playerAvatar,
          'score': score, 
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _saveScoreAndQuit() async {
    timer?.cancel();
    await _updateProgressToFirebase();
    if (mounted) {
      Navigator.pop(context); 
    }
  }

  void _togglePause() {
    setState(() { isPaused = true; });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⏳ TẠM DỪNG / THOÁT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        content: Text('Tiền kiếm được: $score \$\n\nBạn có muốn thoát về Menu Chọn Màn không?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text('THOÁT MÀN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(c); 
              _saveScoreAndQuit(); 
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(c); 
              setState(() => isPaused = false); 
            },
          ),
        ],
      )
    );
  }

  void _gameLoop() {
    if (isPaused) return; 

    bool needsUpdate = false;
    double burnThreshold = 1.6 + (widget.burnLevel * 0.3); 
    double currentCookSpeed = 0.012 + (widget.cookSpeedLevel * 0.003); 

    if (comboTimeLeft > 0) {
      comboTimeLeft -= 0.02; 
      needsUpdate = true;
      if (comboTimeLeft <= 0) {
        comboCount = 1; 
        comboTimeLeft = 0.0;
      }
    }

    for (int i = floatingScores.length - 1; i >= 0; i--) {
      floatingScores[i].yOffset -= 5.0; 
      floatingScores[i].opacity -= 0.05; 
      if (floatingScores[i].opacity <= 0) {
        floatingScores.removeAt(i);
      } else {
        needsUpdate = true;
      }
    }

    for (int i = 0; i < pets.length; i++) {
      if (pets[i] != null) {
        double patienceDrop = 0.003 * widget.level;
        if (pets[i]!.isVip) patienceDrop *= 1.8; 

        pets[i]!.patience -= patienceDrop;
        if (pets[i]!.patience <= 0) { 
          pets[i] = null; hearts--; _play('ohno.mp3'); HapticFeedback.vibrate(); needsUpdate = true;
        } else { needsUpdate = true; }
      } else if (Random().nextInt(40) == 1) {
        bool isVipCustomer = Random().nextInt(100) < 15; 
        pets[i] = PetClient(
          activeMenu[Random().nextInt(activeMenu.length)], 
          petAvatars[Random().nextInt(petAvatars.length)],
          isVip: isVipCustomer 
        );
        _play('bell.mp3'); needsUpdate = true;
      }
    }

    for (int i = 0; i < prepStations.length; i++) {
      var item = prepStations[i];
      if (item != null) {
        if (!item.isRuined) {
          item.progress += currentCookSpeed; 
          needsUpdate = true;
          
          if (item.progress >= 0.8 && item.progress < (0.8 + currentCookSpeed)) {
            HapticFeedback.lightImpact();
          }

          if (item.progress > burnThreshold) { 
            item.isRuined = true; _play('ohno.mp3'); HapticFeedback.heavyImpact(); 
          } 
        } else {
          item.ruinedTicks++;
          needsUpdate = true;

          if (item.ruinedTicks == 40) { 
            item.isOnFire = true; 
            _play('ohno.mp3'); 
            HapticFeedback.vibrate();
          } else if (item.ruinedTicks >= 80) { 
            hearts--; 
            _play('ohno.mp3');
            HapticFeedback.heavyImpact();
            prepStations[i] = null; 
          }
        }
      }
    }

    if (hearts <= 0) { _endGame(); needsUpdate = false; }
    if (needsUpdate && mounted) setState(() {});
  }

  void _endGame() async {
    timer?.cancel();
    await _updateProgressToFirebase(); 
    if (mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('CÁC BÉ DỖI RỒI! 😭', textAlign: TextAlign.center), 
        content: Text('Bạn đã kiếm được $score \$!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.menu, color: Colors.white),
            label: const Text('CHỌN MÀN KHÁC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(c); 
              Navigator.pop(context); 
            }
          )
        ],
      ));
    }
  }

  @override
  void dispose() { 
    timer?.cancel(); 
    _audio.dispose(); 
    _bgmPlayer.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        _togglePause(); 
        return false; 
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('DOANH THU: $score \$ | ${"❤️" * (hearts > 0 ? hearts : 0)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), 
          backgroundColor: const Color(0xFF1A1A1A), 
          iconTheme: const IconThemeData(color: Colors.amber),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: _togglePause),
          actions: [
            IconButton(icon: const Icon(Icons.pause_circle_filled, size: 30, color: Colors.blueAccent), onPressed: _togglePause),
            const SizedBox(width: 10),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF4A2F1D), Color(0xFF140D07)], 
              radius: 1.2,
              center: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                if (comboTimeLeft > 0 || comboCount > 1) 
                  Container(
                    width: double.infinity,
                    color: Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    child: Row(
                      children: [
                        Text('🔥 COMBO x$comboCount', style: TextStyle(color: comboCount >= 3 ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: comboTimeLeft,
                            backgroundColor: Colors.grey[800],
                            color: comboCount >= 3 ? Colors.redAccent : Colors.orangeAccent,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                
                SizedBox(
                  height: 140, 
                  width: screenWidth,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => _buildPetClient(i))),
                      ),
                      
                      ...floatingScores.map((fs) {
                        double xPos = (screenWidth / 3) * fs.petIndex + (screenWidth / 6) - 40;
                        return Positioned(
                          left: xPos,
                          bottom: 40 - fs.yOffset, 
                          child: Opacity(
                            opacity: fs.opacity.clamp(0.0, 1.0),
                            child: Text(
                              fs.text,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: fs.color,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                                  Shadow(color: Colors.white, blurRadius: 10, offset: Offset(0, 0)),
                                ]
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30), 
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DragTarget<PetItem>(
                      onAccept: (item) { HapticFeedback.mediumImpact(); }, 
                      builder: (ctx, _, __) => Container(
                        width: 60, height: 60, 
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.black54, 
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.withOpacity(0.8), width: 2), 
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: const Center(child: Text('🗑️', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                      ),
                    ),
                    
                    Draggable<String>(
                      data: 'extinguisher', 
                      feedback: const Material(color: Colors.transparent, child: Text('🧯', style: TextStyle(fontSize: 60))),
                      child: Container(
                        width: 60, height: 60, 
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.redAccent, 
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2), 
                          boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: const Center(child: Text('🧯', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30), 
                
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(widget.stations, (i) => _buildPrepStation(i))),
                
                const Spacer(), 
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20), 
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A), 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    border: Border(top: BorderSide(color: Colors.amber, width: 3)),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, -5))],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: activeMenu.map((m) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Draggable<String>(
                          data: m, 
                          feedback: Material(color: Colors.transparent, child: Text(m, style: const TextStyle(fontSize: 60))), 
                          child: Text(m, style: const TextStyle(fontSize: 45))
                        ),
                      )).toList()
                    ),
                  ),
                ),
              ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPetClient(int i) {
    var pet = pets[i];
    return DragTarget<PetItem>(
      onAccept: (item) { 
        if (pet != null) {
          if (item.name == pet.itemWanted && item.progress >= 0.8 && !item.isRuined) { 
            setState(() { 
              int multiplier = pet.isVip ? 3 : 1;
              int earnedMoney = (50 * multiplier) * comboCount;
              score += earnedMoney; 
              
              localServes++;
              
              floatingScores.add(FloatingScore(
                i, 0.0, 1.0, '+$earnedMoney\$', 
                pet.isVip ? Colors.amber : (comboCount >= 3 ? Colors.redAccent : Colors.greenAccent)
              ));

              if (comboCount < 5) comboCount++; 
              comboTimeLeft = 1.0; 
              pets[i] = null; 
            }); 
            _play('kaching.mp3'); 
          } else {
            setState(() { 
              hearts--; 
              _play('ohno.mp3'); 
            }); 
            HapticFeedback.heavyImpact(); 
          }
        }
      }, 
      builder: (ctx, _, __) => Container(
        width: 100, 
        decoration: BoxDecoration(
          color: pet != null && pet.isVip ? const Color(0xFFFFF8E1) : const Color(0xFFFDF5E6), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: pet != null && pet.isVip ? Colors.redAccent : Colors.amber, width: pet != null && pet.isVip ? 4 : 3),
          boxShadow: pet != null && pet.isVip 
              ? [const BoxShadow(color: Colors.amber, blurRadius: 15, spreadRadius: 2)] 
              : [const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4))],
        ),
        child: pet == null 
          ? const Center(child: Text('Đang đợi bàn...', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))) 
          : Stack( 
              clipBehavior: Clip.none,
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // MỚI: Trở lại dùng Image.asset với errorBuilder an toàn
                  Image.asset(
                    pet.avatarAssetPath, 
                    height: 50, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 5),
                  Text(pet.itemWanted, style: const TextStyle(fontSize: 24)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10), 
                    child: LinearProgressIndicator(
                      value: pet.patience, 
                      backgroundColor: Colors.grey[300],
                      color: pet.isVip ? Colors.purpleAccent : (pet.patience > 0.3 ? Colors.green : Colors.red)
                    )
                  ),
                ]),
                if (pet.isVip)
                  const Positioned(
                    top: -10, left: -10,
                    child: Text('👑', style: TextStyle(fontSize: 24)),
                  )
              ],
            ),
      ),
    );
  }

  Widget _buildPrepStation(int i) {
    var item = prepStations[i];
    double burnThreshold = 1.6 + (widget.burnLevel * 0.3); 
    double currentCookSpeed = 0.012 + (widget.cookSpeedLevel * 0.003); 
    bool isReady = item != null && item.progress >= 0.8 && !item.isRuined;
    bool isFire = item != null && item.isOnFire; 
    double size = widget.stations > 3 ? 85 : 110; 

    int secondsLeft = 0;
    if (item != null && !item.isRuined) {
      secondsLeft = ((burnThreshold - item.progress) / (currentCookSpeed * 10)).ceil();
    }

    if (isFire) {
      return GestureDetector(
        onTap: () {
          setState(() { prepStations[i] = null; localFires++; }); 
          HapticFeedback.mediumImpact();
        },
        child: DragTarget<String>(
          onAccept: (data) {
            if (data == 'extinguisher') {
              setState(() { prepStations[i] = null; localFires++; });
              HapticFeedback.mediumImpact();
            }
          },
          builder: (ctx, _, __) => Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: Colors.redAccent, 
              border: Border.all(color: Colors.yellowAccent, width: 4),
              boxShadow: [const BoxShadow(color: Colors.red, blurRadius: 15, spreadRadius: 5)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🔥', style: TextStyle(fontSize: widget.stations > 3 ? 30 : 40)),
              const Text('KÉO 🧯 VÀO\nHOẶC NHẤN', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white)),
              SizedBox(
                width: size - 40,
                child: LinearProgressIndicator(
                  value: 1.0 - ((item.ruinedTicks - 40) / 40.0).clamp(0, 1), 
                  backgroundColor: Colors.red[900],
                  color: Colors.yellow,
                ),
              )
            ]),
          ),
        ),
      );
    }

    return DragTarget<String>(
      onAccept: (m) {
        if (m == 'extinguisher') return; 
        setState(() => prepStations[i] = PetItem(m));
      },
      builder: (ctx, _, __) => Container(
        width: size, height: size, 
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: const Color(0xFFEEEEEE), 
          border: Border.all(color: item != null && item.isRuined ? Colors.red : Colors.amber, width: 4),
          boxShadow: isReady 
            ? [BoxShadow(color: secondsLeft <= 3 ? Colors.redAccent : Colors.amber, blurRadius: 20, spreadRadius: 2)] 
            : [const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 5))],
        ),
        child: item == null 
          ? const Center(child: Text('BẾP\nTRỐNG', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))) 
          : Draggable<PetItem>(
              data: item, onDragCompleted: () => setState(() => prepStations[i] = null),
              feedback: Material(color: Colors.transparent, child: Text(item.name, style: const TextStyle(fontSize: 60))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item.name, style: TextStyle(fontSize: widget.stations > 3 ? 25 : 40)),
                if (item.isRuined)
                  Column(
                    children: [
                      const Text('💥 VỨT ĐI!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.red)),
                      SizedBox(
                        width: size - 40,
                        child: LinearProgressIndicator(
                          value: (item.ruinedTicks / 40.0).clamp(0, 1), 
                          backgroundColor: Colors.grey[400],
                          color: Colors.orange, 
                        ),
                      )
                    ],
                  )
                else if (isReady)
                  Text('✨ CHÍN! (${secondsLeft}s)', style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 10, 
                    color: secondsLeft <= 3 ? Colors.red : Colors.green[800]
                  ))
                else
                  const Text('♨️ ĐANG NẤU...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54)),
                
                if (!item.isRuined) 
                  SizedBox(
                    width: size - 40, 
                    child: LinearProgressIndicator(
                      value: item.progress.clamp(0, 1), 
                      backgroundColor: Colors.grey[400], 
                      color: isReady && secondsLeft <= 3 ? Colors.red : Colors.green
                    )
                  ),
              ]),
            ),
      ),
    );
  }
}