-- ****************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
--
-- Control File  : XXCOI003A121D.ctl
-- Description   : HHT���o�Ƀf�[�^���o�iSQLLoader�j
-- MD.050        : HHT���o�Ƀf�[�^���o MD050_COI_003_A12
-- Version       : 1.1
--
-- Target Table  : XXCOI_HHT_INV_IF
--
-- Change Record
-- ------------- ----- ---------------- -------------------------------------------------
--  Date          Ver.  Editor           Description
-- ------------- ----- ---------------- -------------------------------------------------
--  2008/11/20    1.0   SCS H.Nakajima   �V�K�쐬
--  2009/02/16    1.1   SCS K.Nakamura   [��QCOI_004] ���t�̌^�s���Ή�
--****************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE "XXCOI_IN_HHT_INV_TRANSACTIONS"
FIELDS TERMINATED BY ','
(
    INTERFACE_ID
    ,BASE_CODE               OPTIONALLY ENCLOSED BY '"'
    ,RECORD_TYPE             OPTIONALLY ENCLOSED BY '"'
    ,EMPLOYEE_NUM            OPTIONALLY ENCLOSED BY '"'
    ,INVOICE_NO              OPTIONALLY ENCLOSED BY '"'
    ,ITEM_CODE               OPTIONALLY ENCLOSED BY '"'
    ,CASE_QUANTITY           
    ,CASE_IN_QUANTITY        
    ,QUANTITY                
    ,INVOICE_TYPE            OPTIONALLY ENCLOSED BY '"'
    ,BASE_DELIVERY_FLAG      OPTIONALLY ENCLOSED BY '"'
    ,OUTSIDE_CODE            OPTIONALLY ENCLOSED BY '"'
    ,INSIDE_CODE             OPTIONALLY ENCLOSED BY '"'
    ,INVOICE_DATE            DATE(8) "YYYYMMDD"
    ,COLUMN_NO               OPTIONALLY ENCLOSED BY '"'
    ,UNIT_PRICE              
    ,HOT_COLD_DIV            OPTIONALLY ENCLOSED BY '"'
    ,DEPARTMENT_FLAG         OPTIONALLY ENCLOSED BY '"'
    ,OTHER_BASE_CODE         OPTIONALLY ENCLOSED BY '"'
    ,INTERFACE_DATE          DATE(19) "YYYY/MM/DD HH24:MI:SS" OPTIONALLY ENCLOSED BY '"'
    ,CREATED_BY              CONSTANT "-1"
    ,CREATION_DATE           SYSDATE
    ,LAST_UPDATED_BY         CONSTANT "-1" 
    ,LAST_UPDATE_DATE        SYSDATE
    ,LAST_UPDATE_LOGIN       CONSTANT "-1"
    ,REQUEST_ID              CONSTANT "-1"
    ,PROGRAM_APPLICATION_ID  CONSTANT "-1"
    ,PROGRAM_ID              CONSTANT "-1"
    ,PROGRAM_UPDATE_DATE     SYSDATE
)

