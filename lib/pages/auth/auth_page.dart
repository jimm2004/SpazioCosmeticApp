import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthHomePage extends StatelessWidget {
  const AuthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            return Row(
              children: [
                if (isWide)
                  Expanded(
                    child: Container(
                      color: Colors.grey[50],
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/img/Logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'PROFESSIONAL COSMETICS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE91E63),
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Acceso de clientes y catálogo exclusivo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        if (!isWide)
                          Container(
                            padding: const EdgeInsets.only(
                              top: 40,
                              bottom: 20,
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/img/Logo.png',
                                  height: 60,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'PROFESSIONAL COSMETICS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE91E63),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (isWide) const SizedBox(height: 40),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: 'Iniciar Sesión'),
                              Tab(text: 'Registrarse'),
                            ],
                          ),
                        ),

                        const Expanded(
                          child: TabBarView(
                            children: [
                              LoginPage(),
                              RegisterPage(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}