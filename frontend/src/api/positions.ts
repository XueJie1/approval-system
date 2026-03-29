import { http } from "./http";

export interface Position {
  id: number;
  postCode: string;
  postName: string;
}

export interface CreatePositionRequest {
  postCode: string;
  postName: string;
}

export interface UpdatePositionRequest {
  postCode: string;
  postName: string;
}

export const positionApi = {
  list: () => http.get<Position[]>("/positions"),
  getById: (id: number) => http.get<Position>(`/positions/${id}`),
  create: (data: CreatePositionRequest) => http.post<Position>("/positions", data),
  update: (id: number, data: UpdatePositionRequest) => http.put<Position>(`/positions/${id}`, data),
  delete: (id: number) => http.delete(`/positions/${id}`)
};
