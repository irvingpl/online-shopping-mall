export const ORDER_STATUS = {
  PENDING: 'pending',
  PAYMENT_COMPLETED: 'payment_completed',
  PREPARING: 'preparing',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

export const PAYMENT_STATUS = {
  PENDING: 'pending',
  COMPLETED: 'completed',
  FAILED: 'failed',
  REFUNDED: 'refunded',
} as const;

export const DELIVERY_STATUS = {
  PREPARING: 'preparing',
  PICKED_UP: 'picked_up',
  IN_TRANSIT: 'in_transit',
  OUT_FOR_DELIVERY: 'out_for_delivery',
  DELIVERED: 'delivered',
} as const;

export const KAFKA_TOPICS = {
  ORDER_CREATED: 'order.created',
  PAYMENT_COMPLETED: 'payment.completed',
  PAYMENT_FAILED: 'payment.failed',
  DELIVERY_STARTED: 'delivery.started',
  DELIVERY_UPDATED: 'delivery.updated',
} as const;
