import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePhotoView extends StatefulWidget {
  final bool isMyProfile;
  final String name;
  final String photo;

  const ProfilePhotoView({
    super.key,
    this.isMyProfile = false,
    required this.photo,
    required this.name,
  });

  @override
  State<ProfilePhotoView> createState() => _ProfilePhotoViewState();
}

class _ProfilePhotoViewState extends State<ProfilePhotoView> {
  final ImagePicker _picker = ImagePicker();

  void deleteUserPhoto() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set({
          'Photo': "https://firebasestorage.googleapis.com/v0/b/chit-chat-app-593b5.appspot.com/o/default.jpeg?alt=media&token=89bae691-aeca-4b4f-90a6-d0a84baa6fa5",
        }, SetOptions(merge: true)); // Merge set options to update only 'Photo' field
        print("User photo deleted successfully");
      } catch (e) {
        // Catch and print any errors
        print("Failed to delete user photo: $e");
      }
      setState(() {
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
                      deleteUserPhoto();
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
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      print('Camera Image Path: ${image.path}');
    }
  }

  Future<void> getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Handle the selected image from the gallery
      print('Gallery Image Path: ${image.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.isMyProfile
            ? AppBar(
                title: const Text(
                  "Profile photo",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                actions:  [
                  GestureDetector(onTap: (){
                    showCustomBottomSheet(context);
                  },
                    child: Icon(
                      Icons.edit,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Icon(
                    Icons.share,
                  ),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.black,
              )
            : AppBar(
          title: Text(
            widget.name,
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          actions: const [
            Icon(
              Icons.share,
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(widget.photo), // Caches and displays the image
                backgroundDecoration: const BoxDecoration(
                  color: Colors.white, // Background color
                ),
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? null
                        : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                  ),
                ),
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50),
                ),
              ),
          ),
        ));
  }

  Widget buildProfilePhotoIcon({required String title,required IconData iconData}){
    return GestureDetector(
      onTap: (){
        switch(title){
          case "Camera":
            getImageFromGallery();
            break;
          case "Gallery":
            getImageFromGallery();
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
                border: Border.all(
                    width: 1,
                    color: Colors.grey
                ),
                borderRadius: BorderRadius.circular(30)
            ),
            child:  Center(
              child: Icon(iconData,color: const Color(0xFF008069),),
            ),
          ),
          const SizedBox(height: 10,),
          Text(title,style: const TextStyle(fontSize: 15),)
        ],
      ),
    );
  }

}
