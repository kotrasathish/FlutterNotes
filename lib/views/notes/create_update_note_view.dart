import 'package:flutter/material.dart';
import 'package:mynotesflutter/services/auth/auth_service.dart';
import 'package:mynotesflutter/utilitis/dialogs/cannot_share_empty_dialog.dart';
import 'package:mynotesflutter/utilitis/generics/get_arguments.dart';
import 'package:mynotesflutter/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotesflutter/services/cloud/cloud_note.dart';
import 'package:share_plus/share_plus.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteView();
}

class _CreateUpdateNoteView extends State<CreateUpdateNoteView> {
  CloudNote? _notes;
  late final FirebaseCloudStorage _cloudStorage;
  late final TextEditingController _textEditingController;
  late Future<CloudNote> _notesFuture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _textEditingController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _notesFuture = createOrUpdateExstingNote(context);
    }
  }

  void _textControllerListener() async{
    final note = _notes;
    if(note==null){
      return;
    }
    final text = _textEditingController.text;
    await _cloudStorage.updateNote(
      documentId: note.documentId,
      text: text
    );
  }

  void _setupTextControllerListener(){
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<CloudNote> createOrUpdateExstingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();
    if(widgetNote!=null){
      _notes = widgetNote;
      _textEditingController.text = widgetNote.text;
      return widgetNote;
    }

    final currentuser = AuthService.firebase().currentUser!;
    final userId = currentuser.id!;
    final newnote = await _cloudStorage.createNewNote(ownerUserId: userId);
    _notes = newnote;
    return newnote;
  }

  void _deleteNoteIfTextIsEmpty(){
    final note = _notes;
    if(_textEditingController.text.isEmpty&& note!=null){
      _cloudStorage.deleteNote(documentId: note.documentId);
    }
  }
  void _saveNoteIfTextNotEmpty() async{
    final note = _notes;
    final text = _textEditingController.text;
    if(note!=null && text.isNotEmpty){
      await _cloudStorage.updateNote(
        documentId: note.documentId,
        text: text
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        title: const Text('New Note'),
        actions: [
          IconButton(
            onPressed:() async{
              final text = _textEditingController.text;
              if(_notes==null && text.isEmpty){
                await showCannotShareEmptyNoteDialog(context);
              }else{
               Share.share(text);
              }
            },
            icon: const Icon(Icons.share),
          )
        ],
        ),
        body: FutureBuilder<CloudNote>(
          future: _notesFuture,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {

              case ConnectionState.done:
              if(snapshot.hasError){
                return Center(child: Text('Error:${snapshot.error}'),);
              }
              _notes = snapshot.data;
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing Your text here....',
                ),
              );
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
    );
  }
}