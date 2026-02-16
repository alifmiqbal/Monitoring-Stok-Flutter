import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';

class PenjualanScreen extends StatefulWidget {
  const PenjualanScreen({super.key});

  @override
  State<PenjualanScreen> createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends State<PenjualanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;
  List<StokItem> _stokList = [];

  @override
  void initState() {
    super.initState();
    _fetchStokList();
  }

  Future<void> _fetchStokList() async {
    final list = await FirestoreService.getStokList(Kategori.barangJadi);
    if (mounted) setState(() => _stokList = list);
  }

  void _submitForm() async {
    if (_priceController.text.trim().isEmpty ||
        double.tryParse(_priceController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga harus diisi dengan angka yang valid.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final nama = _nameController.text.trim();
    final qty = int.parse(_qtyController.text);
    final satuan = _unitController.text.trim();
    final harga = double.parse(_priceController.text.trim());
    final deskripsi = _deskripsiController.text.trim();

    try {
      await FirestoreService.kurangiStok(
        kategori: Kategori.barangJadi,
        nama: nama,
        qty: qty,
        satuan: satuan,
        sumber: Sumber.penjualan,
        deskripsi: deskripsi,
        harga: harga,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi penjualan berhasil!')),
        );
      }

      _nameController.clear();
      _qtyController.clear();
      _unitController.clear();
      _priceController.clear();
      _deskripsiController.clear();
      await _fetchStokList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transaksi Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Autocomplete<StokItem>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _stokList;
                    return _stokList.where(
                      (item) => item.nama.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (item) => item.nama,
                  onSelected: (selection) {
                    _nameController.text = selection.nama;
                    _unitController.text = selection.satuan;
                    FocusScope.of(context).nextFocus();
                  },
                  fieldViewBuilder:
                      (ctx, controller, focusNode, onEditingComplete) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          onChanged: (v) => _nameController.text = v,
                          decoration: const InputDecoration(
                            labelText: 'Nama Barang',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Mohon masukkan nama barang.'
                              : null,
                        );
                      },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    prefixIcon: Icon(Icons.payments_outlined),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty || double.tryParse(v) == null)
                      ? 'Mohon masukkan harga yang valid.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: Icon(Icons.numbers),
                    suffixText: 'Pengurangan',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty || int.tryParse(v) == null) {
                      return 'Mohon masukkan kuantitas yang valid.';
                    }
                    if (int.parse(v) < 1) return 'Kuantitas minimal 1.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  readOnly: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Mohon masukkan satuan.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _deskripsiController,
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
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Kurangi Stok'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
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
          AppWidgets.buildSectionHeader(
            'Riwayat Penjualan',
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: 12),

          // History — uses same 2-field index, client-side filter for penjualan
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.transaksiStream(
              kategori: Kategori.barangJadi,
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
                return AppWidgets.buildEmptyState(
                  'Belum ada log penjualan.',
                  icon: Icons.receipt_long_outlined,
                );
              }

              // Client-side filter: only show penjualan
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['sumber'] == Sumber.penjualan;
              }).toList();

              if (docs.isEmpty) {
                return AppWidgets.buildEmptyState(
                  'Belum ada log penjualan.',
                  icon: Icons.receipt_long_outlined,
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (ctx, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? DateFormat(
                          'dd MMMM yyyy, HH:mm',
                          'id_ID',
                        ).format(ts.toDate())
                      : '-';
                  final harga = data['harga'] as num?;
                  final deskripsi = data['deskripsi'] as String? ?? '';

                  String sub = 'Qty: ${data['qty']} ${data['satuan'] ?? "-"}';
                  sub += '\nHarga: ${formatRupiah(harga)}';
                  if (deskripsi.isNotEmpty) sub += '\nDeskripsi: $deskripsi';
                  sub += '\nWaktu: $date';

                  return AppWidgets.buildHistoryCard(
                    title: data['nama'] ?? '-',
                    subtitle: sub,
                    trailing: '-${data['qty']}',
                    isPositive: false,
                    negativeIcon: Icons.remove_circle_outline,
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
