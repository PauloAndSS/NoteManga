import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_models.dart';

class StorageService {
  static const String _mangasKey = 'tracked_mangas';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Salva um mangá rastreado
  Future<void> saveManga(MangaTracked manga) async {
    await _ensureInitialized();
    
    final mangas = await getAllMangas();
    final index = mangas.indexWhere((m) => m.id == manga.id);
    
    if (index >= 0) {
      mangas[index] = manga;
    } else {
      mangas.add(manga);
    }
    
    try {
      await _prefs.setString(
        _mangasKey,
        jsonEncode(mangas.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      print('Erro ao salvar mangá: $e');
      rethrow;
    }
  }

  /// Obtém todos os mangás rastreados
  Future<List<MangaTracked>> getAllMangas() async {
    await _ensureInitialized();
    
    final jsonString = _prefs.getString(_mangasKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((item) => MangaTracked.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao carregar mangás: $e');
      return [];
    }
  }

  /// Obtém um mangá específico por ID
  Future<MangaTracked?> getMangaById(String id) async {
    await _ensureInitialized();
    
    final mangas = await getAllMangas();
    try {
      return mangas.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtém mangás de uma lista específica
  Future<List<MangaTracked>> getMangasByList(MangaListType listType) async {
    await _ensureInitialized();
    
    final mangas = await getAllMangas();
    final filtered = mangas.where((m) => m.lists.contains(listType)).toList();
    
    // Ordena por data de adição (mais recentes primeiro)
    filtered.sort((a, b) => (b.addedAt ?? DateTime.now())
        .compareTo(a.addedAt ?? DateTime.now()));
    
    return filtered;
  }

  /// Adiciona um mangá a uma lista
  Future<void> addMangaToList(String mangaId, MangaListType listType) async {
    await _ensureInitialized();
    
    final manga = await getMangaById(mangaId);
    
    if (manga != null) {
      final lists = [...manga.lists];
      if (!lists.contains(listType)) {
        lists.add(listType);
      }
      
      final updated = manga.copyWith(
        lists: lists,
        // Se adicionou na lista de FAVORITOS, seta isFavorite também
        isFavorite: listType == MangaListType.favoritos
            ? true
            : manga.isFavorite,
        addedAt: manga.addedAt ?? DateTime.now(),
      );
      await saveManga(updated);
    }
  }

  /// Remove um mangá de uma lista
  Future<void> removeMangaFromList(String mangaId, MangaListType listType) async {
    await _ensureInitialized();
    
    final manga = await getMangaById(mangaId);
    
    if (manga != null) {
      final lists = manga.lists.where((l) => l != listType).toList();
      final updated = manga.copyWith(
        lists: lists,
        // Se removeu da lista FAVORITOS, desmarca o favorito
        isFavorite: listType == MangaListType.favoritos
            ? false
            : manga.isFavorite,
      );
      await saveManga(updated);
    }
  }

  /// Define a avaliação de um mangá
  Future<void> setMangaRating(String mangaId, double stars, String? review) async {
    await _ensureInitialized();
    
    var manga = await getMangaById(mangaId);
    
    if (manga == null) {
      // Se o mangá não existe, criar um novo
      manga = MangaTracked(
        id: mangaId,
        title: 'Mangá Desconhecido',
        genres: [],
      );
    }
    
    final rating = MangaRating(
      stars: stars.clamp(1, 5),
      review: review,
      ratedAt: DateTime.now(),
    );
    
    final updated = manga.copyWith(rating: rating);
    await saveManga(updated);
  }

  /// Adiciona um comentário a um mangá
  Future<void> addComment(String mangaId, String author, String content) async {
    await _ensureInitialized();
    
    var manga = await getMangaById(mangaId);
    
    if (manga == null) {
      // Se o mangá não existe, criar um novo
      manga = MangaTracked(
        id: mangaId,
        title: 'Mangá Desconhecido',
        genres: [],
      );
    }
    
    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      content: content,
      createdAt: DateTime.now(),
    );
    
    final comments = [...manga.comments, comment];
    final updated = manga.copyWith(comments: comments);
    await saveManga(updated);
  }

  /// Define o checkpoint de progresso
  Future<void> setCheckpoint(
    String mangaId,
    int chapterNumber,
    String? chapterTitle,
  ) async {
    await _ensureInitialized();
    
    var manga = await getMangaById(mangaId);
    
    if (manga == null) {
      // Se o mangá não existe, criar um novo
      manga = MangaTracked(
        id: mangaId,
        title: 'Mangá Desconhecido',
        genres: [],
      );
    }
    
    final checkpoint = MangaCheckpoint(
      lastChapterRead: chapterNumber,
      lastChapterTitle: chapterTitle,
      lastReadAt: DateTime.now(),
    );
    
    final updated = manga.copyWith(checkpoint: checkpoint);
    await saveManga(updated);
  }

  /// Marca um mangá como favorito
  Future<void> toggleFavorite(String mangaId) async {
    await _ensureInitialized();

    var manga = await getMangaById(mangaId);

    if (manga == null) {
      manga = MangaTracked(
        id: mangaId,
        title: 'Mangá Desconhecido',
        genres: const [],
      );
    }

    final bool newIsFavorite = !manga.isFavorite;
    final List<MangaListType> newLists = [...manga.lists];

    if (newIsFavorite) {
      if (!newLists.contains(MangaListType.favoritos)) {
        newLists.add(MangaListType.favoritos);
      }
    } else {
      newLists.removeWhere((l) => l == MangaListType.favoritos);
    }

    final updated = manga.copyWith(
      isFavorite: newIsFavorite,
      lists: newLists,
      addedAt: manga.addedAt ?? DateTime.now(),
    );

    await saveManga(updated);
  }

  /// Remove um mangá completamente
  Future<void> removeManga(String mangaId) async {
    await _ensureInitialized();
    
    final mangas = await getAllMangas();
    mangas.removeWhere((m) => m.id == mangaId);
    
    try {
      await _prefs.setString(
        _mangasKey,
        jsonEncode(mangas.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      print('Erro ao remover mangá: $e');
      rethrow;
    }
  }

  /// Limpa todos os dados
  Future<void> clearAll() async {
    await _ensureInitialized();
    
    try {
      await _prefs.remove(_mangasKey);
    } catch (e) {
      print('Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Obtém estatísticas de leitura
  Future<Map<String, int>> getReadingStats() async {
    await _ensureInitialized();
    
    final allMangas = await getAllMangas();
    
    return {
      'total': allMangas.length,
      'lendo': allMangas.where((m) => m.lists.contains(MangaListType.lendo)).length,
      'queroLer': allMangas.where((m) => m.lists.contains(MangaListType.queroLer)).length,
      'concluido': allMangas.where((m) => m.lists.contains(MangaListType.concluido)).length,
      'dropado': allMangas.where((m) => m.lists.contains(MangaListType.dropado)).length,
      'favoritos': allMangas.where((m) => m.lists.contains(MangaListType.favoritos)).length,
      'avaliados': allMangas.where((m) => m.rating != null).length,
    };
  }
}
