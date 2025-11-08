import { Suspense, lazy } from 'react';

// Lazy load the Orders microfrontend
const OrdersMfe = lazy(() => import('ordersMfe/OrdersApp'));

const OrdersPage = () => {
  return (
    <Suspense fallback={<div>Loading Orders...</div>}>
      <OrdersMfe />
    </Suspense>
  );
};

export default OrdersPage;

