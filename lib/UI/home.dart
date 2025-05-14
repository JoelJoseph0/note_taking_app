import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_app/service/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {

  final Function(bool) onThemeChange;



  // const Home({super.key});
  
  Home({super.key, required this.onThemeChange});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool _isDarkMode = false;

  Future<void> _loadThemePreferences() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = pref.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool value){
    setState(() {
      _isDarkMode = value;
      widget.onThemeChange(_isDarkMode);
    });
  }

List<Map<String,dynamic>> _allNotes = [];
bool _isLoadingNote = true;

final TextEditingController _noteTitleController = TextEditingController();
final TextEditingController _noteDescriptionController = TextEditingController();


void _realodNotes() async{
  final note = await QueryHelper.getAllNotes();
  setState(() {
    _allNotes = note;
    _isLoadingNote = false;
  });
}

Future<void> _addNote() async{
  await QueryHelper.createNote(_noteTitleController.text, _noteDescriptionController.text);
  _realodNotes();
}

Future<void> _updateNote(int id)async{
  await QueryHelper.updateNote(id, _noteTitleController.text, _noteDescriptionController.text);
}

void _deleteNote(int id) async{
  await QueryHelper.deleteNote(id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(
      "Note has been deleted!"
    ))
  );

  _realodNotes();
}


void _deleteAllNNotes() async{
  final noteCount = await QueryHelper.getNoteCount();
  if(noteCount>0){
    await QueryHelper.deleteAllNotes();
    _realodNotes();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All Notes have been deleted')));
  }else{
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No Notes to delete')));
  }
}

@override
  void initState() {
    super.initState();
    _realodNotes();
    _loadThemePreferences();
  }

void showBottomSheetContent(int? id) async{

  if(id != null){
    final currentNote = _allNotes.firstWhere((element) => element['id'] == id);
    _noteTitleController.text = currentNote['title'];
    _noteDescriptionController.text = currentNote['decription'];
  }



  showModalBottomSheet(
    elevation: 1,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(
      top: Radius.circular(0)
    )),
    isScrollControlled: true,
    context: context, 
    builder: (_)=> SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                bottom: MediaQuery.of(context).viewInsets.bottom
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _noteTitleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Note Title"
                    ),
                  ),
        
                  SizedBox(height: 5,),
        
                  TextField(
                    controller: _noteDescriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "decription"
                    ),
                  ),
        
                  const SizedBox(height: 5,),
        
                  Center(
                    child: OutlinedButton(onPressed: () async {
                      
                      if(id== null){
                        await _addNote();
                      }
                      if(id != null){
                        await _updateNote(id);
                      }
                      _noteTitleController.text = "";
                      _noteDescriptionController.text = "";

                      Navigator.of(context).pop();

                    }, child: Text(
                      id == null ? "Add Note" : "Update Note"
                      ,style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w300
                    ),)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    )
    );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () async{
            _deleteAllNNotes();
          }, icon: Icon(Icons.delete_forever)),

          IconButton(onPressed: (){
            _appExit();
          }, icon: Icon(Icons.exit_to_app)),

          Transform.scale(
            scale: 0.7,
            child: Switch(value: _isDarkMode, onChanged: (value){
              _toggleTheme(value);
            }),
          )
        ],
        title: Text("Notes",style: TextStyle(
          fontFamily: 'IndieFlower',fontWeight: FontWeight.bold
        ),),
      ),
      body: SafeArea(
        child: _isLoadingNote ? 
        Center(
          child: CircularProgressIndicator()
        ) : ListView.builder(
          itemCount: _allNotes.length,
          itemBuilder: (context, index) =>
            Card(
              elevation: 5,
              margin: EdgeInsets.all(16),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(_allNotes[index]['title'],style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),),
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: (){
                          showBottomSheetContent(_allNotes[index]['id']);
                        }, icon: Icon(Icons.edit)),

                        IconButton(onPressed: (){
                          _deleteNote(_allNotes[index]['id']);
                        }, icon: Icon(Icons.delete))  
                      ],
                    ),
                  ],
                ),
                subtitle: Text(_allNotes[index]['decription'],style: TextStyle(
                  fontSize: 22
                ),),
              ),
            )
        )
      ),

      floatingActionButton: FloatingActionButton(onPressed: (){
        showBottomSheetContent(null);
      },
      child: const Icon(Icons.add),
      ),
    );
  }
  
  void _appExit() {
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Exit app"),
        content: Text("Are you sure you want to exit the app?"),
        actions: [
          OutlinedButton(onPressed: (){
            Navigator.of(context).pop();
          }, child: Text('Cancel')),


          OutlinedButton(onPressed: (){
            SystemNavigator.pop();
          }, child: Text('Exit')),
        ],
      );
    });
  }
}