import 'dart:convert';

class Merchandise {
  final int id;
  final String nama;
  final String? deskripsi;
  final int poinDibutuhkan;
  final int stok;
  final String? urlGambar;

  Merchandise({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.poinDibutuhkan,
    required this.stok,
    this.urlGambar,
  });

  factory Merchandise.fromJson(Map<String, dynamic> json) {
    return Merchandise(
      id: json['id'],
      nama: json['NAMA'],
      deskripsi: json['DESKRIPSI'],
      poinDibutuhkan: json['POIN_DIBUTUHKAN'],
      stok: json['STOK'],
      urlGambar: json['URL_GAMBAR'],
    );
  }

  static List<Merchandise> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Merchandise.fromJson(json)).toList();
  }
}