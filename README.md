# LinguaAI

LinguaAI is an AI Language Learning App developed for our Flutter Final Project (Group 1, Section 2). 

## What This Project Does
LinguaAI serves as a smart language tutor that helps learners practice and improve their language skills through natural, interactive conversation. Instead of rigid lessons, users can chat freely with the AI, which acts as a fluent speaker of the target language. The app provides grammar correction, vocabulary tips, and cultural insights dynamically during the conversation.

## Supported Languages
You can currently practice and learn 12 different languages with LinguaAI:
- 🇪🇸 **Spanish** (Español)
- 🇫🇷 **French** (Français)
- 🇩🇪 **German** (Deutsch)
- 🇯🇵 **Japanese** (日本語)
- 🇰🇷 **Korean** (한국어)
- 🇨🇳 **Mandarin** (普通话)
- 🇸🇦 **Arabic** (العربية)
- 🇮🇹 **Italian** (Italiano)
- 🇺🇸 **English** (English)
- 🇮🇳 **Hindi** (हिन्दी)
- 🇧🇩 **Bengali** (বাংলা)
- 🇷🇺 **Russian** (Русский)

## How It Works
1. **AI Integration**: The core conversational logic is powered by the **Groq API** (`llama-3.3-70b-versatile` model). We use a tailored system prompt to instruct the AI to act as a supportive language tutor, providing gentle corrections and vocabulary translations in real-time.
2. **State Management**: The app uses the **Provider** package to manage the chat state, ensuring the UI updates smoothly as messages are sent and received.
3. **Data Storage**: User chat history is preserved across sessions using **Firebase Firestore**. This allows users to review past conversations and continue their learning journey where they left off.
4. **Environment Variables**: For security, sensitive keys like the Groq API key are stored locally in an ignored `.env` file (managed via `flutter_dotenv`) and are not committed to the repository.
