import 'package:chat_test/pages/chat_page.dart';
import 'package:chat_test/pages/friends_page.dart';
import 'package:chat_test/pages/home_page.dart';
import 'package:chat_test/pages/profile_page.dart';
import 'package:flutter/material.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  List<Widget> pages = [
    const HomePage(),
    const FriendsPage(),
    const ChatPage(),
    const ProfilePage(),
  ];
  int selectedIndex = 0;
  void onNavItemTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(0),
        height: 65,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.grey[50],
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: selectedIndex,
          onTap: onNavItemTap,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_rounded,
                size: 30,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.people,
                size: 30,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.chat,
                size: 30,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 30,
              ),
              label: '',
            )
          ],
        ),
      ),
    );
  }
}
