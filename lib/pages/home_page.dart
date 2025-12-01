import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import 'manga_detalhe_page.dart';
import 'lista_mangas_page.dart';
import 'pesquisa_page.dart';
import 'favoritos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = MangaDexApi();
  final Map<String, ScrollController> _scrollControllers = {};

  Map<String, List<Manga>> categorias = {
    "Destaques": [],
    "Ação": [],
    "Comédia": [],
    "Slice of Life": [],
    "Romance": [],
  };

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (var key in categorias.keys) {
      _scrollControllers[key] = ScrollController();
    }
    _carregarCategorias();
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final destaques = await _api.searchManga("naruto");
      final acao = await _api.searchManga("action");
      final comedia = await _api.searchManga("comedy");
      final slice = await _api.searchManga("slice of life");
      final romance = await _api.searchManga("romance");

      setState(() {
        categorias["Destaques"] = destaques;
        categorias["Ação"] = acao;
        categorias["Comédia"] = comedia;
        categorias["Slice of Life"] = slice;
        categorias["Romance"] = romance;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao carregar categorias: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF404040),
      appBar: AppBar(
        title: const Text("MangaTracker"),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F),
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: "Minhas listas",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ListaMangasPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Pesquisar",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PesquisaPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: "Favoritos",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritosPage()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: categorias.entries.map((entry) {
                    final nome = entry.key;
                    final lista = entry.value;
                    return _buildCategoria(nome, lista);
                  }).toList(),
                ),
    );
  }

  Widget _buildCategoria(String nome, List<Manga> lista) {
    if (lista.isEmpty) return const SizedBox.shrink();
    final controller = _scrollControllers[nome]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            nome,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showArrows = lista.length * 150 > constraints.maxWidth;
              return Stack(
                children: [
                  ListView.builder(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final manga = lista[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MangaDetalhePage(manga: manga),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: manga.coverUrl != null
                                    ? Image.network(
                                        manga.coverUrl!,
                                        height: 160,
                                        width: 140,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 160,
                                        width: 140,
                                        color: Colors.grey[700],
                                        child: const Icon(Icons.book, size: 60, color: Colors.white),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  manga.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (showArrows) ...[
                    Positioned(
                      left: 0,
                      top: 90,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32, color: Colors.white),
                        onPressed: () {
                          controller.animateTo(
                            controller.offset - 160,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 90,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32, color: Colors.white),
                        onPressed: () {
                          controller.animateTo(
                            controller.offset + 160,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
