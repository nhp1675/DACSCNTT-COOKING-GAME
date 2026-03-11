import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _menuController = TextEditingController();
  final TextEditingController _endlessCustomerController = TextEditingController(); // Controller cho Vô Tận

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Tải dữ liệu Món ăn và cài đặt Vô tận
  void _loadSettings() async {
    var menuDoc = await FirebaseFirestore.instance.collection('settings').doc('game').get();
    var endlessDoc = await FirebaseFirestore.instance.collection('settings').doc('endless').get();

    setState(() {
      if (menuDoc.exists && menuDoc.data()!.containsKey('supplies')) {
        List<String> currentMenu = List<String>.from(menuDoc.data()!['supplies']);
        _menuController.text = currentMenu.join(', ');
      }
      if (endlessDoc.exists && endlessDoc.data()!.containsKey('maxCustomers')) {
        _endlessCustomerController.text = endlessDoc.data()!['maxCustomers'].toString();
      } else {
        _endlessCustomerController.text = '50'; // Mặc định nếu chưa có
      }
    });
  }

  void _saveMenu() async {
    List<String> newMenu = _menuController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await FirebaseFirestore.instance.collection('settings').doc('game').set({'supplies': newMenu}, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật menu món ăn!'), backgroundColor: Colors.green));
  }

  void _saveEndlessConfig() async {
    int maxCustomers = int.tryParse(_endlessCustomerController.text) ?? 50;
    await FirebaseFirestore.instance.collection('settings').doc('endless').set({'maxCustomers': maxCustomers}, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật Chế độ Vô Tận!'), backgroundColor: Colors.green));
  }

  // --- HỘP THOẠI CÀY ẢI --- (Giữ nguyên như cũ)
  void _showLevelDialog({DocumentSnapshot? existingLevel}) {
    final isEditing = existingLevel != null;
    final levelController = TextEditingController(text: isEditing ? existingLevel.id : '');
    final targetScoreController = TextEditingController(text: isEditing ? existingLevel['targetScore'].toString() : '100');
    final timeLimitController = TextEditingController(text: isEditing ? existingLevel['timeLimit'].toString() : '60');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa màn chơi ${existingLevel.id}' : 'Thêm màn chơi mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              TextField(controller: levelController, decoration: const InputDecoration(labelText: 'Số thứ tự Level'), keyboardType: TextInputType.number),
            TextField(controller: targetScoreController, decoration: const InputDecoration(labelText: 'Điểm mục tiêu'), keyboardType: TextInputType.number),
            TextField(controller: timeLimitController, decoration: const InputDecoration(labelText: 'Thời gian (giây)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final levelId = levelController.text.trim();
              if (levelId.isEmpty) return;
              await FirebaseFirestore.instance.collection('levels').doc(levelId).set({
                'targetScore': int.tryParse(targetScoreController.text) ?? 100,
                'timeLimit': int.tryParse(timeLimitController.text) ?? 60,
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLevel(String levelId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa', style: TextStyle(color: Colors.red)),
        content: Text('Bạn có chắc muốn xóa màn $levelId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('levels').doc(levelId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 🌟 Đã tăng lên 3 tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BẢNG ĐIỀU KHIỂN ADMIN'),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.fastfood), text: 'MÓN ĂN'),
              Tab(icon: Icon(Icons.map), text: 'CÀY ẢI'),
              Tab(icon: Icon(Icons.all_inclusive), text: 'VÔ TẬN'), // 🌟 Tab mới
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: QUẢN LÝ MÓN ĂN
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thiết lập Menu món ăn (Emoji hoặc Text):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: _menuController, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 20),
                  Center(child: ElevatedButton.icon(icon: const Icon(Icons.save, color: Colors.white), label: const Text('LƯU MENU', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _saveMenu))
                ],
              ),
            ),

            // TAB 2: QUẢN LÝ CÀY ẢI (GIỮ NGUYÊN)
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(backgroundColor: Colors.redAccent, onPressed: () => _showLevelDialog(), icon: const Icon(Icons.add, color: Colors.white), label: const Text('THÊM MÀN', style: TextStyle(color: Colors.white))),
              body: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('levels').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var levels = snapshot.data!.docs.toList();
                  levels.sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
                  if (levels.isEmpty) return const Center(child: Text('Chưa có màn chơi nào.'));
                  return ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      var level = levels[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.green, child: Text(level.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          title: Text('Mục tiêu: ${level['targetScore']} điểm'),
                          subtitle: Text('Thời gian: ${level['timeLimit']} giây'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showLevelDialog(existingLevel: level)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteLevel(level.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // TAB 3: QUẢN LÝ VÔ TẬN 🌟
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thiết lập Chế độ Vô Tận:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _endlessCustomerController,
                    decoration: const InputDecoration(labelText: 'Số lượng tối đa khách hàng', border: OutlineInputBorder(), helperText: 'VD: 50, 100...'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Center(child: ElevatedButton.icon(icon: const Icon(Icons.save, color: Colors.white), label: const Text('LƯU CÀI ĐẶT', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _saveEndlessConfig))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}