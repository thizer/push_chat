import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:push_chat/controller/user_controller.dart';
import 'package:push_chat/views/login_page.dart';

class ChatPage extends StatefulWidget {
  static String tag = '/chat';

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _newMsg = TextEditingController();

  Map<String, String> _replyTo;

  @override
  Widget build(BuildContext context) {
    var userController = UserController.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Push Chat App'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.remove_circle_outline),
            tooltip: 'Limpar conversa',
            onPressed: () async {
              // Captura todos os documentos
              var docs = await Firestore.instance.collection('chat').getDocuments();

              // Apaga todos os documentos
              docs.documents.forEach((doc) {
                doc.reference.delete();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await userController.signOut();

              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginPage.tag,
                (route) => route.isFirst,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection('chat').orderBy('data', descending: false).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Erro Inesperado: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              (snapshot.data.documents.length == 0)
                  ? Container(
                      width: double.infinity,
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        'Nenhuma mensagem ainda',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SizedBox.shrink(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (BuildContext context, int i) {
                    var item = snapshot.data.documents[i];

                    return Dismissible(
                      key: Key(item.documentID),
                      background: Container(
                        padding: const EdgeInsets.only(left: 40),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.reply),
                        ),
                      ),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        //
                        // Se o player id não for do proprio usuario
                        if (item.data['playerId'] != userController.playerId) {
                          setState(() {
                            _replyTo = {
                              'nome': item.data['nome'],
                              'playerId': item.data['playerId'],
                            };
                          });
                        } else {
                          setState(() {
                            _replyTo = null;
                          });
                        }

                        return false;
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                        padding: const EdgeInsets.fromLTRB(5, 5, 15, 15),
                        decoration: BoxDecoration(
                          color: userController.user.uid == item.data['uid'] ? Colors.deepPurple[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            userController.user.uid == item.data['uid']
                                ? SizedBox.shrink()
                                : ClipRRect(
                                    child: Image.network(
                                      item.data['foto'],
                                      height: 50,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: userController.user.uid == item.data['uid'] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.data['nome'],
                                    style: Theme.of(context).textTheme.subtitle2.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(item.data['mensagem']),
                                ],
                              ),
                            ),
                            SizedBox(width: 15),
                            userController.user.uid != item.data['uid']
                                ? SizedBox.shrink()
                                : ClipRRect(
                                    child: Image.network(
                                      item.data['foto'],
                                      height: 50,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.grey[200],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _replyTo == null
                        ? SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            color: Colors.grey[900],
                            child: Text(
                              'Para: ${_replyTo['nome']}',
                              style: Theme.of(context).textTheme.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _newMsg,
                            decoration: InputDecoration(
                              hintText: 'Sua mensagem...',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () async {
                            if (_newMsg.text.isNotEmpty) {
                              String mensagem = (_replyTo != null) ? '${_replyTo['nome']}, ${_newMsg.text}' : _newMsg.text;

                              Firestore.instance.collection('chat').add({
                                'uid': userController.user.uid,
                                'playerId': userController.playerId,
                                'replyToPlayerId': (_replyTo == null) ? null : _replyTo['playerId'],
                                'foto': userController.user.photoUrl,
                                'nome': userController.user.displayName,
                                'mensagem': mensagem,
                                'data': Timestamp.now(),
                              });

                              if (_replyTo != null) {
                                // Aqui é que sao de fato geradas as notificacoes
                                // pessoas, ou seja, aquelas que chegam apenas para
                                // um usuario especifico
                                await OneSignal.shared.postNotification(
                                  OSCreateNotification(
                                    playerIds: [_replyTo['playerId']],
                                    content: _newMsg.text,
                                    heading: "Nova mensagem de ${userController.user.displayName}",
                                    buttons: [
                                      OSActionButton(text: "Cancelar", id: "id1"),
                                      OSActionButton(text: "Responder", id: "id2"),
                                    ],
                                  ),
                                );

                                setState(() {
                                  _replyTo = null;
                                });
                              }

                              _newMsg.text = '';
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
