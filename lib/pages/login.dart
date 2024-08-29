import 'package:dio/dio.dart';
import 'package:dispatch/global.dart';
import 'package:dispatch/repo.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';

class LoginPageCtr extends GetxController {
  final apiProvider = Get.find<ApiProvider>();
  final localRepo = Get.find<LocalRepo>();
  final globalService = Get.find<GlobalService>();

  final _formKey = GlobalKey<FormState>();
  final username = "".obs;
  final password = "".obs;
  final code = "".obs;
  final isCodeLogin = false.obs;
  final isObscure = true.obs;

  @override
  void onInit() async {
    super.onInit();
    username.value = await localRepo.getAccount();
  }

  void sendEmail() async {
    final form = _formKey.currentState;
    if (!form!.validate()) {
      return;
    }

    form.save();

    await apiProvider.sendEmail(username.value);
    Get.snackbar("消息", "验证码获取成功!");
  }

  void login(BuildContext context) async {
    final form = _formKey.currentState;
    if (!form!.validate()) {
      return;
    }

    form.save();

    final String token;
    if (isCodeLogin.value) {
      token = await apiProvider.codeLogin(username.value, code.value);
    } else {
      token = await apiProvider.userLogin(username.value, password.value);
    }

    await localRepo.setAccount(username.value);
    await localRepo.setToken(token);
    await globalService.syncUserInfo();

    Get.snackbar("消息", "登录成功");
    Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginPageCtr c = Get.put(LoginPageCtr());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: c._formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 110), // 距离顶部一个工具栏的高度
            Container(
              width: 200,
              height: 200,
              child: Image.asset(
                "images/log.png",
              ),
            ),

            const SizedBox(height: 50),
            TextFormField(
              initialValue: c.username.value,
              onSaved: (v) {
                c.username.value = v!;
              },
              decoration: InputDecoration(
                labelText: "用户名",
                hintText: "请输入用户名",
                filled: true,
                fillColor: Colors.white,
              ),
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: "请输入用户名"),
                  FormBuilderValidators.email(errorText: "请输入有效的用户名"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Obx(() {
              if (c.isCodeLogin.value) {
                return TextFormField(
                  onSaved: (v) => c.code.value = v!,
                  decoration: InputDecoration(
                    labelText: "验证码",
                    suffixStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: TextButton(
                      onPressed: c.sendEmail,
                      child: Text("获取验证码"),
                    ),
                  ),
                );
              } else {
                return TextFormField(
                  onSaved: (v) => c.password.value = v!,
                  obscureText: c.isObscure.value,
                  decoration: InputDecoration(
                    labelText: "密码",
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: c.isObscure.value
                            ? Colors.grey
                            : Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () => c.isObscure.value = !c.isObscure.value,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              }
            }),
            const SizedBox(height: 50),
            Align(
              child: SizedBox(
                height: 45,
                width: 270,
                child: ElevatedButton(
                  onPressed: () => c.login(context),
                  child: Text("登录"),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Obx(
              () => Center(
                child: TextButton(
                  onPressed: () {
                    c.isCodeLogin.value = !c.isCodeLogin.value;
                  },
                  child: (c.isCodeLogin.value ? Text("密码登录") : Text("验证码登录")),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
