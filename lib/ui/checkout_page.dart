import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/bloc/user_bloc/user_bloc.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../bloc/detail_item_bloc/detail_item_bloc.dart';
import '../data/datasource/network/firebase_item_datasource.dart';

class CheckoutPage extends StatefulWidget {
  final ItemModel item;

  const CheckoutPage({Key? key, required this.item}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _quantity = 1;
  late int _totalPrice;
  late int _maxQuantity; // Store the maximum quantity available in Firebase

  @override
  void initState() {
    super.initState();
    _totalPrice = widget.item.price;
    _fetchMaxQuantity(); // Fetch the maximum quantity from Firebase
  }

  Future<void> _fetchMaxQuantity() async {
    try {
      _maxQuantity = await FirebaseItemDataSource().getQuantity(widget.item.id!);
      setState(() {});
    } catch (e) {
      print('Error fetching quantity from Firebase: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      if (_quantity < _maxQuantity) {
        _quantity += 1;
        _totalPrice = _quantity * widget.item.price;
      }
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_quantity > 1) {
        _quantity -= 1;
        _totalPrice = _quantity * widget.item.price;
      }
    });
  }

  Future<void> _updateFirebaseQuantity() async {
    try {
      int currentQuantity = await FirebaseItemDataSource().getQuantity(widget.item.id!);
      int updatedQuantity = currentQuantity - _quantity;
      await FirebaseItemDataSource().updateQuantity(widget.item.id!, updatedQuantity);
    } catch (e) {
      print('Error updating quantity in Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: BlocListener<DetailItemBloc, DetailItemState>(
        listener: (context, state) async {
          if (state is BuyItemFailure) {
            showOkAlertDialog(context: context, title: "Error", message: state.errorMessage);
          } else if (state is BuyItemSuccess) {
            await _updateFirebaseQuantity(); // Update Firebase quantity after a successful purchase
            showOkAlertDialog(context: context, title: "Success", message: "Congrats! Your order is on its way!");
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.item.image,
                            width: 160,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text('Price: ${widget.item.price}'),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: _decrementCounter,
                                        child: const Text("-"),
                                      ),
                                      Text('$_quantity'),
                                      TextButton(
                                        onPressed: _incrementCounter,
                                        child: const Text("+"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Seller",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text("Name: ${widget.item.sellerName ?? ""}"),
                          Text("Email: ${widget.item.sellerEmail ?? ""}"),
                          Text("Address: ${widget.item.sellerAddress ?? ""}"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Price",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "$_totalPrice",
                                style: const TextStyle(fontSize: 18.0),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.read<DetailItemBloc>().add(BuyItem(
                                itemId: widget.item.id!,
                                quantity: _quantity,
                              ));
                            },
                            child: const Text("Pay Now"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
