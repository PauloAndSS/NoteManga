import 'package:flutter/material.dart';
import '../api/mangadex_api.dart' as md;

class ChapterReaderPage extends StatefulWidget {
  final md.MangaChapter chapter;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const ChapterReaderPage({
    super.key,
    required this.chapter,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  final md.MangaDexApi _api = md.MangaDexApi();
  final ScrollController _scrollController = ScrollController();

  List<md.ChapterPage> _pages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarPaginas();
  }

  Future<void> _carregarPaginas() async {
    try {
      final paginas = await _api.getChapterPages(widget.chapter.id);
      setState(() {
        _pages = paginas;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao carregar páginas: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _voltarAoTopo() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capNum = widget.chapter.chapterNumber ?? "?";
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content;
    if (_loading) {
      content = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (_error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      content = ListView.builder(
        controller: _scrollController,
        itemCount: _pages.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildNavButton("Anterior capítulo", widget.onPrevious);
          } else if (index == _pages.length + 1) {
            return _buildNavButton("Próximo capítulo", widget.onNext);
          } else {
            final page = _pages[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  page.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF404040), // fundo escuro
      appBar: AppBar(
        title: Text("Capítulo $capNum"),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F), // header vinho
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C), // sombra
        foregroundColor: Colors.white, // texto e ícones brancos
      ),
      floatingActionButton: _pages.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF8C3F3F),
              foregroundColor: Colors.white,
              onPressed: _voltarAoTopo,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 600 : double.infinity,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, VoidCallback? action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8C3F3F),
            foregroundColor: Colors.white,
          ),
          onPressed: action,
          child: Text(label),
        ),
      ),
    );
  }
}
