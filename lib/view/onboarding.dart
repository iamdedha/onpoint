import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Future<void> _selectLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    // Save the selected language
    await prefs.setString('preferred_language', languageCode);
    // Mark onboarding as completed
    await prefs.setBool('onboarding_completed', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(language: languageCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;
    final textColor = Colors.black87;
    // BJP-themed (orange) gradient.
    const Gradient bjpGradient = LinearGradient(
      colors: [Color(0xFFFF9933), Color(0xFFFF6F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          color: backgroundColor,
          child: Column(
            children: [
              // Top image section with your brand logo.
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://scontent.fdel1-7.fna.fbcdn.net/v/t39.30808-1/300964753_7837622476308672_405859357558811935_n.jpg?stp=dst-jpg_s200x200_tt6&_nc_cat=103&ccb=1-7&_nc_sid=2d3e12&_nc_ohc=_uu0qU0x-EoQ7kNvgFxtHJq&_nc_oc=Adi7G1FFcJTBTnV-oUKfdW1-wo_JF1XGMUQ4-7dqw5VfmcNflyy3DTs5f46EQZBLuUFAm-wyxB7RC3TmRFrNu77I&_nc_zt=24&_nc_ht=scontent.fdel1-7.fna&_nc_gid=AhczVEtPdnLgkxZhKNN6k8e&oh=00_AYC3lOjMtbu4fzAMWEivQ8oV_9ZvOWCzSTq22HTElJz-9Q&oe=67BB4F3D',
                          fit: BoxFit.cover,
                          semanticLabel: 'Brand Logo',
                        ),
                      ),
                      // Optional gradient overlay for the image.
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [Color(0xAA000000), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom content area with headline and the toggle switch.
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Headline text.
                          Semantics(
                            header: true,
                            child: Text(
                              'Select Your Preferred Language',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // The Apple-inspired toggle switch.
                          LanguageSelector(
                            bjpGradient: bjpGradient,
                            onLanguageSelected: (lang) {
                              HapticFeedback.selectionClick();
                              Future.delayed(const Duration(milliseconds: 300), () {
                                _selectLanguage(lang);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelector extends StatefulWidget {
  final Gradient bjpGradient;
  final Function(String) onLanguageSelected;
  final String initialSelected;

  const LanguageSelector({
    Key? key,
    required this.bjpGradient,
    required this.onLanguageSelected,
    this.initialSelected = 'hi', // Hindi is selected by default.
  }) : super(key: key);

  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double totalWidth = constraints.maxWidth;
      // Increase the toggle width to 95% of the available width.
      double toggleWidth = totalWidth * 0.95;
      double halfWidth = toggleWidth / 2;
      return Center(
        child: Container(
          width: toggleWidth,
          height: 50, // Refined height.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // Animated indicator that slides between options.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: selectedLanguage == 'en' ? 0 : halfWidth,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  margin: const EdgeInsets.all(4), // Provides inner spacing.
                  decoration: BoxDecoration(
                    gradient: widget.bjpGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Row with the two language options.
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          selectedLanguage = 'en';
                        });
                        widget.onLanguageSelected('en');
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'English',
                          style: TextStyle(
                            color: selectedLanguage == 'en' ? Colors.white : Colors.black87,
                            fontSize: 18, // Increased font size.
                            fontWeight: FontWeight.w600, // Refined font weight.
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          selectedLanguage = 'hi';
                        });
                        widget.onLanguageSelected('hi');
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'हिन्दी',
                          style: TextStyle(
                            color: selectedLanguage == 'hi' ? Colors.white : Colors.black87,
                            fontSize: 18, // Increased font size.
                            fontWeight: FontWeight.w600, // Refined font weight.
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
