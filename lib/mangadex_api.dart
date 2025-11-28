// lib/mangadex_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo de Manga com os campos que você quer usar:
/// - título
/// - descrição
/// - gêneros
/// - imagem (capa)
class Manga {
  final String id;
  final String title;
  final String? description;
  final List<String> genres;
  final String? coverUrl;

  Manga({
    required this.id,
    required this.title,
    this.description,
    required this.genres,
    this.coverUrl,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    final attrs = json['attributes'] as Map<String, dynamic>? ?? {};

    // ----- TÍTULO -----
    final titleMap = attrs['title'] as Map<String, dynamic>?;
    final dynamicTitle = titleMap?['pt-br'] ??
        titleMap?['en'] ??
        titleMap?['ja'] ??
        (titleMap != null && titleMap.isNotEmpty
            ? titleMap.values.first
            : 'Título desconhecido');

    // ----- DESCRIÇÃO -----
    final descMap = attrs['description'] as Map<String, dynamic>?;
    final dynamicDescription = descMap?['pt-br'] ??
        descMap?['en'] ??
        (descMap != null && descMap.isNotEmpty ? descMap.values.first : null);

    // ----- GÊNEROS (tags do grupo "genre") -----
    final tagsRaw =
        (attrs['tags'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    List<String> genres = tagsRaw
        .where((tag) {
          final attr = tag['attributes'] as Map<String, dynamic>?;
          return attr?['group'] == 'genre';
        })
        .map((tag) {
          final attr = tag['attributes'] as Map<String, dynamic>?;
          final nameMap = attr?['name'] as Map<String, dynamic>?;
          return nameMap?['pt-br'] ??
              nameMap?['en'] ??
              (nameMap != null && nameMap.isNotEmpty
                  ? nameMap.values.first
                  : null);
        })
        .whereType<String>()
        .toList();

    // Se por algum motivo não vier "genre", pega todos os nomes de tags
    if (genres.isEmpty) {
      genres = tagsRaw
          .map((tag) {
            final attr = tag['attributes'] as Map<String, dynamic>?;
            final nameMap = attr?['name'] as Map<String, dynamic>?;
            return nameMap?['pt-br'] ??
                nameMap?['en'] ??
                (nameMap != null && nameMap.isNotEmpty
                    ? nameMap.values.first
                    : null);
          })
          .whereType<String>()
          .toList();
    }

    // ----- CAPA (imagem) -----
    final relationships =
        (json['relationships'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    String? coverFileName;
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art') {
        final coverAttrs = rel['attributes'] as Map<String, dynamic>?;
        coverFileName = coverAttrs?['fileName'] as String?;
        break;
      }
    }

    final coverUrl = coverFileName != null
        ? 'https://uploads..org/covers/$id/$coverFileName.512.jpg'
        : null;

    return Manga(
      id: id,
      title: dynamicTitle.toString(),
      description: dynamicDescription?.toString(),
      genres: genres,
      coverUrl: coverUrl,
    );
  }
}

/// Modelo simples de Capítulo (pode manter para depois, se quiser usar)
class MangaChapter {
  final String id;
  final String? title;
  final String? chapterNumber;

  MangaChapter({
    required this.id,
    this.title,
    this.chapterNumber,
  });

  factory MangaChapter.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? {};

    return MangaChapter(
      id: json['id'] as String,
      title: attrs['title'] as String?,
      chapterNumber: attrs['chapter']?.toString(),
    );
  }
}

/// Serviço simples para chamar a API da MangaDex
class MangaDexApi {
  static const String _baseUrl = 'https://api.mangadex.org';

  /// Busca mangás pelo título.
  ///
  /// Ex: searchManga('naruto')
  Future<List<Manga>> searchManga(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/manga?title=$query&limit=20&includes[]=cover_art&contentRating[]=safe',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar mangás (HTTP ${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] as List<dynamic>? ?? [];

    return data
        .map((item) => Manga.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lista capítulos de um mangá (opcional, pra usar depois).
  Future<List<MangaChapter>> getChapters(String mangaId) async {
    final uri = Uri.parse(
      '$_baseUrl/chapter?manga=$mangaId&limit=50&order[chapter]=asc',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar capítulos (HTTP ${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] as List<dynamic>? ?? [];

    return data
        .map((item) => MangaChapter.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
