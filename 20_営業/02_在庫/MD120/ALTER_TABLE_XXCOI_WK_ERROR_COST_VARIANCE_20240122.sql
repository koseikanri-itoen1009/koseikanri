-- �������z���[�N�e�[�u���i�G���[�j���ڒǉ�
ALTER TABLE xxcoi.xxcoi_wk_error_cost_variance ADD(
  company_code           VARCHAR2(3)
 ,group_company_flg      VARCHAR2(1)
 ,transfer_ownership_flg VARCHAR2(1)
);
--
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.company_code IS '��ЃR�[�h';
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.group_company_flg IS '�O���[�v��Ѓt���O';
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.transfer_ownership_flg IS '���L���ړ]����t���O';
