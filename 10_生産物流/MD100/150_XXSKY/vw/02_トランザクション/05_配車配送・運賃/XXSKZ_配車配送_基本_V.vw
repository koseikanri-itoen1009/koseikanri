/*************************************************************************
 * 
 * View  Name      : XXSKZ_配車配送_基本_V
 * Description     : XXSKZ_配車配送_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_配車配送_基本_V
(
 処理種別_配車
,処理種別_配車名
,混載種別
,混載種別名
,配送NO
,基準明細NO
,運送業者
,運送業者名
,配送元
,配送元名
,配送先コード区分
,配送先コード区分名
,配送先
,配送先名
,配送区分
,配送区分名
,出庫形態
,自動配車対象区分
,自動配車対象区分名
,出庫予定日
,着荷予定日
,摘要
,支払運賃計算対象フラグ
,支払運賃計算対象フラグ名
,請求運賃計算対象フラグ
,請求運賃計算対象フラグ名
,積載重量合計
,積載容積合計
,重量積載効率
,容積積載効率
,基本重量
,基本容積
,運送業者_実績
,運送業者_実績名
,配送区分_実績
,配送区分_実績名
,出荷日
,着荷日
,重量容積区分
,重量容積区分名
,運賃形態
,運賃形態名
,送り状NO
,小口個数
,ラベル枚数
,商品区分
,商品区分名
,伝票なし配車区分
,伝票なし配車区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XCS.transaction_type                                --処理種別_配車
       ,FLV01.meaning           transaction_name            --処理種別_配車名
       ,XCS.mixed_type                                      --混載種別
       ,CASE XCS.mixed_type                                 --混載種別名
            WHEN    '1' THEN    '集約'
            WHEN    '2' THEN    '混載'
        END                     mixed_type_name
       ,XCS.delivery_no                                     --配送No
       ,XCS.default_line_number                             --基準明細No
       ,XCS.carrier_code                                    --運送業者
       ,XC2V01.party_name       carrier_name                --運送業者名
       ,XCS.deliver_from                                    --配送元
       ,XIL2V.description       deliver_from_name           --配送元名
       ,XCS.deliver_to_code_class                           --配送先コード区分
       ,FLV02.meaning           deliver_to_code_name        --配送先コード区分名
       ,XCS.deliver_to                                      --配送先
       ,DVTO.name               deliver_name                --配送先名
       ,XCS.delivery_type                                   --配送区分
       ,FLV03.meaning           delivery_type_name          --配送区分名
       ,OTTT.name               transaction_type_name       --出庫形態
       ,XCS.auto_process_type                               --自動配車対象区分
       ,FLV04.meaning           auto_process_name           --自動配車対象区分名
       ,XCS.schedule_ship_date                              --出庫予定日
       ,XCS.schedule_arrival_date                           --着荷予定日
       ,XCS.description                                     --摘要
       ,XCS.payment_freight_flag                            --支払運賃計算対象フラグ
       ,CASE XCS.payment_freight_flag                       --支払運賃計算対象フラグ名
            WHEN    '0' THEN    '対象外'
            WHEN    '1' THEN    '対象'
        END                     payment_freight_name
       ,XCS.demand_freight_flag                             --請求運賃計算対象フラグ
       ,CASE XCS.demand_freight_flag                        --請求運賃計算対象フラグ名
            WHEN    '0' THEN    '対象外'
            WHEN    '1' THEN    '対象'
        END                     demand_freight_name
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( XCS.sum_loading_weight   )                    --積載重量合計(少数点第以下切り上げ)
       ,CEIL( TRUNC(NVL(XCS.sum_loading_weight,0),1) )      --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( XCS.sum_loading_capacity )                    --積載容積合計(少数点第以下切り上げ)
       ,CEIL( XCS.loading_efficiency_weight   * 100 ) / 100 --重量積載効率(少数点第３位以下切り上げ)
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100 --容積積載効率(少数点第３位以下切り上げ)
       ,XCS.based_weight                                    --基本重量
       ,XCS.based_capacity                                  --基本容積
       ,XCS.result_freight_carrier_code                     --運送業者_実績
       ,XC2V02.party_name       result_freight_carrier_name --運送業者_実績名
       ,XCS.result_shipping_method_code                     --配送区分_実績
       ,FLV05.meaning           result_shipping_method_name --配送区分_実績名
       ,XCS.shipped_date                                    --出荷日
       ,XCS.arrival_date                                    --着荷日
       ,XCS.weight_capacity_class                           --重量容積区分
       ,FLV06.meaning           weight_capacity_name        --重量容積区分名
       ,XCS.freight_charge_type                             --運賃形態
       ,FLV07.meaning           freight_charge_name         --運賃形態名
       ,XCS.slip_number                                     --送り状No
       ,XCS.small_quantity                                  --小口個数
       ,XCS.label_quantity                                  --ラベル枚数
       ,XCS.prod_class                                      --商品区分
       ,FLV08.meaning           prod_name                   --商品区分名
       ,XCS.non_slip_class                                  --伝票なし配車区分
       ,CASE XCS.non_slip_class                             --伝票なし配車区分名
            WHEN    '1' THEN    '通常配車'
            WHEN    '2' THEN    '伝票なし配車'
            WHEN    '3' THEN    '伝票なし配車解除'
        END                     non_slip_name
       ,FU_CB.user_name         created_by_name             --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XCS.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                creation_date               --作成日時
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XCS.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                last_update_date            --更新日時
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxcmn_carriers_schedule_arc  XCS                    --配車配送計画（アドオン）バックアップ
       ,xxskz_carriers2_v       XC2V01                      --SKYLINK用中間VIEW 運送業者取得VIEW
       ,xxskz_carriers2_v       XC2V02                      --SKYLINK用中間VIEW 運送業者取得VIEW
       ,xxskz_item_locations2_v XIL2V                       --SKYLINK用中間VIEW 配送元取得VIEW
       ,(  -- 配送先名取得用（配送先名取得区分の値によって取得先が異なる）
           -- 配送先名取得区分が'1'の場合は配送先名を取得
           SELECT
                  1                      class   -- 1:配送先
                 ,party_site_id          id      -- 配送先コード
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                 ,party_site_number      code    -- 配送先コード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                 ,party_site_name        name    -- 配送先名
                 ,start_date_active      dstart  -- 適用開始日
                 ,end_date_active        dend    -- 適用終了日
           FROM   xxskz_party_sites2_v           -- 配送先
         UNION ALL
           -- 配送先名取得区分が'2'の場合はOPM保管場所名を取得
           SELECT
                  2                      class   -- 2:保管場所
                 ,inventory_location_id  id      -- 保管倉庫コード
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                 ,segment1               code      -- 保管倉庫コード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                 ,description            name    -- 保管倉庫名
                 ,TO_DATE( '19000101', 'YYYYMMDD' )
                                         dstart  -- 適用開始日
                 ,TO_DATE( '99991231', 'YYYYMMDD' )
                                         dend    -- 適用終了日
           FROM  xxskz_item_locations_v          -- 保管倉庫
         UNION ALL
           -- 配送先名取得区分が'3'の場合は工場名を取得
           SELECT
                  3                      class   -- 3:工場
                 ,vendor_site_id         id      -- 取引先サイトコード
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                 ,vendor_site_code       code    -- 取引先サイトコード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                 ,vendor_site_name       name    -- 取引先サイト名
                 ,start_date_active      dstart  -- 適用開始日
                 ,end_date_active        dend    -- 適用終了日
           FROM   xxskz_vendor_sites2_v          -- 仕入先サイトVIEW
        )                       DVTO                        --拠点_取引先名取得用
       ,oe_transaction_types_tl OTTT                        --受注タイプ名取得用
       ,fnd_lookup_values       FLV01                       --処理種別_配車名取得用
       ,fnd_lookup_values       FLV02                       --配送先コード区分名取得用
       ,fnd_lookup_values       FLV03                       --配送区分名取得用
       ,fnd_lookup_values       FLV04                       --自動配車対象区分名取得用
       ,fnd_lookup_values       FLV05                       --配送区分_実績名取得用
       ,fnd_lookup_values       FLV06                       --重量容積区分名取得用
       ,fnd_lookup_values       FLV07                       --運賃形態名取得用
       ,fnd_lookup_values       FLV08                       --商品区分名取得用
       ,fnd_user                FU_CB                       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU                       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL                       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL                       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
    --運送業者名取得条件
        XC2V01.party_id(+)              =  XCS.carrier_id
   AND  XC2V01.start_date_active(+)     <= NVL(XCS.schedule_ship_date, SYSDATE)
   AND  XC2V01.end_date_active(+)       >= NVL(XCS.schedule_ship_date, SYSDATE)
    --運送業者_実績名取得条件
   AND  XC2V02.party_id(+)              =  XCS.result_freight_carrier_id
   AND  XC2V02.start_date_active(+)     <= NVL(XCS.schedule_ship_date, SYSDATE)
   AND  XC2V02.end_date_active(+)       >= NVL(XCS.schedule_ship_date, SYSDATE)
    --配送元名取得条件
   AND  XIL2V.inventory_location_id(+)  =  XCS.deliver_from_id
    --配送先名取得条件
   AND  DECODE( XCS.deliver_to_code_class
              , '1' , '1'     -- 1:拠点     → 1:配送先マスタから名称取得
              , '2' , '1'     -- 2:部署     → 1:配送先マスタから名称取得
              , '3' , '2'     -- 3:倉庫     → 2:保管場所マスタから名称取得
              , '4' , '2'     -- 4:倉庫会社 → 2:保管場所マスタから名称取得
              , '5' , '3'     -- 5:パッカー → 3:仕入先サイトマスタから名称取得
              , '6' , '3'     -- 6:生産工場 → 3:仕入先サイトマスタから名称取得
              , '7' , '1'     -- 7:運送業者 → 1:配送先マスタから名称取得
              , '8' , '3'     -- 8:取引先   → 3:仕入先サイトマスタから名称取得
              , '9' , '1'     -- 9:配送先   → 1:配送先マスタから名称取得
              , '10', '1'     --10:顧客     → 1:配送先マスタから名称取得
              , '11', '3'     --11:支給先   → 3:仕入先サイトマスタから名称取得
              , NULL ) = DVTO.class(+)
-- *----------* 2009/06/23 本番#1438対応 start *----------*
-- 一律コードにて結合
--   AND  XCS.deliver_to_id = DVTO.id(+)
   AND  XCS.deliver_to    = DVTO.code(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
   AND  NVL( XCS.schedule_ship_date, SYSDATE ) >= DVTO.dstart(+)
   AND  NVL( XCS.schedule_ship_date, SYSDATE ) <= DVTO.dend(+)
    --受注タイプ名(出庫形態)取得条件
   AND  OTTT.language(+)                = 'JA'
   AND  OTTT.transaction_type_id(+)     = XCS.order_type_id
    --処理種別_配車名取得条件
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWSH_PROCESS_TYPE'
   AND  FLV01.lookup_code(+)            = XCS.transaction_type
   --配送先コード区分名取得条件
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'CUSTOMER CLASS'
   AND  FLV02.lookup_code(+)            = XCS.deliver_to_code_class
    --配送区分名取得条件
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+)            = XCS.delivery_type
   --自動配車対象区分名取得条件
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV04.lookup_code(+)            = XCS.auto_process_type
    --配送区分_実績名取得条件
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV05.lookup_code(+)            = XCS.result_shipping_method_code
   --重量容積区分名取得条件
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV06.lookup_code(+)            = XCS.weight_capacity_class
    --運賃形態名取得条件
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV07.lookup_code(+)            = XCS.freight_charge_type
   --商品区分名取得条件
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV08.lookup_code(+)            = XCS.prod_class
   --WHOカラム取得
   AND  XCS.created_by                  = FU_CB.user_id(+)
   AND  XCS.last_updated_by             = FU_LU.user_id(+)
   AND  XCS.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_配車配送_基本_V                             IS 'SKYLINK用配車配送（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.処理種別_配車              IS '処理種別_配車'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.処理種別_配車名            IS '処理種別_配車名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.混載種別                   IS '混載種別'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.混載種別名                 IS '混載種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送NO                     IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.基準明細NO                 IS '基準明細No'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運送業者                   IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運送業者名                 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送元                     IS '配送元'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送元名                   IS '配送元名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送先コード区分           IS '配送先コード区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送先コード区分名         IS '配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送先                     IS '配送先'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送先名                   IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送区分                   IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送区分名                 IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.出庫形態                   IS '出庫形態'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.自動配車対象区分           IS '自動配車対象区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.自動配車対象区分名         IS '自動配車対象区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.出庫予定日                 IS '出庫予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.着荷予定日                 IS '着荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.摘要                       IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.支払運賃計算対象フラグ     IS '支払運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.支払運賃計算対象フラグ名   IS '支払運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.請求運賃計算対象フラグ     IS '請求運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.請求運賃計算対象フラグ名   IS '請求運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.積載重量合計               IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.積載容積合計               IS '積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.重量積載効率               IS '重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.容積積載効率               IS '容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.基本重量                   IS '基本重量'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.基本容積                   IS '基本容積'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運送業者_実績              IS '運送業者_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運送業者_実績名            IS '運送業者_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送区分_実績              IS '配送区分_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.配送区分_実績名            IS '配送区分_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.出荷日                     IS '出荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.着荷日                     IS '着荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.重量容積区分               IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.重量容積区分名             IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運賃形態                   IS '運賃形態'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.運賃形態名                 IS '運賃形態名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.送り状NO                   IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.小口個数                   IS '小口個数'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.ラベル枚数                 IS 'ラベル枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.商品区分                   IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.商品区分名                 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.伝票なし配車区分           IS '伝票なし配車区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.伝票なし配車区分名         IS '伝票なし配車区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.作成者                     IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.作成日                     IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.最終更新者                 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.最終更新日                 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_配車配送_基本_V.最終更新ログイン           IS '最終更新ログイン'
/
