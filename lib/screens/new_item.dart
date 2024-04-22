import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  bool isUploading = false;
  late String _enteredName = '';
  late String _enteredQuantity = '1';
  var selectedCategory = categories[Categories.fruit];
  final _kKey = GlobalKey<FormState>();

  void _saveNewItem() async {
    if (_kKey.currentState!.validate()) {
      _kKey.currentState!.save();

      setState(() {
        isUploading = true;
      });
      try {
        final url = Uri.https('fluttertest-da2a0-default-rtdb.firebaseio.com',
            'shopping_list.json');
        var result = await http.post(url,
            headers: {'Content-type': 'application/json'},
            body: json.encode({
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'category': selectedCategory!.name
            }));

        if (!context.mounted) {
          return;
        }
        final Map<String, dynamic> returnData = json.decode(result.body);

        setState(() {
          isUploading = false;
        });

        Navigator.pop(
            context,
            GroceryItem(
                id: returnData['name'],
                name: _enteredName,
                quantity: int.parse(_enteredQuantity),
                category: selectedCategory!));
      } catch (error) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: isUploading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Form(
                  key: _kKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          label: Text('New item'),
                        ),
                        maxLength: 50,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length <= 1) {
                            return 'Enter at least 2 characters';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredName = value!;
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '1',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  label: Text('Quantity')),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    int.tryParse(value) == null ||
                                    int.parse(value) < 1) {
                                  return 'The number must be greater or equal to 1';
                                }
                              },
                              onSaved: (value) {
                                _enteredQuantity = value!;
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: DropdownButtonFormField(
                                value: selectedCategory,
                                items: [
                                  for (final val in categories.entries)
                                    DropdownMenuItem(
                                      value: val.value,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            color: val.value.color,
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text(val.value.name),
                                        ],
                                      ),
                                    )
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    selectedCategory = val;
                                  });
                                }),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  _kKey.currentState!.reset();
                                });
                              },
                              child: const Text('Reset')),
                          const SizedBox(
                            width: 6,
                          ),
                          ElevatedButton(
                              onPressed: _saveNewItem,
                              child: const Text('Save'))
                        ],
                      )
                    ],
                  )),
            ),
    );
  }
}
