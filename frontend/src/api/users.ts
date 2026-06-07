import { http } from "./http";
import type { PageResult, UserDirectoryItem } from "../types";

export async function listUsers(params: { keyword?: string; status?: number; page?: number; size?: number }) {
  const { data } = await http.get<PageResult<UserDirectoryItem>>("/users", { params });
  return data;
}
