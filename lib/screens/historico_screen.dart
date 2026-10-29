import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final sessoes = appState.historico.reversed.toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Histórico')),
          body: sessoes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum treino registrado ainda.\nFinalize um treino para ele aparecer aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sessoes.length,
                  itemBuilder: (context, i) {
                    final s = sessoes[i];
                    return Card(
                      color: Theme.of(context).colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        title: Text(s.treinoNome,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(fmtData(s.data)),
                        children: s.itens
                            .map<Widget>((it) => ListTile(
                                  dense: true,
                                  title: Text(it.nome),
                                  trailing: Text(
                                      '${it.series} séries • ${fmtCarga(it.carga)} kg'),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
