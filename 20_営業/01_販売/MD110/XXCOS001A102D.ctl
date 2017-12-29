-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCOS001A102D.ctl
-- Description   : HHT�󒍖��׃��[�N�e�[�u���捞�i���ׁj
-- MD.050        : MD050_COS_001_A10_HHT�󒍃f�[�^�捞 SQL*Loader����
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCOS_HHT_ORDER_LINES_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/07/25    1.0     SCSK K.Kiriu      E_�{�ғ�_14486�i�V�K�쐬�j
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_HHT_ORDER_LINES_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- ��No.(HHT)
    LINE_NO_HHT                  INTEGER EXTERNAL,                  -- �sNo.(HHT)
    ITEM_CODE_SELF               CHAR,                              -- �i���R�[�h(����)
    CASE_NUMBER                  INTEGER EXTERNAL,                  -- �P�[�X��
    QUANTITY                     INTEGER EXTERNAL,                  -- ����
    SALE_CLASS                   CHAR,                              -- ����敪
    WHOLESALE_UNIT_PLICE         INTEGER EXTERNAL,                  -- ���P��
    SELLING_PRICE                INTEGER EXTERNAL,                  -- ���P��
    RECEIVED_DATE                DATE(19) "YYYY/MM/DD HH24:MI:SS",  -- ��M����
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
