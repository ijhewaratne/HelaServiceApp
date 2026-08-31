import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/location_service.dart';
import '../bloc/worker_bloc.dart';

class OnlineTogglePage extends StatefulWidget {
  const OnlineTogglePage({super.key});

  @override
  State<OnlineTogglePage> createState() => _OnlineTogglePageState();
}

class _OnlineTogglePageState extends State<OnlineTogglePage> {
  late final WorkerBloc _workerBloc;

  @override
  void initState() {
    super.initState();
    _workerBloc = sl<WorkerBloc>();
  }

  @override
  void dispose() {
    _workerBloc.close();
    super.dispose();
  }

  Future<void> _toggleStatus(bool currentlyOnline) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!currentlyOnline) {
      try {
        final position = await sl<LocationService>().getCurrentPosition();
        _workerBloc.add(
          UpdateOnlineStatus(
            workerId: uid,
            isOnline: true,
            lat: position.latitude,
            lng: position.longitude,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
        }
      }
    } else {
      _workerBloc.add(UpdateOnlineStatus(workerId: uid, isOnline: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkerBloc, WorkerState>(
      bloc: _workerBloc,
      listener: (context, state) {
        if (state is WorkerError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isOnline = state is WorkerOnlineStatusUpdated
            ? state.isOnline
            : false;
        final isLoading = state is WorkerLoading;

        return Scaffold(
          backgroundColor: isOnline ? Colors.indigo.shade50 : Colors.white,
          appBar: AppBar(title: const Text('Dispatch Dashboard')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOnline
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: isLoading ? null : () => _toggleStatus(isOnline),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLoading
                          ? Colors.grey
                          : isOnline
                          ? Colors.green
                          : Colors.indigo,
                      boxShadow: [
                        BoxShadow(
                          color: (isOnline ? Colors.green : Colors.indigo)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isOnline ? 'GO\nOFFLINE' : 'GO\nONLINE',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  isOnline
                      ? 'Waiting for incoming jobs...'
                      : 'Tap to start receiving job requests',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
