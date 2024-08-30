import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:private_gitlab_notifier_dashboard/page/home/home_view_model.dart';
import 'package:private_gitlab_notifier_dashboard/page/home/notification_list.dart';

import 'package:private_gitlab_notifier_dashboard/provider/notification_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final viewModel = HomeViewModel();
  final portController = TextEditingController();
  NotificationProvider? notificationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.requestNotificationPermission();
    });
  }

  @override
  void dispose() {
    portController.dispose();
    super.dispose();
  }

  void onPortConnectPressed() {
    assert(isValidPortNumber);
    final port = int.parse(portController.text);
    if (notificationProvider != null && notificationProvider!.isConnected) {
      notificationProvider!.closeWS();
    }
    notificationProvider = NotificationProvider(localPort: port);
    setState(() {});
  }

  void onNotificationTestPressed() {
    NotificationProvider.testNotification();
  }

  void onPortNumberChanged(String value) {
    setState(() {});
  }

  bool get isValidPortNumber {
    final port = int.tryParse(portController.text);
    return port != null && port >= 0 && port <= 65535;
  }

  void onCanSendNotificationChanged(bool setCanSend) {
    if (setCanSend) {
      viewModel.requestNotificationPermission();
    } else {
      viewModel.revokeNotificationPermission();
    }
  }

  void onDisconnectPressed() {
    notificationProvider?.closeWS();
  }

  @override
  Widget build(BuildContext context) {
    final portConnectRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a port number';
              }
              if (!isValidPortNumber) {
                return 'Please enter a valid port number';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.always,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              labelText: 'GitLab-Notify websocket port',
              border: const OutlineInputBorder(),
              suffix: notificationProvider != null
                  ? ChangeNotifierProvider.value(
                      value: notificationProvider,
                      child: Selector<NotificationProvider, bool>(
                        selector: (context, viewModel) {
                          final currentPort = int.tryParse(portController.text);
                          final isPortChanged =
                              viewModel.localPort != currentPort;
                          final isConnnected = viewModel.isConnected;
                          return !isConnnected ||
                              (isPortChanged && isValidPortNumber);
                        },
                        builder: (context, canConnect, child) {
                          return IconButton(
                            icon: const Icon(Icons.send_rounded),
                            onPressed: canConnect ? onPortConnectPressed : null,
                          );
                        },
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed:
                          isValidPortNumber ? onPortConnectPressed : null,
                    ),
            ),
            controller: portController,
            onChanged: onPortNumberChanged,
          ),
        ),
      ],
    );

    return ChangeNotifierProvider.value(
      value: viewModel,
      builder: (context, child) {
        final wsConnectionStatusTile = AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: notificationProvider != null
              ? ChangeNotifierProvider.value(
                  value: notificationProvider,
                  child: Selector<NotificationProvider, bool>(
                    selector: (context, viewModel) => viewModel.isConnected,
                    builder: (context, isConnected, child) {
                      log('isWsConnected: $isConnected');
                      final colorScheme = Theme.of(context).colorScheme;
                      final status = isConnected ? 'Connected' : 'Disconnected';
                      return ListTileTheme(
                        iconColor: isConnected
                            ? colorScheme.primary
                            : colorScheme.error,
                        textColor: isConnected
                            ? colorScheme.primary
                            : colorScheme.error,
                        child: ListTile(
                          title: Text('WS Status: $status'),
                          onTap: isConnected ? onDisconnectPressed : null,
                          trailing: isConnected
                              ? const Icon(Icons.check_circle_rounded)
                              : const Icon(Icons.cancel_rounded),
                        ),
                      );
                    },
                  ),
                )
              : const ListTile(
                  title: Text('WS Status: Not Connected'),
                  onTap: null,
                  trailing: Icon(Icons.cancel_rounded),
                ),
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('GitLab Notify Dashboard'),
          ),
          body: Center(
            child: SizedBox(
              width: 650,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: portConnectRow,
                    ),
                    wsConnectionStatusTile,
                    Selector<HomeViewModel, bool>(
                      selector: (context, viewModel) =>
                          viewModel.canSentNotificatiod,
                      builder: (context, canSend, child) {
                        return SwitchListTile(
                          onFocusChange: onCanSendNotificationChanged,
                          value: canSend,
                          onChanged: onCanSendNotificationChanged,
                          title: const Text('Notification Permission'),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: onNotificationTestPressed,
                        child: const Text('Notification Test'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (notificationProvider != null)
                      Expanded(
                        child: ChangeNotifierProvider.value(
                          value: notificationProvider,
                          builder: (context, child) {
                            final provider =
                                context.read<NotificationProvider>();
                            return NotificationList(
                              key: ValueKey(provider.hashCode),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
