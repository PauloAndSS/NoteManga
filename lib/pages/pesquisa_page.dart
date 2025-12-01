import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import 'manga_detalhe_page.dart';

class PesquisaPage extends StatefulWidget {
  const PesquisaPage({super.key});

  @override
  State<PesquisaPage> createState() => _PesquisaPageState();
}

class _PesquisaPageState extends State<PesquisaPage> {
  final _api = MangaDexApi();
  final TextEditingController _controller = TextEditingController();

  List<Manga> _resultados = [];
  bool _loading = false;
  String? _error;
  int _offset = 0;

  final List<String> _generos = [
    "ação",
    "comédia",
    "romance",
    "slice of life",
    "fantasia",
    "drama",
  ];

  final Set<String> _selecionados = {};

  Future<void> _buscar({bool reset = true}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _offset = 0;
        _resultados.clear();
      }
    });

    try {
      final query = _controller.text.trim();
      final busca = query.isEmpty ? "naruto" : query;

      final novos = await _api.searchManga(busca);

      setState(() {
        if (_selecionados.isNotEmpty) {
          _resultados.addAll(
            novos.where((m) =>
                m.genres.any((g) => _selecionados.contains(g.toLowerCase()))),
          );
        } else {
          _resultados.addAll(novos);
        }
        _offset += novos.length;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF404040), // fundo escuro
      appBar: AppBar(
        title: const Text("Pesquisar Mangás"),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F), // header vinho
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C), // sombra
        foregroundColor: Colors.white, // texto e ícones brancos
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Digite o título do mangá...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3F3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _buscar(),
                  child: const Text("Buscar"),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: _generos.map((g) {
              return FilterChip(
                label: Text(
                  g,
                  style: TextStyle(
                    color: _selecionados.contains(g)
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
                selected: _selecionados.contains(g),
                selectedColor: const Color(0xFF8C3F3F),
                backgroundColor: Colors.grey[800],
                checkmarkColor: Colors.white,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selecionados.add(g);
                    } else {
                      _selecionados.remove(g);
                    }
                  });
                  _buscar();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _error != null
                    ? Center(
                        child: Text(
                          "Erro: $_error",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : _resultados.isEmpty
                        ? const Center(
                            child: Text(
                              "Nenhum mangá encontrado",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _resultados.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _resultados.length) {
                                return Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8C3F3F),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _buscar,
                                    child: const Text("Carregar mais"),
                                  ),
                                );
                              }
                              final manga = _resultados[index];
                              return Card(
                                color: Colors.grey[850],
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: manga.coverUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            manga.coverUrl!,
                                            width: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.book,
                                          color: Colors.white),
                                  title: Text(
                                    manga.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    manga.genres.isNotEmpty
                                        ? manga.genres.join(", ")
                                        : "Sem gênero",
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MangaDetalhePage(manga: manga),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
