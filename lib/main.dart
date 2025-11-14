import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Absensi',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AbsensiPage(),
    );
  }
}

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk input teks
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _kelasController = TextEditingController();
  
  // Daftar pilihan
  final List<String> _deviceOptions = ['Android (Smartphone/Tablet)', 'iOS (iPhone/iPad)', 'Laptop/PC'];

  // Variabel state
  String? _selectedKelamin;
  String? _selectedDevice; 
  bool _isLoading = false;
  
  // Endpoint API Absensi
  final String _apiUrl = 'https://absensi-mobile.primakarauniversity.ac.id/api/absensi';

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  // Fungsi untuk mem-parsing pesan error dari API
  String _parseErrors(Map<String, dynamic> message) {
    var errors = <String>[];
    message.forEach((field, messages) {
      if (messages is List) {
        String fieldName = field.toUpperCase(); 
        errors.add('$fieldName: ${messages.join(', ')}');
      }
    });
    return errors.join('\n');
  }

  // Fungsi untuk menampilkan Pop-up Status (Success/Error)
  void _showStatusDialog(String status, String message) {
    bool isSuccess = status == 'success';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IKON STATIS (FIX untuk ClientException)
              Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 80,
              ),
              
              const SizedBox(height: 16),
              
              // Judul
              Text(
                isSuccess ? 'Absensi Berhasil!' : 'Absensi Gagal!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),

              // Pesan Detail
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Tombol Tutup
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup Pop-up
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.indigo : Colors.red,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Fungsi untuk submit absensi
  Future<void> _submitAbsensi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(_apiUrl); // Menggunakan endpoint yang Anda tentukan

    final body = {
      'nama': _namaController.text,
      'nim': _nimController.text,
      'kelas': _kelasController.text,
      'jenis_kelamin': _selectedKelamin,
      'device': _selectedDevice,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      // --- LOGGING UNTUK DEBUGGING (Seperti permintaan Anda) ---
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      // --------------------------------------------------------

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == 'success') {
          // KETIKA SUKSES
          _showStatusDialog('success', responseData['message']);
          
          // Reset form untuk input absensi berulang
          _formKey.currentState!.reset();
          _namaController.clear();
          _nimController.clear();
          _kelasController.clear();
          setState(() {
            _selectedKelamin = null;
            _selectedDevice = null;
          });
        } else {
          // KETIKA ERROR VALIDASI DARI API
          final errorMessage = _parseErrors(responseData['message']);
          _showStatusDialog('error', 'Validasi Gagal:\n$errorMessage');
        }
      } else {
        // KETIKA ERROR SERVER (4xx atau 5xx)
        final errorMessage = _parseErrors(responseData['message']);
        _showStatusDialog('error', 'Error Server (${response.statusCode}):\n$errorMessage');
      }
    } catch (e) {
      // KETIKA ERROR KONEKSI
      _showStatusDialog('error', 'Terjadi Kesalahan Koneksi: Pastikan internet stabil.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Absensi'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Form
                    const Text(
                      'Formulir Absensi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),

                    // Input Nama
                    _buildTextFormField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input NIM
                    _buildTextFormField(
                      controller: _nimController,
                      label: 'NIM',
                      icon: Icons.badge,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIM tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Kelas
                    _buildTextFormField(
                      controller: _kelasController,
                      label: 'Kelas',
                      icon: Icons.school,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kelas tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Jenis Kelamin (Dropdown)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKelamin,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: ['Laki-Laki', 'Perempuan']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKelamin = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih jenis kelamin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Device (Dropdown)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDevice,
                      decoration: const InputDecoration(
                        labelText: 'Device yang Digunakan',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      items: _deviceOptions
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDevice = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih device yang digunakan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitAbsensi,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Submit Absensi',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk membangun TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}