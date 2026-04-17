import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/user_avatar.dart';
import 'profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool showFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final _searchCtrl = TextEditingController();
  final _userService = UserService();
  final Set<String> _followingIds = <String>{};
  final Set<String> _updatingIds = <String>{};

  String _query = '';
  bool _loading = true;
  List<UserModel> _users = const <UserModel>[];

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final results = await Future.wait<dynamic>([
      _userService.getCurrentUserProfile(),
      widget.showFollowers
          ? _userService.getFollowersList(widget.userId)
          : _userService.getFollowingList(widget.userId),
    ]);

    if (!mounted) return;

    final currentProfile = results[0] as UserModel?;
    final users = results[1] as List<UserModel>;

    setState(() {
      _users = users;
      _followingIds
        ..clear()
        ..addAll(currentProfile?.following ?? const <String>[]);
      _loading = false;
    });
  }

  Future<void> _toggleFollow(UserModel user) async {
    final currentUid = _currentUid;
    if (currentUid == null || currentUid == user.uid) return;
    if (_updatingIds.contains(user.uid)) return;

    final isFollowing = _followingIds.contains(user.uid);
    setState(() => _updatingIds.add(user.uid));

    try {
      if (isFollowing) {
        await _userService.unfollowUser(user.uid);
      } else {
        await _userService.followUser(user.uid);
      }

      if (!mounted) return;

      setState(() {
        if (isFollowing) {
          _followingIds.remove(user.uid);
          if (!widget.showFollowers && widget.userId == currentUid) {
            _users = _users.where((item) => item.uid != user.uid).toList();
          }
        } else {
          _followingIds.add(user.uid);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(user.uid));
      }
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      if (_query.isEmpty) return true;
      final normalized = _query.toLowerCase();
      return user.username.toLowerCase().contains(normalized) ||
          user.bio.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03070D),
        elevation: 0,
        title: Text(
          widget.showFollowers
              ? '@${widget.username} takipçileri'
              : '@${widget.username} takipleri',
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : _users.isEmpty
              ? Center(
                  child: Text(
                    widget.showFollowers
                        ? 'Henüz takipçi yok.'
                        : 'Henüz kimse takip edilmiyor.',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Kullanıcı ara...',
                            hintStyle: TextStyle(color: Colors.white38),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.cyanAccent,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'Aramana uygun kullanıcı bulunamadı.',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 15),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isCurrentUser = user.uid == _currentUid;
                                final isFollowing =
                                    _followingIds.contains(user.uid);
                                final isUpdating =
                                    _updatingIds.contains(user.uid);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProfileScreen(userId: user.uid),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.cyanAccent
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          UserAvatar(
                                            imageUrl: user.profilePicUrl,
                                            size: 46,
                                            glow: true,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '@${user.username}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.bio.isEmpty
                                                      ? 'Vibeo kullanıcısı'
                                                      : user.bio,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (isCurrentUser)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.07),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Sen',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              height: 36,
                                              child: OutlinedButton(
                                                onPressed: isUpdating
                                                    ? null
                                                    : () => _toggleFollow(user),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: isFollowing
                                                        ? Colors.white24
                                                        : Colors.cyanAccent,
                                                  ),
                                                  backgroundColor: isFollowing
                                                      ? Colors.white.withValues(
                                                          alpha: 0.05)
                                                      : Colors.cyanAccent,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: isUpdating
                                                    ? SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: isFollowing
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      )
                                                    : Text(
                                                        isFollowing
                                                            ? 'Takiptesin'
                                                            : 'Takip Et',
                                                        style: TextStyle(
                                                          color: isFollowing
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
