class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

const String kLegalLastUpdated = 'October 19, 2026';

const String kLegalContact = 'the TubiLearn project team';

const List<LegalSection> kTermsSections = <LegalSection>[
  LegalSection(
    'About TubiLearn',
    'TubiLearn is a skill-swapping app built as a school project. It lets people teach what they know and learn from others, with no payment involved. It is provided as is, may change or stop at any time, and is not a commercial service.',
  ),
  LegalSection(
    'Your account',
    'You can sign up with an email and password or with Google. You must be at least 13 years old. Give accurate information, keep your login private, and remember that you are responsible for what happens under your account.',
  ),
  LegalSection(
    'Skill swaps',
    "Swaps are arranged directly between users and no money is exchanged. TubiLearn does not verify anyone's identity, skills, or teaching quality, and cannot guarantee any session. If you meet in person, choose a safe public place and use your own judgment. Do not share passwords or sensitive personal information.",
  ),
  LegalSection(
    'Be respectful',
    "Do not harass, threaten, or discriminate against others. Do not post spam, impersonate someone, share illegal or sexual content, or share another person's private information. Do not record a video call without everyone's consent. Do not try to break, overload, or misuse the app.",
  ),
  LegalSection(
    'Your content',
    'Your profile, skills, messages, and reviews stay yours. You allow TubiLearn to store them and show them to other users as needed to run the app. Reviews should be honest and based on a real swap.',
  ),
  LegalSection(
    'AI Match',
    'Smart Match and AI Match give suggestions, and AI Match is written by an AI model that can be wrong. Treat it as a guide only. The decision to swap with someone is always yours.',
  ),
  LegalSection(
    'Video calls',
    'Video calls use your camera and microphone only after you allow it, and run through a third-party video service. This feature is a prototype and may be unavailable or unreliable.',
  ),
  LegalSection(
    'Removing content or accounts',
    'We may remove content or suspend accounts that break these terms. You can log out at any time and delete your own skills, swap requests, and conversations in the app. To ask for your account to be deleted, contact $kLegalContact.',
  ),
  LegalSection(
    'No warranty',
    'TubiLearn is provided as is, without promises that it will always work or be error-free. To the extent allowed by law, the project team is not responsible for losses from using the app or from meeting other users.',
  ),
  LegalSection(
    'Changes and governing law',
    'We may update these terms, and using the app after an update means you accept it. These terms are governed by the laws of the Philippines.',
  ),
  LegalSection(
    'Contact',
    'Questions about these terms can be sent to $kLegalContact.',
  ),
];

const List<LegalSection> kPrivacySections = <LegalSection>[
  LegalSection(
    'What we collect',
    'Account: your name, email, a sign-in ID, and whether your email is verified (and your Google name and email if you use Google sign-in). Profile: name, city, bio, availability, language, preferred mode, teaching style, and the year you joined. Skills: the skills you offer or want to learn, with level and availability. Swaps: who is involved, the skills, proposed schedule, mode, meeting details, note, and status. Chats: the text of your messages. Reviews: rating, optional comment, and your name as reviewer.',
  ),
  LegalSection(
    'What stays on your device',
    'Your profile photo is kept only on your device and is never uploaded, so other users cannot see it. App preferences such as notifications, language, and theme are also kept on your device. Uninstalling the app removes them.',
  ),
  LegalSection(
    'Who can see your information',
    'Other signed-in users can see your public profile details and skills in Explore once your profile is set up: name, city, bio, availability, language, preferred mode, teaching style, and your skills. Your email is not shown on your profile. Swap requests are visible to the two people involved, and chat messages are visible to the people in that conversation. Reviews can be seen by other users.',
  ),
  LegalSection(
    'AI Match',
    "When you analyze a match, TubiLearn sends a summary to Google's Gemini model through Firebase AI Logic. For you and the other user, this includes offered and wanted skill titles, preferred mode, teaching style, language, availability, and simple match flags such as same city. Names, emails, bios, city names, messages, and photos are not sent. This means some of the other user's preferences are processed by Google as part of the analysis.",
  ),
  LegalSection(
    'Services we use',
    "Firebase Authentication and Cloud Firestore (Google) store your account and app data. Google Sign-In handles Google login. Google's Gemini handles AI Match. Agora carries live audio and video during calls, and TubiLearn does not record calls.",
  ),
  LegalSection(
    'Security',
    'Your data is protected by your login and by Firebase security rules, and is sent over secure connections. Chat messages are stored as plain text and are not end-to-end encrypted. No system is completely secure, so do not share passwords or sensitive information in chats.',
  ),
  LegalSection(
    'Keeping and deleting data',
    'Your data is kept while your account exists. You can delete your skills, swap requests, and conversations in the app. To delete your account, profile, and reviews, contact $kLegalContact. Some information, such as messages the other person already has, may remain until they remove it.',
  ),
  LegalSection(
    'Children',
    'TubiLearn is not meant for children under 13.',
  ),
  LegalSection(
    'Changes and contact',
    'We may update this policy and will change the date above when we do. Questions or requests can be sent to $kLegalContact.',
  ),
];
