import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditPage({Key? key, required this.user}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  // สร้าง GlobalKey สำหรับ Form เพื่อใช้ในการตรวจสอบและบันทึกข้อมูล
  final _formKey = GlobalKey<FormState>();
  // สร้าง Controller สำหรับควบคุมข้อมูลใน TextField
  late TextEditingController nameController;
  late TextEditingController emailController;
  // ตัวแปรสำหรับควบคุมสถานะการโหลดและการเปลี่ยนแปลงข้อมูล
  bool isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นให้กับ Controller จากข้อมูลผู้ใช้ที่ได้รับ
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);

    // เพิ่ม listener เพื่อตรวจสอบการเปลี่ยนแปลงข้อมูล
    nameController.addListener(_onTextChanged);
    emailController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // ลบ listener เมื่อไม่ได้ใช้งานแล้ว
    nameController.removeListener(_onTextChanged);
    emailController.removeListener(_onTextChanged);
    // ทำลาย Controller เพื่อป้องกันการรั่วไหลของหน่วยความจำ
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ฟังก์ชันตรวจสอบการเปลี่ยนแปลงข้อมูล
  void _onTextChanged() {
    setState(() {
      _hasChanges = nameController.text != widget.user['name'] ||
          emailController.text != widget.user['email'];
    });
  }

  // ฟังก์ชันสำหรับอัปเดตข้อมูลผู้ใช้
  Future<void> updateUser() async {
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบว่ามีการเปลี่ยนแปลงข้อมูลหรือไม่
      if (!_hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่มีการเปลี่ยนแปลงข้อมูล'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isLoading = true; // เริ่มแสดงสถานะกำลังโหลด
      });

      try {
        // ส่งข้อมูลไปยัง API เพื่ออัปเดต
        final response = await http.post(
          Uri.parse('https://466412221001.itshuntra.net/api/update.php'),
          body: json.encode({
            'id': widget.user['id'],
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
          }),
          headers: {"Content-Type": "application/json"},
        );

        // ตรวจสอบการตอบกลับจาก API
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == 'success') {
            // แสดงข้อความแจ้งเตือนเมื่ออัปเดตสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('อัปเดตข้อมูลสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // ปิดหน้านี้และส่งค่า true กลับไป
          } else {
            throw Exception(jsonResponse['message']);
          }
        } else {
          throw Exception('เกิดข้อผิดพลาดในการแก้ไขข้อมูล');
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
          isLoading = false; // สิ้นสุดการแสดงสถานะกำลังโหลด
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูล'),
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
                          controller: nameController,
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
                          controller: emailController,
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
                // ปุ่มบันทึกการแก้ไข
                ElevatedButton(
                  onPressed: isLoading ? null : updateUser,
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('บันทึกการแก้ไข'),
                  style: ElevatedButton.styleFrom(
                    // เปลี่ยนสีปุ่มตามสถานะการเปลี่ยนแปลงข้อมูล
                    backgroundColor: _hasChanges ? Colors.blue : Colors.grey,
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