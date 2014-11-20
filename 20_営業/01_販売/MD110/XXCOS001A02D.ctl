-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A02D.ctl
-- Description   : HHT�����f�[�^�捞 SQL*Loader����
-- MD.050        : 
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCOS_PAYMENT_WORK
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
INTO TABLE XXCOS_PAYMENT_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    LINE_ID                 SEQUENCE(MAX),                   -- ����ID
    BASE_CODE               CHAR,                            -- ���_�R�[�h
    CUSTOMER_NUMBER         CHAR,                            -- �ڋq�R�[�h
    HHT_INVOICE_NO          CHAR,                            -- �`�[No
    PAYMENT_AMOUNT          INTEGER EXTERNAL,                -- �����z
    PAYMENT_DATE            DATE(8) "yyyymmdd",              -- ������
    PAYMENT_CLASS           CHAR,                            -- �����敪
    CREATED_BY              CONSTANT "-1",                   -- �쐬��
    CREATION_DATE           SYSDATE,                         -- �쐬��
    LAST_UPDATED_BY         CONSTANT "-1",                   -- �ŏI�X�V��
    LAST_UPDATE_DATE        SYSDATE,                         -- �ŏI�X�V��
    LAST_UPDATE_LOGIN       CONSTANT "-1",                   -- �ŏI�X�V���O�C��
    REQUEST_ID              CONSTANT "-1",                   -- �v��ID
    PROGRAM_APPLICATION_ID  CONSTANT "-1",                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    PROGRAM_ID              CONSTANT "-1",                   -- �R���J�����g�E�v���O����ID
    PROGRAM_UPDATE_DATE     SYSDATE                          -- �v���O�����X�V��
  )
