ALTER TABLE XXCOS.XXCOS_REPORT_FORMS_REGISTER  ADD (
                                          ORIG_REPORT_CODE       VARCHAR2(4)         --���������[�R�[�h
                                         ,RESREVE_COLUMN1        VARCHAR2(10)        --�\������1
                                         ,RESREVE_COLUMN2        VARCHAR2(10)        --�\������2
                                         ,RESREVE_COLUMN3        VARCHAR2(10)        --�\������3
                                         ,RESREVE_COLUMN4        VARCHAR2(10)        --�\������4
                                         ,RESREVE_COLUMN5        VARCHAR2(10)        --�\������5
                                         );
/
--
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.ORIG_REPORT_CODE                IS '���������[�R�[�h';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN1                 IS '�\������1';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN2                 IS '�\������2';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN3                 IS '�\������3';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN4                 IS '�\������4';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN5                 IS '�\������5';