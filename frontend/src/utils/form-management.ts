export interface EditableFormFieldDraft {
  fieldKey: string;
  variableKey?: string;
  fieldType: string;
  label?: string;
  required: boolean;
  visibleRule?: string;
  validateRule?: string;
  optionsJson?: string;
  defaultValue?: string;
  sortOrder?: number;
}

export interface FormFieldPayload {
  fieldKey: string;
  variableKey: string | null;
  fieldType: string;
  label: string | null;
  required: boolean;
  visibleRule: string | null;
  validateRule: string | null;
  optionsJson: string | null;
  defaultValue: string | null;
  sortOrder: number;
}

export function normalizeFieldDrafts(fields: EditableFormFieldDraft[]): FormFieldPayload[] {
  return fields
    .map((field, index) => ({
      fieldKey: field.fieldKey.trim(),
      variableKey: field.variableKey?.trim() || null,
      fieldType: field.fieldType,
      label: field.label?.trim() || null,
      required: Boolean(field.required),
      visibleRule: field.visibleRule?.trim() || null,
      validateRule: field.validateRule?.trim() || null,
      optionsJson: field.optionsJson?.trim() || null,
      defaultValue: field.defaultValue?.trim() || null,
      sortOrder: field.sortOrder ?? index
    }))
    .filter(field => field.fieldKey.length > 0);
}

export function missingRequiredKeys(
  fields: Array<Pick<EditableFormFieldDraft, 'fieldKey' | 'required'>>,
  data: Record<string, unknown>
) {
  return fields
    .filter(field => field.required)
    .map(field => field.fieldKey)
    .filter(key => {
      const value = data[key];
      if (value === null || value === undefined) {
        return true;
      }
      return typeof value === 'string' && value.trim().length === 0;
    });
}
