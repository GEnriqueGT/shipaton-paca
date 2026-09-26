import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;
  String? _emailNotice;
  int _noticeGen = 0;

  @override
  void dispose() {
    _noticeGen++;
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _emailNotice = null;
    });
    final client = ref.read(supabaseProvider);
    try {
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (response.session == null) {
          final email = _email.text.trim();
          if (mounted) setState(() => _loading = false);
          await _showEmailNotice(email);
          return;
        }
      } else {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() => _error = 'No se pudo iniciar sesión.');
        return;
      }
      await ref.read(customerInfoProvider.notifier).logIn(user.id);
      if (mounted) context.go('/role');
    } on AuthException catch (e) {
      setState(() => _error = _authMessage(e.message));
    } catch (_) {
      setState(() => _error = 'No se pudo completar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEmailNotice(String email) async {
    final gen = ++_noticeGen;
    if (!mounted) return;
    setState(() {
      _emailNotice = email;
      _isSignUp = false;
      _error = null;
    });
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted || gen != _noticeGen) return;
    setState(() => _emailNotice = null);
  }

  void _dismissEmailNotice() {
    _noticeGen++;
    setState(() => _emailNotice = null);
  }

  String _authMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email not confirmed')) {
      return 'Confirma el correo antes de entrar.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already registered')) {
      return 'Ese correo ya tiene cuenta. Entra con tu contraseña.';
    }
    if (lower.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return 'No se pudo completar. Revisa el correo y la contraseña.';
  }

  @override
  Widget build(BuildContext context) {
    final notice = _emailNotice;
    return Scaffold(
      body: SafeArea(
        child: notice != null
            ? _EmailSentNotice(
                email: notice,
                onContinue: _dismissEmailNotice,
              )
            : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Text(
              'Paca GT',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUp
                  ? 'Crea tu cuenta para tiendas o compradores'
                  : 'Entrá para publicar o encontrar pacas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Registrarme' : 'Entrar'),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? '¿Ya tienes cuenta? Inicia sesión'
                    : '¿Nueva cuenta? Regístrate',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSentNotice extends StatelessWidget {
  const _EmailSentNotice({
    required this.email,
    required this.onContinue,
  });

  final String email;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Revisa tu correo',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enviamos un enlace de confirmación a $email. Ábrelo para activar la cuenta y después entra con tu contraseña.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Volvés a entrar en unos segundos',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onContinue,
            child: const Text('Ir a entrar'),
          ),
        ],
      ),
    );
  }
}
