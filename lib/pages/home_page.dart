import 'dart:io';

import 'package:chat_test/auth/firestore_service.dart';
import 'package:chat_test/components/function.dart';
import 'package:chat_test/pages/create_post.dart';
import 'package:chat_test/pages/post_list_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseApi().user!;
  final ImagePicker picker = ImagePicker();

  File? postFile;

  pickImageOrVideo(type) async {
    if (postType.image == type) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        postFile = File(image.path);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreatePost(
              postFile: postFile,
              type: type,
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "No image specified");
      }
    } else {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        postFile = File(video.path);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreatePost(
              postFile: postFile,
              type: type,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(user.displayName!),
        titleTextStyle: TextStyle(
          color: Colors.blueGrey.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                isDismissible: true,
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                pickImageOrVideo(postType.image);
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text('Photos')
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                pickImageOrVideo(postType.video);
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.video_library,
                                size: 60,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text('Videos')
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: Icon(
              Icons.add,
              size: 35,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostListView(),
            ],
          ),
        ),
      ),
    );
  }
}
