import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';

class InputGabunganScreen extends StatefulWidget {
  const InputGabunganScreen({super.key});

  @override
  State<InputGabunganScreen> createState() => _InputGabunganScreenState();
}

class _InputGabunganScreenState extends State<InputGabunganScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;
  bool _isScreenLoading = true;
  List<StokItem> _stokList = [];
  String _mode = 'pembelian';

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
    final list = await FirestoreService.getStokList(Kategori.barangJadi);
    if (mounted) setState(() => _stokList = list);
  }

  void _submitForm() async {
    if (_mode == 'pembelian') {
      if (_hargaController.text.trim().isEmpty ||
          double.tryParse(_hargaController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga harus diisi dengan angka yang valid.'),
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final nama = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final satuan = _unitController.text.trim();
    final harga = _mode == 'pembelian'
        ? double.tryParse(_hargaController.text)
        : null;
    final deskripsi = _deskripsiController.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Qty harus lebih dari 0.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirestoreService.tambahStok(
        kategori: Kategori.barangJadi,
        nama: nama,
        qty: qty,
        satuan: satuan,
        sumber: _mode == 'pembelian' ? Sumber.pembelian : Sumber.produksi,
        deskripsi: deskripsi,
        harga: harga,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _mode == 'pembelian'
                  ? 'Pembelian berhasil ditambahkan!'
                  : 'Hasil produksi berhasil ditambahkan!',
            ),
          ),
        );
      }

      _nameController.clear();
      _qtyController.clear();
      _unitController.clear();
      _hargaController.clear();
      _deskripsiController.clear();
      await _fetchStokList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScreenLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    bool isPembelian = _mode == 'pembelian';
    final Color buttonColor = isPembelian ? AppColors.success : AppColors.info;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle mode
          AppWidgets.buildToggleBar(
            leftLabel: 'Pembelian',
            rightLabel: 'Produksi',
            leftIcon: Icons.shopping_cart_checkout,
            rightIcon: Icons.precision_manufacturing,
            isLeftSelected: isPembelian,
            leftColor: AppColors.success,
            rightColor: AppColors.info,
            onLeftTap: () => setState(() {
              _mode = 'pembelian';
              _nameController.clear();
              _qtyController.clear();
              _unitController.clear();
              _hargaController.clear();
              _deskripsiController.clear();
            }),
            onRightTap: () => setState(() {
              _mode = 'produksi';
              _nameController.clear();
              _qtyController.clear();
              _unitController.clear();
              _hargaController.clear();
              _deskripsiController.clear();
            }),
          ),
          const SizedBox(height: 20),

          // Form
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
                    _hargaController.clear();
                    _qtyController.clear();
                    _deskripsiController.clear();
                    FocusScope.of(context).nextFocus();
                  },
                  fieldViewBuilder:
                      (ctx, fieldController, fieldFocus, onSubmit) {
                        return TextFormField(
                          controller: fieldController,
                          focusNode: fieldFocus,
                          decoration: const InputDecoration(
                            labelText: 'Nama Barang Jadi',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Mohon masukkan nama barang jadi'
                              : null,
                          onChanged: (v) => _nameController.text = v,
                          onEditingComplete: onSubmit,
                        );
                      },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Kuantitas (QTY)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty || int.tryParse(v) == null)
                      ? 'Mohon masukkan kuantitas valid'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan (contoh: Meter, Kg, Pcs)',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Mohon masukkan satuan' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    hintText: 'Misal: dari supplier A, batch B',
                  ),
                ),
                if (isPembelian) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _hargaController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Pembelian',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Mohon masukkan harga'
                        : null,
                  ),
                ],
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
                                : Icons.precision_manufacturing_outlined,
                          ),
                          label: Text(
                            isPembelian ? 'Tambah Stok' : 'Catat Produksi',
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
          AppWidgets.buildSectionHeader(
            'Log Transaksi Terakhir',
            icon: Icons.history,
          ),
          const SizedBox(height: 12),

          // History — single stream
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
                return AppWidgets.buildEmptyState('Belum ada log.');
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
                  final deskripsi = data['deskripsi'] as String? ?? '';
                  final sumber = data['sumber'] as String? ?? '';
                  final isPembelianLog = sumber == Sumber.pembelian;

                  String sub = 'Qty: ${data['qty']} ${data['satuan'] ?? ""}';
                  if (data['harga'] != null) {
                    sub += '\nHarga: ${formatRupiah(data['harga'])}';
                  }
                  sub +=
                      '\nSumber: ${sumber[0].toUpperCase()}${sumber.substring(1)}';
                  if (deskripsi.isNotEmpty) sub += '\nDeskripsi: $deskripsi';
                  sub += '\n$date';

                  return AppWidgets.buildHistoryCard(
                    title: data['nama'] ?? '-',
                    subtitle: sub,
                    trailing: '+${data['qty']}',
                    isPositive: true,
                    positiveColor: isPembelianLog
                        ? AppColors.success
                        : AppColors.info,
                    positiveIcon: isPembelianLog
                        ? Icons.arrow_downward_rounded
                        : Icons.precision_manufacturing,
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
