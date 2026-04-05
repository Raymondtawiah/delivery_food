import 'package:firebase_database/firebase_database.dart';
import '../pages/menu_page.dart';

class FirebaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  static Future<List<MenuItem>> getMenuItems() async {
    List<MenuItem> menuItems = [];
    
    try {
      DatabaseReference menuRef = _database.ref().child('menu');
      final snapshot = await menuRef.get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            menuItems.add(MenuItem(
              name: value['name'] ?? '',
              price: value['price'] ?? '₵0.00',
              imageAsset: value['image'] ?? 'assets/images/jollof.jpg',
            ));
          }
        });
      }
    } catch (e) {
      // Return empty list if Firebase is not connected
    }
    
    return menuItems;
  }
}