import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

void main() {
  runApp(const TriviaApp());
}

// Main application
class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trivia Showdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TriviaScreen(),
    );
  }
}

// Question model
class Question {
  final String questionText;
  final String correctAnswer;
  final List<String> options;

  Question({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();

    String correct = unescape.convert(json['correct_answer']);

    List<String> answers = [
      correct,
      ...(json['incorrect_answers'] as List).map(
        (answer) => unescape.convert(answer.toString()),
      ),
    ];

    answers.shuffle();

    return Question(
      questionText: unescape.convert(json['question']),
      correctAnswer: correct,
      options: answers,
    );
  }
}

// Main trivia screen
class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  List<Question> questions = [];

  bool isLoading = true;
  bool isFinished = false;
  bool isSynced = false;

  String? errorMessage;
  String? selectedAnswer;

  int currentIndex = 0;
  int score = 0;

  // Fetch five questions from the API
  Future<void> fetchQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      questions = [];
      currentIndex = 0;
      score = 0;
      selectedAnswer = null;
      isFinished = false;
      isSynced = false;
    });

    try {
      final url = Uri.parse(
        'https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['response_code'] != 0) {
        throw const FormatException(
          'Trivia API did not return valid questions.',
        );
      }

      final results = data['results'] as List<dynamic>;

      if (results.length != 5) {
        throw const FormatException('Expected five questions from the API.');
      }

      final loadedQuestions = results.map((item) {
        return Question.fromJson(item as Map<String, dynamic>);
      }).toList();

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;
        isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Request timed out. Please try again.';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load questions: $e';
        isLoading = false;
      });
    }
  }

  // Handle answer selection
  void selectAnswer(String answer) {
    if (selectedAnswer != null) return;

    setState(() {
      selectedAnswer = answer;

      if (answer == questions[currentIndex].correctAnswer) {
        score++;
      }
    });
  }

  // Move to the next question
  void nextQuestion() {
    setState(() {
      if (currentIndex < questions.length - 1) {
        currentIndex++;
        selectedAnswer = null;
      } else {
        isFinished = true;
      }
    });
  }

  // Simulate cloud score submission
  Future<void> syncScoreToCloud() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isSynced = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score synced successfully! (Classroom Simulation)'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trivia Showdown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading trivia questions...'),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 55,
                    ),
                    const SizedBox(height: 16),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: fetchQuestions,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : isFinished
          ? buildResultScreen()
          : buildQuestionScreen(),
    );
  }

  // Display current question and options
  Widget buildQuestionScreen() {
    final question = questions[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${currentIndex + 1} of ${questions.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(value: (currentIndex + 1) / questions.length),

          const SizedBox(height: 25),

          Text(
            question.questionText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          Text(
            'Choose your answer:',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 12),

          ...question.options.map((option) {
            Color? tileColor;

            if (selectedAnswer != null) {
              if (option == question.correctAnswer) {
                tileColor = Colors.green.shade200;
              } else if (option == selectedAnswer) {
                tileColor = Colors.red.shade200;
              }
            }

            return Card(
              color: tileColor,
              child: ListTile(
                title: Text(option),
                trailing: selectedAnswer == null
                    ? const Icon(Icons.circle_outlined)
                    : option == question.correctAnswer
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : option == selectedAnswer
                    ? const Icon(Icons.cancel, color: Colors.red)
                    : null,
                onTap: () => selectAnswer(option),
              ),
            );
          }),

          const SizedBox(height: 15),

          if (selectedAnswer != null)
            Text(
              selectedAnswer == question.correctAnswer
                  ? 'Correct answer!'
                  : 'Incorrect! Correct answer: ${question.correctAnswer}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedAnswer == question.correctAnswer
                    ? Colors.green
                    : Colors.red,
              ),
            ),

          const Spacer(),

          Text(
            'Current Score: $score',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: selectedAnswer == null ? null : nextQuestion,
            child: Text(
              currentIndex == questions.length - 1
                  ? 'Finish Quiz'
                  : 'Next Question',
            ),
          ),
        ],
      ),
    );
  }

  // Final result screen
  Widget buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 90, color: Colors.amber),

            const SizedBox(height: 20),

            const Text(
              'Trivia Completed!',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Text(
              'Your Score: $score / ${questions.length}',
              style: const TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: isSynced ? null : syncScoreToCloud,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                isSynced
                    ? 'Score Synced (Simulation)'
                    : 'Sync Score to Leaderboard',
              ),
            ),

            const SizedBox(height: 15),

            if (isSynced)
              const Text(
                'Your score was simulated successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 25),

            OutlinedButton.icon(
              onPressed: fetchQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
