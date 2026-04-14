import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/config_service.dart';

abstract class ConfigEvent {}

class LoadConfigRequested extends ConfigEvent {}

class RefreshConfigRequested extends ConfigEvent {}

abstract class ConfigState {
  final AppConfig config;
  ConfigState(this.config);
}

class ConfigInitial extends ConfigState {
  ConfigInitial() : super(ConfigService.defaultConfig);
}

class ConfigLoading extends ConfigState {
  ConfigLoading(super.config);
}

class ConfigLoaded extends ConfigState {
  ConfigLoaded(super.config);
}

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigService _configService;

  ConfigBloc(this._configService) : super(ConfigInitial()) {
    on<LoadConfigRequested>((event, emit) async {
      emit(ConfigLoading(state.config));
      final config = await _configService.fetchConfig();
      emit(ConfigLoaded(config));
    });

    on<RefreshConfigRequested>((event, emit) async {
      // Don't emit loading state for refresh to avoid UI flickering
      // Just fetch and update once ready
      final config = await _configService.fetchConfig();
      emit(ConfigLoaded(config));
    });
  }
}
