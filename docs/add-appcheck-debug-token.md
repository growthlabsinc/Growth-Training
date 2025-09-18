# Adding App Check Debug Token to Xcode

## Debug Token
Your Firebase App Check Debug Token: `4C4C2F26-8881-4144-9B48-6FD556A0CD3D`

## Steps to Add as Environment Variable:

1. **Open Xcode**
2. **Select your project** in the navigator
3. **Edit Scheme:**
   - Click on the scheme selector (next to the Run/Stop buttons)
   - Select "Edit Scheme..." 
   - OR use menu: Product → Scheme → Edit Scheme (⌘<)

4. **Add Environment Variable:**
   - Select "Run" in the left sidebar
   - Click on the "Arguments" tab
   - In the "Environment Variables" section, click the "+" button
   - Add:
     - Name: `FIRAppCheckDebugToken`
     - Value: `4C4C2F26-8881-4144-9B48-6FD556A0CD3D`
   - Make sure the checkbox is enabled

5. **Optional - Add Debug Flag:**
   - Add another environment variable:
     - Name: `FIRDebugEnabled`
     - Value: `1`

6. **Apply Changes:**
   - Click "Close" to save

7. **Clean and Run:**
   - Clean Build Folder (⌘⇧K)
   - Delete app from simulator/device
   - Build and Run (⌘R)

## Verification

After running with the environment variable, you should see in the console:
```
[Firebase/AppCheck][I-FAA001001] Firebase App Check Debug Token: 4C4C2F26-8881-4144-9B48-6FD556A0CD3D
```

## Important Notes

- This token is already registered in your Firebase Console
- It will only work in DEBUG builds
- Each developer on your team can have their own debug token
- Don't commit the token to source control if it's in a configuration file

## Troubleshooting

If the token doesn't appear:
1. Make sure you're running in Debug configuration
2. Check that the environment variable is enabled (checkbox checked)
3. Ensure you've completely cleaned and rebuilt the project
4. Try deleting DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*`