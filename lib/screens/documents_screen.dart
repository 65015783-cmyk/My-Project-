import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = _getMockDocuments();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('เอกสาร'),
      ),
      body: documents.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _buildDocumentCard(documents[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีเอกสาร',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentItem doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: doc.type.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            doc.type.icon,
            color: doc.type.color,
            size: 28,
          ),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              doc.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doc.date,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Colors.blue),
          onPressed: () {
            // Download document
          },
        ),
      ),
    );
  }

  List<DocumentItem> _getMockDocuments() {
    return [
      DocumentItem(
        title: 'สลิปเงินเดือน',
        description: 'สลิปเงินเดือน เดือนพฤศจิกายน 2568',
        date: '1 ธันวาคม 2568',
        type: DocumentType.payslip,
      ),
      DocumentItem(
        title: 'ใบรับรองการทำงาน',
        description: 'เอกสารรับรองการทำงาน',
        date: '15 พฤศจิกายน 2568',
        type: DocumentType.certificate,
      ),
      DocumentItem(
        title: 'รายงานการทำงาน',
        description: 'รายงานการทำงานประจำเดือน',
        date: '1 พฤศจิกายน 2568',
        type: DocumentType.report,
      ),
    ];
  }
}

class DocumentItem {
  final String title;
  final String description;
  final String date;
  final DocumentType type;

  DocumentItem({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}

enum DocumentType {
  payslip(Icons.attach_money, Colors.purple),
  certificate(Icons.verified, Colors.green),
  report(Icons.description, Colors.blue);

  final IconData icon;
  final Color color;

  const DocumentType(this.icon, this.color);
}

