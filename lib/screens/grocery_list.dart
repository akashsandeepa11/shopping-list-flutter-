import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadItems();
    error = null;
  }

  void _loadItems() async {
    final url = Uri.https(
        "flutter-prep-3038f-default-rtdb.firebaseio.com", "shopping-list.json");

    try {
      final response = await http.get(url);

      if (response.body == "null") {
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          error = "Failed to fetch data. Please try again later.";
        });
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final Category category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category,
          ),
        );
      }

      setState(
        () {
          _groceryItems = loadedItems;
          isLoading = false;
        },
      );
    } catch (e) {
      setState(() {
        error = "Something went wrong!. Please try again later.";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    _loadItems();

    if (newItem == null) {
      return;
    }

    _groceryItems.add(newItem);
  }

  void _removeItem(GroceryItem item) {
    final url = Uri.https("flutter-prep-3038f-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");

    http.delete(url);

    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Item deleted."),
      action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              _groceryItems.insert(index, item);
            });
          }),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No items added yet"),
    );

    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index]),
          onDismissed: (direction) {
            return _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(
              _groceryItems[index].name,
              style: const TextStyle(fontSize: 16),
            ),
            leading: Container(
              width: 16,
              height: 16,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Groceries")),
      body: content,
      floatingActionButton: IconButton(
        onPressed: _addItem,
        icon: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
