import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';


abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

 
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// In en, this message translates to:
  /// **'Aparna'**
  String get appName;


  /// **'Manage Your account'**
  String get manageYourAccount;


  /// **'Profile'**
  String get profile;

  
  /// **'Days'**
  String get days;


  /// **'Cycles'**
  String get cycles;

  /// **'Avg Length'**
  String get avgLength;


  /// **'Account'**
  String get account;


  /// **'Personal Information'**
  String get personalInformation;

  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @turnOnNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn On Notifications'**
  String get turnOnNotificationsTitle;

  /// No description provided for @turnOnNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to turn on notifications? You will receive reminders and updates from Aparna.'**
  String get turnOnNotificationsMessage;

  /// No description provided for @turnOffNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Notifications'**
  String get turnOffNotificationsTitle;

  /// No description provided for @turnOffNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to turn off notifications? You will no longer receive reminders, period alerts, or other updates.'**
  String get turnOffNotificationsMessage;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications have been enabled.'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications have been disabled.'**
  String get notificationsDisabled;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. You can enable it in your device settings.'**
  String get notificationPermissionDenied;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @cycleSettings.
  ///
  /// In en, this message translates to:
  /// **'Cycle settings'**
  String get cycleSettings;

  /// No description provided for @connectedWatch.
  ///
  /// In en, this message translates to:
  /// **'Connected watch'**
  String get connectedWatch;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  
  /// **'Contact'**
  String get contact;

 
  /// **'Contact health expert'**
  String get contactHealthExpert;


  /// **'Log Out'**
  String get logOut;

  /// **'Home'**
  String get home;


  /// **'Health'**
  String get health;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @whatCanIDoForYou.
  ///
  /// In en, this message translates to:
  /// **'What can I do for you today?'**
  String get whatCanIDoForYou;

  /// No description provided for @askAama.
  ///
  /// In en, this message translates to:
  /// **'Ask aama...'**
  String get askAama;

  /// No description provided for @talkToAama.
  ///
  /// In en, this message translates to:
  /// **'Talk to Aama'**
  String get talkToAama;

  /// No description provided for @askYourQuery.
  ///
  /// In en, this message translates to:
  /// **'Ask your query'**
  String get askYourQuery;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @healthSync.
  ///
  /// In en, this message translates to:
  /// **'Health Sync'**
  String get healthSync;

  /// No description provided for @syncYourHealth.
  ///
  /// In en, this message translates to:
  /// **'Sync your health data'**
  String get syncYourHealth;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @cycleTracking.
  ///
  /// In en, this message translates to:
  /// **'Cycle Tracking'**
  String get cycleTracking;

  /// No description provided for @nextPeriodIn.
  ///
  /// In en, this message translates to:
  /// **'Next period in'**
  String get nextPeriodIn;

  /// No description provided for @currentPhase.
  ///
  /// In en, this message translates to:
  /// **'Current phase'**
  String get currentPhase;

  /// No description provided for @healthArticles.
  ///
  /// In en, this message translates to:
  /// **'Health Articles'**
  String get healthArticles;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePhoto;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @summaryRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a summary of your recent activity'**
  String get summaryRecentActivity;

  /// No description provided for @periodStarted.
  ///
  /// In en, this message translates to:
  /// **'Period Started'**
  String get periodStarted;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @previousStats.
  ///
  /// In en, this message translates to:
  /// **'Previous Stats'**
  String get previousStats;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more >>'**
  String get seeMore;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stats available'**
  String get noStatsAvailable;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @trackYourHealth.
  ///
  /// In en, this message translates to:
  /// **'Track your health journey'**
  String get trackYourHealth;

  /// No description provided for @menstrualCycle.
  ///
  /// In en, this message translates to:
  /// **'Menstrual Cycle'**
  String get menstrualCycle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalBlogs.
  ///
  /// In en, this message translates to:
  /// **'Total Blogs'**
  String get totalBlogs;

  /// No description provided for @expertClinics.
  ///
  /// In en, this message translates to:
  /// **'Expert Clinics'**
  String get expertClinics;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get activeToday;

  /// No description provided for @weeklyUserActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly User Activity'**
  String get weeklyUserActivity;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @newUserRegistered.
  ///
  /// In en, this message translates to:
  /// **'New user registered'**
  String get newUserRegistered;

  /// No description provided for @blogPostPublished.
  ///
  /// In en, this message translates to:
  /// **'Blog post published'**
  String get blogPostPublished;

  /// No description provided for @newClinicAdded.
  ///
  /// In en, this message translates to:
  /// **'New clinic added'**
  String get newClinicAdded;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @blogPosts.
  ///
  /// In en, this message translates to:
  /// **'Blog Posts'**
  String get blogPosts;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @searchBlogs.
  ///
  /// In en, this message translates to:
  /// **'Search blogs...'**
  String get searchBlogs;

  /// No description provided for @noBlogPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No blog posts yet'**
  String get noBlogPostsYet;

  /// No description provided for @createFirstBlogPost.
  ///
  /// In en, this message translates to:
  /// **'Create your first blog post'**
  String get createFirstBlogPost;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get views;

  /// No description provided for @articleTitle.
  ///
  /// In en, this message translates to:
  /// **'Article Title'**
  String get articleTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @markdownSupported.
  ///
  /// In en, this message translates to:
  /// **'Markdown Supported'**
  String get markdownSupported;

  /// No description provided for @writeYourHeartOut.
  ///
  /// In en, this message translates to:
  /// **'Write your heart out...'**
  String get writeYourHeartOut;

  /// No description provided for @mediaAssets.
  ///
  /// In en, this message translates to:
  /// **'Media Assets'**
  String get mediaAssets;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @blogSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Blog saved successfully'**
  String get blogSavedSuccess;

  /// No description provided for @failedToSaveBlog.
  ///
  /// In en, this message translates to:
  /// **'Failed to save blog'**
  String get failedToSaveBlog;

  /// No description provided for @failedToLoadBlogs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load articles'**
  String get failedToLoadBlogs;

  /// No description provided for @blogDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Blog deleted successfully'**
  String get blogDeletedSuccess;

  /// No description provided for @failedToDeleteBlog.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete blog'**
  String get failedToDeleteBlog;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @usersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Users will appear here'**
  String get usersAppearHere;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @disableUser.
  ///
  /// In en, this message translates to:
  /// **'Disable User'**
  String get disableUser;

  /// No description provided for @enableUser.
  ///
  /// In en, this message translates to:
  /// **'Enable User'**
  String get enableUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @areYouSureDisableUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable {username}?'**
  String areYouSureDisableUser(Object username);

  /// No description provided for @areYouSureEnableUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enable {username}?'**
  String areYouSureEnableUser(Object username);

  /// No description provided for @areYouSureDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {username}? This action cannot be undone.'**
  String areYouSureDeleteUser(Object username);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @analyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Analytics Overview'**
  String get analyticsOverview;

  /// No description provided for @userGrowth.
  ///
  /// In en, this message translates to:
  /// **'User Growth'**
  String get userGrowth;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @appUsage.
  ///
  /// In en, this message translates to:
  /// **'App Usage'**
  String get appUsage;

  /// No description provided for @chartComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chart Coming Soon'**
  String get chartComingSoon;

  /// No description provided for @newThisWeek.
  ///
  /// In en, this message translates to:
  /// **'New This Week'**
  String get newThisWeek;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @addClinic.
  ///
  /// In en, this message translates to:
  /// **'Add Clinic'**
  String get addClinic;

  /// No description provided for @searchClinics.
  ///
  /// In en, this message translates to:
  /// **'Search clinics...'**
  String get searchClinics;

  /// No description provided for @noClinicsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No clinics registered'**
  String get noClinicsRegistered;

  /// No description provided for @addYourFirstClinic.
  ///
  /// In en, this message translates to:
  /// **'Add your first clinic'**
  String get addYourFirstClinic;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettings;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @enablePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications for all users'**
  String get enablePushNotifications;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @putAppMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Put app in maintenance mode'**
  String get putAppMaintenance;

  /// No description provided for @allowNewRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Allow New Registrations'**
  String get allowNewRegistrations;

  /// No description provided for @allowNewUsersRegister.
  ///
  /// In en, this message translates to:
  /// **'Allow new users to register'**
  String get allowNewUsersRegister;

  /// No description provided for @appConfiguration.
  ///
  /// In en, this message translates to:
  /// **'App Configuration'**
  String get appConfiguration;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearAllCachedData.
  ///
  /// In en, this message translates to:
  /// **'Clear all cached data'**
  String get clearAllCachedData;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup Database'**
  String get backupDatabase;

  /// No description provided for @createDatabaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of the database'**
  String get createDatabaseBackup;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View application logs'**
  String get viewLogs;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changeAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Change Admin Password'**
  String get changeAdminPassword;

  /// No description provided for @updateAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your admin password'**
  String get updateAdminPassword;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// No description provided for @viewManageActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'View and manage active sessions'**
  String get viewManageActiveSessions;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @blogs.
  ///
  /// In en, this message translates to:
  /// **'Blogs'**
  String get blogs;

  /// No description provided for @clinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get clinics;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orSeparator;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @googleSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In integration is coming soon!'**
  String get googleSignInComingSoon;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Aparna Community'**
  String get joinCommunity;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseEnterUsername;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be at least 10 digits'**
  String get phoneTooShort;

  /// No description provided for @pleaseSelectDOB.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get pleaseSelectDOB;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the username or the email linked to your account.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @pleaseEnterEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or username'**
  String get pleaseEnterEmailOrUsername;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmail;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOTP;

  /// No description provided for @otpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification code to'**
  String get otpSentMessage;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didNotReceiveCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resendCodeIn;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @enterCompleteOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP'**
  String get enterCompleteOTP;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previous passwords.'**
  String get resetPasswordSubtitle;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @userStories.
  ///
  /// In en, this message translates to:
  /// **'User stories'**
  String get userStories;

  /// No description provided for @articles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @noCoverImage.
  ///
  /// In en, this message translates to:
  /// **'No cover image'**
  String get noCoverImage;

  /// No description provided for @noArticlesYet.
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get noArticlesYet;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @deleteBlogConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this blog post?'**
  String get deleteBlogConfirmation;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} mins ago'**
  String minsAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hour(s) ago'**
  String hoursAgo(Object count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} day(s) ago'**
  String daysAgo(Object count);

  /// No description provided for @dashboardError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get dashboardError;

  /// No description provided for @manageBlog.
  ///
  /// In en, this message translates to:
  /// **'Manage Blog'**
  String get manageBlog;

  /// No description provided for @createAndEditBlogPosts.
  ///
  /// In en, this message translates to:
  /// **'Create and edit blog posts'**
  String get createAndEditBlogPosts;

  /// No description provided for @searchForBlogs.
  ///
  /// In en, this message translates to:
  /// **'Search for Blogs'**
  String get searchForBlogs;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @totalBlogsCount.
  ///
  /// In en, this message translates to:
  /// **'Total Blogs: {count}'**
  String totalBlogsCount(Object count);

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @managePartnerClinics.
  ///
  /// In en, this message translates to:
  /// **'Manage Partner Clinics'**
  String get managePartnerClinics;

  /// No description provided for @searchForClinics.
  ///
  /// In en, this message translates to:
  /// **'Search for Clinics'**
  String get searchForClinics;

  /// No description provided for @noExpertsFound.
  ///
  /// In en, this message translates to:
  /// **'No experts found'**
  String get noExpertsFound;

  /// No description provided for @addFirstExpertRegistration.
  ///
  /// In en, this message translates to:
  /// **'Add your first expert assistant registration'**
  String get addFirstExpertRegistration;

  /// No description provided for @noAddressProvided.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddressProvided;

  /// No description provided for @addExpert.
  ///
  /// In en, this message translates to:
  /// **'Add Expert'**
  String get addExpert;

  /// No description provided for @editExpert.
  ///
  /// In en, this message translates to:
  /// **'Edit Expert'**
  String get editExpert;

  /// No description provided for @associateName.
  ///
  /// In en, this message translates to:
  /// **'Associate Name'**
  String get associateName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @contactInfoPhoneEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Info (Phone/Email)'**
  String get contactInfoPhoneEmail;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @clinicImage.
  ///
  /// In en, this message translates to:
  /// **'Clinic image'**
  String get clinicImage;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get pickImage;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @getAddressFromCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Get address from coordinates'**
  String get getAddressFromCoordinates;

  /// No description provided for @enterValidLatLngFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter valid latitude and longitude first'**
  String get enterValidLatLngFirst;

  /// No description provided for @addressFilledFromCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Address filled from coordinates'**
  String get addressFilledFromCoordinates;

  /// No description provided for @couldNotGetAddressForCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Could not get address for these coordinates'**
  String get couldNotGetAddressForCoordinates;

  /// No description provided for @expertSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expert details saved successfully'**
  String get expertSavedSuccess;

  /// No description provided for @deleteExpertTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expert'**
  String get deleteExpertTitle;

  /// No description provided for @expertDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String expertDeleteConfirmation(Object name);

  /// No description provided for @expertDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expert deleted successfully'**
  String get expertDeletedSuccess;

  /// No description provided for @usersAndCycle.
  ///
  /// In en, this message translates to:
  /// **'Users and Cycle'**
  String get usersAndCycle;

  /// No description provided for @viewUserDataAndCycleTracking.
  ///
  /// In en, this message translates to:
  /// **'View user data and cycle tracking'**
  String get viewUserDataAndCycleTracking;

  /// No description provided for @searchForUsers.
  ///
  /// In en, this message translates to:
  /// **'Search for Users'**
  String get searchForUsers;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymousUser;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined: '**
  String get joined;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @userRegistrationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'User registration feature coming soon!'**
  String get userRegistrationComingSoon;

  /// No description provided for @failedToDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user'**
  String get failedToDeleteUser;

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get failedToLoadUsers;

  /// No description provided for @welcomeToAparna.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Aparna'**
  String get welcomeToAparna;

  /// No description provided for @trackYourFlowStayStressFree.
  ///
  /// In en, this message translates to:
  /// **'Track your Flow stay Stress Free.'**
  String get trackYourFlowStayStressFree;

  /// No description provided for @aparnaIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Aparna helps you track your period, ovulation, and fertility with simple reminders and insights.'**
  String get aparnaIntroDescription;

  /// No description provided for @moveIn.
  ///
  /// In en, this message translates to:
  /// **'Move in'**
  String get moveIn;

  /// No description provided for @healthDashboard.
  ///
  /// In en, this message translates to:
  /// **'Health Dashboard'**
  String get healthDashboard;

  /// No description provided for @connectHealthDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect your health device to view dashboard'**
  String get connectHealthDevice;

  /// No description provided for @syncHealthData.
  ///
  /// In en, this message translates to:
  /// **'Sync health data from your fitness device'**
  String get syncHealthData;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity;

  /// No description provided for @activityType.
  ///
  /// In en, this message translates to:
  /// **'Activity Type'**
  String get activityType;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @lastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Last Known Location'**
  String get lastKnownLocation;

  /// No description provided for @connectYourWearable.
  ///
  /// In en, this message translates to:
  /// **'Connect your wearable'**
  String get connectYourWearable;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove Device'**
  String get removeDevice;

  /// No description provided for @removeDeviceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{deviceName}\"? This will disconnect the device and stop syncing health data.'**
  String removeDeviceConfirmation(Object deviceName);

  /// No description provided for @removeDeviceConfirmationParam.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{deviceName}\"? This will disconnect the device and stop syncing health data.'**
  String removeDeviceConfirmationParam(String deviceName);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get lastSynced;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No Devices Found'**
  String get noDevicesFound;

  /// No description provided for @noDevicesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth devices were found nearby. Make sure your device is powered on, nearby, and Bluetooth is enabled.'**
  String get noDevicesFoundMessage;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
