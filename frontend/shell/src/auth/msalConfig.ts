import { Configuration, PopupRequest } from '@azure/msal-browser';

// Determine if user is internal (employee) or external (client)
const getUserType = (): 'internal' | 'external' => {
  // In production, this could be determined by domain, subdomain, or initial route
  const hostname = window.location.hostname;
  if (hostname.includes('admin') || hostname.includes('internal')) {
    return 'internal';
  }
  return 'external';
};

const userType = getUserType();

// Entra ID Configuration (Internal - Employees)
const internalConfig: Configuration = {
  auth: {
    clientId: import.meta.env.VITE_ENTRA_INTERNAL_CLIENT_ID || 'your-internal-client-id',
    authority: `https://login.microsoftonline.com/${import.meta.env.VITE_ENTRA_INTERNAL_TENANT_ID || 'your-internal-tenant-id'}`,
    redirectUri: window.location.origin + '/auth/callback',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

// Entra External ID Configuration (External - Clients)
const externalConfig: Configuration = {
  auth: {
    clientId: import.meta.env.VITE_ENTRA_EXTERNAL_CLIENT_ID || 'your-external-client-id',
    authority: `https://${import.meta.env.VITE_ENTRA_EXTERNAL_TENANT_NAME || 'your-tenant'}.ciam.login.microsoftonline.com/${import.meta.env.VITE_ENTRA_EXTERNAL_TENANT_ID || 'your-external-tenant-id'}`,
    redirectUri: window.location.origin + '/auth/callback',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

export const msalConfig = userType === 'internal' ? internalConfig : externalConfig;

export const loginRequest: PopupRequest = {
  scopes: ['User.Read'],
};

export const apiRequest: PopupRequest = {
  scopes: [`api://${msalConfig.auth.clientId}/.default`],
};

