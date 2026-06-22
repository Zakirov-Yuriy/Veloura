// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Veloura';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get user => 'User';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get skip => 'Skip';

  @override
  String get like => 'Like';

  @override
  String get signIn => 'Sign in';

  @override
  String get next => 'Next';

  @override
  String get start => 'Get started';

  @override
  String get save => 'Save';

  @override
  String get tryAgain => 'Try again';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get newMatchTitle => 'You have a new match';

  @override
  String get noProfilesYet => 'No profiles yet';

  @override
  String get newMatchExcited => 'You have a new match 🔥';

  @override
  String get complaintSent => 'Report sent';

  @override
  String get userBlocked => 'User blocked';

  @override
  String get profileTitle => 'Profile';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get deleteChatTitle => 'Delete chat?';

  @override
  String get deleteChatBody =>
      'The chat will disappear for you. If the other person doesn\'t delete it, it stays on their side.';

  @override
  String deleteFailed(String error) {
    return 'Couldn\'t delete: $error';
  }

  @override
  String get typing => 'Typing...';

  @override
  String get newMatchShort => 'New match';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get userNotFound => 'User not found';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get premiumAccount => 'Premium account';

  @override
  String get myPhotos => 'My photos';

  @override
  String get favorites => 'Favorites';

  @override
  String get blockedUsers => 'Blocked';

  @override
  String get signOut => 'Sign out';

  @override
  String get likesCount => 'Likes';

  @override
  String get matchesCount => 'Matches';

  @override
  String get friendsCount => 'Friends';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get gladToSeeYou => 'We\'re glad to see you again';

  @override
  String get emailOrPhone => 'Email or phone';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get or => 'or';

  @override
  String get noAccount => 'No account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get createAccount => 'Create an account';

  @override
  String get startYourJourney => 'Start your journey';

  @override
  String get name => 'Name';

  @override
  String get acceptTerms => 'I accept the Terms of Use and Privacy Policy';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get resetSubtitle =>
      'Enter your email and we\'ll send a password reset link';

  @override
  String get sendLink => 'Send link';

  @override
  String get rememberedPassword => 'Remembered your password? ';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailBody(String email) {
    return 'If an account with $email exists, we\'ve sent a password reset link. Don\'t forget to check your Spam folder.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get sendAgain => 'Send again';

  @override
  String get validationEnterEmail => 'Enter your email';

  @override
  String get validationInvalidEmail => 'Invalid email';

  @override
  String get validationEnterPassword => 'Enter your password';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get validationEnterName => 'Enter your name';

  @override
  String get validationNameTooShort => 'Name is too short';

  @override
  String get validationUserNotFound => 'No user found with this email';

  @override
  String get validationWrongPassword => 'Wrong password';

  @override
  String get validationInvalidCredentials => 'Invalid email or password';

  @override
  String get validationAccountDisabled => 'This account is disabled';

  @override
  String get validationEmailInUse => 'This email is already registered';

  @override
  String get validationWeakPassword =>
      'Password is too weak, at least 6 characters';

  @override
  String get validationTooManyAttempts => 'Too many attempts. Try again later';

  @override
  String get validationNoInternet => 'No internet connection';

  @override
  String get validationMethodUnavailable =>
      'This sign-in method is currently unavailable';

  @override
  String get validationRequestFailed =>
      'Request failed. Check your details and try again';

  @override
  String get validationAuthError => 'Authorization error. Please try again';

  @override
  String get validationSomethingWrong =>
      'Something went wrong. Please try again';

  @override
  String get onboard1Title => 'Premium dating';

  @override
  String get onboard1Body => 'We create a space for successful people';

  @override
  String get onboard2Title => 'Safety and privacy';

  @override
  String get onboard2Body => 'We verify every profile for your peace of mind';

  @override
  String get onboard3Title => 'Quality above all';

  @override
  String get onboard3Body => 'Only real people and genuine connections';

  @override
  String get myProfile => 'My profile';

  @override
  String get photos => 'Photos';

  @override
  String get nameCaps => 'NAME';

  @override
  String get ageCaps => 'AGE';

  @override
  String get ageField => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get lookingForCaps => 'LOOKING FOR';

  @override
  String get lookingForField => 'Who I\'m looking for';

  @override
  String get manAccusative => 'A man';

  @override
  String get womanAccusative => 'A woman';

  @override
  String get partnerAgeCaps => 'PARTNER\'S AGE';

  @override
  String get yourCityCaps => 'YOUR CITY';

  @override
  String get cityField => 'City';

  @override
  String get aboutCaps => 'ABOUT ME';

  @override
  String get aboutField => 'About me';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get blockedTitle => 'Blocked';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get unblock => 'Unblock';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get splashTagline => 'find your other half';

  @override
  String get iAmCaps => 'I AM';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get deleteMessageTitle => 'Delete message?';

  @override
  String get deleteMessageBody => 'The message will be permanently deleted.';

  @override
  String get photoFromGallery => 'Photo from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get videoFromGallery => 'Video from gallery';

  @override
  String get videoTooLarge => 'Video is too large (max ~95 MB)';

  @override
  String sendFailed(String error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String sendVoiceFailed(String error) {
    return 'Couldn\'t send voice message: $error';
  }

  @override
  String get today => 'Today';

  @override
  String get chatTitle => 'Chat';

  @override
  String get writeFirstMessage => 'Write the first message';

  @override
  String get noMicAccess => 'No microphone access';

  @override
  String get recordingTooShort => 'Recording too short';

  @override
  String get messageHint => 'Message';

  @override
  String get recording => 'Recording…';

  @override
  String get voiceLoadFailed => 'Couldn\'t load voice message';

  @override
  String get month1 => 'January';

  @override
  String get month2 => 'February';

  @override
  String get month3 => 'March';

  @override
  String get month4 => 'April';

  @override
  String get month5 => 'May';

  @override
  String get month6 => 'June';

  @override
  String get month7 => 'July';

  @override
  String get month8 => 'August';

  @override
  String get month9 => 'September';

  @override
  String get month10 => 'October';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'December';
}
