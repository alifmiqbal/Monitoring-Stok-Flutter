import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Model Barang untuk suggest
class Barang {
  final String nama;
  final String satuan;
  Barang(this.nama, this.satuan);
}

class HasilProduksiScreen extends StatefulWidget {
  const HasilProduksiScreen({super.key});

  @override
  State<HasilProduksiScreen> createState() => _HasilProduksiScreenState();
}

class _HasilProduksiScreenState extends State<HasilProduksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isLoading = false;
  List<Barang> _barangList = [];

  @override
  void initState() {
    super.initState();
    _fetchBarangList();
  }

  Future<void> _fetchBarangList() async {
    final snapshot = await FirebaseFirestore.instance.collection('barang_jadi').get();
    final barangSet = <String, String>{};
    for (var doc in snapshot.docs) {
      final nama = doc.data()['nama_barang'] as String? ?? '';
      final satuan = doc.data()['satuan'] as String? ?? '';
      if (nama.isNotEmpty) {
        barangSet[nama] = satuan;
      }
    }
    if (mounted) {
      setState(() {
        _barangList = barangSet.entries.map((e) => Barang(e.key, e.value)).toList();
      });
    }
  }
  
  // ### FUNGSI INI TELAH DIPERBAIKI DENGAN FIRESTORE TRANSACTION ###
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final namaBarang = _nameController.text.trim();
    final qty = int.parse(_qtyController.text);
    final satuan = _unitController.text.trim();
    
    try {
      // Menjalankan operasi sebagai satu transaksi atomik
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Referensi ke dokumen stok barang jadi
        // Menggunakan nama barang sebagai ID dokumen
        final stokRef = FirebaseFirestore.instance.collection('barang_jadi').doc(namaBarang);
        
        // 2. Referensi untuk log baru (ID akan dibuat otomatis)
        final logRef = FirebaseFirestore.instance.collection('hasil_produksi_log').doc();

        // Ambil data stok saat ini DI DALAM transaksi
        final stokDoc = await transaction.get(stokRef);

        if (stokDoc.exists) {
          // Jika barang sudah ada, update kuantitasnya
          final currentQty = stokDoc.data()?['qty'] as int? ?? 0;
          transaction.update(stokRef, {
            'qty': currentQty + qty,
            'satuan': satuan, // Update satuan jika mungkin berubah
            'nama_barang': namaBarang, // Pastikan field nama_barang tetap ada
          });
        } else {
          // Jika barang baru, buat dokumen baru
          transaction.set(stokRef, {
            'nama_barang': namaBarang,
            'qty': qty,
            'satuan': satuan,
          });
        }
        
        // 3. Tulis log DI DALAM transaksi
        // Ini memastikan log hanya dibuat jika update stok berhasil
        transaction.set(logRef, {
          'nama_barang': namaBarang,
          'qty': qty,
          'satuan': satuan,
          'createdAt': FieldValue.serverTimestamp(), // Lebih baik dari Timestamp.now()
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil produksi berhasil ditambahkan!')),
      );

      _nameController.clear();
      _qtyController.clear();
      _unitController.clear();
      await _fetchBarangList(); // Refresh daftar autocomplete

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi Gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Autocomplete<Barang>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _barangList;
                    }
                    return _barangList.where((Barang option) {
                      return option.nama.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  displayStringForOption: (Barang option) => option.nama,
                  onSelected: (Barang selection) {
                    _nameController.text = selection.nama;
                    _unitController.text = selection.satuan;
                    FocusScope.of(context).nextFocus();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: const InputDecoration(labelText: 'Nama Barang'),
                      onChanged: (value) {
                        _nameController.text = value;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mohon masukkan nama barang.';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Barang option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.nama),
                                subtitle: Text('Satuan: ${option.satuan}'),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null) {
                      return 'Mohon masukkan kuantitas yang valid.';
                    }
                    if (int.parse(value) < 1) {
                      return 'Kuantitas minimal 1.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mohon masukkan satuan.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Tambah Hasil Produksi'),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 30.0),
          const Divider(thickness: 2),
          const Text(
            'Log Hasil Produksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10.0),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hasil_produksi_log')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan!'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada log hasil produksi.'));
                }

                final logs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (ctx, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final waktu = (log['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = waktu != null
                        ? DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(waktu)
                        : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.blue),
                        title: Text(
                          log['nama_barang'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Qty: ${log['qty']} ${log['satuan'] ?? "-"}\nWaktu: $formattedDate',
                        ),
                        trailing: Text(
                          '+${log['qty']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}