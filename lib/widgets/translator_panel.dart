import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/translation_language.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

/// Ouvre le traducteur en plein écran (bottom sheet) au-dessus de [context].
///
/// À l'ouverture, le traducteur démarre automatiquement l'écoute de l'agent
/// (français). Quand l'agent parle, sa phrase apparaît en français dans la
/// conversation avec un bouton audio pour faire entendre la traduction dans
/// la langue choisie. Quand l'interlocuteur répond dans sa langue, la
/// traduction française s'affiche directement en texte.
Future<void> showTranslatorPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TranslatorSheet(),
  );
}

enum _Speaker { agent, interlocutor }

class _ChatMessage {
  final String originalText;
  final String originalLangLabel;
  final String translatedText;

  /// Locale à utiliser pour lire [translatedText] à voix haute.
  final String translatedVoiceLocale;
  final String translatedLangLabel;
  final bool fromAgent;
  final DateTime at;

  const _ChatMessage({
    required this.originalText,
    required this.originalLangLabel,
    required this.translatedText,
    required this.translatedVoiceLocale,
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
  final _manualCtrl = TextEditingController();

  _Speaker _speaker = _Speaker.agent;
  bool _micOn = false; // écoute continue active
  bool _listening = false; // capture en cours
  bool _sending = false;
  int? _playingIndex; // bulle dont l'audio est en cours de lecture
  String? _error;

  @override
  void initState() {
    super.initState();
    // Déclenchement automatique de l'écoute de l'agent à l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLive());
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    TtsService.instance.stop();
    _scrollCtrl.dispose();
    _manualCtrl.dispose();
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

  // ── Écoute live ────────────────────────────────────────────────

  Future<void> _startLive() async {
    if (_micOn) return;
    setState(() {
      _micOn = true;
      _error = null;
    });
    await TtsService.instance.stop();
    await _listenOnce();
  }

  Future<void> _stopLive() async {
    setState(() {
      _micOn = false;
      _listening = false;
    });
    await SpeechService.instance.stop();
  }

  /// Une passe d'écoute pour le locuteur actif ; en mode continu, se relance
  /// automatiquement après le traitement de la phrase.
  Future<void> _listenOnce() async {
    if (!_micOn) return;
    final forAgent = _speaker == _Speaker.agent;
    final locale = forAgent
        ? kFrench.speechLocale!
        : (_language.speechLocale ?? kFrench.speechLocale!);

    setState(() => _listening = true);

    final started = await SpeechService.instance.listen(
      localeId: locale,
      onResult: (r) async {
        if (!r.isFinal) return;
        setState(() => _listening = false);
        final text = r.text.trim();
        if (text.isNotEmpty) {
          await _translateAndAdd(text, forAgent: forAgent);
        }
        // Relance l'écoute tant que le mode live est actif et sans erreur.
        if (_micOn && _error == null && mounted) {
          await _listenOnce();
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        _micOn = false;
        _listening = false;
        _error =
            'Reconnaissance vocale indisponible sur cet appareil/navigateur. '
            'Utilisez la saisie manuelle ci-dessous.';
      });
    }
  }

  void _setSpeaker(_Speaker s) {
    if (_speaker == s) return;
    setState(() => _speaker = s);
    if (_micOn) {
      // Redémarre l'écoute dans la langue du nouveau locuteur.
      SpeechService.instance.stop().then((_) {
        if (mounted && _micOn) _listenOnce();
      });
    }
  }

  // ── Traduction ─────────────────────────────────────────────────

  Future<void> _translateAndAdd(String text, {required bool forAgent}) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = forAgent
          ? await TranslationService.instance
              .translate(text: text, source: 'fr', target: _language.code)
          : await TranslationService.instance
              .translate(text: text, source: 'auto', target: 'fr');

      final message = forAgent
          ? _ChatMessage(
              originalText: text,
              originalLangLabel: kFrench.label,
              translatedText: result.translatedText,
              translatedVoiceLocale: _language.voiceLocale,
              translatedLangLabel: _language.label,
              fromAgent: true,
              at: DateTime.now(),
            )
          : _ChatMessage(
              originalText: text,
              originalLangLabel: _labelForCode(result.detectedSourceLanguage),
              translatedText: result.translatedText,
              translatedVoiceLocale: kFrench.voiceLocale,
              translatedLangLabel: kFrench.label,
              fromAgent: false,
              at: DateTime.now(),
            );

      setState(() {
        _messages.add(message);
        if (!forAgent) {
          for (final l in kTranslationLanguages) {
            if (l.code == result.detectedSourceLanguage) _language = l;
          }
        }
      });
      _scrollToBottom();
    } on TranslationException catch (e) {
      setState(() {
        _error = e.message;
        _micOn = false; // stoppe la boucle live sur erreur de traduction
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendManual() async {
    final text = _manualCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _manualCtrl.clear();
    await _translateAndAdd(text, forAgent: _speaker == _Speaker.agent);
  }

  Future<void> _playTranslation(int index) async {
    final msg = _messages[index];
    if (_playingIndex == index) {
      await TtsService.instance.stop();
      setState(() => _playingIndex = null);
      return;
    }
    setState(() => _playingIndex = index);
    final ok = await TtsService.instance
        .speak(msg.translatedText, localeId: msg.translatedVoiceLocale);
    if (mounted) {
      setState(() => _playingIndex = null);
      if (!ok) {
        setState(() => _error =
            'Synthèse vocale indisponible sur cet appareil/navigateur.');
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────

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
              const _Banner(
                color: AppColors.orangeLight,
                textColor: AppColors.orangeText,
                icon: Icons.info_outline,
                text:
                    'Service de traduction non configuré. La reconnaissance vocale '
                    'et la lecture audio fonctionnent ; la traduction texte '
                    'nécessite un fournisseur (voir docs/securite).',
              ),
            if (_error != null)
              _Banner(
                color: AppColors.redLight,
                textColor: AppColors.redText,
                icon: Icons.error_outline,
                text: _error!,
              ),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(listening: _listening)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _Bubble(
                        message: _messages[i],
                        playing: _playingIndex == i,
                        onPlay: () => _playTranslation(i),
                      ),
                    ),
            ),
            _LiveControls(
              speaker: _speaker,
              language: _language,
              micOn: _micOn,
              listening: _listening,
              sending: _sending,
              manualController: _manualCtrl,
              onSpeaker: _setSpeaker,
              onToggleMic: () => _micOn ? _stopLive() : _startLive(),
              onSendManual: _sendManual,
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
            child: Text('Traducteur en direct',
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

class _Banner extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool listening;
  const _EmptyState({required this.listening});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(listening ? Icons.mic : Icons.translate,
              size: 48, color: listening ? AppColors.blue : AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            listening
                ? 'Écoute en cours… parlez en français'
                : 'Appuyez sur le micro pour démarrer la conversation',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  final bool playing;
  final VoidCallback onPlay;

  const _Bubble({
    required this.message,
    required this.playing,
    required this.onPlay,
  });

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

    // L'agent voit sa phrase en français en grand (ce qu'il a dit) + une
    // tuile audio pour faire entendre la traduction. L'interlocuteur voit
    // la traduction française en grand (texte directement lisible).
    final primaryText =
        fromAgent ? message.originalText : message.translatedText;
    final secondaryText =
        fromAgent ? message.translatedText : message.originalText;
    final secondaryLabel =
        fromAgent ? message.translatedLangLabel : message.originalLangLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80),
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
                  Text(primaryText,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg)),
                  const SizedBox(height: 6),
                  // Tuile de traduction + audio.
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                    decoration: BoxDecoration(
                      color: fromAgent
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.bgPage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(secondaryLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: subFg)),
                              const SizedBox(height: 2),
                              Text(secondaryText,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: fg)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AudioButton(
                          playing: playing,
                          onTap: onPlay,
                          onAgent: fromAgent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              '${message.at.hour.toString().padLeft(2, '0')}:${message.at.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  final bool onAgent;

  const _AudioButton({
    required this.playing,
    required this.onTap,
    required this.onAgent,
  });

  @override
  Widget build(BuildContext context) {
    final color = onAgent ? Colors.white : AppColors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onAgent
              ? Colors.white.withValues(alpha: 0.25)
              : AppColors.blueLight,
          shape: BoxShape.circle,
        ),
        child: Icon(playing ? Icons.stop : Icons.volume_up,
            size: 18, color: color),
      ),
    );
  }
}

class _LiveControls extends StatelessWidget {
  final _Speaker speaker;
  final TranslationLanguage language;
  final bool micOn;
  final bool listening;
  final bool sending;
  final TextEditingController manualController;
  final ValueChanged<_Speaker> onSpeaker;
  final VoidCallback onToggleMic;
  final VoidCallback onSendManual;

  const _LiveControls({
    required this.speaker,
    required this.language,
    required this.micOn,
    required this.listening,
    required this.sending,
    required this.manualController,
    required this.onSpeaker,
    required this.onToggleMic,
    required this.onSendManual,
  });

  @override
  Widget build(BuildContext context) {
    final forAgent = speaker == _Speaker.agent;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Sélecteur de locuteur
          Row(
            children: [
              Expanded(
                child: _SpeakerPill(
                  label: 'Vous ${kFrench.flag}',
                  selected: forAgent,
                  color: AppColors.blue,
                  onTap: () => onSpeaker(_Speaker.agent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SpeakerPill(
                  label: 'Interlocuteur ${language.flag}',
                  selected: !forAgent,
                  color: AppColors.purple,
                  onTap: () => onSpeaker(_Speaker.interlocutor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Micro + statut
          Row(
            children: [
              GestureDetector(
                onTap: onToggleMic,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: micOn
                        ? AppColors.red
                        : (forAgent ? AppColors.blue : AppColors.purple),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (micOn)
                        BoxShadow(
                            color: AppColors.red.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2),
                    ],
                  ),
                  child: Icon(micOn ? Icons.stop : Icons.mic,
                      color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sending
                      ? 'Traduction en cours…'
                      : micOn
                          ? (listening
                              ? 'Écoute… ${forAgent ? "parlez en français" : "parlez en ${language.label}"}'
                              : 'En pause…')
                          : 'Appuyez pour parler '
                              '(${forAgent ? "Français" : language.label})',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Saisie manuelle (repli)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: manualController,
                  enabled: !sending,
                  decoration: InputDecoration(
                    hintText: 'Ou écrire ici…',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.bgPage,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => onSendManual(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sending ? null : onSendManual,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: forAgent ? AppColors.blue : AppColors.purple,
                      shape: BoxShape.circle),
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

class _SpeakerPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SpeakerPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.bgPage,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary)),
      ),
    );
  }
}
