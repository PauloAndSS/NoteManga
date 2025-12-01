import 'package:flutter/material.dart';
import '../../../Api/mangadex_api.dart';
import '../../../models/manga_models.dart';

class MangaReaderPage extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;

  const MangaReaderPage({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  final MangaDexApi api = MangaDexApi();
  late Future<List<MangaPage>> _pagesFuture;

  @override
  void initState() {
    super.initState();
    _pagesFuture = api.getPages(widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text(widget.chapterTitle),
        backgroundColor: Colors.black,

        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: "Sair da leitura",
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: FutureBuilder<List<MangaPage>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Erro ao carregar páginas.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final pages = snapshot.data ?? [];

          if (pages.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma página encontrada.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 700 : double.infinity,
              ),

              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        pages[index].url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loading) {
                          if (loading == null) return child;
                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.broken_image, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
