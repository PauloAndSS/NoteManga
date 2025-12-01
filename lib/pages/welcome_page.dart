import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goToHome(BuildContext context) {
    // Por enquanto, entrar = ir para a Home
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black.withOpacity(0.35),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            if (isDesktop)
              const Text(
                'MangaTracker',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
        actions: [
          // BOTÃO ENTRAR (sem bonequinho, bem destacado)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => _goToHome(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E1B26),
              Color(0xFF050509),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context, isDesktop),
                  const SizedBox(height: 32),
                  _buildFeatureChips(),
                  const SizedBox(height: 32),
                  _buildHowItWorksSection(isDesktop),
                  const SizedBox(height: 24),
                  _buildWhySection(isDesktop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // HERO PRINCIPAL
  // ===========================
  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    final double height = isDesktop ? 260 : 260;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B4A5C),
            Color(0xFF281B2B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Marca d’água no fundo (removemos o “cinza vazio”)
          Positioned(
            right: -40,
            top: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.18,
              child: Icon(
                Icons.menu_book_rounded,
                size: height + 80,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: isDesktop ? 0.55 : 0.95,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Seu gerenciador pessoal de mangás.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organize, acompanhe e descubra novos mangás\ncomo se fosse um streaming.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Crie listas de leitura, marque capítulos, deixe avaliações e comentários.\n'
                      'Tudo em um só lugar.',
                      style: TextStyle(
                        color: Color(0xFFF5F5F5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // PRINCIPAL CTA
                        FilledButton(
                          onPressed: () => _goToHome(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            'Começar agora',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // SEGUNDO CTA (também exige “entrar”)
                        OutlinedButton(
                          onPressed: () => _goToHome(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            'Ver minha biblioteca',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // CHIPS DE FEATURES
  // ===========================
  Widget _buildFeatureChips() {
    final features = [
      ('Listas personalizadas', Icons.playlist_add_check),
      ('Progresso por capítulo', Icons.timeline),
      ('Avaliações e comentários', Icons.star_rate_rounded),
      ('Catálogo da MangaDex', Icons.public),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features
          .map(
            (f) => Chip(
              backgroundColor: const Color(0xFF262626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: Color(0x33FFFFFF)),
              ),
              avatar: Icon(
                f.$2,
                size: 18,
                color: const Color(0xFFE88BA7),
              ),
              label: Text(
                f.$1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ===========================
  // SEÇÃO “COMO FUNCIONA?”
  // ===========================
  Widget _buildHowItWorksSection(bool isDesktop) {
    final cards = [
      _infoCard(
        title: 'Monte suas listas',
        text:
            'Separe o que está lendo, o que quer começar, o que já concluiu ou dropou. '
            'Tudo organizado em listas visuais, fáceis de navegar.',
      ),
      _infoCard(
        title: 'Marque seu progresso',
        text:
            'Registre até qual capítulo foi, veja rapidamente onde parou e retome a leitura sem se perder.',
      ),
      _infoCard(
        title: 'Descubra novos títulos',
        text:
            'Use o catálogo da MangaDex para explorar novos mangás por categoria, gênero ou popularidade.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como o MangaTracker funciona?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          )
        else
          Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          ),
      ],
    );
  }

  // ===========================
  // SEÇÃO “POR QUÊ?”
  // ===========================
  Widget _buildWhySection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pensado para leitores de mangá de verdade',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Se você acompanha vários mangás ao mesmo tempo, sabe como é fácil se perder '
          'em capítulos, pausas e novas temporadas.\n\n'
          'O MangaTracker nasce exatamente para isso: ser o seu painel de controle. '
          'Você continua lendo onde quiser, mas registra tudo aqui em um lugar só, bonito e organizado.',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===========================
  // CARD GENÉRICO DE INFORMAÇÃO
  // ===========================
  Widget _infoCard({required String title, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
