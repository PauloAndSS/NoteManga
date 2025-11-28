// lib/main.dart
import 'package:flutter/material.dart';
import 'mangadex_api.dart';

void main() {
  runApp(const MangaTrackerApp());
}

class MangaTrackerApp extends StatelessWidget {
  const MangaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MangaSearchPage(),
    );
  }
}

class MangaSearchPage extends StatefulWidget {
  const MangaSearchPage({super.key});

  @override
  State<MangaSearchPage> createState() => _MangaSearchPageState();
}

class _MangaSearchPageState extends State<MangaSearchPage> {
  final _api = MangaDexApi();
  final _controller = TextEditingController(text: 'naruto');

  bool _loading = false;
  String? _error;
  List<Manga> _results = [];

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final mangas = await _api.searchManga(query);
      setState(() {
        _results = mangas;
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

  Future<void> _showChapters(Manga manga) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chapters = await _api.getChapters(manga.id);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) {
          if (chapters.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nenhum capítulo encontrado para ${manga.title}.'),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Capítulos de ${manga.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return ListTile(
                      title: Text(
                        'Capítulo ${chapter.chapterNumber ?? '?'}',
                      ),
                      subtitle: chapter.title != null
                          ? Text(chapter.title!)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
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
    _search(); // busca inicial com "naruto"
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MangaTracker – MangaDex'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar mangá',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Erro: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('Nenhum mangá encontrado'),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final manga = _results[index];
                      return ListTile(
                        leading: manga.coverUrl != null
                            ? Image.network(
                                manga.coverUrl!,
                                width: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book_outlined),
                        title: Text(manga.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (manga.description != null)
                              Text(
                                manga.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (manga.genres.isNotEmpty)
                              Text(
                                'Gêneros: ${manga.genres.join(', ')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        onTap: () => _showChapters(manga),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
