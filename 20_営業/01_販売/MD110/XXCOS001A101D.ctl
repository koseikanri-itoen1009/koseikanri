-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCOS001A101D.ctl
-- Description   : HHT�󒍃w�b�_���[�N�e�[�u���捞�i�w�b�_�j
-- MD.050        : MD050_COS_001_A10_HHT�󒍃f�[�^�捞 SQL*Loader����
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCOS_HHT_ORDER_HEADERS_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/08/15    1.0     SCSK K.Kiriu      E_�{�ғ�_14486�i�V�K�쐬�j
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_HHT_ORDER_HEADERS_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- ��No.(HHT)
    BASE_CODE                    CHAR,                              -- ���_�R�[�h
    DLV_BY_CODE                  CHAR,                              -- �[�i�҃R�[�h
    INVOICE_NO                   CHAR,                              -- �`�[No.
    DLV_DATE                     DATE(8) "yyyymmdd",                -- �[�i�\���
    SALES_CLASSIFICATION         CHAR,                              -- ���㕪�ދ敪
    SALES_INVOICE                CHAR,                              -- ����`�[�敪
    DLV_TIME                     CHAR,                              -- ����
    CUSTOMER_NUMBER              CHAR,                              -- �ڋq�R�[�h
    CONSUMPTION_TAX_CLASS        CHAR,                              -- ����ŋ敪
    TOTAL_AMOUNT                 INTEGER EXTERNAL,                  -- ���v���z
    SALES_CONSUMPTION_TAX        INTEGER EXTERNAL,                  -- �������Ŋz
    TAX_INCLUDE                  INTEGER EXTERNAL,                  -- �ō����z
    SYSTEM_DATE                  DATE(8) "yyyymmdd",                -- �V�X�e�����t
    ORDER_NO                     CHAR,                              -- �I�[�_�[No
    RECEIVED_DATE                DATE(19) "yyyy/mm/dd hh24:mi:ss",  -- ��M����
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
