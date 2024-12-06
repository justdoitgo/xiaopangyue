import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 用于解析JSON数据

void main() {
  runApp(RandomNumberApp());
}

class RandomNumberApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.green, // 光标颜色
          selectionColor: Colors.blue.withOpacity(0.4), // 文本选择高亮颜色
          selectionHandleColor: Colors.green, // 文本选择句柄（水滴）的颜色
        ),
      ),
      home: RandomNumberPage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('zh', 'CN'),
      ],
    );
  }
}

class RandomNumberPage extends StatefulWidget {
  @override
  _RandomNumberPageState createState() => _RandomNumberPageState();
}

class _RandomNumberPageState extends State<RandomNumberPage> {
  List<int> selectedNumbers = [];
  List<int> httpSelectedNumbers = [];

  int randomNumber = 0;
  bool allowDuplicates = false; //是否可以重复
  bool isAuto = false; //是否自动模式
  bool isScrolling = false; // 控制滚动状态
  Timer? _timer; // 定时器用于滚动随机数

  final TextEditingController startController =
      TextEditingController(text: "1");
  final TextEditingController endController =
      TextEditingController(text: "100");
  final TextEditingController countController =
      TextEditingController(text: "100");

  String httpIp = "";

  int _clickCount = 0; // 连续点击次数
  Timer? _clicktimer; // 定时器，用于检测点击超时
  final int _timeLimit = 1000; // 点击的时间间隔限制（秒）

// 修改 generateRandomNumber 方法
  void generateRandomNumber() async {
    if (isScrolling) {
      return;
    }
    final int count = int.parse(countController.text);

    var url0 = "http://" + httpIp + ":8080/getCount?count=" + count.toString();

    try {
      if (httpIp != "") {
        // 发送GET请求
        final response = await http.get(Uri.parse(url0));

        if (response.statusCode == 200) {
          // 解析返回的数据
          final data = json.decode(response.body);
          if (data["code"] == 0 && data["vaule"] != null) {
            print("data:" + data["vaule"].toString());
            setState(() {
              httpSelectedNumbers = List<int>.from(data["vaule"]); // 设置预设中奖号码
            });
          } else {
            print("获取预设号码失败: ${data['message'] ?? '未知错误'}");
            httpSelectedNumbers.clear();
          }
        } else {
          print(e);
          httpSelectedNumbers.clear();
        }
      }
    } catch (e) {
      print(e);
      httpSelectedNumbers.clear();
    }

    print(
        "httpSelectedNumbers.length:" + httpSelectedNumbers.length.toString());

    final int start = int.parse(startController.text);
    final int end = int.parse(endController.text);
    final random = Random();

    if (isAuto) {
      setState(() {
        isScrolling = true; // 开始滚动
        selectedNumbers.clear(); // 清空选择的数字
      });

      // 滚动随机数
      _timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
        setState(() {
          randomNumber = start + random.nextInt(end - start + 1);
        });
      });

      // 延迟选择结果
      for (int i = 0; i < count; i++) {
        await Future.delayed(
            Duration(seconds: 1 + random.nextInt(2))); // 延迟1-3秒
        setState(() {
          if (httpSelectedNumbers.length > 0) {
            selectedNumbers.add(httpSelectedNumbers[i]);
          } else {
            if (allowDuplicates) {
              selectedNumbers.add(randomNumber);
            } else {
              int num;
              do {
                num = start + random.nextInt(end - start + 1);
              } while (selectedNumbers.contains(num));
              selectedNumbers.add(num);
            }
          }

/*          if (allowDuplicates) {
            selectedNumbers.add(randomNumber);
          } else {
            int num;
            do {
              num = start + random.nextInt(end - start + 1);
            } while (selectedNumbers.contains(num));
            selectedNumbers.add(num);
          }*/
        });
      }

      // 停止滚动
      _timer?.cancel();
      setState(() {
        isScrolling = false; // 停止滚动
        randomNumber = selectedNumbers.last; // 显示最终选中的数字
      });
    } else {
      // 手动模式逻辑保持不变
      _timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
        setState(() {
          randomNumber = start + random.nextInt(end - start + 1);
        });
      });

      setState(() {
        isScrolling = true;
        selectedNumbers.clear();
      });

      setState(() {
        randomNumber = start + random.nextInt(end - start + 1);
      });
    }
  }

  void selectManualNumber() {
    if (!isScrolling ||
        selectedNumbers.length >= int.parse(countController.text)) return;

    final int start = int.parse(startController.text);
    final int end = int.parse(endController.text);

    setState(() {
      if (allowDuplicates || !selectedNumbers.contains(randomNumber)) {
        if (httpSelectedNumbers.length > 0) {
          selectedNumbers.add(httpSelectedNumbers[selectedNumbers.length]);
        } else {
          selectedNumbers.add(randomNumber);
        }
      }

      if (selectedNumbers.length < int.parse(countController.text)) {
        if (httpSelectedNumbers.length > 0) {
          randomNumber = selectedNumbers.last;
        } else {
          randomNumber = start + Random().nextInt(end - start + 1);
        }
      } else {
        // 停止滚动
        _timer?.cancel();
        isScrolling = false; // 已选满
        randomNumber = selectedNumbers.last;
      }
    });
  }

  // 弹出框显示函数
  void _showDialog(BuildContext context) {
    final TextEditingController _ipController =
        TextEditingController(text: httpIp);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Stack(
            clipBehavior: Clip.none, // 使按钮能够超出Stack范围
            children: [
              Center(
                child: Text("输入ip地址"),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 自适应内容高度
            children: [
              // 用户名输入框
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'iP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 5, right: 5),
              child: Flex(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: ElevatedButton(
                          child: Text(
                            '取消',
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.white30),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(50.0),
                                  bottomRight: Radius.circular(50.0),
                                  topLeft: Radius.circular(50.0),
                                  topRight: Radius.circular(50.0),
                                ),
                              ),
                            ),
                          )),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 0),
                      child: ElevatedButton(
                          child: Text(
                            '确定',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                          onPressed: () {
                            httpIp = _ipController.text;
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(50.0),
                                  bottomRight: Radius.circular(50.0),
                                  topLeft: Radius.circular(50.0),
                                  topRight: Radius.circular(50.0),
                                ),
                              ),
                            ),
                          )),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // 确保释放资源
    _clicktimer?.cancel();
    super.dispose();
  }

  bool isShowIP() {
    // 每次点击时重置定时器
    _clicktimer?.cancel();
    _clicktimer = Timer(Duration(milliseconds: _timeLimit), () {
      // 超时后重置计数
      _clickCount = 0;
    });
    _clickCount++;
    if (_clickCount == 3) {
      // 重置计数和定时器
      _clickCount = 0;
      _clicktimer?.cancel();
      // 连续点击三次时触发弹窗
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 判断键盘是否弹出
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: Color(0x010103FF),
/*      appBar: AppBar(
        backgroundColor: Color(0x010103FF),
        elevation: 0,
        title: Center(
          child: Text(
            "随机数生成",
            style: TextStyle(color: Color(0xFF464647),
              fontWeight: FontWeight.bold,
              fontSize: 22,),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),*/
      body: Container(
        //height: MediaQuery.of(context).size.height, // 使用屏幕高度
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [

            // 使用 AnimatedSwitcher 来实现键盘弹出时的平滑过渡
            AnimatedOpacity(
              opacity: isKeyboardVisible ? 0.0 : 1.0, // 控制透明度
              duration: Duration(milliseconds: 300),
              child: isKeyboardVisible
                  ? SizedBox.shrink() // 键盘弹出时隐藏
                  : Container(
                key: ValueKey<bool>(isKeyboardVisible), // 使用键盘是否弹出作为 key，确保切换时动画正常
                padding: const EdgeInsets.only(top: 50, bottom: 50),
                child: Column(
                  children: [
                    Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        Center(
                          child: Text(
                            "随机数生成",
                            style: TextStyle(
                              color: Color(0xFF464647),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isShowIP()) {
                              _showDialog(context);
                            }
                          },
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 5.0),
                              child: CustomPaint(
                                size: Size(20, 20),
                                painter: HexagonWithCirclePainter(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              // color: Colors.red,
              padding: const EdgeInsets.only(top: 75, left: 10, bottom: 0),
              child: Text(
                "$randomNumber",
                style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 175,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spacer(),
                Container(
                  padding: const EdgeInsets.only(left: 5,top: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedNumbers.isNotEmpty)
                        Text(
                          "已选:",
                          style: TextStyle(color: Color(0xFFAAAAAA)),
                        ),
                      Text(
                        selectedNumbers.isNotEmpty
                            ? selectedNumbers.join('、')
                            : "", // 为空时不显示文本
                        style: TextStyle(color: Color(0xFFAAAAAA)),
                      ),
                      SizedBox(height: 15), // 调整间隔
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          inputField("起始:", startController, isScrolling),
                          SizedBox(width: 20),
                          inputField("结束:", endController, isScrolling),
                          SizedBox(width: 20),
                          inputField("数量:", countController, isScrolling),
                        ],
                      ),
                      SizedBox(height: 12), // 调整间隔
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF111113),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      toggleButton("不重复", !allowDuplicates, () {
                                        if (isScrolling) {
                                          return;
                                        }
                                        setState(() {
                                          allowDuplicates = false;
                                        });
                                      }),
                                      toggleButton("可重复", allowDuplicates, () {
                                        if (isScrolling) {
                                          return;
                                        }
                                        setState(() {
                                          allowDuplicates = true;
                                        });
                                      }),
                                    ],
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF111113),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      toggleButton("手动  ", !isAuto, () {
                                        if (isScrolling) {
                                          return;
                                        }
                                        setState(() {
                                          isAuto = false;
                                        });
                                      }),
                                      toggleButton("自动  ", isAuto, () {
                                        if (isScrolling) {
                                          return;
                                        }
                                        setState(() {
                                          isAuto = true;
                                        });
                                      }),
                                    ],
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ), // 调整间隔
                Center(
                  child: TextButton(
                    onPressed: isScrolling
                        ? (isAuto ? null : selectManualNumber)
                        : generateRandomNumber,
                    style: TextButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      backgroundColor: Color(0xFF393939),
                      disabledBackgroundColor: Color(0xFF191919),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Color(0xFF393939); // 按下时的背景颜色
                        }
                        return null;
                      }),
                      foregroundColor:
                          MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.white24; // 按下时文字颜色
                        }
                        return Color(0xFFAAAAAA); // 默认文字颜色
                      }),
                    ),
                    child: Text(
                      isScrolling ? (isAuto ? "选中" : "选中") : "开始",
                      style: TextStyle(fontSize: 19), // 文字大小设置
                    ),
                  ),
                ),

                SizedBox(height: 20), // 调整间隔
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget inputField(
      String label, TextEditingController controller, bool isScrolling) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Color(0xFFAAAAAA))),
        SizedBox(height: 5), // 调整输入框上方间隔
        Container(
          width: 98,
          height: 35,
          child: TextField(
            cursorColor: Colors.green, // 设置光标颜色为红色
            controller: controller,
            style: TextStyle(color: Color(0xFFAAAAAA)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFF191919),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
            ),
            keyboardType: TextInputType.number,
            enabled: !isScrolling,
          ),
        ),
      ],
    );
  }

  Widget toggleButton(String label, bool isSelected, VoidCallback onPressed) {
    if (isSelected) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 21,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF767678) : Colors.transparent,
            border: Border.all(color: Color(0xFFAAAAAA)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label, style: TextStyle(color: Color(0xFFAAAAAA))),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 21, vertical: 5),
          child: Text(label, style: TextStyle(color: Color(0xFFAAAAAA))),
        ),
      );
    }
  }
}

class HexagonWithCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint hexagonPaint = Paint()
      ..color = Color(0xFFAAAAAA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    Paint circlePaint = Paint()
      ..color = Color(0xFFAAAAAA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    Path hexagonPath = Path();
    double w = size.width / 2;
    double h = size.height / 2;
    double radius = w; // 六边形外接圆半径

    // 绘制六边形
    for (int i = 0; i < 6; i++) {
      double angle = (60 * i - 30) * 3.14159 / 180; // 角度换算为弧度
      double x = w + radius * cos(angle);
      double y = h + radius * sin(angle);
      if (i == 0) {
        hexagonPath.moveTo(x, y);
      } else {
        hexagonPath.lineTo(x, y);
      }
    }
    hexagonPath.close();

    // 绘制中心小圆
    canvas.drawCircle(Offset(w, h), radius / 4, circlePaint);

    // 绘制六边形路径
    canvas.drawPath(hexagonPath, hexagonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
