import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import "dart:convert";

void main() => runApp(MaterialApp(
  home: Home(),
));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];
  final _toDoController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;
  
  // esta função corre sempre que inicializzamos o estado o widget
  @override
  void initState() {
    super.initState(); // herança

    // inicializa os dados existentes par a variavel _toDoList
    _readData().then((data){ // then, para estepara pelo future que retrna os dados
      setState(() {
        _toDoList = json.decode(data); // preenche a lista de todos
      });
    });
  }

  void _addToDo(){
    setState(() { // set state seve para fazer atualização dinamica apra que atualizae em reltime
      Map<String, dynamic> newToDo = Map(); // cria o mapa para a nova tarefa
      newToDo["title"] = _toDoController.text; // adiciona o titulo ao mapa criado
      _toDoController.text = ""; // reseta o input de texto
      newToDo['ok'] = false; // define que a tarefa não foi concluida pois foi criada agora mesmo
      _toDoList.add(newToDo); // adiciona a tarefa ao array de tarefas
      _saveData(); //
    });
  }



  Widget buildItem(BuildContext context, int index){
    return Dismissible( // Widget que permite arartar para a direita
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),// Qual é o item, a key tem de ser sempre diferente então criamos uma seed de datetime
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0), // Alinhar o filho
          child: Icon(Icons.delete, color: Colors.white), // icon da lixeira
        ),
      ),
      direction: DismissDirection.startToEnd, // faz com que seja possivel arrastar da esquerda para a direita

      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error)
        ),
        onChanged:(check){ //onchanged serve para
          setState((){ // Mudar estado em realtime
            _toDoList[index]['ok'] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){ // função chamada quando arrastada apra a direita
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]); // Duplica o item que estamos a remover, para caso seja preciso desfazer a acção
          _lastRemovedPos = index; // guarda a posição em que esta item estava
          _toDoList.removeAt(index); // remove o item da posição index

          _saveData(); // guardar a lista sem o item já

          // Sempre que apagarmos um item vai aparecer uma snackbar com o aviso do que foi removido e a posibilidade de cancelar a acção
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
                label: "desfazer",
                onPressed: (){
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved); // volta a inserir os dados que acabamos de eliminar usando o duplicado
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2), // tempo que o snackbar fica no ecra
          );
          
          Scaffold.of(context).showSnackBar(snack); // Mostra o nosso snack criado em cima
          
        });
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas / Compras"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[

          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[

                // Expanded serve para tentar maximizar a largura do elemento
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),

                RaisedButton(
                  color: Colors.blueAccent,
                  child:  Icon(
                        Icons.add,
                        color: Colors.white,
                    ),
                  onPressed: _addToDo,
                ),


              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator( // Serve para ao puxar para baixo ele fazer um refresh à lista
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem // Chama a função que constroi o widget
                ),
                onRefresh: _refresh, // executa a função Future _refresh()
            )
          ),

        ],
      ),
    );
  }

  // Get File
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();  //directorio
    return File("${directory.path}/data.json"); // retorna o arquivo
  }

  // guardar dados
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile(); // Aguarda que ao ficheiro seja carregado
    return file.writeAsString(data); // Escreve os dados dentro do ficheiro
  }

  Future<String> _readData() async {
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }

  Future<Null> _refresh() async{ // função para fazer a lista atualizar ao ser puxada para baixo, o async serve para não ser logo executada mas esperar por exemplo 1 seg, apenas ara dar uam impressão mais fluida
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      // Ordenação do dart
      _toDoList.sort((a, b){
        if(a["ok"] && !b['ok']) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });
    return null;
  }


}