# 🎯 Trivia Showdown – API-to-Cloud

A Flutter-based trivia application developed for **CSC 4360 – Mobile App Development (In-Class Activity #15)**.

## Features
- Fetches five trivia questions using the Open Trivia Database API.
- Parses JSON responses and decodes HTML entities.
- Displays loading and error states.
- Provides shuffled multiple-choice answers.
- Highlights correct answers in green and incorrect answers in red.
- Tracks the final score.
- Simulates cloud leaderboard synchronization.
- Supports replaying the quiz.

## Technologies
- Flutter & Dart
- REST API (HTTP GET)
- JSON
- HTTP package
- HTML Unescape package

## API Endpoint
```text
https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple
```

## Getting Started

Clone the repository:

```bash
git clone https://github.com/anuradha-ks/open_trivia_showdown.git
```

Navigate to the project:

```bash
cd open_trivia_showdown
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Cloud Synchronization
The application generates a JSON payload containing the final score and demonstrates an asynchronous classroom cloud-sync simulation. No actual backend submission or remote database storage is performed.


## References
- [Open Trivia Database](https://opentdb.com/)
- [Flutter Networking](https://docs.flutter.dev/cookbook/networking/fetch-data)
- [Dart HTTP Package](https://pub.dev/packages/http)