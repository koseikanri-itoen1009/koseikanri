-- ������q�`�F�b�N���X�g���[�N���ڒǉ��X�N���v�g
ALTER TABLE xxcmm.xxcmm_rep_undeal_list ADD(
  rep_title               VARCHAR2(50),
  nodata_msg              VARCHAR2(50)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.rep_title               IS '���[�^�C�g��'
/
COMMENT ON COLUMN xxcmm.xxcmm_rep_undeal_list.nodata_msg              IS '�f�[�^�Ȃ����b�Z�[�W'
/