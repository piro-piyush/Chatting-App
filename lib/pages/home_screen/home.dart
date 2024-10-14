import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/pages/sign_in_page.dart';
import 'package:flutter/material.dart';

import 'package:chat_app/services/database.dart';
import 'package:chat_app/pages/settings.dart' as setting;
import 'package:chat_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/internet_connectivity_checker.dart';
import '../chat_screen/chat_screen.dart';
import '../profile_photo_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  bool search = false;
  bool isLoading = false; // Loading state variable
  var queryResultSet = [];
  var tempSearchStore = [];

  String? myName, myPhoto, myUserName, myEmail, myId;
  Stream? chatRoomsStream;

  getTheSharedPref() async {
    myName = await SharedPrefrenceHelper().getDisplayName();
    myUserName = await SharedPrefrenceHelper().getUserName();
    myEmail = await SharedPrefrenceHelper().getUserEmail();
    myPhoto = await SharedPrefrenceHelper().getUserPhoto();
    myId = await SharedPrefrenceHelper().getUserId();
    setState(() {});
  }

  onTheLoad() async {
    await getTheSharedPref();
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onInit();
  }

  Future<void> onInit() async {
    bool hasInternet = await isInternet();
    updateUserStatus(hasInternet);
    onTheLoad();
  }

  @override
  void dispose() {
    updateUserStatus(false); // Set user status to offline when app is closed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      // Set user status to offline when the app goes into background
      updateUserStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      // Check for internet when the app resumes
      bool hasInternet = await isInternet();
      // Update user status based on internet connection
      updateUserStatus(hasInternet);
    }
  }

  void updateUserStatus(bool online) async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      try {
        // Attempt to update user status
        if (online) {
          // User is online, update Last-Seen timestamp
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'isOnline': true,
            'Last-Seen': FieldValue.serverTimestamp(),
            // Store current timestamp
          }, SetOptions(merge: true));
          print(
              "User status updated successfully: isOnline = true, Last-Seen updated");
        } else {
          // User is offline, just update isOnline without changing Last-Seen
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'isOnline': false,
            // Do not update Last-Seen
          }, SetOptions(merge: true));
          print(
              "User status updated successfully: isOnline = false, Last-Seen not updated");
        }
      } catch (e) {
        // Catch and print any errors
        print("Failed to update user status: $e");
      }
    }
  }

  initiateSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        isLoading = false; // Set loading state to false
      });
      return;
    }

    setState(() {
      search = true;
      isLoading = true; // Set loading state to true
    });

    var lowerCasedValue = value.toLowerCase(); // Use lower case for comparison

    // Fetch users if query result set is empty
    if (queryResultSet.isEmpty && value.isNotEmpty) {
      try {
        QuerySnapshot docs = await DatabaseMethods().search(value);
        List userList = docs.docs.map((doc) => doc.data()).toList();
        setState(() {
          queryResultSet =
              userList; // Update the queryResultSet with fetched data
          tempSearchStore =
              userList; // Initialize tempSearchStore with userList
        });
      } catch (e) {
        print("Error fetching users: $e");
      }
    } else {
      // Filter existing results based on input
      tempSearchStore = queryResultSet.where((element) {
        return element["Username"].toLowerCase().contains(lowerCasedValue) ||
            element["Name"].toLowerCase().contains(lowerCasedValue);
      }).toList();
    }

    setState(() {
      isLoading = false; // Set loading state to false after processing
    });
  }
  Future logOutDialogue(BuildContext context){
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Do you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                SharedPrefrenceHelper().clearUserData();
                FirebaseAuth.instance.signOut();
                print('User logged out');
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                      (Route<dynamic> route) => false, // This clears the entire stack
                );// Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: search
          ? AppBar(
              backgroundColor: const Color(0xFF008069),
              leading: GestureDetector(
                onTap: () {
                  setState(() {
                    search = false; // Exit search mode
                  });
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              title: TextField(
                onChanged: (value) {
                  initiateSearch(
                      value.toUpperCase()); // Call search logic on text change
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      search = false; // Exit search mode
                    });
                  },
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      // Define the send action if necessary
                    },
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: const Color(0xFF008069),
              title: const Text(
                "Chit Chat",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      search = true; // Enable search mode
                    });
                  },
                ),
                const SizedBox(width: 5),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle actions based on the selected value
                    switch (value) {
                      case 'New group':
                        // Navigate or perform an action for New group
                        break;
                      case 'New broadcast':
                        // Action for New broadcast
                        break;
                      case 'Linked devices':
                        // Action for Linked devices
                        break;
                      case 'Starred messages':
                        // Action for Starred messages
                        break;
                      case 'Payments':
                        // Action for Payments
                        break;
                      case 'Settings':
                        // Navigate to Settings page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const setting.Settings(),
                          ),
                        );
                        break;
                      case 'Logout':
                        logOutDialogue(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'New group',
                        child: Text('New group',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'New broadcast',
                        child: Text('New broadcast',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Linked devices',
                        child: Text('Linked devices',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Starred messages',
                        child: Text('Starred messages',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Payments',
                        child: Text('Payments',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Settings',
                        child: Text('Settings',
                            style: TextStyle(color: Colors.black)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Logout',
                        child: Text('Logout',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ];
                  },
                  color: Colors.white, // White background for the menu
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white), // Same icon color as AppBar
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: search
                ? searchWidget()
                : chatRoomList(), // Display searchWidget or ChatRoomList
          ),
        ],
      ),
    );
  }

  Widget searchWidget() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(), // Loading indicator
          )
        : tempSearchStore.isEmpty
            ? const Center(
                child: Text(
                  "No users found.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                primary: false,
                shrinkWrap: true,
                children: tempSearchStore.map((element) {
                  return buildResultCard(element); // Display search results
                }).toList(),
              );
  }

  Widget chatRoomList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data.docs.isNotEmpty) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data.docs.length, // Correct itemCount
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // Access the document snapshot at the given index
              DocumentSnapshot ds = snapshot.data.docs[index];
              return ChatRoomListTile(
                  lastMessage: ds["Last-message"] ?? "",
                  // Use actual field name
                  chatRoomId: ds.id,
                  // Use document ID as chatRoomId
                  myUsername: myUserName!,
                  // Ensure myUserName is set
                  time: ds["Last-message-send-time"] ?? "",
                  myId: myId!);
            },
          );
        } else {
          return const Center(
            child: Text(
              "No chats yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
      },
    );
  }

  Widget buildChatRow({
    required String name,
    required String img,
    required String lastMessage,
    required String lastMessageTime,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  img,
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lastMessage,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            lastMessageTime,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the result card for each search result
  Widget buildResultCard(data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        elevation: 2.0,
        borderRadius: BorderRadius.circular(10.0),
        child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                data["Photo"] ?? "assets/images/default.png",
              ),
              radius: 30,
            ),
            title: Text(myUserName == data["Username"]
                ? "${data["Username"].toString()} (You)"
                : data["Username"].toString()),
            subtitle: Text(data["Name"] ?? "No Name"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              // Update the search state
              search = false;
              setState(() {});
              // Generate the chat room ID using usernames
              var chatRoomId =
                  DatabaseMethods().getChatRoomIdByUIDs(myId!, data["Id"]);
              Map<String, dynamic> chatRoomInfoMap = {
                "Users": [myUserName, data["Username"]],
              };
              await DatabaseMethods()
                  .createChatRoom(chatRoomId, chatRoomInfoMap);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    name: data["Name"],
                    profileUrl: data["Photo"],
                    username: data["Username"],
                    userId: data["Id"],
                  ),
                ),
              );
            }),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername, myId, time;

  const ChatRoomListTile(
      {required this.lastMessage,
      required this.chatRoomId,
      required this.myUsername,
      required this.time,
      required this.myId,
      super.key});

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  getThisUserInfo() async {
    id = widget.chatRoomId.replaceAll("_", "").replaceAll(widget.myId, "");
    QuerySnapshot querySnapshot = await DatabaseMethods().getUserByIds(id);
    name = "${querySnapshot.docs[0]["Name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["Photo"]}";
    username = "${querySnapshot.docs[0]["Username"]}";
    id = "${querySnapshot.docs[0]["Id"]}";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              name: name,
              profileUrl: profilePicUrl,
              username: username,
              userId: id,
            ),
          ),
        );
      },
      leading: profilePicUrl == "" ? const CircularProgressIndicator() : GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ProfilePhotoView(
                name: name,
                photo: profilePicUrl,
              ),
            ),
          );
        },
        child: Expanded(
          // height: 50,
          // width: 50,
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center, // Center the loading indicator
              children: [
                CachedNetworkImage(
                  imageUrl: profilePicUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 50,
                    width: 50,
                    color: Colors.grey[200], // Optional placeholder color
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 50,
                    width: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red), // Error widget
                  ),
                ),
                // Optionally show a loading indicator if needed
              ],
            ),
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
      subtitle: Text(
        widget.lastMessage,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: Column(
        children: [
          Text(
            widget.time,
            style: const TextStyle(color: Color(0xFF008069)),
          ),
        ],
      ),
    );
  }
}
