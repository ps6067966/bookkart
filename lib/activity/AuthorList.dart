import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterapp/adapterView/AuthorListItem.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/AuthorListResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import 'AuthorDetails.dart';
import 'ErrorView.dart';
import 'NoInternetConnection.dart';

class AuthorList extends StatefulWidget {
  static var tag = "/AuthorList";

  @override
  _AuthorListState createState() => _AuthorListState();
}

class _AuthorListState extends State<AuthorList> {
  var mSearchCont = TextEditingController();
  var scrollController = new ScrollController();
  List<AuthorListResponse> mAuthorList = [];
  List<AuthorListResponse> mSearchList = [];
  String mSearchText = "";
  int page = 1;
  int mPerPage = 20;
  bool mIsLoading = false;

  @override
  void initState() {
    super.initState();
    getAuthorList(page);
    scrollController.addListener(() {
      scrollHandler();
    });
  }

  @override
  void dispose() {
    mSearchCont.dispose();
    scrollController.dispose();
    super.dispose();
  }

  scrollHandler() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      page++;
      getAuthorList(page);
    }
  }

  Future getAuthorList(page) async {
    setState(() {
      mIsLoading = true;
    });
    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await getAuthorListRestApi(page, mPerPage).then((res) async {
          mIsLoading = false;
          Iterable? mCategory = res;
          setState(() {
            mAuthorList.addAll(mCategory!.map((model) => AuthorListResponse.fromJson(model)).toList());
            mSearchList = mAuthorList;
          });
        }).catchError((onError) {
          setState(() {
            mIsLoading = false;
          });
          printLogs(onError.toString());
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        setState(() {
          mIsLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  String? getAuthorName(authorListResponse) {
    return authorListResponse.firstName + " " + authorListResponse.lastName;
  }

  Widget mSearch() {
    return Container(
      decoration: boxDecoration(showShadow: true, radius: 10, bgColor: appStore.editTextBackColor),
      width: double.infinity,
      child: TextField(
        controller: mSearchCont,
        cursorColor: primaryColor,
        maxLines: 1,
        onChanged: (string) {
          setState(() {
            mSearchList = mAuthorList.where((u) => (u.firstName!.toLowerCase().contains(string.toLowerCase()) || u.firstName!.toLowerCase().contains(string.toLowerCase()))).toList();
          });
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 18,
          color: appStore.appTextPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: keyString(context, "lbl_search_by_author_name"),
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: primaryTextStyle(color: appStore.textSecondaryColor, size: 18),
          fillColor: appStore.editTextBackColor,
          prefixIcon: Icon(
            Icons.search,
            color: appStore.iconColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainView = SingleChildScrollView(
      primary: false,
      controller: scrollController,
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            20.height,
            mSearch(),
            Text(
              keyString(context, "lbl_no_data_found")!,
              style: boldTextStyle(size: 18),
            ).paddingOnly(top: 20).visible(mSearchList.isEmpty),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return new GestureDetector(
                    child: AuthorListItem(mSearchList[index]),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthorDetails(
                          mSearchList[index],
                          mSearchList[index].gravatar,
                          getAuthorName(mSearchList[index]),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: mSearchList.length,
                shrinkWrap: true,
              ),
            ),
          ],
        ),
      ).visible(mAuthorList.isNotEmpty),
    );
    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: appBar(context, title: keyString(context, "lbl_author")) as PreferredSizeWidget?,
      body: RefreshIndicator(
        onRefresh: () {
          page = 1;
          mAuthorList.clear();
          return getAuthorList(page);
        },
        child: Stack(
          children: [
            mainView,
            CircularProgressIndicator().center().visible(mIsLoading && page > 1),
            Center(child: appLoaderWidget.center().visible(mIsLoading && page == 1)),
          ],
        ),
      ),
    );
  }
}
