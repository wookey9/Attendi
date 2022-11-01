import 'package:flutter_share/flutter_share.dart';

share(Map data) async{
  try{
    await FlutterShare.share(title: data["title"], text: data["text"], linkUrl: data["url"]);
    print('done');
  }catch(e){
    print(e);
  }
}