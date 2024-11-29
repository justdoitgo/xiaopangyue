import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  void generateRandomNumber() async {
    if (isScrolling) {
      return;
    }

    final int start = int.parse(startController.text);
    final int end = int.parse(endController.text);
    final int count = int.parse(countController.text);
    final random = Random();

    if (isAuto) {
      //自动模式

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
          if (allowDuplicates) {
            selectedNumbers.add(randomNumber);
          } else {
            int num;
            do {
              num = start + random.nextInt(end - start + 1);
            } while (selectedNumbers.contains(num));
            selectedNumbers.add(num);
          }
        });
      }

      // 停止滚动
      _timer?.cancel();
      setState(() {
        isScrolling = false; // 停止滚动
        randomNumber = selectedNumbers.last; // 显示最终选中的数字
      });
    } else {

      // 滚动随机数
      _timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
        setState(() {
          randomNumber = start + random.nextInt(end - start + 1);
        });
      });

      // 手动模式
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
    if (!isScrolling || selectedNumbers.length >= int.parse(countController.text)) return;

    final int start = int.parse(startController.text);
    final int end = int.parse(endController.text);

    setState(() {
      if (allowDuplicates || !selectedNumbers.contains(randomNumber)) {
        selectedNumbers.add(randomNumber);
      }

      if (selectedNumbers.length < int.parse(countController.text)) {
        randomNumber = start + Random().nextInt(end - start + 1);
      } else {
        // 停止滚动
        _timer?.cancel();
        isScrolling = false; // 已选满
      }
    });
  }


  @override
  void dispose() {
    _timer?.cancel(); // 确保释放资源
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 45),
              child: Stack(
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5.0), // 添加适当的右边距
                      child: CustomPaint(
                        size: Size(20, 20),
                        painter: HexagonWithCirclePainter(),
                      ),
                    ),
                  ),
                ],
              )

              ,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 85,left: 10),
                child: Text(
                  "$randomNumber",
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 175,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               // Spacer(),
                Container(
                  padding: const EdgeInsets.only(left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(selectedNumbers.isNotEmpty)
                      Text(
                        "已选:",
                        style: TextStyle(color: Color(0xFFAAAAAA)),
                      ),
                      Text(
                        selectedNumbers.isNotEmpty
                            ? selectedNumbers.join('、')
                            : "",  // 为空时不显示文本
                        style: TextStyle(color: Color(0xFFAAAAAA)),
                      ),
                      SizedBox(height: 15), // 调整间隔
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          inputField("起始:", startController,isScrolling),
                          SizedBox(width: 20),
                          inputField("结束:", endController,isScrolling),
                          SizedBox(width: 20),
                          inputField("数量:", countController,isScrolling),
                        ],
                      ),
                      SizedBox(height: 10), // 调整间隔
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF111113),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                toggleButton("不重复", !allowDuplicates, () {
                                  if(isScrolling){
                                    return ;
                                  }
                                  setState(() {
                                    allowDuplicates = false;
                                  });


                                }),
                                toggleButton("可重复", allowDuplicates, () {
                                  if(isScrolling){
                                    return ;
                                  }
                                  setState(() {
                                    allowDuplicates = true;
                                  });
                                }),
                              ],
                            ),
                          ),
                          SizedBox(width: 50,),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF111113),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                toggleButton("手动  ", !isAuto, () {
                                  if(isScrolling){
                                    return ;
                                  }
                                  setState(() {
                                    isAuto = false;
                                  });
                                }),
                                toggleButton("自动  ", isAuto, () {
                                  if(isScrolling){
                                    return ;
                                  }
                                  setState(() {
                                    isAuto = true;
                                  });
                                }),
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
                    onPressed: isScrolling ? (isAuto ? null : selectManualNumber)
                        : generateRandomNumber,
                    style: TextButton.styleFrom(
                      splashFactory:NoSplash.splashFactory,
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      backgroundColor: Color(0xFF393939),
                      disabledBackgroundColor: Color(0xFF191919),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),// 设置最小宽度为无穷大，高度可根据需要调整
                    ),
                    child: Text(isScrolling ? (isAuto ? "选中" : "选中") : "开始"
                      ,style: TextStyle(color: Color(0xFFAAAAAA),fontSize: 19,),),
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

  Widget inputField(String label, TextEditingController controller,bool isScrolling) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Color(0xFFAAAAAA))),
        SizedBox(height: 5), // 调整输入框上方间隔
        Container(
          width: 100,
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
            enabled:!isScrolling,
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
          padding: EdgeInsets.symmetric(horizontal: 21, vertical: 5,),
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
      ..color =Color(0xFFAAAAAA)
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