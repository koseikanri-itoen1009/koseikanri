/*************************************************************************
 * 
 * View  Name      : XXSKZ_出荷依頼IF_基本_V
 * Description     : XXSKZ_出荷依頼IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出荷依頼IF_基本_V
(
 受注タイプ
,受注日
,出荷先
,出荷先名
,出荷指示
,顧客発注
,受注ソース参照
,出荷予定日
,着荷予定日
,パレット使用枚数
,パレット回収枚数
,出荷元
,出荷元名
,管轄拠点
,管轄拠点名
,入力拠点
,入力拠点名
,着荷時間FROM
,着荷時間FROM名
,着荷時間TO
,着荷時間TO名
,データタイプ
,運送業者
,運送業者名
,配送区分
,配送区分名
,配送NO
,出荷日
,着荷日
,EOSデータ種別
,EOSデータ種別名
,伝送用枝番
,入庫倉庫
,入庫倉庫名
,倉替返品区分
,倉替返品区分名
,依頼区分
,依頼区分名
,報告部署
,報告部署名
,明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,受注品目コード
,受注品目名
,受注品目略称
,ケース数
,数量
,出荷実績数量
,製造日
,固有記号
,賞味期限
,内訳数量
,入庫実績数量
,保留ステータス
,保留ステータス名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XSH_XSL.order_type                  --受注タイプ
       ,XSH_XSL.ordered_date                --受注日
       ,XSH_XSL.party_site_code             --出荷先
       ,XPSV.party_site_name                --出荷先名
       ,XSH_XSL.shipping_instructions       --出荷指示
       ,XSH_XSL.cust_po_number              --顧客発注
       ,XSH_XSL.order_source_ref            --受注ソース参照
       ,XSH_XSL.schedule_ship_date          --出荷予定日
       ,XSH_XSL.schedule_arrival_date       --着荷予定日
       ,XSH_XSL.used_pallet_qty             --パレット使用枚数
       ,XSH_XSL.collected_pallet_qty        --パレット回収枚数
       ,XSH_XSL.location_code               --出荷元
       ,XLV_SHU.location_name               --出荷元名
       ,XSH_XSL.head_sales_branch           --管轄拠点
       ,XCAV_KAN.party_name                 --管轄拠点名
       ,XSH_XSL.input_sales_branch          --入力拠点
       ,XCAV_NYU.party_name                 --入力拠点名
       ,XSH_XSL.arrival_time_from           --着荷時間FROM
       ,FLV_CHFROM.meaning                  --着荷時間FROM名
       ,XSH_XSL.arrival_time_to             --着荷時間TO
       ,FLV_CHTO.meaning                    --着荷時間TO名
       ,XSH_XSL.data_type                   --データタイプ
       ,XSH_XSL.freight_carrier_code        --運送業者
       ,XCV.party_name                      --運送業者名
       ,XSH_XSL.shipping_method_code        --配送区分
       ,FLV_HAI.meaning                     --配送区分名
       ,XSH_XSL.delivery_no                 --配送No
       ,XSH_XSL.shipped_date                --出荷日
       ,XSH_XSL.arrival_date                --着荷日
       ,XSH_XSL.eos_data_type               --EOSデータ種別
       ,FLV_EOS.meaning                     --EOSデータ種別名
       ,XSH_XSL.tranceration_number         --伝送用枝番
       ,XSH_XSL.ship_to_location            --入庫倉庫
       ,XILV.description                    --入庫倉庫名
       ,XSH_XSL.rm_class                    --倉替返品区分
       ,FLV_KURA.meaning                    --倉替返品区分名
       ,XSH_XSL.ordered_class               --依頼区分
       ,XSCV.request_class_name             --依頼区分名
       ,XSH_XSL.report_post_code            --報告部署
       ,XLV_HOU.location_name               --報告部署名
       ,XSH_XSL.line_number                 --明細番号
       ,XPCV.prod_class_code                --商品区分
       ,XPCV.prod_class_name                --商品区分名
       ,XICV.item_class_code                --品目区分
       ,XICV.item_class_name                --品目区分名
       ,XCCV.crowd_code                     --群コード
       ,XSH_XSL.orderd_item_code            --受注品目コード
       ,XIMV.item_name                      --受注品目名
       ,XIMV.item_short_name                --受注品目略称
       ,XSH_XSL.case_quantity               --ケース数
       ,XSH_XSL.orderd_quantity             --数量
       ,XSH_XSL.shiped_quantity             --出荷実績数量
-- 2009/03/25 H.Iida MOD START 本番障害#1329
--       ,XSH_XSL.designated_production_date  --製造日
       ,TO_CHAR( XSH_XSL.designated_production_date, 'YYYY/MM/DD')
                                            --製造日
-- 2009/03/25 H.Iida MOD END
       ,XSH_XSL.original_character          --固有記号
-- 2009/03/25 H.Iida MOD START 本番障害#1329
--       ,XSH_XSL.use_by_date                 --賞味期限
       ,TO_CHAR( XSH_XSL.use_by_date, 'YYYY/MM/DD')
                                            --賞味期限
-- 2009/03/25 H.Iida MOD END
       ,XSH_XSL.detailed_quantity           --内訳数量
       ,XSH_XSL.ship_to_quantity            --入庫実績数量
       ,XSH_XSL.reserved_status             --保留ステータス
       ,CASE XSH_XSL.reserved_status        --保留ステータス名
           WHEN '1' THEN '保留'
        END
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XSH_XSL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XSH_XSL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM
        ( SELECT 
             XSHI.order_type                    AS  order_type                  --受注タイプ
            ,XSHI.ordered_date                  AS  ordered_date                --受注日
            ,XSHI.party_site_code               AS  party_site_code             --出荷先
            ,XSHI.shipping_instructions         AS  shipping_instructions       --出荷指示
            ,XSHI.cust_po_number                AS  cust_po_number              --顧客発注
            ,XSHI.order_source_ref              AS  order_source_ref            --受注ソース参照
            ,XSHI.schedule_ship_date            AS  schedule_ship_date          --出荷予定日
            ,XSHI.schedule_arrival_date         AS  schedule_arrival_date       --着荷予定日
            ,XSHI.used_pallet_qty               AS  used_pallet_qty             --パレット使用枚数
            ,XSHI.collected_pallet_qty          AS  collected_pallet_qty        --パレット回収枚数
            ,XSHI.location_code                 AS  location_code               --出荷元
            ,XSHI.head_sales_branch             AS  head_sales_branch           --管轄拠点
            ,XSHI.input_sales_branch            AS  input_sales_branch          --入力拠点
            ,XSHI.arrival_time_from             AS  arrival_time_from           --着荷時間FROM
            ,XSHI.arrival_time_to               AS  arrival_time_to             --着荷時間TO
            ,XSHI.data_type                     AS  data_type                   --データタイプ
            ,XSHI.freight_carrier_code          AS  freight_carrier_code        --運送業者
            ,XSHI.shipping_method_code          AS  shipping_method_code        --配送区分
            ,XSHI.delivery_no                   AS  delivery_no                 --配送No
            ,XSHI.shipped_date                  AS  shipped_date                --出荷日
            ,XSHI.arrival_date                  AS  arrival_date                --着荷日
            ,XSHI.eos_data_type                 AS  eos_data_type               --EOSデータ種別
            ,XSHI.tranceration_number           AS  tranceration_number         --伝送用枝番
            ,XSHI.ship_to_location              AS  ship_to_location            --入庫倉庫
            ,XSHI.rm_class                      AS  rm_class                    --倉替返品区分
            ,XSHI.ordered_class                 AS  ordered_class               --依頼区分
            ,XSHI.report_post_code              AS  report_post_code            --報告部署
            ,XSLI.line_number                   AS  line_number                 --明細番号
            ,XSLI.orderd_item_code              AS  orderd_item_code            --受注品目コード
            ,XSLI.case_quantity                 AS  case_quantity               --ケース数
            ,XSLI.orderd_quantity               AS  orderd_quantity             --数量
            ,XSLI.shiped_quantity               AS  shiped_quantity             --出荷実績数量
            ,XSLI.designated_production_date    AS  designated_production_date  --製造日
            ,XSLI.original_character            AS  original_character          --固有記号
            ,XSLI.use_by_date                   AS  use_by_date                 --賞味期限
            ,XSLI.detailed_quantity             AS  detailed_quantity           --内訳数量
            ,XSLI.ship_to_quantity              AS  ship_to_quantity            --入庫実績数量
            ,XSLI.reserved_status               AS  reserved_status             --保留ステータス
            ,XSHI.creation_date                 AS  creation_date               --作成日
            ,XSHI.last_update_date              AS  last_update_date            --最終更新日
            ,XSHI.last_update_login             AS  last_update_login
            ,XSHI.created_by                    AS  created_by
            ,XSHI.last_updated_by               AS  last_updated_by
          FROM 
             xxwsh_shipping_headers_if          XSHI        --出荷依頼インタフェースアドオンヘッダ
            ,xxwsh_shipping_lines_if            XSLI        --出荷依頼インタフェースアドオン明細
          WHERE
             XSHI.header_id = XSLI.header_id                --出荷依頼インタフェースアドオンヘッダ・明細結合
        )                                       XSH_XSL
       ,xxskz_party_sites2_v                    XPSV        --出荷先名取得
       ,xxskz_locations2_v                      XLV_SHU     --出荷元事業所取得
       ,xxskz_cust_accounts2_v                  XCAV_KAN    --管轄拠点名取得
       ,xxskz_cust_accounts2_v                  XCAV_NYU    --入力拠点名取得
       ,fnd_lookup_values                       FLV_CHFROM  --着荷時間FROM名取得
       ,fnd_lookup_values                       FLV_CHTO    --着荷時間TO名取得用結合
       ,xxskz_carriers2_v                       XCV         --運送業者名取得
       ,fnd_lookup_values                       FLV_HAI     --配送区分名取得用結合
       ,fnd_lookup_values                       FLV_EOS     --EOSデータ種別名取得用結合
       ,fnd_lookup_values                       FLV_KURA    --倉替返品区分名取得用結合
       ,xxskz_item_locations_v                  XILV        --保管倉庫名取得
       ,( SELECT DISTINCT 
             request_class
            ,request_class_name
            ,start_date_active
            ,end_date_active
          FROM  xxwsh_shipping_class2_v
          WHERE request_class IS NOT NULL
        )                                       XSCV        --依頼区分取得
       ,xxskz_locations2_v                      XLV_HOU     --報告部署所取得
       ,xxskz_item_mst2_v                       XIMV        --品目名取得(商品区分・品目区分・群コード取得にも使用)
       ,xxskz_prod_class_v                      XPCV        --商品区分取得
       ,xxskz_item_class_v                      XICV        --品目区分取得
       ,xxskz_crowd_code_v                      XCCV        --群コード取得
       ,fnd_user                                FU_CB       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                                FU_LU       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                                FU_LL       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                              FL_LL       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
  --出荷先名取得用結合
      XSH_XSL.party_site_code = XPSV.party_site_number(+)
  AND XPSV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XPSV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --出荷元事業所取得用結合
  AND XLV_SHU.LOCATION_CODE(+) = XSH_XSL.location_code
  AND XLV_SHU.START_DATE_ACTIVE(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_SHU.END_DATE_ACTIVE(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --管轄拠点名取得用結合
  AND XCAV_KAN.party_number(+) = XSH_XSL.head_sales_branch
  AND XCAV_KAN.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_KAN.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --入力拠点名取得用結合
  AND XCAV_NYU.party_number(+) = XSH_XSL.input_sales_branch
  AND XCAV_NYU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_NYU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --着荷時間FROM名取得用結合
  AND FLV_CHFROM.language(+) = 'JA'
  AND FLV_CHFROM.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHFROM.lookup_code(+) = XSH_XSL.arrival_time_from
  --着荷時間TO名取得用結合
  AND FLV_CHTO.language(+) = 'JA'
  AND FLV_CHTO.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHTO.lookup_code(+) = XSH_XSL.arrival_time_to
  --運送業者名取得用結合
  AND XSH_XSL.freight_carrier_code = XCV.freight_code(+)
  AND XCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --配送区分名取得用結合
  AND FLV_HAI.language(+) = 'JA'
  AND FLV_HAI.lookup_type(+) = 'XXCMN_SHIP_METHOD'
  AND FLV_HAI.lookup_code(+) = XSH_XSL.shipping_method_code
  --EOSデータ種別名取得用結合
  AND FLV_EOS.language(+) = 'JA'
  AND FLV_EOS.lookup_type(+) = 'XXCMN_D17'
  AND FLV_EOS.lookup_code(+) = XSH_XSL.eos_data_type
  --倉替返品区分名取得用結合
  AND FLV_KURA.language(+) = 'JA'
  AND FLV_KURA.lookup_type(+) = 'XXCMN_L03'
  AND FLV_KURA.lookup_code(+) = XSH_XSL.rm_class
  --保管倉庫名取得用結合
  AND XSH_XSL.ship_to_location = XILV.segment1(+)
  --依頼区分取得用結合
  AND XSH_XSL.ordered_class = XSCV.request_class(+)
  AND XSCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XSCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --報告部署取得用結合
  AND XLV_HOU.location_code(+) = XSH_XSL.report_post_code
  AND XLV_HOU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_HOU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --品目名取得用結合
  AND XIMV.item_no(+) = XSH_XSL.orderd_item_code
  AND XIMV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XIMV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --商品区分取得用結合
  AND XIMV.item_id = XPCV.item_id(+)
  --品目区分取得用結合
  AND XIMV.item_id = XICV.item_id(+)
  --群コード取得用結合
  AND XIMV.item_id = XCCV.item_id(+)
  AND FU_CB.user_id(+)  = XSH_XSL.created_by                    --CREATED_BY名称取得用結合
  AND FU_LU.user_id(+)  = XSH_XSL.last_updated_by               --LAST_UPDATE_BY名称取得用結合
  AND FL_LL.login_id(+) = XSH_XSL.last_update_login             --LAST_UPDATE_LOGIN名称取得用結合
  AND FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_出荷依頼IF_基本_V IS 'XXSKZ_出荷依頼IF (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注タイプ            IS '受注タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注日                IS '受注日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷先                IS '出荷先'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷先名              IS '出荷先名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷指示              IS '出荷指示'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.顧客発注              IS '顧客発注'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注ソース参照        IS '受注ソース参照'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷予定日            IS '出荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷予定日            IS '着荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.パレット使用枚数      IS 'パレット使用枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.パレット回収枚数      IS 'パレット回収枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷元                IS '出荷元'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷元名              IS '出荷元名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.管轄拠点              IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.管轄拠点名            IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.入力拠点              IS '入力拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.入力拠点名            IS '入力拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷時間FROM          IS '着荷時間FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷時間FROM名        IS '着荷時間FROM名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷時間TO            IS '着荷時間TO'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷時間TO名          IS '着荷時間TO名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.データタイプ          IS 'データタイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.運送業者              IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.運送業者名            IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.配送区分              IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.配送区分名            IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.配送NO                IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷日                IS '出荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.着荷日                IS '着荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.EOSデータ種別         IS 'EOSデータ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.EOSデータ種別名       IS 'EOSデータ種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.伝送用枝番            IS '伝送用枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.入庫倉庫              IS '入庫倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.入庫倉庫名            IS '入庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.倉替返品区分          IS '倉替返品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.倉替返品区分名        IS '倉替返品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.依頼区分              IS '依頼区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.依頼区分名            IS '依頼区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.報告部署              IS '報告部署'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.報告部署名            IS '報告部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.明細番号              IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.商品区分              IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.商品区分名            IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.品目区分              IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.品目区分名            IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.群コード              IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注品目コード        IS '受注品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注品目名            IS '受注品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.受注品目略称          IS '受注品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.ケース数              IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.数量                  IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.出荷実績数量          IS '出荷実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.製造日                IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.固有記号              IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.賞味期限              IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.内訳数量              IS '内訳数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.入庫実績数量          IS '入庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.保留ステータス        IS '保留ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.保留ステータス名      IS '保留ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.作成者                IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.作成日                IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.最終更新者            IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.最終更新日            IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷依頼IF_基本_V.最終更新ログイン      IS '最終更新ログイン'
/
