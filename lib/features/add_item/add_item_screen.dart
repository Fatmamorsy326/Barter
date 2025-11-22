import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';

class AddItemScreen extends StatefulWidget {
  final ItemModel? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit == null ? 'Add Item' : 'Edit Item'),
      ),
      body: const Center(
        child: Text('AddItemScreen'),
      ),
    );
  }
}
