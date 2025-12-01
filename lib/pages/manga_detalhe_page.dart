import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../api/mangadex_api.dart' as md;
import 'chapter_reader_page.dart';

class MangaDetalhePage extends StatefulWidget {
  final Manga manga;
  const MangaDetalhePage({super.key, required this.manga});

  @override
  State<MangaDetalhePage> createState() => _MangaDetalhePageState();
}

class _MangaDetalhePageState extends State<MangaDetalhePage> {
  final md.MangaDexApi _api = md.MangaDexApi();
  List<md.MangaChapter> _capitulos = [];
  bool _loadingCapitulos = false;
  String? _errorCapitulos;

  @override
  void initState() {
    super.initState();
    _carregarCapitulos();
  }

  Future<void> _carregarCapitulos() async {
    setState(() {
      _loadingCapitulos = true;
      _errorCapitulos = null;
    });
    try {
      final caps = await _api.getChapters(widget.manga.id);
      setState(() {
        _capitulos = caps;
      });
    } catch (e) {
      setState(() {
        _errorCapitulos = "Erro ao carregar capítulos: $e";
      });
    } finally {
      setState(() {
        _loadingCapitulos = false;
      });
    }
  }

  void _mudarStatus(String novoStatus) {
    setState(() {
      listaTodos.remove(widget.manga);
      listaLer.remove(widget.manga);
      listaLendo.remove(widget.manga);
      listaLido.remove(widget.manga);

      widget.manga.status = novoStatus;

      switch (novoStatus) {
        case "ler":
          listaLer.add(widget.manga);
          break;
        case "lendo":
          listaLendo.add(widget.manga);
          break;
        case "lido":
          listaLido.add(widget.manga);
          break;
        default:
          listaTodos.add(widget.manga);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${widget.manga.title} movido para $novoStatus")),
    );
  }

  void _toggleFavorito() {
    setState(() {
      widget.manga.isFavorito = !widget.manga.isFavorito;
      if (widget.manga.isFavorito && !listaFavoritos.contains(widget.manga)) {
        listaFavoritos.add(widget.manga);
      } else {
        listaFavoritos.remove(widget.manga);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.manga.isFavorito
              ? "${widget.manga.title} adicionado aos favoritos"
              : "${widget.manga.title} removido dos favoritos",
        ),
      ),
    );
  }

  void _definirCapitulo(String capitulo) {
    setState(() {
      widget.manga.capituloAtual = capitulo;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Capítulo atual definido: $capitulo")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    return Scaffold(
      backgroundColor: const Color(0xFF404040), // fundo escuro
      appBar: AppBar(
        title: Text(manga.title),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F), // header vinho
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C), // sombra
        foregroundColor: Colors.white, // texto e ícones brancos
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (manga.coverUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(manga.coverUrl!, height: 220),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              manga.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              manga.desc,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              "Status atual: ${manga.status.isEmpty ? "Nenhum" : manga.status.toUpperCase()}",
              style: const TextStyle(color: Colors.white),
            ),
            if (manga.status == "lendo") ...[
              const SizedBox(height: 16),
              Text(
                "Capítulo atual: ${manga.capituloAtual ?? "Nenhum"}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Marcar capítulo atual",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: _definirCapitulo,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              "Mover para:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3F3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _mudarStatus("ler"),
                  child: const Text("Ler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3F3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _mudarStatus("lendo"),
                  child: const Text("Lendo"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3F3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _mudarStatus("lido"),
                  child: const Text("Lido"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  "Favoritar:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    manga.isFavorito ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: _toggleFavorito,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Capítulos:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (_loadingCapitulos)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (_errorCapitulos != null)
              Text(_errorCapitulos!, style: const TextStyle(color: Colors.redAccent))
            else if (_capitulos.isEmpty)
              const Text("Nenhum capítulo encontrado", style: TextStyle(color: Colors.white70))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _capitulos.length,
                itemBuilder: (context, index) {
                  final cap = _capitulos[index];
                  return Card(
                    color: Colors.grey[850],
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        "Capítulo ${cap.chapterNumber ?? "?"}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        cap.title ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderPage(chapter: cap),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
