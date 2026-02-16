#!/bin/bash

# Menampilkan pesan awal
echo "🚀 Memulai proses push ke GitHub..."

# 1. Meminta pesan commit dari pengguna
echo "📝 Masukkan pesan commit Anda:"
read commit_message

# 2. Cek apakah pesan commit kosong
if [ -z "$commit_message" ]; then
  echo "❌ Pesan commit tidak boleh kosong. Proses dibatalkan."
  exit 1
fi

# 3. Mendapatkan nama branch yang sedang aktif secara otomatis
current_branch=$(git rev-parse --abbrev-ref HEAD)

# 4. Menjalankan perintah Git
echo "----------------------------------------"
echo "✅ Menambahkan semua file (git add .)"
git add .

echo "✅ Membuat commit dengan pesan: \"$commit_message\""
git commit -m "$commit_message"

echo "✅ Melakukan push ke branch '$current_branch'"
git push origin $current_branch

echo "----------------------------------------"
echo "🎉 Proses selesai! Kode Anda sudah berhasil di-push ke GitHub."