import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/classes/Time.dart';
import 'package:meditrack/screens/Inventory/addMed.dart';
import 'package:meditrack/style/colors.dart';

class ShowInventory extends StatefulWidget {
  const ShowInventory({super.key});

  @override
  State<ShowInventory> createState() => _ShowInventoryState();
}

class _ShowInventoryState extends State<ShowInventory> {
  User? user = FirebaseAuth.instance.currentUser;
  final myTextField = MyTextField();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('medicines')
                .orderBy('addedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading medicines'));
          }
          //lists All Medicines
          final medicines = snapshot.data!.docs;
          if (medicines.isEmpty) {
            return const Center(child: Text('No medicines found'));
          }

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              //each med has its own data
              final data = medicines[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.all(20),
                shadowColor: AppColors.lightGray,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),

                child: ListTile(
                  //Medicine Name
                  title: Text(
                    data['name'] ?? 'No name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  //Medicine Type and Quantity
                  subtitle: Text('Type: ${data['type'] ?? 'Unknown'}\nQuantity: ${data['quantity'] ?? 0}'),
                  leading: Icon(FontAwesomeIcons.capsules, color: AppColors.primary),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //edit
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          TextEditingController nameController = TextEditingController(text: data['name']);
                          TextEditingController typeController = TextEditingController(text: data['type']);
                          TextEditingController quantityController = TextEditingController(
                            text: (data['quantity'] ?? '').toString(),
                          );
                          TextEditingController notesController = TextEditingController(text: data['notes']);
                          TextEditingController expiryDateController = TextEditingController(
                            text: data['expiryDate'] ?? '',
                          );
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  backgroundColor: AppColors.white,
                                  title: const Text('Edit Medicine'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        myTextField.buildTextField('Name', nameController),
                                        SizedBox(height: 10),
                                        myTextField.buildTextField('Type', typeController),
                                        SizedBox(height: 10),
                                        myTextField.buildTextField('Notes', notesController),
                                        SizedBox(height: 10),
                                        myTextField.buildTextField('Quantity', quantityController),
                                        SizedBox(height: 10),

                                        ExpiryDatePicker(
                                          controller: expiryDateController,
                                          labelText: "Expiry Date",
                                          onDateChanged: (date) {
                                            expiryDateController.text =
                                                "${date.day.toString().padLeft(2, '0')}-"
                                                "${date.month.toString().padLeft(2, '0')}-"
                                                "${date.year}";
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    ElevatedButton(
                                      child: const Text('Save'),
                                      onPressed: () async {
                                        //update on firestone
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user?.uid)
                                            .collection('medicines')
                                            .doc(medicines[index].id)
                                            .update({
                                              'name': nameController.text.trim(),
                                              'type': typeController.text.trim(),
                                              'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
                                              'expiryDate': expiryDateController.text.trim(),
                                              'notes': notesController.text.trim(),
                                            });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      //delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('medicines')
                              .doc(medicines[index].id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor: AppColors.white,
                            title: const Text('Medicine Details'),
                            content: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${data['name'] ?? 'No name'}'),
                                  Text('Type: ${data['type'] ?? 'Unknown'}'),
                                  Text('Quantity: ${data['quantity'] ?? 0}'),
                                  Text('Notes: ${data['notes'] ?? 'None'}'),
                                  Text('Reminder: ${data['reminderEnabled'] == true ? 'On' : 'Off'}'),
                                  Text('Expiry Date: ${data['expiryDate'] ?? 'Not set'}'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop()),
                            ],
                          ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      //add medicine button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => addMed()));
        },
        child: Icon(Icons.add, color: AppColors.darkBlue),
      ),
    );
  }
}
