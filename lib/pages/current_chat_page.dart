import 'dart:io';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:chat_test/pages/send_image_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CurrentChatPage extends StatefulWidget {
  final String receiverId;
  const CurrentChatPage({
    super.key,
    required this.receiverId,
  });

  @override
  State<CurrentChatPage> createState() => _CurrentChatPageState();
}

class _CurrentChatPageState extends State<CurrentChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final ScrollController scrollController = ScrollController();
  final ImagePicker imagePicker = ImagePicker();
  File? postFile;

  // void scrollToBottom() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (scrollController.hasClients) {
  //       scrollController.jumpTo(scrollController.position.maxScrollExtent);
  //     }
  //   });
  // }

  void markMessagesAsSeen() {
    FirebaseFirestore.instance
        .collection('messages')
        .where(
          Filter.and(
            Filter('from', isEqualTo: widget.receiverId),
            Filter('to', isEqualTo: currentUser.uid),
            Filter('seen', isEqualTo: false),
          ),
        )
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'seen': true});
      }
    });
  }

  String formatDateTime(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }

  Future pickImage() async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return Fluttertoast.showToast(msg: 'No image was picked');
    } else {
      postFile = File(image.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SendImagePage(
            postFile: postFile,
            receiverId: widget.receiverId,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    markMessagesAsSeen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.receiverId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              // Show a loading text while waiting for the data
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading...');
              }

              // Ensure data exists before accessing it
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('User not found');
              }
              final currentChatReceiver = snapshot.data!;
              // final currentChatReceiverImage =
              //     currentChatReceiver.get('image_url');

              return Row(
                children: [
                  Text(currentChatReceiver['username']),
                ],
              );
            }),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        // leading: GestureDetector(
        //   onTap: () {
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => ChatPage(),
        //       ),
        //     );
        //   },
        //   child: const Icon(Icons.arrow_back_ios),
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where(
                  Filter.or(
                    Filter.and(
                      Filter('from', isEqualTo: widget.receiverId),
                      Filter('to', isEqualTo: currentUser.uid),
                    ),
                    Filter.and(
                      Filter('from', isEqualTo: currentUser.uid),
                      Filter('to', isEqualTo: widget.receiverId),
                    ),
                  ),
                )
                .orderBy('timestamp', descending: false)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading...');
              }
              if (snapshot.data == null) {
                return const Text('No messages yet.');
              }
              return ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final message = snapshot.data!.docs[index];
                  final isSender = message.data().containsKey('from') &&
                      message['from'] == currentUser.uid;
                  final textMessage = message.data().containsKey('message')
                      ? message['message']
                      : '';
                  final imageUrl = message.data().containsKey('imageurl')
                      ? message['imageurl']
                      : null;
                  final caption = message.data().containsKey('caption')
                      ? message['caption']
                      : '';

                  return Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.3,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6)),
                                image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover),
                              ),
                            ),
                            if (caption.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(6),
                                width: MediaQuery.of(context).size.width * 0.5,
                                decoration: BoxDecoration(
                                  color: isSender
                                      ? Colors.deepPurple.shade400
                                      : Colors.deepPurple.shade200,
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(6),
                                      bottomRight: Radius.circular(6)),
                                ),
                                child: Text(
                                  caption,
                                  style: TextStyle(
                                      color: isSender
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              )
                          ],
                        ),
                      const SizedBox(
                        height: 15,
                      ),
                      if (textMessage.isNotEmpty)
                        Column(
                          children: [
                            BubbleSpecialThree(
                              isSender: isSender,
                              sent: true,
                              tail: false,
                              seen: message['seen'],
                              delivered: true,
                              text: message.get('message'),
                              textStyle: TextStyle(
                                color: message.get('from').toString() ==
                                        currentUser.uid.toString()
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              color: message.get('from').toString() ==
                                      currentUser.uid.toString()
                                  ? Colors.deepPurple.shade400
                                  : Colors.deepPurple.shade200,
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              alignment: message.get('from').toString() ==
                                      currentUser.uid.toString()
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                formatDateTime(
                                  (message.get('timestamp') as Timestamp)
                                      .toDate(),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.grey[50],
        height: MediaQuery.of(context).size.height * 0.09,
        child: SingleChildScrollView(
          child: MessageBar(
            messageBarColor: Colors.grey.shade50,
            messageBarHintStyle: TextStyle(
                color: Colors.grey.shade800, fontWeight: FontWeight.w300),
            sendButtonColor: Colors.purple.shade800,
            actions: [
              // GestureDetector(
              //   child: Icon(
              //     Icons.add,
              //     color: Colors.deepPurple.shade800,
              //   ),
              // ),
              GestureDetector(
                onTap: pickImage,
                child: Icon(
                  Icons.photo,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ],
            onSend: (message) {
              if (message.isEmpty) {
                return;
              }
              FirebaseFirestore.instance.collection('messages').doc().set({
                'from': currentUser.uid,
                'to': widget.receiverId,
                'message': message,
                'timestamp': DateTime.now(),
                'seen': false,
              }).then((done) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('conversations')
                    .doc(widget.receiverId)
                    .update({'last_message': message, 'count': 0});
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.receiverId)
                    .collection('conversations')
                    .doc(currentUser.uid)
                    .update({
                  'last_message': message,
                  'count': FieldValue.increment(1)
                });
              });
            },
          ),
        ),
      ),
    );
  }
}
