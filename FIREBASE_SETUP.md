# Firebase Authentication Setup Guide

## Setting Up 3 Users for Sales Tracker

To secure your app with password authentication, you need to create 3 user accounts in Firebase Authentication.

### Steps to Create Users:

1. **Go to Firebase Console**
   - Visit https://console.firebase.google.com
   - Select your project (sales_tracker)

2. **Navigate to Authentication**
   - Click on "Authentication" in the left sidebar
   - Click on "Get started" if you haven't enabled it yet

3. **Enable Email/Password Authentication**
   - Click on the "Sign-in method" tab
   - Find "Email/Password" in the list
   - Click on it and toggle "Enable" to ON
   - Click "Save"

4. **Create the 3 Users**
   - Go to the "Users" tab in Authentication
   - Click "Add user" button
   - Enter email and password for each user:
   
   **User 1:**
   - Email: `user1@fhtechnology.com` (or your preferred email)
   - Password: (choose a strong password)
   
   **User 2:**
   - Email: `user2@fhtechnology.com` (or your preferred email)
   - Password: (choose a strong password)
   
   **User 3:**
   - Email: `user3@fhtechnology.com` (or your preferred email)
   - Password: (choose a strong password)

5. **Share Credentials Securely**
   - Share the email and password with each user securely
   - Each user will use their credentials to log in to the app

### Security Features:

✅ **Password Protection**: Users must enter correct email and password to access the app

✅ **Session Management**: Users stay logged in until they logout or session expires

✅ **Remember Me**: Email is saved locally (not password) for convenience

✅ **Auto Logout**: If someone takes a device, they can't access the app without credentials

### Notes:

- All 3 users have **full access** to all features (add items, sell items, view transactions, etc.)
- Passwords are securely stored in Firebase (never stored in the app)
- Users can logout using the logout button in the dashboard
- The app automatically redirects to login if user is not authenticated

### Testing:

After creating users, test the login:
1. Run the app: `flutter run`
2. Enter one of the user emails and password
3. You should be redirected to the Dashboard
4. Click logout to test logout functionality

