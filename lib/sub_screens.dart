import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_screen.dart';

// --- MÀN HÌNH CHỌN CẤP ĐỘ ---
class LevelSelectScreen extends StatelessWidget {
  final int maxLevel, stations, burnLevel, maxHearts, unlockedIngredients, cookSpeedLevel; 
  final bool isSoundOn; 
  final String bgMusic, playerName, playerAvatar;
  
  const LevelSelectScreen({super.key, required this.maxLevel, required this.stations, required this.burnLevel, required this.maxHearts, required this.unlockedIngredients, required this.cookSpeedLevel, required this.isSoundOn, required this.bgMusic, required this.playerName, required this.playerAvatar});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('CHỌN MÀN CHƠI'), backgroundColor: Colors.green),
      body: uid == null 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<DocumentSnapshot>(
            // 🌟 Lắng nghe dữ liệu trực tiếp (Real-time) từ cơ sở dữ liệu
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (ctx, snap) {
              int currentMaxLevel = maxLevel; 
              // 🌟 Cập nhật cấp độ mới ngay lập tức khi vừa chơi xong
              if (snap.hasData && snap.data!.exists) {
                currentMaxLevel = snap.data!.get('maxLevel') ?? 1;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15),
                itemCount: 20, 
                itemBuilder: (ctx, i) {
                  int level = i + 1;
                  // 🌟 Dùng currentMaxLevel thay cho maxLevel cũ
                  bool isLocked = level > currentMaxLevel; 

                  return InkWell(
                    onTap: isLocked ? null : () => Navigator.push(ctx, MaterialPageRoute(builder: (c) => GameScreen(
                      isEndless: false, level: level, stations: stations, burnLevel: burnLevel, maxHearts: maxHearts, 
                      unlockedIngredients: unlockedIngredients, cookSpeedLevel: cookSpeedLevel, 
                      isSoundOn: isSoundOn, bgMusic: bgMusic, playerName: playerName, playerAvatar: playerAvatar
                    ))),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey[300] : Colors.white, 
                        borderRadius: BorderRadius.circular(15), 
                        border: Border.all(color: isLocked ? Colors.grey : Colors.greenAccent, width: 3)
                      ),
                      child: Center(
                        child: isLocked 
                          ? const Icon(Icons.lock, size: 40, color: Colors.grey)
                          : Text('LV.$level', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))
                      ),
                    ),
                  );
                },
              );
            }
          ),
    );
  }
}// --- MÀN HÌNH CÀI ĐẶT ---
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
          TextField(controller: _nameController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.person)), maxLength: 15),
          const SizedBox(height: 20),

          const Text("CHỌN AVATAR:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _avatars.map((av) => GestureDetector(
              onTap: () => setState(() => _selectedAvatar = av),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _selectedAvatar == av ? Colors.amberAccent : Colors.white, border: Border.all(color: _selectedAvatar == av ? Colors.orange : Colors.grey, width: 2), borderRadius: BorderRadius.circular(15)),
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
                value: _selectedBgm, isExpanded: true,
                items: _musicTracks.map((track) => DropdownMenuItem<String>(value: track['file'], child: Text(track['name']!))).toList(),
                onChanged: (val) { if (val != null) setState(() => _selectedBgm = val); },
              ),
            ),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white), label: const Text('LƯU CÀI ĐẶT', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('HƯỚNG DẪN CHƠI'), backgroundColor: Colors.teal,
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
          const Center(child: Text('Chúc bạn kinh doanh hồng phát! 🐾', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)))
        ],
      ),
    );
  }

  Widget _guideCard(String title, String desc) {
    return Card(
      elevation: 4, margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.teal, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8), Text(desc, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
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
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'coins': coins + reward, claimField: true}, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhận thành công $reward \$! 🥳"), backgroundColor: Colors.green));
    onUpdate(); Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NHIỆM VỤ HÀNG NGÀY'), backgroundColor: Colors.deepPurple, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
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
      elevation: 4, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCompleted && !isClaimed ? Colors.amber : Colors.transparent, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('🎁 $reward \$', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey[300], color: isCompleted ? Colors.green : Colors.blueAccent, borderRadius: BorderRadius.circular(5))), const SizedBox(width: 10), Text('${current > target ? target : current} / $target', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (isCompleted && !isClaimed) ? () => _claimReward(context, claimField, reward) : null, style: ElevatedButton.styleFrom(backgroundColor: isClaimed ? Colors.grey : (isCompleted ? Colors.amber : Colors.blueGrey)), child: Text(isClaimed ? 'ĐÃ NHẬN' : (isCompleted ? 'NHẬN THƯỞNG' : 'CHƯA HOÀN THÀNH'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
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
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'coins': coins + reward, claimField: true}, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chúc mừng! Nhận $reward \$! 🎉"), backgroundColor: Colors.orange));
    onUpdate(); Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 THÀNH TỰU'), backgroundColor: Colors.orangeAccent, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
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
      elevation: 4, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCompleted && !isClaimed ? themeColor : Colors.transparent, width: 3)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor)), Text('💎 $reward \$', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 5), Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87)), const SizedBox(height: 10),
            Row(children: [Expanded(child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey[300], color: isCompleted ? themeColor : Colors.blueGrey, borderRadius: BorderRadius.circular(5))), const SizedBox(width: 10), Text('${current > target ? target : current} / $target', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (isCompleted && !isClaimed) ? () => _claimReward(context, claimField, reward) : null, style: ElevatedButton.styleFrom(backgroundColor: isClaimed ? Colors.grey : (isCompleted ? themeColor : Colors.grey[400])), child: Text(isClaimed ? 'ĐÃ NHẬN' : (isCompleted ? 'NHẬN HUY CHƯƠNG' : 'CHƯA HOÀN THÀNH'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
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
    if (currentValue >= maxValue) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nâng cấp tối đa!"))); return; }
    if (coins < cost) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn không đủ tiền!"), backgroundColor: Colors.red)); return; }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'coins': coins - cost, field: currentValue + 1}, SetOptions(merge: true));
    onUpdate(); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nâng cấp thành công! 🥳"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CỬA HÀNG (💰 $coins \$)'), backgroundColor: Colors.blueAccent, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('$desc\nCấp hiện tại: $current / $max'), isThreeLine: true,
        trailing: ElevatedButton.icon(icon: const Icon(Icons.shopping_cart, size: 18), label: Text(current >= max ? 'MAX' : '$cost \$'), onPressed: current >= max ? null : onTap, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent)),
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
      appBar: AppBar(title: const Text('TOP ĐẦU BẾP'), backgroundColor: Colors.amber, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
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
                  leading: CircleAvatar(backgroundColor: i == 0 ? Colors.amber : (i == 1 ? Colors.grey[300] : (i == 2 ? Colors.orange[200] : Colors.blue[100])), child: Text(i < 3 ? ['🥇','🥈','🥉'][i] : '${i + 1}')),
                  title: Row(children: [Text(avatar, style: const TextStyle(fontSize: 20)), const SizedBox(width: 10), Text(name, style: const TextStyle(fontWeight: FontWeight.bold))]),
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