import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryReminder {
  static Future<void> showExpiredMedsSheet(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('medicines')
        .get();

    final dateFormat = DateFormat('dd-MM-yyyy');

    final expiredMeds = snapshot.docs.where((doc) {
      final expiryStr = doc['expiryDate'];
      try {
        final expiryDate = dateFormat.parseStrict(expiryStr);
        return expiryDate.isBefore(today);
      } catch (_) {
        return false;
      }
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (expiredMeds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("No expired medicines!", style: TextStyle(fontSize: 18)),
          );
        }

        return ListView.builder(
          itemCount: expiredMeds.length,
          itemBuilder: (context, index) {
            final med = expiredMeds[index];
            return ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.red),
              title: Text(med['name']),
              subtitle: Text('Expired on: ${med['expiryDate']}'),
            );
          },
        );
      },
    );
  }
}
