import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:epub_viewer/epub_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/DashboardResponse.dart';
import 'package:flutterapp/model/downloaded_book.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/database_helper.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

// ignore: must_be_immutable
class ViewEPubFileNew extends StatefulWidget {
  Downloads downloads;
  static String tag = '/EpubFiles';
  String? mBookId, mBookName, mBookImage;
  final TargetPlatform platform;
  bool isPDFFile = false;
  bool _isFileExist = false;

  ViewEPubFileNew(this.mBookId, this.mBookName, this.mBookImage, this.downloads, this.platform, this.isPDFFile, this._isFileExist);

  @override
  ViewEPubFileNewState createState() => ViewEPubFileNewState();
}

class ViewEPubFileNewState extends State<ViewEPubFileNew> {
  _TaskInfo? _tasks;
  bool isDownloadFile = false;
  bool isDownloadFailFile = false;
  String percentageCompleted = "";
  ReceivePort _port = ReceivePort();
  String fullFilePath = "";
  int userId = 0;
  final dbHelper = DatabaseHelper.instance;
  DownloadedBook? mSampleDownloadTask;
  DownloadedBook? mBookDownloadTask;
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();

  // int currentPage = 0;
  int? mTotalPage = 0;
  var pageCont = TextEditingController();
  bool mIsLoading = false;

  @override
  void initState() {
    super.initState();
    initialDownload();
    init();
  }

  init() async {
    var mCurrentPAgeData = await getInt(PAGE_NUMBER + widget.mBookId!);
    if (mCurrentPAgeData.toString().isNotEmpty) {
      appStore.setPage(mCurrentPAgeData);
    } else {
      appStore.setPage(0);
    }
  }

  // ignore: missing_return
  Future initialDownload() async {
    if (widget._isFileExist) {
      String filePath = await getBookFilePath(widget.mBookId, widget.downloads.file!);
      setState(() {
        isDownloadFile = true;
      });
      _openDownloadedFile(filePath);
    } else {
      userId = await getInt(USER_ID);
      _bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback);
      requestPermission();
    }
  }

  void requestPermission() async {
    if (await checkPermission(widget)) {
      _prepare();
    } else {
      if (widget.platform == TargetPlatform.android) {
        Navigator.of(context).pop();
      } else {
        _prepare();
      }
    }
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() async {
    bool isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');

    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }

    _port.listen((dynamic data) async {
      DownloadTaskStatus? status = data[1];
      int? progress = data[2];
      if (_tasks != null) {
        setState(() {
          _tasks!.status = status;
          _tasks!.progress = progress;
          percentageCompleted = _tasks!.progress!.toStringAsFixed(2).toString();
          percentageCompleted = percentageCompleted + "% Completed";
        });
        if (_tasks!.status == DownloadTaskStatus.complete) {
          FlutterDownloader.remove(taskId: _tasks!.taskId!, shouldDeleteContent: false);
          String filePath = await getBookFilePath(widget.mBookId, _tasks!.link!);
          insertIntoDb(filePath);
          _openDownloadedFile(filePath);
          setState(() {
            isDownloadFile = true;
          });
        } else if (_tasks!.status == DownloadTaskStatus.failed) {
          setState(() {
            isDownloadFailFile = true;
          });
        }
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: appStore.scaffoldBackground,
        appBar: appBar(context, title: widget.downloads.name) as PreferredSizeWidget?,
        body: Builder(
          builder: (context) => !isDownloadFile
              ? isDownloadFailFile
                  ? new Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: spacing_standard_new),
                            child: Text(
                              keyString(context, "lbl_download_failed")!,
                              style: TextStyle(fontSize: fontSizeLarge, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    )
                  : new Center(
                      child: (_tasks != null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 15,
                                    value: _tasks!.progress!.toDouble(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: spacing_standard_new),
                                  child: Text(
                                    percentageCompleted,
                                    style: TextStyle(fontSize: fontSizeLarge, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            )
                          : SizedBox(),
                    )
              : !widget.isPDFFile
                  ? SizedBox()
                  : Observer(
                      builder: (_) => Container(
                            height: MediaQuery.of(context).size.height,
                            child: PDFView(
                              filePath: fullFilePath,
                              pageSnap: false,
                              swipeHorizontal: false,
                              onViewCreated: (PDFViewController pdfViewController) {
                                _controller.complete(pdfViewController);
                              },
                              onPageChanged: (int? page, int? total) {
                                setInt(PAGE_NUMBER + widget.mBookId.toString(), page!);
                                setState(() {
                                  appStore.setPage(page);
                                  mTotalPage = total;
                                });
                              },
                              defaultPage: appStore.page!,
                            ),
                          )),
        ),
        floatingActionButton: Container(
          decoration: boxDecorationRoundedWithShadow(50, backgroundColor: appStore.appBarColor!),
          padding: EdgeInsets.all(16),
          child: Text(keyString(context, "lbl_go_to")! + " ${appStore.page} / $mTotalPage", style: boldTextStyle()),
        ).onTap(() async {
          int? v = await showInDialog(
            context,
            backgroundColor: appStore.appBarColor,
            actions: [
              Text(keyString(context, "lbl_ok")!, style: boldTextStyle(color: Theme.of(context).primaryColor)).paddingAll(8).onTap(() async {
                Navigator.pop(context, pageCont.text.toInt());
                setState(() {});
              }),
              Text(keyString(context, "lbl_cancel")!, style: secondaryTextStyle(size: 16)).paddingAll(8).onTap(() {
                Navigator.pop(context);
              })
            ],
            builder:(ctx) => EditText(hintText: keyString(context, "lbl_enter_page_number"), isPassword: false, mController: pageCont, mKeyboardType: TextInputType.number),
            contentPadding: EdgeInsets.all(16),
            shape: dialogShape(),
            title: Text(keyString(context, "lbl_enter_page_number")!),
          );

          if (v != null) {
            PDFViewController pdf = await _controller.future;
            appStore.setPage(v);
            await pdf.setPage(v);
            setState(() {});
          }
        }),
      ),
    );
  }

  void _resumeDownload(_TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  void _retryDownload(_TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  // ignore: missing_return
  _openDownloadedFile(String filePath) async {
    setState(() {
      fullFilePath = filePath;
    });

    if (!widget.isPDFFile) {
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
        setStringAsync('locator', locator);
      });
      Navigator.of(context).pop();
    }
  }

  Future<String> getTaskId(id) async {
    int userId = await getInt(USER_ID, defaultValue: 0);
    printLogs(userId.toString() + "_" + id);
    return userId.toString() + "_" + id;
  }

  Future<Null> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();
    _tasks = _TaskInfo(name: widget.downloads.name, link: widget.downloads.file, taskId: await getTaskId(widget.downloads.id));
    tasks?.forEach((task) {
      if (_tasks!.link == task.url) {
        _tasks!.taskId = task.taskId;
        _tasks!.status = task.status;
        _tasks!.progress = task.progress;
      }
    });
    var fileName = await getBookFileName(widget.mBookId, _tasks!.link!);
    String filePath = await getBookFilePath(widget.mBookId, _tasks!.link!);
    String path = await localPath;
    final savedDir = Directory(path);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }

    if (_tasks!.status == DownloadTaskStatus.complete) {
      FlutterDownloader.remove(taskId: _tasks!.taskId!, shouldDeleteContent: false);
      insertIntoDb(filePath);
      _openDownloadedFile(filePath);
      setState(() {
        isDownloadFile = true;
      });
    } else if (_tasks!.status == DownloadTaskStatus.paused) {
      _resumeDownload(_tasks!);
    } else if (_tasks!.status == DownloadTaskStatus.undefined) {
      _tasks!.taskId = await FlutterDownloader.enqueue(url: _tasks!.link!, fileName: fileName, savedDir: path, showNotification: true, openFileFromNotification: false);
    } else if (_tasks!.status == DownloadTaskStatus.failed) {
      _retryDownload(_tasks!);
    }
  }

  void insertIntoDb(filePath) async {
    /**
     * Store data to db for offline usage
     */
    DownloadedBook _download = DownloadedBook();
    _download.bookId = widget.mBookId;
    _download.bookName = widget.mBookName;
    _download.frontCover = widget.mBookImage;
    _download.fileType = widget.isPDFFile ? "PDF File" : "EPub File";
    _download.filePath = filePath;
    _download.userId = userId.toString();
    _download.fileName = widget.downloads.name;
    await dbHelper.insert(_download);
  }
}

class _TaskInfo {
  final String? name;
  final String? link;
  String? taskId;

  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link, this.taskId});
}
