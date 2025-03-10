/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
 *
 * View Name       : XXCMN_LOT_EACH_ITEM_V
 * Description     : ロット別品目情報View
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   R.Tomoyose       新規作成
 *  2008-05-20    1.1   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_Vをやめ
 *                                       必要なテーブルのみの結合とする。
 *  2008-06-30    1.2   Y.Ishikawa       カテゴリ取得部分でGROUP BYの利用をやめる
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW XXCMN_LOT_EACH_ITEM_V(
  ITEM_ID,
  LOT_ID,
  START_DATE_ACTIVE,
  END_DATE_ACTIVE,
  ITEM_CODE,
  ITEM_UM,
  LOT_CTL,
  ITEM_ATTRIBUTE1,
  ITEM_ATTRIBUTE2,
  ITEM_ATTRIBUTE3,
  ITEM_ATTRIBUTE4,
  ITEM_ATTRIBUTE5,
  ITEM_ATTRIBUTE6,
  ITEM_ATTRIBUTE7,
  ITEM_ATTRIBUTE8,
  ITEM_ATTRIBUTE9,
  ITEM_ATTRIBUTE10,
  ITEM_ATTRIBUTE11,
  ITEM_ATTRIBUTE12,
  ITEM_ATTRIBUTE13,
  ITEM_ATTRIBUTE14,
  ITEM_ATTRIBUTE15,
  ITEM_ATTRIBUTE16,
  ITEM_ATTRIBUTE17,
  ITEM_ATTRIBUTE18,
  ITEM_ATTRIBUTE19,
  ITEM_ATTRIBUTE20,
  ITEM_ATTRIBUTE21,
  ITEM_ATTRIBUTE22,
  ITEM_ATTRIBUTE23,
  ITEM_ATTRIBUTE24,
  ITEM_ATTRIBUTE25,
  ITEM_ATTRIBUTE26,
  ITEM_ATTRIBUTE27,
  ITEM_ATTRIBUTE28,
  ITEM_ATTRIBUTE29,
  ITEM_ATTRIBUTE30,
  ITEM_DIV,
  PROD_DIV,
  CROWD_CODE,
  ACNT_CROWD_CODE,
  ITEM_NAME,
  ITEM_SHORT_NAME,
  ITEM_NAME_ALT,
  PARENT_ITEM_ID,
  OBSOLETE_CLASS,
  OBSOLETE_DATE,
  MODEL_TYPE,
  PRODUCT_CLASS,
  PRODUCT_TYPE,
  EXPIRATION_DAY,
  DELIVERY_LEAD_TIME,
  WHSE_COUNTY_CODE,
  STANDARD_YIELD,
  LOT_NO,
  LOT_ATTRIBUTE1,
  LOT_ATTRIBUTE2,
  LOT_ATTRIBUTE3,
  LOT_ATTRIBUTE4,
  LOT_ATTRIBUTE5,
  LOT_ATTRIBUTE6,
  LOT_ATTRIBUTE7,
  LOT_ATTRIBUTE8,
  LOT_ATTRIBUTE9,
  LOT_ATTRIBUTE10,
  LOT_ATTRIBUTE11,
  LOT_ATTRIBUTE12,
  LOT_ATTRIBUTE13,
  LOT_ATTRIBUTE14,
  LOT_ATTRIBUTE15,
  LOT_ATTRIBUTE16,
  LOT_ATTRIBUTE17,
  LOT_ATTRIBUTE18,
  LOT_ATTRIBUTE19,
  LOT_ATTRIBUTE20,
  LOT_ATTRIBUTE21,
  LOT_ATTRIBUTE22,
  LOT_ATTRIBUTE23,
  LOT_ATTRIBUTE24,
  LOT_ATTRIBUTE25,
  LOT_ATTRIBUTE26,
  LOT_ATTRIBUTE27,
  LOT_ATTRIBUTE28,
  LOT_ATTRIBUTE29,
  LOT_ATTRIBUTE30,
  TRANS_QTY,
  ACTUAL_UNIT_PRICE
)
AS
SELECT  XIMV.ITEM_ID                        ITEM_ID,
        ILM.LOT_ID                          LOT_ID,
        XIMV.START_DATE_ACTIVE              START_DATE_ACTIVE,
        XIMV.END_DATE_ACTIVE                END_DATE_ACTIVE,
        XIMV.ITEM_NO                        ITEM_CODE,
        XIMV.ITEM_UM                        ITEM_UM,
        XIMV.LOT_CTL                        LOT_CTL,
        XIMV.OLD_CROWD_CODE                 ITEM_ATTRIBUTE1,
        XIMV.NEW_CROWD_CODE                 ITEM_ATTRIBUTE2,
        XIMV.CROWD_START_DATE               ITEM_ATTRIBUTE3,
        XIMV.OLD_PRICE                      ITEM_ATTRIBUTE4,
        XIMV.NEW_PRICE                      ITEM_ATTRIBUTE5,
        XIMV.PRICE_START_DATE               ITEM_ATTRIBUTE6,
        XIMV.OLD_OPERATING_COST             ITEM_ATTRIBUTE7,
        XIMV.NEW_OPERATING_COST             ITEM_ATTRIBUTE8,
        XIMV.OPERATING_START_DATE           ITEM_ATTRIBUTE9,
        XIMV.PALETTE_STEP_QTY               ITEM_ATTRIBUTE10,
        XIMV.NUM_OF_CASES                   ITEM_ATTRIBUTE11,
        XIMV.NET                            ITEM_ATTRIBUTE12,
        XIMV.SELL_START_DATE                ITEM_ATTRIBUTE13,
        XIMV.INSPECT_LOT                    ITEM_ATTRIBUTE14,
        XIMV.COST_MANAGE_CODE               ITEM_ATTRIBUTE15,
        NULL                                ITEM_ATTRIBUTE16,
        XIMV.FREQUENT_QTY                   ITEM_ATTRIBUTE17,
        XIMV.DELIVERY_QTY                   ITEM_ATTRIBUTE18,
        XIMV.MAX_PALETTE_STEPS              ITEM_ATTRIBUTE19,
        XIMV.UNIT_PRICE_CALC_CODE           ITEM_ATTRIBUTE20,
        XIMV.JAN_CODE                       ITEM_ATTRIBUTE21,
        XIMV.ITF_CODE                       ITEM_ATTRIBUTE22,
        XIMV.TEST_CODE                      ITEM_ATTRIBUTE23,
        XIMV.CONV_UNIT                      ITEM_ATTRIBUTE24,
        XIMV.UNIT                           ITEM_ATTRIBUTE25,
        XIMV.SALES_DIV                      ITEM_ATTRIBUTE26,
        XIMV.JUDGE_TIMES                    ITEM_ATTRIBUTE27,
        XIMV.DESTINATION_DIV                ITEM_ATTRIBUTE28,
        XIMV.ORDER_JUDGE_TIMES              ITEM_ATTRIBUTE29,
        XIMV.RECEPT_DATE                    ITEM_ATTRIBUTE30,
        MCB_A2.SEGMENT1                     ITEM_DIV,
        MCB_A1.SEGMENT1                     PROD_DIV,
        MCB_A3.SEGMENT1                     CROWD_CODE,
        MCB_A4.SEGMENT1                     ACNT_CROWD_CODE,
        XIMV.ITEM_NAME                      ITEM_NAME,
        XIMV.ITEM_SHORT_NAME                ITEM_SHORT_NAME,
        XIMV.ITEM_NAME_ALT                  ITEM_NAME_ALT,
        XIMV.PARENT_ITEM_ID                 PARENT_ITEM_ID,
        XIMV.OBSOLETE_CLASS                 OBSOLETE_CLASS,
        XIMV.OBSOLETE_DATE                  OBSOLETE_DATE,
        XIMV.MODEL_TYPE                     MODEL_TYPE,
        XIMV.PRODUCT_CLASS                  PRODUCT_CLASS,
        XIMV.PRODUCT_TYPE                   PRODUCT_TYPE,
        XIMV.EXPIRATION_DAY                 EXPIRATION_DAY,
        XIMV.DELIVERY_LEAD_TIME             DELIVERY_LEAD_TIME,
        XIMV.WHSE_COUNTY_CODE               WHSE_COUNTY_CODE,
        XIMV.STANDARD_YIELD                 STANDARD_YIELD,
        ILM.LOT_NO                          LOT_NO,
        ILM.ATTRIBUTE1                      LOT_ATTRIBUTE1,
        ILM.ATTRIBUTE2                      LOT_ATTRIBUTE2,
        ILM.ATTRIBUTE3                      LOT_ATTRIBUTE3,
        ILM.ATTRIBUTE4                      LOT_ATTRIBUTE4,
        ILM.ATTRIBUTE5                      LOT_ATTRIBUTE5,
        ILM.ATTRIBUTE6                      LOT_ATTRIBUTE6,
        ILM.ATTRIBUTE7                      LOT_ATTRIBUTE7,
        ILM.ATTRIBUTE8                      LOT_ATTRIBUTE8,
        ILM.ATTRIBUTE9                      LOT_ATTRIBUTE9,
        ILM.ATTRIBUTE10                     LOT_ATTRIBUTE10,
        ILM.ATTRIBUTE11                     LOT_ATTRIBUTE11,
        ILM.ATTRIBUTE12                     LOT_ATTRIBUTE12,
        ILM.ATTRIBUTE13                     LOT_ATTRIBUTE13,
        ILM.ATTRIBUTE14                     LOT_ATTRIBUTE14,
        ILM.ATTRIBUTE15                     LOT_ATTRIBUTE15,
        ILM.ATTRIBUTE16                     LOT_ATTRIBUTE16,
        ILM.ATTRIBUTE17                     LOT_ATTRIBUTE17,
        ILM.ATTRIBUTE18                     LOT_ATTRIBUTE18,
        ILM.ATTRIBUTE19                     LOT_ATTRIBUTE19,
        ILM.ATTRIBUTE20                     LOT_ATTRIBUTE20,
        ILM.ATTRIBUTE21                     LOT_ATTRIBUTE21,
        ILM.ATTRIBUTE22                     LOT_ATTRIBUTE22,
        ILM.ATTRIBUTE23                     LOT_ATTRIBUTE23,
        ILM.ATTRIBUTE24                     LOT_ATTRIBUTE24,
        ILM.ATTRIBUTE25                     LOT_ATTRIBUTE25,
        ILM.ATTRIBUTE26                     LOT_ATTRIBUTE26,
        ILM.ATTRIBUTE27                     LOT_ATTRIBUTE27,
        ILM.ATTRIBUTE28                     LOT_ATTRIBUTE28,
        ILM.ATTRIBUTE29                     LOT_ATTRIBUTE29,
        ILM.ATTRIBUTE30                     LOT_ATTRIBUTE30,
        XLC.TRANS_QTY                       TRANS_QTY,
        XLC.UNIT_PLOCE                      ACTUAL_UNIT_PRICE
FROM  XXCMN_ITEM_MST2_V         XIMV,
      IC_LOTS_MST               ILM,
      XXCMN_LOT_COST            XLC,
      GMI_ITEM_CATEGORIES       GIC_A1,
      MTL_CATEGORIES_B          MCB_A1,
      MTL_CATEGORY_SETS_TL      MCST_A1,
      GMI_ITEM_CATEGORIES       GIC_A2,
      MTL_CATEGORIES_B          MCB_A2,
      MTL_CATEGORY_SETS_TL      MCST_A2,
      GMI_ITEM_CATEGORIES       GIC_A3,
      MTL_CATEGORIES_B          MCB_A3,
      MTL_CATEGORY_SETS_TL      MCST_A3,
      GMI_ITEM_CATEGORIES       GIC_A4,
      MTL_CATEGORIES_B          MCB_A4,
      MTL_CATEGORY_SETS_TL      MCST_A4
  -- 商品区分カテゴリ取得情報
  WHERE GIC_A1.CATEGORY_SET_ID  = MCST_A1.CATEGORY_SET_ID
  AND GIC_A1.CATEGORY_ID        = MCB_A1.CATEGORY_ID
  AND MCST_A1.LANGUAGE          = 'JA'
  AND MCST_A1.SOURCE_LANG       = 'JA'
  AND MCST_A1.CATEGORY_SET_NAME = '商品区分'
  AND XIMV.ITEM_ID              = GIC_A1.ITEM_ID
  -- 商品区分カテゴリ取得情報
  AND GIC_A2.CATEGORY_SET_ID    = MCST_A2.CATEGORY_SET_ID
  AND GIC_A2.CATEGORY_ID        = MCB_A2.CATEGORY_ID
  AND MCST_A2.LANGUAGE          = 'JA'
  AND MCST_A2.SOURCE_LANG       = 'JA'
  AND MCST_A2.CATEGORY_SET_NAME = '品目区分'
  AND XIMV.ITEM_ID              = GIC_A2.ITEM_ID
  -- 郡取得情報
  AND GIC_A3.CATEGORY_SET_ID    = MCST_A3.CATEGORY_SET_ID
  AND GIC_A3.CATEGORY_ID        = MCB_A3.CATEGORY_ID
  AND MCST_A3.LANGUAGE          = 'JA'
  AND MCST_A3.SOURCE_LANG       = 'JA'
  AND MCST_A3.CATEGORY_SET_NAME = '群コード'
  AND XIMV.ITEM_ID              = GIC_A3.ITEM_ID
  -- 経理郡取得情報
  AND GIC_A4.CATEGORY_SET_ID    = MCST_A4.CATEGORY_SET_ID
  AND GIC_A4.CATEGORY_ID        = MCB_A4.CATEGORY_ID
  AND MCST_A4.LANGUAGE          = 'JA'
  AND MCST_A4.SOURCE_LANG       = 'JA'
  AND MCST_A4.CATEGORY_SET_NAME = '経理部用群コード'
  AND XIMV.ITEM_ID              = GIC_A4.ITEM_ID
  AND XIMV.ITEM_ID  = ILM.ITEM_ID(+)
  AND ILM.ITEM_ID   = XLC.ITEM_ID(+)
  AND ILM.LOT_ID    = XLC.LOT_ID(+)
/
COMMENT ON TABLE XXCMN_LOT_EACH_ITEM_V IS 'ロット別品目情報View'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ID            IS '品目ＩＤ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ID             IS 'ロットＩＤ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.START_DATE_ACTIVE  IS '適用開始日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.END_DATE_ACTIVE    IS '適用終了日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_CODE          IS '品目コード'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_UM            IS '単位'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_CTL            IS 'ロット'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE1    IS '旧・群ｺｰﾄﾞ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE2    IS '新・群ｺｰﾄﾞ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE3    IS '群ｺｰﾄﾞ適用開始日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE4    IS '旧・定価'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE5    IS '新・定価'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE6    IS '定価適用開始日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE7    IS '旧・営業原価'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE8    IS '新・営業原価'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE9    IS '営業原価適用開始日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE10   IS '率区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE11   IS 'ケース入数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE12   IS 'NET'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE13   IS '発売（製造）開始日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE14   IS '検査L/T'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE15   IS '原価管理区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE16   IS '代表取引先'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE17   IS '代表入数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE18   IS '配数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE19   IS 'パレット当り最大段数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE20   IS '仕入単価導出日タイプ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE21   IS 'JANｺｰﾄﾞ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE22   IS '出荷区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE23   IS '試験有無区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE24   IS '入出庫換算単位'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE25   IS '重量／体積'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE26   IS '売上対象区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE27   IS '判定回数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE28   IS '仕向区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE29   IS '発注可能判定回数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_ATTRIBUTE30   IS 'マスタ受信日時'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_DIV           IS '品目区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.PROD_DIV           IS '商品区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.CROWD_CODE         IS '群コード'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ACNT_CROWD_CODE    IS '経理群コード'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_NAME          IS '品目名称'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_SHORT_NAME    IS '略称'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ITEM_NAME_ALT      IS 'カナ名'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.PARENT_ITEM_ID     IS '親品目ID'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.OBSOLETE_CLASS     IS '廃止区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.OBSOLETE_DATE      IS '廃止日（製造中止日）'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.MODEL_TYPE         IS '型種別'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.PRODUCT_CLASS      IS '商品分類'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.PRODUCT_TYPE       IS '商品種別'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.EXPIRATION_DAY     IS '賞味期間'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.DELIVERY_LEAD_TIME IS '納入期間'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.WHSE_COUNTY_CODE   IS '工場群コード'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.STANDARD_YIELD     IS '標準歩留'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_NO             IS 'ロットNo'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE1     IS '製造年月日'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE2     IS '固有記号'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE3     IS '賞味期限'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE4     IS '納入日（初回）'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE5     IS '納入日（最終）'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE6     IS '在庫入数'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE7     IS '在庫単価'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE8     IS '取引先'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE9     IS '仕入形態'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE10    IS '茶期区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE11    IS '年度'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE12    IS '産地'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE13    IS 'タイプ'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE14    IS 'ランク１'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE15    IS 'ランク２'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE16    IS '生産伝票区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE17    IS 'ライン��'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE18    IS '摘要'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE19    IS 'ランク３'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE20    IS '原料製造工場'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE21    IS '原料製造元ロット番号'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE22    IS '検査依頼No'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE23    IS 'ロットステータス'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE24    IS '作成区分'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE25    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE26    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE27    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE28    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE29    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.LOT_ATTRIBUTE30    IS ' '
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.TRANS_QTY          IS '取引数量'
/
COMMENT ON COLUMN XXCMN_LOT_EACH_ITEM_V.ACTUAL_UNIT_PRICE  IS '実際単価'
/
