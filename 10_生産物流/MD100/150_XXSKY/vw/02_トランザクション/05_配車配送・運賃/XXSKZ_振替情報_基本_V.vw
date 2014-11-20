/*************************************************************************
 * 
 * View  Name      : XXSKZ_振替情報_基本_V
 * Description     : XXSKZ_振替情報_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_振替情報_基本_V
(
 対象年月
,営業ブロック
,営業ブロック名
,商品区分
,商品区分名
,管轄拠点
,管轄拠点名
,管轄拠点略称
,地区名
,振替数量
,振替金額
,還元金額
,運送費Ａ
,運送費Ｂ
,運送費Ｃ
,その他
,依頼NO
,配送日
,出庫元
,出庫元名
,配送先
,配送先名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,単価
,計算数量
,実際数量
,金額
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        TI.target_date                                  --対象年月
       ,TI.business_block                               --営業ブロック
       ,FLV01.meaning           business_block_name     --営業ブロック名
       ,TI.goods_classe                                 --商品区分
       ,FLV02.meaning           goods_classe_name       --商品区分名
       ,TI.jurisdicyional_hub                           --管轄拠点
       ,XCA2V.party_name        j_hub_name              --管轄拠点名
       ,XCA2V.party_short_name  j_hub_short_name        --管轄拠点略称
       ,TI.area_name                                    --地区名
       ,TI.transfe_qty                                  --振替数量
       ,TI.transfer_amount                              --振替金額
       ,TI.restore_amount                               --還元金額
       ,TI.shipping_expenses_a                          --運送費Ａ
       ,TI.shipping_expenses_b                          --運送費Ｂ
       ,TI.shipping_expenses_c                          --運送費Ｃ
       ,TI.etc_amount                                   --その他
       ,TI.request_no                                   --依頼NO
       ,TI.delivery_date                                --配送日
       ,TI.delivery_whs                                 --出庫元
       ,XILV.description                                --出庫元名
       ,TI.ship_to                                      --配送先
       ,XPS2V.party_site_name                           --配送先名
       ,XICV.item_class_code                            --品目区分
       ,XICV.item_class_name                            --品目区分名
       ,XCCV.crowd_code                                 --群コード
       ,TI.item_code                                    --品目コード
       ,XIM2V.item_name                                 --品目名
       ,XIM2V.item_short_name                           --品目略称
       ,TI.price                                        --単価
       ,TI.calc_qry                                     --計算数量
       ,TI.actual_qty                                   --実際数量
       ,TI.amount                                       --金額
       ,FU_CB.user_name         created_by_name         --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( TI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date           --作成日時
       ,FU_LU.user_name         last_updated_by_name    --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( TI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date        --更新日時
       ,FU_LL.user_name         last_update_login_name  --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  (
        SELECT 
             XTI.target_date                            --対象年月
            ,XTI.business_block                         --営業ブロック
            ,XTI.goods_classe                           --商品区分
            ,XTI.jurisdicyional_hub                     --管轄拠点
            ,XTI.area_name                              --地区名
            ,XTI.transfe_qty                            --振替数量
            ,XTI.transfer_amount                        --振替金額
            ,XTI.restore_amount                         --還元金額
            ,XTI.shipping_expenses_a                    --運送費Ａ
            ,XTI.shipping_expenses_b                    --運送費Ｂ
            ,XTI.shipping_expenses_c                    --運送費Ｃ
            ,XTI.etc_amount                             --その他
            ,XTFI.request_no                            --依頼NO
            ,XTFI.delivery_date                         --配送日
            ,XTFI.delivery_whs                          --出庫元
            ,XTFI.ship_to                               --配送先
            ,XTFI.item_code                             --品目コード
            ,XTFI.price                                 --単価
            ,XTFI.calc_qry                              --計算数量
            ,XTFI.actual_qty                            --実際数量
            ,XTFI.amount                                --金額
            ,XTFI.created_by
            ,XTFI.creation_date
            ,XTFI.last_updated_by
            ,XTFI.last_update_date
            ,XTFI.last_update_login
        FROM
             xxwip_transfer_inf         XTI             --振替情報アドオンインタフェース
            ,xxwip_transfer_fare_inf    XTFI            --振替運賃情報アドオンインタフェース
        WHERE
               XTFI.target_date         =  XTI.target_date
          AND  XTFI.goods_classe        =  XTI.goods_classe
          AND  XTFI.jurisdicyional_hub  =  XTI.jurisdicyional_hub
        )   TI                                          --振替情報・振替運賃情報
       ,xxskz_cust_accounts2_v          XCA2V           --SKYLINK用中間VIEW 拠点取得VIEW
       ,xxskz_item_locations_v          XILV            --SKYLINK用中間VIEW 出庫元取得VIEW
       ,xxskz_party_sites2_v            XPS2V           --SKYLINK用中間VIEW 配送先取得VIEW
       ,xxskz_item_class_v              XICV            --SKYLINK用中間VIEW 品目区分取得VIEW
       ,xxskz_crowd_code_v              XCCV            --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v               XIM2V           --SKYLINK用中間VIEW 品目名取得VIEW
       ,fnd_lookup_values               FLV01           --営業ブロック名取得用
       ,fnd_lookup_values               FLV02           --商品区分名取得用
       ,fnd_user                        FU_CB           --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU           --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL           --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL           --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
    --拠点名取得条件
        XCA2V.party_number(+)       =  TI.jurisdicyional_hub
   AND  XCA2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XCA2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --出庫元名取得条件
   AND  XILV.segment1(+)            =  TI.delivery_whs
    --配送先名取得条件
   AND  XPS2V.party_site_number(+)  =  TI.ship_to
   AND  XPS2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XPS2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --品目名取得条件
   AND  XIM2V.item_no(+)            =  TI.item_code
   AND  XIM2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XIM2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --品目区分取得条件
   AND  XICV.item_id(+)             =  XIM2V.item_id
    --群コード取得条件
   AND  XCCV.item_id(+)             =  XIM2V.item_id
    --営業ブロック名取得条件
   AND  FLV01.language(+)           =  'JA'
   AND  FLV01.lookup_type(+)        =  'XXCMN_AREA'
   AND  FLV01.lookup_code(+)        =  TI.business_block
   --商品区分名取得条件
   AND  FLV02.language(+)           =  'JA'
   AND  FLV02.lookup_type(+)        =  'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+)        =  TI.goods_classe
   --WHOカラム取得
   AND  TI.created_by               =  FU_CB.user_id(+)
   AND  TI.last_updated_by          =  FU_LU.user_id(+)
   AND  TI.last_update_login        =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_振替情報_基本_V                     IS 'SKYLINK用振替情報（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.対象年月           IS '対象年月'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.営業ブロック       IS '営業ブロック'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.営業ブロック名     IS '営業ブロック名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.管轄拠点           IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.管轄拠点名         IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.管轄拠点略称       IS '管轄拠点略称'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.地区名             IS '地区名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.振替数量           IS '振替数量'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.振替金額           IS '振替金額'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.還元金額           IS '還元金額'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.運送費Ａ           IS '運送費Ａ'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.運送費Ｂ           IS '運送費Ｂ'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.運送費Ｃ           IS '運送費Ｃ'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.その他             IS 'その他'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.依頼NO             IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.配送日             IS '配送日'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.出庫元             IS '出庫元'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.出庫元名           IS '出庫元名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.配送先             IS '配送先'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.配送先名           IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.単価               IS '単価'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.計算数量           IS '計算数量'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.実際数量           IS '実際数量'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.金額               IS '金額'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_振替情報_基本_V.最終更新ログイン   IS '最終更新ログイン'
/