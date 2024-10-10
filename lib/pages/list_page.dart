import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'add_page.dart';
import 'edit_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class PhoneDialer {
  static Future<void> makePhoneCall(String phoneNumber) async {
    final url = Uri(scheme: 'tel', path: phoneNumber);

    // ตรวจสอบและขออนุญาต
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      // เปิดแอปโทรศัพท์
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print('Cannot launch dialer for URL: $url');
      }
    } else {
      // ถ้าไม่อนุญาต
      print('Permission to access phone not granted');
    }
  }
}

class _ListPageState extends State<ListPage> {
  List users = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Load user data on initial load
  }

  // Function to fetch users from the API
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
        throw Exception('Error loading data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to handle phone calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final sanitizedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''); // Remove invalid characters
    final url = Uri(path: sanitizedPhoneNumber);

    // Check and request permission
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission to make phone calls not granted'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Exit if permission is not granted
      }
    }
    // Launch the dialer
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot launch the dialer. Please check the phone number.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function for navigating to edit page
  void navigateToEditPage(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(user: user),
      ),
    ).then((_) {
      fetchUsers(); // Reload data after returning from edit page
    });
  }

  // Function for deleting a user
  Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://466412221001.itshuntra.net/api/delete.php'),
        body: json.encode({'id': userId}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          fetchUsers(); // Reload data after delete
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function for navigating to add page
  void navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPage()),
    );
    if (result == true) {
      fetchUsers(); // Reload data after adding
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
            onPressed: fetchUsers, // Reload data on refresh
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddPage,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Add New User',
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
            ? Center(child: Text('No users found', style: TextStyle(fontSize: 18)))
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
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe to edit
                  navigateToEditPage(user);
                  return false; // Do not dismiss
                } else {
                  // Swipe to delete
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Do you want to delete this user?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
                  title: Text('ชื่อ: ${user['name'] ?? 'ไม่มีชื่อ'}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ชื่อเล่น: ${user['nickname'] ?? 'ไม่มีชื่อเล่น'}'),
                      Text('อีเมล: ${user['email'] ?? 'ไม่มีอีเมล'}'),
                      Row(
                        children: [
                          Text('เบอร์โทร: ${user['phone'] ?? 'ไม่มีเบอร์โทร'}'),
                          if (user['phone'] != null) // Show button if phone is not null
                            IconButton(
                              icon: Icon(Icons.phone),
                              onPressed: () {
                                final phone = user['phone'].replaceAll(' ', ''); // ดึงหมายเลขโทรศัพท์
                                if (phone.isNotEmpty) {
                                  PhoneDialer.makePhoneCall(phone); // โทรออกโดยใช้หมายเลขที่ดึงมา
                                } else {
                                  // แจ้งเตือนเมื่อไม่มีหมายเลขโทรศัพท์
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('ไม่พบหมายเลขโทรศัพท์'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),

                        ],
                      ),
                    ],
                  ),
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
