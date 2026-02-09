import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';

class CentralizeLoginHelper {
  static ({CentralizeLoginType type, double size}) getPreferredLoginMethod(CentralizeLoginSetup data, bool isOtpViewEnable, {bool calculateWidth = false}) {
    // Use null-coalescing to treat null as false
    final bool manualLoginStatus = data.manualLoginStatus ?? false;
    final bool otpLoginStatus = data.otpLoginStatus ?? false;
    final bool socialLoginStatus = data.socialLoginStatus ?? false;

    if ((otpLoginStatus && !manualLoginStatus && !socialLoginStatus) || isOtpViewEnable) {
      return (type: CentralizeLoginType.otp, size: 400);
    } else if(manualLoginStatus && !socialLoginStatus && !otpLoginStatus) {
      return (type: CentralizeLoginType.manual, size: 500);
    } else if(socialLoginStatus && !otpLoginStatus && !manualLoginStatus) {
      return (type: CentralizeLoginType.social, size: 500);
    } else if(manualLoginStatus && socialLoginStatus && !otpLoginStatus) {
      return (type: CentralizeLoginType.manualAndSocial, size: 700);
    } else if(manualLoginStatus && socialLoginStatus && otpLoginStatus) {
      return (type: CentralizeLoginType.manualAndSocialAndOtp, size: 700);
    } else if(!manualLoginStatus && socialLoginStatus && otpLoginStatus) {
      return (type: CentralizeLoginType.otpAndSocial, size: 500);
    } else if(manualLoginStatus && !socialLoginStatus && otpLoginStatus) {
      return (type: CentralizeLoginType.manualAndOtp, size: 700);
    } else {
      // Fallback: default to manual login if all are disabled
      // This prevents app crashes when backend config is misconfigured
      return (type: CentralizeLoginType.manual, size: 500);
    }
  }
}