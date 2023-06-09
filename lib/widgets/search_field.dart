import 'package:appwrite_hackathon/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../utilities/utilities.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final List<TaskStatus> _taskStatuses = [];

  late final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        onSubmitted: (taskName) async {
          await context.read<TaskProvider>().getAllSearchFilterTaskDocuments(
                enteredTaskName: taskName.trim(),
              );
        },
        decoration: InputDecoration(
          hintText: 'Search by task name',
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: IconButton(
            tooltip: 'Filter',
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  _showFilterBottomSheet() {
    final textTheme = Theme.of(context).textTheme;
    bool applying = false;
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(8),
          right: Radius.circular(8),
        ),
      ),
      constraints: const BoxConstraints.tightFor(height: 240),
      builder: (_) {
        return StatefulBuilder(
          builder: (_, bottomSheetSetState) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Filter',
                        style: textTheme.titleLarge!.copyWith(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(Icons.close_outlined),
                    )
                  ],
                ),
                const Divider(
                  color: Colors.blueGrey,
                  height: 2,
                  thickness: 0.5,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: TaskStatus.values.map(
                            (TaskStatus taskStatus) {
                              final isSelected =
                                  _taskStatuses.contains(taskStatus);
                              return FilterChip(
                                selected: isSelected,
                                selectedColor:
                                    getTaskCardBackgroundColor(taskStatus),
                                backgroundColor:
                                    getTaskCardBackgroundColor(taskStatus),
                                label: Text(getTaskStatusName(taskStatus)),
                                shape: const StadiumBorder(side: BorderSide()),
                                avatar: isSelected
                                    ? const SizedBox.shrink()
                                    : Icon(getTaskStatusIcon(taskStatus),
                                        size: 20),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onSelected: (bool selected) {
                                  bottomSheetSetState(() {
                                    if (selected) {
                                      _taskStatuses.add(taskStatus);
                                    } else {
                                      _taskStatuses.remove(taskStatus);
                                    }
                                  });
                                },
                              );
                            },
                          ).toList(),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                applying
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: () async {
                          bottomSheetSetState(() {
                            applying = true;
                          });

                          await context
                              .read<TaskProvider>()
                              .getAllSearchFilterTaskDocuments(
                                selectedTaskStatus: _taskStatuses,
                              );

                          bottomSheetSetState(() {
                            applying = false;
                          });

                          context.pop();
                        },
                        icon: const Icon(Icons.content_paste_search_outlined),
                        label: const Text('Apply'),
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(120, 40)),
                      )
              ],
            );
          },
        );
      },
    );
  }
}
