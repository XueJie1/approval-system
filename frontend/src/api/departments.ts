import { http } from "./http";

export interface Department {
  id: number;
  deptCode: string | null;
  deptName: string;
  parentId: number | null;
}

export interface CreateDepartmentRequest {
  deptCode?: string;
  deptName: string;
  parentId?: number | null;
}

export interface UpdateDepartmentRequest {
  deptCode?: string;
  deptName: string;
  parentId?: number | null;
}

export const departmentApi = {
  list: () => http.get<Department[]>("/departments"),
  getById: (id: number) => http.get<Department>(`/departments/${id}`),
  create: (data: CreateDepartmentRequest) => http.post<Department>("/departments", data),
  update: (id: number, data: UpdateDepartmentRequest) => http.put<Department>(`/departments/${id}`, data),
  delete: (id: number) => http.delete(`/departments/${id}`)
};
