/*************************************************************************
 * 
 * View  Name      : XXSKZ_支給ヘッダ_基本_V
 * Description     : XXSKZ_支給ヘッダ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_支給ヘッダ_基本_V
(
 依頼NO
,配送NO
,受注タイプ名
,組織名
,受注日
,最新フラグ
,元依頼NO
,前回配送NO
,顧客
,顧客名
,取引先
,取引先名
,取引先サイト
,取引先サイト名
,出荷指示
,運送業者
,運送業者名
,配送区分
,配送区分名
,価格表
,価格表名
,ステータス
,ステータス名
,出荷予定日
,着荷予定日
,運賃区分
,運賃区分名
,支給出庫指示区分
,支給出庫指示区分名
,支給指示受領区分
,支給指示受領区分名
,有償金額確定区分
,有償金額確定区分名
,引取区分
,引取区分名
,出荷元保管場所
,出荷元保管場所名
,入力拠点
,入力拠点名
,入力拠点略称
,発注NO
,商品区分
,商品区分名
,品目区分
,品目区分名
,契約外運賃区分
,契約外運賃区分名
,着荷時間FROM
,着荷時間FROM名
,着荷時間TO
,着荷時間TO名
,製造品目
,製造品目名
,製造日
,製造枝番
,送り状NO
,合計数量
,小口個数
,ラベル枚数
,重量積載効率
,容積積載効率
,基本重量
,基本容積
,積載重量合計
,積載容積合計
,混載率
,パレット合計枚数
,パレット実績枚数
,合計パレット重量
,運送業者_実績
,運送業者_予実
,運送業者_実績名
,運送業者_予実名
,配送区分_実績
,配送区分_予実
,配送区分_実績名
,配送区分_予実名
,出荷日
,出荷日_予実
,着荷日
,着荷日_予実
,重量容積区分
,重量容積区分名
,実績計上済区分
,通知ステータス
,通知ステータス名
,前回通知ステータス
,前回通知ステータス名
,確定通知実施日時
,新規修正フラグ
,新規修正フラグ名
,成績管理部署
,成績管理部署名
,指示部署
,指示部署名
,混載記号
,画面更新日時
,画面更新者
,配送_処理種別
,配送_処理種別名
,配送_混載種別
,配送_混載種別名
,配送_配送先コード区分
,配送_配送先コード区分名
,配送_自動配車対象区分
,配送_自動配車対象区分名
,配送_摘要
,配送_支払運賃計算対象フラグ
,配送_支払運賃計算対象フラグ名
,配送_請求運賃計算対象フラグ
,配送_請求運賃計算対象フラグ名
,配送_積載重量合計
,配送_積載容積合計
,配送_重量積載効率
,配送_容積積載効率
,配送_運賃形態
,配送_運賃形態名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XOHA.request_no                  --依頼No
       ,XOHA.delivery_no                 --配送No
       ,OTTT.name                        --受注タイプ名
       ,HAOUT.name                       --組織名
       ,XOHA.ordered_date                --受注日
       ,XOHA.latest_external_flag        --最新フラグ
       ,XOHA.base_request_no             --元依頼No
       ,XOHA.prev_delivery_no            --前回配送No
       ,XOHA.customer_code               --顧客
       ,XCA2V01.party_name               --顧客名
       ,XOHA.vendor_code                 --取引先
       ,XV2V.vendor_name                 --取引先名
       ,XOHA.vendor_site_code            --取引先サイト
       ,XVS2V.vendor_site_name           --取引先サイト名
       ,XOHA.shipping_instructions       --出荷指示
       ,XOHA.freight_carrier_code        --運送業者
       ,XC2V01.party_name                --運送業者名
       ,XOHA.shipping_method_code        --配送区分
       ,FLV01.meaning                    --配送区分名
       ,XOHA.price_list_id               --価格表
       ,QLHT.name                        --価格表名
       ,XOHA.req_status                  --ステータス
       ,FLV02.meaning                    --ステータス名
       ,XOHA.schedule_ship_date          --出荷予定日
       ,XOHA.schedule_arrival_date       --着荷予定日
       ,XOHA.freight_charge_class        --運賃区分
       ,FLV03.meaning                    --運賃区分名
       ,XOHA.shikyu_instruction_class    --支給出庫指示区分
       ,FLV04.meaning                    --支給出庫指示区分名
       ,XOHA.shikyu_inst_rcv_class       --支給指示受領区分
       ,FLV05.meaning                    --支給指示受領区分名
       ,XOHA.amount_fix_class            --有償金額確定区分
       ,FLV06.meaning                    --有償金額確定区分名
       ,XOHA.takeback_class              --引取区分
       ,FLV07.meaning                    --引取区分名
       ,XOHA.deliver_from                --出荷元保管場所
       ,XIL2V.description                --出荷元保管場所名
       ,XOHA.input_sales_branch          --入力拠点
       ,XCA2V02.party_name               --入力拠点名
       ,XCA2V02.party_short_name         --入力拠点略称
       ,XOHA.po_no                       --発注No
       ,XOHA.prod_class                  --商品区分
       ,FLV08.meaning                    --商品区分名
       ,XOHA.item_class                  --品目区分
       ,FLV09.meaning                    --品目区分名
       ,XOHA.no_cont_freight_class       --契約外運賃区分
       ,FLV10.meaning                    --契約外運賃区分名
       ,XOHA.arrival_time_from           --着荷時間FROM
       ,FLV11.meaning                    --着荷時間FROM名
       ,XOHA.arrival_time_to             --着荷時間TO
       ,FLV12.meaning                    --着荷時間TO名
       ,XOHA.designated_item_code        --製造品目
       ,XIM2V.item_name                  --製造品目名
       ,XOHA.designated_production_date  --製造日
       ,XOHA.designated_branch_no        --製造枝番
       ,XOHA.slip_number                 --送り状No
       ,XOHA.sum_quantity                --合計数量
       ,XOHA.small_quantity              --小口個数
       ,XOHA.label_quantity              --ラベル枚数
       ,CEIL( XOHA.loading_efficiency_weight * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_weight        --重量積載効率
       ,CEIL( XOHA.loading_efficiency_capacity * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_capacity      --容積積載効率
       ,CEIL( XOHA.based_weight )
        based_weight                     --基本重量
       ,CEIL( XOHA.based_capacity )
        based_capacity                   --基本容積
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XOHA.sum_weight )
       ,CEIL(TRUNC(NVL(XOHA.sum_weight,0),1))     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/8 #627 Y.Fukami Mod Start
        sum_weight                       --積載重量合計
       ,CEIL( XOHA.sum_capacity )
        sum_capacity                     --積載容積合計
       ,CEIL( XOHA.mixed_ratio * 100 ) / 100  --少数点弟３以下切り上げ
        mixed_ratio                      --混載率
       ,XOHA.pallet_sum_quantity         --パレット合計枚数
       ,XOHA.real_pallet_quantity        --パレット実績枚数
       ,XOHA.sum_pallet_weight           --合計パレット重量
       ,XOHA.result_freight_carrier_code --運送業者_実績
       ,NVL( XOHA.result_freight_carrier_code, XOHA.freight_carrier_code )        --NVL( 運送業者_実績, 運送業者 )
                                         --運送業者_予実
       ,XC2V02.party_name                --運送業者_実績名
       ,CASE WHEN XOHA.result_freight_carrier_code IS NULL THEN XC2V01.party_name --運送業者_実績が存在しない場合は運送業者名
             ELSE                                               XC2V02.party_name --運送業者_実績が存在する場合は運送業者_実績名
        END                              --運送業者_予実名
       ,XOHA.result_shipping_method_code --配送区分_実績
       ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )        --NVL( 配送区分_実績, 配送区分 )
                                         --配送区分_予実
       ,FLV13.meaning                    --配送区分_実績名
       ,CASE WHEN XOHA.result_shipping_method_code IS NULL THEN FLV01.meaning     --配送区分_実績が存在しない場合は配送区分名
             ELSE                                               FLV10.meaning     --配送区分_実績が存在する場合は配送区分_実績名
        END                              --配送区分_予実名
       ,XOHA.shipped_date                --出荷日
       ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                         --NVL( 出荷日, 出荷予定日 )
                                         --出荷日_予実
       ,XOHA.arrival_date                --着荷日
       ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                      --NVL( 着荷日, 着荷予定日 )
                                         --着荷日_予実
       ,XOHA.weight_capacity_class       --重量容積区分
       ,FLV14.meaning                    --重量容積区分名
       ,XOHA.actual_confirm_class        --実績計上済区分
       ,XOHA.notif_status                --通知ステータス
       ,FLV15.meaning                    --通知ステータス名
       ,XOHA.prev_notif_status           --前回通知ステータス
       ,FLV16.meaning                    --前回通知ステータス名
       ,TO_CHAR( XOHA.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --確定通知実施日時
       ,XOHA.new_modify_flg              --新規修正フラグ
       ,FLV17.meaning                    --新規修正フラグ名
       ,XOHA.performance_management_dept --成績管理部署
       ,XL2V01.location_name             --成績管理部署名
       ,XOHA.instruction_dept            --指示部署
       ,XL2V02.location_name             --指示部署名
       ,XOHA.mixed_sign                  --混載記号
       ,TO_CHAR( XOHA.screen_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --画面更新日時
       ,FU.user_name                     --画面更新者
       ,XCS.transaction_type             --配送_処理種別
       ,FLV18.meaning                    --配送_処理種別名
       ,XCS.mixed_type                   --配送_混載種別
       ,DECODE(XCS.mixed_type, '1', '集約', '2', '混載')
        mixed_type_name                  --配送_混載種別名
       ,XCS.deliver_to_code_class        --配送_配送先コード区分
       ,FLV19.meaning                    --配送_配送先コード区分名
       ,XCS.auto_process_type            --配送_自動配車対象区分
       ,FLV20.meaning                    --配送_自動配車対象区分名
       ,XCS.description                  --配送_摘要
       ,XCS.payment_freight_flag         --配送_支払運賃計算対象フラグ
       ,DECODE(XCS.payment_freight_flag, '0', '対象外', '1', '対象')
        payment_freight_flag_name        --配送_支払運賃計算対象フラグ名
       ,XCS.demand_freight_flag          --配送_請求運賃計算対象フラグ
       ,DECODE(XCS.demand_freight_flag, '0', '対象外', '1', '対象')
        demand_freight_flag_name         --配送_請求運賃計算対象フラグ名
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XCS.sum_loading_weight )
       ,CEIL( TRUNC(NVL(XCS.sum_loading_weight,0),1) )     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/8 #627 Y.Fukami Mod End
        sum_loading_weight               --配送_積載重量合計
       ,CEIL( XCS.sum_loading_capacity )
        sum_loading_capacity             --配送_積載容積合計
       ,CEIL( XCS.loading_efficiency_weight * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_weight        --配送_重量積載効率
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_capacity      --配送_容積積載効率
       ,XCS.freight_charge_type          --配送_運賃形態
       ,FLV21.meaning                    --配送_運賃形態名
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( XOHA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( XOHA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM  xxcmn_order_headers_all_arc      XOHA    --受注ヘッダ（アドオン）バックアップ
       ,oe_transaction_types_all     OTTA    --受注タイプマスタ
       ,xxcmn_carriers_schedule_arc      XCS     --配車配送計画（アドオン）バックアップ
       ,oe_transaction_types_tl      OTTT    --受注タイプマスタ(日本語)
       ,hr_all_organization_units_tl HAOUT   --倉庫(組織名)
       ,xxskz_cust_accounts2_v       XCA2V01 --SKYLINK用中間VIEW 顧客情報VIEW2(顧客名)
       ,xxskz_vendors2_v             XV2V    --仕入先情報VIEW2(取引先名)
       ,xxskz_vendor_sites2_v        XVS2V   --仕入先サイト情報VIEW2(仕入先サイト名)
       ,xxskz_carriers2_v            XC2V01  --運送業者情報VIEW2(運送業者名)
       ,qp_list_headers_tl           QLHT    --価格表
       ,xxskz_item_locations2_v      XIL2V   --OPM保管場所情報VIEW2(出荷元保管場所名)
       ,xxskz_cust_accounts2_v       XCA2V02 --SKYLINK用中間VIEW 顧客情報VIEW2(入力拠点)
       ,xxskz_item_mst2_v            XIM2V   --SKYLINK用中間VIEW OPM品目情報VIEW2(製造品目名)
       ,xxskz_carriers2_v            XC2V02  --運送業者情報VIEW2(運送業者名)
       ,xxskz_locations2_v           XL2V01  --SKYLINK用中間VIEW 事業所情報VIEW2(成績管理部署名)
       ,xxskz_locations2_v           XL2V02  --SKYLINK用中間VIEW 事業所情報VIEW2(指示部署名)
       ,fnd_user                     FU      --ユーザーマスタ(画面更新者)
       ,fnd_user                     FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                     FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                     FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                   FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_lookup_values            FLV01   --クイックコード(配送区分名)
       ,fnd_lookup_values            FLV02   --クイックコード(ステータス名)
       ,fnd_lookup_values            FLV03   --クイックコード(運賃区分名)
       ,fnd_lookup_values            FLV04   --クイックコード(支給出庫指示区分名)
       ,fnd_lookup_values            FLV05   --クイックコード(支給指示受領区分名)
       ,fnd_lookup_values            FLV06   --クイックコード(有償金額確定区分名)
       ,fnd_lookup_values            FLV07   --クイックコード(引取区分名)
       ,fnd_lookup_values            FLV08   --クイックコード(商品区分名)
       ,fnd_lookup_values            FLV09   --クイックコード(品目区分名)
       ,fnd_lookup_values            FLV10   --クイックコード(契約外運賃区分名)
       ,fnd_lookup_values            FLV11   --クイックコード(着荷時間FROM名)
       ,fnd_lookup_values            FLV12   --クイックコード(着荷時間TO名)
       ,fnd_lookup_values            FLV13   --クイックコード(配送区分_実績名)
       ,fnd_lookup_values            FLV14   --クイックコード(重量容積区分名)
       ,fnd_lookup_values            FLV15   --クイックコード(通知ステータス名)
       ,fnd_lookup_values            FLV16   --クイックコード(前回通知ステータス名)
       ,fnd_lookup_values            FLV17   --クイックコード(新規修正フラグ名)
       ,fnd_lookup_values            FLV18   --クイックコード(配送_処理種別名)
       ,fnd_lookup_values            FLV19   --クイックコード(配送_配送先コード区分名)
       ,fnd_lookup_values            FLV20   --クイックコード(配送_自動配車対象区分名)
       ,fnd_lookup_values            FLV21   --クイックコード(配送_運賃形態名)
 WHERE
   --支給情報取得
        OTTA.attribute1 = '2'            -- 支給
   AND  XOHA.latest_external_flag = 'Y'
   AND  XOHA.order_type_id = OTTA.transaction_type_id
   --配車/配送アドオン情報取得
   AND  XOHA.delivery_no = XCS.delivery_no(+)
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
   --取引先名取得
   AND  XOHA.vendor_id = XV2V.vendor_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XV2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XV2V.end_date_active(+)
   --取引先サイト名取得
   AND  XOHA.vendor_site_id = XVS2V.vendor_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XVS2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XVS2V.end_date_active(+)
   --運送業者名取得
   AND  XOHA.career_id = XC2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V01.end_date_active(+)
   --価格表名取得
   AND  QLHT.LANGUAGE(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.LIST_HEADER_ID(+)
   --出荷元保管場所名取得
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --入力拠点名取得
   AND  XOHA.input_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --製造品目情報取得
-- 2009/03/30 H.Iida MOD START 本番障害#1344
--   AND  XOHA.designated_item_id = XIM2V.item_id(+)
   AND  XOHA.designated_item_code = XIM2V.item_no(+)
-- 2009/03/30 H.Iida MOD END
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XIM2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XIM2V.end_date_active(+)
   --運送業者_実績名取得
   AND  XOHA.result_freight_carrier_id = XC2V02.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V02.end_date_active(+)
   --成績管理部署名取得
   AND  XOHA.performance_management_dept = XL2V01.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V01.end_date_active(+)
   --指示部署名取得
   AND  XOHA.instruction_dept = XL2V02.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V02.end_date_active(+)
   --画面更新者名取得
   AND  XOHA.screen_update_by  = FU.user_id(+)
   --WHOカラム情報取得
   AND  XOHA.created_by        = FU_CB.user_id(+)
   AND  XOHA.last_updated_by   = FU_LU.user_id(+)
   AND  XOHA.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
   --【クイックコード】配送区分名
   AND  FLV01.language(+) = 'JA'                              --言語
   AND  FLV01.lookup_type(+) = 'XXCMN_SHIP_METHOD'            --クイックコードタイプ
   AND  FLV01.lookup_code(+) = XOHA.shipping_method_code      --クイックコード
   --【クイックコード】ステータス名
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXPO_TRANSACTION_STATUS'
   AND  FLV02.lookup_code(+) = XOHA.req_status
   --【クイックコード】運賃区分名
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV03.lookup_code(+) = XOHA.freight_charge_class
   --【クイックコード】支給出庫指示区分名
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXWSH_SHIKYU_INSTRUCTION_CLASS'
   AND  FLV04.lookup_code(+) = XOHA.shikyu_instruction_class
   --【クイックコード】支給指示受領区分名
   AND  FLV05.language(+) = 'JA'
   AND  FLV05.lookup_type(+) = 'XXWSH_SHIKYU_INST_RCV_CLASS'
   AND  FLV05.lookup_code(+) = XOHA.shikyu_inst_rcv_class
   --【クイックコード】有償金額確定区分名
   AND  FLV06.language(+) = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWSH_AMOUNT_FIX_CLASS'
   AND  FLV06.lookup_code(+) = XOHA.amount_fix_class
   --【クイックコード】引取区分名
   AND  FLV07.language(+) = 'JA'
   AND  FLV07.lookup_type(+) = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV07.lookup_code(+) = XOHA.takeback_class
   --【クイックコード】商品区分名
   AND  FLV08.language(+) = 'JA'
   AND  FLV08.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV08.lookup_code(+) = XOHA.prod_class
   --【クイックコード】品目区分名
   AND  FLV09.language(+) = 'JA'
   AND  FLV09.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV09.lookup_code(+) = XOHA.item_class
   --【クイックコード】契約外運金区分名
   AND  FLV10.language(+) = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV10.lookup_code(+) = XOHA.no_cont_freight_class
   --【クイックコード】着荷時間FROM名
   AND  FLV11.language(+) = 'JA'
   AND  FLV11.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV11.lookup_code(+) = XOHA.arrival_time_from
   --【クイックコード】着荷時間TO名
   AND  FLV12.language(+) = 'JA'
   AND  FLV12.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV12.lookup_code(+) = XOHA.arrival_time_to
   --【クイックコード】配送区分_実績名
   AND  FLV13.language(+) = 'JA'
   AND  FLV13.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV13.lookup_code(+) = XOHA.result_shipping_method_code
   --【クイックコード】重量容積区分名
   AND  FLV14.language(+) = 'JA'
   AND  FLV14.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV14.lookup_code(+) = XOHA.weight_capacity_class
   --【クイックコード】通知ステータス名
   AND  FLV15.language(+) = 'JA'
   AND  FLV15.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV15.lookup_code(+) = XOHA.notif_status
   --【クイックコード】前回通知ステータス名
   AND  FLV16.language(+) = 'JA'
   AND  FLV16.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV16.lookup_code(+) = XOHA.prev_notif_status
   --【クイックコード】新規修正フラグ名
   AND  FLV17.language(+) = 'JA'
   AND  FLV17.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV17.lookup_code(+) = XOHA.new_modify_flg
   --【クイックコード】配送_処理種別名
   AND  FLV18.language(+) = 'JA'
   AND  FLV18.lookup_type(+) = 'XXWSH_PROCESS_TYPE'
   AND  FLV18.lookup_code(+) = XCS.transaction_type
   --【クイックコード】配送_配送先コード区分名
   AND  FLV19.language(+) = 'JA'
   AND  FLV19.lookup_type(+) = 'CUSTOMER CLASS'
   AND  FLV19.lookup_code(+) = XCS.deliver_to_code_class
   --【クイックコード】配送_自動配車対象区分名
   AND  FLV20.language(+) = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV20.lookup_code(+) = XCS.auto_process_type
   --【クイックコード】配送_運賃形態
   AND  FLV21.language(+) = 'JA'
   AND  FLV21.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV21.lookup_code(+) = XCS.freight_charge_type
/
COMMENT ON TABLE APPS.XXSKZ_支給ヘッダ_基本_V IS 'SKYLINK用支給ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.依頼NO IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送NO IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.受注タイプ名 IS '受注タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.組織名 IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.受注日 IS '受注日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.最新フラグ IS '最新フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.元依頼NO IS '元依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.前回配送NO IS '前回配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.顧客 IS '顧客'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.顧客名 IS '顧客名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.取引先 IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.取引先名 IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.取引先サイト IS '取引先サイト'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.取引先サイト名 IS '取引先サイト名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷指示 IS '出荷指示'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者 IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者名 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分 IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分名 IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.価格表 IS '価格表'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.価格表名 IS '価格表名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.ステータス IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.ステータス名 IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷予定日 IS '出荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷予定日 IS '着荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運賃区分 IS '運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運賃区分名 IS '運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.支給出庫指示区分 IS '支給出庫指示区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.支給出庫指示区分名 IS '支給出庫指示区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.支給指示受領区分 IS '支給指示受領区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.支給指示受領区分名 IS '支給指示受領区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.有償金額確定区分 IS '有償金額確定区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.有償金額確定区分名 IS '有償金額確定区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.引取区分 IS '引取区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.引取区分名 IS '引取区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷元保管場所 IS '出荷元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷元保管場所名 IS '出荷元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.入力拠点 IS '入力拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.入力拠点名 IS '入力拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.入力拠点略称 IS '入力拠点略称'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.発注NO IS '発注No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.契約外運賃区分 IS '契約外運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.契約外運賃区分名 IS '契約外運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷時間FROM IS '着荷時間FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷時間FROM名 IS '着荷時間FROM名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷時間TO IS '着荷時間TO'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷時間TO名 IS '着荷時間TO名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.製造品目 IS '製造品目'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.製造品目名 IS '製造品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.製造日 IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.製造枝番 IS '製造枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.送り状NO IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.合計数量 IS '合計数量'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.小口個数 IS '小口個数'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.ラベル枚数 IS 'ラベル枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.重量積載効率 IS '重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.容積積載効率 IS '容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.基本重量 IS '基本重量'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.基本容積 IS '基本容積'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.積載重量合計 IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.積載容積合計 IS '積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.混載率 IS '混載率'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.パレット合計枚数 IS 'パレット合計枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.パレット実績枚数 IS 'パレット実績枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.合計パレット重量 IS '合計パレット重量'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者_実績 IS '運送業者_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者_予実 IS '運送業者_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者_実績名 IS '運送業者_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.運送業者_予実名 IS '運送業者_予実名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分_実績 IS '配送区分_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分_予実 IS '配送区分_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分_実績名 IS '配送区分_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送区分_予実名 IS '配送区分_予実名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷日 IS '出荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.出荷日_予実 IS '出荷日_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷日 IS '着荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.着荷日_予実 IS '着荷日_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.重量容積区分 IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.重量容積区分名 IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.実績計上済区分 IS '実績計上済区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.通知ステータス IS '通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.通知ステータス名 IS '通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.前回通知ステータス IS '前回通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.前回通知ステータス名 IS '前回通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.確定通知実施日時 IS '確定通知実施日時'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.新規修正フラグ IS '新規修正フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.新規修正フラグ名 IS '新規修正フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.成績管理部署 IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.成績管理部署名 IS '成績管理部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.指示部署 IS '指示部署'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.指示部署名 IS '指示部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.混載記号 IS '混載記号'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.画面更新日時 IS '画面更新日時'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.画面更新者 IS '画面更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_処理種別 IS '配送_処理種別'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_処理種別名 IS '配送_処理種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_混載種別 IS '配送_混載種別'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_混載種別名 IS '配送_混載種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_配送先コード区分 IS '配送_配送先コード区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_配送先コード区分名 IS '配送_配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_自動配車対象区分 IS '配送_自動配車対象区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_自動配車対象区分名 IS '配送_自動配車対象区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_摘要 IS '配送_摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_支払運賃計算対象フラグ IS '配送_支払運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_支払運賃計算対象フラグ名 IS '配送_支払運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_請求運賃計算対象フラグ IS '配送_請求運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_請求運賃計算対象フラグ名 IS '配送_請求運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_積載重量合計 IS '配送_積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_積載容積合計 IS '配送_積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_重量積載効率 IS '配送_重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_容積積載効率 IS '配送_容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_運賃形態 IS '配送_運賃形態'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.配送_運賃形態名 IS '配送_運賃形態名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給ヘッダ_基本_V.最終更新ログイン IS '最終更新ログイン'
/
