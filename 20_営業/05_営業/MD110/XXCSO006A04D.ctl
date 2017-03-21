-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCSO006A04D.ctl
-- Description   : eSM-EBS�C���^�t�F�[�X�F�iIN�j�K����уf�[�^�iSQL-LOADER-�K����я��j
-- MD.050        : MD050_CSO_006_A03_eSM-EBS�C���^�t�F�[�X�F�iIN�j�K����уf�[�^
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_VISIT_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/03/15    1.0     K.Kiriu          �V�K�쐬
--
-- ************************************************************************************************
--
OPTIONS (DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_VISIT_DATA
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    BASE_NAME                CHAR(360) OPTIONALLY ENCLOSED BY '"',                            -- ������
    EMPLOYEE_NUMBER          CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �Ј��R�[�h
    ACCOUNT_NUMBER           CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �ڋq�R�[�h
    BUSINESS_TYPE            CHAR(100) OPTIONALLY ENCLOSED BY '"',                            -- �Ɩ��^�C�v
    VISIT_DATE               DATE "YYYY/MM/DD" OPTIONALLY ENCLOSED BY '"',                    -- �K���
    VISIT_TIME               CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �K��J�n����
    VISIT_TIME_END           CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �K��I������
    DETAIL                   CHAR(4000) OPTIONALLY ENCLOSED BY '"',                           -- �ڍד��e
    ACTIVITY_CONTENT1        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P
    ACTIVITY_CONTENT2        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�Q
    ACTIVITY_CONTENT3        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�R
    ACTIVITY_CONTENT4        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�S
    ACTIVITY_CONTENT5        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�T
    ACTIVITY_CONTENT6        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�U
    ACTIVITY_CONTENT7        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�V
    ACTIVITY_CONTENT8        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�W
    ACTIVITY_CONTENT9        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�X
    ACTIVITY_CONTENT10       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�O
    ACTIVITY_CONTENT11       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�P
    ACTIVITY_CONTENT12       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�Q
    ACTIVITY_CONTENT13       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�R
    ACTIVITY_CONTENT14       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�S
    ACTIVITY_CONTENT15       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�T
    ACTIVITY_CONTENT16       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�U
    ACTIVITY_CONTENT17       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�V
    ACTIVITY_CONTENT18       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�W
    ACTIVITY_CONTENT19       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�P�X
    ACTIVITY_CONTENT20       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- �������e�Q�O
    ACTIVITY_TIME1           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP(���j
    ACTIVITY_TIME2           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂQ�i���j
    ACTIVITY_TIME3           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂR�i���j
    ACTIVITY_TIME4           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂS�i���j
    ACTIVITY_TIME5           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂT�i���j
    ACTIVITY_TIME6           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂU�i���j
    ACTIVITY_TIME7           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂV�i���j
    ACTIVITY_TIME8           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂW�i���j
    ACTIVITY_TIME9           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂX�i���j
    ACTIVITY_TIME10          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�O�i���j
    ACTIVITY_TIME11          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�P�i���j
    ACTIVITY_TIME12          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�Q�i���j
    ACTIVITY_TIME13          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�R�i���j
    ACTIVITY_TIME14          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�S�i���j
    ACTIVITY_TIME15          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�T�i���j
    ACTIVITY_TIME16          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�U�i���j
    ACTIVITY_TIME17          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�V�i���j
    ACTIVITY_TIME18          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�W�i���j
    ACTIVITY_TIME19          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂP�X�i���j
    ACTIVITY_TIME20          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- �������ԂQ�O�i���j
    ESM_INPUT_DATE           DATE "YYYY/MM/DD HH24:MI" OPTIONALLY ENCLOSED BY '"',            -- eSM���͓���
    SEQ_NO                   "XXCSO_IN_VISIT_DATA_S01.NEXTVAL",                               -- �V�[�P���X�ԍ�
    CREATED_BY               "FND_GLOBAL.USER_ID",                                            -- *** �쐬��
    CREATION_DATE            SYSDATE,                                                         -- *** �쐬��
    LAST_UPDATED_BY          "FND_GLOBAL.USER_ID",                                            -- *** �ŏI�X�V��
    LAST_UPDATE_DATE         SYSDATE,                                                         -- *** �ŏI�X�V��
    LAST_UPDATE_LOGIN        "FND_GLOBAL.LOGIN_ID",                                           -- *** �ŏI�X�V���O�C��
    REQUEST_ID               "FND_GLOBAL.CONC_REQUEST_ID",                                    -- *** �v��ID
    PROGRAM_APPLICATION_ID   "FND_GLOBAL.PROG_APPL_ID",                                       -- *** �ݶ��ĥ��۸��ѥ���ع����ID
    PROGRAM_ID               "FND_GLOBAL.CONC_PROGRAM_ID",                                    -- *** �ݶ��ĥ��۸���ID
    PROGRAM_UPDATE_DATE      SYSDATE                                                          -- *** ��۸��эX�V��
  )