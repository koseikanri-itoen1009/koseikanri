-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A012D.ctl
-- Description   : HHT�[�i�f�[�^�捞�i���ׁj SQL*Loader����
-- MD.050        : 
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCOS_DLV_LINES_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/10/29    1.0     �{�z �ĕ�        �V�K�쐬
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_DLV_LINES_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- ��No.(HHT)
    LINE_NO_HHT                  INTEGER EXTERNAL,                  -- �sNo.(HHT)
    ORDER_NO_EBS                 INTEGER EXTERNAL,                  -- ��No.(EBS)
    LINE_NUMBER_EBS              INTEGER EXTERNAL,                  -- ���הԍ�(EBS)
    ITEM_CODE_SELF               CHAR,                              -- �i���R�[�h(����)
    CASE_NUMBER                  INTEGER EXTERNAL,                  -- �P�[�X��
    QUANTITY                     INTEGER EXTERNAL,                  -- ����
    SALE_CLASS                   CHAR,                              -- ����敪
    WHOLESALE_UNIT_PLOCE         INTEGER EXTERNAL,                  -- ���P��
    SELLING_PRICE                INTEGER EXTERNAL,                  -- ���P��
    COLUMN_NO                    CHAR,                              -- �R����No.
    H_AND_C                      CHAR,                              -- H/C
    SOLD_OUT_CLASS               CHAR,                              -- ���؋敪
    SOLD_OUT_TIME                CHAR,                              -- ���؎���
    REPLENISH_NUMBER             INTEGER EXTERNAL,                  -- ��[��
    CASH_AND_CARD                INTEGER EXTERNAL,                  -- �����E�J�[�h���p�z
    RECEIVE_DATE                 DATE(19) "YYYY/MM/DD HH24:MI:SS",  -- ��M����
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
