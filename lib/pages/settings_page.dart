import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final formKey = GlobalKey<FormState>();
  final currentUser = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance.collection('users');

  final userNameController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  String? newImageUrl;
  File? postFile;
  bool isLoading = false;

  Future pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return Fluttertoast.showToast(msg: 'No image selected');
    } else {
      setState(() {
        postFile = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userNameController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    setState(() {
      isLoading = true;
    });
    bool hasChanges = false;
    final userDoc = await firestore.doc(currentUser.uid).get();
    final userData = userDoc.data();
    if (postFile != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final fileName = postFile!.path.split("/").last;
        final fileRef = storageRef
            .child('profile_images')
            .child('${currentUser.uid}/$fileName');

        await fileRef.putFile(postFile!);
        newImageUrl = await fileRef.getDownloadURL();
        hasChanges = true;
        Fluttertoast.showToast(msg: 'Image uploaded successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error uploading image');
        print(e);
      }
    }
    if (userNameController.text.trim() != userData?['display_name']) {
      await firestore.doc(currentUser.uid).update({
        'display_name': userNameController.text.trim(),
        'username': userNameController.text.trim()
      });
      hasChanges = true;
    }

    if (newImageUrl != null) {
      await firestore.doc(currentUser.uid).update({'image_url': newImageUrl});
    }
    setState(() {
      isLoading = false;
    });
    Fluttertoast.showToast(
      msg: hasChanges ? 'Changes saved' : 'No changes made',
    );
    if (hasChanges) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Settings'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('User not found');
            }
            final userData = snapshot.data!;
            userNameController.text = userData['display_name'] ?? '';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: postFile != null
                                      ? FileImage(postFile!)
                                      : (userData['image_url'] != null
                                          ? NetworkImage(
                                              userData['image_url'])
                                          : const AssetImage(
                                                  'asset/images/profile-image.jpg')
                                              as ImageProvider),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: (){
                                pickImage();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Center(
                    child: Text(
                      'Edit profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'Username',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(16),
                      hintText: userData['display_name'],
                      hintStyle: const TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                            color: Colors.deepPurple, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(
                    height: 24,
                  ),
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : GestureDetector(
                          onTap: () {
                            saveChanges();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(
                    height: 16,
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.blueGrey.shade50,
                              title: const Text('Delete account'),
                              content: const Text(
                                'Are you sure you want to delete this account?',
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        try {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(currentUser.uid)
                                              .delete();
                                          currentUser.delete();
                                          FirebaseAuth.instance.signOut();
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Account deleted successfully');
                                        } catch (e) {
                                          print(e);
                                          Fluttertoast.showToast(
                                              msg: 'Error deleting account');
                                        }
                                      },
                                      child: Text(
                                        'Yes',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        'No',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          });
                    },
                    child: const Center(
                      child: Text(
                        'Delete account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
