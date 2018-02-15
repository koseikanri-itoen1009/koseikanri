/************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * View Name       : XXCFF_FA_UPLOAD_V
 * Description     : 固定資産アップロードビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2017/08/07    1.0   S.Niki           E_本稼動_14502対応（新規作成）
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCFF_FA_UPLOAD_V(
 COLUMN_DESC                -- 項目名称
,BYTE_COUNT                 -- バイト数
,BYTE_COUNT_DECIMAL         -- バイト数_小数点以下
,PAYMENT_MATCH_FLAG_NAME    -- 必須フラグ
,ITEM_ATTRIBUTE             -- 項目属性
,ENABLED_FLAG               -- 有効フラグ
,START_DATE_ACTIVE          -- 開始日
,END_DATE_ACTIVE            -- 終了日
,CODE                       -- コード
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
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.COLUMN_DESC              IS '項目名称';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.BYTE_COUNT               IS 'バイト数';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.BYTE_COUNT_DECIMAL       IS 'バイト数_小数点以下';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.PAYMENT_MATCH_FLAG_NAME  IS '必須フラグ';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.ITEM_ATTRIBUTE           IS '項目属性';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.ENABLED_FLAG             IS '有効フラグ';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.START_DATE_ACTIVE        IS '開始日';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.END_DATE_ACTIVE          IS '終了日';
COMMENT ON COLUMN XXCFF_FA_UPLOAD_V.CODE                     IS 'コード';
COMMENT ON TABLE XXCFF_FA_UPLOAD_V                           IS '固定資産アップロードビュー';
