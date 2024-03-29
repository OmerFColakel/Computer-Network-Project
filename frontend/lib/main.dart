import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyLoginPage(),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({super.key});

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/login');
    try {
      var body = jsonEncode({
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      print('body: $body');
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        print('response: ${response.body}');
        var user_id = jsonDecode(response.body)['user_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(user_id: user_id),
          ),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonDecode(response.body)['message']),
          ),
        );
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<void> _register() async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/register');
    try {
      var body = jsonEncode({
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User registered successfully'),
          ),
        );
      } else {
        print('message: ${jsonDecode(response.body)['message']}');
        if (jsonDecode(response.body)['message'] == 'Email already exists') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User already exists. Try a different email.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ),
              Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _login();
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _register();
                      },
                      child: const Text('Register'),
                    ),
                  ),
                )
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.user_id});

  final String user_id;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentDirectory = '';
  bool addOperation = false;
  String downloadPath = '/storage/emulated/0/Download/';

  @override
  void initState() {
    super.initState();
    _getDirectory();
  }

  Future<void> _getDirectory() async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/currentDirectory');
    try {
      var body = jsonEncode({'user_id': widget.user_id});
      print('body: $body');
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          currentDirectory = decodedResponse['current_directory'];
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<List<String>> _getDirectoryContent() async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/listDirectory');
    try {
      var body = jsonEncode({'user_id': widget.user_id});
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        print(
            'response: $responseBody'); // response: {files: [test.txt, test2.txt]}
        List<String> fileList = [];
        for (var file in responseBody['files']) {
          fileList.add(file);
        }
        print('fileList: $fileList');
        return fileList;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return [];
      }
    } catch (e) {
      print('Request failed with error: $e.');
      return [];
    }
  }

  Future<void> changeDirectory(String directoryName) async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/changeDirectory');
    try {
      // Convert the body to JSON
      var body = jsonEncode({
        'name': directoryName.split("dir").first,
        'user_id': widget.user_id
      });

      // Set the headers to specify that the request contains JSON data
      var headers = {'Content-Type': 'application/json'};

      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var resp = jsonDecode(response.body);
        resp = resp['current_directory'];
        setState(() {
          currentDirectory = resp;
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
        if (jsonDecode(response.body)['message'] ==
            'Already in root directory') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Already in root directory'),
            ),
          );
        }
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<void> createDirectory(String dirName) async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/createDirectory');
    var body = jsonEncode({'name': dirName, 'user_id': widget.user_id});
    var headers = {'Content-Type': 'application/json'};
    try {
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          currentDirectory = decodedResponse['current_directory'];
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<void> _logout() async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/logout');
    try {
      var body = jsonEncode({'user_id': widget.user_id});
      print('body: $body');
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<void> downloadFile(String fileName) async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/downloadFile');

    try {
      // Prepare the request body as JSON
      var body = jsonEncode({'name': fileName, 'user_id': widget.user_id});

      // Send a POST request to the Flask server with JSON content type
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        print('download directory: $downloadPath');
        var file = File('$downloadPath/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName saved successfully'),
          ),
        );

        print('File saved successfully');
      } else {
        // Handle the case where the request was not successful
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occurred during the request
      print('Request failed with error: $e');
    }
  }

  Future<void> _uploadFile() async {
    var ip = dotenv.env['API_URL'];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      withReadStream: true,
    );
    if (result != null) {
      var url = Uri.parse('$ip/uploadFile');

      try {
        var request = http.MultipartRequest('POST', url);

        // Add user_id field to the request
        request.fields['user_id'] = widget.user_id;

        // Add the picked file to the request
        var pickedFile = result.files.single;
        if (pickedFile.readStream != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            pickedFile.path!,
          ));

          var response = await request.send();

          if (response.statusCode == 200) {
            // Handle successful response
            setState(() {
              // Update UI if needed
              currentDirectory = currentDirectory;
            });
          } else {
            print('Request failed with status: ${response.statusCode}.');
          }
        } else {
          print('File read stream is null.');
        }
      } catch (e) {
        print('Request failed with error: $e.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          (addOperation)
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    backgroundColor: Colors.grey[300],
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Create Directory'),
                              content: TextField(
                                onSubmitted: (value) {
                                  createDirectory(value);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          });
                    },
                    child: const Icon(Icons.folder),
                  ),
                )
              : const SizedBox(),
          if (addOperation)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                backgroundColor: Colors.grey[300],
                onPressed: () async {
                  _uploadFile();
                },
                child: const Icon(Icons.file_present),
              ),
            )
          else
            const SizedBox(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  addOperation = !addOperation;
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            _logout();
          },
        ),
        title: const Text("File Manager"),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Current Directory: $currentDirectory'),
                ),
              ),
              InkWell(
                onTap: () {
                  changeDirectory('..');
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  height: 75,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                      Text('Parent Directory')
                    ],
                  ),
                ),
              ),
              FutureBuilder(
                future: _getDirectoryContent(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('An error occurred'),
                      );
                    } else {
                      return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                if (snapshot.data![index].contains('.')) {
                                  downloadFile(snapshot.data![index]);
                                } else {
                                  changeDirectory(snapshot.data![index]);
                                }
                              },
                              onLongPress: () {
                                // show alert dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: const Text(
                                          'Do you want this file or directory?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            if (snapshot.data![index]
                                                .contains('dir')) {
                                              deleteDirectory(
                                                  snapshot.data![index]);
                                            } else {
                                              deleteFile(snapshot.data![index]);
                                            }
                                            Navigator.of(context).pop();
                                            setState(() {
                                              currentDirectory = currentDirectory;
                                            });
                                          },
                                          child: const Text('Yes'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            changeDirectory(
                                                snapshot.data![index]);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('No'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                height: 75,
                                child: Row(
                                  children: [
                                    Icon(
                                      snapshot.data![index].contains("dir")
                                          ? Icons.folder
                                          : Icons.file_present,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          60,
                                      child: Text(
                                        snapshot.data![index].contains("dir")
                                            ? snapshot.data![index]
                                                .split("dir")
                                                .first
                                            : snapshot.data![index],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
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
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteDirectory(String s) async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/deleteDirectory');
    try {
      var body =
          jsonEncode({'name': s.split("dir").first, 'user_id': widget.user_id});
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          currentDirectory = decodedResponse['current_directory'];
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }

  Future<void> deleteFile(String s) async {
    var ip = dotenv.env['API_URL'];
    var url = Uri.parse('$ip/deleteFile');
    try {
      var body = jsonEncode({'name': s, 'user_id': widget.user_id});
      var response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          currentDirectory = decodedResponse['current_directory'];
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Request failed with error: $e.');
    }
  }
}

class FileClass {
  final String name;
  final String type;
  final int size;
  final DateTime modified_time;

  FileClass(
      {required this.name,
      required this.type,
      required this.size,
      required this.modified_time});

  factory FileClass.fromJson(Map<String, dynamic> json) {
    return FileClass(
      name: json['name'],
      type: json['type'],
      size: json['size'],
      modified_time: HttpDate.parse(json['modified_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'lastModified': modified_time.toIso8601String(),
    };
  }
}
