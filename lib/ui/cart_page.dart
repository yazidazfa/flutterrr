import 'package:flutter/material.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import '../data/item_repository.dart';
import '../helper/cart_helper.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<ItemModel>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _cartItemsFuture = CartHelper.getCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: FutureBuilder<List<ItemModel>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading cart items'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No items in cart'));
          } else {
            List<ItemModel> cartItems = snapshot.data!;
            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                ItemModel item = cartItems[index];
                return ListTile(
                  leading: Image.network(
                    item.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seller: ${item.sellerName}'),
                      Text('Price: ${item.price}'),
                      Row(
                        children: [
                          Text('Quantity: '),
                          _buildQuantityAdjustment(item),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      bool success = await CartHelper.removeItemFromCart(item.id.toString());
                      if (success) {
                        setState(() {
                          // Reload cart items after item deletion
                          _loadCartItems();
                        });
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildQuantityAdjustment(ItemModel item) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () async {
            if (item.quantity > 1) {
              await CartHelper.updateItemQuantity(item.id.toString(), item.quantity - 1);
              // Reload cart items after quantity update
              _loadCartItems();
            }
          },
        ),
        Text('${item.quantity}'),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            await CartHelper.updateItemQuantity(item.id.toString(), item.quantity + 1);
            // Reload cart items after quantity update
            _loadCartItems();
          },
        ),
      ],
    );
  }
}
