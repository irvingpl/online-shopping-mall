export type DeliveryStatus =
  | 'preparing'
  | 'picked_up'
  | 'in_transit'
  | 'out_for_delivery'
  | 'delivered';

export interface Delivery {
  id: string;
  orderId: string;
  trackingNumber: string;
  carrier: string;
  status: DeliveryStatus;
  estimatedAt: Date | null;
  deliveredAt: Date | null;
  histories: DeliveryHistory[];
}

export interface DeliveryHistory {
  status: DeliveryStatus;
  location: string;
  description: string;
  timestamp: Date;
}
