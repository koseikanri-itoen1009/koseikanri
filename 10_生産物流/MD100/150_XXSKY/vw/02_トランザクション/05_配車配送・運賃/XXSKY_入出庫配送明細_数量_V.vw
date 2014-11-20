CREATE OR REPLACE VIEW APPS.XXSKY_入出庫配送明細_数量_V
(
 依頼_移動NO
,タイプ
,移動タイプ
,移動タイプ名
,明細番号
,レコードタイプ
,レコードタイプ名
,組織名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,出荷移動_品目
,出荷移動_品目名
,出荷移動_品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,削除フラグ
,依頼数量
,指示数量
,単位
,指定製造日
,依頼品目
,依頼品目名
,依頼品目略称
,付帯コード
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
,参照移動番号
,参照発注番号
,初回指示数量
,出庫実績数量
,入庫実績数量,警告区分
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
SELECT
        SPML.request_no                                     request_no                    --依頼_移動NO
       ,SPML.type                                           type                          --タイプ
       ,SPML.mov_type                                       mov_type                      --移動タイプ
       ,SPML.mov_type_name                                  mov_type_name                 --移動タイプ名
       ,SPML.line_number                                    line_number                   --明細番号
       ,SPML.record_type_code                               record_type_code              --レコードタイプ
       ,FLV01.meaning                                       record_type_name              --レコードタイプ名
       ,HAOUT.name                                          organization_name             --組織名
       ,PRODC.prod_class_code                               prod_class_code               --商品区分
       ,PRODC.prod_class_name                               prod_class_name               --商品区分名
       ,ITEMC.item_class_code                               item_class_code               --品目区分
       ,ITEMC.item_class_name                               item_class_name               --品目区分名
       ,CROWD.crowd_code                                    crowd_code                    --群コード
       ,SPML.shipping_item_code                             shipping_item_code            --出荷移動_品目
       ,ITEM1.item_name                                     shipping_item_name            --出荷移動_品目名
       ,ITEM1.item_short_name                               shipping_item_s_name          --出荷移動_品目略称
       ,NVL( DECODE( SPML.lot_no, 'DEFAULTLOT', '0', SPML.lot_no ), '0' )
                                                            lot_no                        --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute1  --ロット管理品   →製造年月日を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 lot_date                      --製造年月日
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute2  --ロット管理品   →固有記号を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 lot_sign                      --固有記号
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute3  --ロット管理品   →賞味期限を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 best_bfr_date                 --賞味期限
       ,SPML.delete_flag                                    delete_flag                   --削除フラグ
       ,SPML.request_quantity                               request_quantity              --依頼数量
       ,SPML.instruct_quantity                              instruct_quantity             --指示数量
       ,SPML.uom_code                                       uom_code                      --単位
       ,SPML.designated_production_date                     designated_production_date    --指定製造日
       ,SPML.request_item_code                              request_item_code             --依頼品目
       ,ITEM2.item_name                                     request_item_name             --依頼品目名
       ,ITEM2.item_short_name                               request_item_s_name           --依頼品目略称
       ,SPML.futai_code                                     futai_code                    --付帯コード
       ,SPML.designated_date                                designated_date               --指定日付_リーフ
       ,SPML.move_number                                    move_number                   --移動No
       ,SPML.po_number                                      po_number                     --発注No
       ,SPML.cust_po_number                                 cust_po_number                --顧客発注
       ,SPML.pallet_quantity                                pallet_quantity               --パレット数
       ,SPML.layer_quantity                                 layer_quantity                --段数
       ,SPML.case_quantity                                  case_quantity                 --ケース数
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( SPML.weight )                                 weight                        --重量
       ,CEIL( TRUNC(NVL(SPML.weight,0),1) )                 weight                        --重量(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( SPML.capacity )                               capacity                      --容積
       ,SPML.pallet_qty                                     pallet_qty                    --パレット枚数
       ,CEIL( SPML.pallet_weight )                          pallet_weight                 --パレット重量
       ,SPML.reserved_quantity                              reserved_quantity             --引当数
       ,SPML.move_num                                       move_num                      --参照移動番号
       ,SPML.po_num                                         po_num                        --参照発注番号
       ,SPML.first_instruct_qty                             first_instruct_qty            --初回指示数量
       ,SPML.shipped_quantity                               shipped_quantity              --出庫実績数量
       ,SPML.ship_to_quantity                               ship_to_quantity              --入庫実績数量
       ,SPML.warning_class                                  warning_class                 --警告区分
       ,FLV02.meaning                                       warning_name                  --警告区分名
       ,SPML.warning_date                                   warning_date                  --警告日付
       ,SPML.line_description                               line_description              --摘要
       ,SPML.shipping_request_if_flg                        shipping_request_if_flg       --出荷依頼インタフェース済フラグ
       ,SPML.shipping_result_if_flg                         shipping_result_if_flg        --出荷実績インタフェース済フラグ
       ,SPML.actual_date                                    actual_date                   --実績日
       ,SPML.actual_quantity                                actual_quantity               --実績数量
       ,SPML.before_actual_quantity                         before_actual_quantity        --訂正前実績数量
       ,SPML.automanual_reserve_class                       automanual_reserve_class      --自動手動引当区分
       ,FLV03.meaning                                       automanual_reserve_name       --自動手動引当区分名
       ,FU_CB.user_name                                     created_by_name               --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( SPML.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            creation_date                 --作成日時
       ,FU_LU.user_name                                     last_updated_by_name          --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( SPML.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            last_update_date              --更新日時
       ,FU_LL.user_name                                     last_update_login_name        --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM (
         --==========================
         -- 出荷データ
         --==========================
         SELECT
                 XOLA.request_no                            request_no                    --依頼_移動No
                ,OTTT.name                                  type                          --タイプ
                ,NULL                                       mov_type                      --移動タイプ
                ,NULL                                       mov_type_name                 --移動タイプ名
                ,XOLA.order_line_number                     line_number                   --明細番号
                ,XMLD.record_type_code                      record_type_code              --レコードタイプ
                ,XOHA.organization_id                       organization_id               --組織ID
                ,ITEM1.item_id                              shipping_item_id              --出荷移動_品目ID
                ,XOLA.shipping_item_code                    shipping_item_code            --出荷移動_品目
                ,XMLD.lot_id                                lot_id                        --ロットID
                ,XMLD.lot_no                                lot_no                        --ロットNo
                ,XOLA.delete_flag                           delete_flag                   --削除フラグ
                ,XOLA.based_request_quantity                request_quantity              --依頼数量
                ,XOLA.quantity                              instruct_quantity             --指示数量
                ,XOLA.uom_code                              uom_code                      --単位
                ,XOLA.designated_production_date            designated_production_date    --指定製造日
                ,ITEM2.item_id                              request_item_id               --依頼品目ID
                ,XOLA.request_item_code                     request_item_code             --依頼品目
                ,NULL                                       futai_code                    --付帯コード
                ,XOLA.designated_date                       designated_date               --指定日付_リーフ
                ,XOLA.move_number                           move_number                   --移動No
                ,XOLA.po_number                             po_number                     --発注No
                ,XOLA.cust_po_number                        cust_po_number                --顧客発注
                ,XOLA.pallet_quantity                       pallet_quantity               --パレット数
                ,XOLA.layer_quantity                        layer_quantity                --段数
                ,XOLA.case_quantity                         case_quantity                 --ケース数
                ,XOLA.weight                                weight                        --重量
                ,XOLA.capacity                              capacity                      --容積
                ,XOLA.pallet_qty                            pallet_qty                    --パレット枚数
                ,XOLA.pallet_weight                         pallet_weight                 --パレット重量
                ,XOLA.reserved_quantity                     reserved_quantity             --引当数
                ,NULL                                       move_num                      --参照移動番号
                ,NULL                                       po_num                        --参照発注番号
                ,NULL                                       first_instruct_qty            --初回指示数量
                ,XOLA.shipped_quantity                      shipped_quantity              --出庫実績数量
                ,NULL                                       ship_to_quantity              --入庫実績数量
                ,XOLA.warning_class                         warning_class                 --警告区分
                ,XOLA.warning_date                          warning_date                  --警告日付
                ,XOLA.line_description                      line_description              --摘要
                ,XOLA.shipping_request_if_flg               shipping_request_if_flg       --出荷依頼インタフェース済フラグ
                ,XOLA.shipping_result_if_flg                shipping_result_if_flg        --出荷実績インタフェース済フラグ
                ,XMLD.actual_date                           actual_date                   --実績日
                ,XMLD.actual_quantity                       actual_quantity               --実績数量
                ,XMLD.before_actual_quantity                before_actual_quantity        --訂正前実績数量
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --自動手動引当区分
                ,XMLD.created_by                            created_by                    --作成者
                ,XMLD.creation_date                         creation_date                 --作成日
                ,XMLD.last_updated_by                       last_updated_by               --最終更新者
                ,XMLD.last_update_date                      last_update_date              --最終更新日
                ,XMLD.last_update_login                     last_update_login             --最終更新ログイン
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( 着荷日, 着荷予定日 )
                                                            arrival_date                  --着荷日 (⇒品目名称取得で使用)
          FROM   xxwsh_order_headers_all     XOHA           --受注ヘッダアドオン
                ,oe_transaction_types_all    OTTA           --受注タイプマスタ
                ,oe_transaction_types_tl     OTTT           --受注タイプマスタ(日本語)
                ,xxwsh_order_lines_all       XOLA           --受注明細アドオン
                ,ic_item_mst_b               ITEM1          --品目マスタ(出荷品目の品目ID取得用)
                ,ic_item_mst_b               ITEM2          --品目マスタ(依頼品目の品目ID取得用)
                ,xxinv_mov_lot_details       XMLD           --移動ロット詳細アドオン
          WHERE
            --出荷情報の取得
                 OTTA.attribute1             = '1'          --出荷
            AND  XOHA.latest_external_flag   = 'Y'          --最新フラグが有効
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --受注タイプ名取得条件
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --受注明細情報の取得
            AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
            AND  XOHA.order_header_id        = XOLA.order_header_id
            --出荷品目ID取得
            AND  XOLA.shipping_item_code     = ITEM1.item_no
            --依頼品目ID取得
            AND  XOLA.request_item_code      = ITEM2.item_no
            --移動ロット詳細情報の取得
            AND  XMLD.document_type_code(+)  = '10'         --出荷依頼
            AND  XOLA.order_line_id          = XMLD.mov_line_id(+)
         --[ 出荷データ  END ]
        UNION ALL
         --==========================
         -- 支給データ
         --==========================
         SELECT
                 XOLA.request_no                            request_no                    --依頼_移動No
                ,OTTT.name                                  type                          --タイプ
                ,NULL                                       mov_type                      --移動タイプ
                ,NULL                                       mov_type_name                 --移動タイプ名
                ,XOLA.order_line_number                     line_number                   --明細番号
                ,XMLD.record_type_code                      record_type_code              --レコードタイプ
                ,XOHA.organization_id                       organization_id               --組織ID
                ,ITEM1.item_id                              shipping_item_id              --出荷移動_品目ID
                ,XOLA.shipping_item_code                    shipping_item_code            --出荷移動_品目
                ,XMLD.lot_id                                lot_id                        --ロットID
                ,XMLD.lot_no                                lot_no                        --ロットNo
                ,XOLA.delete_flag                           delete_flag                   --削除フラグ
                ,XOLA.based_request_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            request_quantity              --依頼数量
                ,XOLA.quantity               * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            instruct_quantity             --指示数量
                ,XOLA.uom_code                              uom_code                      --単位
                ,NULL                                       designated_production_date    --指定製造日
                ,ITEM2.item_id                              request_item_id               --依頼品目ID
                ,XOLA.request_item_code                     request_item_code             --依頼品目
                ,XOLA.futai_code                            futai_code                    --付帯コード
                ,NULL                                       designated_date               --指定日付_リーフ
                ,NULL                                       move_number                   --移動No
                ,NULL                                       po_number                     --発注No
                ,NULL                                       cust_po_number                --顧客発注
                ,XOLA.pallet_quantity                       pallet_quantity               --パレット数
                ,XOLA.layer_quantity                        layer_quantity                --段数
                ,XOLA.case_quantity                         case_quantity                 --ケース数
                ,XOLA.weight                                weight                        --重量
                ,XOLA.capacity                              capacity                      --容積
                ,XOLA.pallet_qty                            pallet_qty                    --パレット枚数
                ,XOLA.pallet_weight                         pallet_weight                 --パレット重量
                ,XOLA.reserved_quantity      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            reserved_quantity             --引当数
                ,NULL                                       move_num                      --参照移動番号
                ,NULL                                       po_num                        --参照発注番号
                ,NULL                                       first_instruct_qty            --初回指示数量
                ,XOLA.shipped_quantity       * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            shipped_quantity              --出庫実績数量
                ,XOLA.ship_to_quantity       * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            ship_to_quantity              --入庫実績数量
                ,XOLA.warning_class                         warning_class                 --警告区分
                ,XOLA.warning_date                          warning_date                  --警告日付
                ,XOLA.line_description                      line_description              --摘要
                ,NULL                                       shipping_request_if_flg       --出荷依頼インタフェース済フラグ
                ,NULL                                       shipping_result_if_flg        --出荷実績インタフェース済フラグ
                ,XMLD.actual_date                           actual_date                   --実績日
                ,XMLD.actual_quantity        * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            actual_quantity               --実績数量
                ,XMLD.before_actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --返品の場合はマイナス値
                                                            before_actual_quantity        --訂正前実績数量
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --自動手動引当区分
                ,XMLD.created_by                            created_by                    --作成者
                ,XMLD.creation_date                         creation_date                 --作成日
                ,XMLD.last_updated_by                       last_updated_by               --最終更新者
                ,XMLD.last_update_date                      last_update_date              --最終更新日
                ,XMLD.last_update_login                     last_update_login             --最終更新ログイン
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( 着荷日, 着荷予定日 )
                                                            arrival_date                  --着荷日 (⇒品目名称取得で使用)
          FROM   xxwsh_order_headers_all     XOHA           --受注ヘッダアドオン
                ,oe_transaction_types_all    OTTA           --受注タイプマスタ
                ,oe_transaction_types_tl     OTTT           --受注タイプマスタ(日本語)
                ,xxwsh_order_lines_all       XOLA           --受注明細アドオン
                ,ic_item_mst_b               ITEM1          --品目マスタ(出荷品目の品目ID取得用)
                ,ic_item_mst_b               ITEM2          --品目マスタ(依頼品目の品目ID取得用)
                ,xxinv_mov_lot_details       XMLD           --移動ロット詳細アドオン
          WHERE
            --出荷情報の取得
                 OTTA.attribute1             = '2'          --支給
            AND  XOHA.latest_external_flag   = 'Y'          --最新フラグが有効
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --受注タイプ名取得条件
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --受注明細情報の取得
            AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
            AND  XOHA.order_header_id        = XOLA.order_header_id
            --出荷品目ID取得
            AND  XOLA.shipping_item_code     = ITEM1.item_no
            --依頼品目ID取得
            AND  XOLA.request_item_code      = ITEM2.item_no
            --移動ロット詳細情報の取得
            AND  XMLD.document_type_code(+)  = '30'         --支給指示
            AND  XOLA.order_line_id          = XMLD.mov_line_id(+)
         --[ 支給データ  END ]
        UNION ALL
         --==========================
         -- 移動データ
         --==========================
         SELECT
                 XMVH.mov_num                               request_no                    --依頼_移動No
                ,'移動'                                     type                          --タイプ
                ,XMVH.mov_type                              mov_type                      --移動タイプ
                ,FLV01.meaning                              mov_type_name                 --移動タイプ名
                ,XMVL.line_number                           line_number                   --明細番号
                ,XMLD.record_type_code                      record_type_code              --レコードタイプ
                ,XMVL.organization_id                       organization_id               --組織ID
                ,XMVL.item_id                               shipping_item_id              --出荷移動_品目ID
                ,XMVL.item_code                             shipping_item_code            --出荷移動_品目
                ,XMLD.lot_id                                lot_id                        --ロットID
                ,XMLD.lot_no                                lot_no                        --ロットNo
                ,XMVL.delete_flg                            delete_flag                   --削除フラグ
                ,XMVL.request_qty                           request_quantity              --依頼数量
                ,XMVL.instruct_qty                          instruct_quantity             --指示数量
                ,XMVL.uom_code                              uom_code                      --単位
                ,XMVL.designated_production_date            designated_production_date    --指定製造日
                ,NULL                                       request_item_id               --依頼品目ID
                ,NULL                                       request_item_code             --依頼品目
                ,NULL                                       futai_code                    --付帯コード
                ,NULL                                       designated_date               --指定日付_リーフ
                ,NULL                                       move_number                   --移動No
                ,NULL                                       po_number                     --発注No
                ,NULL                                       cust_po_number                --顧客発注
                ,XMVL.pallet_quantity                       pallet_quantity               --パレット数
                ,XMVL.layer_quantity                        layer_quantity                --段数
                ,XMVL.case_quantity                         case_quantity                 --ケース数
                ,XMVL.weight                                weight                        --重量
                ,XMVL.capacity                              capacity                      --容積
                ,XMVL.pallet_qty                            pallet_qty                    --パレット枚数
                ,XMVL.pallet_weight                         pallet_weight                 --パレット重量
                ,XMVL.reserved_quantity                     reserved_quantity             --引当数
                ,XMVL.move_num                              move_num                      --参照移動番号
                ,XMVL.po_num                                po_num                        --参照発注番号
                ,XMVL.first_instruct_qty                    first_instruct_qty            --初回指示数量
                ,XMVL.shipped_quantity                      shipped_quantity              --出庫実績数量
                ,XMVL.ship_to_quantity                      ship_to_quantity              --入庫実績数量
                ,XMVL.warning_class                         warning_class                 --警告区分
                ,XMVL.warning_date                          warning_date                  --警告日付
                ,NULL                                       line_description              --摘要
                ,NULL                                       shipping_request_if_flg       --出荷依頼インタフェース済フラグ
                ,NULL                                       shipping_result_if_flg        --出荷実績インタフェース済フラグ
                ,XMLD.actual_date                           actual_date                   --実績日
                ,XMLD.actual_quantity                       actual_quantity               --実績数量
                ,XMLD.before_actual_quantity                before_actual_quantity        --訂正前実績数量
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --自動手動引当区分
                ,XMLD.created_by                            created_by                    --作成者
                ,XMLD.creation_date                         creation_date                 --作成日
                ,XMLD.last_updated_by                       last_updated_by               --最終更新者
                ,XMLD.last_update_date                      last_update_date              --最終更新日
                ,XMLD.last_update_login                     last_update_login             --最終更新ログイン
                ,NVL( XMVH.actual_arrival_date, XMVH.schedule_arrival_date )    --NVL( 着荷日, 着荷予定日 )
                                                            arrival_date                  --着荷日 (⇒品目名称取得で使用)
           FROM  xxinv_mov_req_instr_headers XMVH           --移動依頼指示ヘッダアドオン
                ,xxinv_mov_req_instr_lines   XMVL           --移動依頼指示明細アドオン
                ,xxinv_mov_lot_details       XMLD           --移動ロット詳細アドオン
                ,fnd_lookup_values           FLV01          --クイックコード(移動タイプ名)
          WHERE
            --移動明細情報の取得
                 NVL(XMVL.delete_flg, 'N')  <> 'Y'
            AND  XMVH.mov_hdr_id             = XMVL.mov_hdr_id
            --移動ロット詳細情報の取得
            AND  XMLD.document_type_code(+)  = '20'         --移動指示
            AND  XMVL.mov_line_id            = XMLD.mov_line_id(+)
            --移動タイプ名取得
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXINV_MOVE_TYPE'
            AND  FLV01.lookup_code(+)        = XMVH.mov_type
         --[ 移動データ  END ]
       )                                SPML                     --出荷/支給/移動 明細情報
       ,hr_all_organization_units_tl    HAOUT                    --組織マスタ
       ,xxsky_item_mst2_v               ITEM1                    --SKYLINK用中間VIEW OPM品目情報VIEW(出荷移動_品目)
       ,xxsky_item_mst2_v               ITEM2                    --SKYLINK用中間VIEW OPM品目情報VIEW(依頼品目)
       ,xxsky_prod_class_v              PRODC                    --SKYLINK用中間VIEW 商品区分情報VIEW
       ,xxsky_item_class_v              ITEMC                    --SKYLINK用中間VIEW 品目区分情報VIEW
       ,xxsky_crowd_code_v              CROWD                    --SKYLINK用中間VIEW 群コード情報VIEW
       ,ic_lots_mst                     LOT                      --ロットマスタ
       ,fnd_user                        FU_CB                    --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU                    --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL                    --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL                    --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_lookup_values               FLV01                    --クイックコード(レコードタイプ名)
       ,fnd_lookup_values               FLV02                    --クイックコード(警告区分名)
       ,fnd_lookup_values               FLV03                    --クイックコード(自動手動引当区分名)
 WHERE
   --組織名取得
        HAOUT.language(+)               = 'JA'
   AND  SPML.organization_id            = HAOUT.organization_id(+)
   --出荷移動_品目名取得
   AND  SPML.shipping_item_id           = ITEM1.item_id(+)
   AND  SPML.arrival_date              >= ITEM1.start_date_active(+)
   AND  SPML.arrival_date              <= ITEM1.end_date_active(+)
   --品目カテゴリ情報取得
   AND  SPML.shipping_item_id           = PRODC.item_id(+)       --商品区分
   AND  SPML.shipping_item_id           = ITEMC.item_id(+)       --品目区分
   AND  SPML.shipping_item_id           = CROWD.item_id(+)       --群コード
   --ロット情報取得
   AND  SPML.shipping_item_id           = LOT.item_id(+)
   AND  SPML.lot_id                     = LOT.lot_id(+)
   --依頼品目名取得
   AND  SPML.request_item_id            = ITEM2.item_id(+)
   AND  SPML.arrival_date              >= ITEM2.start_date_active(+)
   AND  SPML.arrival_date              <= ITEM2.end_date_active(+)
   --WHOカラム情報取得
   AND  SPML.created_by                 = FU_CB.user_id(+)
   AND  SPML.last_updated_by            = FU_LU.user_id(+)
   AND  SPML.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
   --【クイックコード】レコードタイプ名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXINV_RECORD_TYPE'
   AND  FLV01.lookup_code(+)            = SPML.record_type_code
   --【クイックコード】警告区分名
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWSH_WARNING_CLASS'
   AND  FLV02.lookup_code(+)            = SPML.warning_class
   --【クイックコード】自動主導引当区分名
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV03.lookup_code(+)            = SPML.automanual_reserve_class
/
COMMENT ON TABLE APPS.XXSKY_入出庫配送明細_数量_V IS 'SKYLINK用入出庫配送明細（数量）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.依頼_移動NO IS '依頼_移動No'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.タイプ IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.移動タイプ IS '移動タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.移動タイプ名 IS '移動タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.レコードタイプ IS 'レコードタイプ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.レコードタイプ名 IS 'レコードタイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.組織名 IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出荷移動_品目 IS '出荷移動_品目'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出荷移動_品目名 IS '出荷移動_品目名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出荷移動_品目略称 IS '出荷移動_品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.ロットNO IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.製造年月日 IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.固有記号 IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.賞味期限 IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.削除フラグ IS '削除フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.依頼数量 IS '依頼数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.指示数量 IS '指示数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.指定製造日 IS '指定製造日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.依頼品目 IS '依頼品目'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.依頼品目名 IS '依頼品目名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.依頼品目略称 IS '依頼品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.付帯コード IS '付帯コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.指定日付_リーフ IS '指定日付_リーフ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.移動NO IS '移動No'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.発注NO IS '発注No'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.顧客発注 IS '顧客発注'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.パレット数 IS 'パレット数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.段数 IS '段数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.ケース数 IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.容積 IS '容積'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.パレット枚数 IS 'パレット枚数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.パレット重量 IS 'パレット重量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.引当数 IS '引当数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.参照移動番号 IS '参照移動番号'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.参照発注番号 IS '参照発注番号'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.初回指示数量 IS '初回指示数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出庫実績数量 IS '出庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.入庫実績数量 IS '入庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.警告区分 IS '警告区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.警告区分名 IS '警告区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.警告日付 IS '警告日付'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.摘要 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出荷依頼インタフェース済フラグ IS '出荷依頼インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.出荷実績インタフェース済フラグ IS '出荷実績インタフェース済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.実績日 IS '実績日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.実績数量 IS '実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.訂正前実績数量 IS '訂正前実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.自動手動引当区分 IS '自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.自動手動引当区分名 IS '自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫配送明細_数量_V.最終更新ログイン IS '最終更新ログイン'
/
