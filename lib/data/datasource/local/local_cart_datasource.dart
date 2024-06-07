import 'dart:developer';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:kopma/data/datasource/network/firebase_item_datasource.dart';
import 'package:kopma/data/model/cart/cart_collection.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import 'local_database.dart';

class ItemAlreadyExistsException implements Exception {
  String message = 'Item already exists in your cart';
  ItemAlreadyExistsException(this.message);
}

class LocalCartDataSource {
  final localDatabase = serviceLocator<LocalDatabase>();
  final FirebaseItemDataSource _firebaseItemDataSource;
  LocalCartDataSource(this._firebaseItemDataSource);

  Future<bool> addItemToCart(ItemModel item) async {
    try {
      final db = localDatabase.db;
      var existingItems = await db.cartCollections.filter().itemIdEqualTo(item.id).findAll();
      if (existingItems.isNotEmpty) {
        throw ItemAlreadyExistsException("Item with ID ${item.id} already exists in the cart.");
      }
      CartCollection cartCollection = CartCollection(
        itemId: item.id,
        name: item.name,
        image: item.image,
        category: item.category,
        description: item.description,
        quantity: item.quantity,
        price: item.price,
        sellerId: item.sellerId,
        sellerName: item.sellerName,
        sellerEmail: item.sellerEmail,
        sellerAddress: item.sellerAddress,
        sellerImage: item.sellerImage,
      );

      return await db
          .writeTxn(() async => db.cartCollections.put(cartCollection))
          .then((value) => true);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<List<ItemModel>> getListItemFromCart() async {
    try {
      final db = localDatabase.db;
      return await db.cartCollections.where().findAll().then((value) =>
          value.map((item) =>
              ItemModel(
                id: item.id.toString(),
                itemId: item.itemId,
                name: item.name,
                image: item.image,
                category: item.category,
                description: item.description,
                quantity: item.quantity,
                price: item.price,
                sellerId: item.sellerId,
                sellerName: item.sellerName,
                sellerEmail: item.sellerEmail,
                sellerAddress: item.sellerAddress,
                sellerImage: item.sellerImage,
              )
          ).toList()
      );
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> _logCartItems() async {
    try {
      final cartItems = await getListItemFromCart();
      print('Items in cart: $cartItems');
    } catch (e, stackTrace) {
      print('Error logging cart items: $e');
      print(stackTrace);
    }
  }

  Future<bool> deleteItemFromCart(String itemId) async {
    try {
      await _logCartItems();
      final db = localDatabase.db;
      return await db.writeTxn(() async => db.cartCollections.filter().idEqualTo(int.parse(itemId)).deleteAll()).then((value) => true);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
  //   try {
  //     await _logCartItems();
  //     final db = localDatabase.db;
  //     final cartCollection = await db.cartCollections.filter().itemIdEqualTo(itemId).findFirst();
  //     if (cartCollection != null) {
  //       cartCollection.quantity = newQuantity;
  //       await db.writeTxn(() async {
  //         await db.cartCollections.put(cartCollection);
  //       });
  //       return true;
  //     } else {
  //       return false; // Item not found
  //     }
  //   } catch (e, stackTrace) {
  //     print('Error updating item quantity in database: $e');
  //     print(stackTrace); // Print the stack trace
  //     return false;
  //   }
  // }

  Future<bool> buyItemFromCart(BuildContext context, String isarID, itemId, int quantity) async {
    try {
      await _firebaseItemDataSource.buyItem(itemId, quantity);
      showOkAlertDialog(context: context, title: "Success", message: "Congrats! Your order is on its way!");
      deleteItemFromCart(isarID);
      return true;
    } catch (e) {
      log(e.toString());
      showOkAlertDialog(context: context, title: "Failed", message: "Insufficient stock for this product");
      rethrow;
    }
  }

}