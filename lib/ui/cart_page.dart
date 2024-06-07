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
  final String currentUserId;
  const CartPage({Key? key, required this.currentUserId}) : super(key: key);


  @override
  State<CartPage> createState() => _CartPageState(currentUserId: currentUserId);
}

class _CartPageState extends State<CartPage> {
  final String currentUserId;
  _CartPageState({required this.currentUserId});
  late Future<List<ItemModel>> _cartItemsFuture;
  LocalCartDataSource cartDataSource = LocalCartDataSource(FirebaseItemDataSource());
  final ItemRepository _itemRepository = serviceLocator<ItemRepository>();
  Map<String, int> _quantities = {};
  List<ItemModel> cartItems = [];
  bool isLoading = true;
  int _totalPrice = 0;

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
      int currentQuantity = await FirebaseItemDataSource().getQuantity(itemId);
      int updatedQuantity = currentQuantity - quantityBought;
      await FirebaseItemDataSource().updateQuantity(itemId, updatedQuantity);
    } catch (e) {
      print('Error updating quantity in Firebase: $e');
    }
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _cartItemsFuture = _itemRepository.getListItemFromCart();
      isLoading = true;
    });

    try {
      final items = await _cartItemsFuture;
      setState(() {
        cartItems = items;
        _quantities = {for (var item in items) item.id!: 1}; // Initialize quantities to 1
        _calculateTotalPrice();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading cart items: $e');
    }
  }

  void _calculateTotalPrice() {
    setState(() {
      _totalPrice = cartItems.fold(0, (total, item) {
        int quantity = _quantities[item.id!] ?? 1; // Default quantity to 1
        return total + (item.price * quantity);
      });
    });
  }

  Future<void> _incrementCounter(String itemId) async {
    setState(() {
      int currentQuantity = _quantities[itemId] ?? 1;
      _quantities[itemId] = currentQuantity + 1;
      _calculateTotalPrice();
    });
  }

  Future<void> _decrementCounter(String itemId) async {
    setState(() {
      int currentQuantity = _quantities[itemId] ?? 1;
      if (currentQuantity > 1) {
        _quantities[itemId] = currentQuantity - 1;
        _calculateTotalPrice();
      }
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _itemRepository.deleteItemFromCart(itemId);
    _loadCartItems();
  }

  Future<void> _buyBulk(BuildContext context, List<ItemModel> cartItemsWithQuantities, int totalPrice) async {
    bool success = await cartDataSource.buyBulkFromCart(context, cartItemsWithQuantities, totalPrice);
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      _loadCartItems();
    }
  }

  void _checkout(BuildContext context) {
    List<ItemModel> cartItemsWithQuantities = cartItems.map((item) {
      return item.copyWith(quantity: _quantities[item.id!] ?? 1);
    }).toList();
    _buyBulk(context, cartItemsWithQuantities, _totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCartItems,
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
                        int quantity = _quantities[itemId] ?? 1; // Default quantity to 1
                        int totalPrice = item.price * quantity;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Equal padding on top and bottom
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  CachedNetworkImage(
                                    imageUrl: item.image,
                                    height: 160,
                                    width: 130,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text('Seller: ${item.sellerName}'),
                                        const SizedBox(height: 5),
                                        Text('Price: Rp.${item.price}'),
                                        const SizedBox(height: 5),
                                        Text('Total: Rp.${totalPrice.toString()}'),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: <Widget>[
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 24), // Increase size to 24
                                              onPressed: () => _decrementCounter(itemId),
                                            ),
                                            const SizedBox(width: 5), // Add some horizontal space between icons and quantity text
                                            Text('$quantity'),
                                            const SizedBox(width: 5), // Add some horizontal space between quantity text and add icon
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 24), // Increase size to 24
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
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 24),
                                        onPressed: () {
                                          _deleteItem(itemId);
                                        },
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _buyItem(context, item.id, item.itemId, quantity);
                                        },
                                        child: const Text('Buy'),
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
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: Rp.${_totalPrice.toString()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _checkout(context);
                          },
                          child: const Text('Checkout'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
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
