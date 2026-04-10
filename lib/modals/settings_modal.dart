import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/config_bloc.dart';
import '../theme/app_theme.dart';
import 'liked_songs_modal.dart';
import '../widgets/tactile_container.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  // Auth fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  // Profile fields
  final _whatsappController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthYearController = TextEditingController();
  String? _selectedGender;

  bool _profileLoaded = false;
  bool _isEditMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _loadProfileIntoFields(Map<String, dynamic>? profile) {
    if (_profileLoaded || profile == null) return;
    _profileLoaded = true;
    _whatsappController.text = profile['whatsapp_number'] as String? ?? '';
    _instagramController.text = profile['instagram_username'] as String? ?? '';
    _twitterController.text = profile['twitter_username'] as String? ?? '';
    _facebookController.text = profile['facebook_username'] as String? ?? '';
    _tiktokController.text = profile['tiktok_username'] as String? ?? '';
    _locationController.text = profile['location'] as String? ?? '';
    _selectedGender = profile['gender'] as String?;
    final birthYear = profile['birth_year'];
    if (birthYear != null) _birthYearController.text = birthYear.toString();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: () => entry.remove(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isError ? AppTheme.accentOrange : AppTheme.primaryTeal,
                  border: Border.all(
                    color: isError ? AppTheme.shadowOrange : AppTheme.tealShadow,
                    width: 4,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                ),
                child: Text(
                  message,
                  style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, configState) {
        final config = configState.config;
        return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDarkGrey,
              border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthError) {
                              _showSnackBar(state.message.toUpperCase());
                            }
                            if (state is AuthAuthenticated) {
                              _loadProfileIntoFields(state.profile);
                            }
                          },
                          builder: (context, authState) {
                            if (authState is AuthLoading) {
                              return _buildSectionBox('USER PROFILE',
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                                  ),
                                ),
                              );
                            }
                            if (authState is AuthAuthenticated) {
                              _loadProfileIntoFields(authState.profile);
                              return _buildProfileSection(context, authState);
                            }
                            return _buildAuthSection(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLikedSongsButton(context),
                        const SizedBox(height: 12),
                        _buildInfoSection('APP INFO', config.appInfo),
                        const SizedBox(height: 12),
                        _buildInfoSection('STATION', config.stationInfo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('SETTINGS',
              style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                border: Border.all(color: AppTheme.shadowOrange, width: 2),
              ),
              child: const Icon(LucideIcons.x, color: Colors.black, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(BuildContext context) {
    // Capture context here, outside of TactileContainer builder
    final outerContext = context;
    return _buildSectionBox(
      'USER PROFILE',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildToggleButton('LOGIN', !_isRegisterMode, () => setState(() => _isRegisterMode = false)),
              const SizedBox(width: 8),
              _buildToggleButton('REGISTER', _isRegisterMode, () => setState(() => _isRegisterMode = true)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isRegisterMode) ...[
            _buildInputField('NAME *', 'Your display name', _nameController),
            const SizedBox(height: 8),
          ],
          _buildInputField('EMAIL *', 'your@email.com', _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          _buildInputField('PASSWORD *', 'Min. 6 characters', _passwordController, isPassword: true),
          const SizedBox(height: 16),
          TactileContainer(
            onTap: () {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              final name = _nameController.text.trim();

              if (email.isEmpty) {
                _showSnackBar('EMAIL CANNOT BE EMPTY');
                return;
              }
              if (!email.contains('@')) {
                _showSnackBar('PLEASE ENTER A VALID EMAIL');
                return;
              }
              if (password.isEmpty) {
                _showSnackBar('PASSWORD CANNOT BE EMPTY');
                return;
              }
              if (password.length < 6) {
                _showSnackBar('PASSWORD MUST BE AT LEAST 6 CHARACTERS');
                return;
              }
              if (_isRegisterMode && name.isEmpty) {
                _showSnackBar('NAME CANNOT BE EMPTY');
                return;
              }

              if (_isRegisterMode) {
                outerContext.read<AuthBloc>().add(AuthRegisterRequested(
                  email: email,
                  password: password,
                  name: name,
                ));
              } else {
                outerContext.read<AuthBloc>().add(AuthLoginRequested(
                  email: email,
                  password: password,
                ));
              }
            },
            builder: (_, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.accentOrange,
                isPressed: isPressed,
              ),
              child: Center(
                child: Text(
                  _isRegisterMode ? 'CREATE ACCOUNT' : 'LOGIN',
                  style: AppTheme.retroStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthAuthenticated state) {
    if (_isEditMode) {
      return _buildProfileEditForm(context, state);
    }
    return _buildProfileView(context, state);
  }

  Widget _buildProfileView(BuildContext context, AuthAuthenticated state) {
    final profile = state.profile;
    final name = profile?['name'] as String? ?? state.user.email ?? 'User';
    final email = state.user.email ?? '';

    return _buildSectionBox(
      'USER PROFILE',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  border: Border.all(color: AppTheme.tealShadow, width: 3),
                ),
                child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(),
                        style: AppTheme.retroStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(email,
                        style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.primaryTeal)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info Display
          _buildInfoRow('NAME', name),
          _buildInfoRow('GENDER', profile?['gender']),
          _buildInfoRow('BIRTH YEAR', profile?['birth_year']?.toString()),
          _buildInfoRow('LOCATION', profile?['location']),
          _buildInfoRow('WHATSAPP', profile?['whatsapp_number']),
          _buildInfoRow('INSTAGRAM', profile?['instagram_username']),
          _buildInfoRow('TWITTER', profile?['twitter_username']),
          _buildInfoRow('FACEBOOK', profile?['facebook_username']),
          _buildInfoRow('TIKTOK', profile?['tiktok_username']),

          const SizedBox(height: 16),

          // Profile Buttons
          TactileContainer(
            onTap: () => setState(() => _isEditMode = true),
            builder: (_, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.primaryTeal,
                isPressed: isPressed,
              ),
              child: Center(
                child: Text('EDIT PROFILE',
                    style: AppTheme.retroStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          TactileContainer(
            onTap: () {
              _profileLoaded = false;
              _isEditMode = false;
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            builder: (_, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.borderGrey,
                isPressed: isPressed,
              ),
              child: Center(
                child: Text('LOGOUT',
                    style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty)) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.retroStyle(fontSize: 9, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value.toString(),
              style: AppTheme.bodyStyle(fontSize: 12, color: Colors.white)),
          const SizedBox(height: 4),
          Container(height: 1, color: AppTheme.borderGrey.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildProfileEditForm(BuildContext context, AuthAuthenticated state) {
    final outerContext = context;
    // final profile = state.profile; // removing unused local variable


    return _buildSectionBox(
      'EDIT PROFILE',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('BASIC INFO'),
          const SizedBox(height: 8),
          _buildInputField('NAME', 'Display name', _nameController),
          const SizedBox(height: 8),
          _buildGenderDropdown(),
          const SizedBox(height: 8),
          _buildInputField('BIRTH YEAR', 'e.g. 1995', _birthYearController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          _buildInputField('LOCATION', 'City / Region', _locationController),
          const SizedBox(height: 16),

          _buildSectionLabel('CONTACT'),
          const SizedBox(height: 8),
          _buildInputField('WHATSAPP', '+62 812 3456 7890', _whatsappController,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),

          _buildSectionLabel('SOCIAL MEDIA'),
          const SizedBox(height: 8),
          _buildInputField('INSTAGRAM', '@username', _instagramController),
          const SizedBox(height: 8),
          _buildInputField('TWITTER / X', '@username', _twitterController),
          const SizedBox(height: 8),
          _buildInputField('FACEBOOK', 'username or profile URL', _facebookController),
          const SizedBox(height: 8),
          _buildInputField('TIKTOK', '@username', _tiktokController),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TactileContainer(
                  onTap: () {
                    final name = _nameController.text.trim();
                    final location = _locationController.text.trim();

                    if (name.isEmpty) {
                      _showSnackBar('NAME IS REQUIRED');
                      return;
                    }
                    if (_selectedGender == null) {
                      _showSnackBar('PLEASE SELECT YOUR GENDER');
                      return;
                    }
                    if (location.isEmpty) {
                      _showSnackBar('LOCATION IS REQUIRED');
                      return;
                    }

                    final birthYearText = _birthYearController.text.trim();
                    int? birthYear;
                    if (birthYearText.isNotEmpty) {
                      birthYear = int.tryParse(birthYearText);
                      if (birthYear == null || birthYear < 1900 || birthYear > 2025) {
                        _showSnackBar('PLEASE ENTER A VALID BIRTH YEAR');
                        return;
                      }
                    }
                    outerContext.read<AuthBloc>().add(AuthProfileUpdateRequested(
                      name: _nameController.text.trim(),
                      whatsappNumber: _whatsappController.text.trim(),
                      instagramUsername: _instagramController.text.trim(),
                      twitterUsername: _twitterController.text.trim(),
                      facebookUsername: _facebookController.text.trim(),
                      tiktokUsername: _tiktokController.text.trim(),
                      location: _locationController.text.trim(),
                      gender: _selectedGender,
                      birthYear: birthYear,
                    ));
                    setState(() => _isEditMode = false);
                    _showSnackBar('PROFILE SAVED', isError: false);
                  },
                  builder: (_, isPressed) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: AppTheme.controlButtonDecoration(
                      color: AppTheme.primaryTeal,
                      isPressed: isPressed,
                    ),
                    child: Center(
                      child: Text('SAVE',
                          style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TactileContainer(
                  onTap: () => setState(() => _isEditMode = false),
                  builder: (_, isPressed) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: AppTheme.controlButtonDecoration(
                      color: AppTheme.borderGrey,
                      isPressed: isPressed,
                    ),
                    child: Center(
                      child: Text('CANCEL',
                          style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: AppTheme.retroStyle(fontSize: 9, color: AppTheme.accentOrange, fontWeight: FontWeight.bold));
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GENDER',
            style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: AppTheme.borderGrey, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButton<String>(
            value: _selectedGender,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.cardGrey,
            hint: Text('Select gender',
                style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.borderGrey)),
            style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
              DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
            ],
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
        ),
      ],
    );
  }

  Widget _buildLikedSongsButton(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final configBloc = context.read<ConfigBloc>();
    return TactileContainer(
      onTap: () {
        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthAuthenticated) {
          _showSnackBar('YOU HAVE TO LOGIN TO ACCESS LIKED SONGS');
          return;
        }
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: authBloc),
              BlocProvider.value(value: configBloc),
            ],
            child: const LikedSongsModal(),
          ),
        );
      },
      builder: (_, isPressed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: AppTheme.controlButtonDecoration(
          color: AppTheme.borderGrey,
          isPressed: isPressed,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.heart, color: AppTheme.accentOrange, size: 16),
            const SizedBox(width: 8),
            Text('LIKED SONGS',
                style: AppTheme.retroStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: TactileContainer(
        onTap: onTap,
        builder: (_, isPressed) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: AppTheme.controlButtonDecoration(
            color: isActive ? AppTheme.accentOrange : AppTheme.borderGrey,
            isPressed: isPressed,
          ),
          child: Center(
            child: Text(label,
                style: AppTheme.retroStyle(
                    fontSize: 11,
                    color: isActive ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String placeholder, TextEditingController controller,
      {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: AppTheme.borderGrey, width: 2),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            keyboardType: keyboardType,
            style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.borderGrey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: InputBorder.none,
              isDense: true,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: AppTheme.borderGrey, size: 14,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionBox(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, String> info) {
    return _buildSectionBox(
      title,
      Column(
        children: info.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key,
                  style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
              Text(e.value,
                  style: AppTheme.bodyStyle(fontSize: 10, color: Colors.white)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
