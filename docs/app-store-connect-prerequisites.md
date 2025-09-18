# App Store Connect Prerequisites Verification

## Apple Developer Program Membership Requirements

### Active Membership Verification
- **Requirement:** Valid Apple Developer Program membership ($99/year)
- **Status:** ⚠️ **USER ACTION REQUIRED**
- **Verification Steps:**
  1. Log into [Apple Developer Portal](https://developer.apple.com/account/)
  2. Verify active membership status in Account section
  3. Confirm renewal date is at least 6 months future
  4. Document membership details below

### Membership Details (USER TO COMPLETE)
```
[ ] Apple ID: _________________
[ ] Team ID: _________________
[ ] Membership Expiry: _______
[ ] Organization Name: _______
```

## App Store Connect Access Permissions

### Required Role Permissions
- **Minimum Required:** Account Holder or Admin role
- **Status:** ⚠️ **USER ACTION REQUIRED**
- **Verification Steps:**
  1. Log into [App Store Connect](https://appstoreconnect.apple.com/)
  2. Navigate to Users and Roles
  3. Verify current user has Admin or Account Holder permissions
  4. Confirm access to Agreements, Tax, and Banking sections

### Permission Verification Checklist
```
[ ] Can access App Store Connect dashboard
[ ] Can view Agreements, Tax, and Banking
[ ] Can create new apps in App Store Connect
[ ] Can manage subscription products
[ ] Can create App Store Connect API keys
[ ] Can access App Analytics and Sales Reports
```

## Environment Separation Strategy

### Sandbox vs Production Configuration
- **Sandbox Environment:** For development and testing
  - Uses sandbox Apple IDs for testing
  - Separate subscription products for testing
  - No real financial transactions
  
- **Production Environment:** For live app store
  - Real customer transactions
  - Live subscription products
  - Production webhook endpoints

### Environment Configuration Checklist
```
[ ] Sandbox testing environment access verified
[ ] Production environment access documented
[ ] Separate Firebase environments configured for sandbox/production
[ ] Webhook endpoints separated by environment
[ ] API credentials separated by environment
```

## App Store Connect API Requirements

### API Access Prerequisites
- **Requirement:** App Store Connect API key with appropriate permissions
- **Status:** ⚠️ **USER ACTION REQUIRED**
- **Required Permissions:**
  - App Store Connect API Access
  - Developer ID Certificate Management (if needed)
  - Provisioning Profile Management (if needed)

### API Key Generation Process (USER RESPONSIBILITY)
1. Log into App Store Connect
2. Navigate to Users and Roles → Keys
3. Click "+" to generate new API key
4. Select appropriate permissions:
   - **Developer:** For app management
   - **Finance:** For subscription/financial data (if needed)
   - **Admin:** For full access (recommended)
5. Download private key (.p8 file)
6. Note Key ID and Issuer ID
7. Store credentials securely

### API Credentials Template (USER TO COMPLETE)
```
[ ] Key ID: _________________
[ ] Issuer ID: ______________
[ ] Private Key (.p8 file): Stored securely
[ ] API Key Name: __________
[ ] Permissions Level: _____
```

## Security and Compliance Requirements

### Credential Security
- Store private key (.p8 file) in secure location
- Never commit API credentials to version control
- Use environment variables for credential storage
- Implement credential rotation strategy

### Compliance Considerations
- GDPR compliance for EU users
- App Store Review Guidelines compliance
- Subscription terms and conditions
- Privacy policy updates for subscription features

## Verification Completion

### Final Checklist
```
[ ] Apple Developer Program membership verified and documented
[ ] App Store Connect access permissions confirmed
[ ] Environment separation strategy documented
[ ] API credentials generated and securely stored
[ ] Security and compliance requirements reviewed
[ ] All user responsibilities completed
```

**Status:** ⚠️ Pending user completion of manual verification steps

**Next Steps:** Once user completes all verification steps, proceed to automated infrastructure setup.

---

**Created:** {CURRENT_DATE}
**Last Updated:** {CURRENT_DATE}
**Owner:** Development Team
**Status:** Pending User Action