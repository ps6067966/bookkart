import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutterapp/store/AppStore.dart';
import 'package:flutterapp/utils/AppTheme.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'activity/SplashScreen.dart';
import 'app_localizations.dart';
import 'app_state.dart';

// Default Configuration
double bookViewHeight = mobile_BookViewHeight;
double bookHeight = mobile_bookHeight;
double bookWidth = mobile_bookWidth;
double appLoaderWH = mobile_appLoaderWH;
double backIconSize = mobile_backIconSize;
double bookHeightDetails = mobile_bookWidthDetails;
double bookWidthDetails = mobile_bookHeightDetails;
double fontSizeMedium = mobile_font_size_medium;
double fontSizeXxxlarge = mobile_font_size_xxxlarge;
double fontSizeMicro = mobile_font_size_micro;
double fontSize25 = mobile_font_size_25;
double fontSizeLarge = mobile_font_size_large;
double fontSizeSmall = mobile_font_size_small;
double authorImageSize = mobile_authorImageSize;
double fontSizeNormal = mobile_font_size_normal;

AppStore appStore = AppStore();

void main() async {
  await FlutterDownloader.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initialize();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  appStore.toggleDarkMode(value: await getBool(isDarkModeOnPref));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId(ONESIGNAL_ID);

  await OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: true);

  var pref = await getSharedPref();
  var language;
  try {
    if (pref.getString(LANGUAGE) == null) {
      language = DEFAULT_LANGUAGE_CODE;
    } else {
      language = pref.getString(LANGUAGE);
    }
  } catch (e) {
    language = "en";
  }

  runApp(new MyApp(language));
}

// ignore: must_be_immutable
class MyApp extends StatefulWidget {
  var language;

  MyApp(this.language);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ChangeNotifierProvider(
      create: (_) => AppState(widget.language),
      child: Consumer<AppState>(builder: (context, provider, builder) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          supportedLocales: [Locale('af', ''), Locale('de', ''), Locale('en', ''), Locale('es', ''), Locale('fr', ''), Locale('hi', ''), Locale('in', ''), Locale('tr', ''), Locale('vi', ''), Locale('ar', '')],
          localeResolutionCallback: (locale, supportedLocales) {
            return Locale(Provider.of<AppState>(context).selectedLanguageCode!);
          },
          locale: Provider.of<AppState>(context).locale,
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          theme: !appStore.isDarkModeOn ? AppThemeData.lightTheme : AppThemeData.darkTheme,
          home: SplashScreen(),
          routes: <String, WidgetBuilder>{
            SplashScreen.tag: (BuildContext context) => SplashScreen(),
          },
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: SBehavior(),
              child: child!,
            );
          },
        );
      }),
    );
  }
}

class SBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
