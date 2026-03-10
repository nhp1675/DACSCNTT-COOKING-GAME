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
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
    }
  }

  // 🌟 MỚI: Hàm xử lý Đăng nhập bằng Google
  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Cách đăng nhập tối ưu và không bị lỗi dành riêng cho Web (Netlify)
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Cách đăng nhập dành cho Android/iOS (phòng khi sau này bạn làm app)
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainMenu()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi Google Login: $e"), backgroundColor: Colors.red));
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFFFCA28)])),
        child: Center(
          child: SingleChildScrollView( // Chống tràn màn hình
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
                  
                  // NÚT ĐĂNG NHẬP BẰNG EMAIL
                  ElevatedButton.icon(
                    onPressed: _auth, 
                    icon: Icon(isLogin ? Icons.login : Icons.person_add, color: Colors.white),
                    label: Text(isLogin ? 'MỞ CỬA TIỆM' : 'ĐĂNG KÝ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 45)), 
                  ),
                  
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin), 
                    child: Text(isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập')
                  ),

                  const Divider(thickness: 1, color: Colors.grey),
                  const Text("HOẶC", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // 🌟 MỚI: NÚT ĐĂNG NHẬP BẰNG GOOGLE
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/archive/c/c1/20230822192910%21Google_%22G%22_logo.svg',
                      height: 24,
                    ),
                    label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      minimumSize: const Size(double.infinity, 45),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
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
  int coins = 0;
  int stations = 2;
  int burnLevel = 0;
  int maxHearts = 3; 
  int unlockedIngredients = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
        if (doc.exists) {
          setState(() {
            coins = doc.data()?['coins'] ?? 0;
            stations = doc.data()?['stations'] ?? 2;
            burnLevel = doc.data()?['burnLevel'] ?? 0;
            maxHearts = doc.data()?['maxHearts'] ?? 3;
            unlockedIngredients = doc.data()?['unlockedIngredients'] ?? 0; 
          });
        }
      } catch (e) {
        debugPrint("Lỗi tải dữ liệu: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🐾 NHÀ HÀNG THÚ CƯNG 🐾', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green)),
          const SizedBox(height: 10),
          Text('💰 Tiền của bạn: $coins \$', style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _btn(context, 'BẮT ĐẦU CHĂM SÓC', Icons.play_arrow, Colors.green, LevelSelectScreen(stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients)),
          const SizedBox(height: 15),
          _btn(context, 'CỬA HÀNG NÂNG CẤP', Icons.storefront, Colors.blueAccent, ShopScreen(coins: coins, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients, onUpdate: _loadData)),
          const SizedBox(height: 15),
          _btn(context, 'BẢNG XẾP HẠNG', Icons.emoji_events, Colors.amber, const LeaderboardScreen()),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white), 
            label: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen())))
          )
        ]),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData icon, Color c, Widget p) => ElevatedButton.icon(
    icon: Icon(icon, color: Colors.white),
    label: Text(t, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(backgroundColor: c, minimumSize: const Size(280, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white, width: 3))),
    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => p)).then((_) => _loadData()),
  );
}

// --- CỬA HÀNG NÂNG CẤP (SHOP) ---
class ShopScreen extends StatelessWidget {
  final int coins, stations, burnLevel, maxHearts, unlockedIngredients;
  final VoidCallback onUpdate;
  const ShopScreen({super.key, required this.coins, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.onUpdate});

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
        _shopCard(context, '📦 Thêm Bàn Chuẩn Bị', 'Giúp phục vụ nhiều khách cùng lúc.', stations, 4, 1000, () => _buy(context, 'stations', 1000, stations, 4)),
        _shopCard(context, '⏳ Tủ Lạnh Mini', 'Giúp đồ ăn lâu hỏng hơn.', burnLevel, 5, 800, () => _buy(context, 'burnLevel', 800, burnLevel, 5)),
        _shopCard(context, '❤️ Tăng Tim Tối Đa', 'Tăng số lần được phép mắc lỗi.', maxHearts, 6, 1500, () => _buy(context, 'maxHearts', 1500, maxHearts, 6)),
        _shopCard(context, '🛒 Thực Đơn Phong Phú', 'Mở khóa thêm đùi gà, tôm, sữa, trái cây...', unlockedIngredients, 4, 1200, () => _buy(context, 'unlockedIngredients', 1200, unlockedIngredients, 4)),
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

// --- CHỌN CẤP ĐỘ ---
class LevelSelectScreen extends StatelessWidget {
  final int stations, burnLevel, maxHearts, unlockedIngredients;
  const LevelSelectScreen({super.key, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHỌN MÀN CHƠI'), backgroundColor: Colors.green,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
        itemCount: 6,
        itemBuilder: (ctx, i) => InkWell(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (c) => GameScreen(level: i + 1, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, unlockedIngredients: unlockedIngredients))),
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
  PetClient(this.itemWanted, this.avatarAssetPath);
}

class PetItem {
  String name;
  double progress = 0;
  bool isRuined = false; 
  PetItem(this.name);
}

// --- MÀN HÌNH GAME CHÍNH ---
class GameScreen extends StatefulWidget {
  final int level;
  final int stations;
  final int burnLevel;
  final int maxHearts;
  final int unlockedIngredients;
  const GameScreen({super.key, required this.level, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients});
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

  final List<String> allSupplies = ['🦴', '🐟', '🥕', '🌻', '🥩', '🥦', '🍗', '🥛', '🍤', '🍎']; 
  late List<String> activeMenu; 
  
  final List<String> petAvatars = [
    'assets/images/cat.png',
    'assets/images/dog.png',
    'assets/images/elephant.png',
    'assets/images/fox.png',
    'assets/images/koala.png',
    'assets/images/zebra.png',
  ];

  @override
  void initState() {
    super.initState();
    hearts = widget.maxHearts; 
    prepStations = List.filled(widget.stations, null); 
    
    int menuSize = min(widget.level + 2 + widget.unlockedIngredients, allSupplies.length);
    activeMenu = allSupplies.sublist(0, menuSize);

    timer = Timer.periodic(const Duration(milliseconds: 100), (t) => _gameLoop());
  }

  void _play(String file) async {
    if (_audio.state == PlayerState.playing) await _audio.stop();
    await _audio.play(AssetSource('audio/$file')); 
  }

  void _gameLoop() {
    bool needsUpdate = false;
    double burnThreshold = 1.6 + (widget.burnLevel * 0.3);

    for (int i = 0; i < pets.length; i++) {
      if (pets[i] != null) {
        pets[i]!.patience -= (0.003 * widget.level);
        if (pets[i]!.patience <= 0) { 
          pets[i] = null; hearts--; _play('ohno.mp3'); HapticFeedback.vibrate(); needsUpdate = true;
        } else { needsUpdate = true; }
      } else if (Random().nextInt(40) == 1) {
        pets[i] = PetClient(activeMenu[Random().nextInt(activeMenu.length)], petAvatars[Random().nextInt(petAvatars.length)]);
        _play('bell.mp3'); needsUpdate = true;
      }
    }

    for (var item in prepStations) {
      if (item != null && !item.isRuined) {
        item.progress += 0.012;
        needsUpdate = true;
        
        if (item.progress >= 0.8 && item.progress < 0.812) {
          HapticFeedback.lightImpact();
        }

        if (item.progress > burnThreshold) { 
          item.isRuined = true; _play('ohno.mp3'); HapticFeedback.heavyImpact(); 
        } 
      }
    }

    if (hearts <= 0) { _endGame(); needsUpdate = false; }
    if (needsUpdate && mounted) setState(() {});
  }

  void _endGame() async {
    timer?.cancel();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await FirebaseFirestore.instance.collection('leaderboard').add({
        'name': u.email!.split('@')[0], 'score': score, 'timestamp': FieldValue.serverTimestamp(),
      });
      var userDoc = FirebaseFirestore.instance.collection('users').doc(u.uid);
      var snap = await userDoc.get();
      int currentCoins = snap.exists ? (snap.data()?['coins'] ?? 0) : 0;
      await userDoc.set({'coins': currentCoins + score}, SetOptions(merge: true));
    }
    if (mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
        title: const Text('CÁC BÉ DỖI RỒI!'), 
        content: Text('Bạn đã kiếm được $score \$!'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('VỀ MENU'),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)
          )
        ],
      ));
    }
  }

  @override
  void dispose() { timer?.cancel(); _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DOANH THU: $score \$ | ${"❤️" * (hearts > 0 ? hearts : 0)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), 
        backgroundColor: const Color(0xFF1A1A1A), 
        iconTheme: const IconThemeData(color: Colors.amber),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
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
              const SizedBox(height: 20),
              
              // KHU VỰC KHÁCH HÀNG (VIP LOUNGE)
              Container(
                height: 140, padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => _buildPetClient(i))),
              ),
              
              const SizedBox(height: 30), 
              
              // THÙNG RÁC
              DragTarget<PetItem>(
                onAccept: (item) { setState(() { hearts--; _play('ohno.mp3'); }); HapticFeedback.heavyImpact(); }, 
                builder: (ctx, _, __) => Container(
                  width: 60, height: 60, 
                  decoration: BoxDecoration(
                    color: Colors.black54, 
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: const Center(child: Text('🗑️', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                ),
              ),
              
              const SizedBox(height: 30), 
              
              // KHU VỰC CHẾ BIẾN (STATIONS)
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(widget.stations, (i) => _buildPrepStation(i))),
              
              const Spacer(), 
              
              // QUẦY THỨC ĂN (BUFFET COUNTER)
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
    );
  }

  Widget _buildPetClient(int i) {
    var pet = pets[i];
    return DragTarget<PetItem>(
      onAccept: (item) { 
        if (pet != null && item.name == pet.itemWanted && item.progress >= 0.8 && !item.isRuined) { 
          setState(() { score += 50; pets[i] = null; }); _play('kaching.mp3'); 
        } 
      }, 
      builder: (ctx, _, __) => Container(
        width: 100, 
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: Colors.amber, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4))],
        ),
        child: pet == null ? const Center(child: Text('Đang đợi bàn...', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(pet.avatarAssetPath, height: 45, fit: BoxFit.contain), 
          Text(pet.itemWanted, style: const TextStyle(fontSize: 24)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10), 
            child: LinearProgressIndicator(
              value: pet.patience, 
              backgroundColor: Colors.grey[300],
              color: pet.patience > 0.3 ? Colors.green : Colors.red
            )
          ),
        ]),
      ),
    );
  }

  Widget _buildPrepStation(int i) {
    var item = prepStations[i];
    bool isReady = item != null && item.progress >= 0.8 && !item.isRuined;
    double size = widget.stations > 3 ? 85 : 110; 

    return DragTarget<String>(
      onAccept: (m) => setState(() => prepStations[i] = PetItem(m)),
      builder: (ctx, _, __) => Container(
        width: size, height: size, 
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: const Color(0xFFEEEEEE), 
          border: Border.all(color: item != null && item.isRuined ? Colors.red : Colors.amber, width: 4),
          boxShadow: isReady 
            ? [const BoxShadow(color: Colors.amber, blurRadius: 20, spreadRadius: 2)] 
            : [const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 5))],
        ),
        child: item == null ? const Center(child: Text('ĐĨA\nTRỐNG', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))) : Draggable<PetItem>(
          data: item, onDragCompleted: () => setState(() => prepStations[i] = null),
          feedback: Material(color: Colors.transparent, child: Text(item.name, style: const TextStyle(fontSize: 60))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.name, style: TextStyle(fontSize: widget.stations > 3 ? 25 : 40)),
            Text(item.isRuined ? '💥 CHÁY!' : (isReady ? '✨ HOÀN HẢO!' : '♨️ ĐANG NẤU...'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: item.isRuined ? Colors.red : Colors.green[800])),
            if (!item.isRuined) SizedBox(width: size - 40, child: LinearProgressIndicator(value: item.progress.clamp(0, 1), backgroundColor: Colors.grey[400], color: Colors.green)),
          ]),
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
        title: const Text('TOP NGƯỜI CHĂM THÚ'), backgroundColor: Colors.amber,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('leaderboard').orderBy('score', descending: true).limit(10).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: CircleAvatar(backgroundColor: Colors.amber[100], child: Text('${i + 1}')),
              title: Text(docs[i]['name']),
              trailing: Text('${docs[i]['score']} \$', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          );
        },
      ),
    );
  }
}