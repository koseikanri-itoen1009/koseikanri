-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A12D.ctl
-- Description   : HHT-EBS�C���^�[�t�F�[�X�F(IN)����v��iSQL-LOADER-����v��j
-- MD.050        : MD050_IPO_CSO_014_A01_HHT-EBS�C���^�[�t�F�[�X�F(IN)����v��(SQL-LOADER-����v��)
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCSO_WK_SALES_PLAN_MONTH
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/22    1.0     Kenji.Sai        �V�K�쐬
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_SALES_PLAN_MONTH
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    NO_SEQ                  INTEGER EXTERNAL "XXCSO_IN_SALES_PLAN_MONTH_S01.NEXTVAL",   -- �V�[�P���X�ԍ�
    RECORD_NUMBER           POSITION(1) INTEGER EXTERNAL,                               -- ���R�[�h�ԍ�
    ACCOUNT_NUMBER          POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,               -- �ڋq�R�[�h
    SALES_BASE_CODE         POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,               -- ���㋒�_�R�[�h
    SALES_PLAN_MONTH        POSITION(*) INTEGER EXTERNAL "TO_CHAR(TO_DATE(:SALES_PLAN_MONTH,'YYYYMM'),'YYYYMM')" , -- ����v��N��
    SALES_PLAN_AMT          POSITION(*) INTEGER EXTERNAL,                               -- ����v����z
    COALITION_TRANCE_DATE   SYSDATE,                                             -- �A�g������
    CREATED_BY              "FND_GLOBAL.USER_ID",                                -- *** �쐬��
    CREATION_DATE           SYSDATE,                                             -- *** �쐬��
    LAST_UPDATED_BY         "FND_GLOBAL.USER_ID",                                -- *** �ŏI�X�V��
    LAST_UPDATE_DATE        SYSDATE,                                             -- *** �ŏI�X�V��
    LAST_UPDATE_LOGIN       "FND_GLOBAL.LOGIN_ID",                               -- *** �ŏI�X�V���O�C��
    REQUEST_ID              "FND_GLOBAL.CONC_REQUEST_ID",                        -- *** �v��ID
    PROGRAM_APPLICATION_ID  "FND_GLOBAL.CONC_PROGRAM_ID",                        -- *** �ݶ��ĥ��۸��ѥ���ع����ID
    PROGRAM_ID              "FND_GLOBAL.CONC_PROGRAM_ID",                        -- *** �ݶ��ĥ��۸���ID
    PROGRAM_UPDATE_DATE     SYSDATE                                              -- *** ��۸��эX�V��
  )