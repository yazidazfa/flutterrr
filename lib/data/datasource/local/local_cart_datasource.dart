import 'dart:developer';
import 'package:isar/isar.dart';
import 'package:kopma/data/model/cart/cart_collection.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import 'local_database.dart';

class LocalCartDataSource {
  final localDatabase = serviceLocator<LocalDatabase>();

  Future<bool> addItemToCart(ItemModel item) async {
    try {
      final db = localDatabase.db;
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
          sellerImage: item.sellerImage);
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
    final cartItems = await getListItemFromCart();
    print('Items in cart: $cartItems');
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

  Future<bool> updateCartItemQuantity(String itemId, int newQuantity) async {
    try {
      final db = localDatabase.db;
      final item = await db.cartCollections.get(int.parse(itemId));
      if (item != null) {
        final updatedItem = CartCollection(
          itemId: item.itemId,
          name: item.name,
          image: item.image,
          category: item.category,
          description: item.description,
          quantity: newQuantity, // Update quantity here
          price: item.price,
          sellerId: item.sellerId,
          sellerName: item.sellerName,
          sellerEmail: item.sellerEmail,
          sellerAddress: item.sellerAddress,
          sellerImage: item.sellerImage,
        );
        await db.writeTxn(() async {
          await db.cartCollections.put(updatedItem);
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
  // Helper method to convert CartCollection to ItemModel
  ItemModel _convertToItemModel(CartCollection item) {
    return ItemModel(
      id: item.id.toString(),
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
  }
}