import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Flutter InAppWebView Sample",
      home: SafeArea(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  InAppWebViewController? webViewController;

  void _sleep(int milisec) {
    sleep(Duration(milliseconds: milisec));
  }

  final int TIMEOUT_MSEC = 3000;

  late String _menu = "";

  // ロードが完了するまで待つ
  Future<void> _waitUntilLoad() async {
    int Counter = 0;
    while (true) {
      _sleep(100);
      Counter += 1;
      int? progress = await webViewController?.getProgress();
      if (progress == 100 || Counter * 100 > TIMEOUT_MSEC) break;
    }
    return;
  }

  // 翌日の日付をyyyyMMddで取得
  String _getTomorrow() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final outputFormat = DateFormat('yyyyMMdd');

    return outputFormat.format(tomorrow);
  }

  String _TodayOrTomorrowForLabel() {
    // お昼(13時)より前ならば本日の注文を表示する
    // お昼を過ぎていれば明日の注文を表示する

    initializeDateFormatting('ja');
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final outputFormat = DateFormat('MM月dd日');
    final dateFormatForDayOfWeek = DateFormat.E('ja');
    final tommorowDayOfWeek = dateFormatForDayOfWeek.format(tomorrow);
    final todayDayOfWeek = dateFormatForDayOfWeek.format(now);

    if (now.hour <= 13)
      return outputFormat.format(now) + '（' + todayDayOfWeek + '）';
    else
      return outputFormat.format(tomorrow) + '（' + tommorowDayOfWeek + '）';
  }

  // Web画面にログイン
  Future<void> _login() async {
    final url = URLRequest(
        url: Uri.parse("https://www.bento-chumon.com/user/14056411/"));
    await webViewController?.loadUrl(urlRequest: url);

    await webViewController?.evaluateJavascript(
        source: '''document.getElementsByName('custnum')[0].value='k3506';
           document.getElementsByName('pass')[0].value='p3506';
           check_submited();''');

    await _waitUntilLoad();

    _menu = await _getMenuFromCalender();
  }

  Future<String> _getMenuFromCalender() async {
    final day = DateFormat('dd').format(DateTime.now());

    var result = await webViewController?.evaluateJavascript(
        source:
            "document.getElementsByClassName('calendar__menu')[$day].innerText;");

    final res = result.toString();
    return res;
  }

  Future<void> _order(bool orderRice) async {
    await webViewController?.evaluateJavascript(
        source: "Day(${_getTomorrow()});");

    await _waitUntilLoad();

    await webViewController?.evaluateJavascript(source: "Menu('')");

    await _waitUntilLoad();

    if (orderRice) {
      // ご飯を注文する場合
      await webViewController
          ?.evaluateJavascript(source: '''Menuset('60225','1','340');''');
      await _waitUntilLoad();

      await webViewController
          ?.evaluateJavascript(source: '''Menuset('60224','0','260');''');
    } else {
      // ご飯を注文しない場合=>おかずだけを注文する
      await webViewController
          ?.evaluateJavascript(source: '''Menuset('60224','1','260');''');
      await _waitUntilLoad();

      await webViewController
          ?.evaluateJavascript(source: '''Menuset('60225','0','340');''');
    }
    await _waitUntilLoad();

    await webViewController?.evaluateJavascript(source: '''Pgback(); ''');

    await _waitUntilLoad();

    await webViewController?.evaluateJavascript(source: '''Order_Set('0');''');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('${_TodayOrTomorrowForLabel()}の注文：${_menu}',
          style: const TextStyle(
              decoration: TextDecoration.none,
              fontSize: 18,
              color: Color.fromARGB(255, 204, 221, 229))),
      Expanded(
          child: InAppWebView(
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://www.bento-chumon.com/user/14056411/")),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
      )),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.lightBlue[300]),
              onPressed: _login,
              child: const Text("ログイン")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(225, 245, 123, 0)),
              onPressed: () => _order(false),
              child: const Text("ごはん持参")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.yellow[700]),
              onPressed: () => _order(true),
              child: const Text("持参しない")),
        ],
      )
    ]);
  }
}
