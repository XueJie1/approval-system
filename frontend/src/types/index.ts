export interface LoginResult {
  twoFactorRequired: boolean;
  challengeToken?: string;
  accessToken?: string;
  tokenType?: string;
  expiresIn?: number;
  userId?: number;
  username?: string;
  roles?: string[];
}

export interface ActionResult {
  success: boolean;
  message: string;
}

export interface TwoFactorSetup {
  secret: string;
  otpAuthUri: string;
  recoveryCodes?: string;
}

export interface UserDirectoryItem {
  userId: number;
  username: string;
  deptId?: number;
  status: number;
  twoFactorEnabled: boolean;
}

export interface PageResult<T> {
  content: T[];
  total: number;
  page: number;
  size: number;
  totalPages: number;
}

export interface AdminDeptOption {
  id: number;
  parentId?: number | null;
  deptCode?: string | null;
  deptName: string;
}

export interface AdminRoleOption {
  id: number;
  roleCode: string;
  roleName: string;
  status?: number;
}

export interface AdminPostOption {
  id: number;
  postCode: string;
  postName: string;
}

export interface AdminUserOptions {
  depts: AdminDeptOption[];
  roles: AdminRoleOption[];
  posts: AdminPostOption[];
}

export interface AdminUserSummary {
  userId: number;
  username: string;
  deptId?: number | null;
  deptName?: string | null;
  status: number;
  twoFactorEnabled: boolean;
  locked: boolean;
  lockedUntil?: string | null;
  lastLoginAt?: string | null;
  roleNames: string[];
  postNames: string[];
}

export interface AdminUserDetail extends AdminUserSummary {
  roleIds: number[];
  postIds: number[];
  roles: AdminRoleOption[];
  posts: AdminPostOption[];
  loginFailures?: number;
}

export interface AdminUserFormPayload {
  username: string;
  password: string;
  deptId?: number | null;
  roleIds: number[];
  postIds: number[];
  status: number;
}

export interface AdminUserUpdatePayload {
  deptId?: number | null;
  roleIds?: number[];
  postIds?: number[];
  status?: number;
}

export interface AdminUserStatusPayload {
  status: number;
}

export interface AdminUserResetPasswordPayload {
  newPassword: string;
}

export interface UserImportValidationError {
  rowNo: number;
  username?: string;
  message: string;
}

export interface UserImportPreviewRow {
  rowNo: number;
  username?: string;
  deptCode?: string;
  deptName?: string;
  roleCodes: string[];
  postCodes: string[];
  status: number;
  valid: boolean;
  message?: string;
}

export interface UserImportValidateResult {
  jobId: number;
  fileName: string;
  fileType?: string;
  strategy: string;
  totalRows: number;
  successRows: number;
  failedRows: number;
  errors: UserImportValidationError[];
  preview: UserImportPreviewRow[];
}

export interface UserImportExecuteResult {
  jobId: number;
  status: string;
  totalRows: number;
  successRows: number;
  failedRows: number;
}

export interface UserImportJobSummary {
  jobId: number;
  fileName: string;
  fileType: string;
  strategy: string;
  status: string;
  totalRows: number;
  successRows: number;
  failedRows: number;
  operatorId?: number | null;
  createdAt: string;
  finishedAt?: string | null;
}

export interface UserImportJobItem {
  id: number;
  rowNo: number;
  username?: string;
  rawPayload?: string;
  result: string;
  errorMessage?: string;
  createdUserId?: number | null;
  beforeSnapshot?: string;
  afterSnapshot?: string;
}

export interface StartRequestPayload {
  businessKey: string | null;
  title: string;
  applicantId: number;
  applicantDeptId?: number | null;
  applicantPostId?: number | null;
  formInstanceId?: number | null;
  formKey: string | null;
  formVersionId: number | null;
  formData: Record<string, unknown> | null;
  processKey: string;
  countersignUsers: string[];
  countersignMode: string;
  passRatio: number;
  variables: Record<string, unknown>;
}

export interface SaveDraftPayload {
  businessKey: string | null;
  title: string;
  applicantId: number;
  applicantDeptId?: number | null;
  applicantPostId?: number | null;
  formInstanceId?: number | null;
  formKey: string | null;
  formVersionId: number | null;
  formData: Record<string, unknown> | null;
}

export interface SubmitDraftPayload {
  title: string;
  applicantId: number;
  applicantDeptId?: number | null;
  applicantPostId?: number | null;
  formInstanceId?: number | null;
  processKey: string;
  variables: Record<string, unknown>;
  countersignUsers: string[];
  countersignMode: string;
  passRatio: number;
}

export interface WorkflowStartResult {
  processInstanceId: string;
  message: string;
}

export interface DraftSaveResult {
  businessKey: string;
  message: string;
}

export interface UserProfile {
  userId: number;
  username: string;
  roles: string[];
  twoFactorEnabled: boolean;
  hasRecoveryCodes: boolean;
}

export interface TaskInfo {
  taskId: string;
  taskName: string;
  processInstanceId: string;
  assignee?: string;
  createTime?: string;
}

export interface BizRequest {
  id: number;
  businessKey: string;
  processInstanceId?: string;
  processDefinitionId?: string;
  formInstanceId?: number;
  applicantId: number;
  applicantDeptId?: number;
  applicantPostId?: number;
  title: string;
  status: number;
  currentTaskId?: string;
  currentAssigneeId?: number;
  submitTime?: string;
  finishTime?: string;
  createdAt: string;
  updatedAt: string;
}

export interface RequestLog {
  id: number;
  businessKey: string;
  processInstanceId?: string;
  taskId?: string;
  operatorId?: number;
  action: string;
  comment?: string;
  createdAt: string;
}

export interface ProcessInfo {
  processInstanceId: string;
  processDefinitionId: string;
  businessKey: string;
}

export interface AiConversationTurn {
  question: string;
  answer: string;
  askedAt?: string;
  answeredAt?: string;
  model?: string;
}

export interface FormField {
  id: number;
  fieldKey: string;
  fieldType: string;
  label?: string;
  required?: number;
  optionsJson?: string;
}

export interface FormVersion {
  id: number;
  formId: number;
  versionNo: number;
  schemaJson?: string;
}

export interface AiSuggestion {
  recordId: number;
  businessKey: string;
  processInstanceId: string;
  taskId: string;
  decision: string;
  recommendation: string;
  summary: string;
  riskWarnings: string[];
  anomalies: string[];
  supplementaryInfo: string[];
  approvalComment: string;
  suggestedFormUpdates: Record<string, unknown>;
  conversation: AiConversationTurn[];
  adopted: boolean;
  adoptedAt?: string;
  finalApprovalResult?: string;
  model: string;
  generatedAt: string;
}
