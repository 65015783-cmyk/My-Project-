import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // แสดงโลโก้สั้น ๆ ก่อนเข้าแอปหลัก
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _HRLogo(),
      ),
    );
  }
}

class _HRLogo extends StatelessWidget {
  const _HRLogo();

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF424242);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // วงกลมรอบนอก
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: logoColor,
                width: 10,
              ),
            ),
          ),
          // ตัวอักษร HR
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'H',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: logoColor,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'R',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: logoColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          // ขีดเฉียงของตัว R ออกมานอกวงกลม
          Positioned(
            right: 38,
            bottom: 26,
            child: Transform.rotate(
              angle: 0.9, // ประมาณ 50 องศา
              alignment: Alignment.topLeft,
              child: Container(
                width: 12,
                height: 80,
                decoration: BoxDecoration(
                  color: logoColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


