import 'dart:async';
import 'dart:developer';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/page_data.dart';
import 'package:quran/quran.dart' as quran;
import 'package:audioplayers/audioplayers.dart';
import '../../constants.dart';
import '../../utils/app_style.dart';
import '../../widgets/quran_container_down.dart';
import '../../widgets/quran_container_up.dart';
import '../../widgets/surah_border.dart';
import '../../widgets/verse_buttons_widget.dart';
import 'quran_font_size_provider.dart';
import 'quran_reading_main_page.dart';

class SurahPage extends StatefulWidget {
  final int pageNumber;

  const SurahPage({super.key, required this.pageNumber});

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  bool isVisible = true;
  Map<int, List<Map<String, dynamic>>> pageContent = {};
  int currentSurahIndex = 0;
  int currentJuzNumber = 0;
  int? highlightedVerse;
  Offset? buttonPosition;
  late int pageNumber;
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isBuffering = false;

  @override
  void initState() {
    super.initState();
    pageNumber = widget.pageNumber;
    _loadPageContent(pageNumber);
    _preloadAudio();
  }

  double _getAdjustedFontSize(String text, double originalFontSize) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(fontSize: originalFontSize),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);

    double width = textPainter.width;
    double screenWidth = MediaQuery.of(context).size.width;

    // Adjust scaling factors for wider scaling
    double scaleFactor = 1.0;

    // Wider scaling down if the text is much larger than the screen width
    if (width > screenWidth) {
      scaleFactor = (screenWidth / width) * 0.1; // Increased reduction
    }
    // Wider scaling up if the text is much smaller than the screen width
    else if (width < screenWidth * 0.1) {
      scaleFactor = (screenWidth / width) * 3; // Increased increment
    }

    // Adjust the font size and clamp it within reasonable bounds
    double adjustedFontSize = originalFontSize * scaleFactor;
    return adjustedFontSize.clamp(
        originalFontSize - 6, originalFontSize + 6); // Wider range
  }

  Future<void> _loadPageContent(int pageNumber) async {
    try {
      pageContent.clear();
      List<Map<String, dynamic>> currentPageData = pageData[pageNumber - 1];
      for (var entry in currentPageData) {
        int surahNumber = entry['surah'];
        int startVerse = entry['start'];
        int endVerse = entry['end'];

        currentSurahIndex = surahNumber;
        currentJuzNumber = quran.getJuzNumber(surahNumber, startVerse);

        List<Map<String, dynamic>> verses = [];
        for (int verse = startVerse; verse <= endVerse; verse++) {
          verses.add({
            'verseNumber': verse,
            'verseText': quran.getVerse(surahNumber, verse),
          });
        }
        pageContent[surahNumber] = verses;
      }
      setState(() {});
    } catch (e) {
      log("Error loading page content: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load page content: $e")),
      );
    }
  }

  void _preloadAudio() async {
    try {
      String audioUrl =
          quran.getAudioURLByVerse(currentSurahIndex, highlightedVerse ?? 1);
      await _audioPlayer.setSourceUrl(audioUrl);
    } catch (e) {
      debugPrint("Error preloading audio: $e");
    }
  }

  void _selectVerse(Offset globalPosition, int verseNumber) {
    setState(() {
      highlightedVerse = verseNumber;
      buttonPosition = globalPosition;
    });
  }

  void _clearSelection() {
    setState(() {
      highlightedVerse = null;
      buttonPosition = null;
    });
  }

  void _containersVisability() {
    isVisible = !isVisible;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          // Navigate to QuranReadingMainPage
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const QuranReadingMainPage()),
            (route) => false, // Clear all previous routes
          );
        },
        child: Scaffold(
          backgroundColor: AppColors.kPrimaryColor,
          body: Stack(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final Offset localPosition =
                      renderBox.globalToLocal(details.globalPosition);
                  _clearSelection();
                  _containersVisability();
                },
                child: SafeArea(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (newPageIndex) {
                      setState(() {
                        pageNumber = newPageIndex + 1;
                        highlightedVerse = null;
                      });
                      _loadPageContent(pageNumber);
                    },
                    itemBuilder: (context, index) {
                      return _buildPageContent();
                    },
                  ),
                ),
              ),
              if (highlightedVerse != null && buttonPosition != null)
                _buildActionButtons(),
              if (isVisible) _buildTopHeader(),
              if (isVisible) _buildBottomFooter(),
            ],
          ),
        ));
  }

  Widget _buildPageContent() {
    return Consumer<QuranFontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(right: 8),
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    style: AppStyles.styleAmiriMedium30(context).copyWith(
                      fontSize: fontSizeProvider.fontSize,
                    ),
                    children: pageContent.entries.expand((entry) {
                      int surahNumber = entry.key;
                      return entry.value.map((verseEntry) {
                        int verseIndex = verseEntry['verseNumber'];
                        String verseText = verseEntry['verseText'];
                        bool isHighlighted = highlightedVerse == verseIndex;

                        // Split the verse text into words
                        List<String> words = verseText.split(' ');

                        // Create spans for each word with adjusted font sizes
                        List<InlineSpan> wordSpans = words.map((word) {
                          double adjustedFontSize = _getAdjustedFontSize(
                              word, fontSizeProvider.fontSize);

                          return TextSpan(
                            text: '$word ', // Add a space after each word
                            style: TextStyle(
                              fontSize: adjustedFontSize,
                              backgroundColor: isHighlighted
                                  ? Colors.yellow.withOpacity(0.4)
                                  : Colors.transparent,
                              color: isHighlighted ? Colors.red : null,
                            ),
                            recognizer: LongPressGestureRecognizer()
                              ..onLongPressStart = (details) {
                                // Get the global position of the long press
                                RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                Offset globalPosition = renderBox
                                    .localToGlobal(details.globalPosition);

                                // Trigger _selectVerse
                                _selectVerse(globalPosition, verseIndex);
                              },
                          );
                        }).toList();

                        // Add the verse end symbol
                        wordSpans.add(TextSpan(
                          text:
                              '${quran.getVerseEndSymbol(verseIndex, arabicNumeral: true)} ',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize,
                          ),
                        ));

                        return TextSpan(
                          children: [
                            if (verseIndex == 1)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: SurahBorder(surahNumber: surahNumber),
                              ),
                            ...wordSpans,
                          ],
                        );
                      });
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: QuranContainerUP(
          surahIndex: currentSurahIndex,
          isMakkia: quran.getPlaceOfRevelation(currentSurahIndex),
          juzNumber: currentJuzNumber,
          surahsAyat: quran.getVerseCount(currentSurahIndex),
          isPageLeft: widget.pageNumber % 2 == 0,
          verseNumber: int.parse(
              (pageData[widget.pageNumber - 1][0]['start']).toString()),
        ),
      ),
    );
  }

  Widget _buildBottomFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: QuranContainerDown(
          pageNumber: pageNumber,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // Screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Button dimensions (approximated; adjust as needed based on your button size)
    const buttonWidth = 200.0;
    const buttonHeight = 50.0;

    // Clamp the button position to ensure it stays within screen bounds
    final leftPosition = buttonPosition!.dx.clamp(0, screenWidth - buttonWidth);
    final topPosition =
        buttonPosition!.dy.clamp(0, screenHeight - buttonHeight);

    return Positioned(
      left: leftPosition.toDouble(),
      top: topPosition.toDouble(),
      child: VerseButtons(
        currentSurahIndex: currentSurahIndex,
        highlightedVerse: highlightedVerse!,
      ),
    );
  }
}
