import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_container.dart';

class ProfileCompletionModal extends StatefulWidget {
  const ProfileCompletionModal({super.key});

  @override
  State<ProfileCompletionModal> createState() => _ProfileCompletionModalState();
}

class _ProfileCompletionModalState extends State<ProfileCompletionModal> {
  final _locationController = TextEditingController();
  String? _gender;
  int? _birthYear;
  bool _submitting = false;
  String? _error;

  final _genders = ['Male', 'Female', 'Other'];
  final _currentYear = DateTime.now().year;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final location = _locationController.text.trim();

    if (_gender == null) {
      setState(() => _error = 'Please select your gender.');
      return;
    }
    if (_birthYear == null) {
      setState(() => _error = 'Please select your birth year.');
      return;
    }
    if (location.isEmpty) {
      setState(() => _error = 'Please enter your city / location.');
      return;
    }

    setState(() { _submitting = true; _error = null; });
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
      gender: _gender,
      birthYear: _birthYear,
      location: location,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final p = state.profile;
          final complete = p != null &&
              p['gender'] != null &&
              p['birth_year'] != null &&
              p['location'] != null;
          if (complete) Navigator.of(context).pop();
        }
        if (state is AuthError) {
          setState(() { _submitting = false; _error = state.message; });
        }
      },
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDarkGrey,
              border: Border.all(color: AppTheme.borderGrey, width: 4),
              boxShadow: const [AppTheme.arcadeShadow],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('COMPLETE YOUR PROFILE',
                      style: AppTheme.retroStyle(fontSize: 13, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('We need a few more details to personalise your experience.',
                      style: AppTheme.bodyStyle(fontSize: 13, color: AppTheme.primaryTeal)),
                  const SizedBox(height: 24),

                  // Gender
                  Text('GENDER *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
                  const SizedBox(height: 8),
                  Row(
                    children: _genders.map((g) {
                      final selected = _gender == g;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TactileContainer(
                            onTap: () => setState(() => _gender = g),
                            builder: (_, isPressed) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.accentOrange : AppTheme.cardGrey,
                                border: Border.all(
                                  color: selected ? AppTheme.shadowOrange : AppTheme.borderGrey,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(g.toUpperCase(),
                                    style: AppTheme.retroStyle(
                                      fontSize: 9,
                                      color: selected ? Colors.black : AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

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
                      onSelectedItemChanged: (i) {
                        setState(() => _birthYear = _currentYear - 13 - i);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 80,
                        builder: (context, index) {
                          final year = _currentYear - 13 - index;
                          final selected = _birthYear == year;
                          return Center(
                            child: Text(
                              '$year',
                              style: AppTheme.retroStyle(
                                fontSize: selected ? 14 : 11,
                                color: selected ? AppTheme.accentOrange : Colors.white54,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location
                  Text('CITY / LOCATION *', style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey,
                      border: Border.all(color: AppTheme.borderGrey, width: 3),
                    ),
                    child: TextField(
                      controller: _locationController,
                      style: AppTheme.bodyStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Bandung',
                        hintStyle: AppTheme.bodyStyle(fontSize: 14, color: Colors.white38),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red.withValues(alpha: 0.15),
                      child: Text(_error!,
                          style: AppTheme.bodyStyle(fontSize: 12, color: Colors.red)),
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
            ),
          ),
        ),
      ),
    );
  }
}
