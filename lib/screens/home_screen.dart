import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../ia_service.dart';
import '../models.dart';
import '../utils.dart';
import 'config_screen.dart';
import 'historico_screen.dart';
import 'treino_screen.dart';

class _Arquivo {
  final Uint8List bytes;
  final String mime;
  _Arquivo(this.bytes, this.mime);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _carregando = false;

  String _mimePorExtensao(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<_Arquivo?> _escolher(String origem) async {
    if (origem == 'camera') {
      final foto = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 85);
      if (foto == null) return null;
      return _Arquivo(await foto.readAsBytes(), 'image/jpeg');
    }
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (r == null || r.files.isEmpty) return null;
    final f = r.files.single;
    Uint8List? bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    }
    if (bytes == null) return null;
    return _Arquivo(bytes, _mimePorExtensao(f.extension));
  }

  Future<void> _importar(String origem) async {
    if (!await garantirChave(context)) return;
    _Arquivo? arq;
    try {
      arq = await _escolher(origem);
    } catch (e) {
      if (mounted) aviso(context, 'Erro ao abrir o arquivo: $e');
      return;
    }
    if (arq == null || !mounted) return;

    setState(() => _carregando = true);
    try {
      final novos = await IaService.lerPlanilha(arq.bytes, arq.mime);
      if (novos.isEmpty) {
        if (mounted) aviso(context, 'Não encontrei treinos nesse arquivo.');
      } else {
        appState.treinos.addAll(novos);
        await appState.salvar();
        if (mounted) aviso(context, '${novos.length} treino(s) adicionado(s)!');
      }
    } catch (e) {
      if (mounted) aviso(context, mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarManual() async {
    final nome = await pedirTexto(
      context,
      titulo: 'Nome do treino',
      dica: 'Ex.: Treino A - Peito e Tríceps',
    );
    if (nome == null || nome.isEmpty || !mounted) return;
    final grupos = await pedirTexto(
      context,
      titulo: 'Grupos musculares',
      dica: 'Ex.: Peito, Tríceps (separe por vírgula)',
    );
    if (!mounted) return;
    final lista = (grupos ?? '')
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();
    final t = Treino(id: novoId(), dia: nome, grupos: lista, exercicios: []);
    appState.treinos.add(t);
    await appState.salvar();
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => TreinoScreen(treinoId: t.id)));
  }

  Future<void> _renomear(Treino t) async {
    final nome = await pedirTexto(context, titulo: 'Renomear treino', inicial: t.dia);
    if (nome == null || nome.isEmpty) return;
    t.dia = nome;
    await appState.salvar();
  }

  Future<void> _excluir(Treino t) async {
    final ok = await confirmar(
        context, 'Excluir treino', 'Excluir "${t.dia}"? O histórico é mantido.');
    if (!ok) return;
    appState.treinos.removeWhere((x) => x.id == t.id);
    await appState.salvar();
  }

  void _menuNovo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kFundoCard,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.cyanAccent),
            title: const Text('Tirar foto da planilha'),
            onTap: () {
              Navigator.pop(context);
              _importar('camera');
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
            title: const Text('Carregar PDF / imagem'),
            onTap: () {
              Navigator.pop(context);
              _importar('file');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.white70),
            title: const Text('Criar manualmente'),
            onTap: () {
              Navigator.pop(context);
              _criarManual();
            },
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 72, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Nenhum treino ainda.\nToque em "Novo treino" para ler uma planilha ou criar o seu.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final treinos = appState.treinos;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Treino AI',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Histórico',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoricoScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConfigScreen())),
              ),
            ],
            bottom: _carregando
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(minHeight: 3),
                  )
                : null,
          ),
          body: treinos.isEmpty
              ? _vazio()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: treinos.length,
                  itemBuilder: (context, index) {
                    final t = treinos[index];
                    var resumo = '${t.exercicios.length} exercícios';
                    if (t.ultimoTreino != null) {
                      resumo = '$resumo • último: ${fmtData(t.ultimoTreino)}';
                    }
                    return Card(
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TreinoScreen(treinoId: t.id)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.dia,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'renomear') {
                                        _renomear(t);
                                      } else {
                                        _excluir(t);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'renomear', child: Text('Renomear')),
                                      PopupMenuItem(
                                          value: 'excluir', child: Text('Excluir')),
                                    ],
                                  ),
                                ],
                              ),
                              if (t.grupos.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: t.grupos
                                      .map<Widget>((g) => Chip(
                                            label: Text(
                                              g,
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Colors.cyanAccent,
                                            visualDensity: VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(resumo,
                                  style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.cyanAccent,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Novo treino',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            onPressed: _menuNovo,
          ),
        );
      },
    );
  }
}
