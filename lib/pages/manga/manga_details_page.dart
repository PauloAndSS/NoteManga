import 'package:flutter/material.dart';
import '../../Api/mangadex_api.dart';
import '../../models/manga_models.dart';
import '../../services/storage_service.dart';
import 'manga_lists_page.dart';
import 'read/manga_reader_page.dart';

class MangaDetailsPage extends StatefulWidget {
  final Manga manga;
  final MangaTracked? trackedManga;

  const MangaDetailsPage({
    super.key,
    required this.manga,
    this.trackedManga,
  });

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  final MangaDexApi api = MangaDexApi();
  final StorageService storage = StorageService();

  late Future<List<MangaChapter>> _chaptersFuture;
  late MangaTracked currentTracked;
  late TextEditingController _commentController;
  late TextEditingController _authorController;

  double selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _authorController = TextEditingController();

    // valor inicial (sincrono) pra evitar LateInitializationError
    currentTracked = widget.trackedManga ?? widget.manga.toTracked();
    selectedRating = currentTracked.rating?.stars ?? 0;

    _initializeStorage();
    _chaptersFuture = api.getChapters(widget.manga.id);
  }

  Future<void> _initializeStorage() async {
    await storage.init();

    final saved = await storage.getMangaById(widget.manga.id);

    if (!mounted) return;

    if (saved != null) {
      // Já existia um registro completo no storage
      setState(() {
        currentTracked = saved;
        selectedRating = saved.rating?.stars ?? 0;
      });
    } else {
      // Salva o tracked atual (com título, capa, etc.)
      await storage.saveManga(currentTracked);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _saveRating(double rating) async {
    setState(() => selectedRating = rating);
    await storage.setMangaRating(widget.manga.id, rating, null);

    final updated = await storage.getMangaById(widget.manga.id);
    if (updated != null && mounted) {
      setState(() => currentTracked = updated);
    }
  }

  void _addComment() async {
    if (_commentController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha autor e comentário")),
      );
      return;
    }

    await storage.addComment(
      widget.manga.id,
      _authorController.text,
      _commentController.text,
    );

    _commentController.clear();
    _authorController.clear();

    final updated = await storage.getMangaById(widget.manga.id);
    if (updated != null && mounted) {
      setState(() => currentTracked = updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comentário adicionado!")),
      );
    }
  }

  void _setCheckpoint(int chapterNum, String? title) async {
    await storage.setCheckpoint(widget.manga.id, chapterNum, title);

    final updated = await storage.getMangaById(widget.manga.id);
    if (updated != null && mounted) {
      setState(() => currentTracked = updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capítulo $chapterNum marcado como lido!")),
      );
    }
  }

  void _toggleFavorite() async {
    await storage.toggleFavorite(widget.manga.id);

    final updated = await storage.getMangaById(widget.manga.id);
    if (updated != null && mounted) {
      setState(() => currentTracked = updated);
    }
  }

  void _toggleList(MangaListType listType) async {
    if (currentTracked.lists.contains(listType)) {
      await storage.removeMangaFromList(widget.manga.id, listType);
    } else {
      await storage.addMangaToList(widget.manga.id, listType);
    }

    final updated = await storage.getMangaById(widget.manga.id);
    if (updated != null && mounted) {
      setState(() => currentTracked = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 900;

    return Scaffold(
      // HEADER com gradiente + logo (igual Home)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8B4A5C),
                Color(0xFF3A3A3A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 8),
                Image.asset(
                  'assets/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      "MangaTracker",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MangaListsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, "/search");
                },
              ),
            ],
          ),
        ),
      ),

      // BODY com gradiente estilo Netflix
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF151515),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BLOCO PRINCIPAL (poster + infos)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: isWide
                        ? _buildWideHeaderSection(manga)
                        : _buildCompactHeaderSection(manga),
                  ),

                  const SizedBox(height: 20),

                  // Minhas listas
                  _buildListsSection(),

                  const SizedBox(height: 24),

                  // Comentários
                  _buildCommentsSection(),

                  const SizedBox(height: 24),

                  // Capítulos
                  _buildChaptersSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =======================
  // HEADER – LAYOUT WIDE
  // =======================
  Widget _buildWideHeaderSection(Manga manga) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POSTER
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: manga.coverUrl != null
              ? Image.network(
                  manga.coverUrl!,
                  height: 320,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 320,
                      width: 220,
                      color: Colors.grey.shade700,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                      ),
                    );
                  },
                )
              : Container(
                  height: 320,
                  width: 220,
                  color: Colors.grey.shade700,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                  ),
                ),
        ),

        const SizedBox(width: 20),

        // INFOS
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating estrelas
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _saveRating((index + 1).toDouble()),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFEB9A3A),
                      size: 26,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // Título
              Text(
                manga.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),

              // Gêneros
              Text(
                "Gênero: ${manga.genres.join(', ')}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Descrição
              Text(
                manga.description ?? "Sem descrição disponível.",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),

              // Linha com Status / Cap quant / Favorito
              Row(
                children: [
                  _buildInfoChip("Status"),
                  const SizedBox(width: 8),
                  _buildInfoChip("Cap quant."),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      currentTracked.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: const Color(0xFFEB3A6A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Checkpoint atual (se houver)
              if (currentTracked.checkpoint != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4A5C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B4A5C),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark,
                        color: Color(0xFF8B4A5C),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Último capítulo lido: ${currentTracked.checkpoint!.lastChapterRead}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // HEADER – LAYOUT COMPACTO
  // =========================
  Widget _buildCompactHeaderSection(Manga manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // POSTER
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: manga.coverUrl != null
                ? Image.network(
                    manga.coverUrl!,
                    height: 280,
                    width: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 280,
                        width: 190,
                        color: Colors.grey.shade700,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                        ),
                      );
                    },
                  )
                : Container(
                    height: 280,
                    width: 190,
                    color: Colors.grey.shade700,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => _saveRating((index + 1).toDouble()),
              child: Icon(
                index < selectedRating ? Icons.star : Icons.star_border,
                color: const Color(0xFFEB9A3A),
                size: 26,
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // Título
        Text(
          manga.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 6),

        // Gênero
        Text(
          "Gênero: ${manga.genres.join(', ')}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 12),

        // Descrição
        Text(
          manga.description ?? "Sem descrição disponível.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 16),

        // Linha status / cap / favorito
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip("Status"),
            _buildInfoChip("Cap quant."),
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                currentTracked.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: const Color(0xFFEB3A6A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (currentTracked.checkpoint != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4A5C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8B4A5C),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bookmark,
                  color: Color(0xFF8B4A5C),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Último capítulo lido: ${currentTracked.checkpoint!.lastChapterRead}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // =======================
  // MINHAS LISTAS (CHIPS)
  // =======================
  Widget _buildListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Minhas Listas",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildListChip(MangaListType.lendo, "Lendo Atualmente"),
            _buildListChip(MangaListType.queroLer, "Quero Ler"),
            _buildListChip(MangaListType.concluido, "Concluído"),
            _buildListChip(MangaListType.dropado, "Dropado"),
            _buildListChip(MangaListType.favoritos, "Favoritos"),
          ],
        ),
      ],
    );
  }

  Widget _buildListChip(MangaListType listType, String label) {
    final isSelected = currentTracked.lists.contains(listType);

    return GestureDetector(
      onTap: () => _toggleList(listType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4A5C) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B4A5C)
                : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check : Icons.add,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================
  // COMENTÁRIOS
  // =======================
    Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Comentários",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // FORMULÁRIO DE NOVO COMENTÁRIO
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _authorController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Seu nome",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF8B4A5C)),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Seu comentário",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF8B4A5C)),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 12),

              // 🔧 BOTÃO CORRIGIDO
              SizedBox(
                width: 180,
                height: 38,
                child: ElevatedButton(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4A5C),
                    foregroundColor: Colors.white, // garante texto branco
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  child: const Text("Comentar"),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // LISTA DE COMENTÁRIOS
        if (currentTracked.comments.isEmpty)
          const Text(
            "Nenhum comentário ainda.",
            style: TextStyle(color: Colors.grey),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentTracked.comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = currentTracked.comments[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDate(comment.createdAt),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Agora";
    } else if (difference.inMinutes < 60) {
      return "há ${difference.inMinutes}m";
    } else if (difference.inHours < 24) {
      return "há ${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "há ${difference.inDays}d";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  // =======================
  // CAPÍTULOS
  // =======================
  Widget _buildChaptersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Capítulos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MangaChapter>>(
          future: _chaptersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B4A5C),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Erro ao carregar capítulos.",
                  style: TextStyle(color: Colors.red.shade400),
                ),
              );
            }

            final chapters = snapshot.data ?? [];

            if (chapters.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Nenhum capítulo encontrado.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.grey.shade800, height: 1),
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final chapterNum =
                      int.tryParse(chapter.chapterNumber ?? "0") ?? 0;
                  final isRead = currentTracked.checkpoint != null &&
                      currentTracked.checkpoint!.lastChapterRead >= chapterNum;

                  return ListTile(
                    dense: true,
                    tileColor:
                        isRead ? Colors.grey.shade900.withOpacity(0.4) : null,
                    title: Text(
                      "Capítulo ${chapter.chapterNumber ?? '??'}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration:
                            isRead ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: chapter.title != null
                        ? Text(
                            chapter.title!,
                            style: const TextStyle(color: Colors.grey),
                          )
                        : null,
                    trailing: Icon(
                      isRead ? Icons.check_circle : Icons.chevron_right,
                      color: isRead
                          ? const Color(0xFF8B4A5C)
                          : Colors.grey.shade400,
                    ),
                    onTap: () {
                      _setCheckpoint(chapterNum, chapter.title);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MangaReaderPage(
                            chapterId: chapter.id,
                            chapterTitle:
                                "Capítulo ${chapter.chapterNumber ?? ''}",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
