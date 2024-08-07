// ignore_for_file: prefer_const_constructors,prefer_const_literals_to_create_immutables

import 'package:card_todo/utils/widget/button_floating_action/bloc_button/button_animation_bloc.dart';
import 'package:card_todo/utils/widget/button_floating_action/widget_button_animation.dart';
import 'package:card_todo/utils/widget/button_floating_action/widget_button_animation_helper.dart';
import 'package:card_todo/data/model/modelTodo.dart';
import 'package:card_todo/app/todo/main_menu/main_menu_bloc/mainmenu_bloc.dart';
import 'package:card_todo/app/todo/task_list/bloc_task/task_menu_bloc.dart';
import 'package:card_todo/utils/widget/widget_app_bar.dart';
import 'package:card_todo/utils/widget/widget_dialog_add.dart';
import 'package:card_todo/utils/widget/widget_task_page.dart';
import 'package:card_todo/config/icon/todo_app_icon_icons.dart';
import 'package:card_todo/utils/static/color_class.dart';
import 'package:card_todo/core/enums/enum_todo.dart';
import 'package:card_todo/utils/static/size_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.titleTask, required this.keyValue});
  final String titleTask;
  final String keyValue;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  Sizing sizing = Sizing();
  @override
  Widget build(BuildContext context) {
    sizing.init(context);
    double paddingHorizontal = sizing.widthCalc(percent: 12);
    double heightAppBar = 70;
    final mainMenuBloc = context.read<MainMenuBloc>();
    context
        .read<TaskMenuBloc>()
        .initBloc(RepositoryProvider.of<ButtonAnimationBloc>(context));

    return WillPopScope(
      onWillPop: () async {
        mainMenuBloc.add(InitialListEvent());
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(heightAppBar),
          child: CustomAppBar(
            heightAppBar: heightAppBar,
            paddingHorizontal: paddingHorizontal / 2,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.titleTask,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: BlocBuilder<TaskMenuBloc, TaskMenuState>(
                builder: (context, state) {
                  return Text(
                    ' Today you have ${state.sumTask} tasks',
                    style: TextStyle(fontSize: 12),
                  );
                },
              ),
              trailing: GestureDetector(
                onTap: () {
                  mainMenuBloc.add(InitialListEvent());
                  Navigator.of(context).pop();
                },
                child: Icon(
                  TodoAppIcon.previous,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        floatingActionButton:
            BlocBuilder<ButtonAnimationBloc, ButtonAnimationState>(
          builder: (context, state) {
            final buttonAnimationBloc = context.read<ButtonAnimationBloc>();
            if (state is ButtonEmptyState) {
              return const SizedBox();
            }
            if (state.actionEnum == ActionEnum.action &&
                state is ButtonActionState) {
              return LinearFlowWidget(
                isAction: state.isAction,
                whichTodoBloc: buttonAnimationBloc.whichTodoBloc,
              );
            }
            if (state.actionEnum == ActionEnum.action &&
                state is! ButtonActionState) {
              return LinearFlowWidget(
                isAction: false,
                whichTodoBloc: buttonAnimationBloc.whichTodoBloc,
              );
            }
            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DoneButton(
                  actionEnum: state.actionEnum,
                ),
              ),
            );
          },
        ),
        body: BlocBuilder<TaskMenuBloc, TaskMenuState>(
          builder: (context, state) {
            final taskMenuBloc = context.read<TaskMenuBloc>();
            List<TaskList> taskList = state.taskList;

            ///reordered state
            if (state is TaskReorderState) {
              int i = -1;
              return ReorderableColumn(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal)
                    .copyWith(top: 30),
                onReorder: (oldIndex, newIndex) {
                  taskMenuBloc.add(
                    TaskReorderedProcess(
                        oldIndex: oldIndex, newIndex: newIndex),
                  );
                },
                children: state.taskListFalse
                    .map((e) {
                      i++;
                      return TileTaskCard(
                          key: ValueKey(i),
                          isChecked: e.isChecked,
                          title: e.title,
                          isDelete: false,
                          onchanged: () {});
                    })
                    .toList()
                    .cast<Widget>(),
              );
            }

            /// Delete state
            if (state is TaskDeleteState) {
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal)
                    .copyWith(top: 30),
                itemCount: state.taskList.length,
                itemBuilder: (context, index) {
                  bool isChecked = taskList[index].isChecked;
                  bool isDelete = state.isRedList[index];
                  String title = taskList[index].title;
                  return TileTaskCard(
                      onTapDelete: () {
                        context
                            .read<TaskMenuBloc>()
                            .add(TaskDeleteProcess(index: index));
                      },
                      color: isDelete
                          ? const Color(0xFFFF6961)
                          : Color(0xFFFFFFFF),
                      isChecked: isChecked,
                      title: title,
                      isDelete: true,
                      onchanged: () {});
                },
              );
            }

            // if (state is! TaskDeleteState) {
            //   isDelete = false;
            // }

            /// it will build if not reordered
            if (state.taskList.isNotEmpty) {
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal)
                    .copyWith(top: 30),
                itemCount: state.taskList.length,
                itemBuilder: (context, index) {
                  bool isChecked = taskList[index].isChecked;
                  String title = taskList[index].title;
                  return TileTaskCard(
                    isChecked: isChecked,
                    title: title,
                    isDelete: false,
                    onchanged: () {
                      taskMenuBloc.add(TaskEvent(
                          isChecked: isChecked, title: title, index: index));
                    },
                  );
                },
              );
            }
            // For addin if list null
            return Align(
              alignment: Alignment.center,
              child: IconButton(
                onPressed: () {
                  final taskList = state.taskList;
                  final listOfFindingTrue =
                      taskList.map((e) => e.title).toList();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      backgroundColor: ColorStatic.maincolor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      content: MainDialog(
                        taskMenuBloc: taskMenuBloc,
                        parentContext: context,
                        listData: listOfFindingTrue,
                        title: 'Add Task',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  TodoAppIcon.add,
                  color: Colors.black.withOpacity(0.3),
                  size: sizing.isPotrait ? 50 : 30,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
