import 'package:flutter/material.dart';
import '../../Api/mangadex_api.dart';
import '../../models/manga_models.dart';
import '../../services/storage_service.dart';
import 'manga_details_page.dart';

class MangaSearchPage extends StatefulWidget {
  const MangaSearchPage({super.key});

  @override
  State<MangaSearchPage> createState() => _MangaSearchPageState();
}

class _MangaSearchPageState extends State<MangaSearchPage> {
  final MangaDexApi api = MangaDexApi();
  final StorageService storage = StorageService();
  final TextEditingController _controller = TextEditingController();

  bool loading = false;
  bool loadingMore = false;
  List<Manga> results = [];
  int offset = 0;
  static const int limit = 20;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await storage.init();
  }

  /// Busca mangás (reset = true para nova busca, false para carregar mais)
  Future<void> search({bool reset = true}) async {
    final query = _controller.text.trim();

    if (reset) {
      setState(() {
        loading = true;
        offset = 0;
        results = [];
      });
    } else {
      setState(() => loadingMore = true);
    }

    try {
      // Mantém a lógica simples: busca tudo e pagina em memória
      final allResults =
          await api.searchManga(query.isEmpty ? "manga" : query);

      final paginated = allResults.skip(offset).take(limit).toList();

      setState(() {
        results.addAll(paginated);
        offset += limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }

    setState(() {
      loading = false;
      loadingMore = false;
    });
  }

  // Heurística simples: se já temos pelo menos "limit", mostramos o botão
  bool get hasMore => results.isNotEmpty && results.length % limit == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER com gradiente + logo (mesmo padrão das outras telas)
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
                  "Buscar Mangás",
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
                  // futuro: perfil / estatísticas
                },
              ),
            ],
          ),
        ),
      ),

      // BODY com gradiente + layout Netflix
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
            // Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => search(),
                decoration: InputDecoration(
                  hintText: 'Pesquisar por título...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF8B4A5C), size: 22),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF8B4A5C), width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Color(0xFF8B4A5C)),
                    onPressed: () => search(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Área dos resultados
            Expanded(
              child: _buildResultsArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B4A5C),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.search,
              size: 72,
              color: Colors.white30,
            ),
            SizedBox(height: 16),
            Text(
              "Comece digitando o nome de um mangá",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Use o campo acima para encontrar novos títulos e adicioná-los às suas listas.",
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

    // Grid de resultados (estilo Netflix)
    return LayoutBuilder(
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.55,
          ),
          itemCount: results.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < results.length) {
              final manga = results[index];
              return _buildMangaGridItem(manga);
            }

            // Tile do "Carregar mais"
            return _buildLoadMoreTile();
          },
        );
      },
    );
  }

  // Card de mangá em grade (semelhante às outras telas)
  Widget _buildMangaGridItem(Manga manga) {
    return GestureDetector(
      onTap: () {
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
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  // Gradiente + título + gêneros
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
                          if (manga.genres.isNotEmpty)
                            Text(
                              manga.genres.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                        ],
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

  // Tile de "Carregar mais" (corrigido com texto visível)
  Widget _buildLoadMoreTile() {
    if (!hasMore) return const SizedBox.shrink();

    if (loadingMore) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B4A5C),
        ),
      );
    }

    return Center(
      child: ElevatedButton(
        onPressed: () => search(reset: false),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4A5C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        child: const Text(
          'Carregar mais',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
