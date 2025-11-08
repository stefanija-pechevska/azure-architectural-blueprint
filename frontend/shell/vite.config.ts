import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import federation from '@module-federation/vite';

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'shell',
      remotes: {
        ordersMfe: 'http://localhost:3001/assets/remoteEntry.js',
        productsMfe: 'http://localhost:3002/assets/remoteEntry.js',
        accountMfe: 'http://localhost:3003/assets/remoteEntry.js',
        notificationsMfe: 'http://localhost:3004/assets/remoteEntry.js',
      },
      shared: {
        react: { singleton: true },
        'react-dom': { singleton: true },
        'react-router-dom': { singleton: true },
      },
    }),
  ],
  build: {
    target: 'esnext',
    minify: false,
    cssCodeSplit: false,
  },
  server: {
    port: 3000,
  },
});

