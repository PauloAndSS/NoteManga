import 'package:flutter/material.dart';
import '../../models/manga_models.dart';
import '../../services/storage_service.dart';
import 'manga_details_page.dart';

class MangaListsPage extends StatefulWidget {
  const MangaListsPage({super.key});

  @override
  State<MangaListsPage> createState() => _MangaListsPageState();
}

class _MangaListsPageState extends State<MangaListsPage>
    with SingleTickerProviderStateMixin {
  final StorageService storage = StorageService();
  late TabController _tabController;

  final List<MangaListType> listTypes = [
    MangaListType.lendo,
    MangaListType.queroLer,
    MangaListType.concluido,
    MangaListType.dropado,
    MangaListType.favoritos,
  ];

  final Map<MangaListType, String> listLabels = {
    MangaListType.lendo: "Lendo Atualmente",
    MangaListType.queroLer: "Quero Ler",
    MangaListType.concluido: "Concluído",
    MangaListType.dropado: "Dropado",
    MangaListType.favoritos: "Favoritos",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: listTypes.length, vsync: this);
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await storage.init();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER com gradiente + logo (mesmo padrão da Home/Detalhes)
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
                  height: 26,
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
                const SizedBox(width: 12),
                const Text(
                  "Minhas Listas",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  // Futuramente: tela de perfil/estatísticas
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
        child: Column(
          children: [
            // ABAS
            Container(
              color: Colors.black.withOpacity(0.3),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,

                // 👉 espaçamento horizontal entre as abas
                labelPadding: const EdgeInsets.symmetric(horizontal: 28),

                labelColor: const Color(0xFFEB3A6A),
                unselectedLabelColor: Colors.grey.shade400,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: Color(0xFFEB3A6A),
                    width: 3,
                  ),
                  // opcional: combinar com o labelPadding
                  insets: EdgeInsets.symmetric(horizontal: 24),
                ),
                tabs: listTypes
                    .map(
                      (type) => Tab(
                        text: listLabels[type],
                        height: 48,
                      ),
                    )
                    .toList(),
              ),
            ),

            // CONTEÚDO DAS ABAS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: listTypes
                    .map((listType) => _buildListContent(listType))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // CONTEÚDO DE CADA ABA
  // ======================
  Widget _buildListContent(MangaListType listType) {
    return FutureBuilder<List<MangaTracked>>(
      future: storage.getMangasByList(listType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B4A5C),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erro ao carregar lista",
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final mangas = snapshot.data ?? [];

        if (mangas.isEmpty) {
          return _buildEmptyState(listType);
        }

        // Layout responsivo em grade (estilo Netflix)
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: const Color(0xFF8B4A5C),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount;
              if (width < 600) {
                crossAxisCount = 3;
              } else if (width < 900) {
                crossAxisCount = 5;
              } else {
                crossAxisCount = 7;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.55,
                ),
                itemCount: mangas.length,
                itemBuilder: (context, index) {
                  final manga = mangas[index];
                  return _buildMangaGridItem(manga);
                },
              );
            },
          ),
        );
      },
    );
  }

  // Estado vazio com UX mais amigável
  Widget _buildEmptyState(MangaListType listType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_library_outlined,
            size: 72,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            "Nenhum mangá em \"${listLabels[listType]}\"",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Explore os títulos na tela inicial e adicione mangás às suas listas para acompanhar melhor o que está lendo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // CARD EM GRADE (GRID)
  // =====================
  Widget _buildMangaGridItem(MangaTracked manga) {
    return GestureDetector(
      onTap: () {
        // Navegar para detalhes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MangaDetailsPage(
              manga: Manga(
                id: manga.id,
                title: manga.title,
                description: manga.description,
                genres: manga.genres,
                coverUrl: manga.coverUrl,
              ),
              trackedManga: manga,
            ),
          ),
        ).then((_) {
          // Atualizar quando voltar (refletir rating, listas, etc.)
          setState(() {});
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CAPA com overlay de título/rating/progresso
          Expanded(
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

                  // Gradiente no rodapé + título + info
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            manga.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (manga.rating != null) ...[
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Color(0xFFEB9A3A),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  manga.rating!.stars.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (manga.checkpoint != null)
                                Text(
                                  "Cap. ${manga.checkpoint!.lastChapterRead}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Coração de favorito no canto superior direito
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        await storage.toggleFavorite(manga.id);
                        setState(() {});
                      },
                      child: Icon(
                        manga.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: const Color(0xFFEB3A6A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getListLabel(MangaListType listType) {
    switch (listType) {
      case MangaListType.lendo:
        return "Lendo";
      case MangaListType.queroLer:
        return "Ler";
      case MangaListType.concluido:
        return "Concluído";
      case MangaListType.dropado:
        return "Dropado";
      case MangaListType.favoritos:
        return "Favorito";
    }
  }
}
