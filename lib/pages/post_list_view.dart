import 'package:chat_test/auth/firestore_service.dart';
import 'package:chat_test/components/function.dart';
import 'package:chat_test/components/show_video.dart';
import 'package:chat_test/pages/comment_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostListView extends StatefulWidget {
  const PostListView({super.key});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
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
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdat', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Text("No post available"),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.size,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];

            bool isLiked = false;
            var likes = 0;
            if (post.data().containsKey("likes")) {
              isLiked = post.data()["likes"].contains(FirebaseApi().user?.uid);
              likes = post.data()["likes"].length;
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(post.get('userId'))
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.hasError) {
                            return const SizedBox.shrink();
                          }
                          return userProfile(snapshot.data!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                GestureDetector(
                  child: post.get('type') == postType.image.name
                      ? Container(
                          height: 500,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: NetworkImage(
                                  post.get('posturl'),
                                ),
                                fit: BoxFit.cover),
                          ),
                        )
                      : ShowVideo(
                          uri: post.get('posturl'),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (post.data().containsKey("likes")) {
                            final likeReader = post.data()["likes"] as List;
                            if (likeReader.contains(FirebaseApi().user!.uid)) {
                              likeReader.remove(FirebaseApi().user!.uid);
                              FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(post.id)
                                  .update({
                                "likes": likeReader,
                              });
                            } else {
                              likeReader.add(FirebaseApi().user!.uid);
                              FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(post.id)
                                  .update({
                                "likes": likeReader,
                              });
                            }
                          } else {
                            FirebaseFirestore.instance
                                .collection("posts")
                                .doc(post.id)
                                .update({
                              "likes": [FirebaseApi().user!.uid]
                            });
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_outline,
                                  color: isLiked
                                      ? Colors.red.shade800
                                      : Colors.grey[800],
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  '$likes',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                    // enableDrag: false,
                                    isDismissible: true,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (context) {
                                      return CommentSection(
                                        postId: post.id,
                                      );
                                    });
                              },
                              child: Row(
                                children: [
                                  StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(post.id)
                                        .collection('comments')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Row(
                                          children: [
                                            const Text('0'),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Icon(
                                              Icons.comment,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ); // No comments
                                      }
                                      int comments = snapshot.data!.docs.length;
                                      return Row(
                                        children: [
                                          Text(
                                            comments.toString(),
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Icon(
                                            Icons.comment,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Row userProfile(DocumentSnapshot<Map<String, dynamic>> post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 20,
              backgroundImage: post['image_url'] == null
                  ? const AssetImage(
                      "asset/images/profile-image.jpg",
                    )
                  : NetworkImage(
                      post['image_url'],
                    ),
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              post['display_name'] ?? "not set",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Loading...");
                }
                 
                bool isFollowing = snapshot.data!['following']
                    .contains(post.id); // Check if following
                return GestureDetector(
                  onTap: () {
                    toggleFollow(post.id, isFollowing);
                  },
                  child: Text(
                    currentUser.uid == post.get('userId')
                        ? ''
                        : isFollowing
                            ? 'Following'
                            : 'Follow',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        GestureDetector(
          // onTap: () {
          //   try {
          //     FirebaseFirestore.instance
          //         .collection('posts')
          //         .doc(post.id)
          //         .delete();
          //   } catch (e) {
          //     print(e);
          //   }
          // },
          child: Container(
            // width: 50,
            // height: 50,
            // decoration: BoxDecoration(color: Colors.deepPurple),
            child: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }
}
