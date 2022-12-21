import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/7879614191';
const String FULL_UNIT_ID = 'ca-app-pub-4728827454661105/3999114904';

final Map<String, BannerAd> bannerMap = getMapBanner();

Map<String, BannerAd> getMapBanner(){
  Map<String, BannerAd> bannerMap = {};

  if(defaultTargetPlatform != TargetPlatform.iOS){
    return bannerMap;
  }
  bannerMap['big-size-banner'] =  BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.mediumRectangle,
    adUnitId: BANNER_UNIT_ID,
    request: AdRequest(),
  )..load();

  bannerMap['square-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        print('square ad failed to load. error : ' + error.message);
      },
      onAdLoaded: (_) {
        print('square ad loaded');
      },
    ),
    size: AdSize.mediumRectangle,
    adUnitId: BANNER_UNIT_ID,
    request: AdRequest(),
  )..load();

  bannerMap['mid-size-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.fullBanner,
    adUnitId: BANNER_UNIT_ID,
    request: AdRequest(),
  )..load();

  bannerMap['small-size-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.banner,
    adUnitId: BANNER_UNIT_ID,
    request: AdRequest(),
  )..load();

  return bannerMap;
}

Widget getAdBanner(String type){
  BannerAd banner;


  if(defaultTargetPlatform != TargetPlatform.iOS){
    return Container();
  }

  //return Container();
  if(type == 'big-size-banner'){
    if(bannerMap['big-size-banner'] == null) {
      banner = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.mediumRectangle,
        adUnitId: BANNER_UNIT_ID,
        request: AdRequest(),
      )..load();
    }
    else{
      banner = bannerMap['big-size-banner']!;
    }
  }
  else if(type == 'square-banner'){
    if(bannerMap['square-banner'] == null) {
      banner = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('square ad failed to load. error : ' + error.message);
          },
          onAdLoaded: (_) {
            print('square ad loaded');
          },
        ),
        size: AdSize.mediumRectangle,
        adUnitId: BANNER_UNIT_ID,
        request: AdRequest(),
      )..load();
    }
    else{
      banner = bannerMap['square-banner']!;
    }
  }
  else if(type == 'mid-size-banner'){
    if(bannerMap['mid-size-banner'] == null) {
      banner = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.fullBanner,
        adUnitId: BANNER_UNIT_ID,
        request: AdRequest(),
      )..load();
    }
    else{
      banner = bannerMap['mid-size-banner']!;
    }
  }
  else if(type == 'small-size-banner'){
    if(bannerMap['small-size-banner'] == null) {
      banner = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.banner,
        adUnitId: BANNER_UNIT_ID,
        request: AdRequest(),
      )..load();
    }
    else{
      banner = bannerMap['small-size-banner']!;
    }
  }
  else{
    banner = BannerAd(
      listener: BannerAdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {},
        onAdLoaded: (_) {},
      ),
      size: AdSize.banner,
      adUnitId: BANNER_UNIT_ID,
      request: AdRequest(),
    )..load();
  }

  return Container(
    height: banner.size.height.toDouble(),
    width: banner.size.width.toDouble(),
    child: AdWidget(ad: banner,),
  ) ;

 {

} {

}}

