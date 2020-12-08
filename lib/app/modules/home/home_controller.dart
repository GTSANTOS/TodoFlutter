import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/app/models/todo_model.dart';
import 'package:todo_list/app/repositories/todos_repository.dart';
import 'package:collection/collection.dart';

class HomeController extends ChangeNotifier {
  final TodosRepository repository;
  int selectedTab = 1;
  DateTime daySeleted;
  DateTime startFilter;
  DateTime endFilter;
  var dateFormat = DateFormat('dd/MM/yyyy');
  Map<String, List<TodoModel>> listTodos;

  HomeController({@required this.repository}) {
    //repository.saveTodo(DateTime.now(), 'Teste 1');
    findAllForWeek();
  }

  changeSelectedTab(BuildContext context, int index) async {
    selectedTab = index;
    switch (index) {
      case 0:
        filterFinalized();
        break;
      case 1:
        findAllForWeek();
        break;
      case 2:
        var day = await showDatePicker(
          context: context,
          initialDate: daySeleted,
          firstDate: DateTime.now().subtract(Duration(days: (360 * 3))),
          lastDate: DateTime.now().add(Duration(days: (360 * 10))),
        );
        if (day != null) {
          daySeleted = day;
          findTodosBySelectedDay();
        }

        break;
      default:
    }
    notifyListeners();
  }

  Future<void> findAllForWeek() async {
    daySeleted = DateTime.now();
    startFilter = DateTime.now();

    if (startFilter.weekday != DateTime.monday) {
      startFilter =
          startFilter.subtract(Duration(days: (startFilter.weekday - 1)));
    }

    endFilter = startFilter.add(Duration(days: 6));

    var todos = await repository.findByPeriod(startFilter, endFilter);

    if (todos.isEmpty) {
      listTodos = {dateFormat.format(DateTime.now()): []};
    } else {
      listTodos =
          groupBy(todos, (TodoModel todo) => dateFormat.format(todo.dataHora));
    }
    this.notifyListeners();
  }

  void checkedOrUncheck(TodoModel todo) {
    todo.finalizado = !todo.finalizado;
    this.notifyListeners();
    repository.checkOrUncheckTodo(todo);
  }

  void filterFinalized() {
    listTodos = listTodos.map((key, value) {
      var todosFinalizados =
          value.where((element) => element.finalizado).toList();
      return MapEntry(key, todosFinalizados);
    });
    this.notifyListeners();
  }

  Future<void> findTodosBySelectedDay() async {
    var todos = await repository.findByPeriod(daySeleted, daySeleted);
    if (todos.isEmpty) {
      listTodos = {dateFormat.format(daySeleted): []};
    } else {
      listTodos =
          groupBy(todos, (TodoModel todo) => dateFormat.format(todo.dataHora));
    }
    this.notifyListeners();
  }

  void update() {
    if (selectedTab == 1) {
      this.findAllForWeek();
    } else if (selectedTab == 2) {
      this.findTodosBySelectedDay();
    }
  }

  void deleteTodo(TodoModel todo) {
    repository.deletebyId(todo.id);
    this.update();
  }
}
