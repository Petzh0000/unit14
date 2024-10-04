import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'add_page.dart';
import 'edit_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List users = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers(); // โหลดข้อมูลผู้ใช้เมื่อเริ่มต้นหน้า
  }

  // ฟังก์ชันสำหรับดึงข้อมูลผู้ใช้จาก API
  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://466412221001.itshuntra.net/api/select.php'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is List) {
          setState(() {
            users = jsonData;
          });
        } else if (jsonData is Map && jsonData.containsKey('message')) {
          setState(() {
            errorMessage = jsonData['message'];
          });
        }
      } else {
        throw Exception('เกิดข้อผิดพลาดในการโหลดข้อมูล');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับนำทางไปยังหน้าแก้ไขข้อมูล
  void navigateToEditPage(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(user: user),
      ),
    ).then((_) {
      fetchUsers(); // โหลดข้อมูลใหม่หลังจากกลับมาจากหน้าแก้ไข
    });
  }

  // ฟังก์ชันสำหรับลบข้อมูลผู้ใช้
  Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://466412221001.itshuntra.net/api/delete.php'),
        body: json.encode({'id': userId}),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 10)); // กำหนด timeout 10 วินาที

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          fetchUsers(); // โหลดข้อมูลใหม่หลังจากลบ
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } on SocketException {
      // จัดการกรณีไม่สามารถเชื่อมต่อเครือข่ายได้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต'),
          backgroundColor: Colors.red,
        ),
      );
    } on TimeoutException {
      // จัดการกรณีการเชื่อมต่อใช้เวลานานเกินไป
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      // จัดการข้อผิดพลาดอื่นๆ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบข้อมูล: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ฟังก์ชันสำหรับนำทางไปยังหน้าเพิ่มข้อมูล
  void navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPage()),
    );
    if (result == true) {
      fetchUsers(); // โหลดข้อมูลใหม่หลังจากเพิ่มข้อมูล
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายชื่อผู้ใช้', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchUsers, // โหลดข้อมูลใหม่เมื่อกดปุ่ม refresh
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddPage,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'เพิ่มผู้ใช้ใหม่',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)))
            : errorMessage.isNotEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : users.isEmpty
            ? Center(child: Text('ไม่พบข้อมูลผู้ใช้', style: TextStyle(fontSize: 18)))
            : ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            String userId = user['id'].toString();
            return Dismissible(
              key: Key(userId),
              background: Container(
                color: Colors.blue,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                ),
              ),
              // กำหนดการทำงานเมื่อผู้ใช้ swipe รายการ
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe ไปทางขวา (แก้ไข)
                  navigateToEditPage(user);
                  return false; // ไม่ลบรายการออกจาก ListView
                } else {
                  // Swipe ไปทางซ้าย (ลบ)
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("ยืนยันการลบ"),
                        content: const Text("คุณต้องการลบข้อมูลนี้ใช่หรือไม่?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  deleteUser(userId);
                }
              },
              child: Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['name'] ?? 'ไม่มีชื่อ', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'] ?? 'ไม่มีอีเมล'),
                  trailing: Icon(Icons.swipe, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}