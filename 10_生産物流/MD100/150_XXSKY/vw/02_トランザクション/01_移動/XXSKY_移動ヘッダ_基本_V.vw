CREATE OR REPLACE VIEW APPS.XXSKY_移動ヘッダ_基本_V
(
 移動番号
,移動タイプ
,移動タイプ名
,配送NO
,入力日
,指示部署
,指示部署名
,ステータス
,ステータス名
,通知ステータス
,通知ステータス名
,出庫元保管場所
,出庫元保管場所名
,入庫先保管場所
,入庫先保管場所名
,出庫予定日
,入庫予定日
,運賃区分
,運賃区分名
,パレット回収枚数
,パレット枚数_出
,パレット枚数_入
,契約外運賃区分
,契約外運賃区分名
,移動_摘要
,積載率_重量
,積載率_容積
,組織名
,運送業者
,運送業者名
,配送区分
,配送区分名
,運送業者_実績
,運送業者名_実績
,配送区分_実績
,配送区分名_実績
,運送業者_予実
,運送業者名_予実
,配送区分_予実
,配送区分名_予実
,着荷時間FROM
,着荷時間FROM名
,着荷時間TO
,着荷時間TO名
,送り状NO
,合計数量
,小口個数
,ラベル枚数
,基本重量
,基本容積
,積載重量合計
,積載容積合計
,合計パレット重量
,パレット合計枚数
,混載率
,重量容積区分
,重量容積区分名
,出庫実績日
,出庫日_予実
,入庫実績日
,入庫日_予実
,混載記号
,手配No
,商品区分
,商品区分名
,製品識別区分
,製品識別区分名
,指示なし実績区分
,実績計上済フラグ
,実績計上済フラグ名
,実績訂正フラグ
,実績訂正フラグ名
,前回通知ステータス
,前回通知ステータス名
,確定通知実施日時
,前回配送NO
,新規修正フラグ
,新規修正フラグ名
,画面更新者
,画面更新日時
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
,配送_積載重量合計_配車
,配送_積載容積合計_配車
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
SELECT  XMRIH.mov_num                      --移動番号
       ,XMRIH.mov_type                     --移動タイプ
       ,FLV01.meaning                      --移動タイプ名
       ,XMRIH.delivery_no                  --配送No
       ,XMRIH.entered_date                 --入力日
       ,XMRIH.instruction_post_code        --指示部署
       ,XLV.location_name                  --指示部署名
       ,XMRIH.status                       --ステータス
       ,FLV02.meaning                      --ステータス名
       ,XMRIH.notif_status                 --通知ステータス
       ,FLV03.meaning                      --通知ステータス名
       ,XMRIH.shipped_locat_code           --出庫元保管場所
       ,XILV1.description                  --出庫元保管場所名
       ,XMRIH.ship_to_locat_code           --入庫先保管場所
       ,XILV2.description                  --入庫先保管場所名
       ,XMRIH.schedule_ship_date           --出庫予定日
       ,XMRIH.schedule_arrival_date        --入庫予定日
       ,XMRIH.freight_charge_class         --運賃区分
       ,FLV04.meaning                      --運賃区分名
       ,XMRIH.collected_pallet_qty         --パレット回収枚数
       ,XMRIH.out_pallet_qty               --パレット枚数_出
       ,XMRIH.in_pallet_qty                --パレット枚数_入
       ,XMRIH.no_cont_freight_class        --契約外運賃区分
       ,FLV05.meaning                      --契約外運賃区分名
       ,XMRIH.description                  --移動_摘要
       ,CEIL( XMRIH.loading_efficiency_weight * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_weight          --積載率_重量
       ,CEIL( XMRIH.loading_efficiency_capacity * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_capacity        --積載率_容積
       ,HAOUT.name                         --組織名
       ,XMRIH.freight_carrier_code         --運送業者
       ,XCV1.party_name                    --運送業者名
       ,XMRIH.shipping_method_code         --配送区分
       ,FLV06.meaning                      --配送区分名
       ,XMRIH.actual_freight_carrier_code  --運送業者_実績
       ,XCV2.party_name                    --運送業者名_実績
       ,XMRIH.actual_shipping_method_code  --配送区分_実績
       ,FLV07.meaning                      --配送区分名_実績
       ,NVL( XMRIH.actual_freight_carrier_code, XMRIH.freight_carrier_code )      --NVL( 運送業者_実績, 運送業者 )
             yj_freight_carrier_code       --運送業者_予実
       ,CASE WHEN XMRIH.actual_freight_carrier_code IS NULL THEN XCV1.party_name  --運送業者_実績が存在しない場合は運送業者名
             ELSE                                                XCV2.party_name  --運送業者_実績が存在する場合は運送業者名_実績
        END  yj_freight_carrier_name       --運送業者名_予実
       ,NVL(  XMRIH.actual_shipping_method_code, XMRIH.shipping_method_code )     --NVL( 配送区分_実績, 配送区分 )
                                           --配送区分_予実
       ,CASE WHEN XMRIH.actual_shipping_method_code IS NULL THEN FLV06.meaning    --配送区分_実績が存在しない場合は配送区分名
             ELSE                                                FLV07.meaning    --配送区分実績が存在する場合は配送区分名_実績
        END                                --配送区分名_予実
       ,XMRIH.arrival_time_from            --着荷時間FROM
       ,FLV08.meaning                      --着荷時間FROM名
       ,XMRIH.arrival_time_to              --着荷時間TO
       ,FLV09.meaning                      --着荷時間TO名
       ,XMRIH.slip_number                  --送り状No
       ,XMRIH.sum_quantity                 --合計数量
       ,XMRIH.small_quantity               --小口個数
       ,XMRIH.label_quantity               --ラベル枚数
       ,CEIL(XMRIH.based_weight)
        based_weight                       --基本重量
       ,CEIL(XMRIH.based_capacity)
        based_capacity                     --基本容積
-- 2010/1/7 #627 Y.FUkami Mod Start
--       ,CEIL(XMRIH.sum_weight)
       ,CEIL(TRUNC(NVL(XMRIH.sum_weight,0),1))     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/7 #627 Y.FUkami Mod End
        sum_weight                         --積載重量合計
       ,CEIL(XMRIH.sum_capacity)
        sum_capacity                       --積載容積合計
       ,XMRIH.sum_pallet_weight            --合計パレット重量
       ,XMRIH.pallet_sum_quantity          --パレット合計枚数
       ,CEIL( XMRIH.mixed_ratio * 100 ) / 100  --少数点弟３以下切り上げ
        mixed_ratio                        --混載率
       ,XMRIH.weight_capacity_class        --重量容積区分
       ,FLV10.meaning                      --重量容積区分名
       ,XMRIH.actual_ship_date             --出庫実績日
       ,NVL( XMRIH.actual_ship_date, XMRIH.schedule_ship_date )        --NVL( 出荷日, 出荷予定日 )
             yj_shipped_date               --出庫日_予実
       ,XMRIH.actual_arrival_date          --入庫実績日
       ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )  --NVL( 着荷日, 着荷予定日 )
             yj_arrival_date               --入庫日_予実
       ,XMRIH.mixed_sign                   --混載記号
       ,XMRIH.batch_no                     --手配No
       ,XMRIH.item_class                   --商品区分
       ,FLV11.meaning                      --商品区分名
       ,XMRIH.product_flg                  --製品識別区分
       ,FLV12.meaning                      --製品識別区分名
       ,XMRIH.no_instr_actual_class        --指示なし実績区分
       ,XMRIH.comp_actual_flg              --実績計上済フラグ
       ,FLV13.meaning                      --実績計上済フラグ名
       ,XMRIH.correct_actual_flg           --実績訂正フラグ
       ,FLV14.meaning                      --実績訂正フラグ名
       ,XMRIH.prev_notif_status            --前回通知ステータス
       ,FLV15.meaning                      --前回通知ステータス名
       ,TO_CHAR( XMRIH.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                           --確定通知実施日時
       ,XMRIH.prev_delivery_no             --前回配送No
       ,XMRIH.new_modify_flg               --新規修正フラグ
       ,FLV16.meaning                      --新規修正フラグ名
       ,FU_SU.user_name                    --画面更新者のユーザー名
       ,TO_CHAR( XMRIH.screen_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --画面更新日時
       ,XCS.transaction_type               --配送_処理種別
       ,FLV17.meaning                      --配送_処理種別名
       ,XCS.mixed_type                     --配送_混載種別
       ,DECODE(XCS.mixed_type ,'1','集約'  ,'2','混載')
        mixed_name                         --配送_混載種別名
       ,XCS.deliver_to_code_class          --配送_配送先コード区分
       ,FLV18.meaning                      --配送_配送先コード区分名
       ,XCS.auto_process_type              --配送_自動配車対象区分
       ,FLV19.meaning                      --配送_自動配車対象区分名
       ,XCS.description                    --配送_摘要
       ,XCS.payment_freight_flag           --配送_支払運賃計算対象フラグ
       ,DECODE(XCS.payment_freight_flag ,'1','対象'  ,'対象外')
        payment_freight_flg_name           --配送_支払運賃計算対象フラグ名
       ,XCS.demand_freight_flag            --配送_請求運賃計算対象フラグ
       ,DECODE(XCS.demand_freight_flag  ,'1','対象'  ,'対象外')
        demand_freight_flg_name            --配送_請求運賃計算対象フラグ名
-- 2010/1/7 #627 Y.FUkami Mod Start
--       ,CEIL(XCS.sum_loading_weight)
       ,CEIL(TRUNC(NVL(XCS.sum_loading_weight,0),1))     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/7 #627 Y.FUkami Mod End
        sum_loading_weight                 --配送_積載重量合計_配車
       ,CEIL(XCS.sum_loading_capacity)
        sum_loading_capacity               --配送_積載容積合計_配車
       ,CEIL( XCS.loading_efficiency_weight * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_weight          --配送_重量積載効率
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100  --少数点弟３以下切り上げ
        loading_efficiency_capacity        --配送_容積積載効率
       ,XCS.freight_charge_type            --配送_運賃形態
       ,FLV20.meaning                      --配送_運賃形態名
       ,FU_CB.user_name                    --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XMRIH.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --作成日時
       ,FU_LU.user_name                    --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XMRIH.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --更新日時
       ,FU_LL.user_name                    --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  xxinv_mov_req_instr_headers  XMRIH --移動依頼/指示ヘッダアドオン
       ,xxwsh_carriers_schedule      XCS   --配車配送計画アドオン
       ,xxsky_locations2_v           XLV   --SKYLINK用中間VIEW 事業所情報VIEW
       ,xxsky_item_locations2_v      XILV1 --SKYLINK用中間VIEW OPM保管場所情報VIEW(出庫元保管場所名取得用)
       ,xxsky_item_locations2_v      XILV2 --SKYLINK用中間VIEW OPM保管場所情報VIEW(入庫先保管場所名取得用)
       ,hr_all_organization_units_tl HAOUT --
       ,xxsky_carriers2_v            XCV1  --SKYLINK用中間VIEW 運送業者情報VIEW(運送業者名取得用)
       ,xxsky_carriers2_v            XCV2  --SKYLINK用中間VIEW 運送業者情報VIEW(運送業者名_実績取得用)
       ,fnd_lookup_values            FLV01 --クイックコード(移動タイプ名)
       ,fnd_lookup_values            FLV02 --クイックコード(ステータス名)
       ,fnd_lookup_values            FLV03 --クイックコード(通知ステータス名)
       ,fnd_lookup_values            FLV04 --クイックコード(運賃区分名)
       ,fnd_lookup_values            FLV05 --クイックコード(契約外運賃区分名)
       ,fnd_lookup_values            FLV06 --クイックコード(配送区分名)
       ,fnd_lookup_values            FLV07 --クイックコード(配送区分名_実績)
       ,fnd_lookup_values            FLV08 --クイックコード(着荷時間FROM名)
       ,fnd_lookup_values            FLV09 --クイックコード(着荷時間TO名)
       ,fnd_lookup_values            FLV10 --クイックコード(重量容積区分名)
       ,fnd_lookup_values            FLV11 --クイックコード(商品区分名)
       ,fnd_lookup_values            FLV12 --クイックコード(製品識別区分名)
       ,fnd_lookup_values            FLV13 --クイックコード(実績計上済フラグ名)
       ,fnd_lookup_values            FLV14 --クイックコード(実績訂正フラグ名)
       ,fnd_lookup_values            FLV15 --クイックコード(前回通知ステータス名)
       ,fnd_lookup_values            FLV16 --クイックコード(新規修正フラグ名)
       ,fnd_lookup_values            FLV17 --クイックコード(配送_処理種別名)
       ,fnd_lookup_values            FLV18 --クイックコード(配送_配送先コード区分名)
       ,fnd_lookup_values            FLV19 --クイックコード(配送_自動配車対象区分名)
       ,fnd_lookup_values            FLV20 --クイックコード(配送_運賃形態名)
       ,fnd_user                     FU_SU --ユーザーマスタ(画面更新者名取得用)
       ,fnd_user                     FU_CB --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                     FU_LU --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                     FU_LL --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                   FL_LL --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XMRIH.delivery_no = XCS.delivery_no(+)
   --指示部署名取得
   AND  XMRIH.instruction_post_code        = XLV.location_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XLV.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XLV.end_date_active(+)
   --出庫元保管場所名取得
   AND  XMRIH.shipped_locat_id             = XILV1.inventory_location_id(+)
   --入庫先保管場所名取得
   AND  XMRIH.ship_to_locat_id             = XILV2.inventory_location_id(+)
   --組織名取得
   AND  XMRIH.organization_id              = HAOUT.organization_id(+)
   AND  HAOUT.language(+)                  = 'JA'
   --運送業者名取得
   AND  XMRIH.freight_carrier_code         = XCV1.freight_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XCV1.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XCV1.end_date_active(+)
   --運送業者名_実績取得
   AND  XMRIH.actual_freight_carrier_code  = XCV2.freight_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XCV2.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XCV2.end_date_active(+)
   --クイックコード：移動タイプ名取得
   AND  FLV01.language(+) = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_MOVE_TYPE'
   AND  FLV01.lookup_code(+) = XMRIH.mov_type
   --クイックコード：ステータス名取得
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXINV_MOVE_STATUS'
   AND  FLV02.lookup_code(+) = XMRIH.status
   --クイックコード：通知ステータス名取得
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV03.lookup_code(+) = XMRIH.notif_status
   --クイックコード：運賃区分名取得
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXINV_PRESENCE_CLASS'
   AND  FLV04.lookup_code(+) = XMRIH.freight_charge_class
   --クイックコード：契約外運賃区分名取得
   AND  FLV05.language(+) = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV05.lookup_code(+) = XMRIH.no_cont_freight_class
   --クイックコード：配送区分名取得
   AND  FLV06.language(+) = 'JA'
   AND  FLV06.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV06.lookup_code(+) = XMRIH.shipping_method_code
   --クイックコード：配送区分名_実績取得
   AND  FLV07.language(+) = 'JA'
   AND  FLV07.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV07.lookup_code(+) = XMRIH.actual_shipping_method_code
   --クイックコード：着荷時間FROM名取得
   AND  FLV08.language(+) = 'JA'
   AND  FLV08.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV08.lookup_code(+) = XMRIH.arrival_time_from
   --クイックコード：着荷時間TO名取得
   AND  FLV09.language(+) = 'JA'
   AND  FLV09.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV09.lookup_code(+) = XMRIH.arrival_time_to
   --クイックコード：重量容積区分名取得
   AND  FLV10.language(+) = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV10.lookup_code(+) = XMRIH.weight_capacity_class
   --クイックコード：商品区分名取得
   AND  FLV11.language(+) = 'JA'
   AND  FLV11.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV11.lookup_code(+) = XMRIH.item_class
   --クイックコード：製品識別区分名取得
   AND  FLV12.language(+) = 'JA'
   AND  FLV12.lookup_type(+) = 'XXINV_PRODUCT_CLASS'
   AND  FLV12.lookup_code(+) = XMRIH.product_flg
   --クイックコード：実績計上済フラグ名取得
   AND  FLV13.language(+) = 'JA'
   AND  FLV13.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV13.lookup_code(+) = XMRIH.comp_actual_flg
   --クイックコード：実績訂正フラグ名取得
   AND  FLV14.language(+) = 'JA'
   AND  FLV14.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV14.lookup_code(+) = XMRIH.correct_actual_flg
   --クイックコード：前回通知ステータス名取得
   AND  FLV15.language(+) = 'JA'
   AND  FLV15.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV15.lookup_code(+) = XMRIH.prev_notif_status
   --クイックコード：新規修正フラグ名取得
   AND  FLV16.language(+) = 'JA'
   AND  FLV16.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV16.lookup_code(+) = XMRIH.new_modify_flg
   --クイックコード：配送_処理種別名取得
   AND  FLV17.language(+) = 'JA'
   AND  FLV17.lookup_type(+) = 'XXWSH_PROCESS_TYPE'
   AND  FLV17.lookup_code(+) = XCS.transaction_type
   --クイックコード：配送_配送先コード区分名取得
   AND  FLV18.language(+) = 'JA'
   AND  FLV18.lookup_type(+) = 'CUSTOMER CLASS'
   AND  FLV18.lookup_code(+) = XCS.deliver_to_code_class
   --クイックコード：配送_自動配車対象区分名取得
   AND  FLV19.language(+) = 'JA'
   AND  FLV19.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV19.lookup_code(+) = XCS.auto_process_type
   --クイックコード：配送_運賃形態名取得
   AND  FLV20.language(+) = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV20.lookup_code(+) = XCS.freight_charge_type
   --画面更新者名取得
   AND  XMRIH.screen_update_by = FU_SU.user_id(+)
   --WHOカラム取得
   AND  XMRIH.created_by = FU_CB.user_id(+)
   AND  XMRIH.last_updated_by = FU_LU.user_id(+)
   AND  XMRIH.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_移動ヘッダ_基本_V IS 'SKYLINK用移動ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.移動番号                       IS '移動番号'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.移動タイプ                     IS '移動タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.移動タイプ名                   IS '移動タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送NO                         IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入力日                         IS '入力日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.指示部署                       IS '指示部署'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.指示部署名                     IS '指示部署名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.ステータス                     IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.ステータス名                   IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.通知ステータス                 IS '通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.通知ステータス名               IS '通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.出庫元保管場所                 IS '出庫元保管場所'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.出庫元保管場所名               IS '出庫元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入庫先保管場所                 IS '入庫先保管場所'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入庫先保管場所名               IS '入庫先保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.出庫予定日                     IS '出庫予定日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入庫予定日                     IS '入庫予定日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運賃区分                       IS '運賃区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運賃区分名                     IS '運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.パレット回収枚数               IS 'パレット回収枚数'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.パレット枚数_出                IS 'パレット枚数_出'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.パレット枚数_入                IS 'パレット枚数_入'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.契約外運賃区分                 IS '契約外運賃区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.契約外運賃区分名               IS '契約外運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.移動_摘要                      IS '移動_摘要'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.積載率_重量                    IS '積載率_重量'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.積載率_容積                    IS '積載率_容積'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.組織名                         IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者                       IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者名                     IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分                       IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分名                     IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者_実績                  IS '運送業者_実績'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者名_実績                IS '運送業者名_実績'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分_実績                  IS '配送区分_実績'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分名_実績                IS '配送区分名_実績'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者_予実                  IS '運送業者_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.運送業者名_予実                IS '運送業者名_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分_予実                  IS '配送区分_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送区分名_予実                IS '配送区分名_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.着荷時間FROM                   IS '着荷時間FROM'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.着荷時間FROM名                 IS '着荷時間FROM名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.着荷時間TO                     IS '着荷時間TO'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.着荷時間TO名                   IS '着荷時間TO名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.送り状NO                       IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.合計数量                       IS '合計数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.小口個数                       IS '小口個数'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.ラベル枚数                     IS 'ラベル枚数'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.基本重量                       IS '基本重量'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.基本容積                       IS '基本容積'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.積載重量合計                   IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.積載容積合計                   IS '積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.合計パレット重量               IS '合計パレット重量'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.パレット合計枚数               IS 'パレット合計枚数'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.混載率                         IS '混載率'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.重量容積区分                   IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.重量容積区分名                 IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.出庫実績日                     IS '出庫実績日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.出庫日_予実                    IS '出庫日_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入庫実績日                     IS '入庫実績日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.入庫日_予実                    IS '入庫日_予実'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.混載記号                       IS '混載記号'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.手配NO                         IS '手配No'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.製品識別区分                   IS '製品識別区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.製品識別区分名                 IS '製品識別区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.指示なし実績区分               IS '指示なし実績区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.実績計上済フラグ               IS '実績計上済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.実績計上済フラグ名             IS '実績計上済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.実績訂正フラグ                 IS '実績訂正フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.実績訂正フラグ名               IS '実績訂正フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.前回通知ステータス             IS '前回通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.前回通知ステータス名           IS '前回通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.確定通知実施日時               IS '確定通知実施日時'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.前回配送No                     IS '前回配送No'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.新規修正フラグ                 IS '新規修正フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.新規修正フラグ名               IS '新規修正フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.画面更新者                     IS '画面更新者'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.画面更新日時                   IS '画面更新日時'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_処理種別                  IS '配送_処理種別'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_処理種別名                IS '配送_処理種別名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_混載種別                  IS '配送_混載種別'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_混載種別名                IS '配送_混載種別名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_配送先コード区分          IS '配送_配送先コード区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_配送先コード区分名        IS '配送_配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_自動配車対象区分          IS '配送_自動配車対象区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_自動配車対象区分名        IS '配送_自動配車対象区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_摘要                      IS '配送_摘要'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_支払運賃計算対象フラグ    IS '配送_支払運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_支払運賃計算対象フラグ名  IS '配送_支払運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_請求運賃計算対象フラグ    IS '配送_請求運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_請求運賃計算対象フラグ名  IS '配送_請求運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_積載重量合計_配車         IS '配送_積載重量合計_配車'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_積載容積合計_配車         IS '配送_積載容積合計_配車'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_重量積載効率              IS '配送_重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_容積積載効率              IS '配送_容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_運賃形態                  IS '配送_運賃形態'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.配送_運賃形態名                IS '配送_運賃形態名'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.作成者                         IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.作成日                         IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.最終更新者                     IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.最終更新日                     IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_移動ヘッダ_基本_V.最終更新ログイン               IS '最終更新ログイン'
/
