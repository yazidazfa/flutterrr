import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/bloc/user_bloc/user_bloc.dart';
import 'package:kopma/data/model/item/item_model.dart';

import '../bloc/detail_item_bloc/detail_item_bloc.dart';

class CheckoutPage extends StatefulWidget {
  final ItemModel item;

  const CheckoutPage({Key? key, required this.item}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _quantity = 1;
  late int _totalPrice;

  @override
  void initState() {
    super.initState();
    _totalPrice = widget.item.price;
  }

  void _incrementCounter() {
    setState(() {
      if (_quantity < widget.item.quantity) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: BlocListener<DetailItemBloc, DetailItemState>(
        listener: (context, state) {
          if (state is BuyItemFailure) {
            showOkAlertDialog(context: context, title: "Error", message: state.errorMessage);
          } else if (state is BuyItemSuccess) {
            showOkAlertDialog(context: context, title: "Success", message: "Congrats! Your order is on its way!");
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
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
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text('Price: ${widget.item.price}'),
                                  SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: _decrementCounter,
                                        child: Text("-"),
                                      ),
                                      Text('$_quantity'),
                                      TextButton(
                                        onPressed: _incrementCounter,
                                        child: Text("+"),
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
                  SizedBox(height: 16.0),
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Seller",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Text("Name: ${widget.item.sellerName ?? ""}"),
                          Text("Email: ${widget.item.sellerEmail ?? ""}"),
                          Text("Address: ${widget.item.sellerAddress ?? ""}"),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
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
                              Text(
                                "Total Price",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                "$_totalPrice",
                                style: TextStyle(fontSize: 18.0),
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
                            child: Text("Pay Now"),
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
