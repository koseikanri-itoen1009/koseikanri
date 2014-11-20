-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A05D.ctl
-- Description   : �c�ƃV�X�e���\�z�v���W�F�N�g�A�h�I���FHHT-EBS�C���^�[�t�F�[�X�F(IN)�m�[�g 
-- MD.050        : MD050_CSO_014_A05_HHT-EBS�C���^�[�t�F�[�X�F(IN�j�m�[�g_Draft2.0C.doc
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_NOTES
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/3     1.0     Seirin.Kin         �V�K�쐬
--  2009/03/16    1.1     Kunihiko.Boku      �m�[�g�̃t�B���h���w��
--
-- ************************************************************************************************

OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)

LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_NOTES
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (  
    ACCOUNT_NUMBER          CHAR OPTIONALLY ENCLOSED BY '"' ,              -- �ڋq�R�[�h
    NOTES                   CHAR(2000) OPTIONALLY ENCLOSED BY '"' ,        -- �m�[�g
    EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"' ,              -- �c�ƈ��R�[�h
    INPUT_DATE              DATE "yyyymmdd",                               -- ���͓��t
    INPUT_TIME              CHAR OPTIONALLY ENCLOSED BY '"' ,              -- ���͎���
    NO_SEQ                  "XXCSO_IN_NOTES_S01.NEXTVAL",                   -- �V�[�P���X�ԍ�
    CREATED_BY              "FND_GLOBAL.USER_ID",                          -- *** �쐬��
    CREATION_DATE           SYSDATE,                                       -- *** �쐬��
    LAST_UPDATED_BY         "FND_GLOBAL.USER_ID",                          -- *** �ŏI�X�V��
    LAST_UPDATE_DATE        SYSDATE,                                       -- *** �ŏI�X�V��
    LAST_UPDATE_LOGIN       "FND_GLOBAL.LOGIN_ID",                         -- *** �ŏI�X�V���O�C��
    REQUEST_ID              "FND_GLOBAL.CONC_REQUEST_ID",                  -- *** �v��ID
    PROGRAM_APPLICATION_ID  "FND_GLOBAL.CONC_PROGRAM_ID",                  -- *** �ݶ��ĥ��۸��ѥ���ع����ID
    PROGRAM_ID              "FND_GLOBAL.CONC_PROGRAM_ID",                  -- *** �ݶ��ĥ��۸���ID
    PROGRAM_UPDATE_DATE     SYSDATE                                        -- *** ��۸��эX�V��
  )