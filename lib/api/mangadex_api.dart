import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_models.dart';

class MangaDexApi {
  static const String _baseUrl = "https://api.mangadex.org";

  // =========================================================
  // 🔍 1. PESQUISA
  // =========================================================
  Future<List<Manga>> searchManga(String query) async {
    final uri = Uri.parse(
      "$_baseUrl/manga?title=$query&limit=20&includes[]=cover_art&contentRating[]=safe",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar mangás");
    }

    final data = jsonDecode(response.body)["data"] as List<dynamic>? ?? [];
    return data.map((e) => Manga.fromJson(e)).toList();
  }

  // =========================================================
  // ⭐ 2. MANGÁS EM DESTAQUE (POPULARES)
  // =========================================================
  Future<List<Manga>> getPopularManga() async {
    final uri = Uri.parse(
      "$_baseUrl/manga?limit=20&includes[]=cover_art&order[followedCount]=desc",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar destaques");
    }

    final data = jsonDecode(response.body)["data"] as List<dynamic>? ?? [];
    return data.map((e) => Manga.fromJson(e)).toList();
  }

  // =========================================================
  // 🎭 3. BUSCAR POR GÊNERO
  // =========================================================
  Future<List<Manga>> getMangaByGenre(String genreId) async {
    final uri = Uri.parse(
      "$_baseUrl/manga?limit=20&includes[]=cover_art&includedTags[]=$genreId&includedTagsMode=OR",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar mangás por gênero");
    }

    final data = jsonDecode(response.body)["data"] as List<dynamic>? ?? [];
    return data.map((e) => Manga.fromJson(e)).toList();
  }

  // =========================================================
  // 📄 4. CAPÍTULOS
  // =========================================================
  Future<List<MangaChapter>> getChapters(String mangaId) async {
    final uri = Uri.parse(
      "$_baseUrl/chapter?manga=$mangaId&limit=100&translatedLanguage[]=pt-br&translatedLanguage[]=en",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar capítulos");
    }

    final data = jsonDecode(response.body)["data"] as List<dynamic>? ?? [];

    final chapters = data.map((e) => MangaChapter.fromJson(e)).toList();

    chapters.sort((a, b) {
      final ca = double.tryParse(a.chapterNumber ?? "");
      final cb = double.tryParse(b.chapterNumber ?? "");
      if (ca == null || cb == null) return 0;
      return ca.compareTo(cb);
    });

    return chapters;
  }

  // =========================================================
  // 🖼 5. PÁGINAS
  // =========================================================
  Future<List<MangaPage>> getPages(String chapterId) async {
    final uri = Uri.parse("$_baseUrl/at-home/server/$chapterId");

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar páginas");
    }

    final body = jsonDecode(response.body);

    final baseUrl = body["baseUrl"];
    final chapter = body["chapter"];
    final hash = chapter["hash"];

    final data = chapter["data"] as List<dynamic>;

    return data
        .map((file) => MangaPage("$baseUrl/data/$hash/$file"))
        .toList();
  }

  // =========================================================
  // 📚 6. LISTA DE GÊNEROS DISPONÍVEIS
  // =========================================================
  Future<Map<String, String>> getAvailableGenres() async {
    final uri = Uri.parse("$_baseUrl/manga/tag");

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Erro ao carregar gêneros");
    }

    final data = jsonDecode(response.body)["data"] as List<dynamic>;

    final genres = <String, String>{};

    for (final tag in data) {
      if (tag["attributes"]["group"] == "genre") {
        genres[tag["id"]] =
            tag["attributes"]["name"]["pt-br"] ??
            tag["attributes"]["name"]["en"] ??
            "Desconhecido";
      }
    }

    return genres;
  }
}
