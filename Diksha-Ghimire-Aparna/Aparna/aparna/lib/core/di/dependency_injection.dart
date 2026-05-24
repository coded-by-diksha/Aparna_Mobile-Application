import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/aama_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/aama_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/period_stats_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/aama_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/period_stats_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_greeting_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/store_chat_message_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../domain/usecases/update_profile_photo_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_period_stats_usecase.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/notification/notification_event.dart';
import '../../presentation/bloc/period_tracking/period_tracking_bloc.dart';
import '../../presentation/bloc/aama/aama_bloc.dart';
import '../../presentation/bloc/profile/profile_bloc.dart';
import '../../presentation/bloc/change_password/change_password_bloc.dart';
import '../../presentation/bloc/period_stats/period_stats_bloc.dart';
import '../../presentation/bloc/health/health_bloc.dart';
import '../../presentation/bloc/forgot_password/forgot_password_bloc.dart';
import '../../data/services/cycle_service.dart';
import '../../data/services/health_service.dart';
import '../../domain/repositories/expert_help_repository.dart';
import '../../data/repositories/expert_help_repository_impl.dart';
import '../../presentation/bloc/expert_help/expert_help_bloc.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/admin_service.dart';
import '../../presentation/bloc/notification/notification_bloc.dart';
import '../../presentation/bloc/admin_analytics/admin_analytics_bloc.dart';
import '../../presentation/bloc/admin_dashboard/admin_dashboard_bloc.dart';
import '../../presentation/bloc/cycle_history/cycle_history_bloc.dart';
import '../../data/services/blog_service.dart';
import '../../presentation/bloc/user_blogs/user_blogs_bloc.dart';
import '../../data/services/google_auth_service.dart';
import '../../data/services/session_manager_service.dart';

class DependencyInjection {
  // Data sources
  static final AuthRemoteDataSource authRemoteDataSource = AuthRemoteDataSource();
  static final AamaRemoteDataSource aamaRemoteDataSource = AamaRemoteDataSource();
  static final ProfileRemoteDataSource profileRemoteDataSource = ProfileRemoteDataSource();
  
  // Repositories
  static final AuthRepository authRepository = AuthRepositoryImpl(authRemoteDataSource);
  static final AamaRepository aamaRepository = AamaRepositoryImpl(aamaRemoteDataSource);
  static final ProfileRepository profileRepository = ProfileRepositoryImpl(profileRemoteDataSource);
  static final PeriodStatsRepository periodStatsRepository = PeriodStatsRepositoryImpl();
  
  // Auth Use cases
  static final LoginUseCase loginUseCase = LoginUseCase(authRepository);
  static final RegisterUseCase registerUseCase = RegisterUseCase(authRepository);
  static final LogoutUseCase logoutUseCase = LogoutUseCase(authRepository);
  
  // Aama Use cases
  static final SendMessageUseCase sendMessageUseCase = SendMessageUseCase(aamaRepository);
  static final GetGreetingUseCase getGreetingUseCase = GetGreetingUseCase(aamaRepository);
  static final GetChatHistoryUseCase getChatHistoryUseCase = GetChatHistoryUseCase(aamaRepository);
  static final StoreChatMessageUseCase storeChatMessageUseCase = StoreChatMessageUseCase(aamaRepository);
  
  // Profile Use cases
  static final GetUserProfileUseCase getUserProfileUseCase = GetUserProfileUseCase(profileRepository);
  static final UpdateUserProfileUseCase updateUserProfileUseCase = UpdateUserProfileUseCase(profileRepository);
  static final UpdateProfilePhotoUseCase updateProfilePhotoUseCase = UpdateProfilePhotoUseCase(profileRepository);
  
  // Change Password Use case
  static final ChangePasswordUseCase changePasswordUseCase = ChangePasswordUseCase(authRepository);

  // Period Stats Use cases
  static final GetPeriodStatsUseCase getPeriodStatsUseCase = GetPeriodStatsUseCase(periodStatsRepository);
  
  // Expert Help Repository
  static final ExpertHelpRepository expertHelpRepository = ExpertHelpRepositoryImpl();

  // Services
  static final GoogleAuthService googleAuthService = GoogleAuthService();
  static final SessionManagerService sessionManagerService = SessionManagerService();

  // Blocs
  static AuthBloc createAuthBloc() => AuthBloc(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    authRepository: authRepository,
    googleAuthService: googleAuthService,
    sessionManagerService: sessionManagerService,
  );
  
  // For simplicity, PeriodTrackingBloc doesn't have dependencies for now
  static PeriodTrackingBloc createPeriodTrackingBloc() => PeriodTrackingBloc();
  
  static AamaBloc createAamaBloc() => AamaBloc(
    sendMessageUseCase: sendMessageUseCase,
    getGreetingUseCase: getGreetingUseCase,
    getChatHistoryUseCase: getChatHistoryUseCase,
    storeChatMessageUseCase: storeChatMessageUseCase,
  );
  
  static ProfileBloc createProfileBloc() => ProfileBloc(
    getUserProfileUseCase: getUserProfileUseCase,
    updateUserProfileUseCase: updateUserProfileUseCase,
    updateProfilePhotoUseCase: updateProfilePhotoUseCase,
  );

  static ExpertHelpBloc createExpertHelpBloc() => ExpertHelpBloc(
    expertHelpRepository: expertHelpRepository,
  );
  
  static PeriodStatsBloc createPeriodStatsBloc() => PeriodStatsBloc(
    getPeriodStatsUseCase: getPeriodStatsUseCase,
  );

  static final CycleService cycleService = CycleService();
  static final HealthService healthService = HealthService();

  static HealthBloc createHealthBloc() => HealthBloc(cycleService, healthService);

  static ForgotPasswordBloc createForgotPasswordBloc() => ForgotPasswordBloc(
    authRemoteDataSource: authRemoteDataSource,
  );

  static NotificationBloc createNotificationBloc() => NotificationBloc(
    notificationService: NotificationService(),
  );

  static final AdminService adminService = AdminService();

  static AdminAnalyticsBloc createAdminAnalyticsBloc() => AdminAnalyticsBloc(adminService);

  static AdminDashboardBloc createAdminDashboardBloc() => AdminDashboardBloc();

  static CycleHistoryBloc createCycleHistoryBloc() => CycleHistoryBloc(cycleService);

  static final BlogService blogService = BlogService();

  static UserBlogsBloc createUserBlogsBloc() => UserBlogsBloc(blogService: blogService);

  static ChangePasswordBloc createChangePasswordBloc() => ChangePasswordBloc(
    changePasswordUseCase: changePasswordUseCase,
  );
  
  static List<BlocProvider> getBlocProviders() {
    return [
      BlocProvider<AuthBloc>(create: (context) => createAuthBloc()),
      BlocProvider<PeriodTrackingBloc>(create: (context) => createPeriodTrackingBloc()),
      BlocProvider<AamaBloc>(create: (context) => createAamaBloc()),
      BlocProvider<NotificationBloc>(create: (context) => createNotificationBloc()..add(FetchUnreadCount())),
      BlocProvider<ProfileBloc>(create: (context) => createProfileBloc()),
      BlocProvider<HealthBloc>(create: (context) => createHealthBloc()),
      BlocProvider<UserBlogsBloc>(create: (context) => createUserBlogsBloc()),
    ];
  }
}
