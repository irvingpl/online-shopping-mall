export type OrderStatus =
  | 'pending'
  | 'payment_completed'
  | 'preparing'
  | 'shipped'
  | 'delivered'
  | 'cancelled';

export interface OrderItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface Order {
  id: string;
  userId: string;
  items: OrderItem[];
  totalAmount: number;
  status: OrderStatus;
  shippingAddress: Address;
  createdAt: Date;
  updatedAt: Date;
}

export interface Address {
  recipient: string;
  phone: string;
  zipCode: string;
  address1: string;
  address2: string;
}
