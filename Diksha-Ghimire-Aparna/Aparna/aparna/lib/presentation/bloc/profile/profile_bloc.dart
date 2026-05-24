import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../domain/usecases/update_user_profile_usecase.dart';
import '../../../domain/usecases/update_profile_photo_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final UpdateProfilePhotoUseCase updateProfilePhotoUseCase;

  ProfileBloc({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.updateProfilePhotoUseCase,
  }) : super(ProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<UpdateProfilePhoto>(_onUpdateProfilePhoto);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await getUserProfileUseCase(event.userId, event.token);
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await updateUserProfileUseCase(
        userId: event.userId,
        username: event.username,
        email: event.email,
        phone: event.phone,
        dateOfBirth: event.dateOfBirth,
        profilePhoto: event.profilePhoto,
        token: event.token,
      );
      emit(ProfileUpdated(user: user, message: 'Profile updated successfully'));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfilePhoto(
    UpdateProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await updateProfilePhotoUseCase(
        userId: event.userId,
        photoUrl: event.photoUrl,
        token: event.token,
      );
      emit(ProfileUpdated(user: user, message: 'Profile photo updated successfully'));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
