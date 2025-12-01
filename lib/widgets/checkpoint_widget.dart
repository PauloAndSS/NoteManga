import 'package:flutter/material.dart';
import '../models/manga_models.dart';
import 'package:intl/intl.dart';

class CheckpointWidget extends StatelessWidget {
  final MangaCheckpoint? checkpoint;
  final VoidCallback? onEdit;

  const CheckpointWidget({
    super.key,
    this.checkpoint,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (checkpoint == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Progresso de Leitura",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Nenhum capítulo lido ainda",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(
                Icons.edit,
                color: Color(0xFF8B4A5C),
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(checkpoint!.lastReadAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Último Capítulo Lido",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Capítulo ${checkpoint!.lastChapterRead}",
                style: const TextStyle(
                  color: Color(0xFF8B4A5C),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Lido em: $formattedDate",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit,
              color: Color(0xFF8B4A5C),
            ),
          ),
        ],
      ),
    );
  }
}
