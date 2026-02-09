import 'package:get/get.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/features/html/domain/services/html_service_interface.dart';

class HtmlController extends GetxController implements GetxService {
  final HtmlServiceInterface htmlServiceInterface;
  HtmlController({required this.htmlServiceInterface});

  String? _htmlText;
  String? get htmlText => _htmlText;

  Future<void> getHtmlText(HtmlType htmlType) async {
    _htmlText = null;
    final Response response = await htmlServiceInterface.getHtmlText(htmlType);
    if (response.statusCode == 200) {
      if(response.body != null && (response.body is String) && (response.body as String).isNotEmpty){
        _htmlText = response.body as String;
      }else{
        _htmlText = '';
      }
      if(_htmlText != null && _htmlText!.isNotEmpty) {
        _htmlText = _htmlText!.replaceAll('href=', 'target="_blank" href=');
      }else {
        _htmlText = '';
      }
    }
    update();
  }

}