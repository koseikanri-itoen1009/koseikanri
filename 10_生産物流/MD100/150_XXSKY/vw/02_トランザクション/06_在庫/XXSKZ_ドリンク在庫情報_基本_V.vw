/*************************************************************************
 * 
 * View  Name      : XXSKZ_ドリンク在庫情報_基本_V
 * Description     : XXSKZ_ドリンク在庫情報_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ドリンク在庫情報_基本_V
(
 倉庫コード
,倉庫名
,代表倉庫コード
,代表倉庫名
,代表倉庫略称
,保管場所コード
,保管場所名
,保管場所略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,入庫日
,入庫元コード
,入庫元名
,在庫単価
,未判定ケース在庫数
,未判定バラ在庫数
,未判定ケース出庫指示数
,未判定バラ出庫指示数
,良品ケース在庫数
,良品バラ在庫数
,良品ケース出庫指示数
,良品バラ出庫指示数
,条件付良品ケース在庫数
,条件付良品バラ在庫数
,条件付良品ケース出庫指示数
,条件付良品バラ出庫指示数
,不良品ケース在庫数
,不良品バラ在庫数
,不良品ケース出庫指示数
,不良品バラ出庫指示数
-- ***** 2009/09/24 #1634 S *****
,保留ケース在庫数
,保留バラ在庫数
,保留ケース出庫指示数
,保留バラ出庫指示数
-- ***** 2009/09/24 #1634 E *****
)
AS
SELECT
         STRN.whse_code                                     whse_code           --倉庫コード
        ,IWM.whse_name                                      whse_name           --倉庫名
         --代表倉庫コード
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --代表倉庫コードが'ZZZZ'なら品目別代表倉庫コード
                NVL( XFIL.frq_item_location_code, STRN.location )
              ELSE                                          --上記以外は代表倉庫コード
                NVL( ILOC.frequent_whse         , STRN.location )
         END                                                frequent_whse       --代表倉庫コード（代表倉庫の登録が無いデータは自分の保管場所コード）
         --代表倉庫名
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --代表倉庫コードが'ZZZZ'なら品目別代表倉庫名
                DECODE( XFIL.frq_item_location_code, NULL, ILOC.description, FQLOC.description )
              ELSE                                          --上記以外は代表倉庫名
                DECODE( ILOC.frequent_whse         , NULL, ILOC.description, FLOC.description  )
         END                                                fq_whse_name        --代表倉庫名（代表倉庫の登録が無いデータは自分の保管場所名）
         --代表倉庫略称
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --代表倉庫コードが'ZZZZ'なら品目別代表倉庫略称
                DECODE( XFIL.frq_item_location_code, NULL, ILOC.short_name, FQLOC.short_name )
              ELSE                                          --上記以外は代表倉庫略称
                DECODE( ILOC.frequent_whse         , NULL, ILOC.short_name, FLOC.short_name  )
         END                                                fq_whse_s_name      --代表倉庫略称（代表倉庫の登録が無いデータは自分の保管場所略称）
        ,STRN.location                                      location            --保管場所コード
        ,ILOC.description                                   loct_name           --保管場所名
        ,ILOC.short_name                                    loct_s_name         --保管場所略称
        ,PRODC.prod_class_code                              prod_class_code     --商品区分
        ,PRODC.prod_class_name                              prod_class_name     --商品区分名
        ,ITEMC.item_class_code                              item_class_code     --品目区分
        ,ITEMC.item_class_name                              item_class_name     --品目区分名
        ,CROWD.crowd_code                                   crowd_code          --群コード
        ,ITEM.item_no                                       item_code           --品目
        ,ITEM.item_name                                     item_name           --品目名
        ,ITEM.item_short_name                               item_s_name         --品目略称
        ,ILM.lot_no                                         lot_no              --ロットNo
        ,ILM.attribute1                                     lot_date            --製造年月日
        ,ILM.attribute2                                     lot_sign            --固有記号
        ,ILM.attribute3                                     best_bfr_date       --賞味期限
        ,STRN.in_whse_date                                  in_whse_date        --入庫日
        ,ILM.attribute8                                     vendor_code         --入庫元コード
        ,VNDR.vendor_name                                   vendor_name         --入庫元名
        ,TO_NUMBER( ILM.attribute7 )                        inv_amt             --在庫単価
         --未判定
        ,NVL( TRUNC( STRN.njdg_qty     / ITEM.num_of_cases ), 0 )
                                                            njdg_case_qty       --未判定ケース在庫数
        ,NVL( STRN.njdg_qty    , 0 )                        njdg_qty            --未判定バラ在庫数
        ,NVL( TRUNC( STRN.njdg_out_qty / ITEM.num_of_cases ), 0 )
                                                            njdg_out_case_qty   --未判定ケース出庫指示数
        ,NVL( STRN.njdg_out_qty, 0 )                        njdg_out_qty        --未判定バラ出庫指示数
         --良品
        ,NVL( TRUNC( STRN.good_qty     / ITEM.num_of_cases ), 0 )
                                                            good_case_qty       --良品ケース在庫数
        ,NVL( STRN.good_qty    , 0 )                        good_qty            --良品バラ在庫数
        ,NVL( TRUNC( STRN.good_out_qty / ITEM.num_of_cases ), 0 )
                                                            good_out_case_qty   --良品ケース出庫指示数
        ,NVL( STRN.good_out_qty, 0 )                        good_out_qty        --良品バラ出庫指示数
         --条件付良品
        ,NVL( TRUNC( STRN.term_qty     / ITEM.num_of_cases ), 0 )
                                                            term_case_qty       --条件付良品ケース在庫数
        ,NVL( STRN.term_qty    , 0 )                        term_qty            --条件付良品バラ在庫数
        ,NVL( TRUNC( STRN.term_out_qty / ITEM.num_of_cases ), 0 )
                                                            term_out_case_qty   --条件付良品ケース出庫指示数
        ,NVL( STRN.term_out_qty, 0 )                        term_out_qty        --条件付良品バラ出庫指示数
         --不良品
        ,NVL( TRUNC( STRN.ng_qty       / ITEM.num_of_cases ), 0 )
                                                            ng_case_qty         --不良品ケース在庫数
        ,NVL( STRN.ng_qty      , 0 )                        ng_qty              --不良品バラ在庫数
        ,NVL( TRUNC( STRN.ng_out_qty   / ITEM.num_of_cases ), 0 )
                                                            ng_out_case_qty     --不良品ケース出庫指示数
        ,NVL( STRN.ng_out_qty  , 0 )                        ng_out_qty          --不良品バラ出庫指示数
-- ***** 2009/09/24 #1634 S *****
         --保留
        ,NVL( TRUNC( STRN.hold_qty       / ITEM.num_of_cases ), 0 )
                                                            hold_case_qty       --保留ケース在庫数
        ,NVL( STRN.hold_qty      , 0 )                      hold_qty            --保留バラ在庫数
        ,NVL( TRUNC( STRN.hold_out_qty   / ITEM.num_of_cases ), 0 )
                                                            hold_out_case_qty   --保留ケース出庫指示数
        ,NVL( STRN.hold_out_qty  , 0 )                      hold_out_qty        --保留バラ出庫指示数
-- ***** 2009/09/24 #1634 E *****
  FROM
        (
          --************************************************************************
          -- 現在庫＋出庫指示数を出力するレコードを作成  Start
          --************************************************************************
           --倉庫コード、保管場所コード、品目ID、ロットID単位で集計
           SELECT
                   TRAN.whse_code                           whse_code           --倉庫コード
                  ,TRAN.location                            location            --保管場所コード
                  ,NULL                                     in_whse_date        --入庫日
                  ,TRAN.item_id                             item_id             --品目ID
                  ,TRAN.lot_id                              lot_id              --ロットID
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN TRAN.onhand_qty END )  njdg_qty      --未判定バラ在庫数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN TRAN.out_qty    END )  njdg_out_qty  --未判定バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN TRAN.onhand_qty END )  good_qty      --良品バラ在庫数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN TRAN.out_qty    END )  good_out_qty  --良品バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN TRAN.onhand_qty END )  term_qty      --条件付良品バラ在庫数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN TRAN.out_qty    END )  term_out_qty  --条件付良品バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN TRAN.onhand_qty END )  ng_qty        --不良品バラ在庫数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN TRAN.out_qty    END )  ng_out_qty    --不良品バラ出庫指示数
-- ***** 2009/09/24 #1634 S *****
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN TRAN.onhand_qty END )  hold_qty      --保留品バラ在庫数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN TRAN.out_qty    END )  hold_out_qty  --保留品バラ出庫指示数
-- ***** 2009/09/24 #1634 E *****
             FROM
                   (
                    --======================================================================
                    -- 現在庫数を手持ち在庫と各トランザクションから取得
                    --  １．手持ち在庫
                    --  ２．移動入庫実績(出庫報告待ち)
                    --  ３．移動出庫実績(入庫報告待ち)
                    --  ４．移動入庫実績(実績訂正)
                    --  ５．移動出庫実績(実績訂正)
                    --  ６．出荷・倉替返品実績(EBS実績計上待ち)
                    --  ７．支給実績(EBS実績計上待ち)
                    --     ⇒ ２～５はEBS手持ち在庫に反映されていない実績データ
                    --======================================================================
                      -------------------------------------------------------------
                      -- １．手持ち在庫
                      -------------------------------------------------------------
                      SELECT
                              ILI.whse_code                 whse_code           --倉庫コード
                             ,ILI.location                  location            --保管場所コード
                             ,ILI.item_id                   item_id             --品目ID
                             ,ILI.lot_id                    lot_id              --ロットID
                             ,ILI.loct_onhand               onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              ic_loct_inv                   ILI                 --OPM手持ち数量
                      --[ １．手持ち在庫  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．移動入庫実績(出庫報告待ち)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,MLD.actual_quantity           onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH               --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL            --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD             --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上 ⇒ EBS在庫未反映
                         AND  MRIH.status                   IN ( '05', '06' )   --05:入庫報告有、06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_arrival_date     >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ２．移動入庫実績(入出庫報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３．移動出庫実績(入庫報告待ち)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,MLD.actual_quantity * -1      onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL             --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD              --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上 ⇒ EBS在庫未反映
                         AND  MRIH.status                   IN ( '04', '06' )   --04:出庫報告有、06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_ship_date        >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ３．移動出庫実績(入出庫報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ４．移動入庫実績(実績訂正)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                                                            onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.comp_actual_flg          = 'Y'               --実績計上 ⇒ EBS在庫反映済
                         AND  MRIH.correct_actual_flg       = 'Y'               --実績訂正済
                         AND  MRIH.status                   = '06'              --06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_arrival_date     >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ４．移動入庫実績(実績訂正)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ５．移動出庫実績(実績訂正)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) ) * -1
                                                            onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.comp_actual_flg          = 'Y'               --実績計上 ⇒ EBS在庫未反映済
                         AND  MRIH.correct_actual_flg       = 'Y'               --実績訂正済
                         AND  MRIH.status                   = '06'              --06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_ship_date        >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ５．移動出庫実績(実績訂正)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ６．出荷・倉替返品実績(EBS実績計上待ち)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '04'              --実績計上済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上 ⇒ EBS在庫未反映
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               IN ( '1', '3' )     --出荷依頼、倉替返品
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '10'              --出荷依頼
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  oha.SHIPPED_DATE             >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  OHA.PROD_CLASS = '2'                                                                     -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ６．出荷・倉替返品実績(着荷報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ７．支給実績(EBS実績計上待ち)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            onhand_qty          --バラ在庫数
                             ,0                             out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '08'              --実績計上済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上 ⇒ EBS在庫未反映
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '2'               --支給指示
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '30'              --支給指示
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  oha.SHIPPED_DATE             >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  OHA.PROD_CLASS = '2'                                                                      -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ７．支給実績(着荷報告待ち)  End ]--
                    --<< 現在庫数を手持ち在庫と各トランザクションから取得  END >>--
                    UNION ALL
                    --======================================================================
                    -- 出庫指示数を各トランザクションから取得
                    --  １．移動出庫予定(指示 積送あり＆積送なし)
                    --  ２．移動出庫予定(入庫報告有 積送あり)
                    --  ３．受注出荷予定
                    --  ４．有償出荷予定
                    --======================================================================
                      -------------------------------------------------------------
                      -- １．移動出庫予定(指示 積送あり＆積送なし)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             onhand_qty          --バラ在庫数
                             ,MLD.actual_quantity           out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   IN ( '02', '03' )   --02:依頼済、03:調整中
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.schedule_ship_date      >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ １．移動出庫予定(指示 積送あり＆積送なし)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．移動出庫予定(入庫報告有 積送あり 出庫予定日ベース)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             onhand_qty          --バラ在庫数
                             ,MLD.actual_quantity           out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '05'              --05:入庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_ship_date        IS NULL                                                      -- E_本稼動#684
                         AND  mrih.schedule_ship_date      >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ２．移動出庫予定(入庫報告有 積送あり 出庫予定日ベース)  End ]--
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２－２．移動出庫予定(入庫報告有 積送あり 出庫実績日ベース)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             onhand_qty          --バラ在庫数
                             ,MLD.actual_quantity           out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '05'              --05:入庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                         AND  mrih.actual_ship_date        IS NOT NULL
                         AND  mrih.actual_ship_date        >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')
                         AND  mrih.ITEM_CLASS = '2'
                         AND  mrih.PRODUCT_FLG = '1'
                      --[ ２－２．移動出庫予定(入庫報告有 積送あり 出庫実績日ベース)  End ]--
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３．受注出荷予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             onhand_qty          --バラ在庫数
                             ,MLD.actual_quantity           out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '03'              --締め済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '1'               --出荷依頼
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '10'              --出荷依頼
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  oha.schedule_ship_date       >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  OHA.PROD_CLASS = '2'                                                                      -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ３．受注出荷予定  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ４．有償出荷予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             onhand_qty          --バラ在庫数
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            out_qty             --出荷指示バラ数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '07'              --受領済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '2'               --支給指示
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '30'              --支給指示
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  oha.schedule_ship_date       >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  OHA.PROD_CLASS = '2'                                                                      -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ４．有償出荷予定  End ]--
                    --<< 出庫指示数を各トランザクションから取得  END >>--
                   )  TRAN
                  ,ic_lots_mst                              ILM                 --OPMロットマスタ
            WHERE
              --OPMロットマスタとの結合
                   TRAN.item_id                             = ILM.item_id
              AND  TRAN.lot_id                              = ILM.lot_id
           GROUP BY TRAN.whse_code    --倉庫コード
                   ,TRAN.location     --保管場所コード
                   ,TRAN.item_id      --品目ID
                   ,TRAN.lot_id       --ロットID
          -- 【 現在庫＋出庫指示数を出力するレコードを作成  End 】 --
--
         UNION ALL
          --************************************************************************
          -- 入庫予定数を出力するレコードを作成  Start
          --************************************************************************
           SELECT
                   ITRAN.whse_code                          whse_code           --倉庫コード
                  ,ITRAN.location                           location            --保管場所コード
                  ,ITRAN.in_whse_date                       in_whse_date        --入庫日
                  ,ITRAN.item_id                            item_id             --品目ID
                  ,ITRAN.lot_id                             lot_id              --ロットID
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN ITRAN.in_qty END )  njdg_qty      --未判定バラ在庫数
                  ,0                                                                          njdg_out_qty  --未判定バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN ITRAN.in_qty END )  good_qty      --良品バラ在庫数
                  ,0                                                                          good_out_qty  --良品バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN ITRAN.in_qty END )  term_qty      --条件付良品バラ在庫数
                  ,0                                                                          term_out_qty  --条件付良品バラ出庫指示数
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN ITRAN.in_qty END )  ng_qty        --不良品バラ在庫数
                  ,0                                                                          ng_out_qty    --不良品バラ出庫指示数
-- ***** 2009/09/24 #1634 S *****
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN ITRAN.in_qty END )  hold_qty      --保留バラ在庫数
                  ,0                                                                          hold_out_qty  --保留バラ出庫指示数
-- ***** 2009/09/24 #1634 E *****
             FROM
                  (
                    --======================================================================
                    -- 当月首以降の入庫予定数を各トランザクションから取得
                    --  １．発注受入予定
                    --  ２．移動入庫予定(指示 積送あり＆積送なし)
                    --  ３．移動入庫予定(出庫報告有 積送あり)
                    --======================================================================
                      -------------------------------------------------------------
                      -- １．発注受入予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )
                                                            in_whse_date        --入庫日
                             ,IIM.item_id                   item_id             --品目ID
                             ,ILM.lot_id                    lot_id              --ロットID
                             ,PLA.quantity                  in_qty              --入庫予定バラ数
                        FROM  po_headers_all                PHA                 --発注ヘッダ
                             ,po_lines_all                  PLA                 --発注明細
                             ,xxskz_item_locations_v        XILV                --保管場所マスタ(倉庫コード取得用)
                             ,ic_item_mst_b                 IIM                 --OPM品目マスタ(OPM品目ID取得用)
                             ,mtl_system_items_b            MSI                 --INV品目マスタ(OPM品目ID取得用)
                             ,ic_lots_mst                   ILM                 --OPMロットマスタ(ロットID取得用)
                       WHERE
                         --発注ヘッダの条件
                              PHA.attribute1                IN ( '20', '25' )   --20:発注作成済、25:受入あり
                         --発注明細との結合
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --未承諾
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'
                         AND  PHA.po_header_id              = PLA.po_header_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  pha.attribute4               >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')  -- 納入日
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                         --OPM品目ID取得
                         AND  PLA.item_id                   = MSI.inventory_item_id
                         AND  MSI.organization_id           = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                         AND  MSI.segment1                  = IIM.item_no
                         --OPMロットID取得
                         AND  IIM.item_id                   = ILM.item_id
-- 2010/01/07 T.Yoshimoto Mod Start E_本稼動#684
--                         AND (   ( IIM.lot_ctl = 1 AND PLA.attribute1 = ILM.lot_no )  --ロット管理品
--                              OR ( IIM.lot_ctl = 0 AND ILM.lot_id     = 0          )  --非ロット管理品
--                             )
                         AND  PLA.attribute1 = ILM.lot_no                                                               -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Mod End E_本稼動#684
                         --入庫先保管場所情報取得
                         AND  PHA.attribute5                = XILV.segment1
                      --[ １．発注受入予定  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．移動入庫予定(指示 積送あり＆積送なし)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MRIH.schedule_arrival_date    in_whse_date        --入庫日
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,MLD.actual_quantity           in_qty              --入庫予定バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   IN ( '02', '03' )   --02:依頼済、03:調整中
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.schedule_arrival_date   >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ２．移動入庫予定(指示 積送あり＆積送なし)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３－１．移動入庫予定(出庫報告有 積送あり 入庫予定日ベース)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MRIH.schedule_arrival_date    in_whse_date        --入庫日
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,MLD.actual_quantity           in_qty              --入庫予定バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '04'              --04:出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                         AND  mrih.actual_arrival_date     IS NULL                                                      -- E_本稼動#684
                         AND  mrih.schedule_arrival_date   >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')   -- E_本稼動#684
                         AND  mrih.ITEM_CLASS = '2'                                                                     -- E_本稼動#684
                         AND  mrih.PRODUCT_FLG = '1'                                                                    -- E_本稼動#684
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                      --[ ３－１．移動入庫予定(出庫報告有 積送あり 入庫予定日ベース)  End ]--
-- 2010/01/07 T.Yoshimoto Add Start E_本稼動#684
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３－２．移動入庫予定(出庫報告有 積送あり 入庫実績日ベース)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MRIH.actual_arrival_date      in_whse_date        --入庫日
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,MLD.actual_quantity           in_qty              --入庫予定バラ数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '04'              --04:出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                         AND  mrih.actual_arrival_date     IS NOT NULL
                         AND  mrih.actual_arrival_date     >= TRUNC(SYSDATE) - FND_PROFILE.VALUE('XXINV_TARGET_TERM')
                         AND  mrih.ITEM_CLASS = '2'
                         AND  mrih.PRODUCT_FLG = '1'
                      --[ ３－２．移動入庫予定(出庫報告有 積送あり 入庫実績日ベース)  End ]--
-- 2010/01/07 T.Yoshimoto Add End E_本稼動#684
                   )  ITRAN
                  ,ic_lots_mst                              ILM                 --OPMロットマスタ
            WHERE
              --OPMロットマスタとの結合
                   ITRAN.item_id                            = ILM.item_id
              AND  ITRAN.lot_id                             = ILM.lot_id
           GROUP BY ITRAN.whse_code     --倉庫コード
                   ,ITRAN.location      --保管場所コード
                   ,ITRAN.in_whse_date  --入庫日
                   ,ITRAN.item_id       --品目ID
                   ,ITRAN.lot_id        --ロットID
          -- 【 入庫予定数を出力するレコードを作成  End 】 --
        )  STRN
       ,ic_whse_mst                     IWM     --倉庫マスタ
       ,xxskz_item_locations_v          ILOC    --保管場所取得用
       ,xxskz_item_mst_v                ITEM    --品目名称取得用(現在日付で取得)
       ,xxskz_prod_class_v              PRODC   --商品区分取得用
       ,xxskz_item_class_v              ITEMC   --品目区分取得用
       ,xxskz_crowd_code_v              CROWD   --群コード取得用
       ,ic_lots_mst                     ILM     --ロットマスタ
       ,xxskz_vendors_v                 VNDR    --取引先名取得用
       ,xxskz_item_locations_v          FLOC    --代表倉庫名取得用
       ,xxwsh_frq_item_locations        XFIL    --倉庫品目アドオン(品目別代表倉庫取得用)
       ,xxskz_item_locations_v          FQLOC   --品目別代表倉庫名取得用
 WHERE
   --倉庫名取得用
        STRN.whse_code                  = IWM.whse_code(+)
   --保管場所（＋代表倉庫コード）取得
   AND  STRN.location                   = ILOC.segment1(+)
   --代表倉庫名取得
   AND  ILOC.frequent_whse              = FLOC.segment1(+)
   --品目別代表倉庫コード取得
   AND  STRN.location                   = XFIL.item_location_code(+)
   AND  STRN.item_id                    = XFIL.item_id(+)
   --品目別代表倉庫名取得
   AND  XFIL.frq_item_location_code     = FQLOC.segment1(+)
   --品目名称取得(現在日付で取得)
   AND  STRN.item_id                    = ITEM.item_id(+)
   --商品区分:ドリンクの条件  (※ここで条件を絞る方がレスポンスが良い)
   AND  PRODC.prod_class_code           = '2'
   AND  STRN.item_id                    = PRODC.item_id
   --品目区分:製品の条件      (※ここで条件を絞る方がレスポンスが良い)
   AND  ITEMC.item_class_code           = '5'
   AND  STRN.item_id                    = ITEMC.item_id
   --群コード取得
   AND  STRN.item_id                    = CROWD.item_id(+)
   --ロット情報取得
   AND  STRN.item_id                    = ILM.item_id(+)
   AND  STRN.lot_id                     = ILM.lot_id(+)
   --取引先名取得
   AND  ILM.attribute8                  = VNDR.segment1(+)
/
COMMENT ON TABLE APPS.XXSKZ_ドリンク在庫情報_基本_V IS 'SKYLINK用 ドリンク在庫情報（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.倉庫コード                 IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.倉庫名                     IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.代表倉庫コード             IS '代表倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.代表倉庫名                 IS '代表倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.代表倉庫略称               IS '代表倉庫略称'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保管場所コード             IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保管場所名                 IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保管場所略称               IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.商品区分                   IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.商品区分名                 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.品目区分                   IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.品目区分名                 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.群コード                   IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.品目                       IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.品目名                     IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.品目略称                   IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.ロットNO                   IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.製造年月日                 IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.固有記号                   IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.賞味期限                   IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.入庫日                     IS '入庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.入庫元コード               IS '入庫元コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.入庫元名                   IS '入庫元名'
/ 
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.在庫単価                   IS '在庫単価'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.未判定ケース在庫数         IS '未判定ケース在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.未判定バラ在庫数           IS '未判定バラ在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.未判定ケース出庫指示数     IS '未判定ケース出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.未判定バラ出庫指示数       IS '未判定バラ出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.良品ケース在庫数           IS '良品ケース在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.良品バラ在庫数             IS '良品バラ在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.良品ケース出庫指示数       IS '良品ケース出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.良品バラ出庫指示数         IS '良品バラ出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.条件付良品ケース在庫数     IS '条件付良品ケース在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.条件付良品バラ在庫数       IS '条件付良品バラ在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.条件付良品ケース出庫指示数 IS '条件付良品ケース出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.条件付良品バラ出庫指示数   IS '条件付良品バラ出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.不良品ケース在庫数         IS '不良品ケース在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.不良品バラ在庫数           IS '不良品バラ在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.不良品ケース出庫指示数     IS '不良品ケース出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.不良品バラ出庫指示数       IS '不良品バラ出庫指示数'
/
-- ***** 2009/09/24 #1634 S *****
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保留ケース在庫数           IS '保留ケース在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保留バラ在庫数             IS '保留バラ在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保留ケース出庫指示数       IS '保留ケース出庫指示数'
/
COMMENT ON COLUMN APPS.XXSKZ_ドリンク在庫情報_基本_V.保留バラ出庫指示数         IS '保留バラ出庫指示数'
/
-- ***** 2009/09/24 #1634 E *****

