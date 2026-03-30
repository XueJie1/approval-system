import { http } from "./http";

export interface SysRole {
  id: number;
  roleCode: string;
  roleName: string;
  status: number;
}

export interface CreateRolePayload {
  roleCode: string;
  roleName: string;
}

export interface UpdateRolePayload {
  roleCode: string;
  roleName: string;
  status: number;
}

export async function listRoles(keyword?: string, status?: number): Promise<SysRole[]> {
  const params = new URLSearchParams();
  if (keyword) params.append("keyword", keyword);
  if (status !== undefined) params.append("status", status.toString());
  const url = params.toString() ? `/rbac/roles?${params.toString()}` : "/rbac/roles";
  const { data } = await http.get<SysRole[]>(url);
  return data;
}

export async function createRole(payload: CreateRolePayload): Promise<SysRole> {
  const { data } = await http.post<SysRole>("/rbac/roles", payload);
  return data;
}

export async function updateRole(roleId: number, payload: UpdateRolePayload): Promise<SysRole> {
  const { data } = await http.put<SysRole>(`/rbac/roles/${roleId}`, payload);
  return data;
}

export async function deleteRole(roleId: number): Promise<void> {
  await http.delete(`/rbac/roles/${roleId}`);
}
