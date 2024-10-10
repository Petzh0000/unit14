import 'package:flutter/material.dart';
import 'package:varit14/pages/add_page.dart';
import 'package:varit14/pages/list_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
void main() {
  runApp(const MyApp());
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บทที่ 14',
      debugShowCheckedModeBanner: false,
      home: ListPage(),
    );
  }
}
