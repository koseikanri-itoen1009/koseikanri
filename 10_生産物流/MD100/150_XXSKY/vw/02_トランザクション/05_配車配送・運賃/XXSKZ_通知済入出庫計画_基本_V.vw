/*************************************************************************
 * 
 * View  Name      : XXSKZ_通知済入出庫計画_基本_V
 * Description     : XXSKZ_通知済入出庫計画_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_通知済入出庫計画_基本_V
(
 会社名
,依頼No
,配送No
,データ種別
,データ種別名
,データ区分
,データ区分名
,データタイプ
,データタイプ名
,確定通知実施日時
,更新日時
,EOS宛先_出庫倉庫
,EOS宛先_出庫倉庫名
,EOS宛先_運送業者
,EOS宛先_運送業者名
,EOS宛先_CSV出力
,EOS宛先_CSV出力名
,伝送用枝番
,伝送用枝番名
,予備
,管轄拠点コード
,管轄拠点名称
,出庫倉庫コード
,出庫倉庫名称
,入庫倉庫コード
,入庫倉庫名称
,運送業者コード
,運送業者名
,配送先コード
,配送先名
,発日
,着日
,配送区分
,配送区分名
,依頼NO単位_重量容積
,混載元依頼No
,パレット回収枚数
,着荷時間指定FROM
,着荷時間指定FROM名
,着荷時間指定TO
,着荷時間指定TO名
,顧客発注番号
,摘要
,ステータス
,ステータス名
,運賃区分
,運賃区分名
,パレット使用枚数
,報告部署コード
,報告部署名
,予備１
,予備２
,予備３
,予備４
,明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名称
,品目略称
,品目単位
,品目数量
,ロット番号
,製造日
,賞味期限
,固有記号
,ロット数量
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XNDI.corporation_name           corporation_name              --会社名
       ,XNDI.request_no                 request_no                    --依頼No
       ,XNDI.delivery_no                delivery_no                   --配送No
       ,XNDI.data_class                 data_class                    --データ種別
       ,FLV01.meaning                   data_class_name               --データ種別名
       ,XNDI.new_modify_del_class       new_modify_del_class          --データ区分
       ,CASE WHEN XNDI.new_modify_del_class = '0' THEN '追加'
             WHEN XNDI.new_modify_del_class = '1' THEN '訂正'
             WHEN XNDI.new_modify_del_class = '2' THEN '削除'
             ELSE                                      NULL
        END                             new_modify_del_class_name     --データ区分名
       ,XNDI.data_type                  data_type                     --データタイプ
       ,FLV02.meaning                   data_type_name                --データタイプ名
       ,TO_CHAR( XNDI.notif_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        notif_date                    --確定通知実施日時
       ,TO_CHAR( XNDI.update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        update_date                   --更新日時
       ,XNDI.eos_shipped_locat          eos_shipped_locat             --EOS宛先_出庫倉庫
       ,XILV.description                eos_shipped_locat_name        --EOS宛先_出庫倉庫名
       ,XNDI.eos_freight_carrier        eos_freight_carrier           --EOS宛先_運送業者
       ,XCAR.party_name                 eos_freight_carrier_name      --EOS宛先_運送業者名
       ,XNDI.eos_csv_output             eos_csv_output                --EOS宛先_CSV出力
       ,CASE WHEN XNDI.eos_csv_output = XNDI.eos_shipped_locat   THEN XILV.description
             WHEN XNDI.eos_csv_output = XNDI.eos_freight_carrier THEN XCAR.party_name
             ELSE                                                     NULL
        END                             eos_csv_output_name           --EOS宛先_CSV出力名
       ,XNDI.transfer_branch_no         transfer_branch_no            --伝送用枝番
       ,CASE WHEN XNDI.transfer_branch_no = '10' THEN 'ヘッダ'
             WHEN XNDI.transfer_branch_no = '20' THEN '明細'
             ELSE                                     NULL
        END                             transfer_branch_name          --伝送用枝番名
        --以下、伝送用枝番:10(ヘッダ)時に表示される項目
       ,XNDI.reserve                    reserve                       --予備
       ,XNDI.head_sales_branch          head_sales_branch             --管轄拠点コード
       ,XNDI.head_sales_branch_name     head_sales_branch_name        --管轄拠点名称
       ,XNDI.shipped_locat_code         shipped_locat_code            --出庫倉庫コード
       ,XNDI.shipped_locat_name         shipped_locat_name            --出庫倉庫名称
       ,XNDI.ship_to_locat_code         ship_to_locat_code            --入庫倉庫コード
       ,XNDI.ship_to_locat_name         ship_to_locat_name            --入庫倉庫名称
       ,XNDI.freight_carrier_code       freight_carrier_code          --運送業者コード
       ,XNDI.freight_carrier_name       freight_carrier_name          --運送業者名
       ,XNDI.deliver_to                 deliver_to                    --配送先コード
       ,XNDI.deliver_to_name            deliver_to_name               --配送先名
       ,XNDI.schedule_ship_date         schedule_ship_date            --発日
       ,XNDI.schedule_arrival_date      schedule_arrival_date         --着日
       ,XNDI.shipping_method_code       shipping_method_code          --配送区分
       ,FLV03.meaning                   shipping_method_name          --配送区分名
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XNDI.weight )             weight                        --依頼NO単位_重量容積
       ,CEIL( TRUNC(NVL(XNDI.weight,0),1) )
                                        weight                        --依頼NO単位_重量容積(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
       ,XNDI.mixed_no                   mixed_no                      --混載元依頼No
       ,XNDI.collected_pallet_qty       collected_pallet_qty          --パレット回収枚数
       ,XNDI.arrival_time_from          arrival_time_from             --着荷時間指定FROM
       ,FLV04.meaning                   arrival_time_from_name        --着荷時間指定FROM名
       ,XNDI.arrival_time_to            arrival_time_to               --着荷時間指定TO
       ,FLV05.meaning                   arrival_time_to_name          --着荷時間指定TO名
       ,XNDI.cust_po_number             cust_po_number                --顧客発注番号
       ,XNDI.description                description                   --摘要
       ,XNDI.status                     status                        --ステータス
       ,CASE WHEN XNDI.status = '01' THEN '予定'
             WHEN XNDI.status = '02' THEN '確定'
             ELSE                         NULL
        END                             status_name                   --ステータス名
       ,XNDI.freight_charge_class       freight_charge_class          --運賃区分
       ,FLV06.meaning                   freight_charge_clase_name     --運賃区分名
       ,XNDI.pallet_sum_quantity        pallet_sum_quantity           --パレット使用枚数
       ,XNDI.report_dept                report_dept                   --報告部署コード
       ,XLOCT.location_name             report_dept_name              --報告部署名
       ,XNDI.reserve1                   reserve1                      --予備１
       ,XNDI.reserve2                   reserve2                      --予備２
       ,XNDI.reserve3                   reserve3                      --予備３
       ,XNDI.reserve4                   reserve4                      --予備４
        --以下、伝送用枝番:20(明細)時に表示される項目
       ,XNDI.line_number                line_number                   --明細番号
       ,XPRODC.prod_class_code          prod_class_code               --商品区分
       ,XPRODC.prod_class_name          prod_class_name               --商品区分名
       ,XITEMC.item_class_code          item_class_code               --品目区分
       ,XITEMC.item_class_name          item_class_name               --品目区分名
       ,XCRWDC.crowd_code               crowd_cod                     --群コード
       ,XNDI.item_code                  item_code                     --品目コード
       ,XITEM.item_name                 item_name                     --品目名称
       ,XITEM.item_short_name           item_short_name               --品目略称
       ,XNDI.item_uom_code              item_uom_code                 --品目単位
       ,XNDI.item_quantity              item_quantity                 --品目数量
       ,XNDI.lot_no                     lot_no                        --ロット番号
       ,XNDI.lot_date                   lot_date                      --製造日
       ,XNDI.best_bfr_date              best_bfr_date                 --賞味期限
       ,XNDI.lot_sign                   lot_sign                      --固有記号
       ,XNDI.lot_quantity               lot_quantity                  --ロット数量
        --WHOカラム情報
       ,FU_CB.user_name                 created_by                    --作成者
       ,TO_CHAR( XNDI.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date                 --作成日
       ,FU_LU.user_name                 last_updated_by               --最終更新者
       ,TO_CHAR( XNDI.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date              --最終更新日
       ,FU_LL.user_name                 last_update_login             --最終更新ログイン
  FROM
        xxwsh_notif_delivery_info       XNDI                          --通知済入出庫配送計画情報アドオン
       ,xxskz_item_locations_v          XILV                          --EOS宛先_出庫倉庫名取得用
       ,xxskz_carriers2_v               XCAR                          --EOS宛先_運送業者名取得用
       ,xxskz_locations2_v              XLOCT                         --報告部署名取得用
       ,xxskz_item_mst2_v               XITEM                         --品目情報取得用
       ,xxskz_prod_class_v              XPRODC                        --商品区分取得用
       ,xxskz_item_class_v              XITEMC                        --品目区分取得用
       ,xxskz_crowd_code_v              XCRWDC                        --群コード取得用
       ,fnd_lookup_values               FLV01                         --クイックコード(データ種別名)
       ,fnd_lookup_values               FLV02                         --クイックコード(データタイプ名)
       ,fnd_lookup_values               FLV03                         --クイックコード(配送区分名)
       ,fnd_lookup_values               FLV04                         --クイックコード(着荷時間FROM名)
       ,fnd_lookup_values               FLV05                         --クイックコード(着荷時間TO名)
       ,fnd_lookup_values               FLV06                         --クイックコード(運賃区分名)
       ,fnd_user                        FU_CB                         --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU                         --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL                         --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL                         --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   --EOS宛先_出庫倉庫名取得
        XNDI.eos_shipped_locat          = XILV.segment1(+)
   --EOS宛先_運送業者名取得
   AND  XNDI.eos_freight_carrier        = XCAR.freight_code(+)
   AND  XNDI.notif_date                >= XCAR.start_date_active(+)
   AND  XNDI.notif_date                <= XCAR.end_date_active(+)
   --報告部署名取得
   AND  XNDI.report_dept                = XLOCT.location_code(+)
   AND  XNDI.notif_date                >= XLOCT.start_date_active(+)
   AND  XNDI.notif_date                <= XLOCT.end_date_active(+)
   --品目情報取得
   AND  XNDI.item_code                  = XITEM.item_no(+)
   AND  XNDI.notif_date                >= XITEM.start_date_active(+)
   AND  XNDI.notif_date                <= XITEM.end_date_active(+)
   --品目カテゴリ情報取得
   AND  XITEM.item_id                   = XPRODC.item_id(+)           --商品区分
   AND  XITEM.item_id                   = XITEMC.item_id(+)           --品目区分
   AND  XITEM.item_id                   = XCRWDC.item_id(+)           --群コード
   --データ種別名取得（クイックコード値）
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_D17'
   AND  FLV01.lookup_code(+)            = XNDI.data_class
   --データタイプ名取得（クイックコード値）
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWSH_SHIPPING_BIZ_TYPE'
   AND  FLV02.lookup_code(+)            = XNDI.data_type
   --配送区分名取得（クイックコード値）
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+)            = XNDI.shipping_method_code
   --着荷時間FROM名取得（クイックコード値）
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV04.lookup_code(+)            = XNDI.arrival_time_from
   --着荷時間TO名取得（クイックコード値）
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV05.lookup_code(+)            = XNDI.arrival_time_to
   --運賃区分名取得（クイックコード値）
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV06.lookup_code(+)            = XNDI.freight_charge_class
   --WHOカラム情報取得
   AND  XNDI.created_by                 = FU_CB.user_id(+)
   AND  XNDI.last_updated_by            = FU_LU.user_id(+)
   AND  XNDI.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_通知済入出庫計画_基本_V IS 'SKYLINK用 通知済入出庫計画（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.会社名              IS '会社名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.依頼No              IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.配送No              IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データ種別          IS 'データ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データ種別名        IS 'データ種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データ区分          IS 'データ区分'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データ区分名        IS 'データ区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データタイプ        IS 'データタイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.データタイプ名      IS 'データタイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.確定通知実施日時    IS '確定通知実施日時'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.更新日時            IS '更新日時'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_出庫倉庫    IS 'EOS宛先_出庫倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_出庫倉庫名  IS 'EOS宛先_出庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_運送業者    IS 'EOS宛先_運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_運送業者名  IS 'EOS宛先_運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_CSV出力     IS 'EOS宛先_CSV出力'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.EOS宛先_CSV出力名   IS 'EOS宛先_CSV出力名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.伝送用枝番          IS '伝送用枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.伝送用枝番名        IS '伝送用枝番名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.予備                IS '予備'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.管轄拠点コード      IS '管轄拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.管轄拠点名称        IS '管轄拠点名称'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.出庫倉庫コード      IS '出庫倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.出庫倉庫名称        IS '出庫倉庫名称'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.入庫倉庫コード      IS '入庫倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.入庫倉庫名称        IS '入庫倉庫名称'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.運送業者コード      IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.運送業者名          IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.配送先コード        IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.配送先名            IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.発日                IS '発日'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.着日                IS '着日'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.配送区分            IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.配送区分名          IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.依頼NO単位_重量容積 IS '依頼NO単位_重量容積'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.混載元依頼No        IS '混載元依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.パレット回収枚数    IS 'パレット回収枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.着荷時間指定FROM    IS '着荷時間指定FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.着荷時間指定FROM名  IS '着荷時間指定FROM名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.着荷時間指定TO      IS '着荷時間指定TO'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.着荷時間指定TO名    IS '着荷時間指定TO名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.顧客発注番号        IS '顧客発注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.摘要                IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.ステータス          IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.ステータス名        IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.運賃区分            IS '運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.運賃区分名          IS '運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.パレット使用枚数    IS 'パレット使用枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.報告部署コード      IS '報告部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.報告部署名          IS '報告部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.予備１              IS '予備１'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.予備２              IS '予備２'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.予備３              IS '予備３'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.予備４              IS '予備４'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.明細番号            IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.商品区分            IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.商品区分名          IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目区分            IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目区分名          IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.群コード            IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目コード          IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目名称            IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目略称            IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目単位            IS '品目単位'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.品目数量            IS '品目数量'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.ロット番号          IS 'ロット番号'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.製造日              IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.賞味期限            IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.固有記号            IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.ロット数量          IS 'ロット数量'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.作成者              IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.作成日              IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.最終更新者          IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.最終更新日          IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_通知済入出庫計画_基本_V.最終更新ログイン    IS '最終更新ログイン'
/
