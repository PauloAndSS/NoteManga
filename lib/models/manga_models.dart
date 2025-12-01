import 'dart:convert';

/// Enum para as listas personalizadas do usuário
enum MangaListType {
  lendo,      // Lendo Atualmente
  queroLer,   // Quero Ler
  concluido,  // Concluído
  dropado,    // Dropado
  favoritos,  // Favoritos
}

/// Modelo para comentários
class Comment {
  final String id;
  final String author;
  final String content;
  final DateTime createdAt;
  final List<String> replies; // IDs de respostas

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'replies': replies,
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    author: json['author'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    replies: List<String>.from(json['replies'] as List? ?? []),
  );
}

/// Modelo para avaliação de mangá
class MangaRating {
  final double stars; // 1 a 5
  final String? review;
  final DateTime ratedAt;

  MangaRating({
    required this.stars,
    this.review,
    required this.ratedAt,
  });

  Map<String, dynamic> toJson() => {
    'stars': stars,
    'review': review,
    'ratedAt': ratedAt.toIso8601String(),
  };

  factory MangaRating.fromJson(Map<String, dynamic> json) => MangaRating(
    stars: (json['stars'] as num).toDouble(),
    review: json['review'] as String?,
    ratedAt: DateTime.parse(json['ratedAt'] as String),
  );
}

/// Modelo para checkpoint de progresso
class MangaCheckpoint {
  final int lastChapterRead;
  final String? lastChapterTitle;
  final DateTime lastReadAt;

  MangaCheckpoint({
    required this.lastChapterRead,
    this.lastChapterTitle,
    required this.lastReadAt,
  });

  Map<String, dynamic> toJson() => {
    'lastChapterRead': lastChapterRead,
    'lastChapterTitle': lastChapterTitle,
    'lastReadAt': lastReadAt.toIso8601String(),
  };

  factory MangaCheckpoint.fromJson(Map<String, dynamic> json) => MangaCheckpoint(
    lastChapterRead: json['lastChapterRead'] as int,
    lastChapterTitle: json['lastChapterTitle'] as String?,
    lastReadAt: DateTime.parse(json['lastReadAt'] as String),
  );
}

/// Modelo expandido de Mangá com funcionalidades de rastreamento
class MangaTracked {
  final String id;
  final String title;
  final String? description;
  final List<String> genres;
  final String? coverUrl;
  
  // Funcionalidades de rastreamento
  final MangaRating? rating;
  final List<Comment> comments;
  final MangaCheckpoint? checkpoint;
  final List<MangaListType> lists; // Listas em que o mangá está
  final bool isFavorite;
  final DateTime? addedAt;

  MangaTracked({
    required this.id,
    required this.title,
    this.description,
    required this.genres,
    this.coverUrl,
    this.rating,
    this.comments = const [],
    this.checkpoint,
    this.lists = const [],
    this.isFavorite = false,
    this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'genres': genres,
    'coverUrl': coverUrl,
    'rating': rating?.toJson(),
    'comments': comments.map((c) => c.toJson()).toList(),
    'checkpoint': checkpoint?.toJson(),
    'lists': lists.map((l) => l.name).toList(),
    'isFavorite': isFavorite,
    'addedAt': addedAt?.toIso8601String(),
  };

  factory MangaTracked.fromJson(Map<String, dynamic> json) => MangaTracked(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    genres: List<String>.from(json['genres'] as List? ?? []),
    coverUrl: json['coverUrl'] as String?,
    rating: json['rating'] != null 
        ? MangaRating.fromJson(json['rating'] as Map<String, dynamic>)
        : null,
    comments: (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList(),
    checkpoint: json['checkpoint'] != null
        ? MangaCheckpoint.fromJson(json['checkpoint'] as Map<String, dynamic>)
        : null,
    lists: (json['lists'] as List? ?? [])
        .map((l) => MangaListType.values.firstWhere(
          (e) => e.name == l,
          orElse: () => MangaListType.queroLer,
        ))
        .toList(),
    isFavorite: json['isFavorite'] as bool? ?? false,
    addedAt: json['addedAt'] != null 
        ? DateTime.parse(json['addedAt'] as String)
        : null,
  );

  /// Cria uma cópia com mudanças
  MangaTracked copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? genres,
    String? coverUrl,
    MangaRating? rating,
    List<Comment>? comments,
    MangaCheckpoint? checkpoint,
    List<MangaListType>? lists,
    bool? isFavorite,
    DateTime? addedAt,
  }) {
    return MangaTracked(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      comments: comments ?? this.comments,
      checkpoint: checkpoint ?? this.checkpoint,
      lists: lists ?? this.lists,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Modelo para capítulo
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
      id: json['id'],
      title: attrs['title'],
      chapterNumber: attrs['chapter']?.toString(),
    );
  }
}

/// Modelo para página de mangá
class MangaPage {
  final String url;
  MangaPage(this.url);
}

/// Modelo básico de Mangá (para API)
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

    // ----- GÊNEROS -----
    final tagsRaw =
        (attrs['tags'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    List<String> genres = tagsRaw
        .where((tag) => (tag['attributes']?['group'] == 'genre'))
        .map((tag) {
          final nameMap = tag['attributes']?['name'];
          return nameMap?['pt-br'] ??
              nameMap?['en'] ??
              (nameMap != null && nameMap.isNotEmpty
                  ? nameMap.values.first
                  : null);
        })
        .whereType<String>()
        .toList();

    // ----- CAPA -----
    String? coverFileName;

    for (final rel in (json['relationships'] as List? ?? [])) {
      if (rel['type'] == 'cover_art') {
        coverFileName = rel['attributes']?['fileName'];
      }
    }

    final coverUrl = coverFileName != null
        ? "https://uploads.mangadex.org/covers/$id/$coverFileName"
        : null;

    return Manga(
      id: id,
      title: dynamicTitle.toString(),
      description: dynamicDescription?.toString(),
      genres: genres,
      coverUrl: coverUrl,
    );
  }

  /// Converte Manga para MangaTracked
  MangaTracked toTracked() {
    return MangaTracked(
      id: id,
      title: title,
      description: description,
      genres: genres,
      coverUrl: coverUrl,
      addedAt: DateTime.now(),
    );
  }
}
