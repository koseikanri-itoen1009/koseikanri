--********************************************************************
-- ����t�@�C��  : LDR_XX034RL001C.ctl
-- �@�\�T�v      : ������́iAR�j�f�[�^���[�h
-- �o�[�W����    : 11.5.10.2.6
-- �쐬��        : ��C�S��
-- �쐬��        : 2005-01-12
-- �ύX��        : �X�V��,�呐���l
-- �ŏI�ύX��    : 2016-11-29
-- �ύX����      :
--     2005-01-12 �V�K�쐬
--     2005-03-03 LOAD���ł�PROFILE�擾��SHELL�ŏ�������Ή�
--     2005-11-29 INTEGER�^��INTEGER EXTERNAL�^�ɕύX
--     2006-09-05 REQUEST_ID��SHELL�̕����ϊ��ŏ������AORG_ID���㑱��
--                �v���O������UPDATE�ŏ�������Ή��ɕύX
--     2016-11-29 ��Q�Ή�E_�{�ғ�_13901
--
-- Copyright (c) 2004-2005 Oracle Corporation Japan All Rights Reserved
-- ���v���O�����g�p�ɍۂ��Ĉ�؂̕ۏ؂͍s��Ȃ�
-- �����ɂ�鎖�O���F�̂Ȃ���O�҂ւ̊J���s��
--********************************************************************
OPTIONS (SKIP=1, DIRECT=FALSE, ERRORS=99999)
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XX03_RECEIVABLE_SLIPS_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
    SOURCE                     CHAR          "'EXCEL'"                            -- �\�[�X
  , WF_STATUS                  CHAR          "'00'"                               -- �X�e�[�^�X
  , ENTRY_DATE                 CHAR          "SYSDATE"                            -- �N�[��
  , ENTRY_PERSON_NUMBER        CHAR          "'-1'"                               -- �\����
  , REQUESTOR_PERSON_NUMBER    CHAR          "'-1'"                               -- �`�[���͎�
-- ver 1.1 Change Start
--  , ORG_ID                     INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')"   -- �I���OID
-- ver 11.5.10.1.6 Change Start
--  , ORG_ID                     INTEGER       "CHG_ORG_ID"   -- �I���OID
-- ver 1.1 Change End
--  , CREATED_BY                 INTEGER       "'-1'"
--  , CREATION_DATE              CHAR          "SYSDATE"
--  , LAST_UPDATED_BY            INTEGER       "'-1'"
--  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
--  , LAST_UPDATE_LOGIN          INTEGER       "'-1'"
--  , REQUEST_ID                 INTEGER       "'-1'"
--  , PROGRAM_APPLICATION_ID     INTEGER       "'-1'"
--  , PROGRAM_ID                 INTEGER       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , ORG_ID                     INTEGER EXTERNAL       "CHG_ORG_ID"   -- �I���OID
  , ORG_ID                     INTEGER EXTERNAL       "'-1'"   -- �I���OID
-- ver 11.5.10.2.5 Chg End
  , CREATED_BY                 INTEGER EXTERNAL       "'-1'"
  , CREATION_DATE              CHAR          "SYSDATE"
  , LAST_UPDATED_BY            INTEGER EXTERNAL       "'-1'"
  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
  , LAST_UPDATE_LOGIN          INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , REQUEST_ID                 INTEGER EXTERNAL       "'-1'"
  , REQUEST_ID                 INTEGER EXTERNAL       "CHG_REQUEST_ID"
-- ver 11.5.10.2.5 Chg End
  , PROGRAM_APPLICATION_ID     INTEGER EXTERNAL       "'-1'"
  , PROGRAM_ID                 INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.1.6 Change End
  , PROGRAM_UPDATE_DATE        CHAR          "SYSDATE"
  , INTERFACE_ID               POSITION(1)   INTEGER EXTERNAL                     -- �C���^�[�t�F�C�XID
  , SLIP_TYPE_NAME             CHAR          TERMINATED BY ","                    -- �`�[���
  , APPROVER_PERSON_NUMBER     CHAR          TERMINATED BY ","                    -- ���F��

-- ver 1.1 Change Start
--  , TRANS_TYPE_ID              CHAR          TERMINATED BY ","                    -- ����^�C�vID
--  , CUSTOMER_ID                CHAR          TERMINATED BY ","                    -- �ڋqID
--  , CUSTOMER_OFFICE_ID         CHAR          TERMINATED BY ","                    -- �ڋq���Ə�ID
  , TRANS_TYPE_NAME            CHAR          TERMINATED BY ","                    -- ����^�C�v
  , CUSTOMER_NUMBER            CHAR          TERMINATED BY ","                    -- �ڋq
  , LOCATION                   CHAR          TERMINATED BY ","                    -- �ڋq���Ə�
-- ver 1.1 Change End

  , INVOICE_DATE               DATE          "yyyy/mm/dd" TERMINATED BY ","       -- ���������t
  , GL_DATE                    DATE          "yyyy/mm/dd" TERMINATED BY ","       -- �v���
  , RECEIPT_METHOD_NAME        CHAR          TERMINATED BY ","                    -- �x�����@
  , TERMS_NAME                 CHAR          TERMINATED BY ","                    -- �x������
  , CURRENCY_CODE              CHAR          TERMINATED BY ","                    -- �ʉ݃R�[�h
  , CONVERSION_RATE            CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:CONVERSION_RATE, '999,999,999,999,999.000')"  -- ���[�g
  , CONVERSION_TYPE            CHAR          TERMINATED BY ","                    -- ���[�g�^�C�v
  , COMMITMENT_NUMBER          CHAR          TERMINATED BY ","                    -- �O����[���`�[�ԍ�
  , DESCRIPTION                CHAR          TERMINATED BY ","                    -- ���l
  , ONETIME_CUSTOMER_NAME      CHAR          TERMINATED BY ","                    -- �ꌩ�ڋq����
  , ONETIME_CUSTOMER_KANA_NAME CHAR          TERMINATED BY ","                    -- �J�i��
  , ONETIME_CUSTOMER_ADDRESS_1 CHAR          TERMINATED BY ","                    -- �Z���P
  , ONETIME_CUSTOMER_ADDRESS_2 CHAR          TERMINATED BY ","                    -- �Z���Q
  , ONETIME_CUSTOMER_ADDRESS_3 CHAR          TERMINATED BY ","                    -- �Z���R
       )

INTO TABLE XX03_RECEIVABLE_SLIPS_LINE_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
    LINE_NUMBER                CHAR          TERMINATED BY ","                    -- No�i���הԍ��j
  , SLIP_LINE_TYPE_NAME        CHAR          TERMINATED BY ","                    -- �������e
  , SLIP_LINE_UOM              CHAR          TERMINATED BY ","                    -- �P��
  , SLIP_LINE_QUANTITY         CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:SLIP_LINE_QUANTITY, '999,999,999,999,999.000')"   -- ����
  , SLIP_LINE_UNIT_PRICE       CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:SLIP_LINE_UNIT_PRICE, '999,999,999,999,999.000')"   -- �P��
  , ENTERED_TAX_AMOUNT         CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_TAX_AMOUNT, '999,999,999,999,999.000')"   -- �ŋ����z
  , SLIP_LINE_TAX_FLAG         CHAR          TERMINATED BY ","                    -- ����
  , SLIP_LINE_TAX_CODE         CHAR          TERMINATED BY ","                    -- �ŋ敪
  , SLIP_LINE_RECIEPT_NO       CHAR          TERMINATED BY ","                    -- �[�i���ԍ�
  , SLIP_DESCRIPTION           CHAR          TERMINATED BY ","                    -- ���l�i���ׁj
  , SEGMENT1                   CHAR          TERMINATED BY ","                    -- ��ЃR�[�h
  , SEGMENT2                   CHAR          TERMINATED BY ","                    -- ����R�[�h
  , SEGMENT3                   CHAR          TERMINATED BY ","                    -- ����Ȗ�
  , SEGMENT4                   CHAR          TERMINATED BY ","                    -- �⏕�Ȗ�
  , SEGMENT5                   CHAR          TERMINATED BY ","                    -- �����
  , SEGMENT6                   CHAR          TERMINATED BY ","                    -- ���Ƌ敪
  , SEGMENT7                   CHAR          TERMINATED BY ","                    -- �v���W�F�N�g
  , SEGMENT8                   CHAR          TERMINATED BY ","                    -- �\���P
  , JOURNAL_DESCRIPTION        CHAR          TERMINATED BY ","                    -- ���l�i�d��j
  , INCR_DECR_REASON_CODE      CHAR          TERMINATED BY ","                    -- �������R
  , RECON_REFERENCE            CHAR          TERMINATED BY ","                    -- �����Q��
-- ver 2016-11-29 Change Start
  , ATTRIBUTE7                 CHAR          TERMINATED BY ","                    -- �g�c���ٔԍ�
-- ver 2016-11-29 Change End
-- ver 1.1 Change Start
--  , ORG_ID                     INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')"   -- �I���OID
-- ver 11.5.10.1.6 Change Start
--  , ORG_ID                     INTEGER       "CHG_ORG_ID"   -- �I���OID
-- ver 1.1 Change End
--  , SOURCE                     CHAR          "'EXCEL'"
--  , CREATED_BY                 INTEGER       "'-1'"
--  , CREATION_DATE              CHAR          "SYSDATE"
--  , LAST_UPDATED_BY            INTEGER       "'-1'"
--  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
--  , LAST_UPDATE_LOGIN          INTEGER       "'-1'"
--  , REQUEST_ID                 INTEGER       "'-1'"
--  , PROGRAM_APPLICATION_ID     INTEGER       "'-1'"
--  , PROGRAM_ID                 INTEGER       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , ORG_ID                     INTEGER EXTERNAL       "CHG_ORG_ID"   -- �I���OID
  , ORG_ID                     INTEGER EXTERNAL       "'-1'"   -- �I���OID
-- ver 11.5.10.2.5 Chg End
  , SOURCE                     CHAR          "'EXCEL'"
  , CREATED_BY                 INTEGER EXTERNAL       "'-1'"
  , CREATION_DATE              CHAR          "SYSDATE"
  , LAST_UPDATED_BY            INTEGER EXTERNAL       "'-1'"
  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
  , LAST_UPDATE_LOGIN          INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , REQUEST_ID                 INTEGER EXTERNAL       "'-1'"
  , REQUEST_ID                 INTEGER EXTERNAL       "CHG_REQUEST_ID"
-- ver 11.5.10.2.5 Chg End
  , PROGRAM_APPLICATION_ID     INTEGER EXTERNAL       "'-1'"
  , PROGRAM_ID                 INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.1.6 Change End
  , PROGRAM_UPDATE_DATE        CHAR          "SYSDATE"
  , INTERFACE_ID               POSITION(1)   INTEGER EXTERNAL                     -- �C���^�[�t�F�C�XID
  , RECEIVABLE_LINE_ID         SEQUENCE(MAX, 1)
       )
