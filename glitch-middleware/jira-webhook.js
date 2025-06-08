require('dotenv').config();               // Load environment variables from .env file
const fs = require('fs');                 // File system module to read files
const jwt = require('jsonwebtoken');      // Library to create and sign JWT tokens
const axios = require('axios');           // HTTP client for making API requests

// Read the RSA private key file (used to sign the JWT)
const privateKey = fs.readFileSync('./jira-glitch-middleware.key', 'utf8');

module.exports = async function (fastify, opts) {
  // Define a POST route to handle incoming JIRA webhooks
  fastify.post('/jira-webhook', async (request, reply) => {
    try {
      // Validate webhook secret signature from query param
      const receivedSignature = request.query.signature;
      const expectedSignature = process.env.JIRA_WEBHOOK_SECRET;

      if (!receivedSignature || receivedSignature !== expectedSignature) {
        fastify.log.warn('Invalid webhook signature');
        return reply.status(401).send({ error: 'Invalid webhook signature' });
      }

      // Step 1: Create the JWT payload with required claims
      const payload = {
        iss: process.env.CLIENT_ID,            // Connected App Consumer Key (issuer)
        sub: process.env.SF_USERNAME,          // Salesforce username (subject)
        aud: 'https://login.salesforce.com',   // Salesforce login URL for production
        exp: Math.floor(Date.now() / 1000) + (60 * 5) // Token expiration time (current time + 5 minutes)
      };

      // Step 2: Sign the JWT using RS256 algorithm and your private key
      const token = jwt.sign(payload, privateKey, { algorithm: 'RS256' });

      // Step 3: Prepare the form data for Salesforce OAuth token request
      const params = new URLSearchParams();
      params.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
      params.append('assertion', token);

      // Step 4: Request an access token from Salesforce using the JWT Bearer flow
      const tokenResponse = await axios.post(
        'https://login.salesforce.com/services/oauth2/token',
        params.toString(),
        {
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        }
      );
      const accessToken = tokenResponse.data.access_token;

      // Step 5: Call your Salesforce REST Apex endpoint with the obtained access token
      const sfResponse = await axios.post(
        process.env.SF_ENDPOINT_URL,           // Your Salesforce REST endpoint URL
        request.body,                          // Incoming webhook data forwarded to Salesforce
        { headers: { Authorization: `Bearer ${accessToken}` } }
      );

      // Step 6: Respond with success and include Salesforce response data
      reply.send({ message: 'Success', salesforceResponse: sfResponse.data });
    } catch (err) {
      console.error('Error:', err.response?.data || err.message);
      reply.status(500).send({ error: 'Something went wrong' });
    }
  });
};
