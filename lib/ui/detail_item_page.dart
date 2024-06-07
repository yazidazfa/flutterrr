import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/bloc/detail_item_bloc/detail_item_bloc.dart';
import 'package:kopma/data/model/item/item_model.dart';
import 'package:kopma/di/service_locator.dart';

import '../data/item_repository.dart';
import 'checkout_page.dart';

class DetailItemPage extends StatefulWidget {
  final String idItem;

  const DetailItemPage({Key? key, required this.idItem}) : super(key: key);

  @override
  State<DetailItemPage> createState() => _DetailItemPageState();
}

class _DetailItemPageState extends State<DetailItemPage> {
  late final ItemRepository itemRepository;

  @override
  void initState() {
    super.initState();
    itemRepository = serviceLocator<ItemRepository>();
    context.read<DetailItemBloc>().add(GetDetailItem(itemId: widget.idItem));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<DetailItemBloc, DetailItemState>(
        listener: (context, state) {
          if (state == const DetailItemState.empty()) {
            const Text("No Data");
          }
          if (state is AddItemToCartFailure || state is BuyItemFailure) {
            showOkAlertDialog(
              context: context,
              title: "Error",
              message: "Failure to add to cart"
            );
            context.read<DetailItemBloc>().add(GetDetailItem(itemId: widget.idItem));
          } else if (state is AddItemToCartSuccess) {
            showOkAlertDialog(
              context: context,
              title: "Success",
              message: "Item added to cart: ${state.item?.name}",
            );
            context.read<DetailItemBloc>().add(GetDetailItem(itemId: widget.idItem));
          }
        },
        child: BlocBuilder<DetailItemBloc, DetailItemState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Column(
                      children: [
                        CachedNetworkImage(
                          imageUrl: state.item?.image ?? "",
                        ),
                        ListTile(
                          title: Text(state.item?.name ?? "",style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Stock: ${state.item?.quantity.toString() ?? ""}"),
                              Text("Price: ${state.item?.price.toString() ?? ""}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          title: const Text("Category"),
                          subtitle: Text(state.item?.category ?? ""),
                        ),
                        ListTile(
                          title: const Text("Description"),
                          subtitle: Text(state.item?.description ?? ""),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          title: Text("Seller: ${state.item?.sellerName ?? ""}"),
                          subtitle: Text("Address: ${state.item?.sellerAddress ?? ""}"),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                context.read<DetailItemBloc>().add(AddItemToCart(item: state.item!));
                              });
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text("Add to Cart"),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return CheckoutPage(item: state.item ?? ItemModel.empty);
                              }));
                            },
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text("Buy Now"),
                          ),
                        ),
                      ],
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
