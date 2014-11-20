-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Control File     : xxwsh430003d(ctl)
-- Description      : �q�֕ԕi���C���^�[�t�F�[�X SQL*Loader����
-- MD.050           : �q�֕ԕi                                    T_MD050_BPO_430
-- MD.070           : �q�֕ԕi���C���^�[�t�F�[�X_SQLLoader����  T_MD070_BPO_43D
-- Version          : 1.2
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2008/02/22    1.0   Oracle �Ŗ� ���\ ����쐬
--  2008/05/16    1.1   Oracle �Ŗ� ���\ �����ύX�v��#100�Ή�
--  2008/06/19    1.2   Oracle �|�� �N�m VARCHAR���ڂ�RTRIM�֐���t��
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWSH_RESERVE_INTERFACE
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
RESERVE_INTERFACE_ID    SEQUENCE(MAX,1),
DATA_CLASS              POSITION(1) CHAR "RTRIM(:DATA_CLASS, ' �@')",
R_NO                    POSITION(*) CHAR "RTRIM(:R_NO, ' �@')",
CONTINUE                POSITION(*) CHAR "RTRIM(:CONTINUE, ' �@')",
RECORDED_YEAR           POSITION(*) CHAR "RTRIM(:RECORDED_YEAR, ' �@')",
INPUT_BASE_CODE         POSITION(*) CHAR "RTRIM(:INPUT_BASE_CODE, ' �@')",
RECEIVE_BASE_CODE       POSITION(*) CHAR "RTRIM(:RECEIVE_BASE_CODE, ' �@')",
INVOICE_CLASS_1         POSITION(*) CHAR "RTRIM(:INVOICE_CLASS_1, ' �@')",
INVOICE_CLASS_2         POSITION(*) CHAR "RTRIM(:INVOICE_CLASS_2, ' �@')",
RECORDED_DATE           POSITION(*)   DATE(8)"YYYYMMDD",
SHIP_TO_CODE            POSITION(*) CHAR "RTRIM(:SHIP_TO_CODE, ' �@')",
CUSTOMER_CODE           POSITION(*) CHAR "RTRIM(:CUSTOMER_CODE, ' �@')",
INVOICE_NO              POSITION(*) CHAR "RTRIM(:INVOICE_NO, ' �@')",
ITEM_CODE               POSITION(*) CHAR "RTRIM(:ITEM_CODE, ' �@')",
PARENT_ITEM_CODE        POSITION(*) CHAR "RTRIM(:PARENT_ITEM_CODE, ' �@')",
CROWD_CODE              POSITION(*) CHAR "RTRIM(:CROWD_CODE, ' �@')",
CASE_AMOUNT_OF_CONTENT  POSITION(*),
QUANTITY_IN_CASE        POSITION(*),
QUANTITY                POSITION(*),
CREATED_BY              CONSTANT 0,
CREATION_DATE           SYSDATE,
LAST_UPDATED_BY         CONSTANT 0,
LAST_UPDATE_DATE        SYSDATE,
LAST_UPDATE_LOGIN       CONSTANT 0,
REQUEST_ID              CONSTANT 0,
PROGRAM_APPLICATION_ID  CONSTANT 0,
PROGRAM_ID              CONSTANT 0,
PROGRAM_UPDATE_DATE     SYSDATE
)
