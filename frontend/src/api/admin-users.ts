import { http } from "./http";
import type {
  AdminUserDetail,
  AdminUserFormPayload,
  AdminUserOptions,
  AdminUserResetPasswordPayload,
  AdminUserStatusPayload,
  AdminUserSummary,
  AdminUserUpdatePayload,
  PageResult,
  UserImportExecuteResult,
  UserImportJobItem,
  UserImportJobSummary,
  UserImportValidateResult
} from "../types";

export interface AdminUserQueryParams {
  keyword?: string;
  status?: number;
  deptId?: number;
  roleId?: number;
  page?: number;
  size?: number;
}

export interface UserImportQueryParams {
  status?: string;
  operatorId?: number;
  startDate?: string;
  endDate?: string;
  page?: number;
  size?: number;
}

export interface UserImportExecutePayload {
  skipErrorRows?: boolean;
}

interface BackendDeptOption {
  id: number;
  parentId?: number | null;
  deptCode?: string | null;
  deptName: string;
}

interface BackendRoleOption {
  id: number;
  roleCode: string;
  roleName: string;
  status?: number;
}

interface BackendPostOption {
  id: number;
  postCode: string;
  postName: string;
}

interface BackendUserOptions {
  departments: BackendDeptOption[];
  roles: BackendRoleOption[];
  posts: BackendPostOption[];
}

interface BackendAdminUserSummary {
  userId: number;
  username: string;
  department?: BackendDeptOption | null;
  roles: BackendRoleOption[];
  posts: BackendPostOption[];
  status: number;
  twoFactorEnabled: boolean;
  lastLoginAt?: string | null;
  locked: boolean;
}

interface BackendAdminUserDetail extends BackendAdminUserSummary {
  loginFailures?: number;
  lockedUntil?: string | null;
}

interface BackendImportValidateResult {
  jobId: number;
  fileName: string;
  strategy: string;
  totalRows: number;
  successRows: number;
  failedRows: number;
  errors: Array<{ rowNo: number; username?: string; message: string }>;
  preview: Array<{
    rowNo: number;
    username?: string;
    deptCode?: string;
    postCodes: string[];
    roleCodes: string[];
    status: number;
    valid: boolean;
  }>;
}

function mapUserSummary(data: BackendAdminUserSummary): AdminUserSummary {
  return {
    userId: data.userId,
    username: data.username,
    deptId: data.department?.id ?? null,
    deptName: data.department?.deptName ?? null,
    status: data.status,
    twoFactorEnabled: data.twoFactorEnabled,
    locked: data.locked,
    lastLoginAt: data.lastLoginAt ?? null,
    roleNames: data.roles.map((role) => role.roleName || role.roleCode),
    postNames: data.posts.map((post) => post.postName || post.postCode)
  };
}

function mapUserDetail(data: BackendAdminUserDetail): AdminUserDetail {
  return {
    ...mapUserSummary(data),
    roleIds: data.roles.map((role) => role.id),
    postIds: data.posts.map((post) => post.id),
    roles: data.roles,
    posts: data.posts,
    loginFailures: data.loginFailures,
    lockedUntil: data.lockedUntil ?? null
  };
}

export async function fetchAdminUserOptions() {
  const { data } = await http.get<BackendUserOptions>("/admin/users/options");
  return {
    depts: data.departments,
    roles: data.roles,
    posts: data.posts
  } satisfies AdminUserOptions;
}

export async function listAdminUsers(params: AdminUserQueryParams = {}) {
  const { data } = await http.get<PageResult<BackendAdminUserSummary>>("/admin/users", { params });
  return {
    ...data,
    content: data.content.map(mapUserSummary)
  } satisfies PageResult<AdminUserSummary>;
}

export async function fetchAdminUserDetail(userId: number) {
  const { data } = await http.get<BackendAdminUserDetail>(`/admin/users/${userId}`);
  return mapUserDetail(data);
}

export async function createAdminUser(payload: AdminUserFormPayload) {
  const { data } = await http.post<BackendAdminUserDetail>("/admin/users", payload);
  return mapUserDetail(data);
}

export async function updateAdminUser(userId: number, payload: AdminUserUpdatePayload) {
  const { data } = await http.patch<BackendAdminUserDetail>(`/admin/users/${userId}`, payload);
  return mapUserDetail(data);
}

export async function updateAdminUserStatus(userId: number, payload: AdminUserStatusPayload) {
  const { data } = await http.patch<BackendAdminUserDetail>(`/admin/users/${userId}/status`, payload);
  return mapUserDetail(data);
}

export async function resetAdminUserPassword(userId: number, payload: AdminUserResetPasswordPayload) {
  const { data } = await http.post<{ success: boolean; message: string }>(`/admin/users/${userId}/reset-password`, payload);
  return data;
}

export async function validateUserImport(file: File, strategy: string) {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("strategy", strategy);
  const { data } = await http.post<BackendImportValidateResult>("/admin/users/imports/validate", formData, {
    headers: {
      "Content-Type": "multipart/form-data"
    }
  });
  return {
    ...data,
    fileType: file.name.toLowerCase().endsWith(".xlsx") ? "XLSX" : "CSV"
  } satisfies UserImportValidateResult;
}

export async function executeUserImport(jobId: number, payload: UserImportExecutePayload = {}) {
  const { data } = await http.post<UserImportExecuteResult>(`/admin/users/imports/${jobId}/execute`, payload);
  return data;
}

export async function listUserImportJobs(params: UserImportQueryParams = {}) {
  const { data } = await http.get<PageResult<UserImportJobSummary>>("/admin/users/imports", { params });
  return data;
}

export async function listUserImportJobItems(jobId: number) {
  const { data } = await http.get<UserImportJobItem[]>(`/admin/users/imports/${jobId}/items`);
  return data;
}

export async function downloadUserImportTemplate() {
  const response = await http.get<Blob>("/admin/users/imports/template", {
    responseType: "blob"
  });
  return response.data;
}
