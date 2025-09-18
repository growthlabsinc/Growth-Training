# App Store Connect Setup Guide

## Current Configuration

### API Key Details
- **Key ID**: 2AK48N7L5J
- **Issuer ID**: 69a6de85-a1f9-47e3-e053-5b8c7c11a4d1
- **Key File**: AuthKey_2AK48N7L5J.p8 (stored in `.keys/` directory)

### App Configuration
- **Bundle ID**: com.growthlabs.growthmethod
- **SKU**: GROWTH2025
- **Team ID**: 62T6J77P6R

## Step-by-Step Setup

### 1. Create App in App Store Connect

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to "My Apps" → Click "+" → "New App"
3. Enter the following information:
   - **Platform**: iOS
   - **App Name**: Growth
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.growthlabs.growthmethod`
   - **SKU**: GROWTH2025
   - **User Access**: Full Access

### 2. Configure App Information

Navigate to your app and configure:

#### General Information
- **Category**: 
  - Primary: Health & Fitness
  - Secondary: Lifestyle
- **Content Rights**: Does not contain third-party content
- **Age Rating**: 17+ (due to Sexual Content and Nudity - Infrequent/Mild)

#### App Privacy
Complete the privacy questionnaire with:
- **Data Collection**:
  - Email Address (App functionality, Linked to user)
  - Health & Fitness (App functionality, Linked to user)
  - User Content (App functionality, Linked to user)
  - Product Interaction (Analytics, Linked to user)
  - Crash Data (App functionality, Not linked to user)
  - Performance Data (Analytics, Not linked to user)
- **Data Use**: App Functionality, Analytics
- **Data Tracking**: No
- **Third-party sharing**: No

### 3. Create Subscription Group

1. Navigate to "Features" → "In-App Purchases"
2. Click "+" → "Create New Subscription Group"
3. Enter:
   - **Reference Name**: Growth Membership
   - **Subscription Group ID**: growth_membership

### 4. Create Subscription Products

Create three auto-renewable subscriptions:

#### Basic Tier
- **Reference Name**: Growth Basic Monthly
- **Product ID**: com.growthlabs.growthmethod.basic_monthly
- **Subscription Duration**: 1 Month
- **Price**: Tier 5 ($4.99 USD)
- **Subscription Display Name**: Growth Basic
- **Description**: Access to 10 growth methods and enhanced progress tracking

#### Premium Tier
- **Reference Name**: Growth Premium Monthly
- **Product ID**: com.growthlabs.growthmethod.premium_monthly
- **Subscription Duration**: 1 Month
- **Price**: Tier 10 ($9.99 USD)
- **Subscription Display Name**: Growth Premium
- **Description**: All methods plus AI coaching and advanced analytics

#### Elite Tier
- **Reference Name**: Growth Elite Monthly
- **Product ID**: com.growthlabs.growthmethod.elite_monthly
- **Subscription Duration**: 1 Month
- **Price**: Tier 20 ($19.99 USD)
- **Subscription Display Name**: Growth Elite
- **Description**: Premium features plus personal coaching and priority support

### 5. Configure Server Notifications

1. Navigate to "App Information" → "App Store Server Notifications"
2. Configure:
   - **Production Server URL**: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotification`
   - **Sandbox Server URL**: `https://us-central1-growth-70a85.cloudfunctions.net/handleAppStoreNotificationSandbox`
   - **Version**: Version 2

### 6. Generate Shared Secret

1. In "Features" → "In-App Purchases"
2. Select your subscription group
3. Click "App-Specific Shared Secret" → "Generate"
4. Copy the shared secret
5. Update `.env.local` with: `APP_STORE_SHARED_SECRET=<your-secret>`
6. Run `./scripts/configure-appstore-connect.sh` to update Firebase

### 7. Configure TestFlight

1. Navigate to "TestFlight" tab
2. Complete "Test Information":
   - **Beta App Description**: Test the latest features of Growth - your personal wellness and fitness companion
   - **Email**: beta@growth-app.com
   - **Privacy Policy URL**: https://growth-app.com/privacy
   - **License Agreement**: Use Apple's standard EULA

3. Create Internal Testing Group:
   - **Group Name**: Growth Development Team
   - Enable "Automatic Distribution"
   - Add team members by email

### 8. Prepare for App Review

#### Required Assets
- [ ] App Icon (1024x1024)
- [ ] Screenshots:
  - iPhone 6.7" (1290 × 2796)
  - iPhone 6.5" (1242 × 2688 or 1284 × 2778)
  - iPhone 5.5" (1242 × 2208)
  - iPad Pro 12.9" (2048 × 2732)

#### App Description
```
Growth is your personal wellness and fitness companion, designed to help you achieve your health goals through scientifically-backed methods and personalized routines.

Features:
• 20+ growth methods with detailed instructions
• Personalized training routines
• Progress tracking and analytics
• AI-powered coaching (Premium)
• Live activity support for workouts
• Community challenges and achievements

Start your journey today with our free tier, or unlock premium features for advanced analytics and AI coaching.
```

#### Keywords
```
health, fitness, wellness, exercise, personal development, habits, routines, progress tracking, mindfulness, adult health, guided workouts, fitness education
```

## Validation Checklist

- [ ] App created in App Store Connect
- [ ] Bundle ID matches: com.growthlabs.growthmethod
- [ ] All three subscription tiers created
- [ ] Server notification URLs configured
- [ ] Shared secret generated and stored
- [ ] TestFlight configured
- [ ] Privacy details completed
- [ ] API key working (test with validation script)

## Testing the Configuration

Run the validation script:
```bash
./scripts/validate-appstore-config.sh
```

Update Firebase configuration:
```bash
./scripts/configure-appstore-connect.sh
```

## Security Notes

- The API key file is stored in `.keys/` which is gitignored
- Never commit the `.env.local` file
- Rotate API keys every 6-12 months
- Keep the shared secret secure

## Support

For issues with App Store Connect:
- Review [App Store Connect Help](https://help.apple.com/app-store-connect/)
- Check [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Contact Apple Developer Support if needed