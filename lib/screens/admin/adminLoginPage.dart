import 'package:flutter/material.dart';
import 'adminhomepage.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? usernameError;
  String? passwordError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/Admin Login page background image_page-0001.jpg'),
      context,
    );
  }

  void validateLogin(BuildContext context) async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    bool isUsernameCorrect = username.toLowerCase() == 'admin';
    bool isPasswordCorrect = password.toLowerCase() == 'admin';

    setState(() {
      usernameError = isUsernameCorrect ? null : 'Wrong username';
      passwordError = isPasswordCorrect ? null : 'Wrong password';
    });

    if (isUsernameCorrect && isPasswordCorrect) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      if (context.mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(adminName: username),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * 0.045, maxWidth: width * 0.2),
              child: Image.asset(
                'assets/images/adminheadlogo.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Admin Login page background image_page-0001.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                width * 0.08,
                height * 0.02,
                width * 0.08,
                viewInsets > 0 ? viewInsets + height * 0.02 : height * 0.05,
              ),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: height - viewInsets - kToolbarHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            iconSize: width * 0.07,
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          Flexible(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: width * 0.1),
                        ],
                      ),
                      SizedBox(height: height * 0.015),
                      Center(
                        child: Text(
                          'Manage events,\nregistrations, and payments \nfrom your dashboard',
                          style: TextStyle(
                            fontSize: width * 0.045,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: height * 0.035),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField(
                              label: 'Username',
                              controller: usernameController,
                              errorText: usernameError,
                              width: width,
                              height: height,
                            ),
                            SizedBox(height: height * 0.02),
                            _buildField(
                              label: 'Email ID',
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              width: width,
                              height: height,
                            ),
                            SizedBox(height: height * 0.02),
                            _buildField(
                              label: 'Password',
                              controller: passwordController,
                              errorText: passwordError,
                              obscure: true,
                              width: width,
                              height: height,
                            ),
                            SizedBox(height: height * 0.02),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.035,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            SizedBox(
                              width: width * 0.5,
                              height: height * 0.06,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    validateLogin(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: width * 0.045,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    required double width,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: width * 0.045),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: (_) {
            setState(() {
              if (label == 'Username') usernameError = null;
              if (label == 'Password') passwordError = null;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter $label';
            }
            return null;
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white38),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white38),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: width * 0.035,
              ),
            ),
          ),
      ],
    );
  }
}
