# How to Create a New APNs Authentication Key

## Step-by-Step Guide

### 1. Sign in to Apple Developer
- Go to https://developer.apple.com
- Sign in with your Apple ID (the one associated with your business developer account)
- Make sure you're signed in to the correct team: **GrowthMethodLive** (Team ID: 62T6J77P6R)

### 2. Navigate to Keys
- Click on "Account" in the top menu
- In the left sidebar, under "Certificates, IDs & Profiles", click on "Keys"
- Or go directly to: https://developer.apple.com/account/resources/authkeys/list

### 3. Create a New Key
- Click the blue "+" button (Create a key)
- You'll see the "Register a New Key" page

### 4. Configure the Key
- **Key Name**: Enter a descriptive name like "Growth Method APNs Production" or "Growth Live Activity Push"
- **Enable Services**: Check the box for "Apple Push Notifications service (APNs)"
- Leave other services unchecked unless you need them

### 5. Continue and Register
- Click "Continue"
- Review your key configuration
- Click "Register"

### 6. Download the Key (CRITICAL!)
- You'll see a "Download Your Key" page
- **IMPORTANT**: Click "Download" to save the .p8 file
- **⚠️ WARNING**: You can only download this file ONCE. Apple will not let you download it again!
- Save it somewhere safe (like your password manager or secure documents folder)
- The file will be named something like: `AuthKey_XXXXXXXXXX.p8`

### 7. Note the Key ID
- On the same page, you'll see your Key ID (looks like: XXXXXXXXXX)
- Copy this Key ID - you'll need it for the Firebase configuration
- It will be different from your old key ID (KD9A39PBA7)

### 8. After Download
- Click "Done"
- You'll see your new key listed in the Keys page
- The key will show:
  - Name: What you named it
  - Key ID: The 10-character identifier
  - Services: Apple Push Notifications

## What You'll Have After This Process

1. **A .p8 file** (Example: `AuthKey_ABC123DEF4.p8`)
   - Contains your private key
   - Keep this secure!
   - You'll paste its contents into the Firebase function

2. **A Key ID** (Example: `ABC123DEF4`)
   - This replaces your old `KD9A39PBA7`
   - You'll use this in the Firebase configuration

## Next Steps

Once you have both the .p8 file and Key ID:

1. Open the .p8 file in a text editor
2. Copy the entire contents (including the BEGIN/END lines)
3. Update the Firebase function with the new key and ID
4. Deploy the updated function

## Troubleshooting

**"You have already reached the maximum allowed number of Keys"**
- Apple limits you to 2 active keys
- You may need to revoke an old key first
- Go to your Keys list and revoke one you're not using

**Can't see the Keys section**
- Make sure you have the right permissions in your developer team
- You need Admin or App Manager role

**Wrong Team Selected**
- Check the team dropdown in the top right
- Make sure "GrowthMethodLive" is selected