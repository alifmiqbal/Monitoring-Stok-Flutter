import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';

class SparepartScreen extends StatefulWidget {
  const SparepartScreen({super.key});

  @override
  State<SparepartScreen> createState() => _SparepartScreenState();
}

class _SparepartScreenState extends State<SparepartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _transactionType = 'Pembelian';
  bool _isLoading = false;
  bool _isScreenLoading = true;
  List<StokItem> _stokList = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _fetchStokList();
    if (mounted) setState(() => _isScreenLoading = false);
  }

  Future<void> _fetchStokList() async {
    final list = await FirestoreService.getStokList(Kategori.sparepart);
    if (mounted) setState(() => _stokList = list);
  }

  void _submitForm() async {
    if (_transactionType == 'Pembelian') {
      if (_priceController.text.trim().isEmpty ||
          double.tryParse(_priceController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga harus diisi untuk transaksi pembelian.'),
          ),
        );
        return;
      }
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama Sparepart harus diisi.')),
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final nama = _nameController.text.trim();
        final qty = int.parse(_qtyController.text);
        final satuan = _unitController.text.trim();
        final deskripsi = _descriptionController.text.trim();

        if (_transactionType == 'Pembelian') {
          await FirestoreService.tambahStok(
            kategori: Kategori.sparepart,
            nama: nama,
            qty: qty,
            satuan: satuan,
            sumber: Sumber.pembelian,
            deskripsi: deskripsi,
            harga: double.parse(_priceController.text),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stok berhasil ditambahkan!')),
            );
          }
        } else {
          await FirestoreService.kurangiStok(
            kategori: Kategori.sparepart,
            nama: nama,
            qty: qty,
            satuan: satuan,
            sumber: Sumber.pemakaian,
            deskripsi: deskripsi,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stok berhasil dikurangi!')),
            );
          }
        }

        _priceController.clear();
        _qtyController.clear();
        _unitController.clear();
        _descriptionController.clear();
        await _fetchStokList();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScreenLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final uniqueNames = _stokList.map((e) => e.nama).toSet().toList();
    bool isPembelian = _transactionType == 'Pembelian';
    final Color buttonColor = isPembelian
        ? AppColors.success
        : AppColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Toggle Bar
          AppWidgets.buildToggleBar(
            leftLabel: 'Pembelian',
            rightLabel: 'Pemakaian',
            leftIcon: Icons.shopping_cart_checkout,
            rightIcon: Icons.construction,
            isLeftSelected: isPembelian,
            leftColor: AppColors.success,
            rightColor: AppColors.danger,
            onLeftTap: () => setState(() {
              _transactionType = 'Pembelian';
              _priceController.clear();
              _qtyController.clear();
              _unitController.clear();
              _descriptionController.clear();
            }),
            onRightTap: () => setState(() {
              _transactionType = 'Pemakaian';
              _priceController.clear();
              _qtyController.clear();
              _unitController.clear();
              _descriptionController.clear();
            }),
          ),
          const SizedBox(height: 20),

          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return uniqueNames;
                    return uniqueNames.where(
                      (n) => n.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (selection) {
                    _nameController.text = selection;
                    try {
                      final item = _stokList.firstWhere(
                        (s) => s.nama == selection,
                      );
                      _unitController.text = item.satuan;
                    } catch (_) {
                      _unitController.clear();
                    }
                    _priceController.clear();
                    _qtyController.clear();
                    Future.delayed(
                      Duration.zero,
                      () => FocusScope.of(context).nextFocus(),
                    );
                  },
                  fieldViewBuilder: (ctx, textController, focusNode, onSubmit) {
                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      onFieldSubmitted: (_) => onSubmit(),
                      onChanged: (v) => _nameController.text = v,
                      decoration: const InputDecoration(
                        labelText: 'Nama Sparepart',
                        prefixIcon: Icon(Icons.build_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Mohon masukkan nama Sparepart.'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                if (isPembelian)
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Pembelian',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                if (isPembelian) const SizedBox(height: 14),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Kuantitas (QTY)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null ||
                          v.isEmpty ||
                          int.tryParse(v) == null ||
                          int.parse(v) <= 0)
                      ? 'Mohon masukkan kuantitas valid (> 0).'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan (contoh: Meter, Kg, Pcs)',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  readOnly: !isPembelian,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Mohon masukkan satuan.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submitForm,
                          icon: Icon(
                            isPembelian
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                          ),
                          label: Text(
                            isPembelian ? 'Tambah Stok' : 'Kurangi Stok',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 4),
          AppWidgets.buildSectionHeader('Riwayat', icon: Icons.history),
          const SizedBox(height: 12),

          // History — single stream
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.transaksiStream(
              kategori: Kategori.sparepart,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Terjadi kesalahan: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return AppWidgets.buildEmptyState('Belum ada data transaksi.');
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (ctx, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(ts.toDate())
                      : '-';
                  final isMasuk = data['tipe'] == 'masuk';
                  final deskripsi = data['deskripsi'] as String? ?? '';
                  final harga = data['harga'] as num?;

                  String sub = 'Qty: ${data['qty']} ${data['satuan'] ?? ""}';
                  if (harga != null) {
                    sub += '\nHarga: ${formatRupiah(harga)}';
                  }
                  if (deskripsi.isNotEmpty) sub += '\nDeskripsi: $deskripsi';
                  sub += '\n$date';

                  return AppWidgets.buildHistoryCard(
                    title: data['nama'] ?? '-',
                    subtitle: sub,
                    trailing: isMasuk ? '+${data['qty']}' : '-${data['qty']}',
                    isPositive: isMasuk,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
