/*************************************************************************
 * 
 * View  Name      : XXSKZ_移動品目別明細_基本_V
 * Description     : XXSKZ_移動品目別明細_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_移動品目別明細_基本_V
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
,入出庫実績数量
,重量
,容積
,パレット重量
,自動手動引当区分
,自動手動引当区分名
,取消フラグ
,取消フラグ名
,警告日付
,警告区分
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  XILL.mov_num                      --移動番号
       ,XILL.line_number                  --明細番号
       ,HAOUT.name                        --組織名
       ,XPCV.prod_class_code              --商品区分
       ,XPCV.prod_class_name              --商品区分名
       ,XICV.item_class_code              --品目区分
       ,XICV.item_class_name              --品目区分名
       ,XCCV.crowd_code                   --群コード
       ,XILL.item_code                    --品目コード
       ,XIMV.item_name                    --品目名
       ,XIMV.item_short_name              --品目略称
       ,XILL.request_qty                  --依頼数量
       ,XILL.pallet_quantity              --パレット数
       ,XILL.layer_quantity               --段数
       ,XILL.case_quantity                --ケース数
       ,XILL.instruct_qty                 --指示数量
       ,XILL.reserved_quantity            --引当数
       ,XILL.uom_code                     --単位
       ,XILL.designated_production_date   --指定製造日
       ,XILL.pallet_qty                   --パレット枚数
       ,XILL.move_num                     --参照移動番号
       ,XILL.po_num                       --参照発注番号
       ,XILL.first_instruct_qty           --初回指示数量
       ,XILL.shipped_quantity             --出庫実績数量
       ,XILL.ship_to_quantity             --入庫実績数量
       ,XILL.ship_arvl_quantity           --入出庫実績数量
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XILL.weight)
       ,CEIL(TRUNC(NVL(XILL.weight,0),1))     --小数点第2位以下を切り捨て後、小数点第1位を切り上げ
-- 2010/1/7 #627 Y.Fukami Mod Start
        weight                            --重量
       ,CEIL(XILL.capacity)
        capacity                          --容積
       ,XILL.pallet_weight                --パレット重量
       ,XILL.automanual_reserve_class     --自動手動引当区分
       ,FLV02.meaning                     --自動手動引当区分名
       ,XILL.delete_flg                   --取消フラグ
       ,FLV03.meaning                     --取消フラグ名
       ,XILL.warning_date                 --警告日付
       ,XILL.warning_class                --警告区分
       ,FU_CB.user_name                   --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XILL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --作成日時
       ,FU_LU.user_name                   --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( XILL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
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
                  ,CASE WHEN XMRIH.status IN ( '01', '02' )  THEN XMRIL.request_qty
                        WHEN XMRIH.status = '03'             THEN XMRIL.instruct_qty
                        WHEN XMRIH.status IN ( '05', '06' )  THEN XMRIL.ship_to_quantity
                        ELSE                                      XMRIL.shipped_quantity
                   END          ship_arvl_quantity   --入出庫実績数量
                  ,XMRIL.weight                      --重量
                  ,XMRIL.capacity                    --容積
                  ,XMRIL.pallet_weight               --パレット重量
                  ,XMRIL.automanual_reserve_class    --自動手動引当区分
                  ,XMRIL.delete_flg                  --取消フラグ
                  ,XMRIL.warning_date                --警告日付
                  ,XMRIL.warning_class               --警告区分
                  ,XMRIL.created_by                  --作成者
                  ,XMRIL.creation_date               --作成日時
                  ,XMRIL.last_updated_by             --最終更新者
                  ,XMRIL.last_update_date            --更新日時
                  ,XMRIL.last_update_login           --最終更新ログイン
                  ,XMRIL.organization_id             --組織ID(組織名取得用)
                  ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                   arrival_date      --入庫日(品目情報取得用)
             FROM  xxcmn_mov_req_instr_lines_arc   XMRIL --移動依頼/指示明細（アドオン）バックアップ
                  ,xxcmn_mov_req_instr_hdrs_arc XMRIH --移動依頼/指示ヘッダ（アドオン）バックアップ
            WHERE  XMRIL.mov_hdr_id           = XMRIH.mov_hdr_id(+)
              AND  NVL( XMRIL.delete_flg, 'N' ) <> 'Y'              --無効明細以外
        )                            XILL            --移動明細＆ロット詳細情報
       ,hr_all_organization_units_tl HAOUT           --組織名称マスタ
       ,xxskz_prod_class_v           XPCV            --SKYLINK用 商品区分取得VIEW
       ,xxskz_item_class_v           XICV            --SKYLINK用 品目区分取得VIEW
       ,xxskz_crowd_code_v           XCCV            --SKYLINK用 郡コード取得VIEW
       ,xxskz_item_mst2_v            XIMV            --SKYLINK用中間VIEW OPM品目情報VIEW
       ,fnd_lookup_values            FLV02           --クイックコード(自動手動引当区分名)
       ,fnd_lookup_values            FLV03           --クイックコード(取消フラグ名)
       ,fnd_user                     FU_CB           --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                     FU_LU           --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                     FU_LL           --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                   FL_LL           --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   --組織名取得条件
        XILL.organization_id      = HAOUT.organization_id(+)
   AND  HAOUT.language(+)         = 'JA'
   --品目情報取得条件
   AND  XILL.item_code            = XIMV.item_no(+)
   AND  XILL.arrival_date        >= XIMV.start_date_active(+)
   AND  XILL.arrival_date        <= XIMV.end_date_active(+)
   --品目カテゴリ情報取得条件
   AND  XIMV.item_id              = XPCV.item_id(+)
   AND  XIMV.item_id              = XICV.item_id(+)
   AND  XIMV.item_id              = XCCV.item_id(+)
   --クイックコード：自動手動引当区分名取得
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV02.lookup_code(+) = XILL.automanual_reserve_class
   --クイックコード：取消フラグ名取得
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV03.lookup_code(+) = XILL.delete_flg
   --WHOカラム取得
   AND  XILL.created_by         = FU_CB.user_id(+)
   AND  XILL.last_updated_by    = FU_LU.user_id(+)
   AND  XILL.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_移動品目別明細_基本_V IS 'SKYLINK用移動品目別明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.移動番号 IS '移動番号'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.組織名 IS '組織名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.依頼数量 IS '依頼数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.パレット数 IS 'パレット数'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.段数 IS '段数'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.ケース数 IS 'ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.指示数量 IS '指示数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.引当数 IS '引当数'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.指定製造日 IS '指定製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.パレット枚数 IS 'パレット枚数'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.参照移動番号 IS '参照移動番号'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.参照発注番号 IS '参照発注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.初回指示数量 IS '初回指示数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.出庫実績数量 IS '出庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.入庫実績数量 IS '入庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.入出庫実績数量 IS '入出庫実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.容積 IS '容積'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.パレット重量 IS 'パレット重量'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.自動手動引当区分 IS '自動手動引当区分'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.自動手動引当区分名 IS '自動手動引当区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.取消フラグ IS '取消フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.取消フラグ名 IS '取消フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.警告日付 IS '警告日付'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.警告区分 IS '警告区分'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_移動品目別明細_基本_V.最終更新ログイン IS '最終更新ログイン'
/
