ALTER TABLE XXCOS.XXCOS_EDI_ERRORS  ADD (
  ERR_MESSAGE_CODE                 VARCHAR2(20)        NULL                               -- �G���[���b�Z�[�W�R�[�h
 ,EDI_ITEM_NAME                    VARCHAR2(20)        NULL                               -- EDI�i�ږ���
 ,EDI_RECEIVED_DATE                DATE                NULL                               -- EDI��M��
 ,ERR_LIST_OUT_FLAG                VARCHAR2(2)         NULL                               -- �󒍃G���[���X�g�o�͍σt���O
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.ERR_MESSAGE_CODE                            IS  '�G���[���b�Z�[�W�R�[�h';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.EDI_ITEM_NAME                               IS  'EDI�i�ږ���';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.EDI_RECEIVED_DATE                           IS  'EDI��M��';
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.ERR_LIST_OUT_FLAG                           IS  '�󒍃G���[���X�g�o�͍σt���O';
