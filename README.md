# 🧵 Rope Monitoring — Monitoring Stok & Produksi Tali

Aplikasi Flutter untuk **monitoring stok bahan baku, hasil produksi, penjualan, dan sparepart** pada industri pembuatan tali (rope). Terintegrasi penuh dengan **Firebase** (Authentication & Cloud Firestore).

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 🔐 **Autentikasi** | Login & Register menggunakan Firebase Auth |
| 📦 **Stok Bahan Baku** | Input pembelian & pemakaian bahan baku dengan tracking otomatis |
| 🏭 **Hasil Produksi** | Pencatatan hasil produksi barang jadi |
| 🛒 **Penjualan** | Pencatatan penjualan produk jadi |
| 🔧 **Sparepart** | Manajemen stok sparepart mesin |
| 📊 **Sisa Stok** | Monitoring realtime sisa stok semua kategori |
| 📝 **Riwayat Transaksi** | Log transaksi masuk/keluar dengan filter kategori & sumber |
| 👤 **User Tracking** | Setiap transaksi tercatat oleh siapa yang melakukannya |

---

## 🏗️ Arsitektur

```
lib/
├── main.dart                    # Entry point & Firebase init
├── app_theme.dart               # Design system & tema aplikasi
├── firebase_options.dart        # Konfigurasi Firebase (auto-generated)
├── services/
│   └── firestore_service.dart   # Centralized Firestore service (transactional)
└── screens/
    ├── auth_screen.dart         # Login & Register
    ├── home_screen.dart         # Bottom nav + Navigation rail (responsive)
    ├── input_bahan_baku.dart    # Input pembelian/pemakaian bahan baku
    ├── input_barang_jadi.dart   # Input produksi/pemakaian barang jadi
    ├── penjualan.dart           # Input penjualan
    ├── sparepart.dart           # Input sparepart
    └── stok_bahan_baku_screen.dart  # Monitoring sisa stok
```

---

## 🗄️ Struktur Database (Firestore)

Menggunakan **2 koleksi utama** untuk skalabilitas:

### Collection: `stok`
| Field | Type | Keterangan |
|---|---|---|
| `nama` | `string` | Nama barang |
| `qty` | `number` | Jumlah stok saat ini |
| `satuan` | `string` | Satuan (kg, pcs, meter, dll) |
| `kategori` | `string` | `bahan_baku` / `barang_jadi` / `sparepart` |
| `createdAt` | `timestamp` | Waktu pertama kali dibuat |

### Collection: `transaksi`
| Field | Type | Keterangan |
|---|---|---|
| `nama` | `string` | Nama barang |
| `qty` | `number` | Jumlah transaksi |
| `satuan` | `string` | Satuan |
| `kategori` | `string` | Kategori barang |
| `tipe` | `string` | `masuk` / `keluar` |
| `sumber` | `string` | `pembelian` / `pemakaian` / `produksi` / `penjualan` |
| `harga` | `number` | Harga (opsional) |
| `deskripsi` | `string` | Keterangan tambahan |
| `userId` | `string` | ID user yang melakukan transaksi |
| `createdAt` | `timestamp` | Waktu transaksi |

---

## 🚀 Cara Menjalankan

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.8.0`
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Akun Firebase dengan project aktif

### Langkah-langkah

1. **Clone repository**
   ```bash
   git clone https://github.com/alifmiqbal/Monitoring-Stok-Flutter.git
   cd Monitoring-Stok-Flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   
   > ⚠️ Anda perlu membuat project Firebase sendiri dan mengganti konfigurasi.
   
   ```bash
   # Install Firebase CLI & FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Konfigurasi Firebase untuk project Anda
   flutterfire configure
   ```
   
   Ini akan menghasilkan file `lib/firebase_options.dart` baru sesuai project Firebase Anda.

4. **Aktifkan layanan Firebase**
   - Buka [Firebase Console](https://console.firebase.google.com)
   - Aktifkan **Authentication** → Email/Password
   - Aktifkan **Cloud Firestore** → Buat database

5. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 🛠️ Tech Stack

| Teknologi | Keterangan |
|---|---|
| **Flutter** `^3.8.0` | Framework UI cross-platform |
| **Firebase Auth** `^6.0.0` | Autentikasi pengguna |
| **Cloud Firestore** `^6.0.0` | Database NoSQL realtime |
| **Firebase Core** `^4.0.0` | Core Firebase SDK |
| **intl** `^0.18.1` | Formatting tanggal Bahasa Indonesia |
| **RxDart** `^0.27.7` | Reactive stream utilities |

---

## 📱 Platform yang Didukung

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

---

## 📄 Lisensi

Project ini dibuat untuk keperluan edukasi dan monitoring produksi tali.

---

## 👤 Author

**Alif M. Iqbal** — [@alifmiqbal](https://github.com/alifmiqbal)
