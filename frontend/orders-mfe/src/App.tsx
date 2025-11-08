import { useState, useEffect } from 'react';
import { useMsal } from '@azure/msal-react';
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://api.example.com';

interface Order {
  id: string;
  customerId: string;
  status: string;
  totalAmount: number;
  createdAt: string;
  items: OrderItem[];
}

interface OrderItem {
  productId: string;
  quantity: number;
  price: number;
}

const OrdersApp = () => {
  const { instance, accounts } = useMsal();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const getAuthToken = async (): Promise<string | null> => {
    try {
      const account = accounts[0];
      if (!account) return null;

      const response = await instance.acquireTokenSilent({
        scopes: [`api://${import.meta.env.VITE_ENTRA_EXTERNAL_CLIENT_ID}/.default`],
        account: account,
      });

      return response.accessToken;
    } catch (error) {
      console.error('Failed to acquire token:', error);
      return null;
    }
  };

  const fetchOrders = async () => {
    try {
      setLoading(true);
      const token = await getAuthToken();

      const response = await axios.get(`${API_BASE_URL}/api/v1/orders`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      setOrders(response.data);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch orders');
    } finally {
      setLoading(false);
    }
  };

  const createOrder = async (orderData: Partial<Order>) => {
    try {
      const token = await getAuthToken();

      const response = await axios.post(`${API_BASE_URL}/api/v1/orders`, orderData, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      setOrders([...orders, response.data]);
      return response.data;
    } catch (err: any) {
      setError(err.message || 'Failed to create order');
      throw err;
    }
  };

  if (loading) {
    return <div>Loading orders...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="orders-container">
      <h1>My Orders</h1>
      <div className="orders-list">
        {orders.map((order) => (
          <div key={order.id} className="order-card">
            <h3>Order #{order.id}</h3>
            <p>Status: {order.status}</p>
            <p>Total: ${order.totalAmount.toFixed(2)}</p>
            <p>Date: {new Date(order.createdAt).toLocaleDateString()}</p>
            <div className="order-items">
              <h4>Items:</h4>
              {order.items.map((item, index) => (
                <div key={index}>
                  Product: {item.productId} - Qty: {item.quantity} - ${item.price.toFixed(2)}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default OrdersApp;

