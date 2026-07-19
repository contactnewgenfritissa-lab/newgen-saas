export type Role = 'admin'|'supervisor'|'agent'|'shipping'|'store_owner'|'accountant';
export type Permission = 'dashboard:view'|'orders:view'|'orders:create'|'orders:update'|'orders:delete'|'users:manage'|'stores:manage'|'customers:view'|'customers:write'|'shipping:view'|'shipping:update'|'reports:view'|'audit:view'|'settings:manage';
const matrix: Record<Role, Permission[]> = {
  admin:['dashboard:view','orders:view','orders:create','orders:update','orders:delete','users:manage','stores:manage','customers:view','customers:write','shipping:view','shipping:update','reports:view','audit:view','settings:manage'],
  supervisor:['dashboard:view','orders:view','orders:create','orders:update','customers:view','customers:write','shipping:view','shipping:update','reports:view','audit:view'],
  agent:['dashboard:view','orders:view','orders:update','customers:view','customers:write'],
  shipping:['dashboard:view','orders:view','shipping:view','shipping:update'],
  store_owner:['dashboard:view','orders:view','orders:create','customers:view','customers:write','reports:view'],
  accountant:['dashboard:view','orders:view','reports:view'],
};
export const can=(role: Role|undefined, permission: Permission)=>Boolean(role && matrix[role]?.includes(permission));
export const roleLabel: Record<Role,string>={admin:'المدير',supervisor:'المشرفة',agent:'عاملة التأكيد',shipping:'مسؤول الشحن',store_owner:'صاحب المتجر',accountant:'المحاسب'};
