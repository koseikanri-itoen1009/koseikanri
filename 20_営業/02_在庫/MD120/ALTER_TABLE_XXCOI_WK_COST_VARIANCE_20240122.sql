-- �������z���[�N�e�[�u�����ڒǉ�
ALTER TABLE xxcoi.xxcoi_wk_cost_variance ADD(
  company_code           VARCHAR2(3)
 ,transaction_type_id    NUMBER
 ,group_company_flg      VARCHAR2(1)
 ,transfer_ownership_flg VARCHAR2(1)
 ,reverse_flg            VARCHAR2(1)
 ,grcp_adj_dept_code     VARCHAR2(4)
);
--
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.company_code IS '��ЃR�[�h';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.transaction_type_id IS '����^�C�vID';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.group_company_flg IS '�O���[�v��Ѓt���O';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.transfer_ownership_flg IS '���L���ړ]����t���O';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.reverse_flg IS '���]�t���O';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.grcp_adj_dept_code IS '��������R�[�h(�O���[�v���)';
