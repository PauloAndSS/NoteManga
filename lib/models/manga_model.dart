import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo de Manga com os campos da API + campos locais
class Manga {
  final String id;
  final String title;
  final String? description;
  final List<String> genres;
  final String? coverUrl;

  // Campos locais (para lógica do app)
  String status;          // "ler", "lendo", "lido", "Nenhum"
  bool isFavorito;        // true/false
  String? capituloAtual;  // capítulo atual quando status = "lendo"

  Manga({
    required this.id,
    required this.title,
    this.description,
    required this.genres,
    this.coverUrl,
    this.status = "Nenhum",      // padrão inicial
    this.isFavorito = false,     // padrão inicial
    this.capituloAtual,          // começa vazio
  }) {
    // Se o status for Nenhum, adiciona na listaTodos
    if (status == "Nenhum") {
      listaTodos.add(this);
    }
  }

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

    // ----- GÊNEROS -----
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

    // ----- CAPA -----
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
        ? 'https://uploads.mangadex.org/covers/$id/$coverFileName.512.jpg'
        : null;

    // Aqui criamos o Manga com status "Nenhum"
    return Manga(
      id: id,
      title: dynamicTitle.toString(),
      description: dynamicDescription?.toString(),
      genres: genres,
      coverUrl: coverUrl,
      status: "Nenhum", // sempre começa sem status
      isFavorito: false,
      capituloAtual: null,
    );
  }

  String get desc => description ?? '';
}

/// Modelo simples de Capítulo
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

/// Serviço para chamar a API da MangaDex
class MangaDexApi {
  static const String _baseUrl = 'https://api.mangadex.org';

  /// Busca mangás pelo título
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

  /// Lista capítulos de um mangá
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

/// Listas locais para organização
List<Manga> listaTodos = [];
List<Manga> listaLer = [];
List<Manga> listaLendo = [];
List<Manga> listaLido = [];
List<Manga> listaFavoritos = [];

void atualizarListas(Manga manga) {
  // Remove de todas as listas
  listaTodos.remove(manga);
  listaLer.remove(manga);
  listaLendo.remove(manga);
  listaLido.remove(manga);
  listaFavoritos.remove(manga);

  // Adiciona na lista correta
  switch (manga.status) {
    case "ler":
      listaLer.add(manga);
      break;
    case "lendo":
      listaLendo.add(manga);
      break;
    case "lido":
      listaLido.add(manga);
      break;
    case "Nenhum":
      listaTodos.add(manga);
      break;
  }

  // Adiciona na lista de favoritos se for o caso
  if (manga.isFavorito) {
    listaFavoritos.add(manga);
  }
}
