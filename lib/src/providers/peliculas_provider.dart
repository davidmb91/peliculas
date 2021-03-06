import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:peliculas/src/models/actores_model.dart';
import 'package:peliculas/src/models/pelicula_model.dart';

class PeliculasProvider {
  String _apiKey = dotenv.env['APIKEY_MOVIEDB']!;
  String _url = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popularesPage = 0;
  bool _cargando = false;

  List<Pelicula> _populares = [];

  // Tunel stream
  final _popularesStreamController =
      StreamController<List<Pelicula>>.broadcast();

  // Entrada peliculas al stream
  Function(List<Pelicula>) get popularesSink =>
      _popularesStreamController.sink.add;

  // Salida peliculas stream
  Stream<List<Pelicula>> get popularesStream =>
      _popularesStreamController.stream;

  void disposeStrams() {
    _popularesStreamController.close();
  }

  Future<List<Pelicula>> _procesarRespuesta(Uri url) async {
    final respuesta = await http.get(url);
    final decodedData = json.decode(respuesta.body);
    final peliculas = new Peliculas.fromJsonList(decodedData['results']);

    return peliculas.items;
  }

  Future<List<Pelicula>> getEnCartelera() async {
    final url = Uri.https(_url, '3/movie/now_playing',
        {'api_key': _apiKey, 'language': _language});

    return await _procesarRespuesta(url);
  }

  Future<List<Pelicula>> buscarPelicula(String query) async {
    final url = Uri.https(_url, '3/search/movie',
        {
          'api_key': _apiKey,
          'language': _language,
          'query': query
        });

    return await _procesarRespuesta(url);
  }

  Future<List<Pelicula>> getPopulares() async {
    _popularesPage++;
    if (_cargando) {
      return [];
    }
    _cargando = true;

    final url = Uri.https(_url, '3/movie/popular', {
      'api_key': _apiKey,
      'language': _language,
      'page': _popularesPage.toString()
    });

    final resp = await _procesarRespuesta(url);
    _populares.addAll(resp);
    popularesSink(_populares); // Se manda lista peliculas al stream
    _cargando = false;

    return resp;
  }

  Future<List<Actor>> getCast(String idMovie) async {
    final url = Uri.https(_url, '3/movie/$idMovie/credits', {
      'api_key': _apiKey,
      'language': _language,
    });

    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final cast = new Cast.fromJsonList(decodedData['cast']);

    return cast.actores;
  }
}
