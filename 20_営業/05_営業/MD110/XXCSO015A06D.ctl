-- ************************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
-- 
-- Control file  : XXCSO015A06D.ctl
-- Description   : ���̋@-EBS�C���^�t�F�[�X�F(IN)�����}�X�^�| SQL*Loader����
-- BR.050        : T_BR050_CCO_200_����_�����t�@�C��
-- MD.050        : �Ȃ�
-- MD.070        : �Ȃ�
-- Version       : 1.1
--
-- Target Table  : XXCSO_IN_ITEM_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/1    1.0     kyo              �V�K�쐬
--  2016/02/05   1.1     S.Niki           [E_�{�ғ�_13456]���̋@�Ǘ��V�X�e����֑Ή�
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
INTO TABLE XXCSO_IN_ITEM_DATA
APPEND
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    INSTALL_CODE                   CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE, NULL, NULL, SUBSTR(:INSTALL_CODE, 1, 3) || '-' || SUBSTR(:INSTALL_CODE, 4))",  -- �����R�[�h
    UN_NUMBER                      CHAR OPTIONALLY ENCLOSED BY '"',     -- �@��
    INSTALL_NUMBER                 CHAR OPTIONALLY ENCLOSED BY '"',     -- �@��
    MACHINERY_KBN                  INTEGER EXTERNAL,                    -- �@��敪
    MANUFACTURER_CODE              CHAR OPTIONALLY ENCLOSED BY '"',     -- ���[�J�[
    AGE_TYPE                       CHAR OPTIONALLY ENCLOSED BY '"',     -- �N��
    SELE_NUMBER                    INTEGER EXTERNAL,                    -- �Z����
    SPECIAL_MACHINE1               CHAR OPTIONALLY ENCLOSED BY '"',     -- ����@�P
    SPECIAL_MACHINE2               CHAR OPTIONALLY ENCLOSED BY '"',     -- ����@�Q
    SPECIAL_MACHINE3               CHAR OPTIONALLY ENCLOSED BY '"',     -- ����@�R
    FIRST_INSTALL_DATE             INTEGER EXTERNAL,                    -- ����ݒu��
    COUNTER_NO                     INTEGER EXTERNAL,                    -- �J�E���^�[No.
    DIVISION_CODE                  CHAR OPTIONALLY ENCLOSED BY '"',     -- �n��R�[�h
    BASE_CODE                      CHAR OPTIONALLY ENCLOSED BY '"',     -- ���_�R�[�h
    JOB_COMPANY_CODE               CHAR OPTIONALLY ENCLOSED BY '"',     -- ��Ɖ�ЃR�[�h
    LOCATION_CODE                  CHAR OPTIONALLY ENCLOSED BY '"',     -- ���Ə��R�[�h
    LAST_JOB_SLIP_NO               INTEGER EXTERNAL,                    -- �ŏI��Ɠ`�[No.
    LAST_JOB_KBN                   INTEGER EXTERNAL,                    -- �ŏI��Ƌ敪
    LAST_JOB_GOING                 INTEGER EXTERNAL,                    -- �ŏI��Ɛi��
    LAST_JOB_COMPLETION_PLAN_DATE  INTEGER EXTERNAL,                    -- �ŏI��Ɗ����\���
    LAST_JOB_COMPLETION_DATE       INTEGER EXTERNAL,                    -- �ŏI��Ɗ�����
    LAST_MAINTENANCE_CONTENTS      INTEGER EXTERNAL,                    -- �ŏI�������e
    LAST_INSTALL_SLIP_NO           INTEGER EXTERNAL,                    -- �ŏI�ݒu�`�[No.
    LAST_INSTALL_KBN               INTEGER EXTERNAL,                    -- �ŏI�ݒu�敪
    LAST_INSTALL_PLAN_DATE         INTEGER EXTERNAL,                    -- �ŏI�ݒu�\���
    LAST_INSTALL_GOING             INTEGER EXTERNAL,                    -- �ŏI�ݒu�i��
    MACHINERY_STATUS1              INTEGER EXTERNAL,                    -- �@����1�i�ғ���ԁj
    MACHINERY_STATUS2              INTEGER EXTERNAL,                    -- �@����2�i��ԏڍׁj
    MACHINERY_STATUS3              INTEGER EXTERNAL,                    -- �@����3�i�p�����j
    STOCK_DATE                     INTEGER EXTERNAL,                    -- ���ɓ�
    WITHDRAW_COMPANY_CODE          CHAR OPTIONALLY ENCLOSED BY '"',     -- ���g��ЃR�[�h
    WITHDRAW_LOCATION_CODE         CHAR OPTIONALLY ENCLOSED BY '"',     -- ���g���Ə��R�[�h
    INSTALL_NAME                   CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu�於
    INSTALL_EMPLOYEE_NAME          CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��S���Җ�
    INSTALL_PHONE_NUMBER1          CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��TEL�P
    INSTALL_PHONE_NUMBER2          CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��TEL�Q
    INSTALL_PHONE_NUMBER3          CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��TEL�R
    INSTALL_POSTAL_CODE            INTEGER EXTERNAL,                    -- �ݒu��X�֔ԍ�
    INSTALL_ADDRESS1               CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��Z���P
    INSTALL_ADDRESS2               CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��Z���Q
    INSTALL_ADDRESS3               CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��Z���R
    INSTALL_ADDRESS4               CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��Z���S
    INSTALL_ADDRESS5               CHAR OPTIONALLY ENCLOSED BY '"',     -- �ݒu��Z���T
    DISPOSAL_APPROVAL_DATE         INTEGER EXTERNAL,                    -- �p�����ٓ�
    RESALE_DISPOSAL_VENDOR         CHAR OPTIONALLY ENCLOSED BY '"',     -- �]���p���Ǝ�
    RESALE_DISPOSAL_SLIP_NO        INTEGER EXTERNAL,                    -- �]���p���`�[��
    OWNER_COMPANY_CODE             CHAR OPTIONALLY ENCLOSED BY '"',     -- ���L��
    LEASE_START_DATE               INTEGER EXTERNAL,                    -- ���[�X�J�n��
    LEASE_CHARGE                   INTEGER EXTERNAL,                    -- ���[�X��
    ORG_CONTRACT_NUMBER            CHAR OPTIONALLY ENCLOSED BY '"',     -- ���_��ԍ�
    ORG_CONTRACT_LINE_NUMBER       INTEGER EXTERNAL,                    -- ���_��ԍ�-�}��
    CONTRACT_DATE                  INTEGER EXTERNAL,                    -- ���_���
    CONTRACT_NUMBER                CHAR OPTIONALLY ENCLOSED BY '"',     -- ���_��ԍ�
    CONTRACT_LINE_NUMBER           INTEGER EXTERNAL,                    -- ���_��ԍ�-�}��
    RESALE_DISPOSAL_FLAG           INTEGER EXTERNAL,                    -- �]���p���󋵃t���O
    RESALE_COMPLETION_KBN          INTEGER EXTERNAL,                    -- �]�������敪
    DELETE_FLAG                    INTEGER EXTERNAL,                    -- �폜�t���O
    CREATION_EMPLOYEE_NUMBER       CHAR OPTIONALLY ENCLOSED BY '"',     -- �쐬�S���҃R�[�h
    CREATION_SECTION_NAME          CHAR OPTIONALLY ENCLOSED BY '"',     -- �쐬�����R�[�h
    CREATION_PROGRAM_ID            CHAR OPTIONALLY ENCLOSED BY '"',     -- �쐬�v���O�����h�c
    UPDATE_EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"',     -- �X�V�S���҃R�[�h
    UPDATE_SECTION_NAME            CHAR OPTIONALLY ENCLOSED BY '"',     -- �X�V�����R�[�h
    UPDATE_PROGRAM_ID              CHAR OPTIONALLY ENCLOSED BY '"',     -- �X�V�v���O�����h�c
    CREATION_DATE_TIME             DATE "yyyymmddhh24miss",             -- �쐬���������b
    UPDATE_DATE_TIME               DATE "yyyymmddhh24miss",             -- �X�V���������b
-- Ver1.1 Add Start
    LEASE_TYPE                     CHAR OPTIONALLY ENCLOSED BY '"',     -- ���[�X�敪
    DECLARATION_PLACE              CHAR OPTIONALLY ENCLOSED BY '"',     -- �\���n
    GET_PRICE                      INTEGER EXTERNAL,                    -- �擾���i
-- Ver1.1 Add End
    CREATED_BY                     "FND_GLOBAL.USER_ID",                -- �쐬��
    CREATION_DATE                  SYSDATE,                             -- �쐬��
    LAST_UPDATED_BY                "FND_GLOBAL.USER_ID",                -- �ŏI�X�V��
    LAST_UPDATE_DATE               SYSDATE,                             -- �ŏI�X�V��
    LAST_UPDATE_LOGIN              "FND_GLOBAL.LOGIN_ID",               -- �ŏI�X�V���O�C��
    REQUEST_ID                     "FND_GLOBAL.CONC_REQUEST_ID",        -- �v��ID
    PROGRAM_APPLICATION_ID         "FND_GLOBAL.PROG_APPL_ID",           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    PROGRAM_ID                     "FND_GLOBAL.CONC_PROGRAM_ID",        -- �R���J�����g�E�v���O����ID
    PROGRAM_UPDATE_DATE            SYSDATE                              -- �v���O�����X�V��
  )
