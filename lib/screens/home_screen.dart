import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'auth_screen.dart';

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

  // LOGIKA PINJAM
  Future<void> _borrowProduct(Map<String, dynamic> item) async {
    try {
      await _supabase.rpc('borrow_item', params: {
        'p_id': item['id'],
        'u_id': _supabase.auth.currentUser!.id,
      });
      _showSnackBar("Berhasil meminjam ${item['name']}", Colors.green);
    } catch (e) {
      _showSnackBar("Gagal: Stok mungkin sudah habis", Colors.red);
    }
  }

  // LOGIKA KEMBALI
  Future<void> _returnProduct(Map<String, dynamic> trans) async {
    try {
      await _supabase.rpc('return_item', params: {
        't_id': trans['id'],
        'p_id': trans['product_id'],
      });
      _showSnackBar("Barang dikembalikan", Colors.blue);
    } catch (e) {
      _showSnackBar("Gagal mengembalikan barang", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gudang Inventaris Alat",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
        actions: [
          IconButton(
              onPressed: () async {
                await _supabase.auth.signOut();
                if (mounted)
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AuthScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent))
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  const Text("Daftar Barang",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(flex: 3, child: _buildProductList()),
                  const Divider(height: 30),
                  const Text("Pinjaman Saya",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(flex: 2, child: _buildBorrowedList()),
                ],
              ),
            ),
      floatingActionButton: _userProfile?.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              label: const Text("Tambah"),
              icon: const Icon(Icons.add))
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Text(_userProfile?.fullName[0].toUpperCase() ?? "U",
                style: const TextStyle(color: Colors.white))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Halo, ${_userProfile?.fullName}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("Role: ${_userProfile?.role.toUpperCase()}",
              style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
        ])
      ]),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('products')
          .stream(primaryKey: ['id']).order('id', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final item = products[index];
            final int stock = item['stock'] ?? 0;
            return Card(
              child: ListTile(
                title: Text(item['name'] ?? ''),
                subtitle: Text("Stok: $stock unit"),
                trailing: _userProfile?.role == 'admin'
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item['id']))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                stock > 0 ? Colors.green : Colors.grey),
                        onPressed:
                            stock > 0 ? () => _borrowProduct(item) : null,
                        child: Text(stock > 0 ? "Pinjam" : "Habis")),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBorrowedList() {
    final uid = _supabase.auth.currentUser?.id ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('transactions').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        // Filter: Hanya milik user aktif & status 'dipinjam'
        final borrowed = snapshot.data!
            .where((t) => t['user_id'] == uid && t['status'] == 'dipinjam')
            .toList();

        if (borrowed.isEmpty)
          return const Center(
              child: Text("Belum ada pinjaman aktif",
                  style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: borrowed.length,
          itemBuilder: (context, index) {
            final trans = borrowed[index];
            return FutureBuilder(
              future: _supabase
                  .from('products')
                  .select('name')
                  .eq('id', trans['product_id'])
                  .single(),
              builder: (context, prodSnap) {
                return Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    title: Text(prodSnap.data?['name'] ?? "Memuat..."),
                    subtitle: const Text("Status: Sedang Dipinjam"),
                    trailing: TextButton(
                        onPressed: () => _returnProduct(trans),
                        child: const Text("KEMBALIKAN")),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    final n = TextEditingController(), s = TextEditingController();
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text("Tambah Barang"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: n,
                    decoration: const InputDecoration(labelText: "Nama")),
                TextField(
                    controller: s,
                    decoration: const InputDecoration(labelText: "Stok"),
                    keyboardType: TextInputType.number),
              ]),
              actions: [
                ElevatedButton(
                    onPressed: () async {
                      await _supabase
                          .from('products')
                          .insert({'name': n.text, 'stock': int.parse(s.text)});
                      Navigator.pop(c);
                    },
                    child: const Text("Simpan"))
              ],
            ));
  }

  void _confirmDelete(id) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text("Hapus Barang?"),
              actions: [
                ElevatedButton(
                    onPressed: () async {
                      await _supabase.from('products').delete().eq('id', id);
                      Navigator.pop(c);
                    },
                    child: const Text("Hapus"))
              ],
            ));
  }
}
