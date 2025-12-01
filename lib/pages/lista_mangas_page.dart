import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import 'manga_detalhe_page.dart';

class ListaMangasPage extends StatefulWidget {
  @override
  State<ListaMangasPage> createState() => _ListaMangasPageState();
}

class _ListaMangasPageState extends State<ListaMangasPage> {
  int _selectedIndex = 0;

  List<Manga> _filtrarPorStatus(String status) {
    switch (status) {
      case "ler":
        return listaLer;
      case "lendo":
        return listaLendo;
      case "lido":
        return listaLido;
      default:
        return [];
    }
  }

  void _moverEntreListas(Manga manga, String novoStatus) {
    listaTodos.remove(manga);
    listaLer.remove(manga);
    listaLendo.remove(manga);
    listaLido.remove(manga);

    manga.status = novoStatus;

    switch (novoStatus) {
      case "ler":
        listaLer.add(manga);
        break;
      case "lendo":
        listaLendo.add(manga);
        break;
      case "lido":
        listaLido.add(manga);
        break;
      case "Nenhum":
        listaTodos.add(manga);
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = ["ler", "lendo", "lido"];
    final lista = _filtrarPorStatus(status[_selectedIndex]);

    return Scaffold(
      backgroundColor: const Color(0xFF404040), // fundo escuro
      appBar: AppBar(
        title: const Text("Lista de Mangás"),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3F3F), // header vinho
        elevation: 6,
        shadowColor: const Color(0xFFA56C6C), // sombra
        foregroundColor: Colors.white, // texto e ícones brancos
      ),
      body: lista.isEmpty
          ? const Center(
              child: Text(
                "Nenhum mangá nesta categoria",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final manga = lista[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      manga.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: manga.status == "lendo"
                        ? Text(
                            "Capítulo atual: ${manga.capituloAtual ?? "Nenhum"}",
                            style: const TextStyle(color: Colors.white70),
                          )
                        : Text(
                            manga.description ?? "",
                            style: const TextStyle(color: Colors.white70),
                          ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MangaDetalhePage(manga: manga),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    trailing: PopupMenuButton<String>(
                      color: Colors.grey[900],
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        _moverEntreListas(manga, value);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "ler",
                          child: Text(
                            "Mover para Ler",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "lendo",
                          child: Text(
                            "Mover para Lendo",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "lido",
                          child: Text(
                            "Mover para Lido",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "Nenhum",
                          child: Text(
                            "Remover da lista",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF8C3F3F), // cor do header
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Ler"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Lendo"),
          BottomNavigationBarItem(icon: Icon(Icons.done), label: "Lido"),
        ],
      ),
    );
  }
}
