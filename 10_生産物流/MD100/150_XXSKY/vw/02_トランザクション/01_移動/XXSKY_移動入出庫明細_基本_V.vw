CREATE OR REPLACE VIEW APPS.XXSKY_移動入出庫明細_基本_V
(
 移動番号
,明細番号
,組織名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,依頼数量
,パレット数
,段数
,ケース数
,指示数量
,引当数
,単位
,指定製造日
,パレット枚数
,参照移動番号
,参照発注番号
,初回指示数量
,出庫実績数量
,入庫実績数量
,重量
,容積
,パレット重量
,自動手動引当区分
,自動手動引当区分名
,取消フラグ
,取消フラグ名
,警告日付
,警告区分
,ロットNO
,製造年月日
,固有記号
,賞味期限
,指示_レコードタイプ
,指示_レコードタイプ名
,指示_実績日
,指示_実績数量
,指示_訂正前実績数量
,指示_自動手動引当区分
,指示_自動手動引当区分名
,出庫_レコードタイプ
,出庫_レコードタイプ名
,出庫_実績日
,出庫_実績数量
,出庫_訂正前実績数量
,出庫_自動手動引当区分
,出庫_自動手動引当区分名
,入庫_レコードタイプ
,入庫_レコードタイプ名
,入庫_実績日
,入庫_実績数量
,入庫_訂正前実績数量
,入庫_自動手動引当区分
,入庫_自動手動引当区分名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XINS.mov_num                      --移動番号
       ,XINS.line_number                  --明細番号
       ,HAOUT.name                        --組織名
       ,XPCV.prod_class_code              --商品区分
       ,XPCV.prod_class_name              --商品区分名
       ,XICV.item_class_code              --品目区分
       ,XICV.item_class_name              --品目区分名
       ,XCCV.crowd_code                   --群コード
       ,XINS.item_code                    --品目コード
       ,XIMV.item_name                    --品目名
       ,XIMV.item_short_name              --品目略称
       ,XINS.request_qty                  --依頼数量
       ,XINS.pallet_quantity              --パレット数
       ,XINS.layer_quantity               --段数
       ,XINS.case_quantity                --ケース数
       ,XINS.instruct_qty                 --指示数量
       ,XINS.reserved_quantity            --引当数
       ,XINS.uom_code                     --単位
       ,XINS.designated_production_date   --指定製造日
       ,XINS.pallet_qty                   --パレット枚数
       ,XINS.move_num                     --参照移動番号
       ,XINS.po_num                       --参照発注番号
       ,XINS.first_instruct_qty           --初回指示数量
       ,XINS.shipped_quantity             --出庫実績数量
       ,XINS.ship_to_quantity             --入庫実績数量
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XINS.weight)
       ,CEIL(TRUNC(NVL(XINS.weight,0),1))     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/7 #627 Y.Fukami Mod Start
        weight                            --重量
       ,CEIL(XINS.capacity)
        capacity                          --容積
       ,XINS.pallet_weight                --パレット重量
       ,XINS.automanual_reserve_class     --自動手動引当区分
       ,FLV01.meaning                     --自動手動引当区分名
       ,XINS.delete_flg                   --取消フラグ
       ,FLV02.meaning                     --取消フラグ名
       ,XINS.warning_date                 --警告日付
       ,XINS.warning_class                --警告区分
       ,NVL( DECODE( XINS.lot_no, 'DEFAULTLOT', '0', XINS.lot_no ), '0' )
                       lot_no            --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute1  --ロット管理品   →製造年月日を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END             manufacture_date  --製造年月日
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute2  --ロット管理品   →固有記号を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END             uniqe_sign        --固有記号
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute3  --ロット管理品   →賞味期限を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END             expiration_date   --賞味期限
       ,XINS.record_type_code_sj          --指示_レコードタイプ
       ,FLV03.meaning                     --指示_レコードタイプ名
       ,XINS.actual_date_sj               --指示_実績日
       ,XINS.actual_quantity_sj           --指示_実績数量
       ,XINS.before_actual_quantity_sj    --指示_訂正前実績数量
       ,XINS.automanual_reserve_class_sj  --指示_自動手動引当区分
       ,FLV04.meaning                     --指示_自動手動引当区分名
       ,XINS.record_type_code_sk          --出庫_レコードタイプ
       ,FLV05.meaning                     --出庫_レコードタイプ名
       ,XINS.actual_date_sk               --出庫_実績日
       ,XINS.actual_quantity_sk           --出庫_実績数量
       ,XINS.before_actual_quantity_sk    --出庫_訂正前実績数量
       ,XINS.automanual_reserve_class_sk  --出庫_自動手動引当区分
       ,FLV06.meaning                     --出庫_自動手動引当区分名
       ,XINS.record_type_code_nk          --入庫_レコードタイプ
       ,FLV07.meaning                     --入庫_レコードタイプ名
       ,XINS.actual_date_nk               --入庫_実績日
       ,XINS.actual_quantity_nk           --入庫_実績数量
       ,XINS.before_actual_quantity_nk    --入庫_訂正前実績数量
       ,XINS.automanual_reserve_class_nk  --入庫_自動手動引当区分
       ,FLV08.meaning                     --入庫_自動手動引当区分名
       ,FU_CB.user_name                   --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XINS.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --作成日時
       ,FU_LU.user_name                   --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XINS.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --更新日時
       ,FU_LL.user_name                   --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  (  ----名称取得系以外のデータはこの内部SQLで全て取得する
           SELECT  XMRIH.mov_num                     --移動番号
                  ,XMRIL.line_number                 --明細番号
                  ,XMRIL.item_code                   --品目コード
                  ,XMRIL.request_qty                 --依頼数量
                  ,XMRIL.pallet_quantity             --パレット数
                  ,XMRIL.layer_quantity              --段数
                  ,XMRIL.case_quantity               --ケース数
                  ,XMRIL.instruct_qty                --指示数量
                  ,XMRIL.reserved_quantity           --引当数
                  ,XMRIL.uom_code                    --単位
                  ,XMRIL.designated_production_date  --指定製造日
                  ,XMRIL.pallet_qty                  --パレット枚数
                  ,XMRIL.move_num                    --参照移動番号
                  ,XMRIL.po_num                      --参照発注番号
                  ,XMRIL.first_instruct_qty          --初回指示数量
                  ,XMRIL.shipped_quantity            --出庫実績数量
                  ,XMRIL.ship_to_quantity            --入庫実績数量
                  ,XMRIL.weight                      --重量
                  ,XMRIL.capacity                    --容積
                  ,XMRIL.pallet_weight               --パレット重量
                  ,XMRIL.automanual_reserve_class    --自動手動引当区分
                  ,XMRIL.delete_flg                  --取消フラグ
                  ,XMRIL.warning_date                --警告日付
                  ,XMRIL.warning_class               --警告区分
                  ,XMLD.lot_no                       --ロットNo
                  ,ILM.attribute1                    --製造年月日
                  ,ILM.attribute2                    --固有記号
                  ,ILM.attribute3                    --賞味期限
                   --指示ロット詳細項目
                  ,XMLD_SJ.record_type_code
                   record_type_code_sj               --指示_レコードタイプ
                  ,XMLD_SJ.actual_date
                   actual_date_sj                    --指示_実績日
                  ,XMLD_SJ.actual_quantity
                   actual_quantity_sj                --指示_実績数量
                  ,XMLD_SJ.before_actual_quantity
                   before_actual_quantity_sj         --指示_訂正前実績数量
                  ,XMLD_SJ.automanual_reserve_class
                   automanual_reserve_class_sj       --指示_自動手動引当区分
                   --出庫実績ロット詳細項目
                  ,XMLD_SK.record_type_code
                   record_type_code_sk               --出庫_レコードタイプ
                  ,XMLD_SK.actual_date
                   actual_date_sk                    --出庫_実績日
                  ,XMLD_SK.actual_quantity
                   actual_quantity_sk                --出庫_実績数量
                  ,XMLD_SK.before_actual_quantity
                   before_actual_quantity_sk         --出庫_訂正前実績数量
                  ,XMLD_SK.automanual_reserve_class
                   automanual_reserve_class_sk       --出庫_自動手動引当区分
                   --入庫実績ロット詳細項目
                  ,XMLD_NK.record_type_code
                   record_type_code_nk               --入庫_レコードタイプ
                  ,XMLD_NK.actual_date
                   actual_date_nk                    --入庫_実績日
                  ,XMLD_NK.actual_quantity
                   actual_quantity_nk                --入庫_実績数量
                  ,XMLD_NK.before_actual_quantity
                   before_actual_quantity_nk         --入庫_訂正前実績数量
                  ,XMLD_NK.automanual_reserve_class
                   automanual_reserve_class_nk       --入庫_自動手動引当区分
                  ,XMRIL.created_by                  --作成者
                  ,XMRIL.creation_date               --作成日時
                  ,XMRIL.last_updated_by             --最終更新者
                  ,XMRIL.last_update_date            --更新日時
                  ,XMRIL.last_update_login           --最終更新ログイン
                  ,XMRIL.organization_id             --組織ID(組織名取得用)
                  ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                   arrival_date      --入庫日(品目情報取得用)
             FROM  xxinv_mov_req_instr_lines    XMRIL               --移動依頼/指示明細アドオン
                  ,xxinv_mov_req_instr_headers  XMRIH               --移動依頼/指示ヘッダアドオン
                  ,(  SELECT  distinct mov_line_id
                                      ,item_id
                                      ,lot_id
                                      ,lot_no
                        FROM  xxinv_mov_lot_details
                       WHERE  document_type_code = '20'
                    )                            XMLD               --移動ロット詳細アドオン(ラインID,ロットID重複除去)
                  ,(  SELECT  XMLD10.mov_line_id
                             ,XMLD10.lot_id
                             ,XMLD10.record_type_code
                             ,XMLD10.actual_date
                             ,SUM(XMLD10.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD10.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD10.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD10
                       WHERE  XMLD10.record_type_code   = '10'      --指示
                         AND  XMLD10.document_type_code = '20'
                    GROUP BY  XMLD10.mov_line_id
                             ,XMLD10.lot_id
                             ,XMLD10.record_type_code
                             ,XMLD10.actual_date
                             ,XMLD10.automanual_reserve_class
                   )                             XMLD_SJ            --移動ロット詳細アドオン(指示ロット詳細用)
                  ,(  SELECT  XMLD20.mov_line_id
                             ,XMLD20.lot_id
                             ,XMLD20.record_type_code
                             ,XMLD20.actual_date
                             ,SUM(XMLD20.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD20.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD20.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD20
                       WHERE  XMLD20.record_type_code   = '20'      --出庫実績
                         AND  XMLD20.document_type_code = '20'
                    GROUP BY  XMLD20.mov_line_id
                             ,XMLD20.lot_id
                             ,XMLD20.record_type_code
                             ,XMLD20.actual_date
                             ,XMLD20.automanual_reserve_class
                   )                             XMLD_SK            --移動ロット詳細アドオン(出庫実績ロット詳細用)
                  ,(  SELECT  XMLD30.mov_line_id
                             ,XMLD30.lot_id
                             ,XMLD30.record_type_code
                             ,XMLD30.actual_date
                             ,SUM(XMLD30.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD30.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD30.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD30
                       WHERE  XMLD30.record_type_code   = '30'      --入庫実績
                         AND  XMLD30.document_type_code = '20'
                    GROUP BY  XMLD30.mov_line_id
                             ,XMLD30.lot_id
                             ,XMLD30.record_type_code
                             ,XMLD30.actual_date
                             ,XMLD30.automanual_reserve_class
                   )                             XMLD_NK            --移動ロット詳細アドオン(入庫実績ロット詳細用)
                  ,ic_lots_mst               ILM                    --ロットマスタ
            WHERE  XMRIL.mov_hdr_id           = XMRIH.mov_hdr_id
              AND  NVL( XMRIL.delete_flg, 'N' ) <> 'Y'              --無効明細以外
              AND  XMRIL.mov_line_id          = XMLD.mov_line_id(+)
              AND  XMLD.item_id               = ILM.item_id(+)
              AND  XMLD.lot_id                = ILM.lot_id(+)
              --指示ロット詳細取得条件
              AND  XMLD.mov_line_id           = XMLD_SJ.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_SJ.lot_id(+)
              --出庫実績ロット詳細取得条件
              AND  XMLD.mov_line_id           = XMLD_SK.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_SK.lot_id(+)
              --入庫実績ロット詳細取得条件
              AND  XMLD.mov_line_id           = XMLD_NK.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_NK.lot_id(+)
        )                               XINS                        --移動入出庫明細＆移動入出庫ロット詳細情報
       ,hr_all_organization_units_tl    HAOUT                       --組織名称マスタ
       ,xxsky_prod_class_v              XPCV                        --SKYLINK用 商品区分取得VIEW
       ,xxsky_item_class_v              XICV                        --SKYLINK用 品目区分取得VIEW
       ,xxsky_crowd_code_v              XCCV                        --SKYLINK用 郡コード取得VIEW
       ,xxsky_item_mst2_v               XIMV                        --SKYLINK用中間VIEW OPM品目情報VIEW
       ,fnd_lookup_values               FLV01                       --クイックコード(自動手動引当区分名)
       ,fnd_lookup_values               FLV02                       --クイックコード(取消フラグ名)
       ,fnd_lookup_values               FLV03                       --クイックコード(指示_レコードタイプ名)
       ,fnd_lookup_values               FLV04                       --クイックコード(指示_自動手動引当区分名)
       ,fnd_lookup_values               FLV05                       --クイックコード(出庫_レコードタイプ名)
       ,fnd_lookup_values               FLV06                       --クイックコード(出庫_自動手動引当区分名)
       ,fnd_lookup_values               FLV07                       --クイックコード(入庫_レコードタイプ名)
       ,fnd_lookup_values               FLV08                       --クイックコード(入庫_自動手動引当区分名)
       ,fnd_user                        FU_CB                       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU                       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL                       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL                       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   --組織名取得条件
        XINS.organization_id      = HAOUT.organization_id(+)
   AND  HAOUT.language(+)         = 'JA'
   --品目情報取得条件
   AND  XINS.item_code            = XIMV.item_no(+)
   AND  XINS.arrival_date        >= XIMV.start_date_active(+)
   AND  XINS.arrival_date        <= XIMV.end_date_active(+)
   --品目カテゴリ情報取得条件
   AND  XIMV.item_id              = XPCV.item_id(+)
   AND  XIMV.item_id              = XICV.item_id(+)
   AND  XIMV.item_id              = XCCV.item_id(+)
   --クイックコード：自動手動引当区分名取得
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV01.lookup_code(+) = XINS.automanual_reserve_class
   --クイックコード：取消フラグ名取得
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV02.lookup_code(+) = XINS.delete_flg
   --クイックコード：指示_レコードタイプ名取得
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV03.lookup_code(+) = XINS.record_type_code_sj
   --クイックコード：指示_自動手動引当区分名取得
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV04.lookup_code(+) = XINS.automanual_reserve_class_sj
   --クイックコード：出庫_レコードタイプ名取得
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV05.lookup_code(+) = XINS.record_type_code_sk
   --クイックコード：出庫_自動手動引当区分名取得
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV06.lookup_code(+) = XINS.automanual_reserve_class_sk
   --クイックコード：入庫_レコードタイプ名取得
   AND  FLV07.language(+)    = 'JA'
   AND  FLV07.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV07.lookup_code(+) = XINS.record_type_code_nk
   --クイックコード：入庫_自動手動引当区分名取得
   AND  FLV08.language(+)    = 'JA'
   AND  FLV08.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV08.lookup_code(+) = XINS.automanual_reserve_class_nk
   --WHOカラム取得
   AND  XINS.created_by         = FU_CB.user_id(+)
   AND  XINS.last_updated_by    = FU_LU.user_id(+)
   AND  XINS.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_移動入出庫明細_基本_V IS 'SKYLINK用移動入出庫明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.移動番号 IS '移動番号'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.組織名 IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.依頼数量 IS '依頼数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.パレット数 IS 'パレット数'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.段数 IS '段数'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.ケース数 IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示数量 IS '指示数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.引当数 IS '引当数'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指定製造日 IS '指定製造日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.パレット枚数 IS 'パレット枚数'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.参照移動番号 IS '参照移動番号'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.参照発注番号 IS '参照発注番号'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.初回指示数量 IS '初回指示数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫実績数量 IS '出庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫実績数量 IS '入庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.容積 IS '容積'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.パレット重量 IS 'パレット重量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.自動手動引当区分 IS '自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.自動手動引当区分名 IS '自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.取消フラグ IS '取消フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.取消フラグ名 IS '取消フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.警告日付 IS '警告日付'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.警告区分 IS '警告区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.ロットNO IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.製造年月日 IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.固有記号 IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.賞味期限 IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_レコードタイプ IS '指示_レコードタイプ'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_レコードタイプ名 IS '指示_レコードタイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_実績日 IS '指示_実績日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_実績数量 IS '指示_実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_訂正前実績数量 IS '指示_訂正前実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_自動手動引当区分 IS '指示_自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.指示_自動手動引当区分名 IS '指示_自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_レコードタイプ IS '出庫_レコードタイプ'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_レコードタイプ名 IS '出庫_レコードタイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_実績日 IS '出庫_実績日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_実績数量 IS '出庫_実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_訂正前実績数量 IS '出庫_訂正前実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_自動手動引当区分 IS '出庫_自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.出庫_自動手動引当区分名 IS '出庫_自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_レコードタイプ IS '入庫_レコードタイプ'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_レコードタイプ名 IS '入庫_レコードタイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_実績日 IS '入庫_実績日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_実績数量 IS '入庫_実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_訂正前実績数量 IS '入庫_訂正前実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_自動手動引当区分 IS '入庫_ロット_自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.入庫_自動手動引当区分名 IS '入庫_ロット_自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_移動入出庫明細_基本_V.最終更新ログイン IS '最終更新ログイン'
/
