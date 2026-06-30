import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_container.dart';

class ProfileCompletionModal extends StatefulWidget {
  final String prefillName;
  final String prefillEmail;

  const ProfileCompletionModal({
    super.key,
    required this.prefillName,
    required this.prefillEmail,
  });

  @override
  State<ProfileCompletionModal> createState() => _ProfileCompletionModalState();
}

class _ProfileCompletionModalState extends State<ProfileCompletionModal> {
  late final TextEditingController _nameController;
  final _locationController = TextEditingController();
  String? _gender;
  int? _birthYear;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  final _genders = ['Male', 'Female', 'Rather not say'];
  final _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_gender == null) {
      setState(() => _error = 'Please select your gender.');
      return;
    }
    if (_birthYear == null) {
      setState(() => _error = 'Please select your birth year.');
      return;
    }
    if (location.isEmpty) {
      setState(() => _error = 'Please enter your hometown.');
      return;
    }

    setState(() { _submitting = true; _error = null; });
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
      name: name,
      gender: _gender,
      birthYear: _birthYear,
      location: location,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && _submitting) {
          final p = state.profile;
          final complete = p != null &&
              p['gender'] != null &&
              p['birth_year'] != null &&
              p['location'] != null;
          if (complete) setState(() { _submitting = false; _done = true; });
        }
        if (state is AuthError) {
          setState(() { _submitting = false; _error = state.message; });
        }
      },
      child: PopScope(
        canPop: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDarkGrey,
              border: Border.all(color: AppTheme.borderGrey, width: 4),
              boxShadow: const [AppTheme.arcadeShadow],
            ),
            child: _done ? _buildDoneState(context) : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎉', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text('THANK YOU!',
              style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Please enjoy this app. You can complete the rest of your profile anytime from Settings.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          TactileContainer(
            onTap: () => Navigator.of(context).pop(),
            builder: (_, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.accentOrange,
                isPressed: isPressed,
              ),
              child: Center(
                child: Text('LET\'S GO!',
                    style: AppTheme.retroStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('COMPLETE YOUR PROFILE',
              style: AppTheme.retroStyle(fontSize: 13, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('A few more details to personalise your experience.',
              style: AppTheme.bodyStyle(fontSize: 13, color: AppTheme.primaryTeal)),
          const SizedBox(height: 24),

          // Name
          Text('NAME *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
          const SizedBox(height: 8),
          _buildTextField(_nameController, 'Your display name'),
          const SizedBox(height: 16),

          // Email (read-only)
          Text('EMAIL', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.cardGrey.withValues(alpha: 0.5),
              border: Border.all(color: AppTheme.borderGrey, width: 3),
            ),
            child: Text(widget.prefillEmail,
                style: AppTheme.bodyStyle(fontSize: 14, color: Colors.white54)),
          ),
          const SizedBox(height: 16),

          // Gender
          Text('GENDER *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
          const SizedBox(height: 8),
          Column(
            children: _genders.map((g) {
              final selected = _gender == g;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TactileContainer(
                  onTap: () => setState(() => _gender = g),
                  builder: (_, isPressed) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accentOrange : AppTheme.cardGrey,
                      border: Border.all(
                        color: selected ? AppTheme.shadowOrange : AppTheme.borderGrey,
                        width: 3,
                      ),
                    ),
                    child: Text(g.toUpperCase(),
                        style: AppTheme.retroStyle(
                          fontSize: 10,
                          color: selected ? Colors.black : AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Birth Year
          Text('BIRTH YEAR *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              border: Border.all(color: AppTheme.borderGrey, width: 3),
            ),
            child: ListWheelScrollView.useDelegate(
              itemExtent: 36,
              perspective: 0.003,
              diameterRatio: 2.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) => setState(() => _birthYear = _currentYear - 1 - i),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 100,
                builder: (context, index) {
                  final year = _currentYear - 1 - index;
                  final selected = _birthYear == year;
                  return Center(
                    child: Text('$year',
                        style: AppTheme.retroStyle(
                          fontSize: selected ? 14 : 11,
                          color: selected ? AppTheme.accentOrange : Colors.white54,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        )),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location
          Text('HOMETOWN *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
          const SizedBox(height: 8),
          _buildTextField(_locationController, 'e.g. Bandung'),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red.withValues(alpha: 0.15),
              child: Text(_error!, style: AppTheme.bodyStyle(fontSize: 12, color: Colors.red)),
            ),
            const SizedBox(height: 12),
          ],

          TactileContainer(
            onTap: _submitting ? () {} : _submit,
            builder: (_, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.accentOrange,
                isPressed: isPressed,
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text('SAVE & CONTINUE',
                        style: AppTheme.retroStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 3),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.bodyStyle(fontSize: 14, color: Colors.white38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
