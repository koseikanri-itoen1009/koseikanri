/*************************************************************************
 * 
 * View  Name      : XXSKZ_棚卸結果_基本_V
 * Description     : XXSKZ_棚卸結果_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_棚卸結果_基本_V
(
 報告部署コード
,報告部署名
,棚卸年月
,棚卸日
,棚卸倉庫コード
,棚卸倉庫名
,保管場所コード
,保管場所名
,棚卸連番
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,製造日
,賞味期限
,固有記号
,棚卸ケース数
,入数
,棚卸バラ
,ロケーション
,ラックNO１
,ラックNO２
,ラックNO３
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン)
AS
SELECT  XSIR.report_post_code               --報告部署コード
       ,XLV.location_name                   --報告部署名
       ,TO_CHAR( XSIR.invent_date, 'YYYYMM' )
                                            --棚卸年月
       ,XSIR.invent_date                    --棚卸日
       ,XSIR.invent_whse_code               --棚卸倉庫コード
       ,IWM.whse_name                       --棚卸倉庫名
       ,XILV.segment1        location_code  --保管場所コード
       ,XILV.description     location_name  --保管場所名
       ,XSIR.invent_seq                     --棚卸連番
       ,XPCV.prod_class_code                --商品区分
       ,XPCV.prod_class_name                --商品区分名
       ,XICV.item_class_code                --品目区分
       ,XICV.item_class_name                --品目区分名
       ,XCCV.crowd_code                     --群コード
       ,XSIR.item_code                      --品目コード
       ,XIMV.item_name                      --品目名
       ,XIMV.item_short_name                --品目略称
       ,XSIR.lot_no                         --ロットNo
       ,XSIR.maker_date                     --製造日
       ,XSIR.limit_date                     --賞味期限
       ,XSIR.proper_mark                    --固有記号
       ,XSIR.case_amt                       --棚卸ケース数
       ,XSIR.content                        --入数
       ,XSIR.loose_amt                      --棚卸バラ
       ,XSIR.location                       --ロケーション
       ,XSIR.rack_no1                       --ラックNo１
       ,XSIR.rack_no2                       --ラックNo２
       ,XSIR.rack_no3                       --ラックNo３
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XSIR.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XSIR.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM    xxinv_stc_inventory_result  XSIR    --棚卸結果アドオン
       ,xxskz_locations2_v          XLV     --事業所（報告部署）名取得
       ,ic_whse_mst                 IWM     --倉庫名取得
       ,xxskz_item_locations_v      XILV    --保管場所取得用
       ,xxskz_item_mst2_v           XIMV    --品目取得
       ,xxskz_prod_class_v          XPCV    --商品区分取得
       ,xxskz_item_class_v          XICV    --品目区分取得
       ,xxskz_crowd_code_v          XCCV    --群コード取得
       ,fnd_user                    FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                    FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                    FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                  FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
--事業所（報告部署）名取得結合
      XLV.location_code(+) = XSIR.report_post_code
  AND XLV.start_date_active(+) <= XSIR.invent_date
  AND XLV.end_date_active(+)   >= XSIR.invent_date
--倉庫名取得結合
  AND XSIR.invent_whse_code = IWM.whse_code(+)
  --保管場所情報取得結合
  AND XILV.allow_pickup_flag(+) = '1'                  --出荷引当対象フラグ
  AND XSIR.invent_whse_code     = XILV.whse_code(+)
--品目取得結合
  AND XIMV.item_id(+) = XSIR.item_id
  AND XIMV.start_date_active(+) <= XSIR.invent_date
  AND XIMV.end_date_active(+)   >= XSIR.invent_date
--商品区分取得結合
  AND XPCV.item_id(+) = XSIR.item_id
--品目区分取得結合
  AND XICV.item_id(+) = XSIR.item_id
--群コード取得結合
  AND XCCV.item_id(+) = XSIR.item_id
--ユーザーマスタ(CREATED_BY名称取得用結合)
  AND  FU_CB.user_id(+)  = XSIR.created_by
--ユーザーマスタ(LAST_UPDATE_BY名称取得用結合)
  AND  FU_LU.user_id(+)  = XSIR.last_updated_by
--ログインマスタ・ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用結合)
  AND  FL_LL.login_id(+) = XSIR.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_棚卸結果_基本_V IS 'XXSKZ_棚卸結果 (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.報告部署コード   IS '報告部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.報告部署名       IS '報告部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸年月         IS '棚卸年月'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸日           IS '棚卸日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸倉庫コード   IS '棚卸倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸倉庫名       IS '棚卸倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.保管場所コード   IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.保管場所名       IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸連番         IS '棚卸連番'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.ロットNO         IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.製造日           IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.賞味期限         IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.固有記号         IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸ケース数     IS '棚卸ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.入数             IS '入数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.棚卸バラ         IS '棚卸バラ'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.ロケーション     IS 'ロケーション'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.ラックNO１       IS 'ラックNo１'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.ラックNO２       IS 'ラックNo２'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.ラックNO３       IS 'ラックNo３'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果_基本_V.最終更新ログイン IS '最終更新ログイン'
/
