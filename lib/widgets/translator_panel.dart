import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/translation_language.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';

/// Ouvre le traducteur en plein écran (bottom sheet) au-dessus de [context].
Future<void> showTranslatorPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TranslatorSheet(),
  );
}

class _ChatMessage {
  final String originalText;
  final String originalLangLabel;
  final String translatedText;
  final String translatedLangLabel;
  final bool fromAgent;
  final DateTime at;

  const _ChatMessage({
    required this.originalText,
    required this.originalLangLabel,
    required this.translatedText,
    required this.translatedLangLabel,
    required this.fromAgent,
    required this.at,
  });
}

class _TranslatorSheet extends StatefulWidget {
  const _TranslatorSheet();

  @override
  State<_TranslatorSheet> createState() => _TranslatorSheetState();
}

class _TranslatorSheetState extends State<_TranslatorSheet> {
  TranslationLanguage _language = kTranslationLanguages.first;
  final List<_ChatMessage> _messages = [];
  final _scrollCtrl = ScrollController();
  final _agentCtrl = TextEditingController();
  final _interlocutorCtrl = TextEditingController();
  bool _sending = false;
  bool _agentListening = false;
  bool _interlocutorListening = false;
  String? _error;

  @override
  void dispose() {
    SpeechService.instance.stop();
    _scrollCtrl.dispose();
    _agentCtrl.dispose();
    _interlocutorCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _labelForCode(String code) {
    if (code == 'fr') return kFrench.label;
    for (final l in kTranslationLanguages) {
      if (l.code == code) return l.label;
    }
    return code.toUpperCase();
  }

  Future<void> _sendAgentMessage() async {
    final text = _agentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await TranslationService.instance.translate(
        text: text,
        source: 'fr',
        target: _language.code,
      );
      setState(() {
        _messages.add(_ChatMessage(
          originalText: text,
          originalLangLabel: kFrench.label,
          translatedText: result.translatedText,
          translatedLangLabel: _language.label,
          fromAgent: true,
          at: DateTime.now(),
        ));
        _agentCtrl.clear();
      });
      _scrollToBottom();
    } on TranslationException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendInterlocutorMessage() async {
    final text = _interlocutorCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // source: auto — l'IA détecte la langue parlée/saisie par
      // l'interlocuteur plutôt que de présupposer la langue sélectionnée.
      final result = await TranslationService.instance.translate(
        text: text,
        source: 'auto',
        target: 'fr',
      );
      setState(() {
        _messages.add(_ChatMessage(
          originalText: text,
          originalLangLabel: _labelForCode(result.detectedSourceLanguage),
          translatedText: result.translatedText,
          translatedLangLabel: kFrench.label,
          fromAgent: false,
          at: DateTime.now(),
        ));
        _interlocutorCtrl.clear();
        // Aligne le sélecteur sur la langue détectée pour les prochaines
        // réponses de l'agent, sans empêcher une correction manuelle.
        for (final l in kTranslationLanguages) {
          if (l.code == result.detectedSourceLanguage) _language = l;
        }
      });
      _scrollToBottom();
    } on TranslationException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleMic({required bool forAgent}) async {
    final listening = forAgent ? _agentListening : _interlocutorListening;
    if (listening) {
      await SpeechService.instance.stop();
      setState(() {
        if (forAgent) {
          _agentListening = false;
        } else {
          _interlocutorListening = false;
        }
      });
      return;
    }

    final locale = forAgent
        ? kFrench.speechLocale!
        : (_language.speechLocale ?? kFrench.speechLocale!);

    setState(() {
      if (forAgent) {
        _agentListening = true;
      } else {
        _interlocutorListening = true;
      }
    });

    final started = await SpeechService.instance.listen(
      localeId: locale,
      onResult: (r) {
        final ctrl = forAgent ? _agentCtrl : _interlocutorCtrl;
        ctrl.text = r.text;
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        if (r.isFinal) {
          setState(() {
            if (forAgent) {
              _agentListening = false;
            } else {
              _interlocutorListening = false;
            }
          });
          if (forAgent) {
            _sendAgentMessage();
          } else {
            _sendInterlocutorMessage();
          }
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        if (forAgent) {
          _agentListening = false;
        } else {
          _interlocutorListening = false;
        }
        _error =
            'Reconnaissance vocale indisponible sur cet appareil/navigateur. '
            'Utilisez la saisie manuelle.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = TranslationService.instance.isConfigured;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPage,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _Header(
              language: _language,
              onLanguageChanged: (l) => setState(() => _language = l),
              onClose: () => Navigator.pop(context),
            ),
            if (!configured)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.orangeText),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Service de traduction non configuré. Voir docs/securite pour '
                        'choisir un fournisseur avant utilisation réelle.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.orangeText),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.redText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.redText)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate,
                              size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text(
                            'Parlez ou écrivez pour démarrer la conversation',
                            style: TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _Bubble(message: _messages[i]),
                    ),
            ),
            _InputBar(
              label: 'Vous (${kFrench.flag} Français)',
              controller: _agentCtrl,
              listening: _agentListening,
              enabled: !_sending,
              color: AppColors.blue,
              onMicTap: () => _toggleMic(forAgent: true),
              onSend: _sendAgentMessage,
            ),
            _InputBar(
              label: 'Interlocuteur (${_language.flag} ${_language.label})',
              controller: _interlocutorCtrl,
              listening: _interlocutorListening,
              enabled: !_sending,
              color: AppColors.purple,
              onMicTap: () => _toggleMic(forAgent: false),
              onSend: _sendInterlocutorMessage,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TranslationLanguage language;
  final ValueChanged<TranslationLanguage> onLanguageChanged;
  final VoidCallback onClose;

  const _Header({
    required this.language,
    required this.onLanguageChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.translate, color: AppColors.navy, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Traducteur',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TranslationLanguage>(
                value: language,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: kTranslationLanguages
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text('${l.flag} ${l.label}',
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (l) {
                  if (l != null) onLanguageChanged(l);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final fromAgent = message.fromAgent;
    final bg = fromAgent ? AppColors.blue : Colors.white;
    final fg = fromAgent ? Colors.white : AppColors.textPrimary;
    final subFg = fromAgent ? Colors.white70 : AppColors.textSecondary;
    final align = fromAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = fromAgent
        ? const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.translatedText,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg)),
                  const SizedBox(height: 4),
                  Text(
                      '« ${message.originalText} » — ${message.originalLangLabel}',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: subFg)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              '${message.translatedLangLabel} · '
              '${message.at.hour.toString().padLeft(2, '0')}:${message.at.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool listening;
  final bool enabled;
  final Color color;
  final VoidCallback onMicTap;
  final VoidCallback onSend;

  const _InputBar({
    required this.label,
    required this.controller,
    required this.listening,
    required this.enabled,
    required this.color,
    required this.onMicTap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: enabled ? onMicTap : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: listening
                        ? AppColors.red
                        : color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    listening ? Icons.mic : Icons.mic_none,
                    color: listening ? Colors.white : color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  decoration: InputDecoration(
                    hintText:
                        listening ? 'Écoute en cours…' : 'Écrire ou parler…',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.bgPage,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: enabled ? onSend : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
