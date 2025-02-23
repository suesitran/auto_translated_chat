import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:public_chat/_shared/bloc/authentication/authentication_cubit.dart';
import 'package:public_chat/features/chat/ui/public_chat_screen.dart';
import 'package:public_chat/features/genai_setting/bloc/genai_bloc.dart';
import 'package:public_chat/features/login/ui/login_screen.dart';
import 'package:public_chat/firebase_options.dart';
import 'package:public_chat/service_locator/service_locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'utils/global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    /// NOTE: This setting is to run on Flutter web only
    /// to run on Flutter mobile, please set host to be your machine's IP address
    /// and update host in file firebase.json
    FirebaseAuth.instance.useAuthEmulator('localhost', 8000);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8002);
  }
  ServiceLocator.instance.initialise();
  Global().init();
  runApp(MultiBlocProvider(providers: [
    BlocProvider<AuthenticationCubit>(
      create: (context) => AuthenticationCubit(),
    ),
    BlocProvider<GenaiBloc>(
      create: (context) => GenaiBloc(),
    )
  ], child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocBuilder<AuthenticationCubit, AuthenticationState>(
            builder: (context, state) {
          if (state is Authenticated) {
            return const PublicChatScreen();
          } else {
            return const LoginScreen();
          }
        }));
  }
}
