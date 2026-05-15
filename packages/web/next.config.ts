import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  transpilePackages: ['@mall/ui', '@mall/shared'],
  experimental: {
    optimizePackageImports: ['@mall/ui'],
  },
};

export default nextConfig;
