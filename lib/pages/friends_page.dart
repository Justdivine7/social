import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  void toggleFollow(String userId, bool isFollowing) {
    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final targetUserRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    if (isFollowing) {
      currentUserRef.update({
        'following': FieldValue.arrayRemove([userId])
      });
      targetUserRef.update({
        'followers': FieldValue.arrayRemove([currentUser.uid])
      });
    } else {
      currentUserRef.update({
        'following': FieldValue.arrayUnion([userId])
      });
      targetUserRef.update({
        'followers': FieldValue.arrayUnion([currentUser.uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: const Text(
            'Connect',
          ),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Text('Loading users......'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text('No users available'),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading users'),
                      );
                    }
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final users = snapshot.data!.docs[index];
                          final List<dynamic> followers =
                              users.data().containsKey('followers')
                                  ? users['followers']
                                  : [];
                          final isFollowing =
                              followers.contains(currentUser.uid);
                          if (users.get('userId') ==
                              FirebaseAuth.instance.currentUser?.uid) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          users['username'] ?? 'name',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(followers.length <= 1
                                            ? '${followers.length} follower'
                                            : '${followers.length} followers'),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6, horizontal: 12),
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                Colors.deepPurple.shade400,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onPressed: () {
                                            toggleFollow(users.id, isFollowing);
                                          },
                                          child: Text(
                                            isFollowing ? 'Unfollow' : 'Follow',
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: users['image_url'] == null
                                              ? const AssetImage(
                                                  'asset/images/profile-image.jpg')
                                              : NetworkImage(
                                                  users['image_url'],
                                                ),
                                          fit: BoxFit.cover,
                                        ),
                                        // borderRadius: BorderRadius.circular(8),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        });
                  })
            ],
          ),
        ));
  }
}
