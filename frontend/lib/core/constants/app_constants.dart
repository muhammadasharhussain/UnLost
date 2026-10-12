// lib/core/constants/app_constants.dart

class AppConstants {
  static const String appName = 'Unlost';
  static const String appTagline = 'Campus Lost & Found, Verified & Secured';

  static const String aboutDescription =
      'Unlost is an intelligent campus lost-and-found ecosystem designed to connect finders and seekers safely. '
      'Featuring automated category verification questions, administrative verification queues, high-value handover security codes, '
      'and a community trust scoring system, Unlost ensures that recovered belongings return to their rightful owners.';

  static const List<String> teamCredits = [
    'M. Saad Ahmed',
    'M. Ashar Hussain',
    'Zuha Azhar',
  ];

  static const List<String> campusAreas = [
    'Central Campus Library',
    'Student Activity Center',
    'Engineering & Tech Block',
    'Science Complex (Lab 3)',
    'Main Cafeteria & Food Court',
    'Sports Complex & Gym',
    'North Lecture Theatre',
    'South Parking Lot & Shuttle Stop',
    'Administrative Block',
    'University Courtyard',
  ];

  static const List<String> postRejectionReasons = [
    'Insufficient item details or vague location provided.',
    'Duplicate listing detected on campus feed.',
    'Suspected policy violation or restricted item.',
    'Private verification questions revealed in public description.',
  ];

  static const List<String> claimRejectionReasons = [
    'Answers do not match the item verification profile.',
    'Critical ownership details missing or contradictory.',
    'Unable to confirm claimant identity.',
  ];

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How do I prove an item is mine?',
      'answer':
          'When someone finds an item, they answer two private questions about it (like what is inside a wallet). You will be asked the same questions when you claim it — you do not need exact wording, just answer honestly.'
    },
    {
      'question': 'Why cannot I see my match score?',
      'answer':
          'To keep the process fair, only the finder and the admin can see how closely your answers matched. This stops people from adjusting their answers to game the score.'
    },
    {
      'question': 'Why does my post need approval before it is visible?',
      'answer':
          'Every found and lost post is checked by an admin first, to keep the listings genuine and reduce spam or fake posts.'
    },
    {
      'question': 'What is a handover code?',
      'answer':
          'For valuable items (phones, wallets, IDs, bags, laptops, jewellery), once your claim is approved you will get a 6-digit code. Read it out to the finder in person once they have checked your university ID — this confirms the handover in the app.'
    },
    {
      'question': 'What happens if I make a false claim?',
      'answer':
          'If a finder or admin identifies a claim as clearly fake, your trust score drops. Three fake-claim reports will suspend your account.'
    },
    {
      'question': 'Can I sign up as an admin?',
      'answer':
          'No. Admin accounts are managed separately by the university and are not available through sign-up.'
    },
    {
      'question': 'What if my post is rejected?',
      'answer':
          'You will see the admin\'s reason. You are welcome to post again with clearer details.'
    },
  ];
}
