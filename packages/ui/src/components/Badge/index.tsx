import type { OrderStatus } from '@mall/shared';
import * as React from 'react';

type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'info';

interface BadgeProps {
  label: string;
  variant?: BadgeVariant;
}

export function Badge({ label, variant = 'default' }: BadgeProps) {
  const variants: Record<BadgeVariant, string> = {
    default: 'bg-gray-100 text-gray-800',
    success: 'bg-green-100 text-green-800',
    warning: 'bg-yellow-100 text-yellow-800',
    danger: 'bg-red-100 text-red-800',
    info: 'bg-blue-100 text-blue-800',
  };

  return (
    <span
      className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${variants[variant]}`}
    >
      {label}
    </span>
  );
}

export function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const map: Record<OrderStatus, { label: string; variant: BadgeVariant }> = {
    pending: { label: '주문 대기', variant: 'warning' },
    payment_completed: { label: '결제 완료', variant: 'info' },
    preparing: { label: '상품 준비 중', variant: 'info' },
    shipped: { label: '배송 중', variant: 'info' },
    delivered: { label: '배송 완료', variant: 'success' },
    cancelled: { label: '취소됨', variant: 'danger' },
  };

  const { label, variant } = map[status];
  return <Badge label={label} variant={variant} />;
}
