# 🔐 Credentials & Secrets Management

## Overview
This document explains how to securely manage environment variables and credentials for the SafeCopy backend.

## ⚠️ CRITICAL SECURITY RULES

1. **NEVER commit .env to version control** - it contains secrets
2. **NEVER hardcode credentials** in source code
3. **NEVER share passwords via chat, email, or unencrypted channels**
4. **ALWAYS use a password manager** to securely generate and share secrets
5. **ROTATE credentials immediately** if leaked or when team members leave
6. **USE environment variables** in production (from CI/CD, secrets manager, etc.)

## Local Development Setup

### 1. Generate Strong Passwords
Use one of these commands to generate cryptographically secure passwords:

```bash
# OpenSSL (recommended)
openssl rand -base64 32

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# macOS/Linux
head -c 32 /dev/urandom | base64
```

### 2. Create Database User (PostgreSQL)
```sql
-- Connect to Postgres as admin (usually postgres user)
createuser app_user
\password app_user
-- Enter the strong password generated above

-- Grant permissions
ALTER USER app_user CREATEDB;
```

### 3. Create Local .env File
```bash
# Copy the template
cp backend/.env.example backend/.env

# Edit .env with your local values
# Use the strong passwords you generated above
nano backend/.env
# or
code backend/.env
```

### 4. Store Secrets in Password Manager
- **Use 1Password, LastPass, Bitwarden, or similar**
- Store entire .env file or individual credentials
- Share with team members securely (vault/team access)
- Document which credentials are for which environment

## Production Deployment

### Using AWS Secrets Manager
```bash
aws secretsmanager create-secret \
  --name safecopy/production \
  --secret-string file://backend/.env.production
```

### Using Docker/Kubernetes
```yaml
# kubernetes secret
apiVersion: v1
kind: Secret
metadata:
  name: safecopy-secrets
type: Opaque
data:
  DATABASE_URL: <base64-encoded-url>
  JWT_SECRET: <base64-encoded-secret>
```

### Using GitHub Actions
```yaml
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

## Credentials Audit Checklist

- [ ] Database password is strong (32+ chars, mixed case, numbers, symbols)
- [ ] JWT secrets are randomly generated (not default values)
- [ ] All CHANGE_ME_ values are replaced
- [ ] .env file is in .gitignore
- [ ] No credentials appear in git history (use `git log -p` to check)
- [ ] All team members have password manager access to shared credentials
- [ ] Production uses environment variables, not committed .env
- [ ] Credentials are rotated every 90 days
- [ ] Credential access logs are monitored

## If Credentials Are Leaked

1. **IMMEDIATELY:**
   - Revoke the leaked credentials
   - Generate new strong credentials
   - Update all environments

2. **Rotate All Passwords:**
   ```bash
   # Generate new DB password
   createuser new_app_user
   \password new_app_user
   
   # Generate new JWT secrets
   openssl rand -base64 32
   openssl rand -base64 32
   ```

3. **Update Everywhere:**
   - Local .env files
   - CI/CD secrets
   - Production secrets manager
   - Password manager vault

4. **Audit:**
   - Check git history for accidental commits
   - Review audit logs for unauthorized access
   - Document the incident

## Team Onboarding

New team members should:

1. Request access to the shared password vault (1Password team, etc.)
2. Copy `.env.example` to `.env`
3. Retrieve credentials from the vault and populate `.env`
4. Verify database connection: `npm run migrate`
5. Run tests: `npm test`
6. **DO NOT commit .env file**

## Resources

- [OWASP: Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [12-Factor App: Config](https://12factor.net/config)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
