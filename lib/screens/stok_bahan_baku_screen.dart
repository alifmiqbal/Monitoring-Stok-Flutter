import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';

class StokBahanBakuScreen extends StatefulWidget {
  const StokBahanBakuScreen({super.key});

  @override
  State<StokBahanBakuScreen> createState() => _StokBahanBakuScreenState();
}

class _StokBahanBakuScreenState extends State<StokBahanBakuScreen> {
  String _selectedKategori = Kategori.bahanBaku;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      'Bahan Baku',
      Kategori.bahanBaku,
      Icons.inventory_outlined,
      AppColors.primary,
    ),
    _CategoryItem(
      'Hasil Produksi',
      Kategori.barangJadi,
      Icons.factory_outlined,
      AppColors.info,
    ),
    _CategoryItem(
      'Spare Part',
      Kategori.sparepart,
      Icons.build_outlined,
      AppColors.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCat = _categories.firstWhere(
      (c) => c.kategori == _selectedKategori,
      orElse: () => _categories.first,
    );

    return Column(
      children: [
        // Category Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedKategori == cat.kategori;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                        const SizedBox(width: 6),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedKategori = cat.kategori);
                      }
                    },
                    selectedColor: cat.color,
                    backgroundColor: cat.color.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : cat.color,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? cat.color
                            : cat.color.withValues(alpha: 0.3),
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Stock List — unified `stok` collection
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.stokStream(_selectedKategori),
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
                  'Belum ada data stok.',
                  icon: Icons.inventory_2_outlined,
                );
              }

              final items = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, index) {
                  final data = items[index].data() as Map<String, dynamic>;
                  // Unified field: always `nama`
                  final nama = data['nama'] as String? ?? '-';
                  final qty = data['qty'] as int? ?? 0;
                  final satuan = data['satuan'] as String? ?? '-';

                  return AppWidgets.buildStockCard(
                    name: nama,
                    qty: qty,
                    unit: satuan,
                    icon: currentCat.icon,
                    color: currentCat.color,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String label;
  final String kategori;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.label, this.kategori, this.icon, this.color);
}
