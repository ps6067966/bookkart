import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/activity/MobileNumberSignInScreen.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/LoginResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/service/LoginService.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/EmailValidator.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/images.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import '../main.dart';
import 'DashboardActivity.dart';
import 'ErrorView.dart';
import 'NoInternetConnection.dart';
import 'SignUpScreen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  var usernameCont = TextEditingController();
  var passwordCont = TextEditingController();
  bool isLoading = false;
  bool? isRemember = false;
  final _formKey = GlobalKey<FormState>();
  var autoValidate = false;
  var email = TextEditingController();

  Future loginApiCall(request) async {
    await isNetworkAvailable().then((bool) async {
      if (bool) {
        isLoading = true;
        await getLoginUserRestApi(request).then((res) {
          LoginResponse response = LoginResponse.fromJson(res);
          setInt(USER_ID, response.userId!);
          setStringAsync(FIRST_NAME, response.firstName!);
          setStringAsync(LAST_NAME, response.lastName!);
          setStringAsync(USER_EMAIL, response.userEmail!);
          setStringAsync(USERNAME, response.userNicename!);
          setStringAsync(TOKEN, response.token!);
          setStringAsync(AVATAR, response.avatar!);
          if (response.profileImage != null) {
            setStringAsync(PROFILE_IMAGE, response.profileImage!);
          }
          setBool(REMEMBER_PASSWORD, isRemember!);
          setStringAsync(PASSWORD, passwordCont.text.toString());
          if (isRemember!) {
            setStringAsync(EMAIL, usernameCont.text.toString());
            //setString(PASSWORD, passwordCont.text.toString());
          } else {
          //  setString(PASSWORD, "");
            setStringAsync(EMAIL, '');
          }
          setStringAsync(USER_DISPLAY_NAME, response.userDisplayName!);
          setBool(IS_LOGGED_IN, true);
          setState(() {
            isLoading = false;
          });
          DashboardActivity().launch(context, isNewTask: true);
        }).catchError((onError) {
          setState(() {
            isLoading = false;
          });
          printLogs(onError.toString());
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        setState(() {
          isLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  Future forgotPwdApi(value) async {
    await isNetworkAvailable().then((bool) async {
      setState(() {
        isLoading = true;
      });
      if (bool) {
        var request = {
          'email': value,
        };
        await forgetPassword(request).then((res) async {
          setState(() {
            isLoading = false;
          });
          toast(res["message"]);
        }).catchError((onError) {
          setState(() {
            isLoading = false;
          });
          log("Error:" + onError.toString());
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        setState(() {
          isLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (Platform.isIOS) {
      TheAppleSignIn.onCredentialRevoked!.listen((_) {
        log("Credentials revoked");
      });
    }
    var remember = await getBool(REMEMBER_PASSWORD);
    if (remember) {
      var password = await getString(PASSWORD);
      var email = await getString(EMAIL);
      setState(() {
        usernameCont.text = email;
        passwordCont.text = password;
      });
    }
    setState(() {
      isRemember = remember;
    });
  }

  void socialLogin(req) async {
    setState(() {
      isLoading = true;
    });
    await socialLoginApi(req).then((response) async {
      if (!mounted) return;
      await getCustomer(response['user_id']).then((res) {
        if (!mounted) return;
        setBoolAsync(IS_SOCIAL_LOGIN, true);
        setStringAsync(AVATAR, req['photoURL']);
        setIntAsync(USER_ID, response['user_id']);
        setStringAsync(FIRST_NAME, res['first_name']);
        setStringAsync(LAST_NAME, res['last_name']);
        setStringAsync(USER_EMAIL, response['user_email']);
        setStringAsync(USERNAME, response['user_nicename']);
        setStringAsync(TOKEN, response['token']);
        setStringAsync(USER_DISPLAY_NAME, response['user_display_name']);
        setBoolAsync(IS_LOGGED_IN, true);
        setState(() {
          isLoading = false;
        });
        DashboardActivity().launch(context, isNewTask: true);
      }).catchError((error) {
        setState(() {
          isLoading = false;
        });
        print(error.toString());
        toast(error.toString());
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      toast(error.toString());
    });
  }

  void onGoogleSignInTap() async {
    var service = LoginService();
    await service.signInWithGoogle().then((res) {
      socialLogin(res);
    }).catchError((e) {
      toast(e.toString());
    });
  }

  saveAppleDataWithoutEmail() async {
    await getSharedPref().then((pref) {
      log(getStringAsync('appleEmail'));
      log(getStringAsync('appleGivenName'));
      log(getStringAsync('appleFamilyName'));

      var req = {
        'email': getStringAsync('appleEmail'),
        'firstName': getStringAsync('appleGivenName'),
        'lastName': getStringAsync('appleFamilyName'),
        'photoURL': '',
        'accessToken': '12345678',
        'loginType': 'apple',
      };
      socialLogin(req);
    });
  }

  saveAppleData(result) async {
    setStringAsync('appleEmail', result.credential.email);
    setStringAsync('appleGivenName', result.credential.fullName.givenName);
    setStringAsync('appleFamilyName', result.credential.fullName.familyName);

    log('Email:- ${getStringAsync('appleEmail')}');
    log('appleGivenName:- ${getStringAsync('appleGivenName')}');
    log('appleFamilyName:- ${getStringAsync('appleFamilyName')}');

    var req = {
      'email': result.credential.email,
      'firstName': result.credential.fullName.givenName,
      'lastName': result.credential.fullName.familyName,
      'photoURL': '',
      'accessToken': '12345678',
      'loginType': 'apple',
    };
    socialLogin(req);
  }

  void appleLogIn() async {
    if (await TheAppleSignIn.isAvailable()) {
      final AuthorizationResult result = await TheAppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);
      switch (result.status) {
        case AuthorizationStatus.authorized:
          log("Result: $result"); //All the required credentials
          if (result.credential!.email == null) {
            saveAppleDataWithoutEmail();
          } else {
            saveAppleData(result);
          }
          break;
        case AuthorizationStatus.error:
          log("Sign in failed: ${result.error!.localizedDescription}");
          break;
        case AuthorizationStatus.cancelled:
          log('User cancelled');
          break;
      }
    } else {
      toast('Apple SignIn is not available for your device');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget socialButtons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(10), backgroundColor: googleColor),
          padding: EdgeInsets.all(8),
          child: Image.asset(ic_google, color: white, width: 24, height: 24),
        ).onTap(() {
          onGoogleSignInTap();
        }),
        16.width,
        Container(
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(10), backgroundColor: primaryColor),
          padding: EdgeInsets.all(8),
          child: Image.asset(ic_calling, color: white, width: 24, height: 24),
        ).onTap(() {
          MobileNumberSignInScreen().launch(context);
        }),
        16.width,
        Container(
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(10), backgroundColor: Colors.black),
          padding: EdgeInsets.all(8),
          child: Image.asset(ic_apple, color: white, width: 24, height: 24),
        ).onTap(() {
          appleLogIn();
        }).visible(Platform.isIOS),
      ],
    );

    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset("main_logo.png", width: 150, height: 150),
                    16.height,
                    Padding(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            EditText(
                              hintText: keyString(context, "hint_enter_email"),
                              isPassword: false,
                              mController: usernameCont,
                              mKeyboardType: TextInputType.emailAddress,
                              validator: (String? s) {
                                if (s!.trim().isEmpty) {
                                  return keyString(context, "lbl_email_id")! + " " + keyString(context, "lbl_field_required")!;
                                }
                                if (!EmailValidator.validate(s)) {
                                  return keyString(context, "error_email_address");
                                }
                                return null;
                              },
                            ),
                            14.height,
                            EditText(
                              hintText: keyString(context, "hint_enter_password"),
                              isPassword: true,
                              mController: passwordCont,
                              isSecure: true,
                              validator: (String? s) {
                                if (s!.trim().isEmpty) return keyString(context, "lbl_password")! + " " + keyString(context, "lbl_field_required")!;
                                return null;
                              },
                            ),
                            8.height,
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomTheme(
                              child: Checkbox(
                                focusColor: primaryColor,
                                activeColor: primaryColor,
                                value: isRemember,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isRemember = value;
                                  });
                                },
                              ),
                            ),
                            Text(
                              keyString(context, "lbl_remember_me")!,
                              style: secondaryTextStyle(
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          keyString(context, "lbl_forgot_password")!,
                          style: secondaryTextStyle(
                            size: 18,
                          ),
                        ).onTap(() {
                          customDialog(context);
                        }),
                      ],
                    ).paddingOnly(left: 8, right: 16),
                    8.height,
                    AppBtn(
                      value: keyString(context, "lbl_sign_in"),
                      onPressed: () {
                        hideKeyboard(context);
                        var request = {"username": "${usernameCont.text}", "password": "${passwordCont.text}"};
                        if (!mounted) return;
                        setState(() {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });
                            loginApiCall(request);
                          } else {
                            setState(() {
                              isLoading = false;
                              autoValidate = true;
                            });
                          }
                        });
                      },
                    ).paddingOnly(left: 20, right: 20),
                    20.height,
                    socialButtons,
                    16.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(keyString(context, "lbl_don_t_have_an_account")!,
                            style: primaryTextStyle(
                              size: 18,
                            )),
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          child: GestureDetector(
                              child: Text(keyString(context, "lbl_sign_up")!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: primaryColor,
                                  )),
                              onTap: () {
                                SignUpScreen().launch(context);
                              }),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          isLoading
              ? Container(
                  child: CircularProgressIndicator(),
                  alignment: Alignment.center,
                )
              : SizedBox(),
        ],
      ),
    );
  }

  Future customDialog(BuildContext context) async {
    final _formKey1 = GlobalKey<FormState>();
    var autoValidate1 = false;
    var email = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing_control),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: boxDecoration(color: appStore.scaffoldBackground!, radius: 10.0, bgColor: appStore.scaffoldBackground),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(keyString(context, "lbl_forgot_password")!, style: boldTextStyle(size: 24))
                      .paddingOnly(left: spacing_standard_new.toDouble(), right: spacing_standard_new.toDouble(), top: spacing_standard_new.toDouble()),
                  SizedBox(height: spacing_standard_new.toDouble()),
                  Form(
                    key: _formKey1,
                    // ignore: deprecated_member_use
                    autovalidate: autoValidate1,
                    child: Column(
                      children: [
                        EditText(
                          hintText: keyString(context, "hint_enter_email"),
                          isPassword: false,
                          mController: email,
                          mKeyboardType: TextInputType.emailAddress,
                          validator: (String? s) {
                            if (s!.trim().isEmpty) return keyString(context, "lbl_email_id")! + " " + keyString(context, "lbl_field_required")!;
                            if (!EmailValidator.validate(s)) {
                              return keyString(context, "error_email_address");
                            }
                            return null;
                          },
                        ),
                      ],
                    ).paddingOnly(left: spacing_standard_new.toDouble(), right: spacing_standard_new.toDouble(), bottom: spacing_standard.toDouble()),
                  ),
                  AppBtn(
                    value: keyString(context, "lbl_submit"),
                    onPressed: () {
                      if (_formKey1.currentState!.validate()) {
                        hideKeyboard(context);
                        Navigator.of(context).pop();
                        forgotPwdApi(email.text);
                      } else {
                        isLoading = false;
                        autoValidate1 = true;
                      }
                    },
                  ).paddingAll(spacing_standard_new.toDouble()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
