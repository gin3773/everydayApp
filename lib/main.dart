import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everyday/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'wordclass.dart';
import 'dart:math';
import 'auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flushbar/flushbar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: CheckUserClass());
  }
}

class ListPage extends StatefulWidget {
  final FirebaseUser user;
  ListPage(this.user);
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<NewWord>>.value(
      value: DatabaseService(
        widget.user,
      ).userWordsList,
      initialData: [],
      child: WordsList(widget.user),
    );
  }
}

class HomePage extends StatefulWidget {
  final FirebaseUser user;

  HomePage(this.user);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  NewWord startWord;
  CollectionReference savedPlace = Firestore.instance.collection('users');
  Future savedName;
  Future savedDef;
  Future savedExample;
  Future savedCuriosity;
  CollectionReference wordsRef = Firestore.instance.collection('all_words');

  NewWord takeAndSaveRandomWord() {
    print('The multi word is ${this.startWord.name}');
    DatabaseService(widget.user).saveWord(this.startWord);
    return this.startWord;
  }

  Future<NewWord> getAllWordsList() async {
    List<NewWord> allWords = [];
    await wordsRef.getDocuments().then((value) {
      value.documents.forEach((e) {
        NewWord word = new NewWord(e.data['name'], e.data['definition'],
            e.data['example'], e.data['curiosity']);
        allWords.add(word);
      });
    });
    return allWords[new Random().nextInt(allWords.length)];
  }

  getSavedWord() async {
    savedDef = DatabaseService(widget.user).getSavedDef();
    savedName = DatabaseService(widget.user).getSavedName();
    savedExample = DatabaseService(widget.user).getSavedExample();
    savedCuriosity = DatabaseService(widget.user).getSavedCuriosity();
  }

  @override
  void initState() {
    super.initState();
    getAllWordsList().then((value) => this.startWord = value);
    getSavedWord();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: Future.wait([savedName, savedDef, savedExample]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasData) {
              if (snapshot.data[0] != null && snapshot.data[1] != null) {
                return HomeWordCard(
                  snapshot.data[0],
                  snapshot.data[1],
                  widget.user.uid,
                  snapshot.data[2],
                );
              } else {
                return HomeWordCard(
                    takeAndSaveRandomWord().name,
                    takeAndSaveRandomWord().definition,
                    widget.user.uid,
                    takeAndSaveRandomWord().example,
                    takeAndSaveRandomWord().curiosity);
              }
            } else {
              return HomeWordCard(
                takeAndSaveRandomWord().name,
                takeAndSaveRandomWord().definition,
                widget.user.uid,
                takeAndSaveRandomWord().example,
                takeAndSaveRandomWord().curiosity,
              );
            }
          }
        });
  }
}

class DetailedWord extends StatefulWidget {
  final NewWord word;
  final FirebaseUser user;
  DetailedWord(this.word, this.user);
  @override
  _DetailedWordState createState() => _DetailedWordState();
}

class _DetailedWordState extends State<DetailedWord> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.black,
            centerTitle: true,
            title: Text(
              'Everyday',
              style: TextStyle(fontSize: 35, fontFamily: 'Lobster'),
            )),
        body: HomeWordCard(widget.word.name, widget.word.definition,
            widget.user.uid, widget.word.example));
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Size size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        body: Center(
      child: Container(
          height: size.height,
          width: size.width,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 100,
                child: Text(
                  'Everyday',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Lobster', fontSize: 70, color: Colors.white),
                ),
              ),
              Positioned(bottom: 50, child: WelcomePageView()),
            ],
          )),
    ));
  }
}

class WordsList extends StatefulWidget {
  final FirebaseUser user;
  WordsList(this.user);
  @override
  _WordsListState createState() => _WordsListState();
}

class _WordsListState extends State<WordsList> {
  @override
  Widget build(BuildContext context) {
    final wordsCards = Provider.of<List<NewWord>>(context);

    return ListView.builder(
      itemCount: wordsCards.length,
      itemBuilder: (context, index) {
        return WordTile(wordsCards[index], widget.user);
      },
    );
  }
}

class WordTile extends StatefulWidget {
  final NewWord word;
  final FirebaseUser user;
  WordTile(this.word, this.user);
  @override
  _WordTileState createState() => _WordTileState();
}

class _WordTileState extends State<WordTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: ListTile(
          contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 10),
          tileColor: Colors.black,
          title: Text('${widget.word.name}',
              style: TextStyle(
                  color: Colors.white, fontSize: 30, fontFamily: 'OpenSans')),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        DetailedWord(widget.word, widget.user)));
          },
        ),
      ),
    );
  }
}

class CheckUserClass extends StatefulWidget {
  @override
  _CheckUserClassState createState() => _CheckUserClassState();
}

class _CheckUserClassState extends State<CheckUserClass> {
  @override
  void initState() {
    super.initState();
    checkLogged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: Center(
            child: Image(
          image: AssetImage('assets/flutterLogo.jpg'),
          height: 200,
          width: 200,
        )));
  }

  void checkLogged() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    if (user != null) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => PagesMaster(user)),
          (Route<dynamic> route) => false);
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }
}

class PagesMaster extends StatefulWidget {
  final FirebaseUser user;
  PagesMaster(this.user);
  @override
  _PagesMasterState createState() => _PagesMasterState();
}

class _PagesMasterState extends State<PagesMaster> {
  PageController pgctrl = PageController(initialPage: 0);
  int _currentIndex = 0;
  String addingName;
  String addingDef;
  String addingExample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 6),
            color: Colors.black,
            shape: BoxShape.circle),
        child: FittedBox(
          child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.add,
                size: 45,
                color: Colors.black,
              ),
              onPressed: () {
                showDialog(context: context, child: AddingDialog());
              }),
        ),
      ),
      appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.login,
              size: 40,
            ),
            onPressed: () {
              logOutfromGoogle();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginPage()));
            },
          ),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.error,
                  size: 40,
                ),
                onPressed: () async {
                  await launch(
                      "mailto:<apot5720@gmail.com>?subject=Problemi nell'app? Domande su alcune funzioni? Scrivile qui&body=");
                })
          ],
          backgroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            'Everyday',
            style: TextStyle(fontSize: 35, fontFamily: 'Lobster'),
          )),
      body: PageView(
        controller: pgctrl,
        onPageChanged: (page) {
          setState(() {
            _currentIndex = page;
          });
        },
        children: [
          SingleChildScrollView(child: HomePage(widget.user)),
          ListPage(widget.user),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 35,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        backgroundColor: Colors.black,
        currentIndex: _currentIndex,
        onTap: (int index) {
          _currentIndex = index;
          pgctrl.animateToPage(index,
              duration: Duration(milliseconds: 150), curve: Curves.linear);
          setState(() {});
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Archivio',
          ),
        ],
      ),
    );
  }
}

class HomeWordCard extends StatefulWidget {
  final String name;
  final String def;
  final String useruid;
  final String example;
  final String curiosity;
  HomeWordCard(this.name, this.def, this.useruid, this.example,
      [this.curiosity]);
  @override
  _HomeWordCardState createState() => _HomeWordCardState();
}

class _HomeWordCardState extends State<HomeWordCard> {
  bool isSaved = false;

  searchWord() async {
    String url = 'https://www.google.com/search?q=${widget.name}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not search for ${widget.name}';
    }
  }

  void showFlushbar(BuildContext context, String msg) {
    Flushbar(
      message: msg,
      duration: Duration(milliseconds: 1500),
      animationDuration: Duration(milliseconds: 100),
      margin: EdgeInsets.only(bottom: 60),
    )..show(context);
  }

  savedButtonFunc() {
    print(isSaved.toString());
    setState(() {
      isSaved = !isSaved;
    });
    if (isSaved) {
      showFlushbar(context, 'This word is saved');
      return Firestore.instance
          .collection('users')
          .document(widget.useruid)
          .setData({
        'name': '${widget.name}',
        'definition': '${widget.def}',
        'example': '${widget.example}'
      });
    } else {
      return Firestore.instance
          .collection('users')
          .document(widget.useruid)
          .updateData({
        'name': FieldValue.delete(),
        'definition': FieldValue.delete(),
        'example': FieldValue.delete()
      });
    }
  }

  showAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CuriosityDialog(widget.curiosity);
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Column(children: [
          SizedBox(height: 100),
          Text(widget.name,
              style: TextStyle(
                  fontSize: 50,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold)),
          Divider(
            color: Colors.black38,
          ),
          Text(
            widget.def,
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 25),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 30,
          ),
          Text(
            'Esempio',
            style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 25,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            widget.example,
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 25),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 50),
          Wrap(
            spacing: 20,
            children: [
              SavedIcon(savedButtonFunc, widget.useruid, widget.name),
              IconButton(
                  icon: Icon(
                    Icons.help,
                    color: Colors.black,
                    size: 40,
                  ),
                  onPressed: () {
                    showAlertDialog(context);
                  }),
              IconButton(
                  icon: Icon(
                    Icons.language,
                    size: 40,
                  ),
                  onPressed: () async {
                    searchWord();
                  })
            ],
          ),
        ]));
  }
}

class SavedIcon extends StatefulWidget {
  final Function savedButtonFunc;
  final String useruid;
  final String name;
  SavedIcon(this.savedButtonFunc, this.useruid, this.name);
  @override
  _SavedIconState createState() => _SavedIconState();
}

class _SavedIconState extends State<SavedIcon> {
  bool isSaved;
  String useruid;

  @override
  void initState() {
    super.initState();
    useruid = widget.useruid;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firestore.instance.collection('users').document(useruid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Icon(
              Icons.bookmark_border,
              color: Colors.black,
              size: 40,
            );
          } else {
            if (snapshot.data['name'] == widget.name) {
              return IconButton(
                  onPressed: widget.savedButtonFunc,
                  icon: Icon(
                    Icons.bookmark,
                    color: Colors.black,
                    size: 40,
                  ));
            } else {
              return IconButton(
                  onPressed: widget.savedButtonFunc,
                  icon: Icon(
                    Icons.bookmark_border,
                    color: Colors.black,
                    size: 40,
                  ));
            }
          }
        });
  }
}

class WelcomePageView extends StatefulWidget {
  @override
  _WelcomePageViewState createState() => _WelcomePageViewState();
}

class _WelcomePageViewState extends State<WelcomePageView> {
  PageController pgctrl = PageController(initialPage: 0);
  double currentIndex = 0.0;

  List<Widget> pageChildren = [
    WelcomSinglePage(
        Icon(
          Icons.format_underlined,
          color: Colors.white,
          size: 70,
        ),
        'Ogni volta una esperienza diversa: una parola nuova ad ogni accesso'),
    WelcomSinglePage(
        Icon(
          Icons.bookmark,
          color: Colors.white,
          size: 70,
        ),
        'Ti piace particolarmente una parola? Salvala, così la ritroverai al prossimo accesso'),
    WelcomSinglePage(
        Icon(
          Icons.help,
          color: Colors.white,
          size: 70,
        ),
        'Curiosità e aneddoti per ogni parola, così da scoprire di più sulla sua storia'),
    WelcomSinglePage(
        Icon(
          Icons.language,
          color: Colors.white,
          size: 70,
        ),
        "Vuoi saperne di più riguardo una parola? Cercala su internet con l'apposita opzione"),
    SignInButton(),
  ];

  List<Widget> indicator() => List<Widget>.generate(
      pageChildren.length,
      (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 3.0),
            height: currentIndex.round() == index ? 15 : 10,
            width: currentIndex.round() == index ? 15 : 10,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
          ));

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        // color: Colors.white,
        width: screenSize.width - 30,
        height: 550,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: pgctrl,
              itemCount: pageChildren.length,
              itemBuilder: (BuildContext context, int index) {
                pgctrl.addListener(() {
                  setState(() {
                    currentIndex = pgctrl.page;
                  });
                });
                return pageChildren[index];
              },
            ),
            Positioned(
              bottom: 0,
              child: Row(
                children: indicator(),
              ),
            )
          ],
        ));
  }
}

class WelcomSinglePage extends StatefulWidget {
  final Icon icon;
  final String text;
  WelcomSinglePage(this.icon, this.text);
  @override
  _WelcomSinglePageState createState() => _WelcomSinglePageState();
}

class _WelcomSinglePageState extends State<WelcomSinglePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 100, child: widget.icon),
        Positioned(
          bottom: 200,
          child: Container(
            width: 300,
            child: Text(
              '${widget.text}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'OpenSans',
                fontSize: 23,
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class SignInButton extends StatefulWidget {
  @override
  _SignInButtonState createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  FirebaseUser user;

  void click() {
    signInWithGoogle().then((user) {
      this.user = user;
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => PagesMaster(this.user)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
          top: 85,
          child: Image(
            image: AssetImage('assets/whiteGoogle.png'),
            height: 105,
            width: 105,
          ),
        ),
        Positioned(
          bottom: 220,
          child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: FlatButton(
                color: Colors.black,
                onPressed: () {
                  click();
                },
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: 2,
                  ),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                    color: Colors.white,
                    width: 1.0,
                  ))),
                  child: Text(
                    'Accedi da qui con Google per iniziare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'OpenSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )),
        ),
      ]),
    );
  }
}

class AddingDialog extends StatefulWidget {
  @override
  _AddingDialogState createState() => _AddingDialogState();
}

class _AddingDialogState extends State<AddingDialog> {
  String addingName;
  String addingDef;
  String addingExample;

  addWordFromPanel() async {
    if (addingName != null && addingDef != null && addingExample != null) {
      Firestore.instance.collection('all_words').document(addingName).setData({
        'name': addingName,
        'definition': addingDef,
        'example': addingExample
      });
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        margin: EdgeInsets.only(left: 15, right: 15),
        height: 400,
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Text(
              'Aggiungi le tue parole: appariranno insieme alle altre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'OpenSans',
                fontSize: 25,
              ),
            ),
            SizedBox(
              height: 25,
            ),
            TextField(
              cursorColor: Colors.black,
              style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 21,
                  fontStyle: FontStyle.italic),
              onChanged: (value) {
                setState(() {
                  addingName = value;
                });
              },
              decoration: InputDecoration(
                  hintText: 'Scrivi la parola',
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black87))),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
                cursorColor: Colors.black,
                style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 21,
                    fontStyle: FontStyle.italic),
                onChanged: (value) {
                  setState(() {
                    addingDef = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: 'Scrivi la definizione',
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87)))),
            SizedBox(
              height: 20,
            ),
            TextField(
                cursorColor: Colors.black,
                style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 21,
                    fontStyle: FontStyle.italic),
                onChanged: (value) {
                  setState(() {
                    addingExample = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: 'Scrivi un esempio',
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87)))),
            SizedBox(
              height: 25,
            ),
            Container(
              width: 320,
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10, top: 2),
                color: Colors.black,
                onPressed: () {
                  addWordFromPanel();
                },
                child: Text(
                  'Aggiungi',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontSize: 25),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CuriosityDialog extends StatefulWidget {
  final String curiosity;
  CuriosityDialog(this.curiosity);
  @override
  _CuriosityDialogState createState() => _CuriosityDialogState();
}

class _CuriosityDialogState extends State<CuriosityDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help),
          SizedBox(
            width: 10,
          ),
          Text(
            'Lo sapevi?',
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 38),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            thickness: 1,
            color: Colors.black,
          ),
          Text(
            widget.curiosity ?? 'Nessuna curiosità per questa parola...ancora',
            style: TextStyle(fontFamily: 'OpenSans', fontSize: 25),
          ),
        ],
      ),
    );
  }
}
