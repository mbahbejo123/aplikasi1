import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;

  // Kata-kata motivasi inventaris/kerja
  final List<String> _quotes = [
    "Kelola barang dengan bijak, mudahkan kerja bersama.",
    "Kerapian gudang adalah cermin efisiensi tim.",
    "Satu barang kembali tepat waktu, menyelamatkan satu harimu.",
    "Mulai hari ini dengan sistem yang lebih teratur."
  ];

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isRegister && name.isEmpty)) {
      _showMsg("Data tidak boleh kosong!", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegister) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
        _showMsg("Pendaftaran Berhasil! Silakan Login.", Colors.greenAccent);
        setState(() => _isRegister = false);
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }
    } catch (e) {
      _showMsg("Terjadi Kesalahan: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Deep Ocean
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
          // Ornamen lingkaran untuk estetika
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.cyanAccent.withOpacity(0.05)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 70, color: Colors.cyanAccent),
                  const SizedBox(height: 10),
                  const Text(
                    "GUDANG ALAT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Kata-kata Motivasi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _quotes[(_isRegister
                          ? 1
                          : 0)], // Ganti quote berdasarkan mode
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card Glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isRegister ? "BUAT AKUN" : "LOGIN SISTEM",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 25),
                            if (_isRegister) ...[
                              _buildTextField(
                                  controller: _nameController,
                                  hint: "Nama Lengkap",
                                  icon: Icons.person_outline),
                              const SizedBox(height: 15),
                            ],
                            _buildTextField(
                                controller: _emailController,
                                hint: "Email",
                                icon: Icons.email_outlined),
                            const SizedBox(height: 15),
                            _buildTextField(
                                controller: _passwordController,
                                hint: "Password",
                                icon: Icons.lock_outline,
                                isPass: true),
                            const SizedBox(height: 30),
                            _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.cyanAccent)
                                : SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        elevation: 0,
                                      ),
                                      onPressed: _handleAuth,
                                      child: Text(
                                        _isRegister
                                            ? "DAFTAR SEKARANG"
                                            : "MASUK KE DASHBOARD",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? "Sudah terdaftar? Masuk di sini"
                          : "Belum punya akses? Hubungi Admin / Daftar",
                      style: const TextStyle(color: Colors.cyanAccent),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
      ),
    );
  }
}
