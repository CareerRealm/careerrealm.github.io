import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

/// The core single source of truth for the logged-in user in Career Realm.
final userProvider = StateNotifierProvider<UserNotifier, AppUser?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AppUser?> {
  UserNotifier() : super(null);

  /// Called upon authentication to populate the immutable user schema.
  void setUser(AppUser? user) {
    state = user;
  }

  /// The Fatigue Engine: Deplete or restore HP securely inside the UI before validating to Firebase.
  void modifyHp(int amount) {
    if (state != null) {
      final newHp = (state!.hp + amount).clamp(0, 100);
      state = state!.copyWith(hp: newHp);
    }
  }

  /// Add Academic XP via Focus Realm usage.
  void addAxp(int amount) {
    if (state != null) {
      state = state!.copyWith(axp: state!.axp + amount);
    }
  }

  /// Add Professional XP via GitHub/Certificate validation.
  void addPxp(int amount) {
    if (state != null) {
      state = state!.copyWith(pxp: state!.pxp + amount);
    }
  }

  /// Validates a targeted node inside the Career Realm tree.
  void verifyNode(String nodeId) {
    if (state != null && !state!.verifiedNodes.contains(nodeId)) {
      final updatedNodes = List<String>.from(state!.verifiedNodes)..add(nodeId);
      state = state!.copyWith(verifiedNodes: updatedNodes);
    }
  }
}
