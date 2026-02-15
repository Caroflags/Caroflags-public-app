
import 'package:flutter/material.dart';


class TesterNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        'This app is still in testing!!! \n A lot of things will be replaced, scrapped, executed, sliced, diced and changed. \n we would have a better app testing experience if i didnt have adhd but oh well, \n please dont let this set what you think of the app in the future. Thanks for testing, and i hope the passes part is atleast a bit better than their app. \n - Sincerely, underpaid caroflags developer',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}