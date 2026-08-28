import 'dart:convert';
import 'dart:io';

abstract interface class DatasetUpdateSource {
  Future<String> loadManifest();
  Future<Stream<List<int>>> download(Uri url);
}

final class HttpDatasetUpdateSource implements DatasetUpdateSource {
  HttpDatasetUpdateSource({HttpClient? client})
    : _client = client ?? HttpClient();

  static final manifestUri = Uri.parse(
    'https://github.com/lhm0/ladepark_explorer/releases/latest/download/manifest.json',
  );

  final HttpClient _client;

  @override
  Future<String> loadManifest() async {
    final response = await _get(manifestUri);
    if (response.contentLength > 1024 * 1024) {
      throw const FormatException('Dataset manifest is too large.');
    }
    return utf8.decoder.bind(response).join();
  }

  @override
  Future<Stream<List<int>>> download(Uri url) async => _get(url);

  Future<HttpClientResponse> _get(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Dataset server returned HTTP ${response.statusCode}.',
        uri: uri,
      );
    }
    return response;
  }
}
