import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../utils.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late final TextEditingController _chave;
  late final TextEditingController _modelo;
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    _chave = TextEditingController(text: appState.apiKey);
    _modelo = TextEditingController(text: appState.modelo);
  }

  @override
  void dispose() {
    _chave.dispose();
    _modelo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await appState.salvarConfig(_chave.text.trim(), _modelo.text.trim());
    if (mounted) aviso(context, 'Configurações salvas.');
  }

  Future<void> _copiarBackup() async {
    await Clipboard.setData(ClipboardData(text: appState.exportar()));
    if (mounted) {
      aviso(context, 'Backup copiado! Cole em um bloco de notas ou mande para você mesmo.');
    }
  }

  Future<void> _restaurarBackup() async {
    final texto = await pedirTexto(
      context,
      titulo: 'Colar backup',
      dica: 'Cole aqui o texto do backup',
      linhas: 6,
    );
    if (texto == null || texto.isEmpty || !mounted) return;
    final ok = await confirmar(
        context, 'Restaurar backup', 'Isso substitui seus treinos e histórico atuais.');
    if (!ok) return;
    try {
      await appState.importar(texto);
      if (mounted) aviso(context, 'Backup restaurado!');
    } catch (e) {
      if (mounted) aviso(context, 'Backup inválido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('IA (Gemini)',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent)),
          const SizedBox(height: 4),
          const Text(
            'Gere uma chave gratuita no Google AI Studio (aistudio.google.com) e cole abaixo.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chave,
            obscureText: _ocultar,
            decoration: InputDecoration(
              labelText: 'Chave da API',
              suffixIcon: IconButton(
                icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelo,
            decoration: const InputDecoration(
              labelText: 'Modelo',
              helperText: 'Se o Google aposentar este modelo, troque o nome aqui.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _salvar, child: const Text('Salvar')),
          const SizedBox(height: 32),
          const Text('Backup',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent)),
          const SizedBox(height: 4),
          const Text(
            'Seus dados ficam só neste aparelho. Guarde um backup para não perder ao trocar de celular.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _copiarBackup,
            icon: const Icon(Icons.copy),
            label: const Text('Copiar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restaurarBackup,
            icon: const Icon(Icons.paste),
            label: const Text('Restaurar backup'),
          ),
        ],
      ),
    );
  }
}
