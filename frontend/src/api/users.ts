import { http } from "./http";
import type { UserDirectoryItem } from "../types";

export async function listUsers(params: { keyword?: string; status?: number }) {
  const { data } = await http.get<UserDirectoryItem[]>("/users", { params });
  return data;
}
