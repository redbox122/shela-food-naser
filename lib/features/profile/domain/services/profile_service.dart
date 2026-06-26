import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:sixam_mart/features/profile/domain/services/profile_service_interface.dart';

class ProfileService implements ProfileServiceInterface {
  final ProfileRepositoryInterface profileRepositoryInterface;
  ProfileService({required this.profileRepositoryInterface});

  @override
  Future<UserInfoModel?> getUserInfo({bool forceRefresh = false}) async {
    final result = forceRefresh
        ? await profileRepositoryInterface.getUserInfoForceRefresh()
        : await profileRepositoryInterface.get(null);
    return result is UserInfoModel? ? result : null;
  }

/*  @override
  Future<ResponseModel> updateProfile(UserInfoModel userInfoModel, XFile? data, String token) async {
    return await profileRepositoryInterface.updateProfile(userInfoModel, data, token);
  }*/

  @override
  Future<ResponseModel> updateProfile(UpdateUserModel userInfoModel, XFile? data, String token) async {
    return await profileRepositoryInterface.updateProfile(userInfoModel, data, token);
  }

  @override
  Future<ResponseModel> changePassword(UserInfoModel userInfoModel) async {
    final result = await profileRepositoryInterface.changePassword(userInfoModel);
    return result is ResponseModel ? result : ResponseModel(false, 'Error changing password');
  }

  @override
  Future<Response> deleteUser() async {
    final result = await profileRepositoryInterface.delete(null);
    return result is Response ? result : const Response();
  }

  @override
  Future<XFile?> pickImageFromGallery() async {
    XFile? pickedFile;
    final XFile? pickLogo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickLogo != null) {
      await pickLogo.length().then((value) {
        if(value > 1000000) {
          showCustomSnackBar('please_upload_lower_size_file'.tr);
        }else {
          pickedFile = pickLogo;
        }
      });
    }
    return pickedFile;
  }

}