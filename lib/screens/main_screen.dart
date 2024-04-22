import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<GroceryItem> listOfGroceryItems = [];

  void _loadDataFromFirebase() async {
    final url = Uri.https(
        'fluttertest-da2a0-default-rtdb.firebaseio.com', 'shopping_list.json');
    var result = await http.read(url);
    final Map<String, dynamic> fetchedData = json.decode(result);
    List<GroceryItem> newList = [];
    for (final data in fetchedData.entries) {
      var currentCategory = categories.entries
          .firstWhere(
              (category) => category.value.name == data.value['category'])
          .value;
      newList.add(GroceryItem(
          id: data.key,
          name: data.value['name'],
          quantity: int.parse(data.value['quantity']),
          category: currentCategory));
    }
    setState(() {
      listOfGroceryItems = newList;
    });
  }

  void _deleteItem(GroceryItem item) async {
    int index = listOfGroceryItems.indexOf(item);
    setState(() {
      listOfGroceryItems.remove(item);
    });
    final url = Uri.https('fluttertest-da2a0-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');

    final result = await http.delete(url);

    if (result.statusCode >= 400) {
      setState(() {
        listOfGroceryItems.insert(index, item);
      });
    }
  }

  void _addNewItem() async {
    var result = await Navigator.push<GroceryItem>(
        context, MaterialPageRoute(builder: (ctx) => const NewItem()));
    if (result == null) return;

    setState(() {
      listOfGroceryItems.add(result);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    var screen = Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Your Groceries',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(onPressed: _addNewItem, icon: const Icon(Icons.add))
        ],
      ),
      body: Center(
        child: Text('Empty list please add some items.',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Theme.of(context).colorScheme.background)),
      ),
    );

    if (listOfGroceryItems.isNotEmpty) {
      screen = Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              'Your Groceries',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              IconButton(onPressed: _addNewItem, icon: const Icon(Icons.add))
            ],
          ),
          body: ListView.builder(
              itemCount: listOfGroceryItems.length,
              itemBuilder: (ctx, index) => Dismissible(
                    key: Key(listOfGroceryItems[index].id),
                    child: ListTile(
                      leading: Container(
                        height: 24,
                        width: 24,
                        color: listOfGroceryItems[index].category.color,
                      ),
                      title: Text(listOfGroceryItems[index].name),
                      trailing:
                          Text(listOfGroceryItems[index].quantity.toString()),
                    ),
                    onDismissed: (direction) {
                      _deleteItem(listOfGroceryItems[index]);
                    },
                  )));
    }

    return screen;
  }
}
