import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/classes/ExpiryReminder.dart';
import 'package:meditrack/classes/MyAppBar.dart';
import 'package:meditrack/screens/mainhome.dart';
import 'package:meditrack/screens/Inventory/ShowMed.dart';
import 'package:meditrack/screens/Dosage/ShowDosage.dart';


class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homestate();
}

class _homestate extends State<home> {
  final user = FirebaseAuth.instance.currentUser;
  int navIndex = 1;
  List<Widget Function()> screens = [
    () => Show(),//0
    () => Mainhome(),//1
    () => ShowInventory(),//2
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.build(context,   () => ExpiryReminder.showExpiredMedsSheet(context)),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex, 
        onTap: (value) {
          setState(() {
            navIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.pills),
            label: 'Dosages',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
        ],
      ),

      body: screens[navIndex](),
    );
  }
}
