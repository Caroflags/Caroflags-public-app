import 'dart:math';

final List<String> _statements = [
  'Fun fact: There\'s a photo of a banana in the source code. No one knows who added it, but the app crashes if it\'s removed.',
  'Fun fact: uhm',
  'We are supposed to not say swears in our app, but it is sofa king hard',
  'The 50th year of Carowinds was the most boring thing all they sold was clothing',
  'Rest in peace nighthawk 2004-2025',
  'Fun fact: Kings Dominion and Carowinds shared many similar rides today and in the 1990s due to having the same ownership.',
  'Why does carowinds take out more rides then they put in?',
  'Before Camp snoopy there was planet snoopy, Guess which one is better',
  'Fun fact: Now five companies have owned Carowinds at some point, Carowinds corp, Keco, Paramount, cedar Fair and now six flags.',
  'Fun fact: Kings Dominion and Carowinds have had most of the same ownership over the years, Kings dominion and kings island would be #1 if KI Wasn\'t sold off to a different company before rejoining when paramount bought them.',
  'Yeah capitalize on the alcoholics Carowinds',
  '\$randomStatement',
  'Best way to see what we are cooking is on our bluesky page, go to bluesky and type in caroflags, you will find us.',
  'The shortest file we have is 70- er 71 lines of code.',
  'Six flags is 5 billion dollars in debt',
  'We have a status page, If reviews or something is not loading go to status.caroflags.xyz. if it is not us, uhh have you tried turning it off and on again?',
  'Kings dominion and carowinds had identical coasters called the Racer 75 and Thunder road, Thunder road doesnt exist anymore because of fury 325 but racer 75 still exists!',
  'How the hell does the law work at carowinds',
  'Fun fact: There are 5 six flags parks in texas and 5 in california.',
  'United states canada mexico panama hati jamaica peru republic dominica cuba',
  'This is how i can say im productive while procrastinating',
];

final List<String> _nopasses = [
  'You know passes get you into the park right?',
  'HEY ADD A PASS!',
  'No passes?',
  'The add icon is where you add a pass, trust.',
  '\$noPasses',
  'Null: No passes',
  'You know, They dont need to be season passes right?',
  'final List<String> _nopasses',
  'if user.passes == null: Complain()',
  '01100001 01100100 01100100 00100000 01100001 00100000 01110000 01100001 01110011 01110011',
  '-- this will work when the user adds a pass',
  'NO- NO- PASSES?????',
  "You know historians are going to wonder why you didnt add a pass right?",
];

final List<String> _parkClosed = [
  'The park is closed today, maybe tomorrow?',
  'Awwwwh, the park is closed',
  'Park closed ):',
  'i hoped they aren\'t closed for the season',
  'Guess we are going to walmart instead',
  'park closed, this will affect fishing season',
  'damn it\'s closed',
  'Is carowinds really closed?',
  'I mean, it is closed',
  'AWHHHHH, It\'s closed!',
];

final List<String> _parkOpen = [
  'The park is open today!',
  'YAYYYYYY, the park is open',
  'Park open (:',
  'i hoped they aren\'t closed for the season',
  'Guess we are going to the park!',
  'park open, this will NOT affect fishing season',
  'damn it\'s open!',
  'Is carowinds really open?',
  'it is open!',
  'AHHH, It\'s open!',
];

final String randomStatement =
    _statements[Random().nextInt(_statements.length)];
final String nopasses = _nopasses[Random().nextInt(_nopasses.length)];
