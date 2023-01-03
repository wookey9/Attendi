import 'dart:html';
import 'dart:ui' as ui;
import 'package:webviewx/webviewx.dart';
import 'package:flutter/material.dart';

const String BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/7879614191';
const String FULL_UNIT_ID = 'ca-app-pub-4728827454661105/3999114904';

const String AND_BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/9388727281';
//const String AND_BANNER_UNIT_ID = 'ca-app-pub-3940256099942544/6300978111';
const String AND_FULL_UNIT_ID = 'ca-app-pub-4728827454661105/8075645610';
//const String AND_FULL_UNIT_ID = 'ca-app-pub-3940256099942544/1033173712';

void getMapBanner(){


}
Widget getAdBanner(String type){
  if(type == 'big-size-banner'){
    return Container(
      alignment: Alignment.center,
        child: WebViewX(

          height: 280,
          width: 310,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-SG0jz3hmcaa1RYx6\"\n'
              'data-ad-width = \"300\"\n'
              'data-ad-height = \"250\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),

        )
    );
  }
  else if(type == 'square-banner'){
    var iframeElement = IFrameElement();
    iframeElement.style.border = 'none';
    iframeElement.allow = 'allow-scripts';
    iframeElement.srcdoc = ('<body> <ins class=\"kakao_ad_area" style="display:none;\" \n'
    'data-ad-unit = \"DAN-qOQNjT5cS1NoL7U6\"\n'
    'data-ad-width = \"250\"\n'
    'data-ad-height = \"250\"></ins></div>\n'
    '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script> </body>'  );

    iframeElement.onClick.listen((event) {
      print('clicked');
    });
    iframeElement.onTouchStart.listen((event) {
      print('touch');
    });
    iframeElement.addEventListener('unload', (event) => print('clicked'));
    iframeElement.addEventListener('click', (event) => print('clicked'));
    iframeElement.addEventListener('load', (event) => print('load'));
    iframeElement.children.forEach((element) {element.addEventListener('unload', (event) => print('clicked'));});
    iframeElement.children.forEach((element) {element.addEventListener('click', (event) => print('clicked'));});
    iframeElement.children.forEach((element) {element.addEventListener('load', (event) => print('load'));});
    iframeElement.childNodes.forEach((element) { element.addEventListener('unload', (event) => print('clicked'));});
    iframeElement.childNodes.forEach((element) { element.addEventListener('click', (event) => print('clicked'));});
    iframeElement.childNodes.forEach((element) { element.addEventListener('load', (event) => print('load'));});
    iframeElement.onMouseOver.listen((event) {
      print('over');
    });
    iframeElement.onMouseDown.listen((event) {
      print('down');
    });
    iframeElement.onChange.listen((event) {
      print('change');
    });
 iframeElement.onBlur.listen((event) {
      print('blur');
    });
 iframeElement.onFocus.listen((event) {
      print('focus');
    });
 iframeElement.onLoadedData.listen((event) {
   print('loaddata');
 });
 iframeElement.onLoadedMetadata.listen((event) {
   print('loadmetadata');
 });
 iframeElement.onCanPlayThrough.listen((event) {
   print('canplaythrough');
 });
 iframeElement.onCanPlay.listen((event) {
   print('canplay');
 });
 iframeElement.onPlay.listen((event) {
   print('play');
 });
iframeElement.onWheel.listen((event) {
  print('wheel');
});
iframeElement.onTransitionEnd.listen((event) {
  print('transend');
});
iframeElement.onScroll.listen((event) {
  print('scroll');
});
iframeElement.onSubmit.listen((event) {
  print('submit');
});

    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
          (int viewId) => iframeElement,
    );


    return Container(
      width: 270,
      height: 275,
      child: HtmlElementView(
        key: UniqueKey(),
        viewType: 'iframeElement',
      ),
    ) ;

    return Container(
      child: WebViewX(
        width: 270,
        height: 275,
        initialContent:
            '<div id = "adbanner">'
            '<ins class=\"kakao_ad_area" style="display:none;\" \n'
            'data-ad-unit = \"DAN-qOQNjT5cS1NoL7U6\"\n'
            'data-ad-width = \"250\"\n'
            'data-ad-height = \"250\"></ins></div>\n'
            '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
        initialSourceType: SourceType.html,
        webSpecificParams: WebSpecificParams(

        ),
        javascriptMode: JavascriptMode.unrestricted,
        dartCallBacks: {
          DartCallback(
            name: 'NavigationCallback',
            callBack: (url) => _interceptNavigation(url),
          )
        },
        onPageFinished: (_){
          print('page finished');
          final element = document.getElementById('adbanner');
          if(element != null){
            print('element created');
            element!.onClick.listen((event) {
              print('on click');
            });
          }
          else{
            print('element failed');
          }
        },
        onWebViewCreated: (_){
          print('page created');
          final element = document.getElementById('adbanner');
          if(element != null){
            print('element created');
            element!.onClick.listen((event) {
              print('on click');
            });
          }
          else{
            print('element failed');
          }
        },
        onPageStarted: (_){
          print('page created');
          final element = document.getElementById('adbanner');
          if(element != null){
            print('element created');
            element!.onClick.listen((event) {
              print('on click');
            });
          }
          else{
            print('element failed');
          }
        },

      ),
    );
  }

  else if(type == 'mid-size-banner'){
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 8),
        child: WebViewX(
          height: 125,
          width: 350,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-corMK3Lt8IPXqRcK\"\n'
              'data-ad-width = \"320\"\n'
              'data-ad-height = \"100\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),
        )
    );
  }
  else if(type == 'small-size-banner'){
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 8),
        child: WebViewX(
          height: 75,
          width: 350,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-EY2yyQ6UZFUbpYmj\"\n'
              'data-ad-width = \"320\"\n'
              'data-ad-height = \"50\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),
        )
    );
  }
  return Container(
      alignment: Alignment.center,
      child: WebViewX(

        height: 280,
        width: 310,
        initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
            'data-ad-unit = \"DAN-SG0jz3hmcaa1RYx6\"\n'
            'data-ad-width = \"300\"\n'
            'data-ad-height = \"250\"></ins>\n'
            '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
        initialSourceType: SourceType.html,
        webSpecificParams: WebSpecificParams(

        ),
      )
  );
}
void _interceptNavigation(String url) {
  Uri uri = Uri.parse(url);

  print(url);
}
