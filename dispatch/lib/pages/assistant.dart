import 'package:dispatch/dao.dart';
import 'package:dispatch/global.dart';
import 'package:dispatch/repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AssistantCtr extends GetxController {
  final global = Get.find<GlobalService>();
  final appDao = Get.find<AppDao>();
  final localRepo = Get.find<LocalRepo>();

  @override
  void onInit() async {
    super.onInit();
    await localRepo.setUnInit();

    if (!await localRepo.isInit()) {
      await global.loadApp();
      await localRepo.setInit();
    }
  }

  void onCopy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }
}

class AssistantPage extends StatelessWidget {
  AssistantPage({super.key});

  final c = Get.put(AssistantCtr());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: c.global.loadApp,
      child: StreamBuilder(
        stream: c.appDao.findAll(),
        builder:
            (BuildContext context, AsyncSnapshot<List<AppEntity>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView.separated(
            separatorBuilder: (context, index) => Divider(
                height: 15,
                color: Colors.grey.withOpacity(0.2),
                indent: 10,
                endIndent: 10),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final app = data[index];
              return Container(
                child: ListTile(
                  shape: ShapeBorder.lerp(
                    null,
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    1,
                  ),
                  selected: app.enable,
                  selectedTileColor: Colors.greenAccent.withOpacity(0.2),
                  style: ListTileStyle.list,
                  onTap: () => c.appDao.updateEnable(app.id!, !app.enable),
                  title: Text(app.name),
                  leading: Padding(
                      padding: EdgeInsets.all(5),
                      child: Image(image: MemoryImage(app.icon))),
                  trailing: Builder(
                    builder: (BuildContext context) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(builder: (BuildContext context) {
                            if (app.isCut) {
                              return TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => c.global.enableAppNetwork(app),
                                child: Text("网络断开"),
                              );
                            } else {
                              return TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                                onPressed: () => c.global.closeAppNetwork(app),
                                child: Text("网络正常"),
                              );
                            }
                          }),
                          PopupMenuButton<String>(
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<String>>[
                                PopupMenuItem(
                                  child: Text("复制链接"),
                                  onTap: () => c.onCopy(app.promotionLink),
                                )
                              ];
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
