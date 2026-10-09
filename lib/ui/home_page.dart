import 'package:flutter/material.dart';
import '../models/caminhada.dart';
import '../services/caminhada_storage.dart';
import 'detalhes_caminhada_page.dart';
import 'nova_caminhada_page.dart';
import 'splash_page.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  final bool modoEscuro;
  final ValueChanged<bool> onTemaChanged;

  const HomePage({
    super.key,
    required this.modoEscuro,
    required this.onTemaChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CaminhadaStorage _storage = CaminhadaStorage();

  List<Caminhada> caminhadas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarCaminhadas();
  }

  Future<void> carregarCaminhadas() async {
    final dados = await _storage.carregar();

    if (!mounted) return;

    setState(() {
      caminhadas = dados;
      carregando = false;
    });
  }

  Future<void> abrirNovaCaminhada() async {
    final caminhada = await Navigator.push<Caminhada>(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaCaminhadaPage(),
      ),
    );

    if (caminhada == null) return;

    caminhadas.insert(0, caminhada);
    await _storage.salvar(caminhadas);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caminhada salva com sucesso.'),
      ),
    );
  }

  Future<void> abrirDetalhes(Caminhada caminhada) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesCaminhadaPage(
          caminhada: caminhada,
          onAtualizar: (atualizada) async {
            final index = caminhadas.indexWhere(
              (item) => item.id == atualizada.id,
            );

            if (index == -1) return;

            caminhadas[index] = atualizada;
            await _storage.salvar(caminhadas);

            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  void abrirSplash() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplashPage(
          modoEscuro: widget.modoEscuro,
          onTemaChanged: widget.onTemaChanged,
        ),
      ),
    );
  }

  Future<void> excluirCaminhada(Caminhada caminhada) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir caminhada'),
          content: Text(
            'Deseja excluir "${caminhada.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    caminhadas.removeWhere((item) => item.id == caminhada.id);
    await _storage.salvar(caminhadas);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minhas Caminhadas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text('Splash'),
                onTap: () {
                  Navigator.pop(context);
                  abrirSplash();
                },
              ),
              SwitchListTile(
                secondary: Icon(
                  widget.modoEscuro
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: const Text('Tema escuro'),
                value: widget.modoEscuro,
                onChanged: (valor) {
                  widget.onTemaChanged(valor);
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Você saiu da tela principal.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Minhas Caminhadas'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: abrirNovaCaminhada,
        child: const Icon(Icons.add),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : caminhadas.isEmpty
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: carregarCaminhadas,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: caminhadas.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final caminhada = caminhadas[index];

                      return CaminhadaCard(
                        caminhada: caminhada,
                        onTap: () => abrirDetalhes(caminhada),
                        onExcluir: () => excluirCaminhada(caminhada),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma caminhada cadastrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no botão + para escolher um destino e criar sua primeira caminhada.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
