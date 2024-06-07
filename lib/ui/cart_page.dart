import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import '../bloc/detail_item_bloc/detail_item_bloc.dart';
import '../data/datasource/local/local_cart_datasource.dart';
import '../data/datasource/network/firebase_item_datasource.dart';
import '../data/item_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<ItemModel>> _cartItemsFuture;
  LocalCartDataSource cartDataSource = LocalCartDataSource(FirebaseItemDataSource());
  final ItemRepository _itemRepository = serviceLocator<ItemRepository>();
  Map<String, int> _quantities = {};
  List<ItemModel> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _buyItem(BuildContext context, String? itemIdIsar, String? itemId, int quantity) async {
    bool success = await cartDataSource.buyItemFromCart(context, itemIdIsar!, itemId!, quantity);
    if (success) {
      await _updateFirebaseQuantity(itemId, quantity);
      await Future.delayed(Duration(milliseconds: 500));
      _loadCartItems();
      showOkAlertDialog(context: context, title: "Success", message: "Congrats! Your order is on its way!");
    }
  }
  Future<void> _updateFirebaseQuantity(String itemId, int quantityBought) async {
    try {
      // Dapatkan kuantitas saat ini dari Firebase
      int currentQuantity = await FirebaseItemDataSource().getQuantity(itemId);

      // Kurangi kuantitas yang dibeli dari kuantitas saat ini
      int updatedQuantity = currentQuantity - quantityBought;

      // Perbarui kuantitas di Firebase
      await FirebaseItemDataSource().updateQuantity(itemId, updatedQuantity);
    } catch (e) {
      print('Error updating quantity in Firebase: $e');
      // Handle error
    }
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _cartItemsFuture = _itemRepository.getListItemFromCart();
      isLoading = true; // Set loading state to true
    });

    try {
      final items = await _cartItemsFuture;
      setState(() {
        _quantities = {};
        isLoading = false; // Set loading state to false when loading is complete
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Set loading state to false on error
      });
      // Handle error
      print('Error loading cart items: $e');
    }
  }

  Future<void> _incrementCounter(String itemId) async {
    setState(() {
      int currentQuantity = _quantities[itemId] ?? 1; // Default to 1 if quantity is not set
      _quantities[itemId] = currentQuantity + 1;
    });
  }

  Future<void> _decrementCounter(String itemId) async {
    setState(() {
      int currentQuantity = _quantities[itemId] ?? 1; // Default to 1 if quantity is not set
      if (currentQuantity > 1) {
        _quantities[itemId] = currentQuantity - 1;
      }
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _itemRepository.deleteItemFromCart(itemId);
    _loadCartItems();
  }

  int _calculateTotalPrice(ItemModel item, int quantity) {
    return item.price * quantity;
  }

  Future<void> _checkout(BuildContext context) async {
    List<Map<String, dynamic>> itemsToBuy = [];

    // Iterate through cart items and collect information
    for (var item in cartItems) {
      String itemId = item.id!;
      int quantity = _quantities[itemId] ?? 1; // Default to 1 if quantity is not set
      itemsToBuy.add({
        'itemId': itemId,
        'quantity': quantity,
      });
    }

    // Call the buy method once with all items to be purchased
    bool success = await cartDataSource.buyBulkFromCart(context, itemsToBuy);

    if (success) {
      _loadCartItems(); // Refresh cart after successful purchase
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCartItems(), // Reload cart items when refreshed
        child: FutureBuilder<List<ItemModel>>(
          future: _cartItemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading cart items'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No items in cart'));
            } else {
              cartItems = snapshot.data!;
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        ItemModel item = cartItems[index];
                        String itemId = item.id!;
                        int quantity = _quantities[itemId] ?? 1; // Default to 1 if quantity is not set
                        int totalPrice = _calculateTotalPrice(item, quantity);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    height: 120,
                                    child: CachedNetworkImage(
                                      imageUrl: item.image,
                                      fit: BoxFit.fitHeight,
                                      imageBuilder: (context, imageProvider) => Container(
                                        height: 120,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.fitHeight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('Seller: ${item.sellerName}'),
                                        Text('Rp.${item.price}'),
                                        Text('Total: Rp.${totalPrice.toString()}'),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () => _decrementCounter(itemId),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjust the horizontal padding as needed
                                              child: Text('$quantity'),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => _incrementCounter(itemId),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0), // Add some bottom padding
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            _deleteItem(itemId);
                                          },
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _buyItem(context, item.id, item.itemId, quantity);
                                        },
                                        child: const Text('Beli'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _checkout(context);
                      },
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
