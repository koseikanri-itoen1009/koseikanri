-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2010. All rights reserved.
-- 
-- Control file  : XXCSM002A16D.ctl
-- Description   : ���n-EBS�C���^�[�t�F�[�X�F(IN)���i�v��̔����яW�v�iSQL-LOADER-�̔����яW�v�j
-- MD.050        : MD050_CSM_002_A01_���i�v��p�ߔN�x�̔����яW�v.doc
-- MD.070        : �Ȃ�
-- Version       : 1.0
--
-- Target Table  : XXCSM_WK_ITEM_PLAN_RESULT
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2010/02/03    1.0     T.Tsukino        �V�K�쐬
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
INFILE * -- *sql*loader�����s�����f�B���N�g������̑��΃p�X�Ńf�B���N�g�����w��\�B
REPLACE
INTO TABLE XXCSM_WK_ITEM_PLAN_RESULT
FIELDS TERMINATED BY ","
  (
   SUBJECT_YEAR               INTEGER  EXTERNAL(4),              -- �Ώ۔N�x
   MONTH_NO                   INTEGER  EXTERNAL(2),              -- ��
   YEAR_MONTH                 INTEGER  EXTERNAL(6),              -- �N��
   LOCATION_CD                CHAR(4),                           -- ���_�R�[�h
   ITEM_NO                    CHAR(32),                          -- ���i�R�[�h
   ITEM_GROUP_NO              CHAR(4),                           -- ���i�Q�R�[�h
   AMOUNT                     INTEGER  EXTERNAL(17),             -- ����
   SALES_BUDGET               INTEGER  EXTERNAL(15),             -- ������z
   AMOUNT_GROSS_MARGIN        INTEGER  EXTERNAL(15),             -- �e���v
   DISCRETE_COST              INTEGER  EXTERNAL(1),              -- �c�ƌ���
   CREATED_BY                 CONSTANT "-1",                     -- �쐬��
   CREATION_DATE              SYSDATE,                           -- �쐬��
   LAST_UPDATED_BY            CONSTANT "-1",                     -- �ŏI�X�V��
   LAST_UPDATE_DATE           SYSDATE,                           -- �ŏI�X�V��
   LAST_UPDATE_LOGIN          CONSTANT "-1"                      -- �ŏI�X�V���O�C��
  )