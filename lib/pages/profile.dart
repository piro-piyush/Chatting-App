import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../services/shared_pref.dart';
import 'profile_photo_view.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? myName, myUsername, myPhoto, myId, myEmail;
  bool isLoading = true;
  File ? selectedImage;

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  onTheLoad() async {
    await getTheSharedPref();
  }

  Future<void> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Create a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;

      // Define the path where the image will be stored in Firebase Storage
      String storagePath = 'Profile-photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the image to Firebase Storage
      UploadTask uploadTask = storage.ref(storagePath).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      await DatabaseMethods().updateProfilePhotoInFirestore(userId, downloadUrl);

      // Save the new download URL in shared preferences
      await SharedPrefrenceHelper().saveUserPhoto(downloadUrl);

      // Update the myPhoto variable
      setState(() {
        myPhoto = downloadUrl; // Update the local variable
      });

      print('Photo uploaded and URL stored successfully: $downloadUrl');
    } catch (e) {
      print('Error uploading photo: $e');
    }
  }



  getTheSharedPref() async {
    try {
      myName = await SharedPrefrenceHelper().getDisplayName();
      myUsername = await SharedPrefrenceHelper().getUserName();
      myEmail = await SharedPrefrenceHelper().getUserEmail();
      myPhoto = await SharedPrefrenceHelper().getUserPhoto();
      myId = await SharedPrefrenceHelper().getUserId();
    } catch (e) {
      print("Error fetching shared preferences: $e");
    } finally {
      setState(() {
        isLoading = false; // Set loading to false after fetching
      });
    }
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: (){
                    Navigator.pop(context);
                  }, icon: const Icon(Icons.close)),
                  const Text("Profile photo"),
                  IconButton(onPressed: (){
                  }, icon: const Icon(Icons.delete_rounded))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildProfilePhotoIcon(title: "Camera",iconData: Icons.camera_alt_outlined),
                  buildProfilePhotoIcon(title: "Gallery",iconData: Icons.photo),
                  buildProfilePhotoIcon(title: "Avatar",iconData: Icons.face_unlock_outlined),
                ],
              )
            ]
          ),
        );
      },
    );
  }

  Future<void> getImageFromCamera() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null)return;
    setState(() {
      selectedImage = File(returnedImage.path);
    });
      print('Camera Image Path: ${selectedImage!.path}');
  }

  Future<void> getImageFromGallery() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null)return;
    setState(() {
      selectedImage = File(returnedImage.path);
    });
    print('Gallery Image Path: ${selectedImage!.path}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color(0xFF008069),
            title: const Text(
              "Profile",
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.28,
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height*0.25,
                    width: MediaQuery.of(context).size.height*0.25,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext) => ProfilePhotoView(
                                          isMyProfile: true,
                                          name: myName!,
                                          photo: myPhoto!,
                                        )));
                          },
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center, // Center the loading indicator
                                  children: [
                                    ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: myPhoto!,
                                        fit: BoxFit.cover,
                                        // Show a placeholder while the image is loading
                                        placeholder: (context, url) {
                                          // Set loading state to true when loading
                                          isLoading = true;
                                          return Container(color: Colors.grey[200]); // Optional placeholder color
                                        },
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[200], // Optional error color
                                          child: Icon(Icons.error, color: Colors.red), // Error widget
                                        ),
                                        // Set loading state to false once the image loads
                                        imageBuilder: (context, imageProvider) {
                                          isLoading = false; // Image has loaded
                                          return Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Show loading indicator if still loading
                                    if (isLoading)
                                      Center(
                                        child: CircularProgressIndicator(), // Loading indicator
                                      ),
                                  ],
                                ),
                              ),
                            ),

                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: (){
                              showCustomBottomSheet(context);
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: const Color(0xFF008069),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF008069),
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    width: 0.3, color: Colors.grey))),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Name",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        myName!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "This is not your username or pin. This name will be visible to your WhatsApp contacts.",
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF008069),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    width: 0.3, color: Colors.grey))),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 12.0, top: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "About",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        "Hey there! I am using WhatsApp.",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                        child: Icon(
                      Icons.mail,
                      color: Color(0xFF008069),
                    )),
                    const SizedBox(
                      width: 40,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, top: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "E-mail",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      myEmail!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }

  Widget buildProfilePhotoIcon({required String title, required IconData iconData}) {
    return GestureDetector(
      onTap: () async {
        switch (title) {
          case "Camera":
            await getImageFromCamera();
            if (selectedImage != null) {
              // Only upload the photo if one has been selected
              await uploadProfilePhoto(myId!, selectedImage!);
            }
            break;
          case "Gallery":
            await getImageFromGallery();
            if (selectedImage != null) {
              // Only upload the photo if one has been selected
              await uploadProfilePhoto(myId!, selectedImage!);
            }
            break;
          default:
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(30)),
            child: Center(
              child: Icon(
                iconData,
                color: const Color(0xFF008069),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 15),
          )
        ],
      ),
    );
  }
}
