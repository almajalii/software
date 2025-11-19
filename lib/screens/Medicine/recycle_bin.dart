import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';

class RemovedMedicinesScreen extends StatefulWidget {
  final String userId;
  const RemovedMedicinesScreen({super.key, required this.userId});

  @override
  State<RemovedMedicinesScreen> createState() => _RemovedMedicinesScreenState();
}

class _RemovedMedicinesScreenState extends State<RemovedMedicinesScreen> {

  @override
  void initState() {
    super.initState();
    // Load removed medicines only once when the screen opens
    context.read<MedicineBloc>().add(LoadRemovedMedicinesEvent(widget.userId));
  }

  void _deleteMedicine(Medicine med) {
    context.read<MedicineBloc>().add(DeleteMedicineEvent(widget.userId, med.id));

    // Optional: show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} deleted permanently!'),
        duration: const Duration(milliseconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recycle Bin"),
        backgroundColor: const Color(0xFF00B9E4),
      ),

      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, state) {

          if (state is MedicineLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RemovedMedicinesLoadedState) {
            final List<Medicine> removed = state.removedMedicines;

            if (removed.isEmpty) {
              return const Center(
                child: Text(
                  "No removed medicines",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: removed.length,
              itemBuilder: (_, i) {
                final med = removed[i];
                return ListTile(
                  title: Text(med.name),
                  subtitle: Text("Type: ${med.type} - Qty: ${med.quantity}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _deleteMedicine(med),
                    tooltip: 'Delete permanently',
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text("Something went wrong"),
          );
        },
      ),
    );
  }
}
