import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { MsalProvider } from '@azure/msal-react';
import { PublicClientApplication } from '@azure/msal-browser';
import { msalConfig } from './auth/msalConfig';
import Layout from './components/Layout';
import Home from './pages/Home';
import OrdersPage from './pages/OrdersPage';
import ProductsPage from './pages/ProductsPage';
import AccountPage from './pages/AccountPage';
import NotificationsPage from './pages/NotificationsPage';
import { AuthProvider } from './context/AuthContext';

const msalInstance = new PublicClientApplication(msalConfig);

function App() {
  return (
    <MsalProvider instance={msalInstance}>
      <AuthProvider>
        <BrowserRouter>
          <Layout>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/orders/*" element={<OrdersPage />} />
              <Route path="/products/*" element={<ProductsPage />} />
              <Route path="/account/*" element={<AccountPage />} />
              <Route path="/notifications/*" element={<NotificationsPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Layout>
        </BrowserRouter>
      </AuthProvider>
    </MsalProvider>
  );
}

export default App;

