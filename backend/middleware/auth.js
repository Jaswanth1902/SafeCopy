// Authentication Middleware
// Verifies JWT tokens and user permissions

const AuthService = require('../services/authService');

/**
 * Middleware to verify JWT access token from Authorization header
 */
const verifyToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: true,
        statusCode: 401,
        message: 'Missing or invalid authorization header',
      });
    }

    const token = authHeader.substring(7);

    try {
      const payload = AuthService.verifyAccessToken(token);
      req.user = payload;
      req.token = token;
      next();
    } catch (error) {
      return res.status(401).json({
        error: true,
        statusCode: 401,
        message: error.message,
      });
    }
  } catch (error) {
    res.status(500).json({
      error: true,
      statusCode: 500,
      message: 'Authentication error',
    });
  }
};

/**
 * Middleware to verify user role
 */
const verifyRole = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: true,
        statusCode: 401,
        message: 'Unauthorized',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: true,
        statusCode: 403,
        message: 'Forbidden: Insufficient permissions',
      });
    }

    next();
  };
};

/**
 * Middleware for rate limiting
 */
const rateLimit = (limit = 100, windowMs = 60000) => {
  const store = new Map();

  return (req, res, next) => {
    const key = req.ip;
    const now = Date.now();

    if (!store.has(key)) {
      store.set(key, []);
    }

    const requests = store.get(key);
    
    // Remove requests older than window
    const recentRequests = requests.filter(time => now - time < windowMs);
    
    if (recentRequests.length >= limit) {
      return res.status(429).json({
        error: true,
        statusCode: 429,
        message: 'Too many requests, please try again later',
        retryAfter: Math.ceil((recentRequests[0] + windowMs - now) / 1000),
      });
    }

    recentRequests.push(now);
    store.set(key, recentRequests);

    res.set('X-RateLimit-Limit', limit);
    res.set('X-RateLimit-Remaining', limit - recentRequests.length);
    res.set('X-RateLimit-Reset', new Date(now + windowMs).toISOString());

    next();
  };
};

/**
 * Middleware for request validation
 */
const validateRequest = (schema) => {
  return (req, res, next) => {
    // Simple validation - can be extended with libraries like Joi
    try {
      // Validate required fields
      for (const field of schema.required || []) {
        if (!req.body[field]) {
          return res.status(400).json({
            error: true,
            statusCode: 400,
            message: `Missing required field: ${field}`,
          });
        }
      }

      // Validate field types
      for (const [field, type] of Object.entries(schema.types || {})) {
        if (req.body[field] && typeof req.body[field] !== type) {
          return res.status(400).json({
            error: true,
            statusCode: 400,
            message: `Invalid type for field ${field}: expected ${type}`,
          });
        }
      }

      next();
    } catch (error) {
      res.status(400).json({
        error: true,
        statusCode: 400,
        message: 'Request validation failed',
      });
    }
  };
};

module.exports = {
  verifyToken,
  verifyRole,
  rateLimit,
  validateRequest,
};
