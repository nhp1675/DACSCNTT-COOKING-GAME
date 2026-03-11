import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'models.dart';

class GameScreen extends StatefulWidget {
  final bool isEndless;
  final int level, stations, burnLevel, maxHearts, unlockedIngredients, cookSpeedLevel; 
  final bool isSoundOn; 
  final String bgMusic, playerName, playerAvatar;
  
  const GameScreen({super.key, required this.isEndless, required this.level, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.cookSpeedLevel, required this.isSoundOn, required this.bgMusic, required this.playerName, required this.playerAvatar});
  
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0; late int targetScore; late int currentDifficultyLevel; 
  late int hearts; 
  List<PetClient?> pets = []; 
  late int petSlots; 
  late List<PetItem?> prepStations; 
  Timer? timer;
  
  final AudioPlayer _audio = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  bool isPaused = false; int comboCount = 1; double comboTimeLeft = 0.0; 
  List<FloatingScore> floatingScores = [];

  int localServes = 0; int localFires = 0;

  final List<String> allSupplies = ['🦴', '🐟', '🥕', '🌻', '🥩', '🥦', '🍗', '🥛', '🍤', '🍎']; 
  late List<String> activeMenu; 
  
  final List<String> petAvatars = ['assets/images/cat.png', 'assets/images/dog.png', 'assets/images/elephant.png', 'assets/images/fox.png', 'assets/images/koala.png', 'assets/images/zebra.png'];

  @override
  void initState() {
    super.initState();
    hearts = widget.maxHearts; currentDifficultyLevel = widget.level;
    targetScore = currentDifficultyLevel * 400 + 200; 

    prepStations = List.filled(widget.stations, null); 
    _updateDifficultySettings();

    _playBGM();
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) => _gameLoop());
  }

  void _updateDifficultySettings() {
    int newSlots = widget.isEndless ? 10 : min(10, 3 + (currentDifficultyLevel / 2).floor());
    
    if (pets.length != newSlots) {
      List<PetClient?> newPets = List.filled(newSlots, null);
      for (int i = 0; i < pets.length && i < newSlots; i++) {
        newPets[i] = pets[i];
      }
      pets = newPets;
      petSlots = newSlots;
    }

    int menuSize = min(currentDifficultyLevel + 2 + widget.unlockedIngredients, allSupplies.length);
    activeMenu = allSupplies.sublist(0, menuSize);
  }

  void _playBGM() async {
    if (widget.isSoundOn) {
      try { _bgmPlayer.setReleaseMode(ReleaseMode.loop); await _bgmPlayer.play(AssetSource('audio/${widget.bgMusic}')); } 
      catch (e) { debugPrint("Thiếu nhạc."); }
    }
  }

  void _play(String file) async {
    if (!widget.isSoundOn) return; 
    try { if (_audio.state == PlayerState.playing) await _audio.stop(); await _audio.play(AssetSource('audio/$file')); } 
    catch (e) { debugPrint("Thiếu file âm thanh."); }
  }

  Future<void> _updateProgressToFirebase(bool isWin) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      var userDoc = FirebaseFirestore.instance.collection('users').doc(u.uid);
      var snap = await userDoc.get();
      int currentCoins = snap.exists ? (snap.data()?['coins'] ?? 0) : 0;
      int savedMaxLevel = snap.exists ? (snap.data()?['maxLevel'] ?? 1) : 1;
      
      int newMaxLevel = savedMaxLevel;
      if (!widget.isEndless && isWin && widget.level == savedMaxLevel) newMaxLevel = savedMaxLevel + 1;

      await userDoc.set({
        'coins': currentCoins + score, 'maxLevel': newMaxLevel,
        'dailyServes': FieldValue.increment(localServes), 'dailyEarnings': FieldValue.increment(score), 'dailyGames': FieldValue.increment(1),
        'totalServes': FieldValue.increment(localServes), 'totalEarnings': FieldValue.increment(score), 'totalGames': FieldValue.increment(1), 'totalFires': FieldValue.increment(localFires),
      }, SetOptions(merge: true));

      if (score > 0) {
        await FirebaseFirestore.instance.collection('leaderboard').add({'name': widget.playerName, 'avatar': widget.playerAvatar, 'score': score, 'timestamp': FieldValue.serverTimestamp()});
      }
    }
  }

  void _saveScoreAndQuit() async {
    timer?.cancel(); await _updateProgressToFirebase(false); if (mounted) Navigator.pop(context); 
  }

  void _togglePause() {
    setState(() { isPaused = true; });
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⏳ TẠM DỪNG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        content: Text('Tiền kiếm được: $score \$\n\nBạn muốn thoát về Menu Chọn Màn?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(icon: const Icon(Icons.exit_to_app, color: Colors.white), label: const Text('THOÁT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () { Navigator.pop(c); _saveScoreAndQuit(); }),
          ElevatedButton.icon(icon: const Icon(Icons.play_arrow, color: Colors.white), label: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () { Navigator.pop(c); setState(() => isPaused = false); }),
        ],
      )
    );
  }

  void _gameLoop() {
    if (isPaused) return; 
    bool needsUpdate = false;
    double burnThreshold = 1.6 + (widget.burnLevel * 0.3); 
    double currentCookSpeed = 0.012 + (widget.cookSpeedLevel * 0.003); 

    if (widget.isEndless) {
      int dynamicLevel = (score / 1000).floor() + 1;
      if (dynamicLevel > currentDifficultyLevel) {
        currentDifficultyLevel = dynamicLevel; 
        _updateDifficultySettings(); 
        _play('bell.mp3'); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🔥 TĂNG ĐỘ KHÓ: LV $currentDifficultyLevel"), duration: const Duration(seconds: 1), backgroundColor: Colors.orange));
      }
    }

    if (comboTimeLeft > 0) {
      comboTimeLeft -= 0.02; needsUpdate = true;
      if (comboTimeLeft <= 0) { comboCount = 1; comboTimeLeft = 0.0; }
    }

    for (int i = floatingScores.length - 1; i >= 0; i--) {
      floatingScores[i].yOffset -= 5.0; floatingScores[i].opacity -= 0.05; 
      if (floatingScores[i].opacity <= 0) { floatingScores.removeAt(i); } else { needsUpdate = true; }
    }

    for (int i = 0; i < pets.length; i++) {
      if (pets[i] != null) {
        double patienceDrop = 0.0015 + (currentDifficultyLevel * 0.0005);
        if (pets[i]!.isVip) patienceDrop *= 1.5; 
        pets[i]!.patience -= patienceDrop;
        if (pets[i]!.patience <= 0) { pets[i] = null; hearts--; _play('ohno.mp3'); HapticFeedback.vibrate(); needsUpdate = true; } 
        else { needsUpdate = true; }
      } else {
        int spawnRate = max(5, 60 - (currentDifficultyLevel * 5));
        if (Random().nextInt(spawnRate) == 1) {
          bool isVipCustomer = Random().nextInt(100) < (10 + currentDifficultyLevel * 2); 
          pets[i] = PetClient(activeMenu[Random().nextInt(activeMenu.length)], petAvatars[Random().nextInt(petAvatars.length)], isVip: isVipCustomer);
          _play('bell.mp3'); needsUpdate = true;
        }
      }
    }

    for (int i = 0; i < prepStations.length; i++) {
      var item = prepStations[i];
      if (item != null) {
        if (!item.isRuined) {
          item.progress += currentCookSpeed; needsUpdate = true;
          if (item.progress >= 0.8 && item.progress < (0.8 + currentCookSpeed)) HapticFeedback.lightImpact();
          if (item.progress > burnThreshold) { item.isRuined = true; _play('ohno.mp3'); HapticFeedback.heavyImpact(); } 
        } else {
          item.ruinedTicks++; needsUpdate = true;
          if (item.ruinedTicks == 40) { item.isOnFire = true; _play('ohno.mp3'); HapticFeedback.vibrate(); } 
          else if (item.ruinedTicks >= 80) { hearts--; _play('ohno.mp3'); HapticFeedback.heavyImpact(); prepStations[i] = null; }
        }
      }
    }

    if (hearts <= 0) { 
      _endGame(false); needsUpdate = false; 
    } else if (!widget.isEndless && score >= targetScore) {
      _endGame(true); needsUpdate = false;
    }

    if (needsUpdate && mounted) setState(() {});
  }

  void _endGame(bool isWin) async {
    timer?.cancel(); await _updateProgressToFirebase(isWin); 
    if (mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isWin ? 'QUA MÀN THÀNH CÔNG!' : 'CÁC BÉ DỖI RỒI! 😭', textAlign: TextAlign.center, style: TextStyle(color: isWin ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 22)), 
        content: Text('Bạn đã kiếm được: $score \$', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [ElevatedButton.icon(icon: const Icon(Icons.menu, color: Colors.white), label: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () { Navigator.pop(c); Navigator.pop(context); })],
      ));
    }
  }

  @override
  void dispose() { timer?.cancel(); _audio.dispose(); _bgmPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String scoreDisplay = widget.isEndless ? "ĐIỂM: $score" : "ĐIỂM: $score / $targetScore";

    double availableWidth = screenWidth - 20; 
    double calculatedWidth = (availableWidth / petSlots) - 8; 
    double clientWidth = calculatedWidth.clamp(60.0, 130.0); 

    return WillPopScope(
      onWillPop: () async { _togglePause(); return false; },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$scoreDisplay | ${"❤️" * (hearts > 0 ? hearts : 0)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)), 
          backgroundColor: const Color(0xFF1A1A1A), iconTheme: const IconThemeData(color: Colors.amber),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: _togglePause),
          actions: [IconButton(icon: const Icon(Icons.pause_circle_filled, size: 30, color: Colors.blueAccent), onPressed: _togglePause), const SizedBox(width: 10)],
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF4A2F1D), Color(0xFF140D07)], radius: 1.2, center: Alignment.center)),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                if (comboTimeLeft > 0 || comboCount > 1) 
                  Container(
                    width: double.infinity, color: Colors.black45, padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    child: Row(
                      children: [
                        Text('🔥 COMBO x$comboCount', style: TextStyle(color: comboCount >= 3 ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 15),
                        Expanded(child: LinearProgressIndicator(value: comboTimeLeft, backgroundColor: Colors.grey[800], color: comboCount >= 3 ? Colors.redAccent : Colors.orangeAccent, minHeight: 10, borderRadius: BorderRadius.circular(5))),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                
                SizedBox(
                  height: 140, width: screenWidth,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: List.generate(petSlots, (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4), 
                            child: _buildPetClient(i, clientWidth)
                          ))
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20), 
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DragTarget<PetItem>(
                      onAccept: (item) { HapticFeedback.mediumImpact(); }, 
                      builder: (ctx, _, __) => Container(
                        width: 60, height: 60, margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.withOpacity(0.8), width: 2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))]),
                        child: const Center(child: Text('🗑️', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                      ),
                    ),
                    Draggable<String>(
                      data: 'extinguisher', feedback: const Material(color: Colors.transparent, child: Text('🧯', style: TextStyle(fontSize: 60))),
                      child: Container(
                        width: 60, height: 60, margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 8, offset: Offset(0, 4))]),
                        child: const Center(child: Text('🧯', textAlign: TextAlign.center, style: TextStyle(fontSize: 24))),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20), 
                // Sử dụng SingleChildScrollView để bọc các bếp nấu, tránh lỗi tràn khi số lượng bếp quá nhiều (ví dụ 4-5 bếp trên đt bé)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children: List.generate(widget.stations, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildPrepStation(i, screenWidth),
                    ))
                  ),
                ),
                const Spacer(), 
                
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), 
                  decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.amber, width: 3)), boxShadow: [BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, -5))]),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
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
  
  Widget _buildPetClient(int i, double clientWidth) {
    var pet = pets[i];
    var currentScores = floatingScores.where((fs) => fs.petIndex == i).toList();

    return DragTarget<PetItem>(
      onAccept: (item) { 
        if (pet != null) {
          if (item.name == pet.itemWanted && item.progress >= 0.8 && !item.isRuined) { 
            setState(() { 
              int multiplier = pet.isVip ? 3 : 1; int earnedMoney = (50 * multiplier) * comboCount; score += earnedMoney; localServes++;
              floatingScores.add(FloatingScore(i, 0.0, 1.0, '+$earnedMoney\$', pet.isVip ? Colors.amber : (comboCount >= 3 ? Colors.redAccent : Colors.greenAccent)));
              if (comboCount < 5) comboCount++; comboTimeLeft = 1.0; pets[i] = null; 
            }); 
            _play('kaching.mp3'); 
          } else { setState(() { hearts--; _play('ohno.mp3'); }); HapticFeedback.heavyImpact(); }
        }
      }, 
      builder: (ctx, _, __) => SizedBox(
        width: clientWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: pet != null && pet.isVip ? const Color(0xFFFFF8E1) : const Color(0xFFFDF5E6), borderRadius: BorderRadius.circular(15), border: Border.all(color: pet != null && pet.isVip ? Colors.redAccent : Colors.amber, width: pet != null && pet.isVip ? 4 : 3), boxShadow: pet != null && pet.isVip ? [const BoxShadow(color: Colors.amber, blurRadius: 15, spreadRadius: 2)] : [const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4))]),
              child: pet == null 
                ? Center(child: Text('Trống', style: TextStyle(color: Colors.grey, fontSize: (clientWidth * 0.2).clamp(10.0, 14.0), fontStyle: FontStyle.italic))) 
                : Stack( 
                    clipBehavior: Clip.none,
                    children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.asset(pet.avatarAssetPath, height: (clientWidth * 0.45).clamp(30.0, 55.0), fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.red, size: (clientWidth * 0.4).clamp(25.0, 40.0))),
                        Text(pet.itemWanted, style: TextStyle(fontSize: (clientWidth * 0.3).clamp(16.0, 28.0))),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: LinearProgressIndicator(value: pet.patience, backgroundColor: Colors.grey[300], color: pet.isVip ? Colors.purpleAccent : (pet.patience > 0.3 ? Colors.green : Colors.red))),
                      ]),
                      if (pet.isVip) Positioned(top: -10, left: -10, child: Text('👑', style: TextStyle(fontSize: (clientWidth * 0.25).clamp(16.0, 24.0))))
                    ],
                  ),
            ),
            ...currentScores.map((fs) => Positioned(
              bottom: 50 + fs.yOffset, 
              child: Opacity(
                opacity: fs.opacity.clamp(0.0, 1.0),
                child: Text(fs.text, style: TextStyle(fontSize: (clientWidth * 0.3).clamp(18.0, 26.0), fontWeight: FontWeight.w900, color: fs.color, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)), Shadow(color: Colors.white, blurRadius: 10, offset: Offset(0, 0))])),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Thuật toán co giãn tự động cho kích thước Bếp nấu
  Widget _buildPrepStation(int i, double screenWidth) {
    var item = prepStations[i];
    double burnThreshold = 1.6 + (widget.burnLevel * 0.3); 
    double currentCookSpeed = 0.012 + (widget.cookSpeedLevel * 0.003); 
    bool isReady = item != null && item.progress >= 0.8 && !item.isRuined;
    bool isFire = item != null && item.isOnFire; 
    
    // Tự động tính toán kích thước bếp dựa trên chiều rộng màn hình và số lượng bếp
    double size = (screenWidth / widget.stations) - 16; 
    size = size.clamp(70.0, 110.0); // Không cho bếp nhỏ quá 70px hoặc to quá 110px

    int secondsLeft = 0;
    if (item != null && !item.isRuined) { secondsLeft = ((burnThreshold - item.progress) / (currentCookSpeed * 10)).ceil(); }

    if (isFire) {
      return GestureDetector(
        onTap: () { setState(() { prepStations[i] = null; localFires++; }); HapticFeedback.mediumImpact(); },
        child: DragTarget<String>(
          onAccept: (data) { if (data == 'extinguisher') { setState(() { prepStations[i] = null; localFires++; }); HapticFeedback.mediumImpact(); } },
          builder: (ctx, _, __) => Container(
            width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent, border: Border.all(color: Colors.yellowAccent, width: 4), boxShadow: [const BoxShadow(color: Colors.red, blurRadius: 15, spreadRadius: 5)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🔥', style: TextStyle(fontSize: size * 0.35)),
              const Text('KÉO 🧯 VÀO\nHOẶC NHẤN', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white)),
              SizedBox(width: size - 30, child: LinearProgressIndicator(value: 1.0 - ((item.ruinedTicks - 40) / 40.0).clamp(0, 1), backgroundColor: Colors.red[900], color: Colors.yellow))
            ]),
          ),
        ),
      );
    }

    return DragTarget<String>(
      onAccept: (m) { if (m == 'extinguisher') return; setState(() => prepStations[i] = PetItem(m)); },
      builder: (ctx, _, __) => Container(
        width: size, height: size, 
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEEEEEE), border: Border.all(color: item != null && item.isRuined ? Colors.red : Colors.amber, width: 4), boxShadow: isReady ? [BoxShadow(color: secondsLeft <= 3 ? Colors.redAccent : Colors.amber, blurRadius: 20, spreadRadius: 2)] : [const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 5))]),
        child: item == null 
          ? Center(child: Text('BẾP\nTRỐNG', textAlign: TextAlign.center, style: TextStyle(fontSize: size * 0.12, fontWeight: FontWeight.bold, color: Colors.grey))) 
          : Draggable<PetItem>(
              data: item, onDragCompleted: () => setState(() => prepStations[i] = null),
              feedback: Material(color: Colors.transparent, child: Text(item.name, style: const TextStyle(fontSize: 60))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item.name, style: TextStyle(fontSize: size * 0.35)),
                if (item.isRuined)
                  Column(children: [const Text('💥 VỨT ĐI!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.red)), SizedBox(width: size - 30, child: LinearProgressIndicator(value: (item.ruinedTicks / 40.0).clamp(0, 1), backgroundColor: Colors.grey[400], color: Colors.orange))])
                else if (isReady)
                  Text('✨ CHÍN! (${secondsLeft}s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: secondsLeft <= 3 ? Colors.red : Colors.green[800]))
                else
                  const Text('♨️ ĐANG NẤU...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54)),
                
                if (!item.isRuined) SizedBox(width: size - 30, child: LinearProgressIndicator(value: item.progress.clamp(0, 1), backgroundColor: Colors.grey[400], color: isReady && secondsLeft <= 3 ? Colors.red : Colors.green)),
              ]),
            ),
      ),
    );
  }
}