# PHASE 3 QUICK TEST GUIDE

## Phase 3 Complete! ✅

**Status:** 100% Complete  
**Lines of Code:** 1,200+  
**Time:** ~7-8 hours  
**Test Time:** 20-30 minutes

---

## 📦 What Was Built

### 1. Decryption Service (200 lines)
- AES-256-GCM decryption
- File type detection
- Memory shredding
- Parameter validation

### 2. Printer Service (300+ lines)
- Multi-format printing (PDF, Image, Text)
- Printer selection
- Print preview support
- Windows printer integration

### 3. Print Screen Widget (600+ lines)
- File list from backend
- Printer selector
- Download & decrypt workflow
- Progress tracking
- Auto-delete

### 4. API Service (150+ lines)
- List files endpoint
- Download endpoint
- Delete endpoint

### 5. Main App (150 lines)
- Multi-tab navigation
- Service injection
- Home page with instructions

---

## 🧪 How to Test

### Prerequisites
```bash
✅ Backend running: node backend/server.js (port 5000)
✅ PostgreSQL running with secure_print_db
✅ Files uploaded from mobile app
✅ Flutter SDK installed
✅ Windows printer available (or virtual printer)
```

### Test Procedure (20-30 minutes)

#### Step 1: Upload File from Mobile (5 min)
```bash
# If you haven't already:
cd mobile_app
flutter run

# In app:
# - Tap "Upload" tab
# - Select file
# - Tap "Encrypt & Upload"
# - Get file_id and note it
```

#### Step 2: Start Owner App (2 min)
```bash
cd owner_app
flutter pub get
flutter run
```

#### Step 3: View Home Page (1 min)
```
- See welcome message
- See "How It Works" (4 steps)
- Review security information
```

#### Step 4: Go to Print Page (1 min)
```
- Tap "Print" tab
- Should see file list loading
- Wait for files to appear
```

#### Step 5: Select Printer (1 min)
```
- See printer dropdown
- Default printer auto-selected
- Or select different printer
```

#### Step 6: Download & Decrypt (3 min)
```
- Click "Print" button on file
- Watch download progress
- Watch decrypt progress
- File type auto-detected
```

#### Step 7: Print File (5 min)
```
- File sent to printer
- See "Print completed successfully"
- File disappears from list (auto-deleted)
```

#### Step 8: Verify (2 min)
```bash
# Check database
psql -U postgres -d secure_print_db
SELECT * FROM files WHERE id = '<file_id>';

# Should show:
# - is_printed = true
# - deleted_at = <timestamp>
```

---

## ✅ Expected Results

### File List
```
✅ Shows pending files (is_printed = false)
✅ Displays file name
✅ Shows file size in KB
✅ "Ready" status chip
✅ Print button for each file
```

### Printer Selection
```
✅ Dropdown shows available printers
✅ Default printer selected
✅ Can switch printers
```

### Print Process
```
✅ Download progress shows
✅ Decrypt progress shows
✅ Print sends to printer
✅ Success dialog appears
✅ File disappears from list
```

### Database After Print
```
is_printed = true      ✅
deleted_at = now()     ✅
File stays in DB but marked deleted ✅
```

---

## 🔍 Verification Checklist

### File List
```
□ Files load from backend
□ Show pending files only
□ Display metadata correctly
□ Refresh button works
```

### Download
```
□ Downloads encrypted data
□ Gets IV vector
□ Gets auth tag
□ Progress shown
```

### Decryption
```
□ File decrypts successfully
□ Progress shown
□ No errors
□ File type detected
```

### Printing
```
□ File sent to printer
□ Printer accepts file
□ No print errors
□ Success dialog shows
```

### Cleanup
```
□ File deleted from server
□ Status updated in database
□ File removed from list
```

---

## 🐛 Troubleshooting

### Issue: "No printers available"
```
Cause: No printer installed
Fix:
1. Install Windows printer (virtual or physical)
2. Go to Settings → Devices → Printers
3. Add printer
4. Restart app
```

### Issue: "Connection refused"
```
Cause: Backend not running
Fix:
1. Start backend: node backend/server.js
2. Should show: "Server running on port 5000"
3. Try again
```

### Issue: "File not found"
```
Cause: File ID wrong or already deleted
Fix:
1. Upload new file from mobile app
2. Use correct file_id
3. Try again
```

### Issue: "Decryption failed"
```
Cause: Corrupted file data or wrong key
Fix:
1. Verify backend has encrypted file
2. Check database: SELECT * FROM files WHERE id = '<id>';
3. Ensure IV and auth_tag are not NULL
4. Try uploading again
```

### Issue: "Print failed"
```
Cause: Printer error or unsupported format
Fix:
1. Check printer is ready
2. Try different file format (PDF is safest)
3. Install printer drivers
4. Try print to file instead
```

### Issue: File list empty
```
Cause: No pending files
Fix:
1. Upload file from mobile app first
2. Verify file in database: SELECT * FROM files WHERE is_printed = false;
3. Click refresh in owner app
```

---

## 📊 Performance Expectations

### Download
- 10MB: ~1-2 seconds
- 50MB: ~5-10 seconds
- 100MB: ~10-20 seconds

### Decryption
- 10MB: ~0.2-0.5 seconds
- 50MB: ~0.5-2.5 seconds
- 100MB: ~1-5 seconds

### Print
- Depends on printer
- Usually 1-5 seconds to send to printer
- Printer handles actual printing

### Total
- 10MB: ~2-4 seconds
- 50MB: ~6-15 seconds
- 100MB: ~15-30 seconds

---

## 🎯 Success Criteria

✅ All checks pass if:
1. File appears in list
2. Download completes
3. Decrypt completes
4. Print succeeds
5. File deleted
6. No errors
7. UI responsive
8. Database updated

---

## 📋 Test Log Template

```
Date: _______________
Tester: ______________

File Details:
- Name: _______________
- Size: _______________
- Format: ______________

Printer:
- Name: _______________
- Type: _______________

Results:
- File downloaded: YES/NO
- File decrypted: YES/NO
- File printed: YES/NO
- File deleted: YES/NO
- Time taken: ________

Issues:
- None / List below:
  1. _______________
  2. _______________

Overall: PASS / FAIL
```

---

## 🚀 Next Steps

### After Successful Test
1. ✅ Phase 3 verified working
2. ✅ Move to Phase 4 (end-to-end testing)
3. ✅ Test complete mobile → desktop workflow
4. ✅ Stress test with multiple files
5. ✅ Test with large files
6. ✅ Security verification
7. ✅ Documentation finalization

### To Move to Phase 4
```
- Phase 3 testing complete ✅
- All features working ✅
- No critical bugs ✅
- Ready for Phase 4
```

---

## 📊 Project Status

```
Phase 0 (Foundation):    100% ✅
Phase 1 (Backend API):   100% ✅
Phase 2 (Mobile Upload): 100% ✅
Phase 3 (Windows Print): 100% ✅ (JUST DONE)
Phase 4 (Testing):        0%  ⏳

OVERALL: 80% COMPLETE 🎉
```

---

## 📞 Quick Reference

| Task | Command | Location |
|------|---------|----------|
| Start Backend | `node backend/server.js` | `/backend` |
| Start Mobile | `flutter run` | `/mobile_app` |
| Start Desktop | `flutter run` | `/owner_app` |
| Check DB | `psql -U postgres -d secure_print_db` | Terminal |
| View Files | `SELECT * FROM files;` | psql |
| Delete All Test Files | `DELETE FROM files;` | psql |

---

**Phase 3 is ready for testing!** 🎯

Choose next action:
1. **Test Now** → Follow procedure above (20-30 min)
2. **Review Code** → Check print_screen.dart (30 min)
3. **Move to Phase 4** → End-to-end testing (4-6 hours)

Ready to test? Let's go! 🚀
