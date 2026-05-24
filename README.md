# Aparna: Empowering Women's Health

Aparna is a comprehensive, multi-language mobile application designed to empower women with health tracking, educational resources, and professional support. Built with a focus on ease of use and accessibility, it provides personalized period prediction, informative health blogs, and a directory of expert clinics.

## 🚀 Key Features

- **Period Cycle Tracking & Prediction**: Intelligent prediction of menstrual cycles based on historical data using machine learning models.
- **Educational Health Blogs**: A curated collection of articles on women's health, searchable and categorized for easy navigation.
- **Expert Clinics Locator**: Integration with a directory of specialized clinics for professional medical assistance.
- **Real-time Notifications**: Instant updates on period dates, new articles, and account activity via Firebase Cloud Messaging.
- **Admin Dashboard**: A robust management suite for administrators to manage users, publish blogs, and view app analytics.
- **Dynamic Localization**: Full support for both **English** and **Nepali** languages, accessible throughout the app.
- **Secure Authentication**: PIN-based security and JWT-authenticated API requests.

## 🛠️ Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: BLoC 
- **Localization**: Flutter Gen-L10n
- **Media**: Image Picker for profile and blog uploads
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Backend
- **Framework**: [Node.js](https://nodejs.org/) with [Express.js](https://expressjs.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/) (pg)
- **AI/ML**: Google Gemini AI & Random Forest for cycle prediction
- **Authentication**: JWT (JSON Web Tokens) & Bcrypt
- **File Handling**: Multer for image and video uploads
- **Emails**: Nodemailer for system communications

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest Stable)
- [Node.js](https://nodejs.org/) (v16+)
- [PostgreSQL](https://www.postgresql.org/download/)
- [Firebase account](https://console.firebase.google.com/) (for FCM)

### 📂 Project Structure
```
Diksha-Ghimire-Aparna/
├── Aparna/aparna/         # Flutter Mobile Application
└── aparna-backend/        # Node.js Server & Database Logic
```

### ⚙️ Backend Setup
1.  Navigate to the backend directory:
    ```bash
    cd aparna-backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure your environment variables (`.env` file):
    ```env
    DB_USER=your_user
    DB_PASSWORD=your_password
    DB_HOST=localhost
    DB_PORT=5432
    DB_DATABASE=aparna_db
    JWT_SECRET=your_jwt_secret
    ```
4.  Run the development server:
    ```bash
    npm run dev
    ```

### 📱 Frontend Setup
1.  Navigate to the frontend directory:
    ```bash
    cd Aparna/aparna
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Generate localization files:
    ```bash
    flutter gen-l10n
    ```
4.  Update API configuration:
    - Edit `lib/core/constant/apiConstant.dart` to point to your backend IP address (e.g., `http://192.168.100.4:3000/`).
5.  Run the application:
    ```bash
    flutter run
    ```

## 👥 Contributors
Developed by **Diksha Ghimire** 
