import 'package:flutter/material.dart';
import 'package:kopma/data/model/item/item_model.dart';
import '../../../di/service_locator.dart';
import '../data/item_repository.dart';

class CartHelper {
  static final ItemRepository _itemRepository = serviceLocator<ItemRepository>();

  static Future<bool> addItemToCart(ItemModel item) async {
    try {
      return await _itemRepository.addItemToCart(item);
    } catch (e) {
      print('Error adding item to cart: $e');
      return false;
    }
  }

  static Future<bool> removeItemFromCart(String itemId) async {
    try {
      return await _itemRepository.deleteItemFromCart(itemId);
    } catch (e) {
      print('Error removing item from cart: $e');
      return false;
    }
  }

  static Future<List<ItemModel>> getCartItems() async {
    try {
      return await _itemRepository.getListItemFromCart();
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  static Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    return _itemRepository.updateItemQuantityInCart(itemId, newQuantity);
  }
}
