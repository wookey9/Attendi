import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/7879614191';
const String FULL_UNIT_ID = 'ca-app-pub-4728827454661105/3999114904';

const String AND_BANNER_UNIT_ID = 'ca-app-pub-4728827454661105/9388727281';
//const String AND_BANNER_UNIT_ID = 'ca-app-pub-3940256099942544/6300978111';
const String AND_FULL_UNIT_ID = 'ca-app-pub-4728827454661105/8075645610';
//const String AND_FULL_UNIT_ID = 'ca-app-pub-3940256099942544/1033173712';

Map<String, BannerAd> bannerMap = {};

Future<void> getMapBanner() async{
  var bannerid = (defaultTargetPlatform == TargetPlatform.iOS) ? BANNER_UNIT_ID : AND_BANNER_UNIT_ID;

  bannerMap['big-size-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.mediumRectangle,
    adUnitId: bannerid,
    request: AdRequest(),
  );
  await bannerMap['big-size-banner']!.load();

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
    adUnitId: bannerid,
    request: AdRequest(),
  );
  await bannerMap['square-banner']!.load();

  bannerMap['mid-size-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.fullBanner,
    adUnitId: bannerid,
    request: AdRequest(),
  );
  await bannerMap['mid-size-banner']!.load();

  bannerMap['small-size-banner'] = BannerAd(
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad ad, LoadAdError error) {},
      onAdLoaded: (_) {},
    ),
    size: AdSize.banner,
    adUnitId: bannerid,
    request: AdRequest(),
  );
  await bannerMap['small-size-banner']!.load();
}

Widget getAdBanner(String type){
  BannerAd banner;

  var bannerid = (defaultTargetPlatform == TargetPlatform.iOS) ? BANNER_UNIT_ID : AND_BANNER_UNIT_ID;

  //return Container();
  if(type == 'big-size-banner'){
    if(bannerMap['big-size-banner'] == null) {
      bannerMap['big-size-banner'] = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.mediumRectangle,
        adUnitId: bannerid,
        request: AdRequest(),
      )..load();
    }
    banner = bannerMap['big-size-banner']!;
  }
  else if(type == 'square-banner'){
    if(bannerMap['square-banner'] == null) {
      bannerMap['square-banner']  = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('square ad failed to load. error : ' + error.message);
          },
          onAdLoaded: (_) {
            print('square ad loaded');
          },
        ),
        size: AdSize.mediumRectangle,
        adUnitId: bannerid,
        request: AdRequest(),
      )..load();
    }
    banner = bannerMap['square-banner']!;
  }
  else if(type == 'mid-size-banner'){
    if(bannerMap['mid-size-banner'] == null) {
      bannerMap['mid-size-banner'] = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.fullBanner,
        adUnitId: bannerid,
        request: AdRequest(),
      )..load();
    }
    banner = bannerMap['mid-size-banner']!;
  }
  else if(type == 'small-size-banner'){
    if(bannerMap['small-size-banner'] == null) {
      bannerMap['small-size-banner'] = BannerAd(
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {},
          onAdLoaded: (_) {},
        ),
        size: AdSize.banner,
        adUnitId: bannerid,
        request: AdRequest(),
      )..load();
    }
    banner = bannerMap['small-size-banner']!;
  }
  else{
    banner = BannerAd(
      listener: BannerAdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {},
        onAdLoaded: (_) {},
      ),
      size: AdSize.banner,
      adUnitId: bannerid,
      request: AdRequest(),
    )..load();
  }
  //bannerMap = getMapBanner();

  return Container(
    height: banner.size.height.toDouble(),
    width: banner.size.width.toDouble(),
    child: AdWidget(ad: banner,),
  ) ;

 {

} {

}}

