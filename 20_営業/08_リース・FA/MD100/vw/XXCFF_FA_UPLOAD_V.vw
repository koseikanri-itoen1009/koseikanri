/************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * View Name       : XXCFF_FA_UPLOAD_V
 * Description     : �Œ莑�Y�A�b�v���[�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2017/08/07    1.0   S.Niki           E_�{�ғ�_14502�Ή��i�V�K�쐬�j
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCFF_FA_UPLOAD_V(
 COLUMN_DESC                -- ���ږ���
,BYTE_COUNT                 -- �o�C�g��
,BYTE_COUNT_DECIMAL         -- �o�C�g��_�����_�ȉ�
,PAYMENT_MATCH_FLAG_NAME    -- �K�{�t���O
,ITEM_ATTRIBUTE             -- ���ڑ���
,ENABLED_FLAG               -- �L���t���O
,START_DATE_ACTIVE          -- �J�n��
,END_DATE_ACTIVE            -- �I����
,CODE                       -- �R�[�h
)
AS
SELECT FLV.DESCRIPTION       AS COLUMN_DESC
      ,FLV.ATTRIBUTE1        AS BYTE_COUNT
      ,FLV.ATTRIBUTE2        AS BYTE_COUNT_DECIMAL
      ,FLV.ATTRIBUTE3        AS PAYMENT_MATCH_FLAG_NAME
      ,FLV.ATTRIBUTE4        AS ITEM_ATTRIBUTE
      ,FLV.ENABLED_FLAG      AS ENABLED_FLAG
      ,FLV.START_DATE_ACTIVE AS START_DATE_ACTIVE
      ,FLV.END_DATE_ACTIVE   AS END_DATE_ACTIVE
      ,FLV.MEANING           AS CODE
FROM   FND_LOOKUP_VALUES_VL FLV
WHERE  FLV.LOOKUP_TYPE       = 'XXCFF1_FA_UPLOAD'
;
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.COLUMN_DESC              IS '���ږ���';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.BYTE_COUNT               IS '�o�C�g��';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.BYTE_COUNT_DECIMAL       IS '�o�C�g��_�����_�ȉ�';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.PAYMENT_MATCH_FLAG_NAME  IS '�K�{�t���O';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.ITEM_ATTRIBUTE           IS '���ڑ���';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.ENABLED_FLAG             IS '�L���t���O';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.START_DATE_ACTIVE        IS '�J�n��';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.END_DATE_ACTIVE          IS '�I����';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.CODE                     IS '�R�[�h';
COMMENT ON TABLE XXCFF_FA_UPLOAD_V                           IS '�Œ莑�Y�A�b�v���[�h�r���[';
