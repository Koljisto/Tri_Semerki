import 'package:flutter/material.dart';
import 'package:awesome_loader/awesome_loader.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new AwesomeLoader(
          loaderType: AwesomeLoader.AwesomeLoader3,
        ),
      ),
    );
  }
}