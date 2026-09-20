from pathlib import Path

# Folder utama source code
lib_folder = Path("lib")

# File hasil gabungan
output_file = Path("phonkify_all_code.txt")

# Ambil semua file .dart secara otomatis
dart_files = sorted(lib_folder.rglob("*.dart"))

with output_file.open("w", encoding="utf-8") as output:

    # Header
    output.write("=" * 100 + "\n")
    output.write("PHONKIFY - ALL SOURCE CODE\n")
    output.write("=" * 100 + "\n")
    output.write(f"Total file Dart: {len(dart_files)}\n")
    output.write("=" * 100 + "\n\n")

    # Masukkan setiap file
    for file in dart_files:

        # Path relatif terhadap folder proyek
        relative_path = file.as_posix()

        output.write("\n")
        output.write("=" * 100 + "\n")
        output.write(f"FILE: {relative_path}\n")
        output.write("=" * 100 + "\n\n")

        try:
            code = file.read_text(encoding="utf-8")
            output.write(code)
        except Exception as e:
            output.write(f"[ERROR MEMBACA FILE: {e}]\n")

        output.write("\n\n")

print("========================================")
print("PHONKIFY SOURCE CODE BERHASIL DIGABUNG")
print("========================================")
print(f"Jumlah file : {len(dart_files)}")
print(f"File hasil  : {output_file}")
print("========================================")