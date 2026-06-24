/// Localized strings for the reminder call screen and the spoken prompts.
///
/// These drive both the on-screen text and what the TTS voice says, in the
/// user's chosen language. Translations are best-effort and easy to refine —
/// edit the maps below. The task text itself is whatever the user typed and is
/// inserted verbatim into [timePrompt].
class ReminderStrings {
  const ReminderStrings({
    required this.incomingTitle,
    required this.incomingSubtitle,
    required this.accept,
    required this.decline,
    required this.checkingIn,
    required this.askWhen,
    required this.doNow,
    required this.postpone,
    required this.alreadyDone,
    required this.yesDone,
    required this.notYet,
    required this.listening,
    required this.thinking,
    required this.tapToSpeak,
    required this.didntCatch,
    required this.noTimeHeard,
    required String Function(String task) timePromptBuilder,
    required this.confirmPrompt,
  }) : _timePrompt = timePromptBuilder;

  final String incomingTitle;
  final String incomingSubtitle;
  final String accept;
  final String decline;
  final String checkingIn;
  final String askWhen;
  final String doNow;
  final String postpone;
  final String alreadyDone;
  final String yesDone;
  final String notYet;
  final String listening;
  final String thinking;
  final String tapToSpeak;
  final String didntCatch;
  final String noTimeHeard;
  final String Function(String task) _timePrompt;
  final String confirmPrompt;

  String timePrompt(String task) => _timePrompt(task);

  /// Strings for [code] (e.g. 'hi'), falling back to English.
  static ReminderStrings of(String code) => _byCode[code] ?? _byCode['en']!;

  static const Map<String, ReminderStrings> _byCode = {
    'en': ReminderStrings(
      incomingTitle: 'Reminder',
      incomingSubtitle: 'Reminder calling…',
      accept: 'Accept',
      decline: 'Decline',
      checkingIn: 'Checking in…',
      askWhen: 'When should I remind you?',
      doNow: "I'll do it now",
      postpone: 'Postpone',
      alreadyDone: 'Already done',
      yesDone: 'Yes, done',
      notYet: 'Not yet',
      listening: 'Listening…',
      thinking: 'Thinking…',
      tapToSpeak: 'Tap to speak',
      didntCatch: "Sorry, I didn't catch that — please use the buttons.",
      noTimeHeard: "I didn't get a time — pick one below.",
      confirmPrompt: 'Have you done it yet?',
      timePromptBuilder: _enTime,
    ),
    'hi': ReminderStrings(
      incomingTitle: 'रिमाइंडर',
      incomingSubtitle: 'रिमाइंडर कॉल कर रहा है…',
      accept: 'स्वीकारें',
      decline: 'अस्वीकारें',
      checkingIn: 'पुष्टि कर रहे हैं…',
      askWhen: 'मैं आपको कब याद दिलाऊँ?',
      doNow: 'मैं अभी करूँगा',
      postpone: 'बाद में',
      alreadyDone: 'पहले ही हो गया',
      yesDone: 'हाँ, हो गया',
      notYet: 'अभी नहीं',
      listening: 'सुन रहा हूँ…',
      thinking: 'सोच रहा हूँ…',
      tapToSpeak: 'बोलने के लिए टैप करें',
      didntCatch: 'माफ़ कीजिए, समझ नहीं आया — कृपया बटन का उपयोग करें।',
      noTimeHeard: 'समय समझ नहीं आया — नीचे से चुनें।',
      confirmPrompt: 'क्या आपने यह कर लिया?',
      timePromptBuilder: _hiTime,
    ),
    'bn': ReminderStrings(
      incomingTitle: 'রিমাইন্ডার',
      incomingSubtitle: 'রিমাইন্ডার কল করছে…',
      accept: 'গ্রহণ করুন',
      decline: 'প্রত্যাখ্যান করুন',
      checkingIn: 'নিশ্চিত করছি…',
      askWhen: 'আমি কখন আপনাকে মনে করিয়ে দেব?',
      doNow: 'আমি এখনই করব',
      postpone: 'পরে',
      alreadyDone: 'ইতিমধ্যে হয়ে গেছে',
      yesDone: 'হ্যাঁ, হয়েছে',
      notYet: 'এখনো না',
      listening: 'শুনছি…',
      thinking: 'ভাবছি…',
      tapToSpeak: 'বলতে ট্যাপ করুন',
      didntCatch: 'দুঃখিত, বুঝতে পারিনি — অনুগ্রহ করে বোতাম ব্যবহার করুন।',
      noTimeHeard: 'সময় বুঝতে পারিনি — নিচ থেকে বেছে নিন।',
      confirmPrompt: 'আপনি কি এটি করেছেন?',
      timePromptBuilder: _bnTime,
    ),
    'ta': ReminderStrings(
      incomingTitle: 'நினைவூட்டல்',
      incomingSubtitle: 'நினைவூட்டல் அழைக்கிறது…',
      accept: 'ஏற்க',
      decline: 'நிராகரி',
      checkingIn: 'சரிபார்க்கிறேன்…',
      askWhen: 'நான் எப்போது நினைவூட்ட வேண்டும்?',
      doNow: 'இப்போதே செய்கிறேன்',
      postpone: 'பிற்போடு',
      alreadyDone: 'ஏற்கனவே முடிந்தது',
      yesDone: 'ஆம், முடிந்தது',
      notYet: 'இன்னும் இல்லை',
      listening: 'கேட்கிறேன்…',
      thinking: 'யோசிக்கிறேன்…',
      tapToSpeak: 'பேச தட்டவும்',
      didntCatch: 'மன்னிக்கவும், புரியவில்லை — பொத்தான்களைப் பயன்படுத்தவும்.',
      noTimeHeard: 'நேரம் புரியவில்லை — கீழே தேர்ந்தெடுக்கவும்.',
      confirmPrompt: 'நீங்கள் அதை செய்துவிட்டீர்களா?',
      timePromptBuilder: _taTime,
    ),
    'te': ReminderStrings(
      incomingTitle: 'రిమైండర్',
      incomingSubtitle: 'రిమైండర్ కాల్ చేస్తోంది…',
      accept: 'అంగీకరించు',
      decline: 'తిరస్కరించు',
      checkingIn: 'నిర్ధారిస్తున్నాను…',
      askWhen: 'నేను మీకు ఎప్పుడు గుర్తు చేయాలి?',
      doNow: 'నేను ఇప్పుడే చేస్తాను',
      postpone: 'వాయిదా',
      alreadyDone: 'ఇప్పటికే పూర్తయింది',
      yesDone: 'అవును, పూర్తయింది',
      notYet: 'ఇంకా లేదు',
      listening: 'వింటున్నాను…',
      thinking: 'ఆలోచిస్తున్నాను…',
      tapToSpeak: 'మాట్లాడటానికి నొక్కండి',
      didntCatch: 'క్షమించండి, అర్థం కాలేదు — దయచేసి బటన్‌లను ఉపయోగించండి.',
      noTimeHeard: 'సమయం అర్థం కాలేదు — కింద నుండి ఎంచుకోండి.',
      confirmPrompt: 'మీరు దీన్ని చేశారా?',
      timePromptBuilder: _teTime,
    ),
    'mr': ReminderStrings(
      incomingTitle: 'स्मरणपत्र',
      incomingSubtitle: 'स्मरणपत्र कॉल करत आहे…',
      accept: 'स्वीकारा',
      decline: 'नाकारा',
      checkingIn: 'खात्री करत आहे…',
      askWhen: 'मी तुम्हाला कधी आठवण करून देऊ?',
      doNow: 'मी आत्ता करतो',
      postpone: 'नंतर',
      alreadyDone: 'आधीच झाले',
      yesDone: 'हो, झाले',
      notYet: 'अजून नाही',
      listening: 'ऐकत आहे…',
      thinking: 'विचार करत आहे…',
      tapToSpeak: 'बोलण्यासाठी टॅप करा',
      didntCatch: 'माफ करा, समजले नाही — कृपया बटण वापरा.',
      noTimeHeard: 'वेळ समजली नाही — खालून निवडा.',
      confirmPrompt: 'तुम्ही ते केले का?',
      timePromptBuilder: _mrTime,
    ),
    'kn': ReminderStrings(
      incomingTitle: 'ಜ್ಞಾಪನೆ',
      incomingSubtitle: 'ಜ್ಞಾಪನೆ ಕರೆ ಮಾಡುತ್ತಿದೆ…',
      accept: 'ಸ್ವೀಕರಿಸಿ',
      decline: 'ತಿರಸ್ಕರಿಸಿ',
      checkingIn: 'ಖಚಿತಪಡಿಸುತ್ತಿದ್ದೇನೆ…',
      askWhen: 'ನಾನು ನಿಮಗೆ ಯಾವಾಗ ನೆನಪಿಸಲಿ?',
      doNow: 'ನಾನು ಈಗಲೇ ಮಾಡುತ್ತೇನೆ',
      postpone: 'ಮುಂದೂಡಿ',
      alreadyDone: 'ಈಗಾಗಲೇ ಮುಗಿದಿದೆ',
      yesDone: 'ಹೌದು, ಮುಗಿದಿದೆ',
      notYet: 'ಇನ್ನೂ ಇಲ್ಲ',
      listening: 'ಕೇಳುತ್ತಿದ್ದೇನೆ…',
      thinking: 'ಯೋಚಿಸುತ್ತಿದ್ದೇನೆ…',
      tapToSpeak: 'ಮಾತನಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      didntCatch: 'ಕ್ಷಮಿಸಿ, ಅರ್ಥವಾಗಲಿಲ್ಲ — ದಯವಿಟ್ಟು ಬಟನ್‌ಗಳನ್ನು ಬಳಸಿ.',
      noTimeHeard: 'ಸಮಯ ಅರ್ಥವಾಗಲಿಲ್ಲ — ಕೆಳಗಿನಿಂದ ಆಯ್ಕೆಮಾಡಿ.',
      confirmPrompt: 'ನೀವು ಇದನ್ನು ಮಾಡಿದ್ದೀರಾ?',
      timePromptBuilder: _knTime,
    ),
    'gu': ReminderStrings(
      incomingTitle: 'રિમાઇન્ડર',
      incomingSubtitle: 'રિમાઇન્ડર કૉલ કરી રહ્યું છે…',
      accept: 'સ્વીકારો',
      decline: 'નકારો',
      checkingIn: 'ખાતરી કરી રહ્યો છું…',
      askWhen: 'હું તમને ક્યારે યાદ કરાવું?',
      doNow: 'હું હમણાં કરીશ',
      postpone: 'મુલતવી',
      alreadyDone: 'પહેલેથી થઈ ગયું',
      yesDone: 'હા, થઈ ગયું',
      notYet: 'હજી નહીં',
      listening: 'સાંભળું છું…',
      thinking: 'વિચારું છું…',
      tapToSpeak: 'બોલવા માટે ટૅપ કરો',
      didntCatch: 'માફ કરશો, સમજાયું નહીં — કૃપા કરીને બટનનો ઉપયોગ કરો.',
      noTimeHeard: 'સમય સમજાયો નહીં — નીચેથી પસંદ કરો.',
      confirmPrompt: 'શું તમે તે કર્યું?',
      timePromptBuilder: _guTime,
    ),
  };

  static String _enTime(String t) =>
      "It's time to $t. Will you do it now, or postpone?";
  static String _hiTime(String t) =>
      '$t का समय हो गया है। क्या आप इसे अभी करेंगे या बाद में?';
  static String _bnTime(String t) =>
      '$t করার সময় হয়েছে। আপনি কি এখন করবেন নাকি পরে?';
  static String _taTime(String t) =>
      '$t செய்ய நேரம் வந்துவிட்டது. இப்போது செய்வீர்களா அல்லது பிறகா?';
  static String _teTime(String t) =>
      '$t చేయడానికి సమయం వచ్చింది. ఇప్పుడే చేస్తారా లేదా తర్వాతా?';
  static String _mrTime(String t) =>
      '$t करण्याची वेळ झाली आहे. तुम्ही आता कराल का नंतर?';
  static String _knTime(String t) =>
      '$t ಮಾಡುವ ಸಮಯ ಬಂದಿದೆ. ಈಗಲೇ ಮಾಡುತ್ತೀರಾ ಅಥವಾ ನಂತರವೇ?';
  static String _guTime(String t) =>
      '$t કરવાનો સમય થઈ ગયો છે. તમે અત્યારે કરશો કે પછી?';
}
