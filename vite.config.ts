import { defineConfig } from 'vite';

import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import symfonyPlugin from 'vite-plugin-symfony';

import { codecovVitePlugin } from '@codecov/vite-plugin';
import { fontConverterPlugin } from './scripts/fontConverter/plugin';
import { dualCssPlugin } from './scripts/dualCss/plugin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default defineConfig(({ mode }) => ({
 base: '/', // Change from default /build/ to root
 resolve: {
  alias: {
   '@assets': resolve(__dirname, 'assets'),
   '@coverage-data': resolve(__dirname, 'coverage/data'),
   '@coverage': resolve(__dirname, 'build/coverage'),
   '@docs': resolve(__dirname, 'docs'),
   '@fixtures': resolve(__dirname, 'test-fixtures'),
   '@fonts': resolve(__dirname, 'assets/fonts'),
   '@js': resolve(__dirname, 'assets/js'),
   '@public': resolve(__dirname, 'public'),
   '@reports': resolve(__dirname, 'reports'),
   '@results': resolve(__dirname, 'reports/test-results'),
   '@scripts': resolve(__dirname, 'scripts'),
   '@scss': resolve(__dirname, 'assets/scss'),
   '@templates': resolve(__dirname, 'templates'),
   '@testing': resolve(__dirname, 'testing'),
   '@variables': resolve(__dirname, 'assets/scss/_variables.scss'),
   '~': resolve(__dirname, 'node_modules')
  },
 },
 plugins: [
  // Font converter plugin (runs first to process fonts early)
  fontConverterPlugin(),
  dualCssPlugin(),
  symfonyPlugin(),
  ...(process.env.CODECOV_TOKEN ? [
   codecovVitePlugin({
    enableBundleAnalysis: true,
    bundleName: 'eacv3-child-app',
    uploadToken: process.env.CODECOV_TOKEN,
   })
  ] : [])
 ],
 css: {
  devSourcemap: mode === 'development',
  preprocessorOptions: {
   scss: {
    // Suppress Sass deprecation warnings temporarily while we modernize
    silenceDeprecations: ['import', 'global-builtin', 'color-functions', 'if-function'],
    // Use modern API when available
    api: 'modern-compiler',
    // Allow charset declarations
    charset: false,
   }
  }
 },
 root: '.',
 build: {
  manifest: true,
  emptyOutDir: false,
  outDir: 'public',
  assetsDir: './assets',
  sourcemap: mode === 'development' ? 'inline' : false,
  minify: mode === 'production' ? 'esbuild' : false,
  target: ['es2020', 'chrome80', 'firefox78', 'safari14'],
  cssTarget: ['chrome80', 'firefox78', 'safari14'],
  rollupOptions: {
   input: {
    app: resolve(__dirname, 'assets/js/app.ts'),
    'plugins/datatables': resolve(__dirname, 'assets/scss/vendors/datatables.scss'),
    'datatables': resolve(__dirname, 'assets/js/vendors/datatables.ts'),
    'plugins/select2': resolve(__dirname, 'assets/scss/vendors/select2.scss'),
    'print': resolve(__dirname, 'assets/scss/print.scss'),
    'spinner': resolve(__dirname, 'assets/scss/layouts/partials/loading-spinner.scss'),
    'auth': resolve(__dirname, 'assets/scss/layouts/auth.scss'),
    'public': resolve(__dirname, 'assets/scss/layouts/public.scss'),
    'fonts': resolve(__dirname, 'assets/scss/fonts.scss'),
    'portal-dynamic': resolve(__dirname, 'assets/scss/layouts/portal-dynamic.scss'),
    'portal-foundation': resolve(__dirname, 'assets/scss/layouts/portal-foundation.scss'),
    'wizard-step-tracker': resolve(__dirname, 'assets/js/wizard-step-tracker.ts'),
    'global-search': resolve(__dirname, 'assets/js/global-search.ts'),
    'theme-select': resolve(__dirname, 'assets/js/theme-select.ts'),
    'role-search': resolve(__dirname, 'assets/js/role-search.ts'),
    'wizard-style-selector': resolve(__dirname, 'assets/js/wizard-style-selector.js'),
   },

   output: {
    entryFileNames: (chunkInfo) => {
     if (chunkInfo.name === 'app') return 'js/app.js';
     return 'js/[name].js';
    },
    chunkFileNames: 'js/chunks/[name]-[hash:8].js',
    assetFileNames: (assetInfo) => {
     const name = assetInfo.name || '';

     if (name.endsWith('.css')) {
      if (name.includes('portal-dynamic')) return 'css/portal-dynamic.css';
      if (name.includes('portal-foundation')) return 'css/portal-foundation.css';
      return 'css/[name][extname]';
     }
     // Handle font files - route them to fonts directory
     if (/\.(woff|woff2|eot|ttf|otf)$/.test(name)) {
      return 'fonts/[name][extname]';
     }
     // Images with shorter hash
     if (/\.(png|jpe?g|svg|gif|webp|avif)$/.test(name)) {
      return 'images/[name]-[hash:8][extname]';
     }
     return 'assets/[name]-[hash:8][extname]';
    },

    // Manual chunk optimization for better caching
    manualChunks: (id) => {
     // Vendor chunk for node_modules
     if (id.includes('node_modules')) {
      // Split large vendors into separate chunks
      if (id.includes('bootstrap')) return 'vendor-bootstrap';
      if (id.includes('datatables')) return 'vendor-datatables';
      if (id.includes('jquery')) return 'vendor-jquery';
      if (id.includes('select2')) return 'vendor-select2';
      return 'vendor';
     }
     // Default - let Vite handle other files automatically
     return undefined;
    },
   },
  },
  optimizeDeps: {
   exclude: ['@codecov/vite-plugin'],
   include: ['jquery', 'datatables', 'bootstrap', 'select2'],
   // Force include commonly used dependencies
   force: mode === 'development'
  },
  // Improve build performance
  esbuild: {
   // Drop console in production builds
   drop: mode === 'production' ? ['console', 'debugger'] : [],
  },
  server: {
   host: '0.0.0.0',
   port: 5173,
   strictPort: true,
   watch: {
    ignored: ['**/vendor/**', '**/var/**', '**/node_modules/**']
   },
   hmr: {
    port: 5173
   }
  },
  preview: {
   host: '0.0.0.0',
   port: 4173,
   strictPort: true
  }
 }
}));
