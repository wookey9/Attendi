import 'dart:html';
import 'dart:ui' as ui;
import 'package:webviewx/webviewx.dart';
import 'package:flutter/material.dart';

Widget getAdKakaoFit(String type){
  if(type == 'Attendi-web'){
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
  else if(type == 'Attendi-web-userScreen'){
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
  else if(type == 'Attendi-web-userScreen2'){
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 8),
        child: WebViewX(
          height: 75,
          width: 350,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-WuGRpK1hQ8GpqcOG\"\n'
              'data-ad-width = \"320\"\n'
              'data-ad-height = \"50\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),

        )
    );
  }
  else if(type == 'Attendi-web-userScreen3'){
    return Container(
        alignment: Alignment.center,
        child: WebViewX(
          height: 280,
          width: 310,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-qq6qpHxymStW1aXE\"\n'
              'data-ad-width = \"300\"\n'
              'data-ad-height = \"250\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),
        )
    );
  }

  else if(type == 'Attendi-web-userScreen4'){
    return Container(
        alignment: Alignment.center,
        child: WebViewX(
          height: 275,
          width: 275,
          initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
              'data-ad-unit = \"DAN-qOQNjT5cS1NoL7U6\"\n'
              'data-ad-width = \"250\"\n'
              'data-ad-height = \"250\"></ins>\n'
              '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
          initialSourceType: SourceType.html,
          webSpecificParams: WebSpecificParams(

          ),
        )
    );
  }

  else if(type == 'Attendi-web-userScreen-320x100'){
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

