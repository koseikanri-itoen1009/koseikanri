-- ������q�`�F�b�N���X�g���[�N���ڒǉ��X�N���v�g
ALTER TABLE xxcmm_rep_undeal_list ADD (
  employee_number      VARCHAR2(30),
  employee_name        VARCHAR2(20)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.employee_number         IS '�S���c�ƈ��R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.employee_name           IS '�S���c�ƈ�'
/

-- ������q�`�F�b�N���X�g���[�N���ڕύX�X�N���v�g
ALTER TABLE xxcmm_rep_undeal_list MODIFY (
  install_code         VARCHAR2(12),
  change_amount        NUMBER(9,0)
)
/