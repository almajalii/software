import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/screens/main/settings.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';

class MyAppBar {
  static PreferredSizeWidget build(
      BuildContext context, VoidCallback onNotificationPressed) {
    final user = FirebaseAuth.instance.currentUser;
    final themeState = context.watch<ThemeBloc>().state;

    return AppBar(
      title: SizedBox(
        height: 70,
        width: 70,
        child: Image.asset('images/1.png'),
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
        },
        icon: Icon(Icons.settings),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('medicines')
              .snapshots(),
          builder: (context, snapshot) {
            bool hasExpired = false;
            final now = DateTime.now();

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('dateExpired')) {
                  try {
                    final expiry = (data['dateExpired'] as Timestamp).toDate();
                    if (expiry.isBefore(now)) {
                      hasExpired = true;
                      break;
                    }
                  } catch (_) {
                    // Ignore invalid timestamps
                  }
                }
              }
            }

            return Stack(
              children: [
                IconButton(
                  onPressed: onNotificationPressed,
                  icon: Icon(
                    hasExpired
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: hasExpired ? Colors.red : null,
                  ),
                ),
                if (hasExpired)
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: themeState.isDarkMode
              ? LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
          )
              : RadialGradient(
            colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
          ),
        ),
      ),
    );
  }
}