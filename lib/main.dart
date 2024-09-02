import 'package:flutter/material.dart';
import 'package:my_app_card/gong_ju/auth_porvider.dart';
import 'package:my_app_card/login_page/logout.dart';
import 'package:my_app_card/login_page/ru_kou.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: FutureBuilder(
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (ctx, authResultSnapshot) {
          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            return Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return auth.isLoggedIn ? const BottomNavBarExample() : AuthPage();
              },
            );
          }
        },
      ),
    );
  }
}

//底部導航欄
class BottomNavBarExample extends StatefulWidget {
  const BottomNavBarExample({Key? key}) : super(key: key);

  @override
  _BottomNavBarExampleState createState() => _BottomNavBarExampleState();
}

class _BottomNavBarExampleState extends State<BottomNavBarExample> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    return <Widget>[
      const Logout(),
      // Add other pages here
      Container(child: Center(child: Text('產品頁面'))),
      Container(child: Center(child: Text('收藏頁面'))),
      Container(child: Center(child: Text('購物車頁面'))),
      Container(child: Center(child: Text('個人中心頁面'))),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopify),
            label: '產品',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '購物車',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '個人中心',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}