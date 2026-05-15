export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded';
export type PaymentMethod = 'card' | 'bank_transfer' | 'virtual_account';

export interface Payment {
  id: string;
  orderId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  paidAt: Date | null;
  createdAt: Date;
}
