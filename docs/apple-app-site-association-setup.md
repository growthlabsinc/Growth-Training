# Apple App Site Association Setup Guide

## Overview
The apple-app-site-association (AASA) file enables universal links and app associations between your website (growthlabs.coach) and your iOS app.

## File Structure

### 1. Create the AASA File
Create a file named `apple-app-site-association` (no file extension) with the following content:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.growthlabs.growthmethod",
        "paths": [
          "/app/*",
          "/method/*",
          "/routine/*",
          "/session/*",
          "/share/*"
        ]
      },
      {
        "appID": "TEAMID.com.growthlabs.growthmethod.dev",
        "paths": [
          "/app/*",
          "/method/*",
          "/routine/*",
          "/session/*",
          "/share/*"
        ]
      },
      {
        "appID": "TEAMID.com.growthlabs.growthmethod.staging",
        "paths": [
          "/app/*",
          "/method/*",
          "/routine/*",
          "/session/*",
          "/share/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAMID.com.growthlabs.growthmethod"
    ]
  }
}
```

**IMPORTANT**: Replace `TEAMID` with your actual Apple Developer Team ID (e.g., "ABC123DEF4").

### 2. Finding Your Team ID
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Sign in and go to "Membership"
3. Your Team ID is displayed there
4. Or in Xcode: Select project → Signing & Capabilities → Team → View Details

### 3. Hosting Requirements

The AASA file must be hosted at **EXACTLY** one of these URLs:
- `https://growthlabs.coach/apple-app-site-association`
- `https://growthlabs.coach/.well-known/apple-app-site-association`
- `https://www.growthlabs.coach/apple-app-site-association`
- `https://www.growthlabs.coach/.well-known/apple-app-site-association`

**Requirements:**
- ✅ HTTPS is required (no HTTP)
- ✅ No redirects allowed
- ✅ Content-Type: `application/json`
- ✅ No authentication required
- ✅ Must be accessible within 3 seconds

### 4. Web Server Configuration

#### For Nginx:
```nginx
location = /apple-app-site-association {
    root /path/to/your/static/files;
    default_type application/json;
    add_header Cache-Control "no-cache";
}

location = /.well-known/apple-app-site-association {
    root /path/to/your/static/files;
    default_type application/json;
    add_header Cache-Control "no-cache";
}
```

#### For Apache:
```apache
<Files "apple-app-site-association">
    ForceType application/json
    Header set Cache-Control "no-cache"
</Files>

<Directory "/.well-known">
    <Files "apple-app-site-association">
        ForceType application/json
        Header set Cache-Control "no-cache"
    </Files>
</Directory>
```

#### For Firebase Hosting:
Add to `firebase.json`:
```json
{
  "hosting": {
    "headers": [
      {
        "source": "/apple-app-site-association",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      },
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      }
    ]
  }
}
```

### 5. Path Patterns

Common path patterns you can use:
- `*` - All paths
- `/app/*` - All paths starting with /app/
- `/method/*/practice` - Wildcard in the middle
- `/session/?` - Single character wildcard
- `NOT /admin/*` - Exclude paths (iOS 14+)

### 6. Testing Your AASA File

#### 1. Verify File Access:
```bash
curl -I https://growthlabs.coach/apple-app-site-association
# Should return 200 OK with Content-Type: application/json

curl https://growthlabs.coach/apple-app-site-association
# Should display your JSON content
```

#### 2. Use Apple's Validator:
- Install the [Apple Configurator 2](https://apps.apple.com/us/app/apple-configurator-2/id1037126344) app
- Or use the `swcutil` command (macOS 11+):
```bash
swcutil dl -d growthlabs.coach
```

#### 3. Test on Device:
1. Install your app on a physical device (not simulator)
2. Open Safari and navigate to a universal link (e.g., https://growthlabs.coach/app/test)
3. Long press the link - you should see "Open in Growth" option
4. Or paste the link in Notes app and tap it

### 7. Common Issues and Solutions

#### Issue: Links open in Safari instead of app
- **Solution**: Check Team ID is correct
- **Solution**: Ensure AASA file is accessible without redirects
- **Solution**: Delete and reinstall the app
- **Solution**: Check entitlements include the domain

#### Issue: AASA file not updating
- **Solution**: iOS caches AASA files aggressively
- **Solution**: Delete app, reboot device, reinstall
- **Solution**: Change app version number to force refresh

#### Issue: Works in dev but not production
- **Solution**: Verify all bundle IDs are in AASA file
- **Solution**: Check both www and non-www domains

### 8. Monitoring

Add logging to track AASA file requests:
```nginx
# Nginx
access_log /var/log/nginx/aasa.log combined if=$aasa_request;
map $request_uri $aasa_request {
    ~/apple-app-site-association 1;
    default 0;
}
```

### 9. Multiple Apps Support

If you have multiple apps (e.g., a companion app):
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.growthlabs.growthmethod",
        "paths": ["/app/*", "/method/*"]
      },
      {
        "appID": "TEAMID.com.growthlabs.companion",
        "paths": ["/companion/*"]
      }
    ]
  }
}
```

### 10. Security Considerations

- Never include sensitive paths in your AASA file
- Use specific paths rather than wildcards when possible
- Regularly audit your universal links
- Consider using "NOT" patterns to exclude admin areas

## Implementation Checklist

- [ ] Find your Apple Developer Team ID
- [ ] Create apple-app-site-association file with correct JSON
- [ ] Replace TEAMID with your actual Team ID
- [ ] Upload file to web server root and/or .well-known directory
- [ ] Configure web server to serve with correct Content-Type
- [ ] Test file accessibility with curl
- [ ] Verify no redirects on the file URL
- [ ] Test on physical iOS device
- [ ] Monitor server logs for AASA requests

## Quick Start Example

For a basic setup, create this file at `https://growthlabs.coach/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.growthlabs.growthmethod",
        "paths": ["*"]
      }
    ]
  }
}
```

Replace `YOUR_TEAM_ID` with your actual Team ID and you're ready to go!