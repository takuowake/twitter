import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterlabo_twitter/model/account.dart';
import 'package:flutterlabo_twitter/utils/authentication.dart';
import 'package:flutterlabo_twitter/utils/firestore/users.dart';
import 'package:flutterlabo_twitter/utils/function_utils.dart';
import 'package:flutterlabo_twitter/utils/wiget_utils.dart';
import 'package:flutterlabo_twitter/view/screen.dart';
import 'package:flutterlabo_twitter/view/start_up/check_email_page.dart';

class CreateAccountPage extends StatefulWidget {
  final bool isSignInWithGoogle;
  CreateAccountPage({this.isSignInWithGoogle = false});
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController userIdController = TextEditingController();
  TextEditingController selfIntroductionController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  File? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('新規登録'),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 30,),
              GestureDetector(
                onTap: () async{
                  var result = await FunctionUtils.getImageFromGallery();
                  if(result != null) {
                    setState(() {
                      image = File(result.path);
                    });
                  }
                },
                child: CircleAvatar(
                  foregroundImage: image == null ? null : FileImage(image!),
                  radius: 40,
                  child: Icon(Icons.add),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: '名前'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
                  width: 300,
                  child: TextField(
                    controller: userIdController,
                    decoration: InputDecoration(hintText: 'ユーザーID'),
                  ),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  controller: selfIntroductionController,
                  decoration: InputDecoration(hintText: '自己紹介'),
                ),
              ),
              widget.isSignInWithGoogle ? Container() : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      width: 300,
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(hintText: 'メールアドレス'),
                      ),
                    ),
                  ),
                  Container(
                    width: 300,
                    child: TextField(
                      controller: passController,
                      decoration: InputDecoration(hintText: 'パスワード'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              ElevatedButton(
                  onPressed: () async{
                    if(nameController.text.isNotEmpty
                        && userIdController.text.isNotEmpty
                        && selfIntroductionController.text.isNotEmpty
                        && image!= null) {
                      if(widget.isSignInWithGoogle) {
                        var _result = await createAccount(Authentication.currentFirebaseUser!.uid);
                        if(_result == true) {
                          await UserFirestore.getUser(Authentication.currentFirebaseUser!.uid);
                          Navigator.pop(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Screen()));
                        }
                      }
                      var result = await Authentication.signUp(email: emailController.text, pass: passController.text);
                      if(result is UserCredential) {
                        var _result = await createAccount(result.user!.uid);
                        if(_result == true) {
                          result.user!.sendEmailVerification();
                          // ignore: use_build_context_synchronously
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CheckEmailPage(
                                  email: emailController.text,
                                  pass: passController.text
                            )
                          ));
                        }
                      }
                    }
                  },
                  child: Text('アカウントを作成')
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> createAccount(String uid) async {
    String imagePath = await FunctionUtils.uploadImage(uid, image!);
    Account newAccount = Account(
      id: uid,
      name: nameController.text,
      userId: userIdController.text,
      selfIntroduction: selfIntroductionController.text,
      imagePath: imagePath,
    );
    var _result = await UserFirestore.setUser(newAccount);
    return _result;
  }
}
