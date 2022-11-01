import 'dart:html' as html;

share(Map data) async{
  try{
    await html.window.navigator.share(data);
    print('done');
  }catch(e){
    print(e);
  }
}