export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  createdAt: Date;
  updatedAt: Date;
}

export type UserRole = 'admin' | 'customer';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}
