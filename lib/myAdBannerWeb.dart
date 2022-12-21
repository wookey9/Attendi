import 'dart:html';
import 'dart:ui' as ui;
import 'package:webviewx/webviewx.dart';
import 'package:flutter/material.dart';

const String BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/7879614191';
const String FULL_UNIT_ID = 'ca-app-pub-4728827454661105/3999114904';

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
    return Container(
      child: WebViewX(
        width: 270,
        height: 275,
        initialContent: '<ins class=\"kakao_ad_area" style="display:none;\" \n'
            'data-ad-unit = \"DAN-qOQNjT5cS1NoL7U6\"\n'
            'data-ad-width = \"250\"\n'
            'data-ad-height = \"250\"></ins>\n'
            '<script type=\"text/javascript\" src=\"//t1.daumcdn.net/kas/static/ba.min.js\" async></script>',
        initialSourceType: SourceType.html,
        webSpecificParams: WebSpecificParams(

        ),
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

