import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _handleContinue() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak boleh kosong')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // Panggil API Backend
      await ApiService.forgotPassword(_emailController.text.trim());
      
      if (!mounted) return;
      
      // Tampilkan pesan sukses (Token akan muncul di log Docker)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Instruksi dikirim! Cek Log Docker untuk melihat Token.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ));
      
      // Pindah ke halaman input password baru sambil membawa Email
      Navigator.pushNamed(
        context, 
        '/new-password', 
        arguments: _emailController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Forgot Password', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.school, size: 60, color: Color(0xFF145A4A)),
              const SizedBox(height: 30),
              
              const Text(
                'Enter your email address below to reset password',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CONTINUE'),
              ),
              
              const Spacer(),
              
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF145A4A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.psychology, size: 80, color: Color(0xFFD97736)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}