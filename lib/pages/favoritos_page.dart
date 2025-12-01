import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import 'manga_detalhe_page.dart';

class FavoritosPage extends StatelessWidget {
  const FavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritos = listaFavoritos.where((m) => m.isFavorito).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF404040), // fundo escuro
      appBar: AppBar(
        title: const Text("Favoritos"),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F), // header vinho
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C), // sombra
        foregroundColor: Colors.white, // texto e ícones brancos
      ),
      body: favoritos.isEmpty
          ? const Center(
              child: Text(
                "Nenhum mangá favoritado",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: favoritos.length,
              itemBuilder: (context, index) {
                final manga = favoritos[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: manga.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              manga.coverUrl!,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.book, color: Colors.white),
                    title: Text(
                      manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      manga.description ?? "",
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MangaDetalhePage(manga: manga),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      tooltip: "Remover dos favoritos",
                      onPressed: () {
                        manga.isFavorito = false;
                        listaFavoritos.remove(manga);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${manga.title} removido dos favoritos"),
                          ),
                        );
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
