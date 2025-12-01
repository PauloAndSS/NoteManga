import 'package:flutter/material.dart';
import '../Api/mangadex_api.dart';
import '../models/manga_models.dart';
import '../services/storage_service.dart';
import 'manga/manga_details_page.dart';
import 'manga/manga_lists_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MangaDexApi api = MangaDexApi();
  final StorageService storage = StorageService();

  bool loading = true;

  List<Manga> popular = [];
  List<Manga> updated = [];
  List<Manga> featured = [];

  // Destaques do banner (até 5 mangás aleatórios)
  List<Manga> heroMangas = [];
  late PageController _heroPageController;
  int _currentHeroIndex = 0;

  // Sessões por gênero
  final Map<String, List<Manga>> genreSections = {
    "Ação": [],
    "Romance": [],
    "Comédia": [],
    "Drama": [],
  };

  @override
  void initState() {
    super.initState();
    // viewportFraction = 1.0 -> banner ocupando toda a largura (modelo anterior)
    _heroPageController = PageController();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await storage.init();
    await loadData();
  }

  /// Monta a lista de mangás de destaque (até 5 aleatórios, sem repetir)
  void _rebuildHeroMangas() {
    final pool = <Manga>[
      ...featured,
      ...popular,
      ...updated,
      for (final entry in genreSections.entries) ...entry.value,
    ];

    final Map<String, Manga> unique = {};
    for (final m in pool) {
      unique[m.id] ??= m;
    }

    final list = unique.values.toList();
    list.shuffle();
    heroMangas = list.take(5).toList();
    _currentHeroIndex = 0;
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      popular = await api.searchManga("popular");
      updated = await api.searchManga("updated");
      featured = await api.searchManga("featured");

      // GÊNEROS
      genreSections["Ação"] = await api.searchManga("action");
      genreSections["Romance"] = await api.searchManga("romance");
      genreSections["Comédia"] = await api.searchManga("comedy");
      genreSections["Drama"] = await api.searchManga("drama");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }

    if (!mounted) return;

    setState(() {
      loading = false;
      _rebuildHeroMangas();
    });
  }

  void _openDetails(Manga manga) {
    final tracked = manga.toTracked();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MangaDetailsPage(
          manga: manga,
          trackedManga: tracked,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      // HEADER
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
            titleSpacing: 16,
            title: Row(
              children: [
                // LOGO IMG
                Image.asset(
                  'assets/logo.png',
                  height: 32,
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

      // BODY
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
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4A5C)),
              )
            : RefreshIndicator(
                onRefresh: loadData,
                color: const Color(0xFF8B4A5C),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // CARROSSEL DE DESTAQUE
                    if (heroMangas.isNotEmpty)
                      _buildHeroCarousel(isDesktop),

                    const SizedBox(height: 16),

                    _buildCategorySection("Categoria", popular, isDesktop),
                    _buildCategorySection("Título", updated, isDesktop),
                    _buildCategorySection("Gênero", featured, isDesktop),
                    _buildCategorySection("Status", featured, isDesktop),

                    for (final entry in genreSections.entries)
                      _buildCategorySection(
                        entry.key,
                        entry.value,
                        isDesktop,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // ==============================
  // CARROSSEL DE HERO BANNERS
  // ==============================
  Widget _buildHeroCarousel(bool isDesktop) {
    // Banner um pouco maior que antes
    final double height = isDesktop ? 320 : 260;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: heroMangas.length,
            onPageChanged: (index) {
              setState(() => _currentHeroIndex = index);
            },
            itemBuilder: (context, index) {
              final manga = heroMangas[index];
              return _buildHeroSection(manga, isDesktop);
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicadores (bolinhas) do carrossel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(heroMangas.length, (i) {
            final bool isActive = i == _currentHeroIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width: isActive ? 18 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF8B4A5C)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==============================
  // HERO / BANNER PRINCIPAL
  // ==============================
  Widget _buildHeroSection(Manga manga, bool isDesktop) {
    return GestureDetector(
      onTap: () => _openDetails(manga),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Imagem de fundo (um pouco mais alta)
              AspectRatio(
                aspectRatio: isDesktop ? 16 / 4.5 : 16 / 8.5,
                child: manga.coverUrl != null
                    ? Image.network(
                        manga.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade800,
                      ),
              ),

              // Overlay em gradiente
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Título + botões
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (manga.genres.isNotEmpty)
                      Text(
                        manga.genres.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _openDetails(manga),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: const Icon(Icons.menu_book),
                          label: const Text(
                            "Ver detalhes",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MangaListsPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: const Icon(Icons.list_alt),
                          label: const Text("Minhas listas"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // SEÇÃO DE CATEGORIA (CARROSSEL)
  // ==============================
  Widget _buildCategorySection(
    String title,
    List<Manga> items,
    bool isDesktop,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    final double cardWidth = isDesktop ? 140 : 120;
    final double cardHeight = isDesktop ? 210 : 190;

    // controlador para permitir scroll pela setinha
    final ScrollController controller = ScrollController();

    void scrollRight() {
      if (!controller.hasClients) return;
      final double delta = cardWidth * 2;
      final double max = controller.position.maxScrollExtent;
      final double target = (controller.offset + delta).clamp(0.0, max);
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TÍTULO DA SEÇÃO
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // LISTA HORIZONTAL + SETA À DIREITA
        SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final manga = items[index];
                  return _buildMangaCard(manga, cardWidth, cardHeight);
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: items.length,
              ),

              Positioned(
                right: 8,
                top: (cardHeight / 2) - 20,
                child: GestureDetector(
                  onTap: scrollRight,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ==============================
  // CARD DO MANGÁ (CAPA + OVERLAY)
  // ==============================
  Widget _buildMangaCard(Manga manga, double width, double height) {
    return GestureDetector(
      onTap: () => _openDetails(manga),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: manga.coverUrl != null
                            ? Image.network(
                                manga.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade700,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade700,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: Text(
                            manga.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
