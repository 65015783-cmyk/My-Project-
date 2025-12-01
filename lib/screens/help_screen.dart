import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = _getFAQs();
    final contacts = _getContacts();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ความช่วยเหลือ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ติดต่อสอบถาม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...contacts.map((contact) => _buildContactItem(contact)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // FAQ Section
            const Text(
              'คำถามที่พบบ่อย',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...faqs.map((faq) => _buildFAQCard(faq)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(ContactItem contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: contact.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(contact.icon, color: contact.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  contact.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ContactItem> _getContacts() {
    return [
      ContactItem(
        icon: Icons.phone,
        label: 'โทรศัพท์',
        value: '02-123-4567',
        color: Colors.green,
      ),
      ContactItem(
        icon: Icons.email,
        label: 'อีเมล',
        value: 'support@company.com',
        color: Colors.blue,
      ),
      ContactItem(
        icon: Icons.chat,
        label: 'แชท',
        value: 'เปิดใช้งาน',
        color: Colors.orange,
      ),
    ];
  }

  List<FAQItem> _getFAQs() {
    return [
      FAQItem(
        question: 'วิธีการเช็คอิน/เช็คเอาท์?',
        answer: 'กดปุ่ม "เข้างาน" หรือ "ออกงาน" ในหน้าหลัก และถ่ายรูปเพื่อแสดงหลักฐาน',
      ),
      FAQItem(
        question: 'ฉันลืมรหัสผ่านทำอย่างไร?',
        answer: 'ติดต่อฝ่าย HR เพื่อขอรีเซ็ตรหัสผ่าน หรือส่งอีเมลไปที่ support@company.com',
      ),
      FAQItem(
        question: 'ดูประวัติการทำงานได้อย่างไร?',
        answer: 'เข้าไปที่หน้า "โปรไฟล์" แล้วเลือก "ประวัติการทำงาน" เพื่อดูรายละเอียด',
      ),
      FAQItem(
        question: 'ดาวน์โหลดเอกสารได้อย่างไร?',
        answer: 'เข้าไปที่หน้า "โปรไฟล์" แล้วเลือก "เอกสาร" จากนั้นกดไอคอนดาวน์โหลดที่เอกสารที่ต้องการ',
      ),
    ];
  }
}

class ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

