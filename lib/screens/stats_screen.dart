import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("STATISTIK GUDANG",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionTitle("Komposisi Stok Barang"),
            const SizedBox(height: 20),
            _buildPieChart(supabase),
            const SizedBox(height: 40),
            _buildSectionTitle("Aktivitas Pinjaman"),
            const SizedBox(height: 20),
            _buildBarChart(supabase),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold));
  }

  Widget _buildPieChart(SupabaseClient supabase) {
    return SizedBox(
      height: 250,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('products').select('name, stock'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final data = snapshot.data!;
          return PieChart(
            PieChartData(
              sections: data.map((item) {
                return PieChartSectionData(
                  color: Colors
                      .primaries[data.indexOf(item) % Colors.primaries.length],
                  value: (item['stock'] as int).toDouble(),
                  title: item['name'],
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(SupabaseClient supabase) {
    return SizedBox(
      height: 300,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        // Menghitung jumlah transaksi per barang
        future: supabase.from('transactions').select('product_id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          // Logic sederhana untuk menghitung frekuensi
          Map<dynamic, int> counts = {};
          for (var t in snapshot.data!) {
            counts[t['product_id']] = (counts[t['product_id']] ?? 0) + 1;
          }

          return BarChart(
            BarChartData(
              barGroups: counts.entries.map((e) {
                return BarChartGroupData(
                  x: e.key.hashCode,
                  barRods: [
                    BarChartRodData(
                        toY: e.value.toDouble(),
                        color: Colors.cyanAccent,
                        width: 20)
                  ],
                );
              }).toList(),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          );
        },
      ),
    );
  }
}
