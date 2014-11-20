/*************************************************************************
 * 
 * View  Name      : XXSKZ_トレサビリティ_基本_V
 * Description     : XXSKZ_トレサビリティ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_トレサビリティ_基本_V
(
要求ID
,区分
,区分名
,レベル番号
,親品目_商品区分
,親品目_商品区分名
,親品目_品目区分
,親品目_品目区分名
,親品目_群コード
,親品目コード
,親品目名
,親品目略称
,親ロットNO
,親取引数量
,子品目_商品区分
,子品目_商品区分名
,子品目_品目区分
,子品目_品目区分名
,子品目_群コード
,子品目コード
,子品目名
,子品目略称
,子ロットNO
,子取引数量
,製造バッチ番号
,製造日
,倉庫コード
,倉庫名
,ライン番号
,投入日
,投入バッチ番号
,受入日
,受入番号
,発注番号
,仕入先コード
,仕入先名
,斡旋業者
,製造年月日
,固有記号
,賞味期限
,初回納入日
,最終納入日
,在庫入数
,茶期区分
,茶期区分名
,年度
,産地
,タイプ
,タイプ名
,ランク１
,ランク２
,ランク３
,生産伝票区分
,生産伝票区分名
,摘要
,検査依頼NO
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XLT.request_id                      --要求ID
       ,XLT.division                        --区分
       ,CASE XLT.division
            WHEN '0' THEN 'ロットトレース（原料へ）'
            WHEN '1' THEN 'トレースバック（製品へ）'
        END                                 --区分名
       ,XLT.level_num                       --レベル番号
       ,XPCV_OYA.prod_class_code            --親品目_商品区分
       ,XPCV_OYA.prod_class_name            --親品目_商品区分名
       ,XICV_OYA.item_class_code            --親品目_品目区分
       ,XICV_OYA.item_class_name            --親品目_品目区分名
       ,XCCV_OYA.crowd_code                 --親品目_群コード
       ,XLT.item_code                       --親品目コード
       ,XLT.item_name                       --親品目名
       ,XIMV_OYA.item_short_name            --親品目略称
       ,XLT.lot_num                         --親ロットNo
       ,XLT.trans_qty                       --親取引数量
       ,XPCV_KO.prod_class_code             --子品目_商品区分
       ,XPCV_KO.prod_class_name             --子品目_商品区分名
       ,XICV_KO.item_class_code             --子品目_品目区分
       ,XICV_KO.item_class_name             --子品目_品目区分名
       ,XCCV_KO.crowd_code                  --子品目_群コード
       ,XLT.trace_item_code                 --子品目コード
       ,XLT.trace_item_name                 --子品目名
       ,XIMV_KO.item_short_name             --子品目略称
       ,XLT.trace_lot_num                   --子ロットNo
       ,XLT.trace_trans_qty                 --子取引数量
       ,XLT.batch_num                       --製造バッチ番号
       ,XLT.batch_date                      --製造日
       ,XLT.whse_code                       --倉庫コード
       ,IWM.whse_name                       --倉庫名
       ,XLT.line_num                        --ライン番号
       ,XLT.turn_date                       --投入日
       ,XLT.turn_batch_num                  --投入バッチ番号
       ,XLT.receipt_date                    --受入日
       ,XLT.receipt_num                     --受入番号
       ,XLT.order_num                       --発注番号
       ,XLT.supp_code                       --仕入先コード
       ,XLT.supp_name                       --仕入先名
       ,XLT.trader_name                     --斡旋業者
       ,XLT.lot_date                        --製造年月日
       ,XLT.lot_sign                        --固有記号
       ,XLT.best_bfr_date                   --賞味期限
       ,XLT.dlv_date_first                  --初回納入日
       ,XLT.dlv_date_last                   --最終納入日
       ,XLT.stock_ins_amount                --在庫入数
       ,XLT.tea_period_dev                  --茶期区分
       ,FLV_CHA.meaning                     --茶期区分名
       ,XLT.product_year                    --年度
       ,XLT.product_home                    --産地
       ,XLT.product_type                    --タイプ
       ,FLV_TYP.meaning                     --タイプ名
       ,XLT.product_ranc_1                  --ランク１
       ,XLT.product_ranc_2                  --ランク２
       ,XLT.product_ranc_3                  --ランク３
       ,XLT.product_slip_dev                --生産伝票区分
       ,FLV_DEN.meaning                     --生産伝票区分名
       ,XLT.description                     --摘要
       ,XLT.inspect_req                     --検査依頼No
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XLT.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XLT.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM    xxcmn_lot_trace         XLT         --ロットトレース
       ,xxskz_item_mst2_v       XIMV_OYA    --親品目名取得
       ,xxskz_prod_class_v      XPCV_OYA    --親商品区分取得
       ,xxskz_item_class_v      XICV_OYA    --親品目区分取得
       ,xxskz_crowd_code_v      XCCV_OYA    --親群コード取得
       ,xxskz_item_mst2_v       XIMV_KO     --子品目名取得
       ,xxskz_prod_class_v      XPCV_KO     --子商品区分取得
       ,xxskz_item_class_v      XICV_KO     --子品目区分取得
       ,xxskz_crowd_code_v      XCCV_KO     --子群コード取得
       ,ic_whse_mst             IWM         --倉庫名取得
       ,fnd_lookup_values       FLV_CHA     --茶期区分名取得
       ,fnd_lookup_values       FLV_TYP     --タイプ名取得
       ,fnd_lookup_values       FLV_DEN     --生産伝票区分名取
       ,fnd_user                FU_CB       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
--親品目名取得結合
      XIMV_OYA.item_no(+) = XLT.item_code
  AND XIMV_OYA.start_date_active(+) <= NVL(XLT.batch_date,XLT.receipt_date)
  AND XIMV_OYA.end_date_active(+)   >= NVL(XLT.batch_date,XLT.receipt_date)
--親商品区分取得結合
  AND XPCV_OYA.item_id(+) = XIMV_OYA.item_id
--親品目区分取得結合
  AND XICV_OYA.item_id(+) = XIMV_OYA.item_id
--親群コード取得結合
  AND XCCV_OYA.item_id(+) = XIMV_OYA.item_id
--子品目名取得結合
  AND XIMV_KO.item_no(+) = XLT.trace_item_code
  AND XIMV_KO.start_date_active(+) <= NVL(XLT.batch_date,XLT.receipt_date)
  AND XIMV_KO.end_date_active(+)   >= NVL(XLT.batch_date,XLT.receipt_date)
--子商品区分取得結合
  AND XPCV_KO.item_id(+) = XIMV_KO.item_id
--子品目区分取得結合
  AND XICV_KO.item_id(+) = XIMV_KO.item_id
--子群コード取得結合
  AND XCCV_KO.item_id(+) = XIMV_KO.item_id
--倉庫名取得結合
  AND XLT.whse_code = IWM.whse_code(+)
--茶期区分名取得結合
  AND FLV_CHA.language(+) = 'JA'
  AND FLV_CHA.lookup_type(+) = 'XXCMN_L06'
  AND FLV_CHA.lookup_code(+) = XLT.tea_period_dev
--タイプ名取得結合
  AND FLV_TYP.language(+) = 'JA'
  AND FLV_TYP.lookup_type(+) = 'XXCMN_L08'
  AND FLV_TYP.lookup_code(+) = XLT.product_type
--生産伝票区分名取得結合
  AND FLV_DEN.language(+) = 'JA'
  AND FLV_DEN.lookup_type(+) = 'XXCMN_L03'
  AND FLV_DEN.lookup_code(+) = XLT.product_slip_dev
--ユーザーマスタ(CREATED_BY名称取得用結合)
  AND  FU_CB.user_id(+)  = XLT.created_by
--ユーザーマスタ(LAST_UPDATE_BY名称取得用結合)
  AND  FU_LU.user_id(+)  = XLT.last_updated_by
--ログインマスタ・ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用結合)
  AND  FL_LL.login_id(+) = XLT.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_トレサビリティ_基本_V IS 'XXSKZ_トレサビリティ (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.要求ID               IS '要求ID'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.区分                 IS '区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.区分名               IS '区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.レベル番号           IS 'レベル番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目_商品区分      IS '親品目_商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目_商品区分名    IS '親品目_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目_品目区分      IS '親品目_品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目_品目区分名    IS '親品目_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目_群コード      IS '親品目_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目コード         IS '親品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目名             IS '親品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親品目略称           IS '親品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親ロットNO           IS '親ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.親取引数量           IS '親取引数量'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目_商品区分      IS '子品目_商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目_商品区分名    IS '子品目_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目_品目区分      IS '子品目_品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目_品目区分名    IS '子品目_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目_群コード      IS '子品目_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目コード         IS '子品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目名             IS '子品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子品目略称           IS '子品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子ロットNO           IS '子ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.子取引数量           IS '子取引数量'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.製造バッチ番号       IS '製造バッチ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.製造日               IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.倉庫コード           IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.倉庫名               IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.ライン番号           IS 'ライン番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.投入日               IS '投入日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.投入バッチ番号       IS '投入バッチ番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.受入日               IS '受入日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.受入番号             IS '受入番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.発注番号             IS '発注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.仕入先コード         IS '仕入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.仕入先名             IS '仕入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.斡旋業者             IS '斡旋業者'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.製造年月日           IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.固有記号             IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.賞味期限             IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.初回納入日           IS '初回納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.最終納入日           IS '最終納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.在庫入数             IS '在庫入数'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.茶期区分             IS '茶期区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.茶期区分名           IS '茶期区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.年度                 IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.産地                 IS '産地'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.タイプ               IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.タイプ名             IS 'タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.ランク１             IS 'ランク１'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.ランク２             IS 'ランク２'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.ランク３             IS 'ランク３'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.生産伝票区分         IS '生産伝票区分'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.生産伝票区分名       IS '生産伝票区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.摘要                 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.検査依頼NO           IS '検査依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.作成者               IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.作成日               IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.最終更新者           IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.最終更新日           IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_トレサビリティ_基本_V.最終更新ログイン     IS '最終更新ログイン'
/
