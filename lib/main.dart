// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import "package:http/http.dart" as http;
import 'dart:io';

void main() {
  runApp(AskGPT());
}

String _apikey = '';
List<String> chat_history = [];
// URL for OpenAI API
final openaiUrl = 'https://api.openai.com/v1/';

// Function to send and receive text from OpenAI
Future<String> sendAndReceiveText(String text) async {
  // Set headers for API request
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apikey',
  };
  // Set request body
  final body =
      '{"model": "text-davinci-002", "prompt": "$text", "temperature": 0.5, "max_tokens": 60}';
  // Send POST request to OpenAI API
  final response = await http.post(Uri.parse(openaiUrl + 'completions'),
      headers: headers, body: body);

  // Return response body
  return response.body;
}

class AskGPT extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AskGPT();
  }
}

class _AskGPT extends State<AskGPT> {
  @override
  void initState() {
    super.initState();
    _readText().then((String value) {
      setState(() {
        _apikey = value;
      });
    });
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/myFile.txt');
  }

  Future<File> _writeText(String text) async {
    final file = await _getLocalFile();
    return file.writeAsString('$text');
  }

  Future<String> _readText() async {
    try {
      final file = await _getLocalFile();
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ask GPT",
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: IndexPage(),
      routes: {
        '/OpenAISetting': (context) => OpenAISettings(),
        //'/third': (context) => ThirdPage(),
      },
    );
  }
}

class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _IndexState();
  }
}

class _IndexState extends State<IndexPage> {
  final titles = [Text("Ask GPT"), Text("设置")];
  final btm_navibar_items = [
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: "聊天"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置"),
  ];
  final pages = [MyHomePage(), SettingMenu()];
  final appbars = [
    AppBar(
      title: Text("Ask GPT"),
      actions: [
        IconButton(onPressed: ()  {
              //TODO: clean chat history
        }, icon: Icon(Icons.cleaning_services_sharp)),
      ],
    ),
    AppBar(
      title: Text("设置"),
    ),
  ];
  int cur_idx = 0;
  @override
  void initState() {
    super.initState();
    cur_idx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbars[cur_idx],
      bottomNavigationBar: BottomNavigationBar(
        items: btm_navibar_items,
        type: BottomNavigationBarType.fixed,
        currentIndex: cur_idx,
        onTap: (index) {
          _changePage(index);
        },
      ),
      body: pages[cur_idx],
    );
  }

  void _changePage(int index) {
    /*如果点击的导航项不是当前项  切换 */
    if (index != cur_idx) {
      setState(() {
        cur_idx = index;
      });
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final myController = TextEditingController();

  void _newChat() async {
    String question=myController.text;
    myController.text='';
    String resp=await sendAndReceiveText("${question}");
    final directory =await getApplicationDocumentsDirectory();
    final chatFile=File('${directory.path}/chat_history.txt');
    //ret=ret.indexOf("message");
    setState(() {
      chat_history.removeAt(chat_history.length-1);
      chat_history.add(jsonDecode(resp)['error']['message']);
    });

    for(int i=0;i<chat_history.length;i++){
      chatFile.writeAsString(chat_history[i],mode: FileMode.write);
    }
  }

  String response;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: chat_history.length,
                itemBuilder: (BuildContext context, int index) {
                  return index % 2 == 1
                      ? ListTile(
                          leading: Image.asset('assets/images/gpt_avatar.png'),
                          title: Text(
                            "${chat_history[index]}",
                            softWrap: true,
                          ),
                        )
                      : ListTile(
                          leading: CircleAvatar(
                            child: Text("我"),
                          ),
                          title: Text(
                            "${chat_history[index]}",
                            softWrap: true,
                          ),
                        );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: myController,
                      decoration: InputDecoration(
                        hintText: '请输入消息',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // chat_history.add(chatFile.readAsStringSync());
                        chat_history.add(myController.text+'\n');
                        chat_history.add("正在思考中...\n");
                      });

                      _newChat();
                    },
                    child: Text('发送'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class OpenAISettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _OpenAISettingsState();
  }
}

class _OpenAISettingsState extends State<OpenAISettings> {
  final myController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readText().then((String value) {
      setState(() {
        _apikey = value;
        myController.text = _apikey; // set the text in the TextField
      });
    });
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/myFile.txt');
  }

  Future<File> _writeText(String text) async {
    final file = await _getLocalFile();
    return file.writeAsString('$text');
  }

  Future<String> _readText() async {
    try {
      final file = await _getLocalFile();
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('OpenAI 设置'),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              })),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: myController,
              decoration: InputDecoration(
                hintText: '在此输入API Key',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _writeText(myController.text);
                _readText().then((String value) {
                  setState(() {
                    _apikey = value;
                  });
                });
              },
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("OpenAI 设置"),
          ListTile(
            leading: Image.asset('assets/images/gpt_avatar.png'),
            title: Text("OpenAI设置"),
            subtitle: Text("API Key, API Server"),
            onTap: () {
              Navigator.pushNamed(context, '/OpenAISetting');
            },
          ),
        ],
      ),
    );
  }
}

// class ChatScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('聊天界面'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: 10,
//               itemBuilder: (BuildContext context, int index) {
//                 return index % 2 == 0
//                     ? ListTile(
//                         leading: CircleAvatar(
//                           child: Text('对'),
//                         ),
//                         title: Text('对方'),
//                         onTap: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: Text('对方'),
//                                 content: Text('你好'),
//                                 actions: [
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                     child: Text('关闭'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       )
//                     : ListTile(
//                         trailing: CircleAvatar(
//                           child: Text('我'),
//                         ),
//                         title: Text('我'),
//                         onTap: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: Text('我'),
//                                 content: Text('你好'),
//                                 actions: [
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                     child: Text('关闭'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       );
//               },
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.all(10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: '请输入消息',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 10,
//                 ),
//                 ElevatedButton(
//                   onPressed: () {},
//                   child: Text('发送'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
