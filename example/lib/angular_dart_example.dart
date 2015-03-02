import 'package:barback/barback.dart';
import 'dart:async';

String _newListItem(int i) => '<li><a href="todo$i.html">todo$i.html</a></li>';
String _newTodoLib(int i) => '''
library todo$i;
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular/playback/playback_http.dart';
import 'todo.dart';

main() {
  print(window.location.search);
  var module = new Module()..bind(PlaybackHttpBackendConfig);

  // If these is a query in the URL, use the server-backed
  // TodoController.  Otherwise, use the stored-data controller.
  var query = window.location.search;
  module.bind(Server, toImplementation: NoOpServer);

  applicationFactory()
      .addModule(module)
      .rootContextType(Todo)
      .run();
}
''';

const int _defaultGenerate = 10;

class TodoGenerator implements Transformer {

   int generate;

  TodoGenerator.asPlugin(BarbackSettings settings) {
    int parsed = int.parse(settings.configuration['generate'], onError: (String source) => _defaultGenerate);
    generate = parsed == null ? _defaultGenerate : parsed;
  }

  apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.readInputAsString(id).then((String content) {
      var buf = new StringBuffer();
      for (var i = 1; i <= generate; i++) {
        buf
          ..write('\n')
          ..write(_newListItem(i));
      }

      var todoHtmlId = new AssetId(id.package, 'web/todo.html');
      return transform.readInputAsString(todoHtmlId).then((todoHtml) {
        transform.logger.info('Generating $generate todo views', asset: id);
        for (var i = 1; i <= generate; i++) {
          var newTodoHtmlId = new AssetId(id.package, 'web/todo$i.html');
          transform
            ..logger.info(' -> $newTodoHtmlId')
            ..addOutput(new Asset.fromString(new AssetId(id.package, 'web/todo$i.dart'), _newTodoLib(i)))
            ..addOutput(new Asset.fromString(newTodoHtmlId, todoHtml.replaceAll('todo.dart', 'todo$i.dart')));
        }
        var transformed = content.replaceFirst('</ul>', '$buf</ul>');
        transform.addOutput(new Asset.fromString(id, transformed));
      });

    });
  }

  String get allowedExtensions => ".html";

  Future<bool> isPrimary(AssetId id) => new Future.value(id.path.contains('index'));
}

