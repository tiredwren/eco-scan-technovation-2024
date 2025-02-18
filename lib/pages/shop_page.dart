import 'package:barcode_scanner/components/item_tile.dart';
import 'package:barcode_scanner/models/shop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/items.dart';
import 'add_to_cart_page.dart';
import 'dart:developer' as devLog;

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late List<Item> allItems;
  late List<Item> displayedItems;

  @override
  void initState() {
    super.initState();
    // Initialize the list of items from the SustainableShop class
    allItems = Provider.of<SustainableShop>(context, listen: false).sustainableShop;
    displayedItems = List.from(allItems);
    devLog.log(allItems.toString(), name: "my log: ");
  }
  // add to saved items method
  void addToSaved(Item item) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userUid = user?.uid;

    if (userUid != null) {
      CollectionReference savedItemsCollection =
      FirebaseFirestore.instance.collection('users').doc(userUid).collection('saved items'); // Adjust the collection path

      // check if the item already exists in the user's collection
      QuerySnapshot queryResult =
      await savedItemsCollection.where('itemName', isEqualTo: item.name).get();

      if (queryResult.docs.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Center(
                child: Text("This item is already saved."),
              ),
            );
          },
        );
      } else {
        // converting the Item object to a map
        Map<String, dynamic> itemData = {
          'itemName': item.name,
          'price': item.price.toString(),
          'image': item.imagePath.toString(),
          'url': item.url.toString(),
          'sustainabilityScore': item.sustainabilityScore.toString()
        };

        // adding the item to the user's collection
        savedItemsCollection.add(itemData).then((value) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Center(
                  child: Text("Item saved."),
                ),
              );
            },
          );
        }).catchError((error) {
          print("Error adding item to Firestore: $error");
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Center(
                  child: Text("Error saving item."),
                ),
              );
            },
          );
        });
      }
    }
  }

  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedItems = List.from(allItems);
      } else {
        displayedItems = allItems.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Text(
              "Welcome to EcoScan",
              style: TextStyle(fontSize: 20),
            ),
            SearchBar(onQueryChanged: onQueryChanged),
            Expanded(
              child: ListView.builder(
                itemCount: displayedItems.length,
                itemBuilder: (context, index) {
                  Item eachItem = displayedItems[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddToCartPage(
                            item: eachItem,
                            addToSavedCallback: () => addToSaved(eachItem),
                          ),
                        ),
                      );
                    },
                    child: ItemTile(
                      item: eachItem,
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => AddToCartPage(
                          item: eachItem,
                          addToSavedCallback: () => addToSaved(eachItem),
                        ),
                            ),
                        );
                      }
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final Function(String) onQueryChanged;

  SearchBar({required this.onQueryChanged});

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  String query = '';

  void onQueryChanged(String newQuery) {
    setState(() {
      query = newQuery;
    });

    widget.onQueryChanged(newQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child:
      TextField(
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          labelText: 'Search',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.white),
          ),
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

    );
  }
}