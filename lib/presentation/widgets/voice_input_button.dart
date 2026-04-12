import 'package:flutter/material.dart';

/// Botão reservado para entrada por voz.
///
/// PONTO DE EXTENSÃO: Implemente [onVoiceResult] para integrar com
/// speech_to_text, google_speech ou qualquer serviço STT.
/// A UI já está pronta — basta conectar o serviço.
class VoiceInputButton extends StatelessWidget {
  /// Chamado quando o reconhecimento de voz retorna um texto.
  /// No MVP este callback nunca é chamado (botão mostra "em breve").
  final void Function(String text)? onVoiceResult;

  const VoiceInputButton({super.key, this.onVoiceResult});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Entrada por voz (em breve)',
      child: IconButton.filledTonal(
        onPressed: () {
          // TODO: integrar speech_to_text aqui
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrada por voz estará disponível em breve!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: Icon(Icons.mic_outlined, color: colorScheme.primary),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
        ),
      ),
    );
  }
}
