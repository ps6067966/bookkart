import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterapp/activity/BookDetails.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/activity/ErrorView.dart';
import 'package:flutterapp/activity/NoInternetConnection.dart';
import 'package:flutterapp/adapterView/DownloadFilesViewOffline.dart';
import 'package:flutterapp/adapterView/PurchasedBookList.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/BookPurchaseResponse.dart';
import 'package:flutterapp/model/DashboardResponse.dart';
import 'package:flutterapp/model/OfflineBookList.dart';
import 'package:flutterapp/model/downloaded_book.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/database_helper.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

class MyLibraryView extends StatefulWidget {
  @override
  _MyLibraryViewState createState() => _MyLibraryViewState();
}

class _MyLibraryViewState extends State<MyLibraryView> {
  bool mIsLoading = false;
  var mOrderList = <BookPurchaseResponse>[];
  var mBookList = <LineItems>[];
  String firstName = "";
  int? _sliding = 0;
  final dbHelper = DatabaseHelper.instance;
  var downloadedList = <OfflineBookList>[];

  @override
  void initState() {
    super.initState();
    getUserDetails();
    getBookmarkBooks();
    fetchData(context);
  }

  void fetchData(context) async {
    int userId = await getInt(USER_ID, defaultValue: 0);
    List<OfflineBookList>? books = await (dbHelper.queryAllRows(userId));
    if (books!.isNotEmpty) {
      downloadedList.clear();
      downloadedList.addAll(books);
      setState(() {});
    } else {
      setState(() {
        downloadedList.clear();
      });
    }
  }

  void _settingModalBottomSheet(context, OfflineBookList downloadData) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          primary: false,
          child: Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(
                        top: spacing_standard_new,
                      ),
                      padding: EdgeInsets.only(right: spacing_standard),
                      child: Text(
                        "All Files",
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: appStore.appTextPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.close,
                        color: appStore.iconColor,
                        size: 30,
                      ),
                      onTap: () => {Navigator.of(context).pop()},
                    )
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: spacing_standard_new),
                  height: 2,
                  color: lightGrayColor,
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return DownloadFilesViewOffline(
                        downloadData.bookId,
                        downloadData.offlineBook[index],
                        downloadData.frontCover,
                        downloadData.bookName,
                      );
                    },
                    itemCount: downloadData.offlineBook.length,
                    shrinkWrap: true,
                  ),
                ).visible(downloadData.offlineBook.isNotEmpty),
              ],
            ),
          ),
        );
      },
    );
  }

  Future getUserDetails() async {
    firstName = "Hello, " + await getString(FIRST_NAME);
  }

  Future getBookmarkBooks() async {
    setState(() {
      mIsLoading = true;
    });

    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await getPurchasedRestApi().then((res) async {
          printLogs(res.toString());
          Iterable order = res;
          mOrderList = order.map((model) => BookPurchaseResponse.fromJson(model)).toList();
          mBookList.clear();
          setStringAsync(LIBRARY_DATA, jsonEncode(res));
          printLogs(mOrderList.length.toString());
          for (var i = 0; i < mOrderList.length; i++) {
            printLogs(mOrderList[i].lineItems!.length.toString());
            if (mOrderList[i].lineItems!.length > 0) {
              mBookList.addAll(mOrderList[i].lineItems!);
            }
          }
          setState(() {
            mIsLoading = false;
          });
        }).catchError((onError) {
          setState(() {
            mIsLoading = false;
          });
          printLogs(onError.toString());
          if (getBoolAsync(TOKEN_EXPIRED) == true) {
            getBookmarkBooks();
          } else {
            ErrorView(
              message: onError.toString(),
            ).launch(context);
          }
        });
      } else {
        setState(() {
          mIsLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  DownloadedBook? isExists(List<DownloadedBook> tasks, BookInfoDetails mBookDetail) {
    DownloadedBook? exist;
    tasks.forEach((task) {
      if (task.bookId == mBookDetail.id.toString()) {
        exist = task;
      }
    });
    if (exist == null) {
      exist = defaultBook(mBookDetail, "purchased");
    }
    return exist;
  }

  @override
  Widget build(BuildContext context) {
    Widget blankView = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(margin: EdgeInsets.all(spacing_standard_30), child: Image.asset("logo.png", width: 150)),
        Text(keyString(context, "lbl_you_don_t_have_any_purchased_book")!, style: boldTextStyle(size: 20, color: appStore.appTextPrimaryColor), textAlign: TextAlign.center),
        10.height,
        FittedBox(
          child: AppBtn(
              value: keyString(context, "lbl_purchased_now"),
              onPressed: () {
                DashboardActivity().launch(context);
              }),
        )
      ],
    );

    Widget mainView = Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 50),
      width: MediaQuery.of(context).size.width,
      child: (mBookList.length < 1)
          ? blankView.center()
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(firstName, style: TextStyle(fontSize: fontSizeMedium, color: appStore.appTextPrimaryColor)),
                Text(keyString(context, "lbl_your_purchased_library")!, style: TextStyle(fontSize: fontSizeXxxlarge, color: appStore.textSecondaryColor, fontWeight: FontWeight.bold)),
                GridView.builder(
                  itemCount: mBookList.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: getChildAspectRatio(),
                    crossAxisCount: getCrossAxisCount(),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      child: PurchasedBookList(mBookList[index]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetails(
                            mBookList[index].productId.toString(),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
    );

    Widget blankViewFreeBook = Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          30.height,
          Image.asset("logo.png", width: 150),
          30.height,
          Text(keyString(context, 'lbl_book_not_available')!, style: TextStyle(fontSize: fontSizeLarge, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold)),
          10.height,
        ],
      ),
    );

    Widget getList(List<OfflineBookList> list, context) {
      return Container(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 50),
        width: MediaQuery.of(context).size.width,
        child: (list.length < 1)
            ? blankViewFreeBook
            : GridView.builder(
              itemCount: list.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: getChildAspectRatio(),
                crossAxisCount: getCrossAxisCount(),
              ),
              controller: ScrollController(keepScrollOffset: false),
              itemBuilder: (context, index) {
                OfflineBookList bookDetail = list[index];
                return GestureDetector(
                  onTap: () {
                    _settingModalBottomSheet(context, bookDetail);
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 8),
                    width: bookWidth,
                    height: bookHeight,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: bookWidth,
                          height: bookHeight,
                          padding: EdgeInsets.all(8),
                          child: CachedNetworkImage(
                            placeholder: (context, url) => Center(
                              child: bookLoaderWidget,
                            ),
                            imageUrl: bookDetail.frontCover!,
                            fit: BoxFit.fill,
                          ).cornerRadiusWithClipRRect(10),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(left: 8, right: 8),
                            child: Text(bookDetail.bookName!,
                                overflow: TextOverflow.ellipsis, softWrap: true, textAlign: TextAlign.start, style: TextStyle(color: appStore.textSecondaryColor, fontSize: fontSizeSmall)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: appStore.scaffoldBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSlidingSegmentedControl(
                children: {
                  0: Container(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        keyString(context, "lbl_purchased_book")!,
                        style: primaryTextStyle(color: _sliding == 0 ? primaryColor : appStore.appTextPrimaryColor),
                      )),
                  1: Container(padding: EdgeInsets.all(8), child: Text(keyString(context, "lbl_free_book")!, style: primaryTextStyle(color: _sliding == 1 ? primaryColor : appStore.appTextPrimaryColor))),
                },
                groupValue: _sliding,
                onValueChanged: (dynamic newValue) {
                  setState(() {
                    _sliding = newValue;
                  });
                }),
          ),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            (!mIsLoading)
                ? ListView(
                    shrinkWrap: true,
                    children: [
                      if (_sliding == 0) mainView,
                      if (_sliding == 1) getList(downloadedList, context)
                    ],
                  )
                : appLoaderWidget.center().visible(mIsLoading),
          ],
        ),
      ),
    );
  }
}
