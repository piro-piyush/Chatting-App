import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import '../services/shared_pref.dart';
import 'profile.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String? myName, myUsername, myPhoto, myId, myEmail;
  bool isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getTheSharedPref(); // Call this to fetch the latest data when the widget tree changes
  }

  onTheLoad() async {
    await getTheSharedPref();
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: const Center(
            child: CircularProgressIndicator()), // Show loading indicator
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(
              Icons.search,
              color: Colors.black87,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const Profile(),),);},
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.15,
                decoration: const BoxDecoration(
                  // color: Colors.orangeAccent,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 40, backgroundImage: myPhoto != null ? CachedNetworkImageProvider(myPhoto!) : const AssetImage("assets/images/default.jpeg") as ImageProvider,
                            child: myPhoto !=
                                    null // If myPhoto is not null, show loading indicator
                                ? ClipOval(child: SizedBox(width: 80,
                                      child: CachedNetworkImage(
                                        imageUrl: myPhoto!,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: CircularProgressIndicator(), // Loading indicator
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                        // Error icon
                                        fit: BoxFit.cover, // Fit the image inside the CircleAvatar
                                      ),
                                    ),
                                  )
                                : null, // No child if myPhoto is null
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            // Align text to start
                            children: [
                              Text(
                                myName ?? 'Name not set',
                                // Default text if null
                                style: const TextStyle(fontSize: 22, color: Colors.black),
                              ),
                              Text(
                                myUsername ?? 'Username not set',
                                // Default text if null
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.qr_code, color: Color(0xFF008069), size: 30,),
                          SizedBox(width: 15),
                          Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF008069), size: 30,),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildSettingOptions(titleText: 'Account', subtitleText: "Security notifications, change number", iconData: Icons.key),
            buildSettingOptions(titleText: 'Privacy', subtitleText: "Block contacts, disappearing messages", iconData: Icons.lock_outline),
            buildSettingOptions(titleText: 'Avatar', subtitleText: "Create, edit, profile photo", iconData: Icons.face_unlock_outlined),
            buildSettingOptions(titleText: 'Favourites', subtitleText: "Add reorder, remove", iconData: Icons.favorite_border_sharp),
            buildSettingOptions(titleText: 'Chats', subtitleText: "Theme, wallpapers, chat history", iconData: Icons.chat_outlined),
            buildSettingOptions(titleText: 'Notifications', subtitleText: "Message, group & call tones", iconData: Icons.notifications_none_outlined),
            buildSettingOptions(titleText: 'Storage and data', subtitleText: "Network usage, auto-download", iconData: Icons.data_saver_off_rounded),
            buildSettingOptions(titleText: 'App language', subtitleText: "English (device's language", iconData: Icons.language),
            buildSettingOptions(titleText: 'Help', subtitleText: "Help centre, contact us, privacy policy", iconData: Icons.help_outline_sharp),
            buildOtherOptions(titleText: "Invite a friend", iconData: Icons.people_alt_outlined),
            buildOtherOptions(titleText: "App updates", iconData: Icons.security_update_outlined),
            const SizedBox(height: 30,),
            const Padding(padding: EdgeInsets.only(left: 18.0),
              child: Text("Also from Meta", style: TextStyle(fontSize: 14),),),
            const SizedBox(height: 10,),
            buildSocialTile(titleText: "Open Instagram", iconData: FontAwesomeIcons.instagram),
            buildSocialTile(titleText: "Open Facebook", iconData: FontAwesomeIcons.facebook),
            buildSocialTile(titleText: "Open Threads", iconData: FontAwesomeIcons.threads),
          ],
        ),
      ),
    );
  }

  Widget buildSettingOptions({required String titleText, required String subtitleText, required IconData iconData,}) {
    return ListTile(
      onTap: () {},
      title: Text(titleText, style: const TextStyle(fontSize: 18),),
      subtitle: Text(subtitleText, style: const TextStyle(fontSize: 13),),
      leading: Icon(iconData, size: 24,),
    );
  }

  Widget buildOtherOptions({required String titleText, required IconData iconData}) {
    return ListTile(
      onTap: () {},
      leading: Icon(iconData, size: 24,),
      title: Text(titleText, style: const TextStyle(fontSize: 18),),
    );
  }

  Widget buildSocialTile({required String titleText, required IconData iconData}) {
    return ListTile(
      onTap: () {},
      leading: FaIcon(iconData, size: 24,),
      title: Text(titleText, style: const TextStyle(fontSize: 18),),
    );
  }
}
