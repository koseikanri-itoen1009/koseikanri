ALTER TABLE XXCOS.XXCOS_REPORT_FORMS_REGISTER  ADD (
                                          ORIG_REPORT_CODE       VARCHAR2(4)         --•ªŠ„Œ³’ •[ƒR[ƒh
                                         ,RESREVE_COLUMN1        VARCHAR2(10)        --—\”õ€–Ú1
                                         ,RESREVE_COLUMN2        VARCHAR2(10)        --—\”õ€–Ú2
                                         ,RESREVE_COLUMN3        VARCHAR2(10)        --—\”õ€–Ú3
                                         ,RESREVE_COLUMN4        VARCHAR2(10)        --—\”õ€–Ú4
                                         ,RESREVE_COLUMN5        VARCHAR2(10)        --—\”õ€–Ú5
                                         );
/
--
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.ORIG_REPORT_CODE                IS '•ªŠ„Œ³’ •[ƒR[ƒh';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN1                 IS '—\”õ€–Ú1';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN2                 IS '—\”õ€–Ú2';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN3                 IS '—\”õ€–Ú3';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN4                 IS '—\”õ€–Ú4';
COMMENT ON COLUMN XXCOS.XXCOS_REPORT_FORMS_REGISTER.RESREVE_COLUMN5                 IS '—\”õ€–Ú5';