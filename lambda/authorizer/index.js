exports.handler = async (event) => {
  console.log('Auth event:', JSON.stringify(event));
  
  const token = event.authorizationToken;
  
  if (!token) {
    throw new Error('Unauthorized');
  }

  if (token.startsWith('Bearer ')) {
    return generatePolicy('user', 'Allow', event.methodArn);
  }
  
  return generatePolicy('user', 'Deny', event.methodArn);
};

function generatePolicy(principalId, effect, resource) {
  // Allow access to ALL methods in this API, not just the one being called
  const arnParts = resource.split(':');
  const region = arnParts[3];
  const accountId = arnParts[4];
  const apiParts = arnParts[5].split('/');
  const apiId = apiParts[0];
  const stage = apiParts[1];
  const wildcardArn = `arn:aws:execute-api:${region}:${accountId}:${apiId}/${stage}/*/*`;

  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: wildcardArn
      }]
    }
  };
}