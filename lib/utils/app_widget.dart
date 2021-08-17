import 'dart:convert';
import 'dart:io';

import 'package:epub_viewer/epub_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutterapp/activity/PDFScreen.dart';
import 'package:flutterapp/main.dart';
import 'package:flutterapp/model/downloaded_book.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:intl/intl.dart' as init;
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_localizations.dart';

BoxDecoration boxDecoration({double radius = 2, Color color = Colors.transparent, Color? bgColor = Colors.white, var showShadow = false}) {
  return BoxDecoration(
      //gradient: LinearGradient(colors: [bgColor, whiteColor]),
      color: bgColor,
      boxShadow: showShadow ? [BoxShadow(color: appStore.isDarkModeOn ? appStore.scaffoldBackground! : shadow_color, blurRadius: 10, spreadRadius: 2)] : [BoxShadow(color: Colors.transparent)],
      border: Border.all(color: color),
      borderRadius: BorderRadius.all(Radius.circular(radius)));
}

// ignore: must_be_immutable
class EditText extends StatefulWidget {
  var isPassword;
  var hintText;
  var isSecure;
  int fontSize;
  var textColor;
  var fontFamily;
  var text;
  var visible;
  var validator;
  var maxLine;
  TextEditingController? mController;
  VoidCallback? onPressed;
  Function? onFieldSubmitted;
  TextInputType? mKeyboardType;

  EditText({
    var this.fontSize = textSizeNormal,
    var this.textColor = textPrimaryColor,
    var this.hintText = '',
    var this.isPassword = true,
    var this.isSecure = false,
    var this.text = "",
    var this.mController,
    this.validator,
    this.onFieldSubmitted,
    this.mKeyboardType,
    var this.maxLine = 1,
    var this.visible = false,
  });

  @override
  State<StatefulWidget> createState() {
    return EditTextState();
  }
}

class EditTextState extends State<EditText> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isSecure) {
      return TextFormField(
        controller: widget.mController,
        obscureText: widget.isPassword,
        cursorColor: primaryColor,
        maxLines: widget.maxLine,
        readOnly: widget.visible,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted as void Function(String)?,
        keyboardType: widget.mKeyboardType,
        style: TextStyle(fontSize: widget.fontSize.toDouble(), color: appStore.appTextPrimaryColor, fontFamily: widget.fontFamily),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(26, 16, 4, 16),
          hintText: widget.hintText,
          hintStyle: TextStyle(color: appStore.textSecondaryColor),
          fillColor: appStore.editTextBackColor,
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
          ),
          errorMaxLines: 2,
          errorStyle: primaryTextStyle(color: Colors.red, size: 12),
        ),
      );
    } else {
      return TextFormField(
        controller: widget.mController,
        obscureText: widget.isPassword,
        cursorColor: primaryColor,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted as void Function(String)?,
        style: TextStyle(fontSize: widget.fontSize.toDouble(), color: appStore.appTextPrimaryColor, fontFamily: widget.fontFamily),
        decoration: InputDecoration(
          suffixIcon: new GestureDetector(
            onTap: () {
              setState(() {
                widget.isPassword = !widget.isPassword;
              });
            },
            child: new Icon(
              widget.isPassword ? Icons.visibility : Icons.visibility_off,
              color: appStore.iconColor,
            ),
          ),
          contentPadding: EdgeInsets.fromLTRB(26, 18, 4, 18),
          hintText: widget.hintText,
          hintStyle: TextStyle(color: appStore.textSecondaryColor),
          filled: true,
          fillColor: appStore.editTextBackColor,
          errorMaxLines: 2,
          errorStyle: primaryTextStyle(color: Colors.red, size: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
          ),
        ),
      );
    }
  }
}

enum ConfirmAction { CANCEL, ACCEPT }

// Book Loader View
Widget bookLoaderWidget = Container(
  width: 100,
  height: 100,
  child: Lottie.asset(BOOK_LOADER),
);

Widget viewMoreDataLoader = Container(
  width: 200,
  height: 20,
  child: Lottie.asset(MORE_DATA_LOADER),
);

Widget appDownloadWidget = Container(
  width: appLoaderWH,
  height: appLoaderWH,
  child: Lottie.asset(FILE_DOWNLOAD_LOADER),
);

Widget appLoaderWidget = Container(
  width: appLoaderWH,
  height: appLoaderWH,
  child: Lottie.asset(APP_LOADER),
);

Widget backIcons(context, {isPopOperation = false}) {
  return GestureDetector(
    child: Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appStore.editTextBackColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
        boxShadow: [
          BoxShadow(
            color: appStore.isDarkModeOn ? appStore.scaffoldBackground! : shadow_color,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Image.asset(
        "back.png",
        width: backIconSize,
        height: backIconSize,
        color: appStore.iconColor,
      ),
    ),
    onTap: () {
      if (isPopOperation) {
        SystemNavigator.pop();
      } else {
        Navigator.of(context).pop();
      }
    },
  );
}

bool getDeviceTypePhone() {
  final data = MediaQueryData.fromWindow(WidgetsBinding.instance!.window);
  return data.size.shortestSide < 600 ? true : false;
}

double getChildAspectRatio() {
  if (getDeviceTypePhone()) {
    return 180 / 250;
  } else {
    return 150 / 250;
  }
}

int getCrossAxisCount() {
  if (getDeviceTypePhone()) {
    return 2;
  } else {
    return 4;
  }
}

// ignore: must_be_immutable
class AppBtn extends StatefulWidget {
  var value;
  VoidCallback onPressed;

  AppBtn({required this.value, required this.onPressed});

  @override
  State<StatefulWidget> createState() {
    return AppBtnState();
  }
}

class AppBtnState extends State<AppBtn> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: widget.onPressed,
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing_standard_new.toDouble(), 16, spacing_standard_new.toDouble(), 16),
        child: Center(
            child: Text(
          widget.value,
          style: boldTextStyle(
            color: Colors.white,
          ),
        )),
      ),
    );
  }
}

Widget getLoadingProgress(loadingProgress) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes : null,
      ),
    ),
  );
}

Widget appBar(BuildContext context, {List<Widget>? actions, bool showBack = true, bool showTitle = true, bool isPopOperation = false, String? title}) {
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: appStore.appBarColor,
    elevation: 0,
    leading: showBack ? backIcons(context, isPopOperation: isPopOperation) : null,
    title: showTitle
        ? Html(
            data: title,
            style: {
              'body': Style(fontWeight: FontWeight.bold, fontSize: FontSize(fontSizeLarge),color: textPrimaryColorGlobal),
            },
          )
        : null,
    actions: actions,
  );
}

// ignore: must_be_immutable
class CustomTheme extends StatelessWidget {
  Widget? child;

  CustomTheme({this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appStore.isDarkModeOn
          ? ThemeData.dark().copyWith(
              accentColor: primaryColor,
              backgroundColor: appStore.scaffoldBackground,
            )
          : ThemeData.light(),
      child: child!,
    );
  }
}

String reviewConvertDate(date) {
  try {
    return date != null ? init.DateFormat(reviewDateFormat).format(DateTime.parse(date)) : '';
  } catch (e) {
    printLogs(e.toString());
    return '';
  }
}

Widget errorView(height, width, BuildContext context) {
  return Stack(
    children: [
      Image.asset(
        'assets/error.png',
        height: height,
        width: width,
        fit: BoxFit.cover,
      ),
      Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(keyString(context, 'lbl_no_internet')!,
                style: boldTextStyle(
                  size: 24,
                )),
            4.height,
            Text(
              keyString(context, 'lbl_network_msg')!,
              style: secondaryTextStyle(
                size: 14,
              ),
              textAlign: TextAlign.center,
            ).paddingOnly(left: 20, right: 20),
            AppBtn(
              value: "Close",
              onPressed: () {
                Navigator.of(context).pop();
              },
            ).paddingAll(16)
          ],
        ).paddingOnly(top: 30),
      )
    ],
  );
}

Widget noInternet(height, width, BuildContext context) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Image.asset(
        'noInternet.png',
        height: 250,
        width: 250,
        fit: BoxFit.cover,
      ),
      Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(keyString(context, 'lbl_no_internet')!, style: boldTextStyle(size: 24)),
            4.height,
            Text(
              keyString(context, 'lbl_network_msg')!,
              style: secondaryTextStyle(size: 14),
              textAlign: TextAlign.center,
            ).paddingOnly(left: 20, right: 20),
            AppBtn(
              value: "Close",
              onPressed: () {
                Navigator.of(context).pop();
              },
            ).paddingAll(16)
          ],
        ).paddingOnly(top: 30),
      )
    ],
  );
}

// ignore: must_be_immutable
class Button extends StatefulWidget {
  static String tag = '/T4Button';
  var textContent;
  VoidCallback onPressed;
  var isStroked = false;
  var height = 50.0;

  Button({
    required this.textContent,
    required this.onPressed,
    this.isStroked = false,
  });

  @override
  ButtonState createState() => ButtonState();
}

class ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: EdgeInsets.fromLTRB(spacing_standard_new.toDouble(), 10, spacing_standard_new.toDouble(), 10),
        alignment: Alignment.center,
        child: Center(
          child: Text(
            widget.textContent,
            textAlign: TextAlign.center,
            style: primaryTextStyle(
              color: widget.isStroked ? primaryColor : Colors.white,
            ),
          ),
        ),
        decoration: widget.isStroked ? boxDecoration(bgColor: Colors.transparent, color: primaryColor, radius: 10) : boxDecoration(bgColor: primaryColor, radius: 10),
      ),
    );
  }
}

void redirectUrl(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    toast('Please check URL');
    throw 'Could not launch $url';
  }
}

Future<String?> requestDownload({BuildContext? context, required DownloadedBook downloadTask}) async {
  String path = await localPath;
  var url = downloadTask.mDownloadTask.url.replaceAll(' ', '%20');
  var fileName = await getBookFileName(downloadTask.bookId, url);
  final savedDir = Directory(path);
  bool hasExisted = await savedDir.exists();
  if (!hasExisted) {
    savedDir.create();
  }
  return await FlutterDownloader.enqueue(
    url: url,
    fileName: fileName,
    savedDir: path,
    showNotification: true,
    openFileFromNotification: false,
  );
}

readFile(context, String? mBookId, String filePath, String? name, {isCloseApp = true}) async {
  printLogs(filePath);
  if (filePath.contains(".pdf")) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PDFScreen(mBookId, filePath, name)));
  } else if (filePath.contains(".epub")) {
    EpubViewer.setConfig(themeColor: Theme.of(context).primaryColor, identifier: "iosBook", scrollDirection: EpubScrollDirection.VERTICAL, allowSharing: true, enableTts: true, nightMode: false);

    var epubLocator = EpubLocator();
    String locatorPref = await getString('locator');

    try {
      if (locatorPref.isNotEmpty) {
        Map<String, dynamic> r = jsonDecode(locatorPref);

        epubLocator = EpubLocator.fromJson(r);
      }
    } on Exception {
      epubLocator = EpubLocator();
      await removeKey('locator');
    }
    EpubViewer.open(Platform.isAndroid ? filePath : filePath, lastLocation: epubLocator);

    EpubViewer.locatorStream.listen((locator) {
      setString('locator', locator);
    });
    if (isCloseApp) Navigator.of(context).pop();
  }
}

class PinEntryTextField extends StatefulWidget {
  final String? lastPin;
  final int fields;
  final onSubmit;
  final fieldWidth;
  final fontSize;
  final isTextObscure;
  final showFieldAsBox;

  PinEntryTextField({this.lastPin, this.fields: 6, this.onSubmit, this.fieldWidth: 30.0, this.fontSize: 16.0, this.isTextObscure: false, this.showFieldAsBox: false}) : assert(fields > 0);

  @override
  State createState() {
    return PinEntryTextFieldState();
  }
}

class PinEntryTextFieldState extends State<PinEntryTextField> {
  late List<String?> _pin;
  late List<FocusNode?> _focusNodes;
  late List<TextEditingController?> _textControllers;

  Widget textfields = Container();

  @override
  void initState() {
    super.initState();
    _pin = List<String?>.filled(widget.fields, null, growable: false);
    _focusNodes = List<FocusNode?>.filled(widget.fields, null, growable: false);
    _textControllers = List<TextEditingController?>.filled(widget.fields, null, growable: false);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        if (widget.lastPin != null) {
          for (var i = 0; i < widget.lastPin!.length; i++) {
            _pin[i] = widget.lastPin![i];
          }
        }
        textfields = Directionality(textDirection: TextDirection.ltr, child: generateTextFields(context));
      });
    });
  }

  @override
  void dispose() {
    _textControllers.forEach((TextEditingController? t) => t!.dispose());
    super.dispose();
  }

  Widget generateTextFields(BuildContext context) {
    List<Widget> textFields = List.generate(widget.fields, (int i) {
      return buildTextField(i, context);
    });

    if (_pin.first != null) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, verticalDirection: VerticalDirection.down, children: textFields);
  }

  void clearTextFields() {
    _textControllers.forEach((TextEditingController? tEditController) => tEditController!.clear());
    _pin.clear();
  }

  Widget buildTextField(int i, BuildContext context) {
    if (_focusNodes[i] == null) {
      _focusNodes[i] = FocusNode();
    }
    if (_textControllers[i] == null) {
      _textControllers[i] = TextEditingController();
      if (widget.lastPin != null) {
        _textControllers[i]!.text = widget.lastPin![i];
      }
    }

    _focusNodes[i]!.addListener(() {
      if (_focusNodes[i]!.hasFocus) {}
    });

    final String lastDigit = _textControllers[i]!.text;
    log("Language" + lastDigit);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: widget.fieldWidth,
        margin: EdgeInsets.only(right: 10.0),
        child: TextField(
          controller: _textControllers[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          textDirection: TextDirection.ltr,
          autofocus: true,
          style: primaryTextStyle(color: Theme.of(context).textTheme.subtitle2!.color),
          focusNode: _focusNodes[i],
          obscureText: widget.isTextObscure,
          decoration: InputDecoration(focusColor: Theme.of(context).primaryColor, counterText: "", border: widget.showFieldAsBox ? OutlineInputBorder(borderSide: BorderSide(width: 2.0)) : null),
          onChanged: (String str) {
            setState(() {
              _pin[i] = str;
            });
            if (i + 1 != widget.fields) {
              _focusNodes[i]!.unfocus();
              if (_pin[i] == '') {
                FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
              } else {
                FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
              }
            } else {
              _focusNodes[i]!.unfocus();
              if (_pin[i] == '') {
                FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
              }
            }
            if (_pin.every((String? digit) => digit != null && digit != '')) {
              widget.onSubmit(_pin.join());
            }
          },
          onSubmitted: (String str) {
            if (_pin.every((String? digit) => digit != null && digit != '')) {
              widget.onSubmit(_pin.join());
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return textfields;
  }
}
