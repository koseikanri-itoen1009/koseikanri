--���ڂ̒ǉ�
ALTER TABLE XXCOS.XXCOS_REP_COST_DIV_LIST  ADD (
    UNIT_PRICE_CHECK_MARK     VARCHAR2(2),                                 --�ُ�|�������i�`�F�b�N(�\���p)
    UNIT_PRICE_CHECK_SORT     VARCHAR2(1)                                  --�ُ�|�������i�`�F�b�N(�\�[�g�p)
);
--���ڃR�����g�̐ݒ�
COMMENT ON COLUMN XXCOS.XXCOS_REP_COST_DIV_LIST.UNIT_PRICE_CHECK_MARK      IS '�ُ�|�������i�`�F�b�N(�\���p)';
COMMENT ON COLUMN XXCOS.XXCOS_REP_COST_DIV_LIST.UNIT_PRICE_CHECK_SORT      IS '�ُ�|�������i�`�F�b�N(�\�[�g�p)';
--
--�����̒���
ALTER TABLE XXCOS.XXCOS_REP_COST_DIV_LIST  MODIFY (
    DELIVER_TO_NAME     VARCHAR2(28)                                       --�o�א�
);

