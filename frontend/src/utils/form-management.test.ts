import { describe, expect, it } from 'vitest';
import { missingRequiredKeys, normalizeFieldDrafts } from './form-management';

describe('form-management utils', () => {
  it('normalizeFieldDrafts trims values and drops empty keys', () => {
    const payload = normalizeFieldDrafts([
      {
        fieldKey: ' amount ',
        variableKey: ' expenseAmount ',
        fieldType: 'number',
        label: ' 金额 ',
        required: true,
        validateRule: ' {"min": 1} ',
        sortOrder: 2
      },
      {
        fieldKey: '  ',
        fieldType: 'string',
        required: false
      }
    ]);

    expect(payload).toHaveLength(1);
    expect(payload[0]).toEqual({
      fieldKey: 'amount',
      variableKey: 'expenseAmount',
      fieldType: 'number',
      label: '金额',
      required: true,
      visibleRule: null,
      validateRule: '{"min": 1}',
      optionsJson: null,
      defaultValue: null,
      sortOrder: 2
    });
  });

  it('missingRequiredKeys detects null and blank values', () => {
    const missing = missingRequiredKeys(
      [
        { fieldKey: 'amount', required: true },
        { fieldKey: 'reason', required: true },
        { fieldKey: 'remark', required: false }
      ],
      {
        amount: 100,
        reason: ' '
      }
    );

    expect(missing).toEqual(['reason']);
  });
});
