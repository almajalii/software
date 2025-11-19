import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/screens/main/welcome_screen.dart';
import 'package:meditrack/widgets/ExpiryReminder.dart';
import 'package:meditrack/widgets/app_bar.dart';
import 'package:meditrack/screens/Medicine/display_medicine.dart';
import 'package:meditrack/screens/Dosage/display_dosage.dart';

class NavigationMain extends StatefulWidget {
  const NavigationMain({super.key});

  @override
  State<NavigationMain> createState() => _NavigationMainstate();
}

class _NavigationMainstate extends State<NavigationMain> {
  final user = FirebaseAuth.instance.currentUser;
  int navIndex = 1;
  late final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Widget Function()> screens = [
    () => DisplayDosage(), //0
    () => WelcomeScreen(), //1
    () => DisplayMedicine(), //2
  ];

  @override
  Widget build(BuildContext context) {
    //provides the medicine bloc
    return Scaffold(
          appBar: MyAppBar.build(context, () => ExpiryReminder.showExpiredMedsSheet(context)),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navIndex,
            onTap: (value) {
              setState(() {
                navIndex = value;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.pills), label: 'Dosages'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
            ],
          ),

          body: screens[navIndex](),
        );
  }
}
