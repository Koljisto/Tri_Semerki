import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

final _passwordFormKey = new GlobalKey<FormState>();

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  String _mail;
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Container(
          padding: new EdgeInsets.only(left: 60.0, right: 60.0),
          child: new SingleChildScrollView(
            child: new Form(
              key: _passwordFormKey,
              child: new Column(
                children: <Widget>[
                  new Text(
                    "Enter your E-mail",
                    style: new TextStyle(
                      fontFamily: 'Times new roman',
                    ),
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "E-mail"),
                    validator: validateEmail,
                    autovalidate: true,
                    onSaved: (String value) => _mail = value,
                  ),
                  new Padding(
                    padding: new EdgeInsets.only(top: 20.0),
                  ),
                  new RaisedButton(
                    child: new Text(
                      "Send",
                      style: new TextStyle(
                        fontFamily: 'Times new roman',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String validateEmail(String value) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(value))
    return "Enter Valid Email";
  else
    return null;
}