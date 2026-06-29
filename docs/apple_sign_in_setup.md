# Sign in with Apple setup

This app shows the Apple sign-in button only on iOS. Complete the following release configuration before submitting to App Store Review.

## Apple Developer / Xcode

1. In Apple Developer > Certificates, Identifiers & Profiles > Identifiers, open the explicit App ID for `com.kono.judoexam`.
2. Enable the **Sign in with Apple** capability for that App ID and save it.
3. Regenerate/download provisioning profiles that include the new capability.
4. In Xcode, open `ios/Runner.xcworkspace` and confirm Runner > Signing & Capabilities contains **Sign in with Apple**.
5. The repository includes `ios/Runner/Runner.entitlements` with `com.apple.developer.applesignin = Default`; keep it assigned to every Runner build configuration.

## Firebase Authentication

1. Firebase Console > Authentication > Sign-in method > **Apple** > Enable.
2. For iOS-only Firebase Authentication, confirm the app uses bundle ID `com.kono.judoexam` and that `ios/Runner/GoogleService-Info.plist` is the current file for the same Firebase project.
3. If Apple asks for service identifiers or private keys because you later enable Apple sign-in on Android/web, create an Apple Services ID, private key, Team ID, and Key ID in Apple Developer, then enter those values in the Firebase Apple provider settings. This implementation intentionally does not show or use Apple sign-in on Android.
4. After enabling the provider, test with a real iOS device or a simulator signed into an Apple ID that supports Sign in with Apple.

## App Store Review note

The login screen offers Google sign-in and, on iOS only, Sign in with Apple on the same screen. Android continues to hide the Apple button.
