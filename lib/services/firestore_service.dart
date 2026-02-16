import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================
// DATA MODEL
// ============================================================

/// Represents a stock item for autocomplete and display
class StokItem {
  final String nama;
  final String satuan;
  final int qty;
  StokItem(this.nama, this.satuan, this.qty);
}

// ============================================================
// KATEGORI & SUMBER CONSTANTS
// ============================================================

class Kategori {
  static const bahanBaku = 'bahan_baku';
  static const barangJadi = 'barang_jadi';
  static const sparepart = 'sparepart';
}

class Sumber {
  static const pembelian = 'pembelian';
  static const pemakaian = 'pemakaian';
  static const produksi = 'produksi';
  static const penjualan = 'penjualan';
}

// ============================================================
// FIRESTORE SERVICE
// ============================================================

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static const _stokCol = 'stok';
  static const _transaksiCol = 'transaksi';

  // ---- HELPERS ----

  /// Predictable doc ID for stok items → enables transaction-safe reads
  static String _docId(String kategori, String nama) => '${kategori}_$nama';

  static DocumentReference _stokRef(String kategori, String nama) {
    return _db.collection(_stokCol).doc(_docId(kategori, nama));
  }

  static String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // ---- STOK: READ ----

  /// Realtime stream of all stok items in a kategori
  static Stream<QuerySnapshot> stokStream(String kategori) {
    return _db
        .collection(_stokCol)
        .where('kategori', isEqualTo: kategori)
        .snapshots();
  }

  /// One-time fetch of stok list for autocomplete
  static Future<List<StokItem>> getStokList(String kategori) async {
    final snapshot = await _db
        .collection(_stokCol)
        .where('kategori', isEqualTo: kategori)
        .get();
    return snapshot.docs
        .map((doc) {
          final d = doc.data();
          return StokItem(
            d['nama'] as String? ?? '',
            d['satuan'] as String? ?? '',
            d['qty'] as int? ?? 0,
          );
        })
        .where((item) => item.nama.isNotEmpty)
        .toList();
  }

  // ---- STOK: WRITE ----

  /// Add stock (pembelian / produksi) — transactional
  static Future<void> tambahStok({
    required String kategori,
    required String nama,
    required int qty,
    required String satuan,
    required String sumber,
    String deskripsi = '',
    double? harga,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _stokRef(kategori, nama);
      final doc = await tx.get(ref);

      if (doc.exists) {
        final cur = (doc.data() as Map<String, dynamic>?)?['qty'] as int? ?? 0;
        tx.update(ref, {'qty': cur + qty, 'satuan': satuan});
      } else {
        tx.set(ref, {
          'nama': nama,
          'qty': qty,
          'satuan': satuan,
          'kategori': kategori,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Log transaksi
      tx.set(_db.collection(_transaksiCol).doc(), {
        'nama': nama,
        'qty': qty,
        'satuan': satuan,
        'kategori': kategori,
        'tipe': 'masuk',
        'sumber': sumber,
        if (harga != null) 'harga': harga,
        'deskripsi': deskripsi,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Reduce stock (pemakaian / penjualan) — transactional
  static Future<void> kurangiStok({
    required String kategori,
    required String nama,
    required int qty,
    required String satuan,
    required String sumber,
    String deskripsi = '',
    double? harga,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _stokRef(kategori, nama);
      final doc = await tx.get(ref);

      if (!doc.exists) {
        throw Exception('Stok "$nama" tidak ditemukan.');
      }

      final cur = (doc.data() as Map<String, dynamic>?)?['qty'] as int? ?? 0;
      if (cur < qty) {
        throw Exception('Stok tidak cukup. Tersedia: $cur, diminta: $qty');
      }

      tx.update(ref, {'qty': cur - qty});

      // Log transaksi
      tx.set(_db.collection(_transaksiCol).doc(), {
        'nama': nama,
        'qty': qty,
        'satuan': satuan,
        'kategori': kategori,
        'tipe': 'keluar',
        'sumber': sumber,
        if (harga != null) 'harga': harga,
        'deskripsi': deskripsi,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---- TRANSAKSI: READ ----

  /// Realtime stream of all transaksi for a kategori
  static Stream<QuerySnapshot> transaksiStream({
    required String kategori,
    int limit = 20,
  }) {
    return _db
        .collection(_transaksiCol)
        .where('kategori', isEqualTo: kategori)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Realtime stream of transaksi filtered by sumber
  static Stream<QuerySnapshot> transaksiStreamBySumber({
    required String kategori,
    required String sumber,
    int limit = 20,
  }) {
    return _db
        .collection(_transaksiCol)
        .where('kategori', isEqualTo: kategori)
        .where('sumber', isEqualTo: sumber)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
