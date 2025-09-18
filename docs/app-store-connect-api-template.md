# App Store Connect API Configuration Template

## API Key Storage

Store these values securely. **NEVER commit these to version control.**

### Required Environment Variables

```bash
# App Store Connect API Key ID
APP_STORE_CONNECT_KEY_ID="YOUR_KEY_ID_HERE"

# App Store Connect Issuer ID  
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID_HERE"

# Path to the private key .p8 file
APP_STORE_CONNECT_PRIVATE_KEY_PATH="./AuthKey_YOUR_KEY_ID.p8"

# App Store Shared Secret (for receipt validation)
APP_STORE_SHARED_SECRET="YOUR_SHARED_SECRET_HERE"
```

### Firebase Functions Configuration

Set these values using Firebase CLI:

```bash
# Set App Store Connect configuration
firebase functions:config:set \
  appstore.key_id="YOUR_KEY_ID_HERE" \
  appstore.issuer_id="YOUR_ISSUER_ID_HERE" \
  appstore.shared_secret="YOUR_SHARED_SECRET_HERE"

# Verify configuration
firebase functions:config:get
```

### Local Development (.env.local)

For local testing, create a `.env.local` file:

```env
APP_STORE_CONNECT_KEY_ID=YOUR_KEY_ID_HERE
APP_STORE_CONNECT_ISSUER_ID=YOUR_ISSUER_ID_HERE
APP_STORE_CONNECT_PRIVATE_KEY_PATH=./AuthKey_YOUR_KEY_ID.p8
APP_STORE_SHARED_SECRET=YOUR_SHARED_SECRET_HERE
```

### Production Deployment

For production, use your CI/CD system's secret management:

- **GitHub Actions**: Use GitHub Secrets
- **Bitrise**: Use Secret Environment Variables
- **Fastlane**: Use match or environment variables
- **Xcode Cloud**: Use Environment Variables

### Key File Security

The `.p8` private key file should be:
1. Stored in a secure location (not in the repository)
2. Added to `.gitignore`
3. Encrypted if stored in CI/CD
4. Rotated periodically

### Example .gitignore entries

```gitignore
# App Store Connect API Keys
AuthKey_*.p8
.env.local
.env.production
*.p8
```

### Required API Permissions

When creating the API key in App Store Connect, ensure these permissions:
- **App Manager**: For app metadata management
- **Developer**: For TestFlight access
- **Sales and Finance**: For subscription data
- **Customer Support**: For handling support requests

### Validation Script

Use this script to validate your configuration:

```bash
#!/bin/bash
# validate-appstore-config.sh

if [ -z "$APP_STORE_CONNECT_KEY_ID" ]; then
    echo "❌ APP_STORE_CONNECT_KEY_ID not set"
    exit 1
fi

if [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    echo "❌ APP_STORE_CONNECT_ISSUER_ID not set"
    exit 1
fi

if [ ! -f "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo "❌ Private key file not found at $APP_STORE_CONNECT_PRIVATE_KEY_PATH"
    exit 1
fi

echo "✅ App Store Connect API configuration valid"
```

## Security Best Practices

1. **Never commit credentials**: Use environment variables or secure vaults
2. **Rotate keys regularly**: Every 6-12 months
3. **Limit key permissions**: Only grant necessary access
4. **Monitor key usage**: Check App Store Connect for unusual activity
5. **Use different keys**: Separate keys for dev/staging/production
6. **Encrypt in transit**: Always use HTTPS for API calls
7. **Audit access logs**: Regular security reviews

## Troubleshooting

### Common Issues

1. **401 Unauthorized**: Check key ID and issuer ID
2. **403 Forbidden**: Verify key permissions
3. **Key not found**: Ensure .p8 file path is correct
4. **Expired token**: JWT tokens expire after 20 minutes

### Debug Commands

```bash
# Check if environment variables are set
env | grep APP_STORE

# Verify .p8 file exists and is readable
ls -la "$APP_STORE_CONNECT_PRIVATE_KEY_PATH"

# Test Firebase function config
firebase functions:config:get appstore
```