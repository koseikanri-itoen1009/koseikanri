-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXINV530004D.ctl
-- Description   : HHT�I���f�[�^ SQL*Loader����
-- MD.050        : T_MD050_BPO_530_�I��
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXINV_STC_INVENTORY_HHT_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/03/25    1.0     T.Endou      	   �V�K�쐬
--
-- ************************************************************************************************

OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)

LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXINV_STC_INVENTORY_HHT_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
  (
    COMPANY_NAME            CHAR,                          -- ��Ж�
    DATA_KBN                CHAR,                          -- �f�[�^���
    TRANS_NUMBER            CHAR,                          -- �`���p�}��
    REPORT_POST_CODE        CHAR,                            -- 003 �񍐕���
    INVENT_DATE             DATE "yyyy/mm/dd hh24:mi:ss",    -- 011 �I����
    INVENT_WHSE_CODE        CHAR,                            -- 002 �I���q��
    INVENT_SEQ              CHAR,                            -- 001 �I���A��
    ITEM_CODE               CHAR,                            -- 004 �i��
    LOT_NO                  CHAR,                            -- 005 ���b�gNo
    MAKER_DATE              CHAR,                            -- 006 ������
    LIMIT_DATE              CHAR,                            -- 007 �ܖ�����
    PROPER_MARK             CHAR,                            -- 008 �ŗL�L��
    CASE_AMT                INTEGER EXTERNAL,                -- 009 �I���P�[�X��
    CONTENT                 INTEGER EXTERNAL,                -- 012 ����
    LOOSE_AMT               INTEGER EXTERNAL,                -- 010 �I���o��
    LOCATION                CHAR,                            -- 013 ���P�[�V����
    RACK_NO1                CHAR,                            -- 014 ���b�NNo�P
    RACK_NO2                CHAR,                            -- 015 ���b�NNo�Q
    RACK_NO3                CHAR,                            -- 016 ���b�NNo�R
    HHT_UPDATE_DAY          DATE "yyyy/mm/dd hh24:mi:ss",    -- �X�V����
    INVENT_HHT_IF_ID        "xxinv_stc_invt_hht_s1.nextval", -- *** HHT�I��IF_ID
    CREATED_BY              CONSTANT "-1",                   -- *** �쐬��
    CREATION_DATE           SYSDATE,                         -- *** �쐬��
    LAST_UPDATED_BY         CONSTANT "-1",                   -- *** �ŏI�X�V��
    LAST_UPDATE_DATE        SYSDATE,                         -- *** �ŏI�X�V��
    LAST_UPDATE_LOGIN       CONSTANT "-1",                   -- *** �ŏI�X�V���O�C��
    REQUEST_ID              CONSTANT "-1",                   -- *** �v��ID
    PROGRAM_APPLICATION_ID  CONSTANT "-1",                   -- *** �ݶ��ĥ��۸��ѥ���ع����ID
    PROGRAM_ID              CONSTANT "-1",                   -- *** �ݶ��ĥ��۸���ID
    PROGRAM_UPDATE_DATE     SYSDATE                          -- *** ��۸��эX�V��
  )
