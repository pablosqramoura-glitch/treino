import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../ia_service.dart';
import '../models.dart';
import '../utils.dart';

class TreinoScreen extends StatefulWidget {
  final String treinoId;
  const TreinoScreen({super.key, required this.treinoId});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  final Map<Exercicio, int> _feitas = {};
  Timer? _timer;
  int _total = 0;
  int _restante = 0;
  String _nomeDescanso = '';
  bool _carregando = false;

  Treino? get _treino {
    for (final t in appState.treinos) {
      if (t.id == widget.treinoId) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- Descanso ----------

  void _iniciarDescanso(int segundos, String nome) {
    _timer?.cancel();
    if (segundos <= 0) {
      setState(() {
        _total = 0;
        _restante = 0;
      });
      return;
    }
    setState(() {
      _total = segundos;
      _restante = segundos;
      _nomeDescanso = nome;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restante <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _restante = 0);
      } else {
        setState(() => _restante--);
      }
    });
  }

  void _fecharDescanso() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _total = 0;
      _restante = 0;
    });
  }

  Widget _barraDescanso() {
    final acabou = _restante == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: kFundoCard,
        border: Border(top: BorderSide(color: Colors.cyanAccent, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Descanso • $_nomeDescanso',
                style: const TextStyle(color: Colors.white54)),
            Text(
              acabou ? 'Bora!' : '$_restante s',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _total == 0 ? 0 : _restante / _total,
              color: Colors.blueAccent,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _iniciarDescanso(_restante + 15, _nomeDescanso),
                  child: const Text('+15s'),
                ),
                TextButton(
                  onPressed: _fecharDescanso,
                  child: Text(acabou ? 'Fechar' : 'Pular',
                      style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Séries ----------

  void _marcarSerie(Exercicio ex, int i) {
    final atual = _feitas[ex] ?? 0;
    if (i < atual) {
      setState(() => _feitas[ex] = i);
    } else {
      setState(() => _feitas[ex] = i + 1);
      _iniciarDescanso(ex.descanso, ex.nome);
    }
  }

  Widget _bolinha(int i, bool feita, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: feita ? Colors.cyanAccent : Colors.transparent,
          border: Border.all(
              color: feita ? Colors.cyanAccent : Colors.white38, width: 2),
        ),
        child: feita
            ? const Icon(Icons.check, color: Colors.black, size: 22)
            : Text('${i + 1}',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------- Edição ----------

  Future<void> _editarCarga(Exercicio ex) async {
    final texto = await pedirTexto(
      context,
      titulo: ex.nome,
      inicial: fmtCarga(ex.carga),
      dica: 'Carga em kg',
    );
    if (texto == null) return;
    final v = double.tryParse(texto.replaceAll(',', '.'));
    if (v == null) return;
    ex.carga = v;
    await appState.salvar();
  }

  Future<void> _editarExercicio(Treino t, {Exercicio? ex}) async {
    final nome = TextEditingController(text: ex?.nome ?? '');
    final series = TextEditingController(text: '${ex?.series ?? 3}');
    final reps = TextEditingController(text: ex?.repeticoes ?? '10-12');
    final descanso = TextEditingController(text: '${ex?.descanso ?? 60}');
    final carga =
        TextEditingController(text: ex == null ? '0' : fmtCarga(ex.carga));

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kFundoCard,
        title: Text(ex == null ? 'Novo exercício' : 'Editar exercício'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: series,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Séries'),
            ),
            TextField(
              controller: reps,
              decoration: const InputDecoration(labelText: 'Repetições'),
            ),
            TextField(
              controller: descanso,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Descanso (segundos)'),
            ),
            TextField(
              controller: carga,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Carga (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true || nome.text.trim().isEmpty) return;

    final s = paraInt(series.text, 3).clamp(1, 20).toInt();
    final d = paraInt(descanso.text, 60).clamp(0, 600).toInt();
    final c = paraDouble(carga.text, 0);
    final r = reps.text.trim().isEmpty ? '10' : reps.text.trim();

    if (ex == null) {
      t.exercicios.add(Exercicio(
        nome: nome.text.trim(),
        series: s,
        repeticoes: r,
        descanso: d,
        carga: c,
      ));
    } else {
      ex.nome = nome.text.trim();
      ex.series = s;
      ex.repeticoes = r;
      ex.descanso = d;
      ex.carga = c;
    }
    await appState.salvar();
  }

  Future<void> _removerExercicio(Treino t, Exercicio ex) async {
    final ok = await confirmar(context, 'Remover exercício', 'Remover "${ex.nome}"?');
    if (!ok) return;
    t.exercicios.remove(ex);
    _feitas.remove(ex);
    await appState.salvar();
  }

  // ---------- Finalizar ----------

  Future<void> _finalizar(Treino t) async {
    final itens = <SessaoItem>[];
    for (final ex in t.exercicios) {
      final f = _feitas[ex] ?? 0;
      if (f > 0) {
        itens.add(SessaoItem(nome: ex.nome, carga: ex.carga, series: f));
      }
    }
    if (itens.isEmpty) {
      aviso(context, 'Marque ao menos uma série para registrar.');
      return;
    }
    final agora = DateTime.now().toIso8601String();
    appState.historico.add(Sessao(
      id: novoId(),
      data: agora,
      treinoId: t.id,
      treinoNome: t.dia,
      itens: itens,
    ));
    t.ultimoTreino = agora;
    _feitas.clear();
    _fecharDescanso();
    await appState.salvar();
    if (mounted) aviso(context, 'Treino registrado no histórico!');
  }

  // ---------- IA ----------

  Future<void> _sugerir(Treino t) async {
    if (t.exercicios.isEmpty) {
      aviso(context, 'Adicione exercícios primeiro.');
      return;
    }
    if (!await garantirChave(context)) return;
    if (!mounted) return;

    setState(() => _carregando = true);
    List<Sugestao> sugestoes = [];
    try {
      sugestoes = await IaService.sugerir(t);
    } catch (e) {
      if (mounted) aviso(context, mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
    if (sugestoes.isEmpty || !mounted) return;

    final aplicar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kFundoCard,
        title: const Text('Sugestões da IA'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sugestoes.map<Widget>((s) {
            final partes = <String>[];
            if (s.series != null) partes.add('${s.series} séries');
            if (s.repeticoes != null) partes.add('${s.repeticoes} reps');
            if (s.carga != null) partes.add('${fmtCarga(s.carga!)} kg');
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (partes.isNotEmpty)
                    Text(partes.join(' • '),
                        style: const TextStyle(color: Colors.cyanAccent)),
                  if (s.motivo.isNotEmpty)
                    Text(s.motivo, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar tudo'),
          ),
        ],
      ),
    );
    if (aplicar != true) return;

    for (final s in sugestoes) {
      for (final ex in t.exercicios) {
        if (ex.nome.toLowerCase().trim() == s.nome.toLowerCase().trim()) {
          if (s.series != null) ex.series = s.series!.clamp(1, 20).toInt();
          if (s.repeticoes != null && s.repeticoes!.isNotEmpty) {
            ex.repeticoes = s.repeticoes!;
          }
          if (s.carga != null) ex.carga = s.carga!;
        }
      }
    }
    await appState.salvar();
    if (mounted) aviso(context, 'Sugestões aplicadas!');
  }

  // ---------- Interface ----------

  Widget _cartaoExercicio(Treino t, Exercicio ex) {
    final feitas = _feitas[ex] ?? 0;
    final ultima = appState.ultimaCarga(ex.nome);
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.nome,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(
                        '${ex.series} × ${ex.repeticoes} • descanso ${ex.descanso}s',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'editar') {
                      _editarExercicio(t, ex: ex);
                    } else {
                      _removerExercicio(t, ex);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'remover', child: Text('Remover')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.fitness_center, size: 16),
                  label: Text('${fmtCarga(ex.carga)} kg'),
                  onPressed: () => _editarCarga(ex),
                ),
                if (ultima != null && ultima != ex.carga)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'última vez: ${fmtCarga(ultima)} kg',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                ex.series,
                (i) => _bolinha(i, i < feitas, () => _marcarSerie(ex, i)),
              ),
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
        final t = _treino;
        if (t == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Treino não encontrado.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(t.dia),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                tooltip: 'Sugerir progressão (IA)',
                onPressed: () => _sugerir(t),
              ),
            ],
            bottom: _carregando
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(minHeight: 3),
                  )
                : null,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (t.exercicios.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Nenhum exercício ainda.\nToque no + para adicionar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ...t.exercicios.map<Widget>((ex) => _cartaoExercicio(t, ex)),
              if (t.exercicios.isNotEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _finalizar(t),
                  icon: const Icon(Icons.flag),
                  label: const Text('Finalizar treino'),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.cyanAccent,
            onPressed: () => _editarExercicio(t),
            child: const Icon(Icons.add, color: Colors.black),
          ),
          bottomNavigationBar: _total > 0 ? _barraDescanso() : null,
        );
      },
    );
  }
}
