import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/RegisterResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/EmailValidator.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:nb_utils/nb_utils.dart';
import '../main.dart';
import 'ErrorView.dart';
import 'NoInternetConnection.dart';

class SignUpScreen extends StatefulWidget {
  final String? userName;

  const SignUpScreen({Key? key, this.userName}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var usernameCont = TextEditingController();
  var fullname = TextEditingController();
  var passwordCont = TextEditingController();
  var confirmPasswordCont = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  var autoValidate = false;
  var mUsername;

  Future registerUser(request) async {
    await isNetworkAvailable().then((bool) async {
      if (bool) {
        isLoading = true;
        await getRegisterUserRestApi(request).then((res) {
          isLoading = false;
          RegisterResponse response = RegisterResponse.fromJson(res);
          if (response.code == 200) {
            if (widget.userName != null) {
              if (widget.userName!.isNotEmpty) {
                var request = {"username": widget.userName, "password": widget.userName};
                log("Request" + request.toString());
                signInApi(request);
              } else {
                toast(keyString(context, "lbl_registration_completed"));
                finish(context);
              }
            } else {
              toast(keyString(context, "lbl_registration_completed"));
              Navigator.pop(context);
            }
            setState(() {});
          } else if (response.code == 406) {
            ErrorView(
              message: response.message.toString(),
            ).launch(context);
          } else {
            ErrorView(
              message: "400 Error",
            ).launch(context);
          }
        }).catchError((onError) {
          setState(() {
            isLoading = false;
          });
          log("Error" + onError.toString());
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
      if (res['book_profile_image'] != null) {
        setStringAsync(PROFILE_IMAGE, res['book_profile_image']);
      }
      setStringAsync(USER_DISPLAY_NAME, res['user_display_name']);
      setBoolAsync(IS_LOGGED_IN, true);
      setBoolAsync(IS_SOCIAL_LOGIN, true);
      setState(() {
        isLoading = false;
      });
      DashboardActivity().launch(context, isNewTask: true);
    }).catchError((error) {
      log("Error" + error.toString());
      setState(() {
        isLoading = false;
      });
      toast(error.toString());
    });
  }

  @override
  void initState() {
    if (widget.userName.isEmptyOrNull) {
      mUsername = "";
    } else {
      mUsername = widget.userName.toString();
    }
    log("mUSerName" + mUsername.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: appBar(context, showTitle: false) as PreferredSizeWidget?,
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(spacing_standard_new),
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Image.asset(
                                "main_logo.png",
                                width: 200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: Container(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                EditText(
                                  hintText: keyString(context, "hint_enter_full_name"),
                                  isPassword: false,
                                  mController: fullname,
                                  mKeyboardType: TextInputType.text,
                                  validator: (String? s) {
                                    if (s!.trim().isEmpty) return keyString(context, "lbl_full_name")! + " " + keyString(context, "lbl_field_required")!;
                                    if (s.contains(RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%0-9-]'))) return keyString(context, "error_string");
                                    return null;
                                  },
                                ),
                                SizedBox(height: 14),
                                EditText(
                                  hintText: keyString(context, "hint_enter_email"),
                                  isPassword: false,
                                  mController: usernameCont,
                                  mKeyboardType: TextInputType.emailAddress,
                                  validator: (String? s) {
                                    if (s!.trim().isEmpty) return keyString(context, "lbl_email_id")! + " " + keyString(context, "lbl_field_required")!;
                                    if (!EmailValidator.validate(s)) {
                                      return keyString(context, "error_email_address");
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 14),
                                widget.userName.isEmptyOrNull
                                    ? EditText(
                                        hintText: keyString(context, "hint_enter_password"),
                                        isPassword: true,
                                        mController: passwordCont,
                                        isSecure: true,
                                        validator: (String? s) {
                                          if (s!.trim().isEmpty) return keyString(context, "lbl_password")! + " " + keyString(context, "lbl_field_required")!;
                                          if (s.length <= 5) return keyString(context, "error_pwd_length");
                                          return null;
                                        },
                                      )
                                    : SizedBox(),
                                SizedBox(height: 14).visible(widget.userName.isEmptyOrNull),
                                widget.userName.isEmptyOrNull
                                    ? EditText(
                                        hintText: keyString(context, "hint_re_enter_password"),
                                        isPassword: true,
                                        mController: confirmPasswordCont,
                                        isSecure: true,
                                        validator: (String? s) {
                                          if (s!.trim().isEmpty) return keyString(context, "lbl_re_enter_pwd")! + " " + keyString(context, "lbl_field_required")!;
                                          if (confirmPasswordCont.text != passwordCont.text) return keyString(context, "lbl_pwd_not_match");
                                          return null;
                                        },
                                      )
                                    : SizedBox(),
                                SizedBox(height: 14.0).visible(widget.userName.isEmptyOrNull),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      AppBtn(
                        value: keyString(context, "lbl_sign_up"),
                        onPressed: () {
                          hideKeyboard(context);
                          var request = {
                            "first_name": "${fullname.text}",
                            "last_name": "${fullname.text}",
                            "email": "${usernameCont.text}",
                            "username": widget.userName != null
                                ? widget.userName!.isNotEmpty
                                    ? widget.userName
                                    : usernameCont.text
                                : usernameCont.text,
                            "password": widget.userName != null
                                ? widget.userName!.isNotEmpty
                                    ? widget.userName
                                    : passwordCont.text
                                : passwordCont.text,
                          };
                          if (!mounted) return;
                          setState(() {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                              });
                              registerUser(request);
                            } else {
                              setState(() {
                                isLoading = false;
                                autoValidate = true;
                              });
                            }
                          });
                        },
                      ).paddingOnly(left: 20, right: 20),
                      SizedBox(
                        height: 20,
                      ),
                      Wrap(
                        children: [
                          Text(keyString(context, "lbl_already_have_an_account")!,
                              style: primaryTextStyle(
                                size: 18,
                              )),
                          Container(
                              margin: EdgeInsets.only(left: 4),
                              child: GestureDetector(
                                  child: Text(keyString(context, "lbl_sign_in")!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: primaryColor,
                                      )),
                                  onTap: () {
                                    Navigator.pop(context);
                                  })),
                        ],
                      ),
                    ],
                  ),
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
}
