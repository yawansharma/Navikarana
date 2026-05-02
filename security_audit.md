# 🔒 Comprehensive Security Audit — Upasthiti

**Application:** Upasthiti (Flutter attendance management system)  
**Date:** 2026-05-02  
**Auditor:** Antigravity AI  
**Risk Summary:**

| Severity | Count |
|----------|-------|
| 🔴 Critical | 5 |
| 🟠 High | 7 |
| 🟡 Medium | 6 |
| 🔵 Low | 4 |

---

## 1. Authentication & Credential Management

### 🔴 CRIT-01: Plaintext Password Storage in Database

- **Files:** [register_page.dart](file:///d:/VirtualVIsionTestTool/lib/register_page.dart#L170-L183), [main.dart](file:///d:/VirtualVIsionTestTool/lib/main.dart#L218-L225), [admin_login.dart](file:///d:/VirtualVIsionTestTool/lib/admin_login.dart#L108-L115)
- **Description:** Passwords are stored as raw plaintext in the Appwrite `users` collection. Login queries match passwords via `Query.equal('password', password)`.
- **Exploit:** Any database breach, admin panel access, or Appwrite console access exposes every user's password in cleartext. The Dean portal (see CRIT-02) literally displays admin passwords in an editable TextField.
- **Impact:** Complete credential compromise of all users. Password reuse across services compounds the damage.
- **Fix:**
  - Hash passwords client-side with bcrypt/Argon2 before storing.
  - Better: use Appwrite's built-in Auth system (`account.create()`, `account.createEmailPasswordSession()`) which handles hashing, sessions, and tokens automatically.
  - Never query by password field — authenticate via Appwrite Auth sessions.

---

### 🔴 CRIT-02: Hardcoded Dean Credentials in Source Code

- **File:** [dean_login.dart](file:///d:/VirtualVIsionTestTool/lib/dean_login.dart#L77)
- **Description:** The highest-privilege account uses hardcoded credentials: `deanId == "dean" && password == "dean123"`. The comment even says "Hardcoded for maximum security" — this is the opposite of secure.
- **Exploit:** Anyone who decompiles the APK (trivial with `apktool`/`jadx`) or reads the source code gets full super-admin access. The credentials are also extremely weak.
- **Impact:** Complete system takeover — the Dean can create/delete admins, override passwords, migrate data, and impersonate any admin.
- **Fix:**
  - Store the Dean account in the database with the same auth system as other users.
  - Use Appwrite Auth with proper role-based permissions.
  - Enforce strong password requirements.

---

### 🟠 HIGH-03: Dean Portal Displays & Allows Password Override in Plaintext

- **File:** [dean_home_page.dart](file:///d:/VirtualVIsionTestTool/lib/dean_home_page.dart#L633-L754)
- **Description:** `_showAdminDetails()` pre-populates a `TextField` with the admin's raw password (`data['password']`) and allows overriding it to any value with no confirmation beyond a button tap.
- **Exploit:** Shoulder surfing reveals admin passwords. No audit trail for password changes.
- **Impact:** Admin impersonation, unauthorized access to admin panels.
- **Fix:** Never display existing passwords. Require current-password or MFA confirmation for password resets. Log all password change events.

---

### 🟠 HIGH-04: No Session Management / Persistent Authentication

- **Files:** All login pages, all home pages
- **Description:** The app has zero session management. "Logout" simply navigates to the login page via `Navigator.pushAndRemoveUntil()`. There are no auth tokens, no session expiry, no Appwrite account sessions. Anyone who presses "back" or reconstructs the navigation stack can access the app without re-authenticating.
- **Exploit:** On shared/stolen devices, the previous user's data remains accessible. Deep links or state restoration could bypass login.
- **Impact:** Unauthorized access to user accounts.
- **Fix:**
  - Use Appwrite's session management (`account.createEmailPasswordSession()`).
  - Check for valid session on app start.
  - Implement proper session expiry and token refresh.
  - Clear all cached data on logout.

---

### 🟡 MED-05: No Password Strength Enforcement

- **File:** [register_page.dart](file:///d:/VirtualVIsionTestTool/lib/register_page.dart#L185-L215)
- **Description:** Registration accepts any password with no minimum length, complexity, or entropy requirements.
- **Exploit:** Users can set passwords like "1", "a", or empty strings (after trim).
- **Impact:** Trivial brute-force or guessing attacks.
- **Fix:** Enforce minimum 8 characters, require mixed case + numbers. Validate on both client and server.

---

### 🟡 MED-06: No Account Lockout / Rate Limiting

- **Files:** [main.dart](file:///d:/VirtualVIsionTestTool/lib/main.dart#L175-L271), [admin_login.dart](file:///d:/VirtualVIsionTestTool/lib/admin_login.dart#L64-L168)
- **Description:** Failed login attempts have no limit. The captcha on admin login provides minimal protection (client-side only, easily automated).
- **Exploit:** Automated brute-force attacks against any account. The captcha is generated and validated client-side, so an attacker can bypass it entirely by calling the Appwrite API directly.
- **Impact:** Credential compromise through brute force.
- **Fix:** Implement server-side rate limiting via Appwrite Functions. Add progressive delays and account lockout after N failed attempts.

---

### 🔵 LOW-07: Client-Side-Only Captcha

- **File:** [admin_login.dart](file:///d:/VirtualVIsionTestTool/lib/admin_login.dart#L56-L61)
- **Description:** The captcha is generated and validated entirely on the client. It provides zero protection against automated attacks — only inconveniences legitimate users.
- **Fix:** Use a server-side captcha service (reCAPTCHA, hCaptcha) or remove it entirely if relying on proper rate limiting.

---

## 2. Data Security & Sensitive Data Exposure

### 🔴 CRIT-08: Hardcoded Google Maps API Key in AndroidManifest

- **File:** [AndroidManifest.xml](file:///d:/VirtualVIsionTestTool/android/app/src/main/AndroidManifest.xml#L12-L13)
- **Description:** The Google Maps API key `AIzaSyBZHk8D5L8x7rrHBFqrZBRIeuxYCkaITak` is hardcoded in plain XML, committed to source control.
- **Exploit:** Extractable from the APK. Can be used for unauthorized API calls, potentially incurring billing charges.
- **Impact:** Financial abuse, quota exhaustion, service disruption.
- **Fix:**
  - Restrict the API key to specific APIs (Maps SDK only) and specific app signatures in Google Cloud Console.
  - Use `local.properties` or environment variables, excluded from version control.
  - Add API key restrictions (HTTP referrer, Android app, IP restrictions).

---

### 🔴 CRIT-09: Hardcoded Appwrite Project ID & Database IDs

- **File:** [appwrite_service.dart](file:///d:/VirtualVIsionTestTool/lib/services/appwrite_service.dart#L4-L5)
- **Description:** The Appwrite endpoint, project ID (`69ecea2600127cefd5b2`), and database ID (`69ecebfb0033cf785741`) are hardcoded throughout the codebase. While project IDs are semi-public in client apps, the real issue is that this app **relies entirely on these IDs for security** with no server-side authorization layer.
- **Exploit:** An attacker can use the project ID to directly query the Appwrite API, bypassing the app entirely. If collection-level permissions are misconfigured, they can read/write any data.
- **Impact:** Full database read/write access if Appwrite permissions are not properly configured.
- **Fix:**
  - Configure strict collection-level permissions in Appwrite (only authenticated users, role-based).
  - Use Appwrite Auth so that document-level permissions work.
  - Move sensitive operations to Appwrite Functions (server-side).

---

### 🟠 HIGH-10: Firebase Configuration Exposed

- **File:** [firebase.json](file:///d:/VirtualVIsionTestTool/firebase.json)
- **Description:** Firebase project ID (`unknown-23ada`) and app IDs for all platforms are committed to the repository.
- **Impact:** While Firebase config is semi-public by design, combined with other misconfigurations it can be exploited.
- **Fix:** Ensure Firebase Security Rules are properly configured. Add `.gitignore` entries for sensitive config files.

---

### 🟠 HIGH-11: Verbose Error Messages Expose System Internals

- **Files:** [main.dart:L269](file:///d:/VirtualVIsionTestTool/lib/main.dart#L269), [admin_login.dart:L166](file:///d:/VirtualVIsionTestTool/lib/admin_login.dart#L166), [register_page.dart:L211](file:///d:/VirtualVIsionTestTool/lib/register_page.dart#L211)
- **Description:** Error messages display raw exception details to users: `"An unexpected error occurred: $e"`. This leaks stack traces, Appwrite error codes, collection names, and internal structure.
- **Exploit:** Attackers use error messages to map the backend architecture and craft targeted attacks.
- **Impact:** Information disclosure aiding further exploitation.
- **Fix:** Show generic error messages to users. Log detailed errors to a secure monitoring service (e.g., Sentry, Crashlytics).

---

## 3. Authorization & Access Control

### 🔴 CRIT-12: No Server-Side Authorization — All Security is Client-Side

- **Files:** All files performing RBAC checks
- **Description:** Every authorization check is performed in Dart on the client:
  - User login checks `role != 'admin'` client-side ([main.dart:L236](file:///d:/VirtualVIsionTestTool/lib/main.dart#L236))
  - Admin login checks `role == 'admin'` client-side ([admin_login.dart:L128](file:///d:/VirtualVIsionTestTool/lib/admin_login.dart#L128))
  - Admin level restrictions (`adminLevel < 2`) are UI-only ([admin_home_page.dart:L495](file:///d:/VirtualVIsionTestTool/lib/admin_home_page.dart#L495))
  
  The Appwrite database appears to use a single shared client with no per-user authentication. Any user can call the Appwrite API directly and bypass all role checks.
- **Exploit:** Using the Appwrite SDK with the publicly exposed project ID, an attacker can:
  1. Query all users and their plaintext passwords
  2. Create admin accounts
  3. Delete any document
  4. Modify attendance records
  5. Impersonate any user
- **Impact:** Complete system compromise. All RBAC is theater.
- **Fix:**
  - **Use Appwrite Auth** for user authentication (creates server-managed sessions).
  - **Set collection permissions** to restrict access by role (e.g., only `role:admin` can write to `users` collection).
  - **Use Appwrite Functions** for sensitive operations (user creation, role changes, password updates).
  - **Never trust client-side role checks** as the sole authorization mechanism.

---

### 🟠 HIGH-13: Any User Can Create Admin Accounts via Direct API

- **File:** [dean_home_page.dart](file:///d:/VirtualVIsionTestTool/lib/dean_home_page.dart#L569-L587)
- **Description:** Admin account creation writes directly to the `users` collection with `role: 'admin'`. Since there's no server-side auth, anyone with the project ID can create admin accounts.
- **Exploit:** Craft an Appwrite API call: `databases.createDocument(... data: { 'role': 'admin', 'username': 'evil', 'password': 'evil' })`.
- **Impact:** Privilege escalation to full admin access.
- **Fix:** Admin creation must go through a server-side Appwrite Function that verifies the caller is a Dean.

---

### 🟠 HIGH-14: Profile Page Allows Password Change Without Current Password

- **File:** [profile_page.dart](file:///d:/VirtualVIsionTestTool/lib/profile_page.dart#L25-L61)
- **Description:** The password change flow only requires the username and new password — no current password verification, no email confirmation, no MFA.
- **Exploit:** On a shared/unlocked device, anyone can change any user's password by entering their username.
- **Impact:** Account takeover.
- **Fix:** Require current password or secondary verification before allowing password changes.

---

### 🟡 MED-15: Hidden Dean Portal is Security Through Obscurity

- **File:** [main.dart](file:///d:/VirtualVIsionTestTool/lib/main.dart#L150-L523)
- **Description:** The Dean login is hidden behind a "5-tap secret gesture" on the app title. This is not a security control — it's a UI trick. The `DeanLoginPage` route is accessible to anyone who knows about it or decompiles the app.
- **Impact:** False sense of security. The portal's existence is easily discoverable.
- **Fix:** Proper authentication is the control, not UI hiding. The Dean portal should be protected by strong credentials and MFA, not obscurity.

---

## 4. API & External Integration Security

### 🟠 HIGH-16: Face Recognition API Has No Authentication

- **Files:** [register_page.dart](file:///d:/VirtualVIsionTestTool/lib/register_page.dart#L48-L49), [class_detail_page.dart](file:///d:/VirtualVIsionTestTool/lib/class_detail_page.dart#L73-L74)
- **Description:** The face recognition backend (`https://pasteshub404-navikarana-backend.hf.space`) is called without any authentication tokens, API keys, or request signing. Endpoints:
  - `POST /register-face` — registers a face with just a username + image
  - `POST /login-face` — verifies identity with just a username + image
- **Exploit:**
  1. **Face spoofing:** Register someone else's face under a target username.
  2. **Replay attack:** Capture and replay a valid face image.
  3. **DoS:** Flood the endpoint with registrations.
  4. **Face data theft:** No auth means anyone can probe the API.
- **Impact:** Complete bypass of face verification. Attendance fraud.
- **Fix:**
  - Add API key or JWT-based authentication to the backend.
  - Implement liveness detection (anti-spoofing).
  - Add request signing/HMAC to prevent replay attacks.
  - Rate-limit the endpoints.

---

### 🟡 MED-17: Photo Storage URLs Are Publicly Accessible

- **File:** [class_detail_page.dart](file:///d:/VirtualVIsionTestTool/lib/class_detail_page.dart#L107)
- **Description:** Attendance photo URLs are constructed as: `{endpoint}/storage/buckets/attendance_photos/files/{id}/view?project={projectId}`. If the Appwrite bucket permissions allow public reads, anyone with the URL can access student photos.
- **Impact:** Privacy violation, potential GDPR/data protection issues. Biometric data exposure.
- **Fix:** Set bucket permissions to require authentication. Use Appwrite's file-level permissions. Generate time-limited signed URLs.

---

## 5. Input Validation & Injection

### 🟡 MED-18: No Input Validation or Sanitization

- **Files:** All form inputs across the app
- **Description:** User inputs (name, username, class codes, community messages, leave reasons) are only `trim()`ed before being stored. There is no validation for:
  - Maximum length
  - Character restrictions
  - HTML/script injection in community messages
  - Path traversal in file names
- **Exploit:** While Appwrite itself provides some protection, the community chat could be used for social engineering with crafted messages, and excessively long inputs could cause UI issues.
- **Impact:** Potential XSS in WebView contexts, UI corruption, storage abuse.
- **Fix:** Validate all inputs (length, charset, format). Sanitize community messages. Validate file names and types server-side.

---

### 🟡 MED-19: File Upload Has Limited Validation

- **File:** [community_page.dart](file:///d:/VirtualVIsionTestTool/lib/community_page.dart#L232-L282)
- **Description:** File uploads restrict extensions client-side (`pdf, csv, doc, docx, xls, xlsx, png, jpg, jpeg, gif, txt`) but this is easily bypassed. There's no:
  - File size limit
  - MIME type verification
  - Server-side extension validation
  - Malware scanning
- **Exploit:** Upload malicious files disguised with allowed extensions. Storage exhaustion via large files.
- **Impact:** Malware distribution, storage abuse, potential server-side exploitation.
- **Fix:** Add file size limits. Validate MIME types server-side. Configure Appwrite bucket limits. Scan uploads for malware.

---

## 6. Network & Transport Security

### 🟡 MED-20: Mixed Security Posture on Network Communications

- **Files:** [appwrite_service.dart](file:///d:/VirtualVIsionTestTool/lib/services/appwrite_service.dart), [register_page.dart](file:///d:/VirtualVIsionTestTool/lib/register_page.dart#L48)
- **Description:** While both the Appwrite endpoint and face recognition API use HTTPS (good), there is:
  - No certificate pinning
  - No `android:usesCleartextTraffic="false"` in the manifest (missing attribute means platform default)
  - The `transparenttextures.com` image in the captcha loads over HTTPS but from an external domain
- **Impact:** Susceptible to MitM attacks on compromised networks.
- **Fix:** Add certificate pinning for critical endpoints. Explicitly set `android:usesCleartextTraffic="false"`. Bundle the captcha texture locally.

---

## 7. Platform-Specific Risks

### 🔵 LOW-21: WebView with Unrestricted JavaScript

- **Files:** [eye_test_dialog.dart](file:///d:/VirtualVIsionTestTool/lib/eye_test_dialog.dart#L23), [camera_page.dart](file:///d:/VirtualVIsionTestTool/lib/camera_page.dart#L23)
- **Description:** WebViews use `JavaScriptMode.unrestricted` to load local HTML files. While the content is bundled, if a path traversal or file replacement attack occurs, arbitrary JavaScript could execute with app permissions.
- **Impact:** Potential code execution in app context.
- **Fix:** Use `JavaScriptMode.disabled` where JS isn't needed. Validate file paths. Consider using the `camera` plugin directly instead of WebView.

---

### 🔵 LOW-22: CSV Export Path Traversal Risk

- **File:** [admin_home_page.dart](file:///d:/VirtualVIsionTestTool/lib/admin_home_page.dart#L1384-L1433)
- **Description:** The CSV export constructs file paths using environment variables (`USERPROFILE`) without sanitization. While unlikely in normal use, this pattern could be exploitable.
- **Impact:** File write to unexpected locations.
- **Fix:** Use `path_provider` consistently. Validate output paths.

---

### 🔵 LOW-23: No App Integrity / Tamper Detection

- **Description:** The app has no runtime integrity checks, no root/jailbreak detection, no debugger detection. Combined with client-side auth, a tampered app can bypass all security.
- **Fix:** Add integrity checks (e.g., `flutter_jailbreak_detection`). Implement code obfuscation. Use Appwrite server-side validation.

---

## Summary of Recommended Architecture Changes

> [!IMPORTANT]
> The **single most impactful change** is migrating from the custom `users` collection to **Appwrite Auth**. This alone fixes CRIT-01, CRIT-02, CRIT-12, HIGH-04, HIGH-13, and HIGH-14.

### Priority 1 — Critical (Do Immediately)
1. **Migrate to Appwrite Auth** — Use `account.create()` and `account.createEmailPasswordSession()` for all authentication
2. **Set Appwrite collection permissions** — Restrict read/write by authenticated roles
3. **Remove hardcoded Dean credentials** — Store in database with hashed password
4. **Restrict the Google Maps API key** — Add app signature restrictions in Google Cloud Console
5. **Add API authentication** to the face recognition backend

### Priority 2 — High (Do This Sprint)
6. Move admin creation, password resets, and role changes to **Appwrite Functions**
7. Add **server-side rate limiting** for login attempts
8. Stop displaying passwords anywhere in the UI
9. Implement proper **session management** with token expiry
10. Add generic error messages; log details server-side

### Priority 3 — Medium (Plan for Next Release)
11. Add input validation (length, charset, format) on all forms
12. Enforce password complexity requirements
13. Add file size limits and server-side MIME validation
14. Add certificate pinning for critical API endpoints
15. Configure `android:usesCleartextTraffic="false"`

### Priority 4 — Low (Hardening)
16. Add root/jailbreak detection
17. Enable code obfuscation (`--obfuscate --split-debug-info`)
18. Add liveness detection to face verification
19. Implement audit logging for all admin actions
20. Add request signing/HMAC for API calls
