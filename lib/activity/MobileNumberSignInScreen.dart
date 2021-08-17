import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/activity/SignUpScreen.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/main.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:nb_utils/nb_utils.dart';

class MobileNumberSignInScreen extends StatefulWidget {
  MobileNumberSignInScreen({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MobileNumberSignInScreenState createState() => _MobileNumberSignInScreenState();
}

class _MobileNumberSignInScreenState extends State<MobileNumberSignInScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;
  late String phoneNo;
  late String code;
  String? smsOTP;
  String? data;
  var passwordCont = TextEditingController();
  var isLoading = false;

  Future<void> verifyPhoneNumber(BuildContext context) async {
    return await _auth.verifyPhoneNumber(
      phoneNumber: this.phoneNo,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          toast('The provided phone number is not valid.');
          throw 'The provided phone number is not valid.';
        } else {
          toast(e.toString());
          throw e.toString();
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        toast('Please check your phone for the verification code.');
        _verificationId = verificationId;
        smsOTPDialog(context).then((value) {});
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //
      },
    );
  }

  Future<void> signInWithPhoneNumber() async {
    setState(() {});
    AuthCredential credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: smsOTP.validate());

    await FirebaseAuth.instance.signInWithCredential(credential).then((result) async {
      Map req = {
        'username': this.data,
        'password': this.data,
      };
      signInApi(req);
    }).catchError((e) {
      log(e);
      toast(e.toString());
      isLoading = false;
      setState(() {});
    });
  }

  void signInApi(req) async {
    setState(() {
      isLoading = true;
    });
    await getLoginUserRestApi(req).then((res) async {
      if (!mounted) return;
      setIntAsync(USER_ID, res['user_id']);
      setStringAsync(FIRST_NAME, res['first_name']);
      setStringAsync(LAST_NAME, res['last_name']);
      setStringAsync(USER_EMAIL, res['user_email']);
      setStringAsync(USERNAME, res['user_nicename']);
      setStringAsync(TOKEN, res['token']);
      setStringAsync(AVATAR, res['avatar']);
      setBoolAsync(IS_SOCIAL_LOGIN, true);
      setBoolAsync(IS_LOGGED_IN, true);
      if (res['book_profile_image'] != null) {
        setStringAsync(PROFILE_IMAGE, res['book_profile_image']);
      }
      setStringAsync(USER_DISPLAY_NAME, res['user_display_name']);
      setState(() {
        isLoading = false;
      });
      DashboardActivity().launch(context, isNewTask: true);
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      if (error.toString() == "Invalid Credential.") {
        finish(context);
        SignUpScreen(userName: this.data.toString()).launch(context);
      }
    });
  }
  Future<bool?> smsOTPDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          backgroundColor: appStore.scaffoldBackground,
          title: Text(keyString(context, "lbl_sms_code")!, style: boldTextStyle(color: appStore.appTextPrimaryColor)),
          content: Container(
            height: 85,
            child: Column(
              children: [
                PinEntryTextField(
                  onSubmit: (value) {
                    this.smsOTP = value;
                  },
                ),
              ],
            ),
          ),
          contentPadding: EdgeInsets.all(10),
          actions: <Widget>[
            AppButton(
                width: context.width(),
                text: keyString(context, "lbl_done"),
                onTap: () {
                  hideKeyboard(context);
                  Navigator.pop(context);
                  signInWithPhoneNumber();
                },
                color: primaryColor),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          key: _scaffoldKey,
          //resizeToAvoidBottomPadding: false,
          appBar: appBar(context, title: keyString(context, "lbl_otp_verification"), showBack: true) as PreferredSizeWidget?,
          backgroundColor: appStore.scaffoldBackground,
          body: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Image.asset("main_logo.png", width: 200, height: 200),
                  Container(
                    decoration: boxDecorationWithRoundedCorners(backgroundColor: appStore.editTextBackColor!, borderRadius: radius(8), border: Border.all(color: Theme.of(context).textTheme.subtitle1!.color!)),
                    padding: EdgeInsets.only(left: 8),
                    child: Row(
                      children: <Widget>[
                        CountryCodePicker(
                          onChanged: (value) {
                            this.code = value.dialCode.toString();
                          },
                          backgroundColor: Colors.transparent,
                          showFlag: true,
                          padding: EdgeInsets.all(4),
                          dialogBackgroundColor: appStore.scaffoldBackground,
                          textStyle: primaryTextStyle(color: appStore.appTextPrimaryColor),
                        ),
                        Container(
                          height: 30.0,
                          width: 1.0,
                          color: primaryColor,
                          margin: EdgeInsets.only(left: 10.0, right: 10.0),
                        ),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            style: secondaryTextStyle(size: 18, color: appStore.appTextPrimaryColor),
                            controller: passwordCont,
                            decoration: InputDecoration(
                              counterText: "",
                              contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                              hintText: keyString(context, "hint_mobile_number"),
                              hintStyle: secondaryTextStyle(size: 18, color: appStore.appTextPrimaryColor),
                              border: InputBorder.none,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  24.height,
                  AppButton(
                      width: context.width(),
                      text: keyString(context, "lbl_verify"),
                      onTap: () {
                        hideKeyboard(context);
                        if (passwordCont.text.isEmpty) {
                          toast(keyString(context, "lbl_field_required"));
                        } else {
                          this.phoneNo = this.code + passwordCont.text.toString();
                          this.data = passwordCont.text.toString();
                          verifyPhoneNumber(context);
                        }
                      },
                      color: primaryColor),
                ],
              ).center().paddingAll(16),
              Center(child: CircularProgressIndicator()).visible(isLoading),
            ],
          )),
    );
  }
}
