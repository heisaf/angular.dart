library todo_component;

import 'package:angular/angular.dart';

part 'comp2.dart';

class Item {
  String text;
  bool done;

  Item([this.text = '', this.done = false]);

  bool get isEmpty => text.isEmpty;

  Item clone() => new Item(text, done);

  void clear() {
    text = '';
    done = false;
  }
}


// ServerController interface. Logic in main.dart determines which
// implementation we should use.
abstract class Server {
  init(Todo todo);
}

@Component(
  selector: 'todo1',
  useShadowDom: false,
  templateUrl: 'packages/angular_dart_example/todo/todo_component.html'
  )
class Todo {
  var items = <Item>[];
  Item newItem;

  @NgAttr('comp-id')
  int compId;

  Todo(Server serverController) {
    newItem = new Item();
    items = [
      new Item('Write Angular in Dart', true),
      new Item('Write Dart in Angular'),
      new Item('Do something useful')
    ];

    serverController.init(this);
  }

  void add() {
    if (newItem.isEmpty) return;

    items.add(newItem.clone());
    newItem.clear();
  }

  void markAllDone() {
    items.forEach((item) => item.done = true);
  }

  void archiveDone() {
    items.removeWhere((item) => item.done);
  }

  String classFor(Item item) => item.done ? 'done' : '';

  int remaining() => items.fold(0, (count, item) => count += item.done ? 0 : 1);
}
