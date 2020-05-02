import 'dart:io';

import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  FirebaseUser _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_currentUser != null
              ? "Ola, ${_currentUser.displayName}"
              : "Chat App"),
          centerTitle: true,
          elevation: 0,
          actions: <Widget>[
            _currentUser != null
                ? IconButton(icon: Icon(Icons.exit_to_app), onPressed: _logout)
                : IconButton(
                    icon: Icon(Icons.supervised_user_circle),
                    onPressed: () {
                      _getUser();
                      _isLoading ? LinearProgressIndicator() : Container();
                    })
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance
                      .collection("messages")
                      .orderBy('time')
                      .snapshots(),
                  builder: _listMessages)),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage)
        ]));
  }

  Future<FirebaseUser> _getUser() async {
    if (_currentUser != null) return _currentUser;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final FirebaseUser user = authResult.user;

      setState(() {
        _isLoading = false;
      });
      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Nao foi possivel fazer login!"),
        backgroundColor: Colors.red,
      ));
    }
    ;

    Map<String, dynamic> data = {
      "uid": user.uid,
      'senderName': user.displayName,
      'senderPhotoUrl': user.photoUrl,
      'time': Timestamp.now()
    };

    if (imgFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);

      setState(() {
        _isLoading = true;
      });

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data["imageUrl"] = url;
    }

    setState(() {
      _isLoading = false;
    });

    if (text != null) data['text'] = text;

    Firestore.instance.collection("messages").add(data);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _logout() {
    FirebaseAuth.instance..signOut();
    googleSignIn.signOut();
    return _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text("Logout feito com Sucesso!"),
    ));
  }

  Widget _listMessages(context, snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
        return Center(child: CircularProgressIndicator());
      default:
        List<DocumentSnapshot> documents =
            snapshot.data.documents.reversed.toList();

        return ListView.builder(
          itemCount: documents.length,
          reverse: true,
          itemBuilder: (context, index) {
            return ChatMessage(documents[index].data,
                documents[index].data['uid'] == _currentUser?.uid);
          },
        );
    }
  }
}
