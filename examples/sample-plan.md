# Sample Implementation Plan

This is a sample plan for testing the llm-cli-council review functionality.

## Phase 1: Authentication System

**Objective**: Implement JWT-based authentication with secure password hashing and session management.

### Tasks

#### Task 1: Create User Model
- Add User model to Prisma schema
- Fields: id, email (unique), passwordHash, createdAt, updatedAt
- Add Session relation for refresh tokens

#### Task 2: Implement Password Hashing
- Use bcrypt for password hashing
- Salt rounds: 12
- Store only hashed passwords, never plaintext

#### Task 3: Create Login Endpoint
- POST /api/auth/login
- Accept: { email, password }
- Validate credentials against database
- On success: Generate JWT, set httpOnly cookie
- On failure: Return 401

#### Task 4: Create Registration Endpoint
- POST /api/auth/register
- Accept: { email, password, confirmPassword }
- Validate email format and password strength
- Check for existing user
- Hash password and create user
- Auto-login after registration

#### Task 5: Protected Route Middleware
- Create middleware to verify JWT
- Check token validity and expiration
- Attach user object to request
- Redirect to login if invalid

### Verification

- [ ] npm run build succeeds
- [ ] All tests pass
- [ ] Can register new user
- [ ] Can login with valid credentials
- [ ] Cannot access protected routes without auth
- [ ] Invalid credentials return 401

### Success Criteria

- All tasks completed
- Authentication flow works end-to-end
- No security vulnerabilities
- Code follows project patterns
- Tests have good coverage

## Potential Issues to Review

1. **JWT Secret Management**: Where should we store the JWT secret? Environment variable or config file?

2. **Session Duration**: 15-minute expiry might be too short. Should we implement refresh tokens?

3. **Password Requirements**: Should we enforce password complexity rules? Min length, special characters, etc.?

4. **Rate Limiting**: Should we add rate limiting to prevent brute force attacks on login?

5. **Email Verification**: Should we require email verification before allowing login?

## Architecture Decisions Needed

- **Auth Library**: NextAuth.js vs custom implementation?
- **Token Storage**: httpOnly cookies vs localStorage?
- **Session Management**: Stateless JWT vs database sessions?
- **Password Reset**: Email-based vs security questions?

---

**Instructions for Council Review**:

Test this plan with:
```bash
/llm-cli-council:review-plan examples/sample-plan.md
```

The council should evaluate:
- Completeness of the plan
- Security considerations
- Missing requirements
- Potential issues
- Better approaches
