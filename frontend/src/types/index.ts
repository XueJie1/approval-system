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
