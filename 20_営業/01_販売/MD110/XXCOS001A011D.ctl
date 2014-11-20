-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A011D.ctl
-- Description   : HHT�[�i�f�[�^�捞�i�w�b�_�j SQL*Loader����
-- MD.050        : 
-- MD.070        : �Ȃ�
-- Version       : 1.1
--
-- Target Table  : XXCOS_DLV_HEADERS_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/10/29    1.0     �{�z �ĕ�        �V�K�쐬
--  2011/03/16    1.1     ���� �s��        [E_�{�ғ�_06590] �I�[�_�[No�ǉ�
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_DLV_HEADERS_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- ��No.(HHT)
    ORDER_NO_EBS                 INTEGER EXTERNAL,                  -- ��No.(EBS)
    BASE_CODE                    CHAR,                              -- ���_�R�[�h
    PERFORMANCE_BY_CODE          CHAR,                              -- ���ю҃R�[�h
    DLV_BY_CODE                  CHAR,                              -- �[�i�҃R�[�h
    HHT_INVOICE_NO               CHAR,                              -- �`�[No.
    DLV_DATE                     DATE(8) "yyyymmdd",                -- �[�i��
    INSPECT_DATE                 DATE(8) "yyyymmdd",                -- ������
    SALES_CLASSIFICATION         CHAR,                              -- ���㕪�ދ敪
    SALES_INVOICE                CHAR,                              -- ����`�[�敪
    CARD_SALE_CLASS              CHAR,                              -- �J�[�h���敪
    VISIT_FLAG                   CHAR,                              -- �K��t���O
    EFFECTIVE_FLAG               CHAR,                              -- �L���t���O
    DLV_TIME                     CHAR,                              -- ����
    CHANGE_OUT_TIME_100          CHAR,                              -- ��K�؂ꎞ��100�~
    CHANGE_OUT_TIME_10           CHAR,                              -- ��K�؂ꎞ��10�~
    CUSTOMER_NUMBER              CHAR,                              -- �ڋq�R�[�h
    INPUT_CLASS                  CHAR,                              -- ���͋敪
    CONSUMPTION_TAX_CLASS        CHAR,                              -- ����ŋ敪
    TOTAL_AMOUNT                 INTEGER EXTERNAL,                  -- ���v���z
    SALE_DISCOUNT_AMOUNT         INTEGER EXTERNAL,                  -- ����l���z
    SALES_CONSUMPTION_TAX        INTEGER EXTERNAL,                  -- �������Ŋz
    TAX_INCLUDE                  INTEGER EXTERNAL,                  -- �ō����z
    KEEP_IN_CODE                 CHAR,                              -- �a����R�[�h
    DEPARTMENT_SCREEN_CLASS      CHAR,                              -- �S�ݓX��ʎ��
-- 2011/03/16 Ver.1.1 S.Ochiai ADD Start
    ORDER_NUMBER                 CHAR,                              --�I�[�_�[No
-- 2011/03/16 Ver.1.1 S.Ochiai ADD End
    RECEIVE_DATE                 DATE(19) "yyyy/mm/dd hh24:mi:ss",  -- ��M����
    CREATED_BY                   CONSTANT "-1",                     -- �쐬��
    CREATION_DATE                SYSDATE,                           -- �쐬��
    LAST_UPDATED_BY              CONSTANT "-1",                     -- �ŏI�X�V��
    LAST_UPDATE_DATE             SYSDATE,                           -- �ŏI�X�V��
    LAST_UPDATE_LOGIN            CONSTANT "-1",                     -- �ŏI�X�V���O�C��
    REQUEST_ID                   CONSTANT "-1",                     -- �v��ID
    PROGRAM_APPLICATION_ID       CONSTANT "-1",                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    PROGRAM_ID                   CONSTANT "-1",                     -- �R���J�����g�E�v���O����ID
    PROGRAM_UPDATE_DATE          SYSDATE                            -- �v���O�����X�V��
  )
