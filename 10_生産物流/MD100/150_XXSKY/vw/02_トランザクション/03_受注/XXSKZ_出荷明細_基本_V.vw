/*************************************************************************
 * 
 * View  Name      : XXSKZ_出荷明細_基本_V
 * Description     : XXSKZ_出荷明細_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出荷明細_基本_V
(
 依頼NO
,明細番号
,レコードタイプ
,レコードタイプ名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,出荷品目
,出荷品目名
,出荷品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,削除フラグ
,数量
,単位
,出荷実績数量
,指定製造日
,拠点依頼数量
,依頼品目
,依頼品目名
,依頼品目略称
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
,警告区分
,警告区分名
,警告日付
,摘要
,出荷依頼インタフェース済フラグ
,出荷実績インタフェース済フラグ
,実績日
,実績数量
,訂正前実績数量
,自動手動引当区分
,自動手動引当区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XOLL.request_no                 request_no                 --依頼No
       ,XOLL.order_line_number          order_line_number          --明細番号
       ,XOLL.record_type_code           record_type_code           --レコードタイプ
       ,FLV01.meaning                   record_type_name           --レコードタイプ名
       ,PRODC.prod_class_code           prod_class_code            --商品区分
       ,PRODC.prod_class_name           prod_class_name            --商品区分名
       ,ITEMC.item_class_code           item_class_code            --品目区分
       ,ITEMC.item_class_name           item_class_name            --品目区分名
       ,CROWD.crowd_code                crowd_code                 --群コード
       ,XOLL.shipping_item_code         shipping_item_code         --出荷品目
       ,ITEM1.item_name                 shipping_item_name         --出荷品目名
       ,ITEM1.item_short_name           shipping_item_s_name       --出荷品目略称
       ,NVL( DECODE( XOLL.lot_no, 'DEFAULTLOT', '0', XOLL.lot_no ), '0' )
                                        lot_no                     --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.lot_date       --ロット管理品   →製造年月日を取得
             ELSE NULL                                       --非ロット管理品 →NULL
        END                             lot_date                   --製造年月日
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.lot_sign       --ロット管理品   →固有記号を取得
             ELSE NULL                                       --非ロット管理品 →NULL
        END                             lot_sign                   --固有記号
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.best_bfr_date  --ロット管理品   →賞味期限を取得
             ELSE NULL                                       --非ロット管理品 →NULL
        END                             best_bfr_date              --賞味期限
       ,XOLL.delete_flag                delete_flag                --削除フラグ
       ,XOLL.quantity                   quantity                   --数量
       ,XOLL.uom_code                   uom_code                   --単位
       ,XOLL.shipped_quantity           shipped_quantity           --出荷実績数量
       ,XOLL.designated_production_date designated_production_date --指定製造日
       ,XOLL.based_request_quantity     based_request_quantity     --拠点依頼数量
       ,XOLL.request_item_code          request_item_code          --依頼品目
       ,ITEM2.item_name                 request_item_name          --依頼品目名
       ,ITEM2.item_short_name           request_item_s_name        --依頼品目略称
       ,XOLL.designated_date            designated_date            --指定日付_リーフ
       ,XOLL.move_number                move_number                --移動No
       ,XOLL.po_number                  po_number                  --発注No
       ,XOLL.cust_po_number             cust_po_number             --顧客発注
       ,XOLL.pallet_quantity            pallet_quantity            --パレット数
       ,XOLL.layer_quantity             layer_quantity             --段数
       ,XOLL.case_quantity              case_quantity              --ケース数
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XOLL.weight)               weight                     --重量(小数点以下切上げ)
       ,CEIL(TRUNC(NVL(XOLL.weight,0),1))
                                        weight                     --重量(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL(XOLL.capacity)             capacity                   --容積(小数点以下切上げ)
       ,XOLL.pallet_qty                 pallet_qty                 --パレット枚数
       ,CEIL(XOLL.pallet_weight)        pallet_weight              --パレット重量(小数点以下切上げ)
       ,XOLL.reserved_quantity          reserved_quantity          --引当数
       ,XOLL.warning_class              warning_class              --警告区分
       ,FLV02.meaning                   warning_c_name             --警告区分名
       ,XOLL.warning_date               warning_date               --警告日付
       ,XOLL.line_description           line_description           --摘要
       ,XOLL.shipping_request_if_flg    shipping_request_if_flg    --出荷依頼インタフェース済フラグ
       ,XOLL.shipping_result_if_flg     shipping_result_if_flg     --出荷実績インタフェース済フラグ
       ,XOLL.actual_date                actual_date                --実績日
       ,XOLL.actual_quantity            actual_quantity            --実績数量
       ,XOLL.before_actual_quantity     before_actual_quantity     --訂正前実績数量
       ,XOLL.automanual_reserve_class   automanual_reserve_class   --自動手動引当区分
       ,FLV03.meaning                   automanual_reserve_c_name  --自動手動引当区分名
       ,FU_CB.user_name                 created_by_name            --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XOLL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date              --作成日時
       ,FU_LU.user_name                 last_updated_by_name       --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XOLL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date           --更新日時
       ,FU_LL.user_name                 last_update_login_name     --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  ( --名称取得系以外のデータはこの内部SQLで全て取得する
          SELECT XOLA.request_no                                   --依頼No
                ,XOLA.order_line_number                            --明細番号
                ,XMLD.record_type_code                             --レコードタイプ
                ,XOLA.shipping_item_code                           --出荷品目コード
                ,XMLD.lot_no                                       --ロットNo
                ,ILTM.attribute1           lot_date                --製造年月日
                ,ILTM.attribute2           lot_sign                --固有記号
                ,ILTM.attribute3           best_bfr_date           --賞味期限
                ,XOLA.delete_flag                                  --削除フラグ
                ,XOLA.quantity                                     --数量
                ,XOLA.uom_code                                     --単位
                ,XOLA.shipped_quantity                             --出荷実績数量
                ,XOLA.designated_production_date                   --指定製造日
                ,XOLA.based_request_quantity                       --拠点依頼数量
                ,XOLA.request_item_code                            --依頼品目コード
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
                ,XOLA.warning_class                                --警告区分
                ,XOLA.warning_date                                 --警告日付
                ,XOLA.line_description                             --摘要
                ,XOLA.shipping_request_if_flg                      --出荷依頼インタフェース済フラグ
                ,XOLA.shipping_result_if_flg                       --出荷実績インタフェース済フラグ
                ,XMLD.actual_date                                  --実績日
                ,XMLD.actual_quantity                              --実績数量
                ,XMLD.before_actual_quantity                       --訂正前実績数量
                ,XMLD.automanual_reserve_class                     --自動手動引当区分
                ,XMLD.created_by                                   --作成者
                ,XMLD.creation_date                                --作成日
                ,XMLD.last_updated_by                              --最終更新者
                ,XMLD.last_update_date                             --最終更新日
                ,XMLD.last_update_login                            --最終更新ログイン
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( 着荷日, 着荷予定日 )
                                                  arrival_date     --着荷日 (⇒品目名称取得で使用)
          FROM   xxcmn_order_headers_all_arc   XOHA  --受注ヘッダ（アドオン）バックアップ
                ,xxcmn_order_lines_all_arc     XOLA  --受注明細（アドオン）バックアップ
                ,oe_transaction_types_all  OTTA
                ,xxcmn_mov_lot_details_arc     XMLD  --移動ロット詳細（アドオン）バックアップ
                ,ic_lots_mst               ILTM                    --ロット情報取得用
          WHERE  XOHA.order_header_id = XOLA.order_header_id
          AND    XOHA.order_type_id = OTTA.transaction_type_id
          AND    XOHA.latest_external_flag = 'Y'
          AND    NVL(XOLA.delete_flag, 'N') <> 'Y'
          AND    OTTA.attribute1 = '1'                             --1:出荷
          AND    XMLD.document_type_code(+) = '10'                 --10:出荷依頼
          AND    XOLA.order_line_id = XMLD.mov_line_id(+)
          AND    XMLD.item_id = ILTM.item_id(+)
          AND    XMLD.lot_id = ILTM.lot_id(+)
        )                     XOLL     --明細＆LOT詳細情報
        --以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
       ,xxskz_item_mst2_v     ITEM1    --出荷品目名称取得用
       ,xxskz_item_mst2_v     ITEM2    --依頼品目名称取得用
       ,xxskz_prod_class_v    PRODC    --商品区分取得用
       ,xxskz_item_class_v    ITEMC    --品目区分取得用
       ,xxskz_crowd_code_v    CROWD    --群コード取得用
       ,fnd_lookup_values     FLV01    --レコードタイプ名取得用
       ,fnd_lookup_values     FLV02    --警告区分名取得用
       ,fnd_lookup_values     FLV03    --自動手動引当区分名取得用
       ,fnd_user              FU_CB    --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user              FU_LU    --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user              FU_LL    --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins            FL_LL    --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   --出荷品目情報取得条件
        XOLL.shipping_item_code =  ITEM1.item_no(+)
   AND  XOLL.arrival_date       >= ITEM1.start_date_active(+)
   AND  XOLL.arrival_date       <= ITEM1.end_date_active(+)
   --出荷品目のカテゴリ情報取得条件
   AND  ITEM1.item_id = PRODC.item_id(+)    --商品区分
   AND  ITEM1.item_id = ITEMC.item_id(+)    --品目区分
   AND  ITEM1.item_id = CROWD.item_id(+)    --群コード
   --依頼品目情報取得条件
   AND  XOLL.request_item_code =  ITEM2.item_no(+)
   AND  XOLL.arrival_date      >= ITEM2.start_date_active(+)
   AND  XOLL.arrival_date      <= ITEM2.end_date_active(+)
   --レコードタイプ名取得条件
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV01.lookup_code(+) = XOLL.record_type_code
   --警告区分名取得条件
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWSH_WARNING_CLASS'
   AND  FLV02.lookup_code(+) = XOLL.warning_class
   --自動手動引当区分名取得条件
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV03.lookup_code(+) = XOLL.automanual_reserve_class
   --WHOカラム取得
   AND  XOLL.created_by        = FU_CB.user_id(+)
   AND  XOLL.last_updated_by   = FU_LU.user_id(+)
   AND  XOLL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_出荷明細_基本_V IS 'SKYLINK用出荷明細基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.依頼NO IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.レコードタイプ IS 'レコードタイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.レコードタイプ名 IS 'レコードタイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷品目 IS '出荷品目'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷品目名 IS '出荷品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷品目略称 IS '出荷品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.ロットNO IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.製造年月日 IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.固有記号 IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.賞味期限 IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.削除フラグ IS '削除フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷実績数量 IS '出荷実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.指定製造日 IS '指定製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.拠点依頼数量 IS '拠点依頼数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.依頼品目 IS '依頼品目'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.依頼品目名 IS '依頼品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.依頼品目略称 IS '依頼品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.指定日付_リーフ IS '指定日付_リーフ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.移動NO IS '移動No'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.発注NO IS '発注No'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.顧客発注 IS '顧客発注'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.パレット数 IS 'パレット数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.段数 IS '段数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.ケース数 IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.容積 IS '容積'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.パレット枚数 IS 'パレット枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.パレット重量 IS 'パレット重量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.引当数 IS '引当数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.警告区分 IS '警告区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.警告区分名 IS '警告区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.警告日付 IS '警告日付'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.摘要 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷依頼インタフェース済フラグ IS '出荷依頼インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.出荷実績インタフェース済フラグ IS '出荷実績インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.実績日 IS '実績日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.実績数量 IS '実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.訂正前実績数量 IS '訂正前実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.自動手動引当区分 IS '自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.自動手動引当区分名 IS '自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷明細_基本_V.最終更新ログイン IS '最終更新ログイン'
/
