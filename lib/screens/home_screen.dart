import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'auth_screen.dart';
import 'stats_screen.dart'; // Pastikan file ini sudah dibuat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Profile? _userProfile;
  bool _isLoadingProfile = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (mounted) {
          setState(() {
            _userProfile = data != null
                ? Profile.fromJson(data)
                : Profile(
                    id: user.id,
                    fullName: user.email?.split('@')[0] ?? "User",
                    role: 'user');
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // --- LOGIKA TRANSAKSI ---
  Future<void> _borrowProduct(Map<String, dynamic> item) async {
    try {
      await _supabase.rpc('borrow_item',
          params: {'p_id': item['id'], 'u_id': _supabase.auth.currentUser!.id});
      _showSnackBar("Berhasil meminjam ${item['name']}", Colors.greenAccent);
    } catch (e) {
      _showSnackBar("Gagal: Stok habis", Colors.redAccent);
    }
  }

  Future<void> _returnProduct(Map<String, dynamic> trans) async {
    try {
      await _supabase.rpc('return_item',
          params: {'t_id': trans['id'], 'p_id': trans['product_id']});
      _showSnackBar("Barang dikembalikan", Colors.cyanAccent);
    } catch (e) {
      _showSnackBar("Gagal mengembalikan", Colors.redAccent);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userProfile?.role == 'admin';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("INVENTARIS GUDANG",
            style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Tombol Statistik (Hanya untuk Admin)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.cyanAccent),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StatsScreen())),
            ),
          // Tombol Logout
          IconButton(
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AuthScreen()));
              }
            },
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
              ),
            ),
          ),
          _isLoadingProfile
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent))
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlassHeader(),
                        const SizedBox(height: 25),
                        _sectionTitle("Daftar Barang"),
                        Expanded(flex: 3, child: _buildProductList(isAdmin)),
                        const SizedBox(height: 20),
                        _sectionTitle(isAdmin
                            ? "Monitor Pinjaman (Admin)"
                            : "Pinjaman Saya"),
                        Expanded(flex: 2, child: _buildBorrowedList(isAdmin)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: isAdmin ? _buildFab() : null,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.cyanAccent,
                child: Text(_userProfile?.fullName[0].toUpperCase() ?? "U",
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Halo, ${_userProfile?.fullName}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(_userProfile?.role.toUpperCase() ?? "",
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(bool isAdmin) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream:
          _supabase.from('products').stream(primaryKey: ['id']).order('name'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final item = products[index];
            final stock = item['stock'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(item['name'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text("Stok: $stock",
                    style: const TextStyle(color: Colors.white54)),
                trailing:
                    isAdmin ? _adminActions(item) : _userActions(item, stock),
              ),
            );
          },
        );
      },
    );
  }

  Widget _adminActions(Map<String, dynamic> item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.orangeAccent),
            onPressed: () => _showEditDialog(item)),
        IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(item['id'])),
      ],
    );
  }

  Widget _userActions(Map<String, dynamic> item, int stock) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: stock > 0 ? Colors.cyanAccent : Colors.white10,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: stock > 0 ? () => _borrowProduct(item) : null,
      child: Text(stock > 0 ? "PINJAM" : "HABIS",
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBorrowedList(bool isAdmin) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('transactions').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final uid = _supabase.auth.currentUser?.id;
        final borrowed = snapshot.data!
            .where((t) =>
                t['status'] == 'dipinjam' && (isAdmin || t['user_id'] == uid))
            .toList();

        if (borrowed.isEmpty) {
          return const Center(
              child: Text("Belum ada pinjaman",
                  style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          itemCount: borrowed.length,
          itemBuilder: (context, index) {
            final trans = borrowed[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.subdirectory_arrow_right,
                    color: Colors.orangeAccent),
                title: FutureBuilder(
                  future: _supabase
                      .from('products')
                      .select('name')
                      .eq('id', trans['product_id'])
                      .single(),
                  builder: (context, res) => Text(res.data?['name'] ?? "...",
                      style: const TextStyle(color: Colors.white)),
                ),
                trailing: TextButton(
                    onPressed: () => _returnProduct(trans),
                    child: const Text("KEMBALI",
                        style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold))),
              ),
            );
          },
        );
      },
    );
  }

  FloatingActionButton _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.cyanAccent,
      onPressed: _showAddDialog,
      label: const Text("TAMBAH",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.add, color: Colors.black),
    );
  }

  void _showAddDialog() {
    final n = TextEditingController(), s = TextEditingController();
    _styledDialog("Tambah Barang", n, s, () async {
      if (n.text.isNotEmpty && s.text.isNotEmpty) {
        await _supabase
            .from('products')
            .insert({'name': n.text, 'stock': int.parse(s.text)});
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final n = TextEditingController(text: item['name']),
        s = TextEditingController(text: item['stock'].toString());
    _styledDialog("Edit Barang", n, s, () async {
      if (n.text.isNotEmpty && s.text.isNotEmpty) {
        await _supabase.from('products').update(
            {'name': n.text, 'stock': int.parse(s.text)}).eq('id', item['id']);
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _styledDialog(String title, TextEditingController n,
      TextEditingController s, VoidCallback onSave) {
    showDialog(
      context: context,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A2E35),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: n,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Nama",
                    labelStyle: TextStyle(color: Colors.white38))),
            TextField(
                controller: s,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Stok",
                    labelStyle: TextStyle(color: Colors.white38)),
                keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("BATAL",
                    style: TextStyle(color: Colors.white38))),
            ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent),
                child: const Text("SIMPAN",
                    style: TextStyle(color: Colors.black))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E35),
        title:
            const Text("Hapus Barang?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("TIDAK")),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await _supabase.from('products').delete().eq('id', id);
                if (mounted) Navigator.pop(c);
              },
              child:
                  const Text("HAPUS", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}