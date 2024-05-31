import { defineConfig } from 'vite'
import reactRefresh from '@vitejs/plugin-react-refresh'

export default defineConfig({

  logLevel: 'info',

  plugins: [reactRefresh()],
  server: {
    host: process.env.VITE_HOST || null,
    port: process.env.VITE_PORT || null,
    hmr: {
      clientPort: process.env.VITE_CLIENT_PORT || null
    },
    proxy: {
      '^/api': {
//        target: 'http://127.0.0.1:5000',
          target: 'http://api:5000',  //si lo vamos a usar en k8s el path deberia ser el nombre de la app (api) mas el puerto
        changeOrigin: true
      }
    }
  }
})
