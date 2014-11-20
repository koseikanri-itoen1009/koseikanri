/*************************************************************************
 * 
 * View  Name      : XXSKZ_品目マスタ_現在_V
 * Description     : XXSKZ_品目マスタ_現在_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_品目マスタ_現在_V
(
 品目コード
,品目名
,品目略称
,品目カナ名
,適用開始日
,適用終了日
,適用済フラグ
,単位
,ロット管理区分
,ロット管理区分名
,倉庫品目コード
,倉庫品目名
,倉庫品目略称
,旧_群コード
,新_群コード
,群コード適用開始日
,旧_定価
,新_定価
,定価適用開始日
,旧_営業原価
,新_営業原価
,営業原価適用開始日
,売上対象区分
,売上対象区分名
,発売製造開始日
,JANｺｰﾄﾞ
,ITFコード
,ケース入数
,NET
,重量容積区分
,重量容積区分名
,重量
,容積
,仕向区分
,仕向区分名
,出荷区分
,出荷区分名
,原価管理区分
,原価管理区分名
,仕入単価導出日タイプ
,仕入単価導出日タイプ名
,代表入数
,入出庫換算単位
,試験有無区分
,試験有無区分名
,検査LT
,判定回数
,発注可能判定回数
,マスタ受信日時
,自動ロット採番有効
,親品目コード
,親品目名
,親品目略称
,型種別
,型種別名
,商品分類
,商品分類名
,商品種別
,商品種別名
,賞味期間
,納入期間
,工場群コード
,標準歩留
,出荷停止日
,率区分
,率区分名
,消費期間
,賞味期間区分
,賞味期間区分名
,容器区分
,容器区分名
,単位区分
,単位区分名
,棚卸区分
,棚卸区分名
,トレース区分
,トレース区分名
,出荷入数
,配数
,パレット当り最大段数
,パレット段
,ケース重量容積
,原料使用量
-- 2012/08/29 T.Makuta Add Start E_本稼動_09591
,鮮度条件
,鮮度条件名称
-- 2012/08/29 T.Makuta Add End   E_本稼動_09591
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  IIMB.item_no                  item_no                     --品目コード
       ,XIMB.item_name                item_name                   --品目名
       ,XIMB.item_short_name          item_short_name             --品目略称
       ,XIMB.item_name_alt            item_name_alt               --品目カナ名
       ,XIMB.start_date_active        start_date_active           --適用開始日
       ,XIMB.end_date_active          end_date_active             --適用終了日
       ,XIMB.active_flag              active_flag                 --適用済フラグ
       ,IIMB.item_um                  item_um                     --単位
       ,IIMB.lot_ctl                  lot_ctl                     --ロット管理区分
       ,DECODE(IIMB.lot_ctl, 1, '有り', '無し')
                                      lot_ctl_name                --ロット管理区分名
       ,IIMB2.item_no                 whse_item_no                --倉庫品目コード
       ,XIMB2.item_name               whse_item_name              --倉庫品目名
       ,XIMB2.item_short_name         whse_item_short_name        --倉庫品目略称
       ,IIMB.attribute1               old_crowd_code              --旧・群コード
       ,IIMB.attribute2               new_crowd_code              --新・群コード
       ,IIMB.attribute3               crowd_code_s_date           --群コード適用開始日
       ,NVL( TO_NUMBER( IIMB.attribute4 ), 0 )
                                      old_fixed_price             --旧・定価
       ,NVL( TO_NUMBER( IIMB.attribute5 ), 0 )
                                      new_fixed_price             --新・定価
       ,IIMB.attribute6               fixed_price_s_date          --定価適用開始日
       ,NVL( TO_NUMBER( IIMB.attribute7 ), 0 )
                                      old_buss_cost               --旧・営業原価
       ,NVL( TO_NUMBER( IIMB.attribute8 ), 0 )
                                      new_buss_cost               --新・営業原価
       ,IIMB.attribute9               buss_cost_s_date            --営業原価適用開始日
       ,IIMB.attribute26              sales_target_class          --売上対象区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV01.meaning                 sales_target_class_name     --売上対象区分名
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01                               --クイックコード(売上対象区分名)
         WHERE FLV01.language    = 'JA'                               --言語
           AND FLV01.lookup_type = 'XXCMN_SALES_TARGET_CLASS'         --クイックコードタイプ
           AND FLV01.lookup_code = IIMB.attribute26                   --クイックコード
        ) sales_target_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,IIMB.attribute13              sale_s_date                 --発売（製造）開始日
       ,IIMB.attribute21              jan_code                    --JANコード
       ,IIMB.attribute22              itf_code                    --ITFコード
       ,NVL( TO_NUMBER( IIMB.attribute11 ), 0 )
                                      in_case_amount              --ケース入数
       ,NVL( TO_NUMBER( IIMB.attribute12 ), 0 )
                                      net                         --NET
       ,IIMB.attribute10              weight_capacity_class       --重量容積区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV02.meaning                 weight_capacity_class_name  --重量容積区分名
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02                               --クイックコード(重量容積区分名)
         WHERE FLV02.language    = 'JA'                               --言語
           AND FLV02.lookup_type = 'XXCMN_WEIGHT_CAPACITY_CLASS'      --クイックコードタイプ
           AND FLV02.lookup_code = IIMB.attribute10                   --クイックコード
        ) weight_capacity_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( IIMB.attribute25 ), 0 )
                                      weight                      --重量
       ,NVL( TO_NUMBER( IIMB.attribute16 ), 0 )
                                      capacity                    --容積
       ,IIMB.attribute28              destination_div             --仕向区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV03.meaning                 destination_div_name        --仕向区分名
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03                               --クイックコード(仕向区分名)
         WHERE FLV03.language    = 'JA'                                  --言語
           AND FLV03.lookup_type = 'XXCMN_DESTINATION_DIV'            --クイックコードタイプ
           AND FLV03.lookup_code = IIMB.attribute28                   --クイックコード
        ) destination_div_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,IIMB.attribute18              shipping_class              --出荷区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV04.meaning                 shipping_class_name         --出荷区分名
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04                               --クイックコード(出荷区分名)
         WHERE FLV04.language    = 'JA'                                  --言語
           AND FLV04.lookup_type = 'XXCMN_SHIPPING_CLASS'             --クイックコードタイプ
           AND FLV04.lookup_code = IIMB.attribute18                   --クイックコード
        ) shipping_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,IIMB.attribute15              cost_management             --原価管理区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV05.meaning                 cost_management_name        --原価管理区分名
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05                               --クイックコード(原価管理区分名)
         WHERE FLV05.language    = 'JA'                                  --言語
           AND FLV05.lookup_type ='XXCMN_COST_MANAGEMENT'             --クイックコードタイプ
           AND FLV05.lookup_code = IIMB.attribute15                   --クイックコード
        ) cost_management_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,IIMB.attribute20              vendor_price_deri_day       --仕入単価導出日タイプ
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV06.meaning                 vendor_price_deri_day_name  --仕入単価導出日タイプ名
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06                               --クイックコード(仕入単価導出日タイプ名)
         WHERE FLV06.language    = 'JA'                                  --言語
           AND FLV06.lookup_type = 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'   --クイックコードタイプ
           AND FLV06.lookup_code = IIMB.attribute20                   --クイックコード
        ) vendor_price_deri_day_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( IIMB.attribute17 ), 0 )
                                      representative_amount       --代表入数
       ,IIMB.attribute24              inout_conversion_uom        --入出庫換算単位
       ,IIMB.attribute23              need_test                   --試験有無区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV07.meaning                 need_test_name              --試験有無区分名
       ,(SELECT FLV07.meaning
         FROM fnd_lookup_values FLV07                               --クイックコード(試験有無区分名)
         WHERE FLV07.language    = 'JA'                                  --言語
           AND FLV07.lookup_type = 'XXCMN_NEED_TEST'                  --クイックコードタイプ
           AND FLV07.lookup_code = IIMB.attribute23                   --クイックコード
        ) need_test_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,NVL( TO_NUMBER( IIMB.attribute14 ), 0 )
                                      inspection_lt               --検査L/T
       ,NVL( TO_NUMBER( IIMB.attribute27 ), 0 )
                                      judge_Times                 --判定回数
       ,NVL( TO_NUMBER( IIMB.attribute29 ), 0 )
                                      order_possible_times        --発注可能判定回数
       ,IIMB.attribute30              reception_date              --マスタ受信日時
       ,DECODE(IIMB.autolot_active_indicator, 1, '無効', '有効')
                                      autolot_active_indicator    --自動ロット採番有効
       ,IIMB3.item_no                 parent_item_no              --親品目コード
       ,XIMB3.item_name               parent_item_name            --親品目名
       ,XIMB3.item_short_name         parent_item_short_name      --親品目略称
       ,XIMB.model_type               model_type                  --型種別
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV08.meaning                 model_type_name             --型種別名
       ,(SELECT FLV08.meaning
         FROM fnd_lookup_values FLV08                               --クイックコード(型種別名)
         WHERE FLV08.language    = 'JA'                                  --言語
           AND FLV08.lookup_type = 'XXCMN_D01'                        --クイックコードタイプ
           AND FLV08.lookup_code = XIMB.model_type                    --クイックコード
        ) model_type_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.product_class            product_class               --商品分類
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV09.meaning                 product_class_name          --商品分類名
       ,(SELECT FLV09.meaning
         FROM fnd_lookup_values FLV09                               --クイックコード(商品分類名)
         WHERE FLV09.language    = 'JA'                                  --言語
           AND FLV09.lookup_type = 'XXCMN_D02'                        --クイックコードタイプ
           AND FLV09.lookup_code = XIMB.product_class                 --クイックコード
        ) product_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.product_type             product_type                --商品種別
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV10.meaning                 product_type_name           --商品種別名
       ,(SELECT FLV10.meaning
         FROM fnd_lookup_values FLV10                               --クイックコード(商品種別名)
         WHERE FLV10.language    = 'JA'                                  --言語
           AND FLV10.lookup_type = 'XXCMN_D03'                        --クイックコードタイプ
           AND FLV10.lookup_code = XIMB.product_type                  --クイックコード
        ) product_type_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.expiration_day           expiration_day              --賞味期間
       ,XIMB.delivery_lead_time       delivery_lead_time          --納入期間
       ,XIMB.whse_county_code         whse_county_code            --工場群コード
       ,XIMB.standard_yield           standard_yield              --標準保留
       ,XIMB.shipping_end_date        shipping_end_date           --出荷停止日
       ,XIMB.rate_class               rate_class                  --率区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV11.meaning                 rate_class_name             --率区分名
       ,(SELECT FLV11.meaning
         FROM fnd_lookup_values FLV11                               --クイックコード(率区分名)
         WHERE FLV11.language    = 'JA'                                  --言語
           AND FLV11.lookup_type = 'XXCMN_RATE'                       --クイックコードタイプ
           AND FLV11.lookup_code = XIMB.rate_class                    --クイックコード
        ) rate_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.shelf_life               shelf_life                  --消費期間
       ,XIMB.shelf_life_class         shelf_life_class            --賞味期間区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV12.meaning                 shelf_life_class_name       --賞味期間区分名
       ,(SELECT FLV12.meaning
         FROM fnd_lookup_values FLV12                               --クイックコード(賞味期間区分名)
         WHERE FLV12.language    = 'JA'                                  --言語
           AND FLV12.lookup_type = 'XXCMN_SHELF_LIFE_CLASS'           --クイックコードタイプ
           AND FLV12.lookup_code = XIMB.shelf_life_class              --クイックコード
        ) shelf_life_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.bottle_class             bottle_class                --容器区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV13.meaning                 bottle_class_name           --容器区分名
       ,(SELECT FLV13.meaning
         FROM fnd_lookup_values FLV13                               --クイックコード(容器区分名)
         WHERE FLV13.language    = 'JA'                                  --言語
           AND FLV13.lookup_type = 'XXCMN_BOTTLE_CLASS'               --クイックコードタイプ
           AND FLV13.lookup_code = XIMB.bottle_class                  --クイックコード
        ) bottle_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.uom_class                uom_class                   --単位区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV14.meaning                 uom_class_name              --単位区分名
       ,(SELECT FLV14.meaning
         FROM fnd_lookup_values FLV14                               --クイックコード(単位区分名)
         WHERE FLV14.language    = 'JA'                                  --言語
           AND FLV14.lookup_type = 'XXCMN_UOM_CLASS'                  --クイックコードタイプ
           AND FLV14.lookup_code = XIMB.uom_class                     --クイックコード
        ) uom_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.inventory_chk_class      inventory_chk_class         --棚卸区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV15.meaning                 inventory_chk_class_name    --棚卸区分名
       ,(SELECT FLV15.meaning
         FROM fnd_lookup_values FLV15                               --クイックコード(棚卸区分名)
         WHERE FLV15.language    = 'JA'                                  --言語
           AND FLV15.lookup_type = 'XXCMN_INVENTORY_CHK_CLASS'        --クイックコードタイプ
           AND FLV15.lookup_code = XIMB.inventory_chk_class           --クイックコード
        ) inventory_chk_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.trace_class              trace_class                 --トレース区分
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FLV16.meaning                 trace_class_name            --トレース区分名
       ,(SELECT FLV16.meaning
         FROM fnd_lookup_values FLV16                               --クイックコード(トレース区分名)
         WHERE FLV16.language    = 'JA'                                  --言語
           AND FLV16.lookup_type = 'XXCMN_TRACE_CLASS'                --クイックコードタイプ
           AND FLV16.lookup_code = XIMB.trace_class                   --クイックコード
        ) trace_class_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,XIMB.shipping_cs_unit_qty     shipping_cs_unit_qty        --出荷入数
       ,XIMB.palette_max_cs_qty       palette_max_cs_qty          --配数
       ,XIMB.palette_max_step_qty     palette_max_step_qty        --パレット当り最大段数
       ,XIMB.palette_step_qty         palette_step_qty            --パレット段
       ,XIMB.cs_weigth_or_capacity    cs_weigth_or_capacity       --ケース重量容積
       ,XIMB.raw_material_consumption raw_material_consumption    --原料使用量
-- 2012/08/29 T.Makuta Add Start E_本稼動_09591
       ,IIMB.attribute19              freshness_condition         --鮮度条件
       ,(SELECT FLV17.meaning
         FROM fnd_lookup_values FLV17                             --クイックコード(鮮度条件名称)
         WHERE FLV17.language    = 'JA'                           --言語
           AND FLV17.lookup_type = 'XXCMN_FRESHNESS_CONDITION'    --クイックコードタイプ
           AND FLV17.lookup_code = IIMB.attribute19               --クイックコード
        ) freshness_condition_name
-- 2012/08/29 T.Makuta Add End   E_本稼動_09591
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_CB.user_name               created_by_name             --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --ユーザーマスタ(created_by名称取得用)
         WHERE XIMB.created_by = FU_CB.user_id
        ) created_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XIMB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                      creation_date               --作成日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LU.user_name               last_updated_by_name        --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --ユーザーマスタ(last_updated_by名称取得用)
         WHERE XIMB.last_updated_by = FU_LU.user_id
        ) last_updated_by_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
       ,TO_CHAR( XIMB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                      last_update_date            --更新日時
-- 2010/01/28 T.Yoshimoto Mod Start 本稼動#1168
       --,FU_LL.user_name               last_update_login_name      --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --ユーザーマスタ(last_update_login名称取得用)
              ,fnd_logins FL_LL  --ログインマスタ(last_update_login名称取得用)
         WHERE XIMB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) last_update_login_name
-- 2010/01/28 T.Yoshimoto Mod End 本稼動#1168
  FROM  ic_item_mst_b         IIMB                                --OPM品目マスタ
       ,xxcmn_item_mst_b      XIMB                                --品目マスタアドオン
       ,ic_item_mst_b         IIMB2                               --OPM品目マスタ     (倉庫品目取得用)
       ,xxcmn_item_mst_b      XIMB2                               --品目マスタアドオン(倉庫品目取得用)
       ,ic_item_mst_b         IIMB3                               --OPM品目マスタ     (親品目取得用)
       ,xxcmn_item_mst_b      XIMB3                               --品目マスタアドオン(親品目取得用)
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
       --,fnd_lookup_values     FLV01                               --クイックコード(売上対象区分名)
       --,fnd_lookup_values     FLV02                               --クイックコード(重量容積区分名)
       --,fnd_lookup_values     FLV03                               --クイックコード(仕向区分名)
       --,fnd_lookup_values     FLV04                               --クイックコード(出荷区分名)
       --,fnd_lookup_values     FLV05                               --クイックコード(原価管理区分名)
       --,fnd_lookup_values     FLV06                               --クイックコード(仕入単価導出日タイプ名)
       --,fnd_lookup_values     FLV07                               --クイックコード(試験有無区分名)
       --,fnd_lookup_values     FLV08                               --クイックコード(型種別名)
       --,fnd_lookup_values     FLV09                               --クイックコード(商品分類名)
       --,fnd_lookup_values     FLV10                               --クイックコード(商品種別名)
       --,fnd_lookup_values     FLV11                               --クイックコード(率区分名)
       --,fnd_lookup_values     FLV12                               --クイックコード(賞味期間区分名)
       --,fnd_lookup_values     FLV13                               --クイックコード(容器区分名)
       --,fnd_lookup_values     FLV14                               --クイックコード(単位区分名)
       --,fnd_lookup_values     FLV15                               --クイックコード(棚卸区分名)
       --,fnd_lookup_values     FLV16                               --クイックコード(トレース区分名)
       --,fnd_user              FU_CB                               --ユーザーマスタ(CREATED_BY名称取得用)
       --,fnd_user              FU_LU                               --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       --,fnd_user              FU_LL                               --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       --,fnd_logins            FL_LL                               --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
 WHERE  XIMB.obsolete_class <> '1'                                --廃止区分 '1:廃止'以外
   AND  XIMB.start_date_active <= TRUNC(SYSDATE)                  --適用開始日
   AND  XIMB.end_date_active   >= TRUNC(SYSDATE)                  --適用終了日
   AND  IIMB.inactive_ind <> '1'                                  --無効フラグ '1:無効'以外
   AND  IIMB.item_id = XIMB.item_id
   AND  IIMB.whse_item_id = IIMB2.item_id(+)                      --倉庫品目
   AND  IIMB.whse_item_id = XIMB2.item_id(+)                      --倉庫品目
   AND  XIMB2.start_date_active <= TRUNC(SYSDATE)                 --適用開始日
   AND  XIMB2.end_date_active   >= TRUNC(SYSDATE)                 --適用終了日
   AND  XIMB.parent_item_id = IIMB3.item_id(+)                    --親品目
   AND  XIMB.parent_item_id = XIMB3.item_id(+)                    --親品目
   AND  XIMB3.start_date_active <= TRUNC(SYSDATE)                 --適用開始日
   AND  XIMB3.end_date_active   >= TRUNC(SYSDATE)                 --適用終了日
   --クイックコード：売上対象区分名取得
-- 2010/01/28 T.Yoshimoto Del Start 本稼動#1168
   --AND  FLV01.language(+) = 'JA'                                  --言語
   --AND  FLV01.lookup_type(+) = 'XXCMN_SALES_TARGET_CLASS'         --クイックコードタイプ
   --AND  FLV01.lookup_code(+) = IIMB.attribute26                   --クイックコード
   --クイックコード：重量容積区分名取得
   --AND  FLV02.language(+) = 'JA'                                  --言語
   --AND  FLV02.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'      --クイックコードタイプ
   --AND  FLV02.lookup_code(+) = IIMB.attribute10                   --クイックコード
   --クイックコード：仕向区分名取得
   --AND  FLV03.language(+) = 'JA'                                  --言語
   --AND  FLV03.lookup_type(+) = 'XXCMN_DESTINATION_DIV'            --クイックコードタイプ
   --AND  FLV03.lookup_code(+) = IIMB.attribute28                   --クイックコード
   --クイックコード：出荷区分名取得
   --AND  FLV04.language(+) = 'JA'                                  --言語
   --AND  FLV04.lookup_type(+) = 'XXCMN_SHIPPING_CLASS'             --クイックコードタイプ
   --AND  FLV04.lookup_code(+) = IIMB.attribute18                   --クイックコード
   --クイックコード：原価管理区分名取得
   --AND  FLV05.language(+) = 'JA'                                  --言語
   --AND  FLV05.lookup_type(+) ='XXCMN_COST_MANAGEMENT'             --クイックコードタイプ
   --AND  FLV05.lookup_code(+) = IIMB.attribute15                   --クイックコード
   --クイックコード：仕入単価導出日タイプ名取得
   --AND  FLV06.language(+) = 'JA'                                  --言語
   --AND  FLV06.lookup_type(+) = 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'   --クイックコードタイプ
   --AND  FLV06.lookup_code(+) = IIMB.attribute20                   --クイックコード
   --クイックコード：試験有無区分名取得
   --AND  FLV07.language(+) = 'JA'                                  --言語
   --AND  FLV07.lookup_type(+) = 'XXCMN_NEED_TEST'                  --クイックコードタイプ
   --AND  FLV07.lookup_code(+) = IIMB.attribute23                   --クイックコード
   --クイックコード：型種別名取得
   --AND  FLV08.language(+) = 'JA'                                  --言語
   --AND  FLV08.lookup_type(+) = 'XXCMN_D01'                        --クイックコードタイプ
   --AND  FLV08.lookup_code(+) = XIMB.model_type                    --クイックコード
   --クイックコード：商品分類名取得
   --AND  FLV09.language(+) = 'JA'                                  --言語
   --AND  FLV09.lookup_type(+) = 'XXCMN_D02'                        --クイックコードタイプ
   --AND  FLV09.lookup_code(+) = XIMB.product_class                 --クイックコード
   --クイックコード：商品種別名取得
   --AND  FLV10.language(+) = 'JA'                                  --言語
   --AND  FLV10.lookup_type(+) = 'XXCMN_D03'                        --クイックコードタイプ
   --AND  FLV10.lookup_code(+) = XIMB.product_type                  --クイックコード
   --クイックコード：率区分名取得
   --AND  FLV11.language(+) = 'JA'                                  --言語
   --AND  FLV11.lookup_type(+) = 'XXCMN_RATE'                       --クイックコードタイプ
   --AND  FLV11.lookup_code(+) = XIMB.rate_class                    --クイックコード
   --クイックコード：賞味期間区分名取得
   --AND  FLV12.language(+) = 'JA'                                  --言語
   --AND  FLV12.lookup_type(+) = 'XXCMN_SHELF_LIFE_CLASS'           --クイックコードタイプ
   --AND  FLV12.lookup_code(+) = XIMB.shelf_life_class              --クイックコード
   --クイックコード：容器区分名取得
   --AND  FLV13.language(+) = 'JA'                                  --言語
   --AND  FLV13.lookup_type(+) = 'XXCMN_BOTTLE_CLASS'               --クイックコードタイプ
   --AND  FLV13.lookup_code(+) = XIMB.bottle_class                  --クイックコード
   --クイックコード：単位区分名取得
   --AND  FLV14.language(+) = 'JA'                                  --言語
   --AND  FLV14.lookup_type(+) = 'XXCMN_UOM_CLASS'                  --クイックコードタイプ
   --AND  FLV14.lookup_code(+) = XIMB.uom_class                     --クイックコード
   --クイックコード：棚卸区分名取得
   --AND  FLV15.language(+) = 'JA'                                  --言語
   --AND  FLV15.lookup_type(+) = 'XXCMN_INVENTORY_CHK_CLASS'        --クイックコードタイプ
   --AND  FLV15.lookup_code(+) = XIMB.inventory_chk_class           --クイックコード
   --クイックコード：トレース区分名取得
   --AND  FLV16.language(+) = 'JA'                                  --言語
   --AND  FLV16.lookup_type(+) = 'XXCMN_TRACE_CLASS'                --クイックコードタイプ
   --AND  FLV16.lookup_code(+) = XIMB.trace_class                   --クイックコード
   --WHOカラム取得
   --AND  XIMB.created_by = FU_CB.user_id(+)
   --AND  XIMB.last_updated_by = FU_LU.user_id(+)
   --AND  XIMB.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End 本稼動#1168
/
COMMENT ON TABLE APPS.XXSKZ_品目マスタ_現在_V IS 'SKYLINK用品目マスタ（現在）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.品目コード             IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.品目名                 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.品目略称               IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.品目カナ名             IS '品目カナ名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.適用開始日             IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.適用終了日             IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.適用済フラグ           IS '適用済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.単位                   IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.ロット管理区分         IS 'ロット管理区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.ロット管理区分名       IS 'ロット管理区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.倉庫品目コード         IS '倉庫品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.倉庫品目名             IS '倉庫品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.倉庫品目略称           IS '倉庫品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.旧_群コード            IS '旧_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.新_群コード            IS '新_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.群コード適用開始日     IS '群コード適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.旧_定価                IS '旧_定価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.新_定価                IS '新_定価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.定価適用開始日         IS '定価適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.旧_営業原価            IS '旧_営業原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.新_営業原価            IS '新_営業原価'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.営業原価適用開始日     IS '営業原価適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.売上対象区分           IS '売上対象区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.売上対象区分名         IS '売上対象区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.発売製造開始日         IS '発売製造開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.JANｺｰﾄﾞ                IS 'JANｺｰﾄﾞ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.ITFコード              IS 'ITFコード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.ケース入数             IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.NET                    IS 'NET'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.重量容積区分           IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.重量容積区分名         IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.重量                   IS '重量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.容積                   IS '容積'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.仕向区分               IS '仕向区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.仕向区分名             IS '仕向区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.出荷区分               IS '出荷区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.出荷区分名             IS '出荷区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.原価管理区分           IS '原価管理区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.原価管理区分名         IS '原価管理区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.仕入単価導出日タイプ   IS '仕入単価導出日タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.仕入単価導出日タイプ名 IS '仕入単価導出日タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.代表入数               IS '代表入数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.入出庫換算単位         IS '入出庫換算単位'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.試験有無区分           IS '試験有無区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.試験有無区分名         IS '試験有無区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.検査LT                 IS '検査LT'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.判定回数               IS '判定回数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.発注可能判定回数       IS '発注可能判定回数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.マスタ受信日時         IS 'マスタ受信日時'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.自動ロット採番有効     IS '自動ロット採番有効'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.親品目コード           IS '親品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.親品目名               IS '親品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.親品目略称             IS '親品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.型種別                 IS '型種別'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.型種別名               IS '型種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.商品分類               IS '商品分類'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.商品分類名             IS '商品分類名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.商品種別               IS '商品種別'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.商品種別名             IS '商品種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.賞味期間               IS '賞味期間'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.納入期間               IS '納入期間'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.工場群コード           IS '工場群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.標準歩留               IS '標準歩留'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.出荷停止日             IS '出荷停止日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.率区分                 IS '率区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.率区分名               IS '率区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.消費期間               IS '消費期間'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.賞味期間区分           IS '賞味期間区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.賞味期間区分名         IS '賞味期間区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.容器区分               IS '容器区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.容器区分名             IS '容器区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.単位区分               IS '単位区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.単位区分名             IS '単位区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.棚卸区分               IS '棚卸区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.棚卸区分名             IS '棚卸区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.トレース区分           IS 'トレース区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.トレース区分名         IS 'トレース区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.出荷入数               IS '出荷入数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.配数                   IS '配数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.パレット当り最大段数   IS 'パレット当り最大段数'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.パレット段             IS 'パレット段'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.ケース重量容積         IS 'ケース重量容積'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.原料使用量             IS '原料使用量'
/
-- 2012/08/29 T.Makuta Add Start E_本稼動_09591
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.鮮度条件               IS '鮮度条件'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.鮮度条件名称           IS '鮮度条件名称'
/
-- 2012/08/29 T.Makuta Add End   E_本稼動_09591
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.作成者                 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.作成日                 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.最終更新者             IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.最終更新日             IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目マスタ_現在_V.最終更新ログイン       IS '最終更新ログイン'
/
