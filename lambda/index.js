exports.handler = async (event) => {
  console.log('Auth event:', JSON.stringify(event));
  
  const token = event.authorizationToken;
  
  if (!token) {
    throw new Error('Unauthorized');
  }

  // Accept any Bearer token for demo purposes
  // In production you would verify JWT signature here
  if (token.startsWith('Bearer ')) {
    return generatePolicy('user', 'Allow', event.methodArn);
  }
  
  return generatePolicy('user', 'Deny', event.methodArn);
};

function generatePolicy(principalId, effect, resource) {
  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: resource
      }]
    },
    context: {
      userId: 'demo-user'
    }
  };
}