import axios, { AxiosError } from "axios";
import { ElMessage } from "element-plus";
import type { ApiErrorResponse } from "../types";

const baseURL = import.meta.env.DEV ? "/api" : "/api";

export const http = axios.create({
  baseURL,
  timeout: 15000
});

http.interceptors.request.use((config) => {
  const token = localStorage.getItem("approval.accessToken");
  if (token) {
    config.headers = config.headers ?? {};
    (config.headers as Record<string, string>).Authorization = `Bearer ${token}`;
  }
  return config;
});

http.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiErrorResponse>) => {
    const status = error.response?.status;
    const message =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message ||
      "请求失败";

    if (status === 401) {
      localStorage.removeItem("approval.accessToken");
      localStorage.removeItem("approval.user");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    } else if (status === 403) {
      ElMessage.error("无权限执行该操作");
    } else {
      ElMessage.error(message);
    }
    return Promise.reject(error);
  }
);
