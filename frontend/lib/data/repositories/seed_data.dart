// lib/data/repositories/seed_data.dart
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../models/chat_message_model.dart';

class SeedData {
  // ── Seed Users ──────────────────────────────────────────────────────────────
  static const UserModel userTerry = UserModel(
    id: 'user_terry',
    name: 'Terry Melton',
    email: 'terry@campus.edu',
    phone: '+1 (555) 012-3456',
    role: 'student',
    trustScore: 88, // Trusted
    itemsReturned: 4,
    itemsRecovered: 2,
    token: 'token_terry_88',
  );

  static const UserModel userSarah = UserModel(
    id: 'user_sarah',
    name: 'Sarah Jenkins',
    email: 'sarah@campus.edu',
    phone: '+1 (555) 019-8765',
    role: 'student',
    trustScore: 64, // Building trust
    itemsReturned: 2,
    itemsRecovered: 1,
    token: 'token_sarah_64',
  );

  static const UserModel userAlex = UserModel(
    id: 'user_alex',
    name: 'Alex Chen',
    email: 'alex@campus.edu',
    phone: '+1 (555) 014-9922',
    role: 'student',
    trustScore: 38, // New account
    itemsReturned: 0,
    itemsRecovered: 0,
    token: 'token_alex_38',
  );

  static const UserModel adminUser = UserModel(
    id: 'user_admin',
    name: 'Dean Reynolds (Campus Admin)',
    email: 'admin@campus.edu',
    phone: '+1 (555) 000-0001',
    role: 'admin', // Admin role!
    trustScore: 100,
    itemsReturned: 15,
    itemsRecovered: 0,
    token: 'token_admin_secret',
  );

  static List<UserModel> get initialUsers => [
        userTerry,
        userSarah,
        userAlex,
        adminUser,
      ];

  // ── Seed Items (Found & Lost) ────────────────────────────────────────────────
  static List<ItemModel> get initialItems => [
        // 1. Found: Leather Bifold Wallet (High-value, Active) - Found by Sarah
        ItemModel(
          id: 'item_f1_wallet',
          type: 'found',
          title: 'Brown Leather Bifold Wallet',
          category: 'wallet',
          description:
              'Found on a study desk on 2nd floor of Central Library. Contains student ID card and cards inside.',
          area: 'Central Campus Library',
          dateTime: DateTime.now().subtract(const Duration(hours: 4)),
          hiddenFields: [
            '3 credit cards and 1 student ID card',
            '\$35 cash and a folded bookstore receipt',
          ],
          status: 'active',
          posterId: 'user_sarah',
          posterName: 'Sarah Jenkins',
          posterTrustScore: 64,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),

        // 2. Found: Midnight Blue iPhone 15 Pro (High-value, Handover pending!) - Found by Terry
        ItemModel(
          id: 'item_f2_iphone',
          type: 'found',
          title: 'Midnight Blue iPhone 15 Pro',
          category: 'phone',
          description:
              'Left behind on a dining table at Main Cafeteria near the smoothie bar.',
          area: 'Main Cafeteria & Food Court',
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          hiddenFields: [
            'Translucent matte case with a holographic moon sticker',
            'Lock screen has an astronomy wallpaper; Verizon carrier',
          ],
          status: 'handover_pending',
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),

        // 3. Found: Dell XPS 15 Laptop (High-value, Claim in progress) - Found by Terry
        ItemModel(
          id: 'item_f3_laptop',
          type: 'found',
          title: 'Dell XPS 15 Silver Laptop',
          category: 'electronics',
          description:
              'Found plugged into the study cubicles in Science Complex Lab 3.',
          area: 'Science Complex (Lab 3)',
          dateTime: DateTime.now().subtract(const Duration(hours: 12)),
          hiddenFields: [
            'Dell XPS 15 with GitHub and Python stickers on the lid',
            'Came in a black felt zip sleeve with USB-C 130W charger',
          ],
          status: 'active', // Has claims waiting for Terry to review!
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),

        // 4. Found: Campus ID Badge (High-value, Pending Admin Review) - Found by Terry
        ItemModel(
          id: 'item_f4_idcard',
          type: 'found',
          title: 'University Student ID & Keycard',
          category: 'documents',
          description:
              'Found on the pathway between Tech Block and Library.',
          area: 'Engineering & Tech Block',
          dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
          hiddenFields: [
            'Computer Science Department student card ending in #4092',
            'Attached to a navy blue campus lanyard',
          ],
          status: 'pending_review', // Demo under review state!
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),

        // 5. Found: Black North Face Backpack (High-value, Active) - Found by Alex
        ItemModel(
          id: 'item_f5_bag',
          type: 'found',
          title: 'Black North Face Surge Backpack',
          category: 'bag',
          description:
              'Found on the bleachers in the Sports Complex after basketball practice.',
          area: 'Sports Complex & Gym',
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          hiddenFields: [
            'Contains organic chemistry binder, water flask, and TI-84 calculator',
            'Small silver carabiner clipped to front daisy chain',
          ],
          status: 'active',
          posterId: 'user_alex',
          posterName: 'Alex Chen',
          posterTrustScore: 38,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),

        // 6. Found: Silver Mechanical Watch (High-value, Active) - Found by Sarah
        ItemModel(
          id: 'item_f6_watch',
          type: 'found',
          title: 'Silver Seiko Automatic Wristwatch',
          category: 'jewellery',
          description:
              'Found on the sink counter in Student Activity Center 1st floor restroom.',
          area: 'Student Activity Center',
          dateTime: DateTime.now().subtract(const Duration(hours: 18)),
          hiddenFields: [
            'Silver stainless steel with blue sunburst dial and exhibition caseback',
            'Engraved initials "R.K." on the deployment clasp',
          ],
          status: 'active',
          posterId: 'user_sarah',
          posterName: 'Sarah Jenkins',
          posterTrustScore: 64,
          createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        ),

        // 7. Found: Subaru Car Key & Dorm Fob (Low-value, Active) - Found by Sarah
        ItemModel(
          id: 'item_f7_keys',
          type: 'found',
          title: 'Set of 4 Keys with Car Remote',
          category: 'keys',
          description:
              'Found in the grass near South Parking Lot shuttle stop.',
          area: 'South Parking Lot & Shuttle Stop',
          dateTime: DateTime.now().subtract(const Duration(hours: 8)),
          hiddenFields: [
            '4 keys total: 1 Subaru key, 2 brass Yale keys, 1 RFID gym token',
            'Black rubber fob with a red mini Swiss Army knife charm',
          ],
          status: 'active',
          posterId: 'user_sarah',
          posterName: 'Sarah Jenkins',
          posterTrustScore: 64,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),

        // 8. Found: Green Olive Utility Jacket (Low-value, Active) - Found by Alex
        ItemModel(
          id: 'item_f8_jacket',
          type: 'found',
          title: 'Olive Green Canvas Jacket (Size M)',
          category: 'clothing',
          description:
              'Draped over chair #14 in North Lecture Theatre.',
          area: 'North Lecture Theatre',
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          hiddenFields: [
            'Size M, brand Columbia, plaid flannel lining',
            'Left pocket had a pack of spearmint gum and a USB flash drive',
          ],
          status: 'active',
          posterId: 'user_alex',
          posterName: 'Alex Chen',
          posterTrustScore: 38,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),

        // 9. Found: Calculus Textbook & Notebook (Low-value, Resolved) - Found by Terry
        ItemModel(
          id: 'item_f9_book',
          type: 'found',
          title: 'Stewart Calculus 9th Edition Book',
          category: 'books',
          description:
              'Left on bench in University Courtyard. Returned to student successfully.',
          area: 'University Courtyard',
          dateTime: DateTime.now().subtract(const Duration(days: 4)),
          hiddenFields: [
            'Notes for MATH 201 on page 45; professor name Dr. Vance',
            'Blue metallic ruler used as bookmark',
          ],
          status: 'resolved', // Demo resolved item!
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),

        // 10. Found: Bose Noise-Cancelling Headphones (High-value, Pending Admin Review) - Found by Alex
        ItemModel(
          id: 'item_f10_bose',
          type: 'found',
          title: 'Bose QuietComfort 45 Headphones',
          category: 'electronics',
          description:
              'Found in study pod B at Student Activity Center.',
          area: 'Student Activity Center',
          dateTime: DateTime.now().subtract(const Duration(hours: 3)),
          hiddenFields: [
            'Matte black Bose QC45 in original zippered hard case',
            'Auxiliary cable and airplane adapter inside the mesh pocket',
          ],
          status: 'pending_review',
          posterId: 'user_alex',
          posterName: 'Alex Chen',
          posterTrustScore: 38,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),

        // 11. Found: Hydro Flask Water Bottle (Low-value, Rejected by Admin) - Found by Terry
        ItemModel(
          id: 'item_f11_bottle',
          type: 'found',
          title: 'Yellow Hydro Flask 32oz',
          category: 'other',
          description: 'Found somewhere on campus yesterday.',
          area: 'University Courtyard',
          dateTime: DateTime.now().subtract(const Duration(days: 3)),
          hiddenFields: [
            'Yellow 32oz with dent on bottom',
            'Stickers from National Parks',
          ],
          status: 'rejected',
          rejectionReason:
              'Insufficient item details or vague location provided.',
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),

        // ── Lost Items (No verification questions required) ───────────────────
        // 12. Lost: Sony Wireless Earbuds (Active) - Lost by Terry
        ItemModel(
          id: 'item_l1_sony',
          type: 'lost',
          title: 'Sony WF-1000XM4 Earbuds (Silver Case)',
          category: 'electronics',
          description:
              'Lost my silver Sony earbud case somewhere between the Cafeteria and Library quiet zone.',
          area: 'Central Campus Library',
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          status: 'active',
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        ),

        // 13. Lost: Red Leather Cardholder (Active) - Lost by Alex
        ItemModel(
          id: 'item_l2_cardholder',
          type: 'lost',
          title: 'Red Slim Leather Cardholder',
          category: 'wallet',
          description:
              'Has driver license, transit pass, and bank card. Reward offered for safe return!',
          area: 'Engineering & Tech Block',
          dateTime: DateTime.now().subtract(const Duration(hours: 6)),
          status: 'active',
          posterId: 'user_alex',
          posterName: 'Alex Chen',
          posterTrustScore: 38,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),

        // 14. Lost: Scientific Graphing Calculator (Pending Admin Review) - Lost by Terry
        ItemModel(
          id: 'item_l3_calc',
          type: 'lost',
          title: 'TI-84 Plus CE Graphing Calculator (Teal)',
          category: 'electronics',
          description:
              'Teal body with initials T.M. on battery cover. Left in North Lecture Theatre after physics exam.',
          area: 'North Lecture Theatre',
          dateTime: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'pending_review', // Demo lost item under review!
          posterId: 'user_terry',
          posterName: 'Terry Melton',
          posterTrustScore: 88,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),

        // 15. Lost: Prescription Ray-Ban Eyeglasses (Active) - Lost by Sarah
        ItemModel(
          id: 'item_l4_glasses',
          type: 'lost',
          title: 'Tortoiseshell Ray-Ban Prescription Glasses',
          category: 'other',
          description:
              'Lost inside black leather magnetic case at Sports Complex bleachers.',
          area: 'Sports Complex & Gym',
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          status: 'active',
          posterId: 'user_sarah',
          posterName: 'Sarah Jenkins',
          posterTrustScore: 64,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),

        // 16. Lost: Apple Pencil 2nd Gen (Active) - Lost by Alex
        ItemModel(
          id: 'item_l5_pencil',
          type: 'lost',
          title: 'Apple Pencil 2nd Generation',
          category: 'electronics',
          description:
              'Magnetic stylus for iPad, white with custom silicone grip sleeve.',
          area: 'Central Campus Library',
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          status: 'active',
          posterId: 'user_alex',
          posterName: 'Alex Chen',
          posterTrustScore: 38,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  // ── Seed Claims ─────────────────────────────────────────────────────────────
  static List<ClaimModel> get initialClaims => [
        // Claim 1: Alex claiming Terry's iPhone (Approved & Handover Pending with 6-digit code!)
        // Terry is finder, Alex is claimant. Handover code is 849201.
        ClaimModel(
          id: 'claim_1_iphone_alex',
          itemId: 'item_f2_iphone',
          itemTitle: 'Midnight Blue iPhone 15 Pro',
          itemCategory: 'phone',
          claimantId: 'user_alex',
          claimantName: 'Alex Chen',
          claimantTrustScore: 38,
          answers: [
            'Frosted translucent case with an iridescent moon sticker on center back',
            'Lock screen has an astronomy photo with starry sky; Verizon network',
          ],
          finderAnswers: [
            'Translucent matte case with a holographic moon sticker',
            'Lock screen has an astronomy wallpaper; Verizon carrier',
          ],
          matchScore: 92, // Strong match
          status: 'handover_pending',
          handoverOtp: '849201', // 6-digit handover code visible to Alex (claimant)!
          isHighValue: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        ),

        // Claim 2: Sarah claiming Terry's Dell XPS Laptop (Admin passed, waiting for Terry to review!)
        ClaimModel(
          id: 'claim_2_laptop_sarah',
          itemId: 'item_f3_laptop',
          itemTitle: 'Dell XPS 15 Silver Laptop',
          itemCategory: 'electronics',
          claimantId: 'user_sarah',
          claimantName: 'Sarah Jenkins',
          claimantTrustScore: 64,
          answers: [
            'Dell XPS 15, lid has a green Octocat / GitHub sticker and Python logo',
            'Black felt zipper pouch sleeve with genuine Dell 130W USB-C brick',
          ],
          finderAnswers: [
            'Dell XPS 15 with GitHub and Python stickers on the lid',
            'Came in a black felt zip sleeve with USB-C 130W charger',
          ],
          matchScore: 94, // Ranked recommendation!
          status: 'passed_to_finder',
          isHighValue: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),

        // Claim 3: Another student claiming Terry's Dell XPS Laptop (Close match for side-by-side comparison!)
        ClaimModel(
          id: 'claim_3_laptop_rival',
          itemId: 'item_f3_laptop',
          itemTitle: 'Dell XPS 15 Silver Laptop',
          itemCategory: 'electronics',
          claimantId: 'user_rival',
          claimantName: 'David Miller',
          claimantTrustScore: 55,
          answers: [
            'Dell XPS 15 Silver laptop with coding stickers on top',
            'Had a black zip case and standard power cable',
          ],
          finderAnswers: [
            'Dell XPS 15 with GitHub and Python stickers on the lid',
            'Came in a black felt zip sleeve with USB-C 130W charger',
          ],
          matchScore: 82, // Close match
          status: 'passed_to_finder',
          isHighValue: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),

        // Claim 4: Terry claiming Sarah's Leather Bifold Wallet (Awaiting Admin Review!)
        // This demos Terry seeing "Under review" on his claim!
        ClaimModel(
          id: 'claim_4_wallet_terry',
          itemId: 'item_f1_wallet',
          itemTitle: 'Brown Leather Bifold Wallet',
          itemCategory: 'wallet',
          claimantId: 'user_terry',
          claimantName: 'Terry Melton',
          claimantTrustScore: 88,
          answers: [
            'Has 3 credit cards (Chase sapphire, Discover) and student ID with my name Terry Melton',
            'Around \$35 in bills and receipt from Campus Books',
          ],
          finderAnswers: [
            '3 credit cards and 1 student ID card',
            '\$35 cash and a folded bookstore receipt',
          ],
          matchScore: 95,
          status: 'awaiting_admin', // Claimant sees "Under review" while waiting!
          isHighValue: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),

        // Claim 5: Alex claiming Sarah's Seiko Watch (Admin Queue Demo - Awaiting Admin)
        ClaimModel(
          id: 'claim_5_watch_alex',
          itemId: 'item_f6_watch',
          itemTitle: 'Silver Seiko Automatic Wristwatch',
          itemCategory: 'jewellery',
          claimantId: 'user_alex',
          claimantName: 'Alex Chen',
          claimantTrustScore: 38,
          answers: [
            'Silver metal band with dark blue face',
            'Has some initials engraved on the metal lock',
          ],
          finderAnswers: [
            'Silver stainless steel with blue sunburst dial and exhibition caseback',
            'Engraved initials "R.K." on the deployment clasp',
          ],
          matchScore: 78,
          status: 'awaiting_admin',
          isHighValue: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

  // ── Seed Chat Messages ──────────────────────────────────────────────────────
  static List<ChatMessageModel> get initialChatMessages => [
        ChatMessageModel(
          id: 'msg_1',
          claimId: 'claim_1_iphone_alex',
          senderId: 'user_terry',
          senderName: 'Terry Melton',
          text:
              'Hi Alex! Your claim was approved. I have your iPhone safely kept with me.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
        ),
        ChatMessageModel(
          id: 'msg_2',
          claimId: 'claim_1_iphone_alex',
          senderId: 'user_alex',
          senderName: 'Alex Chen',
          text:
              'Thank goodness!! I was panicking all morning. Where can we meet on campus?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
        ),
        ChatMessageModel(
          id: 'msg_3',
          claimId: 'claim_1_iphone_alex',
          senderId: 'user_terry',
          senderName: 'Terry Melton',
          text:
              'How about outside the Central Library front desk at 3:00 PM today? Make sure to bring your student ID and have your handover code ready.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 10)),
        ),
        ChatMessageModel(
          id: 'msg_4',
          claimId: 'claim_1_iphone_alex',
          senderId: 'user_alex',
          senderName: 'Alex Chen',
          text:
              'Perfect! See you there. I have my physical student ID card with me.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 5)),
        ),
      ];
}
