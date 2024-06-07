import 'dart:developer';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:kopma/data/datasource/network/firebase_item_datasource.dart';
import 'package:kopma/data/model/cart/cart_collection.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import '../../model/user/user_entity.dart';
import '../../model/user/user_model.dart';
import 'local_database.dart';
import '../shared_preferences_service.dart';

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



  Future<bool> buyItemFromCart(BuildContext context, String isarID, itemId, int quantity) async {
    try {
      await _firebaseItemDataSource.buyItem(itemId, quantity);
      deleteItemFromCart(isarID);
      return true;
    } catch (e) {
      log(e.toString());
      showOkAlertDialog(context: context, title: "Failed", message: "Insufficient stock for this product");
      rethrow;
    }
  }

  Future<bool> updateItemQuantity(String? itemId, String itemIdFirebase, int newQuantity) async {
    int idItem = int.parse(itemId!);
    if (itemId == null) {
      log('Item ID is null');
      return false;
    }
    try {
      final db = localDatabase.db;
      final item = await db.cartCollections.filter().idEqualTo(idItem).findFirst();
      if (item != null) {
        final updatedItem = CartCollection(
          id: idItem,
          itemId: itemIdFirebase,
          name: item.name,
          image: item.image,
          category: item.category,
          description: item.description,
          quantity: newQuantity,
          price: item.price,
          sellerId: item.sellerId,
          sellerName: item.sellerName,
          sellerEmail: item.sellerEmail,
          sellerAddress: item.sellerAddress,
          sellerImage: item.sellerImage,
        );
        await db.writeTxn(() async => db.cartCollections.put(updatedItem));

        return true;
      }
      return false; // Item not found
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<bool> buyBulkFromCart(BuildContext context, List<ItemModel> cartItems, int totalPrice) async {
    try {
      UserModel user = await FirebaseItemDataSource().usersCollection
          .doc(FirebaseItemDataSource().sharedPrefService.uid)
          .get()
          .then((value) => UserModel.fromEntity(UserEntity.fromDocument(value.data()!)));
      int userBalance = user.balance ?? 0;

      if (userBalance >= totalPrice) {
        List<String> outOfStockItems = [];
        for (var cartItem in cartItems) {
          ItemModel item = await FirebaseItemDataSource().getDetailItem(cartItem.itemId!);
          if ((item.quantity - cartItem.quantity) >= 0) {
            // The item is in stock
          } else {
            outOfStockItems.add(cartItem.name);
          }
        }
        if (outOfStockItems.isEmpty) {
          for (var cartItem in cartItems) {
            await FirebaseItemDataSource().buyItem(cartItem.itemId!, cartItem.quantity);
            log('buying ${cartItem.itemId!}, ${cartItem.quantity}');
            await deleteItemFromCart(cartItem.id!);
            log('deleting ${cartItem.id}');
          }
          showOkAlertDialog(context: context, title: "Success", message: "Congrats! Your order is on its way!");
        } else {
          showOkAlertDialog(
            context: context,
            title: "Out of Stock Item(s)",
            message: "The following items are out of stock: ${outOfStockItems.join(', ')}",
          );
          return false;
        }
        return true;
      } else {
        showOkAlertDialog(context: context, title: "Failed", message: "You don't have enough balance!");
        return false;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}