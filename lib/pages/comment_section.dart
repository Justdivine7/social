import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:chat_test/auth/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentSection extends StatelessWidget {
  final String postId;

  const CommentSection({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseApi().user!.uid;
    final currentUser =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Text('Loading comments.....'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Be the first to comment'),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading comments'),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data!.docs[index];
                        final commenterId = comment.get('from');
                        return FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(commenterId)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.data() == null) {
                                return const Center(
                                  child: Text('No comments yet'),
                                );
                              }
                              final userDoc = snapshot.data!;
                              final profileImage = userDoc['image_url'] ??
                                  const AssetImage(
                                          'asset/images/profile-image.jpg')
                                      .toString();
                              bool picturePresent =
                                  profileImage == userDoc['image_url'];
                              bool isLiked = false;
                              var likes = 0;
                              if (comment.data().containsKey("likes")) {
                                isLiked = comment
                                    .data()["likes"]
                                    .contains(FirebaseApi().user?.uid);
                                likes = comment.data()["likes"].length;
                              }
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                            radius: 20,
                                            backgroundImage:
                                                NetworkImage(profileImage)),
                                        BubbleSpecialThree(
                                          text: comment.get('comment'),
                                          color: Colors.grey.shade300,
                                          isSender: false,
                                          tail: false,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (comment
                                                .data()
                                                .containsKey("likes")) {
                                              var likeCounter = comment
                                                  .data()["likes"] as List;
                                              if (likeCounter.contains(
                                                  FirebaseApi().user!.uid)) {
                                                likeCounter.remove(
                                                    FirebaseApi().user!.uid);
                                                FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(postId)
                                                    .collection('comments')
                                                    .doc(comment.id)
                                                    .update(
                                                        {'likes': likeCounter});
                                              } else {
                                                likeCounter.add(
                                                    FirebaseApi().user!.uid);
                                                FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(postId)
                                                    .collection('comments')
                                                    .doc(comment.id)
                                                    .update(
                                                        {'likes': likeCounter});
                                              }
                                            } else {
                                              FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(postId)
                                                  .collection('comments')
                                                  .doc(comment.id)
                                                  .update({
                                                'likes': [
                                                  FirebaseApi().user!.uid
                                                ]
                                              });
                                            }
                                          },
                                          child: Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_outline,
                                            color: isLiked
                                                ? Colors.red.shade800
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MessageBar(
                  sendButtonColor: Colors.purple.shade800,
                  onSend: (message) {
                    if (message.isEmpty) return;
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .add(
                      {
                        'from': FirebaseApi().user!.uid,
                        'to': postId,
                        'likes': [],
                        'timestamp': DateTime.now(),
                        'comment': message
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
