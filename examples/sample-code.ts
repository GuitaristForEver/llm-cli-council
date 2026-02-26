// Sample TypeScript code for testing llm-cli-council code review
// This intentionally has some issues for the council to catch

import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { NextRequest, NextResponse } from 'next/server';

// ⚠️ Issue: Hardcoded secret (should be in env)
const JWT_SECRET = 'super-secret-key-123';

// ⚠️ Issue: No types defined
export async function POST(request) {
  try {
    const body = await request.json();
    const { email, password } = body;

    // ⚠️ Issue: No input validation
    // What if email or password is missing?

    // ⚠️ Issue: SQL injection vulnerable if not using ORM
    const user = await db.query(
      `SELECT * FROM users WHERE email = '${email}'`
    );

    if (!user) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Password comparison
    const isValid = await bcrypt.compare(password, user.passwordHash);

    if (!isValid) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // ⚠️ Issue: No token expiration set
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET
    );

    // ⚠️ Issue: Token in response body (should be httpOnly cookie)
    return NextResponse.json({
      success: true,
      token: token,
      user: {
        id: user.id,
        email: user.email
        // ⚠️ Issue: Accidentally exposing password hash
        passwordHash: user.passwordHash
      }
    });

  } catch (error) {
    // ⚠️ Issue: Exposing error details to client
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}

// Helper function with issues
function generateToken(userId) {
  // ⚠️ Issue: No expiration
  // ⚠️ Issue: Weak secret
  return jwt.sign({ userId }, 'weak-secret');
}

// ⚠️ Issue: No rate limiting
// ⚠️ Issue: No logging for security events
// ⚠️ Issue: No CSRF protection

/**
 * Instructions for Council Review:
 *
 * Test this code with:
 * /llm-cli-council:review-code examples/sample-code.ts
 *
 * The council should identify:
 * 1. Security vulnerabilities
 * 2. Missing error handling
 * 3. Type safety issues
 * 4. Best practice violations
 * 5. Suggested improvements
 */
