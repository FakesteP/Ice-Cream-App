import 'package:flutter/material.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan dan Pesan'),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '🍦 Kesan dan Pesan',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade600),
            ),
            const SizedBox(height: 10),
            Text(
              'Untuk Mata Kuliah Teknologi dan Pemrograman Mobile',
              style: TextStyle(fontSize: 16, color: Colors.pink.shade400),
            ),
            Divider(height: 30, thickness: 1.5, color: Colors.pink.shade200),
            _buildSectionTitle('Kesan 😊', Colors.pink.shade500),
            const SizedBox(height: 8),
            const Text(
              'Mata kuliah Mobile Programming sangat menarik dan memberikan pengalaman berharga dalam pengembangan aplikasi Flutter. Materi yang diberikan membantu memahami konsep secara mendalam, dan dosen sangat supportif dalam proses pembelajaran.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 25),
            _buildSectionTitle('Pesan & Harapan ✨', Colors.pink.shade500),
            const SizedBox(height: 8),
            const Text(
              '• Semoga materi terus diupdate sesuai perkembangan teknologi Flutter\n'
              '• Mungkin bisa ditambahkan lebih banyak studi kasus real-world projects\n'
              '• Pengenalan state management yang lebih advanced sebagai materi tambahan\n\n'
              'Terima kasih atas ilmu dan bimbingannya! Mata kuliah ini memberikan bekal yang sangat berharga.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            Center(
              child: Icon(Icons.favorite, color: Colors.pink[400], size: 50),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Semoga Sukses Selalu! 🌟",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
