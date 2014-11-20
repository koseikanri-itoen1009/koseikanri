CREATE OR REPLACE VIEW APPS.XXSKY_受注出荷明細_基本_V
(
 依頼NO
,明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,出荷品目
,出荷品目名
,出荷品目略称
,依頼品目
,依頼品目名
,依頼品目略称
,削除フラグ
,数量
,単位
,出荷実績数量
,指定製造日
,拠点依頼数量
,指定日付_リーフ
,移動NO
,発注NO
,顧客発注
,パレット数
,段数
,ケース数
,重量
,容積
,パレット枚数
,パレット重量
,引当数
,ステータス別数量
,警告区分
,警告区分名
,警告日付
,摘要
,出荷依頼インタフェース済フラグ
,出荷実績インタフェース済フラグ
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン)
AS
SELECT  XOL.request_no                  request_no                 --依頼No
       ,XOL.order_line_number           order_line_number          --明細番号
       ,PRODC.prod_class_code           prod_class_code            --商品区分
       ,PRODC.prod_class_name           prod_class_name            --商品区分名
       ,ITEMC.item_class_code           item_class_code            --品目区分
       ,ITEMC.item_class_name           item_class_name            --品目区分名
       ,CROWD.crowd_code                crowd_code                 --群コード
       ,XOL.shipping_item_code          shipping_item_code         --出荷品目
       ,ITEM1.item_name                 shipping_item_name         --出荷品目名
       ,ITEM1.item_short_name           shipping_item_s_name       --出荷品目略称
       ,XOL.request_item_code           request_item_code          --依頼品目
       ,ITEM2.item_name                 request_item_name          --依頼品目名
       ,ITEM2.item_short_name           request_item_s_name        --依頼品目略称
       ,XOL.delete_flag                 delete_flag                --削除フラグ
       ,XOL.quantity                    quantity                   --数量
       ,XOL.uom_code                    uom_code                   --単位
       ,XOL.shipped_quantity            shipped_quantity           --出荷実績数量
       ,XOL.designated_production_date  designated_production_date --指定製造日
       ,XOL.based_request_quantity      based_request_quantity     --拠点依頼数量
       ,XOL.designated_date             designated_date            --指定日付_リーフ
       ,XOL.move_number                 move_number                --移動No
       ,XOL.po_number                   po_number                  --発注No
       ,XOL.cust_po_number              cust_po_number             --顧客発注
       ,XOL.pallet_quantity             pallet_quantity            --パレット数
       ,XOL.layer_quantity              layer_quantity             --段数
       ,XOL.case_quantity               case_quantity              --ケース数
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XOL.weight)                weight                     --重量(小数点以下切上げ)
       ,CEIL(TRUNC(NVL(XOL.weight,0),1))                           
                                        weight                     --重量(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL(XOL.capacity)              capacity                   --容積(小数点以下切上げ)
       ,XOL.pallet_qty                  pallet_qty                 --パレット枚数
       ,CEIL(XOL.pallet_weight)         pallet_weight              --パレット重量(小数点以下切上げ)
       ,XOL.reserved_quantity           reserved_quantity          --引当数
       ,XOL.status_quantity             status_quantity            --ステータス別数量
       ,XOL.warning_class               warning_class              --警告区分
       ,FLV01.meaning                   warning_c_name             --警告区分名
       ,XOL.warning_date                warning_date               --警告日付
       ,XOL.line_description            line_description           --摘要
       ,XOL.shipping_request_if_flg     shipping_request_if_flg    --出荷依頼インタフェース済フラグ
       ,XOL.shipping_result_if_flg      shipping_result_if_flg     --出荷実績インタフェース済フラグ
       ,FU_CB.user_name                 created_by_name            --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XOL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date              --作成日時
       ,FU_LU.user_name                 last_updated_by_name       --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XOL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date           --更新日時
       ,FU_LL.user_name                 last_update_login_name     --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  ( --名称取得系以外のデータはこの内部SQLで全て取得する
          SELECT XOLA.request_no                                   --依頼No
                ,XOLA.order_line_number                            --明細番号
                ,XOLA.shipping_item_code                           --出荷品目コード
                ,XOLA.request_item_code                            --依頼品目コード
                ,XOLA.delete_flag                                  --削除フラグ
                ,XOLA.quantity                                     --数量
                ,XOLA.uom_code                                     --単位
                ,XOLA.shipped_quantity                             --出荷実績数量
                ,XOLA.designated_production_date                   --指定製造日
                ,XOLA.based_request_quantity                       --拠点依頼数量
                ,XOLA.designated_date                              --指定日付_リーフ
                ,XOLA.move_number                                  --移動No
                ,XOLA.po_number                                    --発注No
                ,XOLA.cust_po_number                               --顧客発注
                ,XOLA.pallet_quantity                              --パレット数
                ,XOLA.layer_quantity                               --段数
                ,XOLA.case_quantity                                --ケース数
                ,XOLA.weight                                       --重量
                ,XOLA.capacity                                     --容積
                ,XOLA.pallet_qty                                   --パレット枚数
                ,XOLA.pallet_weight                                --パレット重量
                ,XOLA.reserved_quantity                            --引当数
                ,CASE WHEN XOHA.req_status = '04' THEN XOLA.shipped_quantity        --実績時
                      WHEN XOHA.req_status = '03' THEN XOLA.quantity                --指示時
                      ELSE                             XOLA.based_request_quantity  --依頼時
                 END                              status_quantity  --ステータス別数量
                ,XOLA.warning_class                                --警告区分
                ,XOLA.warning_date                                 --警告日付
                ,XOLA.line_description                             --摘要
                ,XOLA.shipping_request_if_flg                      --出荷依頼インタフェース済フラグ
                ,XOLA.shipping_result_if_flg                       --出荷実績インタフェース済フラグ
                ,XOLA.created_by                                   --作成者
                ,XOLA.creation_date                                --作成日
                ,XOLA.last_updated_by                              --最終更新者
                ,XOLA.last_update_date                             --最終更新日
                ,XOLA.last_update_login                            --最終更新ログイン
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( 着荷日, 着荷予定日 )
                                                  arrival_date     --着荷日 (⇒品目名称取得で使用)
          FROM   xxwsh_order_headers_all   XOHA
                ,xxwsh_order_lines_all     XOLA
                ,oe_transaction_types_all  OTTA
          WHERE
                 XOHA.order_header_id = XOLA.order_header_id
          AND    XOHA.order_type_id = OTTA.transaction_type_id
          AND    OTTA.attribute1 = '1'                             --1:出荷
          AND    XOHA.latest_external_flag = 'Y'
          AND    NVL(XOLA.delete_flag, 'N') <> 'Y'
        )                     XOL     --明細情報
       ,xxsky_item_mst2_v     ITEM1    --出荷品目名称取得用
       ,xxsky_item_mst2_v     ITEM2    --依頼品目名称取得用
       ,xxsky_prod_class_v    PRODC    --商品区分取得用
       ,xxsky_item_class_v    ITEMC    --品目区分取得用
       ,xxsky_crowd_code_v    CROWD    --群コード取得用
       ,fnd_lookup_values     FLV01    --警告区分名取得用
       ,fnd_user                     FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                     FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                     FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                   FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        --出荷品目情報取得条件
        XOL.shipping_item_code =  ITEM1.item_no(+)
   AND  XOL.arrival_date       >= ITEM1.start_date_active(+)
   AND  XOL.arrival_date       <= ITEM1.end_date_active(+)
        --出荷品目のカテゴリ情報取得条件
   AND  ITEM1.item_id = PRODC.item_id(+)    --商品区分
   AND  ITEM1.item_id = ITEMC.item_id(+)    --品目区分
   AND  ITEM1.item_id = CROWD.item_id(+)    --群コード
        --依頼品目情報取得条件
   AND  XOL.request_item_code =  ITEM2.item_no(+)
   AND  XOL.arrival_date      >= ITEM2.start_date_active(+)
   AND  XOL.arrival_date      <= ITEM2.end_date_active(+)
        --警告区分名取得条件
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWSH_WARNING_CLASS'
   AND  FLV01.lookup_code(+) = XOL.warning_class
        --WHOカラム取得
   AND  XOL.created_by        = FU_CB.user_id(+)
   AND  XOL.last_updated_by   = FU_LU.user_id(+)
   AND  XOL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_受注出荷明細_基本_V IS 'SKYLINK用 受注出荷明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.依頼NO IS '依頼NO'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷品目 IS '出荷品目'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷品目名 IS '出荷品目名'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷品目略称 IS '出荷品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.依頼品目 IS '依頼品目'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.依頼品目名 IS '依頼品目名'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.依頼品目略称 IS '依頼品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.削除フラグ IS '削除フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷実績数量 IS '出荷実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.指定製造日 IS '指定製造日'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.拠点依頼数量 IS '拠点依頼数量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.指定日付_リーフ IS '指定日付_リーフ'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.移動NO IS '移動NO'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.発注NO IS '発注NO'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.顧客発注 IS '顧客発注'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.パレット数 IS 'パレット数'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.段数 IS '段数'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.ケース数 IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.容積 IS '容積'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.パレット枚数 IS 'パレット枚数'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.パレット重量 IS 'パレット重量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.引当数 IS '引当数'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.ステータス別数量 IS 'ステータス別数量'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.警告区分 IS '警告区分'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.警告区分名 IS '警告区分名'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.警告日付 IS '警告日付'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.摘要 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷依頼インタフェース済フラグ IS '出荷依頼インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.出荷実績インタフェース済フラグ IS '出荷実績インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_受注出荷明細_基本_V.最終更新ログイン IS '最終更新ログイン'
/
