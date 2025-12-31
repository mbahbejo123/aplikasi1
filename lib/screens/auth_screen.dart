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

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isRegister && name.isEmpty)) {
      _showMsg("Data tidak boleh kosong!");
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
        _showMsg("Berhasil Daftar! Silakan Login.");
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
      _showMsg("Error: $e"); // Ini akan memunculkan pesan merah di bawah layar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.inventory, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(_isRegister ? "Daftar Akun" : "Login Inventaris",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              if (_isRegister) ...[
                TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Nama Lengkap",
                        border: OutlineInputBorder())),
                const SizedBox(height: 15),
              ],
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: "Password", border: OutlineInputBorder())),
              const SizedBox(height: 25),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                          onPressed: _handleAuth,
                          child: Text(_isRegister ? "Daftar" : "Login")),
                    ),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister
                    ? "Sudah punya akun? Login"
                    : "Belum punya akun? Daftar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
