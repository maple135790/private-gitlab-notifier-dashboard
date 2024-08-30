import 'package:flutter/material.dart';
import 'package:private_gitlab_notifier_dashboard/provider/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  late final Future<bool> createWSChannel;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    createWSChannel = provider.listenBroadcast();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: createWSChannel,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) return const SizedBox();

        final isListeningBroadcast = snapshot.data!;
        if (snapshot.hasError || !isListeningBroadcast) {
          return const Center(
            child: Text('Failed to connect to the server'),
          );
        }
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: const _NotificationList(),
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationProvider, List<NotificationHistory>>(
      selector: (context, provider) => provider.historyList,
      shouldRebuild: (previous, next) {
        return previous.length != next.length;
      },
      builder: (context, historyList, child) {
        return ListView.separated(
          itemCount: historyList.isEmpty ? 1 : historyList.length,
          itemBuilder: (context, index) {
            if (historyList.isEmpty) {
              return const ListTile(
                title: Center(child: Text('No history')),
              );
            }

            final history = historyList[index];
            final title = history.title;
            final body = history.body;
            final timeFormatter = DateFormat('yyyy/MM/dd HH:mm:ss');
            final time = timeFormatter.format(DateTime.now());

            return DefaultTextStyle(
              style: const TextStyle(overflow: TextOverflow.ellipsis),
              child: ListTile(
                title: Text(title),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        body,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(time),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) {
            return Divider(
              color: Theme.of(context).colorScheme.secondary,
            );
          },
        );
      },
    );
  }
}
