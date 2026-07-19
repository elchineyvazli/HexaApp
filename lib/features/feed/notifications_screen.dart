import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hexa_theme.dart';
import 'notification_model.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_state_views.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HexaColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: HexaColors.backgroundDark,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NotificationsHeader(),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withOpacity(0.065),
              ),
              Expanded(
                child: notificationsAsync.when(
                  loading: () {
                    return const NotificationsLoadingView();
                  },
                  error: (error, stackTrace) {
                    return NotificationsErrorView(message: error.toString());
                  },
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return const NotificationsEmptyView();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 72),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.055),
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        return NotificationCard(
                          key: ValueKey<int>(index),
                          item: notifications[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
