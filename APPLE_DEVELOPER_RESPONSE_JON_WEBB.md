# Apple Developer Response - Jon Webb

**Developer Name**: Jon Webb  
**Topic**: Delivery issues with push notifications

## Key Information from Apple Developer Support

Delivery issues with push notifications can usually be determined by examining the responses from APNs.

APNs will return useful information both in the HTTP/2 header response, and as a JSON dictionary for unsuccessful requests. You can find the list of responses, and further troubleshooting steps in the article **Handling Notification Responses from APNs**.

If the above document does not help clarify the issue, or issues with receiving notifications persist despite receiving an error status neither in the HTTP/2 headers nor in the response JSON dictionary, we may be able to assist you with diagnosing the issue.

If you are using a third-party push notification provider service, we recommend to contact them first to make sure the issue is not between your app and their service, and to obtain information on any errors they might be receiving from Apple servers.

## Required Information for Diagnosis

To help diagnose the issue, we will need some information about the push requests. Please include the following information in your post, for a failed or delayed notification that has been attempted **within the last 48 hours**:

### Required Information:
1. **Exact time and date** (including time zone) of the push request sent
2. **Exact time and date** (including time zone) of the notification received by the device (if received at all)
3. Your app's **Bundle ID**
4. The **token** the push was sent to
5. The returned **(error) status and message** from APNs
6. **Full contents of the HTTP/2 headers**
7. **Full contents of the payload**

### Helpful Additional Information:
- If using your own server to send: the **public IPv4 address** of the push provider server used to send the push
- If using a third-party service to send: the **name of the third-party push provider service** used
- The **push topic** (apns-topic header value)
- The **push type** (alert, background, VoIP, other)
- The **apns-id** (either set in your request, or received from the HTTP/2 header response)
- Any **logging** you have from the server side that shows the interaction with it and APNs

## Important Note

If you are using a third-party push provider service, and do not have the above necessary info, or only have the info you are providing to the service, please first contact the service provider for a resolution or to give you the above specific information.

When posting about an issue you are having with sending/receiving push notifications, include the above required information and as much of the secondary helpful information you can collect with your post in an organized manner for us to be able to help with diagnosing the issues.

---

## Our Current Information for Growth Method App

### Required Information Available:
1. **Exact time and date**: 2025-07-13T02:43:48.339548Z (UTC)
2. **Bundle ID**: com.growthlabs.growthmethod
3. **Error status**: 403 InvalidProviderToken
4. **HTTP/2 headers**: 
   ```
   ':status': 403,
   'apns-id': '8E478634-93DC-0160-B592-456C62E61956'
   ```
5. **Payload**: Available in Firebase function logs

### Additional Information:
- **Push provider**: Firebase Cloud Functions (Google Cloud)
- **Push topic**: com.growthlabs.growthmethod.push-type.liveactivity
- **Push type**: liveactivity
- **APNs endpoint**: api.development.push.apple.com
- **Authentication**: JWT token with Key ID 378FZMBP8L

### What We Need to Collect:
- [ ] Exact push token from a failed request
- [ ] Full HTTP/2 request headers being sent
- [ ] Public IPv4 address of Firebase Functions server
- [ ] Complete server-side logs showing the full APNs interaction