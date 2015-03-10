part of todo_component;

@Component(
  selector: 'todo2',
  useShadowDom: false,
  templateUrl: 'packages/angular_dart_example/todo/todo_component.html'
)
class Todo2 extends Todo {
  Todo2(Server serverController) : super(serverController);
}