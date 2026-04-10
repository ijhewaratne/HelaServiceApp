# Firestore Security Rules Documentation

## Current Production Rules

The complete security rules are in `/firestore.rules`. Key features:

### Helper Functions
```
isAuthenticated() - User is logged in
isAdmin() - User has admin claim
isWorkerInZone(workerId, zoneId) - Worker allowed in zone
```

### Collection Access Summary

| Collection | Access Pattern |
|------------|---------------|
| `users/{id}` | Owner read/write |
| `customer_profiles/{id}` | Owner read/write (PDPA) |
| `workers/{id}` | Owner read/write, verification protected |
| `workers/{id}/private_data/{doc}` | Owner only (sensitive data) |
| `worker_documents/{id}` | Owner only (KYC docs) |
| `jobs/{id}` | Participant read, customer create, worker update |
| `job_locations/{id}` | Active job participants only |
| `job_requests/{id}` | Customer create, assigned worker update, participant read |
| `job_offers/{id}` | Worker read own offers, worker update status |
| `worker_locations/{id}` | Worker write only, Cloud Functions read |
| `messages/{id}` | Participant read, authenticated create with timestamp |
| `audit_logs/{id}` | Immutable, admin read only |

### Security Principles
1. **PDPA Compliance** - Customer data only accessible by owner
2. **Worker Privacy** - Bank details, NIC in protected subcollections
3. **Job State Machine** - Updates restricted by status transitions
4. **Location Privacy** - Live locations only during active jobs
5. **Immutable Audit** - Labor dispute protection via write-once logs
6. **Zone Enforcement** - Workers can only work in allowed zones

### Deployment
```bash
firebase deploy --only firestore:rules
```

## Appendix A: Simplified Reference Rules

For quick reference, here's a simplified version of the security rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && request.auth.token.admin == true;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
    }

    match /workers/{workerId} {
      allow read: if isOwner(workerId) || isAdmin();
      allow create: if isOwner(workerId);
      allow update: if isOwner(workerId) || isAdmin();
      
      match /private/{doc} {
        allow read, write: if isOwner(workerId) || isAdmin();
      }
    }

    match /worker_locations/{workerId} {
      allow write: if isOwner(workerId);
      allow read: if isAdmin();
    }

    match /customers/{customerId} {
      allow read, write: if isOwner(customerId) || isAdmin();
    }

    match /jobs/{jobId} {
      allow read: if isAuthenticated() && 
        (resource.data.customerId == request.auth.uid ||
         resource.data.workerId == request.auth.uid ||
         isAdmin());
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
        (resource.data.customerId == request.auth.uid ||
         resource.data.workerId == request.auth.uid ||
         isAdmin());
    }

    match /job_offers/{offerId} {
      allow read: if isAuthenticated() && 
        resource.data.workerId == request.auth.uid;
      allow update: if isAuthenticated() && 
        resource.data.workerId == request.auth.uid;
    }

    match /messages/{messageId} {
      allow read: if isAuthenticated() &&
        (resource.data.senderId == request.auth.uid ||
         resource.data.receiverId == request.auth.uid);
      allow create: if isAuthenticated() &&
        request.resource.data.createdAt != null;
    }

    match /audit_logs/{logId} {
      allow create: if isAuthenticated();
      allow read: if isAdmin();
      allow update, delete: if false;
    }

    match /{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

### Testing Security Rules

```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start emulator
firebase emulators:start --only firestore

# Run tests
firebase emulators:exec --only firestore "npm test"
```

### Rule Validation CI

The project includes automatic security rule validation in GitHub Actions:
- Checks for overly permissive rules (`allow read, write: if true`)
- Validates helper function usage
- Ensures admin override exists

---

## Firebase Storage Security Rules

Location: `/storage.rules`

### Rules Summary

| Path | Read | Write | Constraints |
|------|------|-------|-------------|
| `/workers/{workerId}/{file}` | Owner, Admin | Owner | Max 5MB, images only |
| `/workers/{workerId}/profile.jpg` | Authenticated | Owner | Public read for trust badges |
| All other paths | Denied | Denied | - |

### File Upload Validation
- Maximum file size: 5MB (NIC images), 2MB (profile photos)
- Allowed content types: `image/*`
- PDPA: Only worker can access their own documents
- Profile photos are public for customer trust
- NIC documents remain private (owner/admin only)

### Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Worker documents - owner only
    match /workers/{workerId}/{fileName} {
      allow read, write: if request.auth != null 
        && request.auth.uid == workerId
        && request.resource.size <= 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Admin access for verification
    match /workers/{workerId}/{fileName} {
      allow read: if request.auth != null 
        && request.auth.token.admin == true;
    }

    // Profile photos - public read
    match /workers/{workerId}/profile.jpg {
      allow read: if request.auth != null;
    }

    // Deny all else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Deployment
```bash
firebase deploy --only storage
```
