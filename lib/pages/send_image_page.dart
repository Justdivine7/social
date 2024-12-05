import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SendImagePage extends StatefulWidget {
  final File? postFile;
  final String receiverId;
  const SendImagePage({
    super.key,
    this.postFile,
    required this.receiverId,
  });

  @override
  State<SendImagePage> createState() => _SendImagePageState();
}

class _SendImagePageState extends State<SendImagePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  TextEditingController captionController = TextEditingController();
  bool isLoading = false;

  Future<void> sendImageWithCaption() async {
    try {
      setState(() {
        isLoading = true;
      });
      final imageStorage = FirebaseStorage.instance.ref();
      final imageName = widget.postFile!.path.split("/").last;
      final storageRef = imageStorage.child('messages_media').child(imageName);

      await storageRef.putFile(widget.postFile!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('messages').doc().set({
        'caption': captionController.text.trim(),
        'from': currentUser.uid,
        'to': widget.receiverId,
        'imageurl': imageUrl,
        'timestamp': DateTime.now(),
        'seen': false,
      }).then((done) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('conversations')
            .doc(widget.receiverId)
            .update({'last_message': '📷 image', 'count': 0});
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverId)
            .collection('conversations')
            .doc(currentUser.uid)
            .update(
                {'last_message': '📷 image', 'count': FieldValue.increment(1)});
      });
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Image sent');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      Fluttertoast.showToast(msg: 'Error creating post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(widget.postFile!),
              ),
            ),
          ),
          // Spacer(),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: captionController,
          decoration: InputDecoration(
            suffixIcon: isLoading
                ? const SizedBox(
                    width: 20.0, // Set the desired width
                    height: 20.0, // Set the desired height
                    child: CircularProgressIndicator(
                      strokeWidth: 4.0, 
                      
                       
                    ),
                  )
                : GestureDetector(
                    onTap: sendImageWithCaption,
                    child: Icon(
                      Icons.send,
                      color: Colors.purple.shade800,
                    ),
                  ),
            contentPadding: const EdgeInsets.all(12),
            hintText: 'Add a caption....',
            // fillColor: Colors.black54, // For slight background behind text
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
