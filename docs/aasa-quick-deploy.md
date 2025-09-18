# Quick Deploy: Apple App Site Association

## Your File is Ready! 

The `apple-app-site-association` file has been created with your Team ID: `62T6J77P6R`

## Deploy Steps

### Option 1: Simple Web Hosting (Recommended)

1. **Upload the file** to your web server at one of these locations:
   - `https://growthlabs.coach/apple-app-site-association`
   - `https://growthlabs.coach/.well-known/apple-app-site-association`

2. **Set the Content-Type** to `application/json`

3. **Test it works**:
   ```bash
   curl https://growthlabs.coach/apple-app-site-association
   ```

### Option 2: Firebase Hosting

1. **Copy the file** to your Firebase public directory:
   ```bash
   cp apple-app-site-association functions/public/
   cp apple-app-site-association functions/public/.well-known/
   ```

2. **Update firebase.json**:
   ```json
   {
     "hosting": {
       "public": "public",
       "headers": [
         {
           "source": "/apple-app-site-association",
           "headers": [{
             "key": "Content-Type",
             "value": "application/json"
           }]
         }
       ]
     }
   }
   ```

3. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

### Option 3: GitHub Pages

1. **Add to your repo** at:
   - Root: `/apple-app-site-association`
   - Or: `/.well-known/apple-app-site-association`

2. **Add _config.yml**:
   ```yaml
   include:
     - apple-app-site-association
     - .well-known
   ```

## Test Your Setup

Run the validation script:
```bash
./scripts/validate-aasa.sh growthlabs.coach
```

## Testing Universal Links

1. **Install app** on a physical iOS device (not simulator)
2. **Create a test link**: https://growthlabs.coach/app/test
3. **Test in Notes app**: 
   - Paste the link
   - Tap and hold
   - Should see "Open in Growth"

## Troubleshooting

**Links not working?**
- Delete and reinstall the app
- Check the validation script output
- Ensure no redirects on the AASA file URL
- Wait 5-10 minutes for CDN propagation

**Still not working?**
- Reboot the iOS device
- Check Console.app logs while installing
- Verify entitlements include `growthlabs.coach`

## Your App IDs

Based on your configuration:
- Production: `62T6J77P6R.com.growthlabs.growthmethod`
- Development: `62T6J77P6R.com.growthlabs.growthmethod.dev`
- Staging: `62T6J77P6R.com.growthlabs.growthmethod.staging`