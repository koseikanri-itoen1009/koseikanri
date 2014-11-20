CREATE OR REPLACE VIEW APPS.XXSKY_倉替返品ヘッダ_基本_V
(
 依頼NO
,受注タイプ名
,組織名
,受注日
,最新フラグ
,元依頼NO
,顧客
,顧客名
,出荷先
,出荷先名
,出荷指示
,価格表
,価格表名
,ステータス
,ステータス名
,出荷予定日
,着荷予定日
,出荷元保管場所
,出荷元保管場所名
,管轄拠点
,管轄拠点名
,管轄拠点略称
,入力拠点
,入力拠点名
,入力拠点略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,合計数量
,出荷先_実績
,出荷先_予実
,出荷先_実績名
,出荷先_予実名
,出荷日
,出荷日_予実
,着荷日
,着荷日_予実
,実績計上済区分
,確定通知実施日時
,新規修正フラグ
,新規修正フラグ名
,成績管理部署
,成績管理部署名
,登録順序
,出荷依頼締め日時
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XOHA.request_no                  --依頼No
       ,OTTT.name                        --受注タイプ名
       ,HAOUT.name                       --組織名
       ,XOHA.ordered_date                --受注日
       ,XOHA.latest_external_flag        --最新フラグ
       ,XOHA.base_request_no             --元依頼No
       ,XOHA.customer_code               --顧客
       ,XCA2V01.party_name               --顧客名
       ,XOHA.deliver_to                  --出荷先
       ,XPS2V01.party_site_name          --出荷先名
       ,XOHA.shipping_instructions       --出荷指示
       ,XOHA.price_list_id               --価格表
       ,QLHT.name                        --価格表名
       ,XOHA.req_status                  --ステータス
       ,FLV01.meaning                    --ステータス名
       ,XOHA.schedule_ship_date          --出荷予定日
       ,XOHA.schedule_arrival_date       --着荷予定日
       ,XOHA.deliver_from                --出荷元保管場所
       ,XIL2V.description                --出荷元保管場所名
       ,XOHA.head_sales_branch           --管轄拠点
       ,XCA2V02.party_name               --管轄拠点名
       ,XCA2V02.party_short_name         --管轄拠点略称
       ,XOHA.input_sales_branch          --入力拠点
       ,XCA2V03.party_name               --入力拠点名
       ,XCA2V03.party_short_name         --入力拠点略称
       ,XOHA.prod_class                  --商品区分
       ,FLV02.meaning                    --商品区分名
       ,XOHA.item_class                  --品目区分
       ,FLV03.meaning                    --品目区分名
       ,XOHA.sum_quantity                --合計数量
       ,XOHA.result_deliver_to           --出荷先_実績
       ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )                            --NVL( 出荷先_実績, 出荷先 )
                                         --出荷先_予実
       ,XPS2V02.party_site_name          --出荷先_実績名
       ,CASE WHEN XOHA.result_deliver_to IS NULL THEN XPS2V01.party_site_name     --出荷先_実績が存在しない場合は出荷先名
             ELSE                                     XPS2V02.party_site_name     --出荷先_実績が存在する場合は出荷先_実績名
        END                              --出荷先_予実名
       ,XOHA.shipped_date                --出荷日
       ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                         --NVL( 出荷日, 出荷予定日 )
                                         --出荷日_予実
       ,XOHA.arrival_date                --着荷日
       ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                      --NVL( 着荷日, 着荷予定日 )
                                         --着荷日_予実
       ,XOHA.actual_confirm_class        --実績計上済区分
       ,TO_CHAR( XOHA.notif_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --確定通知実施日時
       ,XOHA.new_modify_flg              --新規修正フラグ
       ,FLV04.meaning                    --新規修正フラグ名
       ,XOHA.performance_management_dept --成績管理部署
       ,XL2V.location_name               --成績管理部署名
       ,XOHA.registered_sequence         --登録順序
       ,TO_CHAR( XOHA.tightening_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --出荷依頼締め日時
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( XOHA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( XOHA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM  xxwsh_order_headers_all      XOHA    --受注ヘッダアドオン
       ,oe_transaction_types_all     OTTA    --受注タイプマスタ
       ,oe_transaction_types_tl      OTTT    --受注タイプマスタ(日本語)
       ,hr_all_organization_units_tl HAOUT   --倉庫(組織名)
       ,xxsky_cust_accounts2_v       XCA2V01 --SKYLINK用中間VIEW 顧客情報VIEW2(顧客名)
       ,xxsky_party_sites2_v         XPS2V01 --SKYLINK用中間VIEW 配送先情報VIEW2(出荷先名)
       ,qp_list_headers_tl           QLHT    --価格表
       ,xxsky_item_locations2_v      XIL2V   --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出荷元保管場所名)
       ,xxsky_cust_accounts2_v       XCA2V02 --SKYLINK用中間VIEW 顧客情報VIEW2(管轄拠点名)
       ,xxsky_cust_accounts2_v       XCA2V03 --SKYLINK用中間VIEW 顧客情報VIEW2(入力拠点名)
       ,xxsky_party_sites2_v         XPS2V02 --SKYLINK用中間VIEW 配送先情報VIEW2(出荷先_実績名)
       ,xxsky_locations2_v           XL2V    --SKYLINK用中間VIEW 事業所情報VIEW2(成績管理部署名)
       ,fnd_user                     FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                     FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                     FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                   FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_lookup_values            FLV01   --クイックコード(ステータス名)
       ,fnd_lookup_values            FLV02   --クイックコード(商品区分名)
       ,fnd_lookup_values            FLV03   --クイックコード(品目区分名)
       ,fnd_lookup_values            FLV04   --クイックコード(新規修正フラグ名)
 WHERE
   --倉替返品情報取得
        OTTA.attribute1 = '3'            --倉替返品
   AND  XOHA.latest_external_flag = 'Y'
   AND  XOHA.order_type_id = OTTA.transaction_type_id
   --受注タイプ名取得
   AND  OTTT.language(+) = 'JA'
   AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
   --組織名取得
   AND  HAOUT.language(+) = 'JA'
   AND  XOHA.organization_id = HAOUT.organization_id(+)
   --顧客名取得
   AND  XOHA.customer_id = XCA2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V01.end_date_active(+)
   --出荷先名取得
-- 2010/01/28 M.Miyagawa MOD Start 本番障害#1694
   AND  XOHA.deliver_to = XPS2V01.party_site_number(+)         --配送先コード
--   AND  XOHA.deliver_to_id = XPS2V01.party_site_id(+)        --配送先ID
-- 2010/01/28 M.Miyagawa MOD ENd
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V01.end_date_active(+)
   --価格表名取得
   AND  QLHT.language(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.list_header_id(+)
   --出庫元保管場所名取得
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --管轄拠点名取得
   AND  XOHA.head_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --入力拠点名取得
   AND  XOHA.input_sales_branch = XCA2V03.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V03.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V03.end_date_active(+)
   --出荷先_実績名取得
-- 2010/01/28 M.Miyagawa MOD Start 本番障害#1694
   AND  XOHA.result_deliver_to = XPS2V02.party_site_number(+)  --配送先コード
--   AND  XOHA.result_deliver_to_id = XPS2V02.party_site_id(+) --配送先ID
-- 2010/01/28 M.Miyagawa MOD End
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V02.end_date_active(+)
   --成績管理部署名取得
   AND  XOHA.performance_management_dept = XL2V.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V.end_date_active(+)
   --WHOカラム情報取得
   AND  XOHA.created_by        = FU_CB.user_id(+)
   AND  XOHA.last_updated_by   = FU_LU.user_id(+)
   AND  XOHA.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
   --【クイックコード】ステータス名
   AND  FLV01.language(+) = 'JA'                              --言語
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'     --クイックコードタイプ
   AND  FLV01.lookup_code(+) = XOHA.req_status                --クイックコード
   --【クイックコード】商品区分名
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+) = XOHA.prod_class
   --【クイックコード】品目区分名
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV03.lookup_code(+) = XOHA.item_class
   --【クイックコード】新規修正フラグ名
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV04.lookup_code(+) = XOHA.new_modify_flg
/
COMMENT ON TABLE APPS.XXSKY_倉替返品ヘッダ_基本_V IS 'SKYLINK用倉替返品ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.依頼NO IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.受注タイプ名 IS '受注タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.組織名 IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.受注日 IS '受注日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.最新フラグ IS '最新フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.元依頼NO IS '元依頼No'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.顧客 IS '顧客'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.顧客名 IS '顧客名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先 IS '出荷先'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先名 IS '出荷先名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷指示 IS '出荷指示'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.価格表 IS '価格表'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.価格表名 IS '価格表名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.ステータス IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.ステータス名 IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷予定日 IS '出荷予定日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.着荷予定日 IS '着荷予定日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷元保管場所 IS '出荷元保管場所'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷元保管場所名 IS '出荷元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.管轄拠点 IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.管轄拠点名 IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.管轄拠点略称 IS '管轄拠点略称'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.入力拠点 IS '入力拠点'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.入力拠点名 IS '入力拠点名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.入力拠点略称 IS '入力拠点略称'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.合計数量 IS '合計数量'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先_実績 IS '出荷先_実績'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先_予実 IS '出荷先_予実'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先_実績名 IS '出荷先_実績名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷先_予実名 IS '出荷先_予実名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷日 IS '出荷日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷日_予実 IS '出荷日_予実'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.着荷日 IS '着荷日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.着荷日_予実 IS '着荷日_予実'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.実績計上済区分 IS '実績計上済区分'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.確定通知実施日時 IS '確定通知実施日時'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.新規修正フラグ IS '新規修正フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.新規修正フラグ名 IS '新規修正フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.成績管理部署 IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.成績管理部署名 IS '成績管理部署名'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.登録順序 IS '登録順序'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.出荷依頼締め日時 IS '出荷依頼締め日時'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_倉替返品ヘッダ_基本_V.最終更新ログイン IS '最終更新ログイン'
/
