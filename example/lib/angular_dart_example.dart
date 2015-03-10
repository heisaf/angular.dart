import 'package:barback/barback.dart';
import 'dart:async';

const int _defaultGenerate = 2;

const _COMP_BINDING = '''
  module
    ..bind(Todo)
    ..bind(Todo2);
''';

String newTodoComponent(int i) => '''
@Component(
  selector: 'todo$i',
  useShadowDom: false,
  templateUrl: 'packages/angular_dart_example/todo/todo_component.html'
)
class Todo$i extends Todo {
  Todo$i(Server serverController) : super(serverController);
}
''';

String _newRoute(int i) => ''',
    'todo$i' : ngRoute(
      path : '/todo$i',
      viewHtml : '<todo$i comp-id="$i"></todo$i>'
    )
''';

String _newRoutingInitializer(buf) => '''
void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'default': ngRoute(
      defaultRoute: true,
      enter: (RouteEnterEvent e) {
        router.go('todo1', {});
      }
    ),
    'todo1' : ngRoute(
      path : '/todo1',
      viewHtml : '<todo1 comp-id="1"></todo1>'
    ),
    'todo2' : ngRoute(
      path : '/todo2',
      viewHtml : '<todo2 comp-id="2"></todo2>'
    )$buf
  });
}
''';

const _COMP_ROUTING = '''
void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'default': ngRoute(
      defaultRoute: true,
      enter: (RouteEnterEvent e) {
        router.go('todo1', {});
      }
    ),
    'todo1' : ngRoute(
      path : '/todo1',
      viewHtml : '<todo1 comp-id="1"></todo1>'
    ),
    'todo2' : ngRoute(
      path : '/todo2',
      viewHtml : '<todo2 comp-id="2"></todo2>'
    )
  });
}
''';

const _COMP_LIST_INIT = 'final List<int> items =  new List.generate(2, (i) => ++i);';

String _newListGenerator(int i) => 'final List<int> items =  new List.generate($i, (i) => ++i);';

class ExampleTransformerGroup implements TransformerGroup {

  final Iterable<Iterable> phases;

  static List<List<Transformer>> _createPhases(BarbackSettings settings) {
    int parsed = int.parse(settings.configuration['generate'], onError: (String source) => _defaultGenerate);
    var generate = parsed == null ? _defaultGenerate : parsed;

    return [
      [new TodoBindingGenerator(generate)],
      [new TodoCompGenerator(generate)]
    ];
  }

  ExampleTransformerGroup.asPlugin(BarbackSettings settings) :
    phases = _createPhases(settings);
}

class TodoCompGenerator implements Transformer {
  final int generate;
  TodoCompGenerator(this.generate);

  apply(Transform transform) {
    var id = transform.primaryInput.id;

    if (generate <= 2) {
      transform
        ..logger.info('nothing to generate', asset: id)
        ..addOutput(transform.primaryInput);
      return new Future.value(true);
    }

    return transform.readInputAsString(id).then((String content) {
      transform.logger.info('Generating $generate todo components', asset: id);
      var compDeclaration = new StringBuffer();
      for (var i = _defaultGenerate + 1; i <= generate; i++) {
        compDeclaration
          ..write('\n')
          ..write(newTodoComponent(i));
      }
      var transformed = content + compDeclaration.toString();
      transform.addOutput(new Asset.fromString(id, transformed));
    });
  }

  String get allowedExtensions => ".dart";

  Future<bool> isPrimary(AssetId id) => new Future.value(id.path.endsWith('comp2.dart'));
}

class TodoBindingGenerator implements Transformer {

  final int generate;
  TodoBindingGenerator(this.generate);

  apply(Transform transform) {
    var id = transform.primaryInput.id;

    if (generate <= 2) {
      transform
        ..logger.info('nothing to generate', asset: id)
        ..addOutput(transform.primaryInput);
      return new Future.value(true);
    }

    return transform.readInputAsString(id).then((String content) {
      transform.logger.info('Generating $generate todo bindings', asset: id);
      var compBinding = new StringBuffer(_COMP_BINDING.replaceAll(';\n', ''));
      var routes = new StringBuffer();

      for (var i = _defaultGenerate + 1; i <= generate; i++) {
        compBinding
          ..write('\n')
          ..write('    ..bind(Todo$i)');
        routes.write(_newRoute(i));
      }
      compBinding.writeln(';');

      var transformed = content
        .replaceAll(_COMP_BINDING, compBinding.toString())
        .replaceAll(_COMP_LIST_INIT, _newListGenerator(generate))
        .replaceAll(_COMP_ROUTING, _newRoutingInitializer(routes));
//      transform.logger.info('transformed\n$transformed', asset: id);
      transform.addOutput(new Asset.fromString(id, transformed));
    });
  }

  String get allowedExtensions => ".dart";

  Future<bool> isPrimary(AssetId id) => new Future.value(id.path.endsWith('todo.dart'));
}

