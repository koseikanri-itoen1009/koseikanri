-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A13D.ctl
-- Description   : HHT-EBS�C���^�[�t�F�[�X�F(IN)���[�g���(SQL-LOADER-���[�g���)
-- MD.050        : MD050_IPO_CSO_014_A04_HHT-EBS�C���^�[�t�F�[�X�F(IN)���[�g���(SQL-LOADER-���[�g���)
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_ROUTE_NO
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2009/1/16    1.0     Kenji.Sai        �V�K�쐬
--  2009/5/7     1.1     Tomoko.Mori      T1_0912�Ή�
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_ROUTE_NO
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    NO_SEQ                  INTEGER EXTERNAL "XXCSO_IN_ROUTE_NO_S01.NEXTVAL",    -- �V�[�P���X�ԍ�
    RECORD_NUMBER           POSITION(1) INTEGER EXTERNAL,                        -- ���R�[�h�ԍ�
    ACCOUNT_NUMBER          POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,        -- �ڋq�R�[�h
--    /*20090507_mori_T1_0912 START*/
    ROUTE_NO                POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' "TRIM(' ' from :ROUTE_NO)",        -- ���[�g�R�[�h
--    ROUTE_NO                POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,        -- ���[�g�R�[�h
--    /*20090507_mori_T1_0912 END*/
    INPUT_DATE              POSITION(*) INTEGER EXTERNAL "TO_DATE(:INPUT_DATE,'YYYYMMDD')" , -- ���͓��t
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