import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddPage extends StatefulWidget {
  const AddPage({Key? key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  // สร้าง GlobalKey สำหรับ Form เพื่อใช้ในการตรวจสอบและบันทึกข้อมูล
  final _formKey = GlobalKey<FormState>();
  // สร้าง Controller สำหรับควบคุมข้อมูลใน TextField
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  // ตัวแปรสำหรับควบคุมสถานะการโหลด
  bool _isLoading = false;

  // ฟังก์ชันสำหรับเพิ่มข้อมูลผู้ใช้
  Future<void> _addUser() async {
    // ตรวจสอบความถูกต้องของข้อมูลในฟอร์ม
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // เริ่มแสดงสถานะกำลังโหลด
      });

      try {
        // เตรียมข้อมูลสำหรับส่งไปยัง API
        final data = {
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
        };

        // ส่งข้อมูลไปยัง API
        final response = await http.post(
          Uri.parse('https://466412221001.itshuntra.net/api/insert.php'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );

        // ตรวจสอบการตอบกลับจาก API
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == 'success') {
            // แสดงข้อความแจ้งเตือนเมื่อเพิ่มข้อมูลสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonResponse['message']),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // ปิดหน้านี้และส่งค่า true กลับไป
          } else {
            throw Exception(jsonResponse['message']);
          }
        } else {
          throw Exception('HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        // แสดงข้อความแจ้งเตือนเมื่อเกิดข้อผิดพลาด
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // สิ้นสุดการแสดงสถานะกำลังโหลด
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลใหม่'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // ช่องกรอกชื่อ
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'ชื่อ',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          // ตรวจสอบความถูกต้องของข้อมูล
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกชื่อ';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        // ช่องกรอกอีเมล
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'อีเมล',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          // ตรวจสอบความถูกต้องของอีเมล
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกอีเมล';
                            }
                            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                              return 'กรุณากรอกอีเมลที่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // ปุ่มเพิ่มข้อมูล
                ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('เพิ่มข้อมูล'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}