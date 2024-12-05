import 'dart:io';

import 'package:chat_test/auth/firestore_service.dart';
import 'package:chat_test/components/function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pod_player/pod_player.dart';

class CreatePost extends StatefulWidget {
  final File? postFile;
  final postType type;
  const CreatePost({
    super.key,
    required this.postFile,
    required this.type,
  });

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  PodPlayerController? videoController; // Make it nullable
  final captionEditingController = TextEditingController();
  bool isLoading = false;

  isVideo() {
    if (widget.type.name == postType.video.name) {
      videoController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.file(widget.postFile!),
      )..initialise().then((onValue) {
          setState(() {}); // Once the video is initialized, rebuild the UI
        });
    }
  }

  @override
  void dispose() {
    videoController?.dispose(); // Safely dispose if initialized
    super.dispose();
  }

  @override
  void initState() {
    isVideo(); // Initialize video controller if needed
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.grey[50],

      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Create Post'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            child: Column(
              children: [
                // Display the image or video based on the post type
                widget.type.name == postType.image.name
                    ? SizedBox(
                        height: 200,
                        child: Image.file(widget.postFile!),
                      )
                    : (videoController != null &&
                            videoController!.isInitialised)
                        ? SizedBox(
                            height: 350,
                            child: PodVideoPlayer(controller: videoController!),
                          )
                        : const SizedBox(
                            height: 200,
                            child: Icon(Icons.help_center_outlined),
                          ),
                TextFormField(
                  maxLines: 5,
                  maxLength: 150,
                  controller: captionEditingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write a caption.....',
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (widget.postFile == null) {
                            Fluttertoast.showToast(msg: 'No post file');
                            return;
                          }
                          setState(() {
                            isLoading = true; // Corrected
                          });

                          try {
                            final storageRef = FirebaseStorage.instance.ref();
                            final fileName =
                                widget.postFile!.path.split("/").last;
                            final ref =
                                storageRef.child('posts').child(fileName);

                            // Upload the file
                            await ref.putFile(widget.postFile!);

                            // Get the download URL
                            final posturl = await ref.getDownloadURL();

                            // Save the post to Firestore
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc()
                                .set({
                              'caption': captionEditingController.text
                                  .trim(), // Fixed this
                              'posturl': posturl,
                              'userId': FirebaseApi().user!.uid,
                              'type': widget.type.name,
                              'filepath': fileName,
                              'createdat': DateTime.now(),
                            });

                            Fluttertoast.showToast(
                                msg: 'Post created successfully');
                            Navigator.of(context).pop();
                          } catch (error) {
                            // Log the error if any occurs
                            print("Error: $error");
                            Fluttertoast.showToast(
                                msg: 'Error creating post: $error');
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 14),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.blueGrey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Post',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
