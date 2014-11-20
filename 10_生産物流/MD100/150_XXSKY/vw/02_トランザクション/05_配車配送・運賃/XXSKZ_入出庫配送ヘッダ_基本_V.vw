/*************************************************************************
 * 
 * View  Name      : XXSKZ_入出庫配送ヘッダ_基本_V
 * Description     : XXSKZ_入出庫配送ヘッダ_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_入出庫配送ヘッダ_基本_V
(
 依頼_移動NO
,配送NO
,タイプ
,移動タイプ
,移動タイプ名
,組織名
,受注_入力日
,最新フラグ
,元依頼NO
,前回配送NO
,顧客
,顧客名
,出荷_入庫先
,出荷_入庫先名
,出荷指示
,取引先
,取引先名
,取引先サイト
,取引先サイト名
,運送業者
,運送業者名
,配送区分
,配送区分名
,顧客発注
,価格表
,価格表名
,ステータス
,ステータス名
,出荷_出庫予定日
,着荷_入庫予定日
,混載元NO
,パレット回収枚数
,パレット枚数_出
,パレット枚数_入
,移動_摘要
,物流担当確認依頼区分
,物流担当確認依頼区分名
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
,出荷_出庫元保管場所
,出荷_出庫元保管場所名
,管轄拠点
,管轄拠点名
,管轄拠点略称
,入力拠点
,入力拠点名
,入力拠点略称
,発注NO
,商品区分
,商品区分名
,品目区分
,品目区分名
,製品識別区分
,製品識別区分名
,指示なし実績区分
,契約外運賃区分
,契約外運賃区分名
,着荷時間FROM
,着荷時間FROM名
,着荷時間TO
,着荷時間TO名
,製造品目
,製造品目名
,製造品目略称
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
,出荷先_実績
,出荷先_予実
,出荷先_実績名
,出荷先_予実名
,出荷_出庫日
,出荷_出庫日_予実
,着荷_入庫日
,着荷_入庫日_予実
,重量容積区分
,重量容積区分名
,実績計上済区分
,実績訂正フラグ
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
,振替先
,振替先名
,混載記号
,手配NO
,画面更新日時
,画面更新者
,出荷依頼締め日時
,締めコンカレントID
,締め後修正区分
,締め後修正区分名
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
        SPMH.request_no                                     request_no                    --依頼_移動No
       ,SPMH.delivery_no                                    delivery_no                   --配送No
       ,SPMH.type                                           type                          --タイプ
       ,SPMH.mov_type                                       mov_type                      --移動タイプ
       ,SPMH.mov_type_name                                  mov_type_name                 --移動タイプ名
       ,HAOUT.name                                          org_name                      --組織名
       ,SPMH.ordered_date                                   ordered_date                  --受注入力日
       ,SPMH.latest_external_flag                           latest_external_flag          --最新フラグ
       ,SPMH.base_request_no                                base_request_no               --元依頼No
       ,SPMH.prev_delivery_no                               prev_delivery_no              --前回配送No
       ,CUST1.party_number                                  customer_code                 --顧客
       ,CUST1.party_name                                    customer_name                 --顧客名
       ,SPMH.deliver_to                                     deliver_to                    --出荷_入庫先
       ,SPMH.deliver_to_name                                deliver_to_name               --出荷_入庫先名
       ,SPMH.shipping_instructions                          shipping_instructions         --出荷指示
       ,SPMH.vendor_code                                    vendor_code                   --取引先
       ,SPMH.vendor_name                                    vendor_name                   --取引先名
       ,SPMH.vendor_site_code                               vendor_site_code              --取引先サイト
       ,SPMH.vendor_site_name                               vendor_site_name              --取引先サイト名
       ,CARR1.freight_code                                  carrier_code                  --運送業者
       ,CARR1.party_name                                    carrier_name                  --運送業者名
       ,SPMH.shipping_method_code                           shipping_method_code          --配送区分
       ,FLV02.meaning                                       shipping_method_name          --配送区分名
       ,SPMH.cust_po_number                                 cust_po_number                --顧客発注
       ,SPMH.price_list_id                                  price_list_id                 --価格表
       ,QLHT.name                                           price_list_name               --価格表名
       ,SPMH.status                                         status                        --ステータス
       ,SPMH.status_name                                    status_name                   --ステータス名
       ,SPMH.schedule_ship_date                             schedule_ship_date            --出荷_出庫予定日
       ,SPMH.schedule_arrival_date                          schedule_arrival_date         --着荷_入庫予定日
       ,SPMH.mixed_no                                       mixed_no                      --混載元No
       ,SPMH.collected_pallet_qty                           collected_pallet_qty          --パレット回収枚数
       ,SPMH.out_pallet_qty                                 out_pallet_qty                --パレット枚数_出
       ,SPMH.in_pallet_qty                                  in_pallet_qty                 --パレット枚数_入
       ,SPMH.mov_description                                mov_description               --移動_摘要
       ,SPMH.confirm_request_class                          confirm_request_class         --物流担当確認依頼区分
       ,FLV03.meaning                                       confirm_request_class_name    --物流担当確認依頼区分
       ,SPMH.freight_charge_class                           freight_charge_class          --運賃区分
       ,FLV04.meaning                                       freight_charge_class          --運賃区分名
       ,SPMH.shikyu_instruction_class                       shikyu_instruction_class      --支給出庫指示区分
       ,FLV05.meaning                                       shikyu_instruction_class_name --支給出庫指示区分名
       ,SPMH.shikyu_inst_rcv_class                          shikyu_inst_rcv_class         --支給指示受領区分
       ,FLV06.meaning                                       shikyu_inst_rcv_class_name    --支給指示受領区分名
       ,SPMH.amount_fix_class                               amount_fix_class              --有償金額確定区分
       ,FLV07.meaning                                       amount_fix_class_name         --有償金額確定区分名
       ,SPMH.takeback_class                                 takeback_class                --引取区分
       ,FLV08.meaning                                       takeback_class_name           --引取区分名
       ,ILCT1.segment1                                      deliver_from                  --出荷_出庫元保管場所
       ,ILCT1.description                                   deliver_from_name             --出荷_出庫元保管場所名
       ,SPMH.head_sales_branch                              head_sales_branch             --管轄拠点
       ,CUST2.party_name                                    head_sales_branch_name        --管轄拠点名
       ,CUST2.party_short_name                              head_sales_branch_s_name      --管轄拠点略称
       ,SPMH.input_sales_branch                             input_sales_branch            --入力拠点
       ,CUST3.party_name                                    input_sales_branch_name       --入力拠点名
       ,CUST3.party_short_name                              input_sales_branch_s_name     --入力拠点略称
       ,SPMH.po_no                                          po_no                         --発注No
       ,SPMH.prod_class                                     prod_class                    --商品区分
       ,FLV09.meaning                                       prod_class_name               --商品区分名
       ,SPMH.item_class                                     item_class                    --品目区分
       ,FLV10.meaning                                       item_class_name               --品目区分名
       ,SPMH.product_flg                                    product_flg                   --製品識別区分
       ,FLV11.meaning                                       product_flg_name              --製品識別区分名
       ,SPMH.no_instr_actual_class                          no_instr_actual_class         --指示なし実績区分
       ,SPMH.no_cont_freight_class                          no_cont_freight_class         --契約外運賃区分
       ,FLV12.meaning                                       no_cont_freight_class_name    --契約外運賃区分名
       ,SPMH.arrival_time_from                              arrival_time_from             --着荷時間FROM
       ,FLV13.meaning                                       arrival_time_from_name        --着荷時間FROM名
       ,SPMH.arrival_time_to                                arrival_time_to               --着荷時間TO
       ,FLV14.meaning                                       arrival_time_to_name          --着荷時間TO名
       ,ITEM.item_no                                        designated_item_code          --製造品目
       ,ITEM.item_name                                      designated_item_name          --製造品目名
       ,ITEM.item_short_name                                designated_item_s_name        --製造品目略称
       ,SPMH.designated_production_date                     designated_production_date    --製造日
       ,SPMH.designated_branch_no                           designated_branch_no          --製造枝番
       ,SPMH.slip_number                                    slip_number                   --送り状No
       ,SPMH.sum_quantity                                   sum_quantity                  --合計数量
       ,SPMH.small_quantity                                 small_quantity                --小口個数
       ,SPMH.label_quantity                                 label_quantity                --ラベル枚数
       ,CEIL( SPMH.loading_efficiency_weight   * 100 ) / 100    --少数点弟３以下切り上げ
                                                            loading_efficiency_weight     --重量積載効率
       ,CEIL( SPMH.loading_efficiency_capacity * 100 ) / 100    --少数点弟３以下切り上げ
                                                            loading_efficiency_capacity   --容積積載効率
       ,CEIL( SPMH.based_weight )                           based_weight                  --基本重量
       ,CEIL( SPMH.based_capacity )                         based_capacity                --基本容積
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( SPMH.sum_weight )                             sum_weight                    --積載重量合計
       ,CEIL( TRUNC(NVL(SPMH.sum_weight,0),1) )             sum_weight                    --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( SPMH.sum_capacity )                           sum_capacity                  --積載容積合計
       ,CEIL( SPMH.mixed_ratio                 * 100 ) / 100    --少数点弟３以下切り上げ
                                                            mixed_ratio                   --混載率
       ,SPMH.pallet_sum_quantity                            pallet_sum_quantity           --パレット合計枚数
       ,SPMH.real_pallet_quantity                           real_pallet_quantity          --パレット実績枚数
       ,SPMH.sum_pallet_weight                              sum_pallet_weight             --合計パレット重量
       ,CARR2.freight_code                                  result_carrier_code           --運送業者_実績
       ,CARR3.freight_code                                  yj_carrier_code               --運送業者_予実
       ,CARR2.party_name                                    result_carrier_name           --運送業者_実績名
       ,CARR3.party_name                                    yj_carrier_name               --運送業者_予実名
       ,SPMH.result_shipping_method_code                    result_shipping_method_code   --配送区分_実績
       ,SPMH.yj_shipping_method_code                        yj_shipping_method_code       --配送区分_予実
       ,FLV15.meaning                                       result_shipping_method_name   --配送区分_実績名
       ,FLV16.meaning                                       yj_shipping_method_name       --配送区分_予実名
       ,SPMH.result_deliver_to                              result_deliver_to             --出荷先_実績
       ,SPMH.yj_deliver_to                                  yj_deliver_to                 --出荷先_予実
       ,SPMH.result_deliver_to_name                         result_deliver_to_name        --出荷先_実績名
       ,SPMH.yj_deliver_to_name                             yj_deliver_to_name            --出荷先_予実名
       ,SPMH.shipped_date                                   shipped_date                  --出荷_出庫日
       ,SPMH.yj_shipped_date                                yj_shipped_date               --出荷日_予実
       ,SPMH.arrival_date                                   arrival_date                  --着荷_入庫日
       ,SPMH.yj_arrival_date                                yj_arrival_date               --着荷日_予実
       ,SPMH.weight_capacity_class                          weight_capacity_class         --重量容積区分
       ,FLV17.meaning                                       weight_capacity_class_name    --重量容積区分名
       ,SPMH.actual_confirm_class                           actual_confirm_class          --実績計上済区分
       ,SPMH.correct_actual_flg                             correct_actual_flg            --実績訂正フラグ
       ,SPMH.notif_status                                   notif_status                  --通知ステータス
       ,FLV18.meaning                                       notif_status_name             --通知ステータス名
       ,SPMH.prev_notif_status                              prev_notif_status             --前回通知ステータス
       ,FLV19.meaning                                       prev_notif_status_name        --前回通知ステータス名
       ,TO_CHAR( SPMH.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                                            notif_date                    --確定通知実施日時
       ,SPMH.new_modify_flg                                 new_modify_flg                --新規修正フラグ
       ,FLV20.meaning                                       new_modify_flg_name           --新規修正フラグ名
       ,SPMH.performance_management_dept                    performance_manage_dept       --成績管理部署
       ,LOCT1.location_name                                 performance_manage_dept_name  --成績管理部署名
       ,SPMH.instruction_dept                               instruction_dept              --指示部署
       ,LOCT2.location_name                                 instruction_dept_name         --指示部署名
       ,SPMH.transfer_location_code                         transfer_location_code        --振替先
       ,LOCT3.location_name                                 transfer_location_name        --振替先名
       ,SPMH.mixed_sign                                     mixed_sign                    --混載記号
       ,SPMH.batch_no                                       batch_no                      --手配No
       ,TO_CHAR( SPMH.screen_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            screen_update_date            --画面更新日時
       ,FU.user_name                                        screen_update_by              --画面更新者
       ,TO_CHAR( SPMH.tightening_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            tightening_date               --出荷依頼締め日時
       ,SPMH.tightening_program_id                          tightening_program_id         --締めコンカレントID
       ,SPMH.corrected_tighten_class                        corrected_tighten_class       --締め後修正区分
       ,FLV21.meaning                                       corrected_tighten_class_name  --締め後修正区分名
        --配車/配送アドオンデータ
       ,XCS.transaction_type                                transaction_type              --配送_処理種別
       ,FLV22.meaning                                       transaction_type_name         --配送_処理種別名
       ,XCS.mixed_type                                      mixed_type                    --配送_混載種別
       ,DECODE(XCS.mixed_type, '1', '集約', '2', '混載')    mixed_type_name               --配送_混載種別名
       ,XCS.deliver_to_code_class                           deliver_to_code_class         --配送_配送先コード区分
       ,FLV23.meaning                                       deliver_to_code_class_name    --配送_配送先コード区分名
       ,XCS.auto_process_type                               auto_process_type             --配送_自動配車対象区分
       ,FLV24.meaning                                       auto_process_type_name        --配送_自動配車対象区分名
       ,XCS.description                                     cs_description                --配送_摘要
       ,XCS.payment_freight_flag                            payment_freight_flag          --配送_支払運賃計算対象フラグ
       ,DECODE(XCS.payment_freight_flag, '0', '対象外', '1', '対象')
                                                            payment_freight_flag_name     --配送_支払運賃計算対象フラグ名
       ,XCS.demand_freight_flag                             demand_freight_flag           --配送_請求運賃計算対象フラグ
       ,DECODE(XCS.demand_freight_flag , '0', '対象外', '1', '対象')
                                                            demand_freight_flag_name      --配送_請求運賃計算対象フラグ名
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( XCS.sum_loading_weight )                      sum_loading_weight            --配送_積載重量合計
       ,CEIL( TRUNC(NVL(XCS.sum_loading_weight,0),1) )      sum_loading_weight            --配送_積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( XCS.sum_loading_capacity )                    sum_loading_capacity          --配送_積載容積合計
       ,CEIL( XCS.loading_efficiency_weight    * 100 ) / 100    --少数点弟３以下切り上げ
                                                            cs_loading_effc_weight        --配送_重量積載効率
       ,CEIL( XCS.loading_efficiency_capacity  * 100 ) / 100    --少数点弟３以下切り上げ
                                                            cs_loading_effc_capacity      --配送_容積積載効率
       ,XCS.freight_charge_type                             freight_charge_type           --配送_運賃形態
       ,FLV25.meaning                                       freight_charge_type_name      --配送_運賃形態名
        --WHOカラム
       ,FU_CB.user_name                                     created_by                    --作成者
       ,TO_CHAR( SPMH.creation_date     , 'YYYY/MM/DD HH24:MI:SS' )
                                                            creation_date                 --作成日
       ,FU_LU.user_name                                     last_updated_by               --最終更新者
       ,TO_CHAR( SPMH.last_update_date  , 'YYYY/MM/DD HH24:MI:SS' )
                                                            last_update_date              --最終更新日
       ,FU_LL.user_name                                     last_update_login             --最終更新ログイン
  FROM (
         --==========================
         -- 出荷データ
         --==========================
         SELECT
                 XOHA.request_no                            request_no                    --依頼_移動No
                ,XOHA.delivery_no                           delivery_no                   --配送No
                ,OTTT.name                                  type                          --タイプ
                ,NULL                                       mov_type                      --移動タイプ
                ,NULL                                       mov_type_name                 --移動タイプ名
                ,XOHA.organization_id                       organization_id               --組織ID
                ,XOHA.ordered_date                          ordered_date                  --受注_入力日
                ,XOHA.latest_external_flag                  latest_external_flag          --最新フラグ
                ,XOHA.base_request_no                       base_request_no               --元依頼No
                ,XOHA.prev_delivery_no                      prev_delivery_no              --前回配送No
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--                ,XOHA.customer_id                           customer_id                   --顧客ID
                ,CASE WHEN XOHA.result_deliver_to IS NULL THEN PSIT1.party_id   --出荷先実績が存在しない場合は配送先（予定）の顧客ID
                      ELSE                                     PSIT2.party_id   --出荷先実績が存在する場合は配送先（実績）の顧客ID
                 END                                        customer_id                   --顧客ID
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                ,XOHA.deliver_to                            deliver_to                    --出荷_入庫先
                ,PSIT1.party_site_name                      deliver_to_name               --出荷_入庫先名
                ,XOHA.shipping_instructions                 shipping_instructions         --出荷指示
                ,NULL                                       vendor_code                   --取引先
                ,NULL                                       vendor_name                   --取引先名
                ,NULL                                       vendor_site_code              --取引先サイト
                ,NULL                                       vendor_site_name              --取引先サイト名
                ,XOHA.career_id                             career_id                     --運送業者ID
                ,XOHA.shipping_method_code                  shipping_method_code          --配送区分
                ,XOHA.cust_po_number                        cust_po_number                --顧客発注
                ,XOHA.price_list_id                         price_list_id                 --価格表ID
                ,XOHA.req_status                            status                        --ステータス
                ,FLV01.meaning                              status_name                   --ステータス名
                ,XOHA.schedule_ship_date                    schedule_ship_date            --出荷_出庫予定日
                ,XOHA.schedule_arrival_date                 schedule_arrival_date         --着荷_入庫予定日
                ,XOHA.mixed_no                              mixed_no                      --混載元No
                ,XOHA.collected_pallet_qty                  collected_pallet_qty          --パレット回収枚数
                ,NULL                                       out_pallet_qty                --パレット枚数_出
                ,NULL                                       in_pallet_qty                 --パレット枚数_入
                ,NULL                                       mov_description               --移動_摘要
                ,XOHA.confirm_request_class                 confirm_request_class         --物流担当確認依頼区分
                ,XOHA.freight_charge_class                  freight_charge_class          --運賃区分
                ,NULL                                       shikyu_instruction_class      --支給出庫指示区分
                ,NULL                                       shikyu_inst_rcv_class         --支給指示受領区分
                ,NULL                                       amount_fix_class              --有償金額確定区分
                ,NULL                                       takeback_class                --引取区分
                ,XOHA.deliver_from_id                       deliver_from_id               --出荷_出庫元保管場所ID
                ,XOHA.head_sales_branch                     head_sales_branch             --管轄拠点
                ,XOHA.input_sales_branch                    input_sales_branch            --入力拠点
                ,NULL                                       po_no                         --発注No
                ,XOHA.prod_class                            prod_class                    --商品区分
                ,XOHA.item_class                            item_class                    --品目区分
                ,NULL                                       product_flg                   --製品識別区分
                ,NULL                                       no_instr_actual_class         --指示なし実績区分
                ,XOHA.no_cont_freight_class                 no_cont_freight_class         --契約外運賃区分
                ,XOHA.arrival_time_from                     arrival_time_from             --着荷時間FROM
                ,XOHA.arrival_time_to                       arrival_time_to               --着荷時間TO
                ,NULL                                       designated_item_id            --製造品目ID
                ,NULL                                       designated_production_date    --製造日
                ,NULL                                       designated_branch_no          --製造枝番
                ,XOHA.slip_number                           slip_number                   --送り状No
                ,XOHA.sum_quantity                          sum_quantity                  --合計数量
                ,XOHA.small_quantity                        small_quantity                --小口個数
                ,XOHA.label_quantity                        label_quantity                --ラベル枚数
                ,XOHA.loading_efficiency_weight             loading_efficiency_weight     --重量積載効率
                ,XOHA.loading_efficiency_capacity           loading_efficiency_capacity   --容積積載効率
                ,XOHA.based_weight                          based_weight                  --基本重量
                ,XOHA.based_capacity                        based_capacity                --基本容積
                ,XOHA.sum_weight                            sum_weight                    --積載重量合計
                ,XOHA.sum_capacity                          sum_capacity                  --積載容積合計
                ,XOHA.mixed_ratio                           mixed_ratio                   --混載率
                ,XOHA.pallet_sum_quantity                   pallet_sum_quantity           --パレット合計枚数
                ,XOHA.real_pallet_quantity                  real_pallet_quantity          --パレット実績枚数
                ,XOHA.sum_pallet_weight                     sum_pallet_weight             --合計パレット重量
                ,XOHA.result_freight_carrier_id             result_freight_carrier_id     --運送業者_実績
                ,NVL( XOHA.result_freight_carrier_id, XOHA.career_id )                 --NVL( 運送業者_実績ID, 運送業者ID )
                                                            yj_freight_carrier_id         --運送業者_予実ID
                ,XOHA.result_shipping_method_code           result_shipping_method_code   --配送区分_実績
                ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )    --NVL( 配送区分_実績, 配送区分 )
                                                            yj_shipping_method_code       --配送区分_予実
                ,XOHA.result_deliver_to                     result_deliver_to             --出荷先_実績
                ,PSIT2.party_site_name                      result_deliver_to_name        --出荷先_実績名
                ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )                        --NVL( 出荷先実績, 出荷先 )
                                                            yj_deliver_to                 --出荷先_予実
                ,CASE WHEN XOHA.result_deliver_to IS NULL THEN PSIT1.party_site_name   --出荷先実績が存在しない場合は出荷先名
                      ELSE                                     PSIT2.party_site_name   --出荷先実績が存在する場合は出荷先_実績名
                 END                                        yj_deliver_to_name            --出荷先_予実名
                ,XOHA.shipped_date                          shipped_date                  --出荷_出庫日
                ,XOHA.arrival_date                          arrival_date                  --着荷_入庫日
                ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                     --NVL( 出荷日, 出荷予定日 )
                                                            yj_shipped_date               --出荷日_予実
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                  --NVL( 着荷日, 着荷予定日 )
                                                            yj_arrival_date               --着荷日_予実
                ,XOHA.weight_capacity_class                 weight_capacity_class         --重量容積区分
                ,XOHA.actual_confirm_class                  actual_confirm_class          --実績計上済区分
                ,NULL                                       correct_actual_flg            --実績訂正フラグ
                ,XOHA.notif_status                          notif_status                  --通知ステータス
                ,XOHA.prev_notif_status                     prev_notif_status             --前回通知ステータス
                ,XOHA.notif_date                            notif_date                    --確定通知実施日時
                ,XOHA.new_modify_flg                        new_modify_flg                --新規修正フラグ
                ,XOHA.performance_management_dept           performance_management_dept   --成績管理部署
                ,XOHA.instruction_dept                      instruction_dept              --指示部署
                ,XOHA.transfer_location_code                transfer_location_code        --振替先
                ,XOHA.mixed_sign                            mixed_sign                    --混載記号
                ,NULL                                       batch_no                      --手配No
                ,XOHA.screen_update_date                    screen_update_date            --画面更新日時
                ,XOHA.screen_update_by                      screen_update_by              --画面更新者ID
                ,XOHA.tightening_date                       tightening_date               --出荷依頼締め日時
                ,XOHA.tightening_program_id                 tightening_program_id         --締めコンカレントID
                ,XOHA.corrected_tighten_class               corrected_tighten_class       --締め後修正区分
                ,XOHA.created_by                            created_by                    --作成者
                ,XOHA.creation_date                         creation_date                 --作成日
                ,XOHA.last_updated_by                       last_updated_by               --最終更新者
                ,XOHA.last_update_date                      last_update_date              --最終更新日
                ,XOHA.last_update_login                     last_update_login             --最終更新ログイン
           FROM
                 xxcmn_order_headers_all_arc     XOHA       --受注ヘッダ（アドオン）バックアップ
                ,oe_transaction_types_all    OTTA           --受注タイプマスタ
                ,oe_transaction_types_tl     OTTT           --受注タイプマスタ(日本語)
                ,xxskz_party_sites2_v        PSIT1          --SKYLINK用中間VIEW 配送先情報VIEW(出荷_入庫先)
                ,xxskz_party_sites2_v        PSIT2          --SKYLINK用中間VIEW 配送先情報VIEW(出荷先_実績)
                ,fnd_lookup_values           FLV01          --クイックコード(ステータス名)
          WHERE
            --出荷情報の取得
                 OTTA.attribute1             = '1'          --出荷
            AND  XOHA.latest_external_flag   = 'Y'          --最新フラグが有効
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --受注タイプ名取得条件
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --出荷_入庫先名取得
-- *----------* 2009/06/23 本番#1438対応 start *----------*
-- idによる結合ではなくcodeで結合する
--            AND  XOHA.deliver_to_id          = PSIT1.party_site_id(+)
            AND  XOHA.deliver_to             = PSIT1.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= PSIT1.start_date_active(+)  --有効開始日
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= PSIT1.end_date_active(+)    --有効終了日
            --出荷先_実績名取得
-- *----------* 2009/06/23 本番#1438対応 start *----------*
-- idによる結合ではなくcodeで結合する
--            AND  XOHA.result_deliver_to_id   = PSIT2.party_site_id(+)
            AND  XOHA.result_deliver_to   = PSIT2.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= PSIT2.start_date_active(+)  --有効開始日
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= PSIT2.end_date_active(+)    --有効終了日
            --ステータス名取得
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXWSH_TRANSACTION_STATUS'
            AND  FLV01.lookup_code(+)        = XOHA.req_status
         --[ 出荷データ  END ]
        UNION ALL
         --==========================
         -- 支給データ
         --==========================
         SELECT
                 XOHA.request_no                            request_no                    --依頼_移動No
                ,XOHA.delivery_no                           delivery_no                   --配送No
                ,OTTT.name                                  type                          --タイプ
                ,NULL                                       mov_type                      --移動タイプ
                ,NULL                                       mov_type_name                 --移動タイプ名
                ,XOHA.organization_id                       organization_id               --組織ID
                ,XOHA.ordered_date                          ordered_date                  --受注_入力日
                ,XOHA.latest_external_flag                  latest_external_flag          --最新フラグ
                ,XOHA.base_request_no                       base_request_no               --元依頼No
                ,XOHA.prev_delivery_no                      prev_delivery_no              --前回配送No
                ,XOHA.customer_id                           customer_id                   --顧客ID
                ,XOHA.vendor_site_code                      deliver_to                    --出荷_入庫先
                ,VSIT.vendor_site_name                      deliver_to_name               --出荷_入庫先名
                ,XOHA.shipping_instructions                 shipping_instructions         --出荷指示
                ,XOHA.vendor_code                           vendor_code                   --取引先
                ,VNDR.vendor_name                           vendor_code                   --取引先名
                ,XOHA.vendor_site_code                      vendor_site_code              --取引先サイト
                ,VSIT.vendor_site_name                      vendor_site_code              --取引先サイト名
                ,XOHA.career_id                             career_id                     --運送業者ID
                ,XOHA.shipping_method_code                  shipping_method_code          --配送区分
                ,XOHA.cust_po_number                        cust_po_number                --顧客発注
                ,XOHA.price_list_id                         price_list_id                 --価格表ID
                ,XOHA.req_status                            status                        --ステータス
                ,FLV01.meaning                              status_name                   --ステータス名
                ,XOHA.schedule_ship_date                    schedule_ship_date            --出荷_出庫予定日
                ,XOHA.schedule_arrival_date                 schedule_arrival_date         --着荷_入庫予定日
                ,XOHA.mixed_no                              mixed_no                      --混載元No
                ,XOHA.collected_pallet_qty                  collected_pallet_qty          --パレット回収枚数
                ,NULL                                       out_pallet_qty                --パレット枚数_出
                ,NULL                                       in_pallet_qty                 --パレット枚数_入
                ,NULL                                       mov_description               --移動_摘要
                ,XOHA.confirm_request_class                 confirm_request_class         --物流担当確認依頼区分
                ,XOHA.freight_charge_class                  freight_charge_class          --運賃区分
                ,XOHA.shikyu_instruction_class              shikyu_instruction_class      --支給出庫指示区分
                ,XOHA.shikyu_inst_rcv_class                 shikyu_inst_rcv_class         --支給指示受領区分
                ,XOHA.amount_fix_class                      amount_fix_class              --有償金額確定区分
                ,XOHA.takeback_class                        takeback_class                --引取区分
                ,XOHA.deliver_from_id                       deliver_from_id               --出荷_出庫元保管場所ID
                ,XOHA.head_sales_branch                     head_sales_branch             --管轄拠点
                ,XOHA.input_sales_branch                    input_sales_branch            --入力拠点
                ,XOHA.po_no                                 po_no                         --発注No
                ,XOHA.prod_class                            prod_class                    --商品区分
                ,XOHA.item_class                            item_class                    --品目区分
                ,NULL                                       product_flg                   --製品識別区分
                ,NULL                                       no_instr_actual_class         --指示なし実績区分
                ,XOHA.no_cont_freight_class                 no_cont_freight_class         --契約外運賃区分
                ,XOHA.arrival_time_from                     arrival_time_from             --着荷時間FROM
                ,XOHA.arrival_time_to                       arrival_time_to               --着荷時間TO
                ,XOHA.designated_item_code                  designated_item_id            --製造品目ID
                ,XOHA.designated_production_date            designated_production_date    --製造日
                ,XOHA.designated_branch_no                  designated_branch_no          --製造枝番
                ,XOHA.slip_number                           slip_number                   --送り状No
                ,XOHA.sum_quantity                          sum_quantity                  --合計数量
                ,XOHA.small_quantity                        small_quantity                --小口個数
                ,XOHA.label_quantity                        label_quantity                --ラベル枚数
                ,XOHA.loading_efficiency_weight             loading_efficiency_weight     --重量積載効率
                ,XOHA.loading_efficiency_capacity           loading_efficiency_capacity   --容積積載効率
                ,XOHA.based_weight                          based_weight                  --基本重量
                ,XOHA.based_capacity                        based_capacity                --基本容積
                ,XOHA.sum_weight                            sum_weight                    --積載重量合計
                ,XOHA.sum_capacity                          sum_capacity                  --積載容積合計
                ,XOHA.mixed_ratio                           mixed_ratio                   --混載率
                ,XOHA.pallet_sum_quantity                   pallet_sum_quantity           --パレット合計枚数
                ,XOHA.real_pallet_quantity                  real_pallet_quantity          --パレット実績枚数
                ,XOHA.sum_pallet_weight                     sum_pallet_weight             --合計パレット重量
                ,XOHA.result_freight_carrier_id             result_freight_carrier_id     --運送業者_実績ID
                ,NVL( XOHA.result_freight_carrier_id, XOHA.career_id )                 --NVL( 運送業者_実績ID, 運送業者ID )
                                                            yj_freight_carrier_id         --運送業者_予実ID
                ,XOHA.result_shipping_method_code           result_shipping_method_code   --配送区分_実績
                ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )    --NVL( 配送区分_実績, 配送区分 )
                                                            yj_shipping_method_code       --配送区分_予実
                ,XOHA.vendor_site_code                      result_deliver_to             --出荷先_実績
                ,VSIT.vendor_site_name                      result_deliver_to_name        --出荷先_実績名
                ,XOHA.vendor_site_code                      yj_deliver_to                 --出荷先_予実
                ,VSIT.vendor_site_name                      yj_deliver_to_name            --出荷先_予実名
                ,XOHA.shipped_date                          shipped_date                  --出荷_出庫日
                ,XOHA.arrival_date                          arrival_date                  --着荷_入庫日
                ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                     --NVL( 出荷日, 出荷予定日 )
                                                            yj_shipped_date               --出荷日_予実
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                  --NVL( 着荷日, 着荷予定日 )
                                                            yj_arrival_date               --着荷日_予実
                ,XOHA.weight_capacity_class                 weight_capacity_class         --重量容積区分
                ,XOHA.actual_confirm_class                  actual_confirm_class          --実績計上済区分
                ,NULL                                       correct_actual_flg            --実績訂正フラグ
                ,XOHA.notif_status                          notif_status                  --通知ステータス
                ,XOHA.prev_notif_status                     prev_notif_status             --前回通知ステータス
                ,XOHA.notif_date                            notif_date                    --確定通知実施日時
                ,XOHA.new_modify_flg                        new_modify_flg                --新規修正フラグ
                ,XOHA.performance_management_dept           performance_management_dept   --成績管理部署
                ,XOHA.instruction_dept                      instruction_dept              --指示部署
                ,XOHA.transfer_location_code                transfer_location_code        --振替先
                ,XOHA.mixed_sign                            mixed_sign                    --混載記号
                ,NULL                                       batch_no                      --手配No
                ,XOHA.screen_update_date                    screen_update_date            --画面更新日時
                ,XOHA.screen_update_by                      screen_update_by              --画面更新者ID
                ,NULL                                       tightening_date               --出荷依頼締め日時
                ,NULL                                       tightening_program_id         --締めコンカレントID
                ,NULL                                       corrected_tighten_class       --締め後修正区分
                ,XOHA.created_by                            created_by                    --作成者
                ,XOHA.creation_date                         creation_date                 --作成日
                ,XOHA.last_updated_by                       last_updated_by               --最終更新者
                ,XOHA.last_update_date                      last_update_date              --最終更新日
                ,XOHA.last_update_login                     last_update_login             --最終更新ログイン
           FROM
                 xxcmn_order_headers_all_arc     XOHA       --受注ヘッダ（アドオン）バックアップ
                ,oe_transaction_types_all    OTTA           --受注タイプマスタ
                ,oe_transaction_types_tl     OTTT           --受注タイプマスタ(日本語)
                ,xxskz_vendors2_v            VNDR           --SKYLINK用中間VIEW 配送先情報VIEW(取引先)
                ,xxskz_vendor_sites2_v       VSIT           --SKYLINK用中間VIEW 配送先情報VIEW(取引先サイト)
                ,fnd_lookup_values           FLV01          --クイックコード(ステータス名)
          WHERE
            --出荷情報の取得
                 OTTA.attribute1             = '2'          --支給
            AND  XOHA.latest_external_flag   = 'Y'          --最新フラグが有効
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --受注タイプ名取得条件
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --取引先名取得
            AND  XOHA.vendor_id              = VNDR.vendor_id(+)
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= VNDR.start_date_active(+)  --有効開始日
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= VNDR.end_date_active(+)    --有効終了日
            --取引先サイト名取得
            AND  XOHA.vendor_site_id         = VSIT.vendor_site_id(+)
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= VSIT.start_date_active(+)  --有効開始日
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= VSIT.end_date_active(+)    --有効終了日
            --ステータス名取得
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXPO_TRANSACTION_STATUS'
            AND  FLV01.lookup_code(+)        = XOHA.req_status
         --[ 支給データ  END ]
        UNION ALL
         --==========================
         -- 移動データ
         --==========================
         SELECT
                 XMVH.mov_num                               request_no                    --依頼_移動No
                ,XMVH.delivery_no                           delivery_no                   --配送No
                ,'移動'                                     type                          --タイプ
                ,XMVH.mov_type                              mov_type                      --移動タイプ
                ,FLV01.meaning                              mov_type_name                 --移動タイプ名
                ,XMVH.organization_id                       organization_id               --組織ID
                ,XMVH.entered_date                          ordered_date                  --受注_入力日
                ,NULL                                       latest_external_flag          --最新フラグ
                ,NULL                                       base_request_no               --元依頼No
                ,XMVH.prev_delivery_no                      prev_delivery_no              --前回配送No
                ,NULL                                       customer_id                   --顧客ID
                ,XMVH.ship_to_locat_code                    deliver_to                    --出荷_入庫先
                ,ILCT.description                           deliver_to_name               --出荷_入庫先名
                ,NULL                                       shipping_instructions         --出荷指示
                ,NULL                                       vendor_code                   --取引先
                ,NULL                                       vendor_name                   --取引先名
                ,NULL                                       vendor_site_code              --取引先サイト
                ,NULL                                       vendor_site_name              --取引先サイト名
                ,XMVH.career_id                             career_id                     --運送業者ID
                ,XMVH.shipping_method_code                  shipping_method_code          --配送区分
                ,NULL                                       cust_po_number                --顧客発注
                ,NULL                                       price_list_id                 --価格表ID
                ,XMVH.status                                status                        --ステータス
                ,FLV02.meaning                              status_name                   --ステータス名
                ,XMVH.schedule_ship_date                    schedule_ship_date            --出荷_出庫予定日
                ,XMVH.schedule_arrival_date                 schedule_arrival_date         --着荷_入庫予定日
                ,NULL                                       mixed_no                      --混載元No
                ,XMVH.collected_pallet_qty                  collected_pallet_qty          --パレット回収枚数
                ,XMVH.out_pallet_qty                        out_pallet_qty                --パレット枚数_出
                ,XMVH.in_pallet_qty                         in_pallet_qty                 --パレット枚数_入
                ,XMVH.description                           mov_description               --移動_摘要
                ,NULL                                       confirm_request_class         --物流担当確認依頼区分
                ,XMVH.freight_charge_class                  freight_charge_class          --運賃区分
                ,NULL                                       shikyu_instruction_class      --支給出庫指示区分
                ,NULL                                       shikyu_inst_rcv_class         --支給指示受領区分
                ,NULL                                       amount_fix_class              --有償金額確定区分
                ,NULL                                       takeback_class                --引取区分
                ,XMVH.shipped_locat_id                      deliver_from_id               --出荷_出庫元保管場所ID
                ,NULL                                       head_sales_branch             --管轄拠点
                ,NULL                                       input_sales_branch            --入力拠点
                ,NULL                                       po_no                         --発注No
                ,XMVH.item_class                            prod_class                    --商品区分
                ,NULL                                       item_class                    --品目区分
                ,XMVH.product_flg                           product_flg                   --製品識別区分
                ,XMVH.no_instr_actual_class                 no_instr_actual_class         --指示なし実績区分
                ,XMVH.no_cont_freight_class                 no_cont_freight_class         --契約外運賃区分
                ,XMVH.arrival_time_from                     arrival_time_from             --着荷時間FROM
                ,XMVH.arrival_time_to                       arrival_time_to               --着荷時間TO
                ,NULL                                       designated_item_id            --製造品目ID
                ,NULL                                       designated_production_date    --製造日
                ,NULL                                       designated_branch_no          --製造枝番
                ,XMVH.slip_number                           slip_number                   --送り状No
                ,XMVH.sum_quantity                          sum_quantity                  --合計数量
                ,XMVH.small_quantity                        small_quantity                --小口個数
                ,XMVH.label_quantity                        label_quantity                --ラベル枚数
                ,XMVH.loading_efficiency_weight             loading_efficiency_weight     --重量積載効率
                ,XMVH.loading_efficiency_capacity           loading_efficiency_capacity   --容積積載効率
                ,XMVH.based_weight                          based_weight                  --基本重量
                ,XMVH.based_capacity                        based_capacity                --基本容積
                ,XMVH.sum_weight                            sum_weight                    --積載重量合計
                ,XMVH.sum_capacity                          sum_capacity                  --積載容積合計
                ,XMVH.mixed_ratio                           mixed_ratio                   --混載率
                ,XMVH.pallet_sum_quantity                   pallet_sum_quantity           --パレット合計枚数
                ,NULL                                       real_pallet_quantity          --パレット実績枚数
                ,XMVH.sum_pallet_weight                     sum_pallet_weight             --合計パレット重量
                ,XMVH.actual_career_id                      result_freight_carrier_id     --運送業者_実績ID
                ,NVL( XMVH.actual_career_id, XMVH.career_id )                          --NVL( 運送業者_実績ID, 運送業者ID )
                                                            yj_freight_carrier_id         --運送業者_予実ID
                ,XMVH.actual_shipping_method_code           result_shipping_method_code   --配送区分_実績
                ,NVL( XMVH.actual_shipping_method_code, XMVH.shipping_method_code )    --NVL( 配送区分_実績, 配送区分 )
                                                            yj_shipping_method_code       --配送区分_予実
                ,XMVH.ship_to_locat_code                    result_deliver_to             --出荷先_実績
                ,ILCT.description                           result_deliver_to_name        --出荷先_実績名
                ,XMVH.ship_to_locat_code                    yj_deliver_to                 --出荷先_予実
                ,ILCT.description                           yj_deliver_to_name            --出荷先_予実名
                ,XMVH.actual_ship_date                      shipped_date                  --出荷_出庫日
                ,XMVH.actual_arrival_date                   arrival_date                  --着荷_入庫日
                ,NVL( XMVH.actual_ship_date, XMVH.schedule_ship_date )                 --NVL( 出荷日, 出荷予定日 )
                                                            yj_shipped_date               --出荷日_予実
                ,NVL( XMVH.actual_arrival_date, XMVH.schedule_arrival_date )           --NVL( 着荷日, 着荷予定日 )
                                                            yj_arrival_date               --着荷日_予実
                ,XMVH.weight_capacity_class                 weight_capacity_class         --重量容積区分
                ,XMVH.comp_actual_flg                       actual_confirm_class          --実績計上済区分
                ,XMVH.correct_actual_flg                    correct_actual_flg            --実績訂正フラグ
                ,XMVH.notif_status                          notif_status                  --通知ステータス
                ,XMVH.prev_notif_status                     prev_notif_status             --前回通知ステータス
                ,XMVH.notif_date                            notif_date                    --確定通知実施日時
                ,XMVH.new_modify_flg                        new_modify_flg                --新規修正フラグ
                ,NULL                                       performance_management_dept   --成績管理部署
                ,XMVH.instruction_post_code                 instruction_dept              --指示部署
                ,NULL                                       transfer_location_code        --振替先
                ,XMVH.mixed_sign                            mixed_sign                    --混載記号
                ,XMVH.batch_no                              batch_no                      --手配No
                ,NULL                                       screen_update_date            --画面更新日時
                ,NULL                                       screen_update_by              --画面更新者ID
                ,NULL                                       tightening_date               --出荷依頼締め日時
                ,NULL                                       tightening_program_id         --締めコンカレントID
                ,NULL                                       corrected_tighten_class       --締め後修正区分
                ,XMVH.created_by                            created_by                    --作成者
                ,XMVH.creation_date                         creation_date                 --作成日
                ,XMVH.last_updated_by                       last_updated_by               --最終更新者
                ,XMVH.last_update_date                      last_update_date              --最終更新日
                ,XMVH.last_update_login                     last_update_login             --最終更新ログイン
           FROM
                 xxcmn_mov_req_instr_hdrs_arc  XMVH         --移動依頼/指示ヘッダ（アドオン）バックアップ
                ,xxskz_item_locations2_v     ILCT           --SKYLINK用中間VIEW 保管場所情報VIEW(出荷_入庫先保管場所)
                ,fnd_lookup_values           FLV01          --クイックコード(移動タイプ名)
                ,fnd_lookup_values           FLV02          --クイックコード(ステータス名)
          WHERE
            --出荷_入庫先名取得
                 XMVH.ship_to_locat_id       = ILCT.inventory_location_id(+)
            --移動タイプ名取得
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXINV_MOVE_TYPE'
            AND  FLV01.lookup_code(+)        = XMVH.mov_type
            --ステータス名取得
            AND  FLV02.language(+)           = 'JA'
            AND  FLV02.lookup_type(+)        = 'XXINV_MOVE_STATUS'
            AND  FLV02.lookup_code(+)        = XMVH.status
         --[ 移動データ  END ]
       )                                     SPMH           --出荷/支給/移動 ヘッダ情報
       ,xxcmn_carriers_schedule_arc              XCS        --配車配送計画（アドオン）バックアップ
       ,hr_all_organization_units_tl         HAOUT          --組織マスタ
       ,xxskz_cust_accounts2_v               CUST1          --SKYLINK用中間VIEW 顧客情報VIEW(顧客)
       ,xxskz_cust_accounts2_v               CUST2          --SKYLINK用中間VIEW 顧客情報VIEW(管轄拠点)
       ,xxskz_cust_accounts2_v               CUST3          --SKYLINK用中間VIEW 顧客情報VIEW(入力拠点)
       ,xxskz_carriers2_v                    CARR1          --SKYLINK用中間VIEW 運送業者情報VIEW(運送業者)
       ,xxskz_carriers2_v                    CARR2          --SKYLINK用中間VIEW 運送業者情報VIEW(運送業者_実績)
       ,xxskz_carriers2_v                    CARR3          --SKYLINK用中間VIEW 運送業者情報VIEW(運送業者_予実)
       ,xxskz_item_locations2_v              ILCT1           --SKYLINK用中間VIEW 保管場所情報VIEW(出荷_出庫元保管場所)
       ,xxskz_item_mst2_v                    ITEM           --SKYLINK用中間VIEW 品目情報VIEW(製造品目)
       ,xxskz_locations2_v                   LOCT1          --SKYLINK用中間VIEW 事業所情報VIEW(成績管理部署)
       ,xxskz_locations2_v                   LOCT2          --SKYLINK用中間VIEW 事業所情報VIEW(指示部署)
       ,xxskz_locations2_v                   LOCT3          --SKYLINK用中間VIEW 事業所情報VIEW(振替先)
       ,qp_list_headers_tl                   QLHT           --価格表ヘッダ(日本語)
       ,fnd_user                             FU             --ユーザーマスタ(画面更新者名取得用)
       ,fnd_user                             FU_CB          --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                             FU_LU          --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                             FU_LL          --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                           FL_LL          --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_lookup_values                    FLV02          --クイックコード(配送区分名)
       ,fnd_lookup_values                    FLV03          --クイックコード(物流担当確認依頼区分名)
       ,fnd_lookup_values                    FLV04          --クイックコード(運賃区分名)
       ,fnd_lookup_values                    FLV05          --クイックコード(支給出庫指示区分名)
       ,fnd_lookup_values                    FLV06          --クイックコード(支給指示受領区分名)
       ,fnd_lookup_values                    FLV07          --クイックコード(有償金額確定区分名)
       ,fnd_lookup_values                    FLV08          --クイックコード(引取区分名)
       ,fnd_lookup_values                    FLV09          --クイックコード(商品区分名)
       ,fnd_lookup_values                    FLV10          --クイックコード(品目区分名)
       ,fnd_lookup_values                    FLV11          --クイックコード(製品識別区分名)
       ,fnd_lookup_values                    FLV12          --クイックコード(契約外運賃区分名)
       ,fnd_lookup_values                    FLV13          --クイックコード(着荷時間FROM名)
       ,fnd_lookup_values                    FLV14          --クイックコード(着荷時間TO名)
       ,fnd_lookup_values                    FLV15          --クイックコード(配送区分_実績名)
       ,fnd_lookup_values                    FLV16          --クイックコード(配送区分_予実名)
       ,fnd_lookup_values                    FLV17          --クイックコード(重量容積区分名)
       ,fnd_lookup_values                    FLV18          --クイックコード(通知ステータス名)
       ,fnd_lookup_values                    FLV19          --クイックコード(前回通知ステータス名)
       ,fnd_lookup_values                    FLV20          --クイックコード(新規修正フラグ名)
       ,fnd_lookup_values                    FLV21          --クイックコード(締め後修正区分名)
       ,fnd_lookup_values                    FLV22          --クイックコード(配送_処理種別名)
       ,fnd_lookup_values                    FLV23          --クイックコード(配送_配送先コード区分名)
       ,fnd_lookup_values                    FLV24          --クイックコード(配送_自動配車対象区分)
       ,fnd_lookup_values                    FLV25          --クイックコード(配送_運賃形態)
 WHERE
   --配車配送アドオンテーブルデータ取得
        SPMH.delivery_no                     = XCS.delivery_no(+)
   --組織名取得
   AND  HAOUT.language(+)                    = 'JA'
   AND  SPMH.organization_id                 = HAOUT.organization_id(+)
   --顧客名取得
   AND  SPMH.customer_id                     = CUST1.party_id(+)
   AND  SPMH.yj_arrival_date                >= CUST1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST1.end_date_active(+)
   --運送業者名取得
   AND  SPMH.career_id                       = CARR1.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR1.end_date_active(+)
   --価格表名取得
   AND  QLHT.LANGUAGE(+)                     = 'JA'
   AND  SPMH.price_list_id                   = QLHT.LIST_HEADER_ID(+)
   --出荷_出庫元保管場所名取得
   AND  SPMH.deliver_from_id                 = ILCT1.inventory_location_id(+)
   --管轄拠点名取得
   AND  SPMH.head_sales_branch               = CUST2.party_number(+)
   AND  SPMH.yj_arrival_date                >= CUST2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST2.end_date_active(+)
   --入力拠点名取得
   AND  SPMH.input_sales_branch              = CUST3.party_number(+)
   AND  SPMH.yj_arrival_date                >= CUST3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST3.end_date_active(+)
   --製造品目名取得
   AND  SPMH.designated_item_id              = ITEM.item_id(+)
   AND  SPMH.yj_arrival_date                >= ITEM.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= ITEM.end_date_active(+)
   --運送業者_実績名取得
   AND  SPMH.result_freight_carrier_id       = CARR2.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR2.end_date_active(+)
   --運送業者_予実名取得
   AND  SPMH.yj_freight_carrier_id           = CARR3.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR3.end_date_active(+)
   --成績管理部署名取得
   AND  SPMH.performance_management_dept     = LOCT1.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT1.end_date_active(+)
   --指示部署名取得
   AND  SPMH.instruction_dept                = LOCT2.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT2.end_date_active(+)
   --振替先名取得
   AND  SPMH.transfer_location_code          = LOCT3.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT3.end_date_active(+)
   -- 画面更新者名取得
   AND  SPMH.screen_update_by                = FU.user_id(+)
   --作成者・最終更新者取得条件
   AND  SPMH.created_by                      = FU_CB.user_id(+)
   AND  SPMH.last_updated_by                 = FU_LU.user_id(+)
   AND  SPMH.last_update_login               = FL_LL.login_id(+)
   AND  FL_LL.user_id                        = FU_LL.user_id(+)
   --【クイックコード】配送区分名
   AND  FLV02.language(+)                    = 'JA'
   AND  FLV02.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+)                 = SPMH.shipping_method_code
   --【クイックコード】物流担当確認依頼区分名
   AND  FLV03.language(+)                    = 'JA'
   AND  FLV03.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV03.lookup_code(+)                 = SPMH.confirm_request_class
   --【クイックコード】運賃区分名
   AND  FLV04.language(+)                    = 'JA'
   AND  FLV04.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV04.lookup_code(+)                 = SPMH.freight_charge_class
   --【クイックコード】支給出庫指示区分名
   AND  FLV05.language(+)                    = 'JA'
   AND  FLV05.lookup_type(+)                 = 'XXWSH_SHIKYU_INSTRUCTION_CLASS'
   AND  FLV05.lookup_code(+)                 = SPMH.shikyu_instruction_class
   --【クイックコード】支給指示受領区分名
   AND  FLV06.language(+)                    = 'JA'
   AND  FLV06.lookup_type(+)                 = 'XXWSH_SHIKYU_INST_RCV_CLASS'
   AND  FLV06.lookup_code(+)                 = SPMH.shikyu_inst_rcv_class
   --【クイックコード】有償金額確定区分名
   AND  FLV07.language(+)                    = 'JA'
   AND  FLV07.lookup_type(+)                 = 'XXWSH_AMOUNT_FIX_CLASS'
   AND  FLV07.lookup_code(+)                 = SPMH.amount_fix_class
   --【クイックコード】引取区分名
   AND  FLV08.language(+)                    = 'JA'
   AND  FLV08.lookup_type(+)                 = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV08.lookup_code(+)                 = SPMH.takeback_class
   --【クイックコード】商品区分名
   AND  FLV09.language(+)                    = 'JA'
   AND  FLV09.lookup_type(+)                 = 'XXWIP_ITEM_TYPE'
   AND  FLV09.lookup_code(+)                 = SPMH.prod_class
   --【クイックコード】品目区分名
   AND  FLV10.language(+)                    = 'JA'
   AND  FLV10.lookup_type(+)                 = 'XXWSH_ITEM_DIV'
   AND  FLV10.lookup_code(+)                 = SPMH.item_class
   --【クイックコード】製品識別区分名
   AND  FLV11.language(+)                    = 'JA'
   AND  FLV11.lookup_type(+)                 = 'XXINV_PRODUCT_CLASS'
   AND  FLV11.lookup_code(+)                 = SPMH.product_flg
   --【クイックコード】契約外運賃区分名
   AND  FLV12.language(+)                    = 'JA'
   AND  FLV12.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV12.lookup_code(+)                 = SPMH.no_cont_freight_class
   --【クイックコード】着荷時間FROM名
   AND  FLV13.language(+)                    = 'JA'
   AND  FLV13.lookup_type(+)                 = 'XXWSH_ARRIVAL_TIME'
   AND  FLV13.lookup_code(+)                 = SPMH.arrival_time_from
   --【クイックコード】着荷時間TO名
   AND  FLV14.language(+)                    = 'JA'
   AND  FLV14.lookup_type(+)                 = 'XXWSH_ARRIVAL_TIME'
   AND  FLV14.lookup_code(+)                 = SPMH.arrival_time_to
   --【クイックコード】配送区分_実績名
   AND  FLV15.language(+)                    = 'JA'
   AND  FLV15.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV15.lookup_code(+)                 = SPMH.result_shipping_method_code
   --【クイックコード】配送区分_予実名
   AND  FLV16.language(+)                    = 'JA'
   AND  FLV16.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV16.lookup_code(+)                 = SPMH.yj_shipping_method_code
   --【クイックコード】重量容積区分名
   AND  FLV17.language(+)                    = 'JA'
   AND  FLV17.lookup_type(+)                 = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV17.lookup_code(+)                 = SPMH.weight_capacity_class
   --【クイックコード】通知ステータス名
   AND  FLV18.language(+)                    = 'JA'
   AND  FLV18.lookup_type(+)                 = 'XXWSH_NOTIF_STATUS'
   AND  FLV18.lookup_code(+)                 = SPMH.notif_status
   --【クイックコード】前回通知ステータス名
   AND  FLV19.language(+)                    = 'JA'
   AND  FLV19.lookup_type(+)                 = 'XXWSH_NOTIF_STATUS'
   AND  FLV19.lookup_code(+)                 = SPMH.prev_notif_status
   --【クイックコード】新規修正フラグ名
   AND  FLV20.language(+)                    = 'JA'
   AND  FLV20.lookup_type(+)                 = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV20.lookup_code(+)                 = SPMH.new_modify_flg
   --【クイックコード】締め後修正区分名
   AND  FLV21.language(+)                    = 'JA'
   AND  FLV21.lookup_type(+)                 = 'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV21.lookup_code(+)                 = SPMH.corrected_tighten_class
   --【クイックコード】配送_処理種別名
   AND  FLV22.language(+)                    = 'JA'
   AND  FLV22.lookup_type(+)                 = 'XXWSH_PROCESS_TYPE'
   AND  FLV22.lookup_code(+)                 = XCS.transaction_type
   --【クイックコード】配送_配送先コード区分名
   AND  FLV23.language(+)                    = 'JA'
   AND  FLV23.lookup_type(+)                 = 'CUSTOMER CLASS'
   AND  FLV23.lookup_code(+)                 = XCS.deliver_to_code_class
   --【クイックコード】配送_自動配車対象区分名
   AND  FLV24.language(+)                    = 'JA'
   AND  FLV24.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV24.lookup_code(+)                 = XCS.auto_process_type
   --【クイックコード】配送_運賃形態名
   AND  FLV25.language(+)                    = 'JA'
   AND  FLV25.lookup_type(+)                 = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV25.lookup_code(+)                 = XCS.freight_charge_type
/
COMMENT ON TABLE APPS.XXSKZ_入出庫配送ヘッダ_基本_V IS 'SKYLINK用入出庫配送ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.依頼_移動NO                   IS '依頼_移動NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送NO                        IS '配送NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.タイプ                        IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.移動タイプ                    IS '移動タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.移動タイプ名                  IS '移動タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.組織名                        IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.受注_入力日                   IS '受注_入力日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.最新フラグ                    IS '最新フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.元依頼NO                      IS '元依頼NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.前回配送NO                    IS '前回配送NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.顧客                          IS '顧客'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.顧客名                        IS '顧客名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_入庫先                   IS '出荷_入庫先'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_入庫先名                 IS '出荷_入庫先名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷指示                      IS '出荷指示'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.取引先                        IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.取引先名                      IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.取引先サイト                  IS '取引先サイト'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.取引先サイト名                IS '取引先サイト名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者                      IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者名                    IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分                      IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分名                    IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.顧客発注                      IS '顧客発注'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.価格表                        IS '価格表'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.価格表名                      IS '価格表名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.ステータス                    IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.ステータス名                  IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_出庫予定日               IS '出荷_出庫予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷_入庫予定日               IS '着荷_入庫予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.混載元NO                      IS '混載元NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.パレット回収枚数              IS 'パレット回収枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.パレット枚数_出               IS 'パレット枚数_出'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.パレット枚数_入               IS 'パレット枚数_入'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.移動_摘要                     IS '移動_摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.物流担当確認依頼区分          IS '物流担当確認依頼区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.物流担当確認依頼区分名        IS '物流担当確認依頼区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運賃区分                      IS '運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運賃区分名                    IS '運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.支給出庫指示区分              IS '支給出庫指示区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.支給出庫指示区分名            IS '支給出庫指示区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.支給指示受領区分              IS '支給指示受領区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.支給指示受領区分名            IS '支給指示受領区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.有償金額確定区分              IS '有償金額確定区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.有償金額確定区分名            IS '有償金額確定区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.引取区分                      IS '引取区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.引取区分名                    IS '引取区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_出庫元保管場所           IS '出荷_出庫元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_出庫元保管場所名         IS '出荷_出庫元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.管轄拠点                      IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.管轄拠点名                    IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.管轄拠点略称                  IS '管轄拠点略称'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.入力拠点                      IS '入力拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.入力拠点名                    IS '入力拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.入力拠点略称                  IS '入力拠点略称'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.発注NO                        IS '発注NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.商品区分                      IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.商品区分名                    IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.品目区分                      IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.品目区分名                    IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製品識別区分                  IS '製品識別区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製品識別区分名                IS '製品識別区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.指示なし実績区分              IS '指示なし実績区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.契約外運賃区分                IS '契約外運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.契約外運賃区分名              IS '契約外運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷時間FROM                  IS '着荷時間FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷時間FROM名                IS '着荷時間FROM名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷時間TO                    IS '着荷時間TO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷時間TO名                  IS '着荷時間TO名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製造品目                      IS '製造品目'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製造品目名                    IS '製造品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製造品目略称                  IS '製造品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製造日                        IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.製造枝番                      IS '製造枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.送り状NO                      IS '送り状NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.合計数量                      IS '合計数量'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.小口個数                      IS '小口個数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.ラベル枚数                    IS 'ラベル枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.重量積載効率                  IS '重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.容積積載効率                  IS '容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.基本重量                      IS '基本重量'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.基本容積                      IS '基本容積'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.積載重量合計                  IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.積載容積合計                  IS '積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.混載率                        IS '混載率'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.パレット合計枚数              IS 'パレット合計枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.パレット実績枚数              IS 'パレット実績枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.合計パレット重量              IS '合計パレット重量'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者_実績                 IS '運送業者_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者_予実                 IS '運送業者_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者_実績名               IS '運送業者_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.運送業者_予実名               IS '運送業者_予実名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分_実績                 IS '配送区分_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分_予実                 IS '配送区分_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分_実績名               IS '配送区分_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送区分_予実名               IS '配送区分_予実名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷先_実績                   IS '出荷先_実績'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷先_予実                   IS '出荷先_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷先_実績名                 IS '出荷先_実績名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷先_予実名                 IS '出荷先_予実名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_出庫日                   IS '出荷_出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷_出庫日_予実              IS '出荷_出庫日_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷_入庫日                   IS '着荷_入庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.着荷_入庫日_予実              IS '着荷_入庫日_予実'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.重量容積区分                  IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.重量容積区分名                IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.実績計上済区分                IS '実績計上済区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.実績訂正フラグ                IS '実績訂正フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.通知ステータス                IS '通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.通知ステータス名              IS '通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.前回通知ステータス            IS '前回通知ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.前回通知ステータス名          IS '前回通知ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.確定通知実施日時              IS '確定通知実施日時'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.新規修正フラグ                IS '新規修正フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.新規修正フラグ名              IS '新規修正フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.成績管理部署                  IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.成績管理部署名                IS '成績管理部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.指示部署                      IS '指示部署'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.指示部署名                    IS '指示部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.振替先                        IS '振替先'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.振替先名                      IS '振替先名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.混載記号                      IS '混載記号'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.手配NO                        IS '手配NO'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.画面更新日時                  IS '画面更新日時'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.画面更新者                    IS '画面更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.出荷依頼締め日時              IS '出荷依頼締め日時'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.締めコンカレントID            IS '締めコンカレントID'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.締め後修正区分                IS '締め後修正区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.締め後修正区分名              IS '締め後修正区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_処理種別                 IS '配送_処理種別'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_処理種別名               IS '配送_処理種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_混載種別                 IS '配送_混載種別'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_混載種別名               IS '配送_混載種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_配送先コード区分         IS '配送_配送先コード区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_配送先コード区分名       IS '配送_配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_自動配車対象区分         IS '配送_自動配車対象区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_自動配車対象区分名       IS '配送_自動配車対象区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_摘要                     IS '配送_摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_支払運賃計算対象フラグ   IS '配送_支払運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_支払運賃計算対象フラグ名 IS '配送_支払運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_請求運賃計算対象フラグ   IS '配送_請求運賃計算対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_請求運賃計算対象フラグ名 IS '配送_請求運賃計算対象フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_積載重量合計             IS '配送_積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_積載容積合計             IS '配送_積載容積合計'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_重量積載効率             IS '配送_重量積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_容積積載効率             IS '配送_容積積載効率'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_運賃形態                 IS '配送_運賃形態'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.配送_運賃形態名               IS '配送_運賃形態名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.作成者                        IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.作成日                        IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.最終更新者                    IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.最終更新日                    IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫配送ヘッダ_基本_V.最終更新ログイン              IS '最終更新ログイン'
/
