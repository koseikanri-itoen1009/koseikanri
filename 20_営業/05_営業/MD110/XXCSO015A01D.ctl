-- ************************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
-- 
-- Control file  : XXCSO015A01D.ctl
-- Description   : ���̋@-EBS�C���^�t�F�[�X�F(IN)��ƃf�[�^ SQL*Loader����
-- BR.050        : T_BR050_CCO_200_����_��ƃf�[�^
-- MD.050        : MD050_CSO_015_A01_���̋@-EBS�C���^�t�F�[�X�F�iIN�j��ƃf�[�^
-- MD.070        : �Ȃ�
-- Version       : 1.4
--
-- Target Table  : XXCSO_IN_WORK_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/11/28    1.0     kyo              �V�K�쐬
--  2009/01/27    1.1     kyo              �x�~�����σt���O���ڒǉ�
--  2009/03/10    1.1     abe              �V�[�P���X�ԍ��̒ǉ�
--  2009/05/29    1.2     K.Satomura       �V�X�e���e�X�g��Q�Ή�(T1_1017,T1_1107)
--  2009/06/04    1.3     K.Satomura       �V�X�e���e�X�g��Q�Ή�(T1_1107�ďC��)
--  2009/12/08    1.4     K.Hosoi          E_�{�ғ�_00219�Ή�
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
INTO TABLE XXCSO_IN_WORK_DATA
APPEND
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    SEQ_NO                         SEQUENCE( MAX ),                         -- �V�[�P���X�ԍ�
    SLIP_NO                        INTEGER EXTERNAL,                        -- �`�[No.
    SLIP_BRANCH_NO                 INTEGER EXTERNAL,                        -- �`�[�}��
    LINE_NUMBER                    INTEGER EXTERNAL,                        -- �s�ԍ�
    JOB_KBN                        INTEGER EXTERNAL,                        -- ��Ƌ敪
    INSTALL_CODE1                  CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE1, NULL, NULL, 
      SUBSTR(:INSTALL_CODE1, 1, 3) || '-' || SUBSTR(:INSTALL_CODE1, 4))",    -- �����R�[�h�P�i�ݒu�p�j
    INSTALL_CODE2                  CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE2, NULL, NULL, 
      SUBSTR(:INSTALL_CODE2, 1, 3) || '-' || SUBSTR(:INSTALL_CODE2, 4))",    -- �����R�[�h�Q�i���g�p�j
    WORK_HOPE_DATE                 INTEGER EXTERNAL,                        -- ��Ɗ�]��/�����]��
    WORK_HOPE_TIME_KBN             INTEGER EXTERNAL,                        -- ��Ɗ�]���ԋ敪
    WORK_HOPE_TIME                 CHAR OPTIONALLY ENCLOSED BY '"',         -- ��Ɗ�]����
    CURRENT_INSTALL_NAME           CHAR OPTIONALLY ENCLOSED BY '"',         -- ���ݒu�於
    NEW_INSTALL_NAME               CHAR OPTIONALLY ENCLOSED BY '"',         -- �V�ݒu�於
    WITHDRAWAL_PROCESS_KBN         INTEGER EXTERNAL,                        -- ���g�@�����敪
    ACTUAL_WORK_DATE               INTEGER EXTERNAL,                        -- ����Ɠ�
    ACTUAL_WORK_TIME1              CHAR OPTIONALLY ENCLOSED BY '"',         -- ����Ǝ��ԂP
    ACTUAL_WORK_TIME2              CHAR OPTIONALLY ENCLOSED BY '"',         -- ����Ǝ��ԂQ
    COMPLETION_KBN                 INTEGER EXTERNAL,                        -- �����敪
    DELETE_FLAG                    INTEGER EXTERNAL,                        -- �폜�t���O
    COMPLETION_PLAN_DATE           INTEGER EXTERNAL,                        -- �����\���/�C�������\���
    COMPLETION_DATE                INTEGER EXTERNAL,                        -- ������/�C��������
    DISPOSAL_APPROVAL_DATE         INTEGER EXTERNAL,                        -- �p�����ٓ�
    WITHDRAWAL_DATE                INTEGER EXTERNAL,                        -- �������/�����
    DELIVERY_DATE                  INTEGER EXTERNAL,                        -- ��t��
    LAST_DISPOSAL_END_DATE         INTEGER EXTERNAL,                        -- �ŏI�����I���N����
    FWD_ROOT_COMPANY_CODE          CHAR OPTIONALLY ENCLOSED BY '"',         -- �i�]�����j��ЃR�[�h
    FWD_ROOT_LOCATION_CODE         CHAR OPTIONALLY ENCLOSED BY '"',         -- �i�]�����j���Ə��R�[�h
    FWD_DISTINATION_COMPANY_CODE   CHAR OPTIONALLY ENCLOSED BY '"',         -- �i�]����j��ЃR�[�h
    FWD_DISTINATION_LOCATION_CODE  CHAR OPTIONALLY ENCLOSED BY '"',         -- �i�]����j���Ə��R�[�h
    CREATION_EMPLOYEE_NUMBER       CHAR OPTIONALLY ENCLOSED BY '"',         -- �쐬�S���҃R�[�h
    CREATION_SECTION_NAME          CHAR OPTIONALLY ENCLOSED BY '"',         -- �쐬�����R�[�h
    CREATION_PROGRAM_ID            CHAR OPTIONALLY ENCLOSED BY '"',         -- �쐬�v���O�����h�c
    UPDATE_EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"',         -- �X�V�S���҃R�[�h
    UPDATE_SECTION_NAME            CHAR OPTIONALLY ENCLOSED BY '"',         -- �X�V�����R�[�h
    UPDATE_PROGRAM_ID              CHAR OPTIONALLY ENCLOSED BY '"',         -- �X�V�v���O�����h�c
    CREATION_DATE_TIME             DATE "yyyymmddhh24miss",                 -- �쐬���������b
    UPDATE_DATE_TIME               DATE "yyyymmddhh24miss",                 -- �X�V���������b
    PO_NUMBER                      INTEGER EXTERNAL,                        -- �����ԍ�
    PO_LINE_NUMBER                 INTEGER EXTERNAL,                        -- �������הԍ�
    PO_DISTRIBUTION_NUMBER         INTEGER EXTERNAL,                        -- ���������ԍ�
    PO_REQ_NUMBER                  INTEGER EXTERNAL,                        -- �����˗��ԍ�
    LINE_NUM                       INTEGER EXTERNAL,                        -- �����˗����הԍ�
    ACCOUNT_NUMBER1                CHAR OPTIONALLY ENCLOSED BY '"',         -- �ڋq�R�[�h�P�i�V�ݒu��j
    ACCOUNT_NUMBER2                CHAR OPTIONALLY ENCLOSED BY '"',         -- �ڋq�R�[�h�Q�i���ݒu��j
    SAFE_SETTING_STANDARD          CHAR OPTIONALLY ENCLOSED BY '"',         -- ���S�ݒu�
    INSTALL1_PROCESSED_FLAG        CONSTANT 'N',                            -- �����P�����σt���O
    INSTALL2_PROCESSED_FLAG        CONSTANT 'N',                            -- �����Q�����σt���O
    SUSPEND_PROCESSED_FLAG         CONSTANT '0',                            -- �x�~�����σt���O
    -- 2009.06.04 K.Satomura T1_1107�ďC���Ή� START
    -- 2009.05.29 K.Satomura T1_1017,T1_1107�Ή� START
    --INSTALL1_PROCESSED_DATE        DATE "yyyymmddhh24miss",                 -- �����P�����ϓ�
    --INSTALL2_PROCESSED_DATE        DATE "yyyymmddhh24miss",                 -- �����Q�����ϓ�
    --VDMS_INTERFACE_FLAG            CHAR OPTIONALLY ENCLOSED BY '"',         -- ���̋@S�A�g�t���O
    --VDMS_INTERFACE_DATE            DATE "yyyymmddhh24miss",                 -- ���̋@S�A�g��
    --PROCESS_NO_TARGET_FLAG         CHAR OPTIONALLY ENCLOSED BY '"',         -- ��ƈ˗������ΏۊO�t���O
    -- 2009.05.29 K.Satomura T1_1017,T1_1107�Ή� END
    INSTALL1_PROCESSED_DATE        CONSTANT "",                           -- �����P�����ϓ�
    INSTALL2_PROCESSED_DATE        CONSTANT "",                           -- �����Q�����ϓ�
    VDMS_INTERFACE_FLAG            CONSTANT 'N',                          -- ���̋@S�A�g�t���O
    VDMS_INTERFACE_DATE            CONSTANT "",                           -- ���̋@S�A�g��
    INSTALL1_PROCESS_NO_TARGET_FLG CONSTANT 'N',                          -- �����P��ƈ˗������ΏۊO�t���O
    INSTALL2_PROCESS_NO_TARGET_FLG CONSTANT 'N',                          -- �����Q��ƈ˗������ΏۊO�t���O
    -- 2009.06.04 K.Satomura T1_1107�ďC���Ή� END
    CREATED_BY                     "FND_GLOBAL.USER_ID",                    -- �쐬��
    CREATION_DATE                  SYSDATE,                                 -- �쐬��
    LAST_UPDATED_BY                "FND_GLOBAL.USER_ID",                    -- �ŏI�X�V��
    LAST_UPDATE_DATE               SYSDATE,                                 -- �ŏI�X�V��
    LAST_UPDATE_LOGIN              "FND_GLOBAL.LOGIN_ID",                   -- �ŏI�X�V���O�C��
    REQUEST_ID                     "FND_GLOBAL.CONC_REQUEST_ID",            -- �v��ID
    PROGRAM_APPLICATION_ID         "FND_GLOBAL.PROG_APPL_ID",     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    PROGRAM_ID                     "FND_GLOBAL.CONC_PROGRAM_ID",            -- �R���J�����g�E�v���O����ID
    PROGRAM_UPDATE_DATE            SYSDATE,                                 -- �v���O�����X�V��
    -- 2009.12.08 K.Hosoi E_�{�ғ�_00219�Ή� START
    INFOS_INTERFACE_FLAG           CONSTANT 'N',                            -- ���n�A�g�σt���O
    INFOS_INTERFACE_DATE           CONSTANT ""                              -- ���n�A�g��
    -- 2009.12.08 K.Hosoi E_�{�ғ�_00219�Ή� END
  )