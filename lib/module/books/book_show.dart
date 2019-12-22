import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

// ignore: must_be_immutable
class BookShow extends StatefulWidget {
  String bookName;
  int total;

  BookShow({Key key,@required this.bookName,@required this.total});

  @override
  _BookShowState createState() => _BookShowState();
}

class _BookShowState extends State<BookShow> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  int page;
  String url;
  @override
  void initState() {
    super.initState();
    page = 0;
    url = getUrl();
  }

  String getUrl(){
    return 'file:///android_asset/books/${widget.bookName}/$page.html';
  }


  void reloadPage(){
     flutterWebviewPlugin.reloadUrl(getUrl());
  }

  void nextPage() {
    if(page < widget.total) {
      setState(() {
        page++;
      });
      reloadPage();
    }
  }

  void prevPage() {
    if(page > 1) {
      setState(() {
        page--;
      });
      reloadPage();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: <Widget>[
          Expanded(
            child: WebviewScaffold(
              url: url,
              allowFileURLs: true,
            ),
          ),
          Container(
            color: Colors.blueGrey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  child: Icon(Icons.arrow_back,color: Colors.white,), onPressed: () {
                  nextPage();
                },
                ),
                FlatButton(
                  child: Icon(Icons.arrow_forward,color: Colors.white,), onPressed: () {
                  prevPage();
                },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}