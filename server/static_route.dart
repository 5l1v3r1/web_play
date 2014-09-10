part of web_play_server;

class StaticFileRoute extends PathRoute {
  final String localPath;
  final String mimeType;
  
  StaticFileRoute(String path, String method, bool caseSensitive,
                  this.localPath, this.mimeType) :
                  super(path, method, caseSensitive);
  
  Future<bool> handle(RouteRequest _req) {
    HttpResponse response = _req.request.response;
    Stream<List<int>> stream = new File(localPath).openRead();
    response.headers.contentType = mimeType;
    return stream.pipe(response);
  }
}
