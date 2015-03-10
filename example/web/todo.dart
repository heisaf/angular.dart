library todo;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular/playback/playback_http.dart';
import 'package:angular_dart_example/todo/todo_component.dart';

// An implementation of ServerController that does nothing.
@Injectable()
class NoOpServer implements Server {
  init(Todo todo) { }
}


// An implementation of ServerController that fetches items from
// the server over HTTP.
@Injectable()
class HttpServer implements Server {
  final Http _http;
  HttpServer(this._http);

  init(Todo todo) {
    _http(method: 'GET', url: '/todos').then((HttpResponse data) {
      data.data.forEach((d) {
        todo.items.add(new Item(d["text"], d["done"]));
      });
    });
  }
}

@Injectable()
class TodoComponentList {
  final List<int> items =  new List.generate(2, (i) => ++i);
  final Router _router;

  TodoComponentList(this._router);

  void route(i) {
    _router.go('todo$i', {});
  }
}

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

main() {
  print(window.location.search);
  var module = new Module()
    ..bind(PlaybackHttpBackendConfig);

  // If these is a query in the URL, use the server-backed
  // TodoController.  Otherwise, use the stored-data controller.
  var query = window.location.search;
  module.bind(Server, toImplementation: query.contains('?') ? HttpServer : NoOpServer);

  if (query == '?record') {
    print('Using recording HttpBackend');
    var wrapper = new HttpBackendWrapper(new HttpBackend());
    module.bind(HttpBackendWrapper, toValue: new HttpBackendWrapper(new HttpBackend()));
    module.bind(HttpBackend, toImplementation: RecordingHttpBackend);
  }

  if (query == '?playback') {
    print('Using playback HttpBackend');
    module.bind(HttpBackend, toImplementation: PlaybackHttpBackend);
  }

  // bind the router
  module.bind(RouteInitializerFn, toValue: routeInitializer);

  // bind the TodoComponents (the TodoGenerator replaces this line)
  module
    ..bind(Todo)
    ..bind(Todo2);

  applicationFactory()
      .addModule(module)
      .rootContextType(TodoComponentList)
      .run();
}
