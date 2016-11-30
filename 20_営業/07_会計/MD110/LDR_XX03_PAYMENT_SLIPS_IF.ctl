--********************************************************************
-- ����t�@�C��  : LDR_XX034DL001C.ctl
-- �@�\�T�v      : ������́iAP�j�f�[�^���[�h
-- �o�[�W����    : 11.5.10.1.7
-- �쐬��        : OCSJ BFA-Fin
-- �쐬��        : 2004-04-26
-- �ύX��        : ��l�G�P
-- �ŏI�ύX��    : 2016-11-10
-- �ύX����      :
--     2004-04-19 �V�K�쐬
--     2004-05-21 EXCHANGE_RATE ��EXCHANGE_RATE_TYPE_NAME�̍��ڏ��C��
--     2005-12-02 INTEGER�^��INTEGER EXTERNAL�^�ɕύX
--     2016-11-10 [E_�{�ғ�_13901]�Ή� �g�c���ٔԍ��ǉ�
--
-- Copyright (c) 2002 Oracle Corporation Japan All Rights Reserved
-- ���v���O�����g�p�ɍۂ��Ĉ�؂̕ۏ؂͍s��Ȃ�
-- �����ɂ�鎖�O���F�̂Ȃ���O�҂ւ̊J���s��
--********************************************************************
OPTIONS (SKIP=1, DIRECT=FALSE, ERRORS=99999)
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XX03_PAYMENT_SLIPS_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
  SOURCE                    CHAR          "'EXCEL'",
  WF_STATUS                 CHAR          "'00'",
  ENTRY_DATE                CHAR          "SYSDATE",
  ENTRY_PERSON_NUMBER       CHAR          "'-1'",
  REQUESTOR_PERSON_NUMBER   CHAR          "'-1'",
-- ver 11.5.10.1.6 Change Start
--  ORG_ID                    INTEGER       "'-1'",
--  CREATED_BY                INTEGER       "'-1'",
--  CREATION_DATE             CHAR          "SYSDATE",
--  LAST_UPDATED_BY           INTEGER       "'-1'",
--  LAST_UPDATE_DATE          CHAR          "SYSDATE",
--  LAST_UPDATE_LOGIN         INTEGER       "'-1'",
--  REQUEST_ID                INTEGER       "'-1'",
--  REQUEST_ID                INTEGER       "CHG_REQUEST_ID",
--  PROGRAM_APPLICATION_ID    INTEGER       "'-1'",
--  PROGRAM_ID                INTEGER       "'-1'",
  ORG_ID                    INTEGER EXTERNAL       "'-1'",
  CREATED_BY                INTEGER EXTERNAL       "'-1'",
  CREATION_DATE             CHAR          "SYSDATE",
  LAST_UPDATED_BY           INTEGER EXTERNAL       "'-1'",
  LAST_UPDATE_DATE          CHAR          "SYSDATE",
  LAST_UPDATE_LOGIN         INTEGER EXTERNAL       "'-1'",
  REQUEST_ID                INTEGER EXTERNAL       "CHG_REQUEST_ID",
  PROGRAM_APPLICATION_ID    INTEGER EXTERNAL       "'-1'",
  PROGRAM_ID                INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.1.6 Change End
  PROGRAM_UPDATE_DATE       CHAR          "SYSDATE",
  INTERFACE_ID              POSITION(1)   INTEGER EXTERNAL,
  SLIP_TYPE_NAME            CHAR          TERMINATED BY ",",
  APPROVER_PERSON_NUMBER    CHAR          TERMINATED BY ",",
  VENDOR_CODE               CHAR          TERMINATED BY ",",
  VENDOR_SITE_CODE          CHAR          TERMINATED BY ",",
  VENDOR_INVOICE_NUM        CHAR          TERMINATED BY ",",
  INVOICE_DATE              DATE          "yyyy/mm/dd" TERMINATED BY ",",
  DESCRIPTION               CHAR          TERMINATED BY ",",
  GL_DATE                   DATE          "yyyy/mm/dd" TERMINATED BY ",",
  PAY_GROUP_LOOKUP_NAME     CHAR          TERMINATED BY ",",
  TERMS_NAME                CHAR          TERMINATED BY ",",
  TERMS_DATE                DATE          "yyyy/mm/dd" TERMINATED BY ",",
  INVOICE_CURRENCY_CODE     CHAR          TERMINATED BY ",",
-- Ver.1.1 Modify Start ���ڏ��C��
  EXCHANGE_RATE_TYPE_NAME   CHAR          TERMINATED BY ",",
  EXCHANGE_RATE             CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:EXCHANGE_RATE, '999,999,999,999,999.000')",
--  EXCHANGE_RATE_TYPE_NAME   CHAR          TERMINATED BY ",",
-- Ver.1.1 Modify End
  PREPAY_NUM                CHAR          TERMINATED BY ","
       )

INTO TABLE XX03_PAYMENT_SLIP_LINES_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
  SLIP_LINE_TYPE            CHAR          TERMINATED BY ",",
  ENTERED_ITEM_AMOUNT       CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_ITEM_AMOUNT, '999,999,999,999,999.000')",
  TAX_CODE                  CHAR          TERMINATED BY ",",
  AMOUNT_INCLUDES_TAX_FLAG  CHAR          TERMINATED BY ",",
  ENTERED_TAX_AMOUNT        CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_TAX_AMOUNT, '999,999,999,999,999.000')",
  DESCRIPTION               CHAR          TERMINATED BY ",",
  SEGMENT1                  CHAR          TERMINATED BY ",",
  SEGMENT2                  CHAR          TERMINATED BY ",",
  SEGMENT3                  CHAR          TERMINATED BY ",",
  SEGMENT4                  CHAR          TERMINATED BY ",",
  SEGMENT5                  CHAR          TERMINATED BY ",",
  SEGMENT6                  CHAR          TERMINATED BY ",",
  SEGMENT7                  CHAR          TERMINATED BY ",",
  SEGMENT8                  CHAR          TERMINATED BY ",",
  INCR_DECR_REASON_CODE     CHAR          TERMINATED BY ",",
  RECON_REFERENCE           CHAR          TERMINATED BY ",",
-- ver 2016-11-10 Add Start
  ATTRIBUTE7                CHAR          TERMINATED BY ",",
-- ver 2016-11-10 Add End
  SOURCE                    CHAR          "'EXCEL'",
-- ver 11.5.10.1.6 Change Start
--  ORG_ID                    INTEGER       "'-1'",
--  CREATED_BY                INTEGER       "'-1'",
--  CREATION_DATE             CHAR          "SYSDATE",
--  LAST_UPDATED_BY           INTEGER       "'-1'",
--  LAST_UPDATE_DATE          CHAR          "SYSDATE",
--  LAST_UPDATE_LOGIN         INTEGER       "'-1'",
--  REQUEST_ID                INTEGER       "'-1'",
--  REQUEST_ID                INTEGER       "CHG_REQUEST_ID",
--  PROGRAM_APPLICATION_ID    INTEGER       "'-1'",
--  PROGRAM_ID                INTEGER       "'-1'",
  ORG_ID                    INTEGER EXTERNAL       "'-1'",
  CREATED_BY                INTEGER EXTERNAL       "'-1'",
  CREATION_DATE             CHAR          "SYSDATE",
  LAST_UPDATED_BY           INTEGER EXTERNAL       "'-1'",
  LAST_UPDATE_DATE          CHAR          "SYSDATE",
  LAST_UPDATE_LOGIN         INTEGER EXTERNAL       "'-1'",
  REQUEST_ID                INTEGER EXTERNAL       "CHG_REQUEST_ID",
  PROGRAM_APPLICATION_ID    INTEGER EXTERNAL       "'-1'",
  PROGRAM_ID                INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.1.6 Change End
  PROGRAM_UPDATE_DATE       CHAR          "SYSDATE",
  LINE_NUMBER               SEQUENCE(MAX, 1),
  INTERFACE_ID              POSITION(1)   INTEGER EXTERNAL
       )

