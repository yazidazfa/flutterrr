import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kopma/data/model/item/item_entity.dart';
import 'package:kopma/data/model/item/item_model.dart';
import 'package:kopma/data/model/transaction/transaction_model.dart';
import 'package:kopma/data/model/user/user_model.dart';
import '../../../di/service_locator.dart';
import '../../model/user/user_entity.dart';
import '../shared_preferences_service.dart';

class FirebaseItemDataSource {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  final itemsCollection = FirebaseFirestore.instance.collection('items');
  final itemsStorage = FirebaseStorage.instance.ref().child('/items');
  final transactionCollection =
  FirebaseFirestore.instance.collection('transaction');

  Future<bool> postItem(ItemModel item) async {
    try {
      final sharedPrefService = await SharedPreferencesService.getInstance();
      final userDoc = await usersCollection.doc(sharedPrefService.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final user = UserModel.fromEntity(UserEntity.fromDocument(userDoc.data()!));
        if (user.address != null && user.name.isNotEmpty) {
          String id = itemsCollection.doc().id;
          return await itemsCollection
              .doc(id)
              .set(item
              .toEntity(id, user.id, user.name, user.email, user.address!,
              user.image)
              .toDocument())
              .then((value) => true);
        } else {
          return false;
        }
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<ItemModel> getDetailItem(String id) async {
    try {
      final itemDoc = await itemsCollection.doc(id).get();
      if (itemDoc.exists && itemDoc.data() != null) {
        return ItemModel.fromEntity(ItemEntity.fromDocument(itemDoc.data()!));
      } else {
        log("Item with id $id not found");
        return ItemModel.empty;
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Query<Map<String, dynamic>> getListItem(String? query) {
    try {
      return itemsCollection.orderBy('name');
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<bool> buyItem(String itemId, int quantity) async {
    try {
      final sharedPrefService = await SharedPreferencesService.getInstance();

      // Check if sharedPrefService.uid is not null or empty
      if (sharedPrefService.uid.isNotEmpty) {
        ItemModel item = await getDetailItem(itemId);
        if (item == ItemModel.empty) {
          throw Exception("Item not found");
        }
        final userDoc = await usersCollection.doc(sharedPrefService.uid).get();
        if (!userDoc.exists || userDoc.data() == null) {
          throw Exception("User not found");
        }
        UserModel user = UserModel.fromEntity(UserEntity.fromDocument(userDoc.data()!));

        if ((item.quantity - quantity) >= 0) {
          int totalPrice = quantity * item.price;
          int userBalance = user.balance ?? 0;

          if (userBalance >= totalPrice) {
            await itemsCollection.doc(item.id).update(item
                .toEntity(itemId, item.sellerId!, item.sellerName!,
                item.sellerEmail!, item.sellerAddress!, item.sellerImage)
                .toDocument());

            await usersCollection.doc(user.id).update(user
                .copyWith(balance: userBalance - totalPrice)
                .toEntity()
                .toDocument());

            String id = transactionCollection.doc().id;
            if (user.address != null && user.address!.isNotEmpty) {
              return await transactionCollection
                  .doc(id)
                  .set(TransactionModel(
                  id: id,
                  dateTime: DateTime.now().toUtc(),
                  itemId: itemId,
                  itemName: item.name,
                  itemImage: item.image,
                  itemQuantity: quantity,
                  itemPrice: totalPrice,
                  buyerId: user.id,
                  buyerName: user.name,
                  buyerEmail: user.email,
                  buyerAddress: user.address!,
                  buyerMoney: userBalance,
                  sellerId: item.sellerId!,
                  sellerName: item.sellerName!,
                  sellerEmail: item.sellerEmail!,
                  sellerAddress: item.sellerAddress!,
                  sellerImage: item.sellerImage)
                  .toEntity()
                  .toDocument())
                  .then((value) => true);
            } else {
              throw Exception('Can\'t ship without an address! Add it now.');
            }
          } else {
            throw Exception('Bummer, balance is a bit low. Top up first?');
          }
        } else {
          throw Exception(
              'Insufficient stock.\nPlease reduce the quantity or choose a different item');
        }
      } else {
        throw Exception('Shared preferences UID is null or empty');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int updatedQuantity) async {
    try {
      await itemsCollection.doc(itemId).update({'quantity': updatedQuantity});
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<int> getQuantity(String itemId) async {
    try {
      final itemDoc = await itemsCollection.doc(itemId).get();
      if (itemDoc.exists && itemDoc.data() != null) {
        return itemDoc.data()!['quantity'] ?? 0;
      } else {
        throw Exception('Item not found or quantity unavailable');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }


  Future<bool> deleteItem(String itemId) {
    // TODO: implement deleteItem
    throw UnimplementedError();
  }

  Future<String> uploadImage(File file, String fileName) async {
    try {
      final TaskSnapshot snapshot =
      await itemsStorage.child(fileName).putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
