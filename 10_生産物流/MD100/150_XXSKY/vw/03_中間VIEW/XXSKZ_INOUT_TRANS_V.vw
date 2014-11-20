/*************************************************************************
 * 
 * View  Name      : XXSKZ_INOUT_TRANS_V
 * Description     : XXSKZ_INOUT_TRANS_V
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai    初回作成
 *  2013/03/19    1.1   SCSK D.Sugahara E_本稼働_10479 課題20対応
 ************************************************************************/
--*******************************************************************
-- 入出庫情報 中間VIEW
--   当VIEWではロット割り当てされている予定データのみを出力する
--    ⇒ ドリンク部門向け
--
--   【使用対象VIEW】
--     ・XXSKZ_入出庫情報_基本_V
--     ・XXSKZ_入出庫情報_数量_V
--     ・XXSKZ_入出庫情報_日別_V
--     ・XXSKZ_入出庫情報_発日_V
--*******************************************************************
CREATE OR REPLACE VIEW APPS.XXSKZ_INOUT_TRANS_V
(
 reason_code
,whse_code
,location_code
,location
,location_s_name
,item_id
,item_no
,item_name
,item_short_name
,case_content
,lot_ctl
,lot_id
,lot_no
,manufacture_date
,uniqe_sign
,expiration_date
,voucher_no
,line_no
,delivery_no
,loct_code
,loct_name
,in_out_kbn
,leaving_date
,arrival_date
,standard_date
,ukebaraisaki_code
,ukebaraisaki_name
,status
,deliver_to_no
,deliver_to_name
,stock_quantity
,leaving_quantity
,quantity
)
AS
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--■ 【入庫予定】                                                     ■
--■    １．発注受入予定                                              ■
--■    ２．移動入庫予定(指示 積送あり)                               ■
--■    ３．移動入庫予定(指示 積送なし)                               ■
--■    ４．移動入庫予定(出庫報告有 積送あり)                         ■
--■    ５．生産入庫予定                                              ■
--■    ６．生産入庫予定 品目振替 品種振替                            ■
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  -------------------------------------------------------------
  -- １．発注受入予定
  -------------------------------------------------------------
  SELECT
          xrpm_in_po.new_div_invent                     AS reason_code            -- 事由コード
         ,xilv_in_po.whse_code                          AS whse_code              -- 倉庫コード
         ,xilv_in_po.segment1                           AS location_code          -- 保管場所コード
         ,xilv_in_po.description                        AS location               -- 保管場所名
         ,xilv_in_po.short_name                         AS location_s_name        -- 保管場所略称
         ,ximv_in_po.item_id                            AS item_id                -- 品目ID
         ,ximv_in_po.item_no                            AS item_no                -- 品目コード
         ,ximv_in_po.item_name                          AS item_name              -- 品目名
         ,ximv_in_po.item_short_name                    AS item_short_name        -- 品目略称
         ,ximv_in_po.num_of_cases                       AS case_content           -- ケース入数
         ,ximv_in_po.lot_ctl                            AS lot_ctl                -- ロット管理区分
         ,ilm_in_po.lot_id                              AS lot_id                 -- ロットID
         ,ilm_in_po.lot_no                              AS lot_no                 -- ロットNo
         ,ilm_in_po.attribute1                          AS manufacture_date       -- 製造年月日
         ,ilm_in_po.attribute2                          AS uniqe_sign             -- 固有記号
         ,ilm_in_po.attribute3                          AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,pha_in_po.segment1                            AS voucher_no             -- 伝票番号
         ,pla_in_po.line_num                            AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,pha_in_po.attribute10                         AS loct_code              -- 部署コード
         ,xlc_in_po.location_name                       AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS leaving_date           -- 入出庫日_発日
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS arrival_date           -- 入出庫日_着日
         ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS standard_date          -- 基準日（着日）
         ,xvv_in_po.segment1                            AS ukebaraisaki_code      -- 受払先コード
         ,xvv_in_po.vendor_name                         AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_in_po.segment1                           AS deliver_to_no          -- 配送先コード
         ,xilv_in_po.description                        AS deliver_to_name        -- 配送先名
         ,pla_in_po.quantity                            AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,pla_in_po.quantity                            AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_po                -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_po                -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_po                 -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_po                -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,po_headers_all                                pha_in_po                 -- 発注ヘッダ
         ,po_lines_all                                  pla_in_po                 -- 発注明細
         ,xxskz_vendors2_v                              xvv_in_po                 -- 仕入先情報VIEW(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_po                 -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_in_po.doc_type                           = 'PORC'
     AND  xrpm_in_po.source_document_code               = 'PO'
     AND  xrpm_in_po.use_div_invent                     = 'Y'
     AND  xrpm_in_po.transaction_type                   = 'DELIVER'
     --発注ヘッダの条件
     AND  pha_in_po.attribute1                          IN ( '20'                 -- 発注作成済
                                                            ,'25' )               -- 受入あり
     --発注明細との結合
     AND  NVL( pla_in_po.attribute13, 'N' )            <> 'Y'    --未承諾
     AND  NVL( pla_in_po.cancel_flag, 'N' )            <> 'Y'
     AND  pha_in_po.po_header_id                        = pla_in_po.po_header_id
     --品目マスタとの結合
     AND  pla_in_po.item_id                             = ximv_in_po.inventory_item_id
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= ximv_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= ximv_in_po.end_date_active
     --ロット情報取得
     AND  ximv_in_po.item_id                            = ilm_in_po.item_id
     AND (   ( ximv_in_po.lot_ctl = 1 AND pla_in_po.attribute1 = ilm_in_po.lot_no )  -- ロット管理品
          OR ( ximv_in_po.lot_ctl = 0 AND 'DEFAULTLOT'         = ilm_in_po.lot_no )  -- 非ロット管理品
         )
     --保管場所情報取得
     AND  pha_in_po.attribute5                          = xilv_in_po.segment1
     --取引先情報取得
     AND  xvv_in_po.vendor_id                           = pha_in_po.vendor_id
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xvv_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xvv_in_po.end_date_active
     -- 部署名取得(外部結合とする)
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  pha_in_po.attribute10                         = xlc_in_po.location_code(+)
--     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xlc_in_po.start_date_active(+)
--     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xlc_in_po.end_date_active(+)
     AND  pha_in_po.attribute10                         = xlc_in_po.location_code
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) >= xlc_in_po.start_date_active
     AND  TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) <= xlc_in_po.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ １．発注受入予定  END ]
UNION ALL
  -------------------------------------------------------------
  -- ２．移動入庫予定(指示 積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf.new_div_invent                     AS reason_code            -- 事由コード
         ,xilv_in_xf.whse_code                          AS whse_code              -- 倉庫コード
         ,xilv_in_xf.segment1                           AS location_code          -- 保管場所コード
         ,xilv_in_xf.description                        AS location               -- 保管場所名
         ,xilv_in_xf.short_name                         AS location_s_name        -- 保管場所略称
         ,ximv_in_xf.item_id                            AS item_id                -- 品目ID
         ,ximv_in_xf.item_no                            AS item_no                -- 品目コード
         ,ximv_in_xf.item_name                          AS item_name              -- 品目名
         ,ximv_in_xf.item_short_name                    AS item_short_name        -- 品目略称
         ,ximv_in_xf.num_of_cases                       AS case_content           -- ケース入数
         ,ximv_in_xf.lot_ctl                            AS lot_ctl                -- ロット管理区分
         ,ilm_in_xf.lot_id                              AS lot_id                 -- ロットID
         ,ilm_in_xf.lot_no                              AS lot_no                 -- ロットNo
         ,ilm_in_xf.attribute1                          AS manufacture_date       -- 製造年月日
         ,ilm_in_xf.attribute2                          AS uniqe_sign             -- 固有記号
         ,ilm_in_xf.attribute3                          AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_in_xf.mov_num                           AS voucher_no             -- 伝票番号
         ,xmril_in_xf.line_number                       AS line_no                -- 行番号
         ,xmrih_in_xf.delivery_no                       AS delivery_no            -- 配送番号
         ,xmrih_in_xf.instruction_post_code             AS loct_code              -- 部署コード
         ,xlc_in_xf.location_name                       AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xmrih_in_xf.schedule_ship_date                AS leaving_date           -- 入出庫日_発日
         ,xmrih_in_xf.schedule_arrival_date             AS arrival_date           -- 入出庫日_着日
         ,xmrih_in_xf.schedule_arrival_date             AS standard_date          -- 基準日（着日）
         ,xilv_in_xf2.segment1                          AS ukebaraisaki_code      -- 受払先コード
         ,xilv_in_xf2.description                       AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_in_xf2.segment1                          AS deliver_to_no          -- 配送先コード
         ,xilv_in_xf2.description                       AS deliver_to_name        -- 配送先名
         ,CASE WHEN xmld_in_xf.mov_lot_dtl_id IS NULL THEN xmril_in_xf.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                        xmld_in_xf.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_in_xf.mov_lot_dtl_id IS NULL THEN xmril_in_xf.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                        xmld_in_xf.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_xf                -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf                -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_xf                 -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf                -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf               -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf               -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf                -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_in_xf2               -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_xf                 -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_in_xf.doc_type                           = 'XFER'                  -- 移動積送あり
     AND  xrpm_in_xf.use_div_invent                     = 'Y'
     AND  xrpm_in_xf.rcv_pay_div                        = '1'                     -- 受入
     --移動ヘッダの条件
     AND  xmrih_in_xf.mov_type                          = '1'
     AND  NVL( xmrih_in_xf.comp_actual_flg, 'N' )       = 'N'                     -- 実績未計上
     AND  xmrih_in_xf.status                            IN ( '02'                 -- 依頼済
                                                            ,'03' )               -- 調整中
     --移動明細との結合
     AND  NVL( xmril_in_xf.delete_flg, 'N' )            = 'N'                     -- 無効明細以外
     AND  xmrih_in_xf.mov_hdr_id                        = xmril_in_xf.mov_hdr_id
     --移動ロット詳細取得
     AND  xmld_in_xf.document_type_code                 = '20'                    -- 移動
     AND  xmld_in_xf.record_type_code                   = '10'                    -- 指示
     AND  xmril_in_xf.mov_line_id                       = xmld_in_xf.mov_line_id
     --品目マスタ情報取得
     AND  xmril_in_xf.item_id                           = ximv_in_xf.item_id
     AND  xmrih_in_xf.schedule_arrival_date            >= ximv_in_xf.start_date_active
     AND  xmrih_in_xf.schedule_arrival_date            <= ximv_in_xf.end_date_active
     --ロット情報取得
     AND  xmld_in_xf.item_id                            = ilm_in_xf.item_id
     AND  xmld_in_xf.lot_id                             = ilm_in_xf.lot_id
     --OPM保管場所情報取得
     AND  xmrih_in_xf.ship_to_locat_id                  = xilv_in_xf.inventory_location_id
     --OPM保管場所情報2取得
     AND  xmrih_in_xf.shipped_locat_id                  = xilv_in_xf2.inventory_location_id
     -- 部署名取得(外部結合とする)
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_in_xf.instruction_post_code             = xlc_in_xf.location_code(+)
--     AND  xmrih_in_xf.schedule_arrival_date            >= xlc_in_xf.start_date_active(+)
--     AND  xmrih_in_xf.schedule_arrival_date            <= xlc_in_xf.end_date_active(+)
     AND  xmrih_in_xf.instruction_post_code             = xlc_in_xf.location_code
     AND  xmrih_in_xf.schedule_arrival_date            >= xlc_in_xf.start_date_active
     AND  xmrih_in_xf.schedule_arrival_date            <= xlc_in_xf.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ２．移動入庫予定(指示 積送あり)  END ]
UNION ALL
  -------------------------------------------------------------
  -- ３．移動入庫予定(指示 積送なし)
  -------------------------------------------------------------
  SELECT
          xrpm_in_tr.new_div_invent                     AS reason_code            -- 事由コード
         ,xilv_in_tr.whse_code                          AS whse_code              -- 倉庫コード
         ,xilv_in_tr.segment1                           AS location_code          -- 保管場所コード
         ,xilv_in_tr.description                        AS location               -- 保管場所名
         ,xilv_in_tr.short_name                         AS location_s_name        -- 保管場所略称
         ,ximv_in_tr.item_id                            AS item_id                -- 品目ID
         ,ximv_in_tr.item_no                            AS item_no                -- 品目コード
         ,ximv_in_tr.item_name                          AS item_name              -- 品目名
         ,ximv_in_tr.item_short_name                    AS item_short_name        -- 品目略称
         ,ximv_in_tr.num_of_cases                       AS case_content           -- ケース入数
         ,ximv_in_tr.lot_ctl                            AS lot_ctl                -- ロット管理区分
         ,ilm_in_tr.lot_id                              AS lot_id                 -- ロットID
         ,ilm_in_tr.lot_no                              AS lot_no                 -- ロットNo
         ,ilm_in_tr.attribute1                          AS manufacture_date       -- 製造年月日
         ,ilm_in_tr.attribute2                          AS uniqe_sign             -- 固有記号
         ,ilm_in_tr.attribute3                          AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_in_tr.mov_num                           AS voucher_no             -- 伝票番号
         ,xmril_in_tr.line_number                       AS line_no                -- 行番号
         ,xmrih_in_tr.delivery_no                       AS delivery_no            -- 配送番号
         ,xmrih_in_tr.instruction_post_code             AS loct_code              -- 部署コード
         ,xlc_in_tr.location_name                       AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xmrih_in_tr.schedule_ship_date                AS leaving_date           -- 入出庫日_発日
         ,xmrih_in_tr.schedule_arrival_date             AS arrival_date           -- 入出庫日_着日
         ,xmrih_in_tr.schedule_arrival_date             AS standard_date          -- 基準日（着日）
         ,xilv_in_tr2.segment1                          AS ukebaraisaki_code      -- 受払先コード
         ,xilv_in_tr2.description                       AS ukebaraisaki_name      -- 受払先名(受払先名取得用)
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_in_tr2.segment1                          AS deliver_to_no          -- 配送先コード
         ,xilv_in_tr2.description                       AS deliver_to_name        -- 配送先名
         ,CASE WHEN xmld_in_tr.mov_lot_dtl_id IS NULL THEN xmril_in_tr.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                        xmld_in_tr.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_in_tr.mov_lot_dtl_id IS NULL THEN xmril_in_tr.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                        xmld_in_tr.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_tr                -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_tr                -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_tr                 -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_tr                -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_tr               -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_tr               -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_tr                -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_in_tr2               -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_tr                 -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_in_tr.doc_type                           = 'TRNI'                  -- 移動積送なし
     AND  xrpm_in_tr.use_div_invent                     = 'Y'
     AND  xrpm_in_tr.rcv_pay_div                        = '1'                     -- 受入
     --移動ヘッダの条件
     AND  xmrih_in_tr.mov_type                          = '2'
     AND  NVL( xmrih_in_tr.comp_actual_flg, 'N' )       = 'N'                     -- 実績未計上
     AND  xmrih_in_tr.status                            IN ( '02'                 -- 依頼済
                                                            ,'03' )               -- 調整中
     --移動明細との結合
     AND  NVL( xmril_in_tr.delete_flg, 'N' )            = 'N'                     -- 無効明細以外
     AND  xmrih_in_tr.mov_hdr_id                        = xmril_in_tr.mov_hdr_id
     --移動ロット詳細との結合
     AND  xmld_in_tr.document_type_code                 = '20'                    -- 移動
     AND  xmld_in_tr.record_type_code                   = '10'                    -- 指示
     AND  xmril_in_tr.mov_line_id                       = xmld_in_tr.mov_line_id
     --品目マスタ情報取得
     AND  xmril_in_tr.item_id                           = ximv_in_tr.item_id
     AND  xmrih_in_tr.schedule_arrival_date            >= ximv_in_tr.start_date_active
     AND  xmrih_in_tr.schedule_arrival_date            <= ximv_in_tr.end_date_active
     --ロット情報取得
     AND  xmld_in_tr.item_id                            = ilm_in_tr.item_id
     AND  xmld_in_tr.lot_id                             = ilm_in_tr.lot_id
     --OPM保管場所情報取得
     AND  xmrih_in_tr.ship_to_locat_id                  = xilv_in_tr.inventory_location_id
     --OPM保管場所情報2取得
     AND  xmrih_in_tr.shipped_locat_id                  = xilv_in_tr2.inventory_location_id
     -- 部署名取得(外部結合とする)
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_in_tr.instruction_post_code             = xlc_in_tr.location_code(+)
--     AND  xmrih_in_tr.schedule_arrival_date            >= xlc_in_tr.start_date_active(+)
--     AND  xmrih_in_tr.schedule_arrival_date            <= xlc_in_tr.end_date_active(+)
     AND  xmrih_in_tr.instruction_post_code             = xlc_in_tr.location_code
     AND  xmrih_in_tr.schedule_arrival_date            >= xlc_in_tr.start_date_active
     AND  xmrih_in_tr.schedule_arrival_date            <= xlc_in_tr.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ３．移動入庫予定(指示 積送なし)  END ]
UNION ALL
  -------------------------------------------------------------
  -- ４．移動入庫予定(出庫報告有 積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf20.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_xf20.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_xf20.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_xf20.description                      AS location               -- 保管場所名
         ,xilv_in_xf20.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_xf20.item_id                          AS item_id                -- 品目ID
         ,ximv_in_xf20.item_no                          AS item_no                -- 品目コード
         ,ximv_in_xf20.item_name                        AS item_name              -- 品目名
         ,ximv_in_xf20.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_xf20.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_xf20.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_xf20.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_xf20.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_xf20.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_xf20.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_in_xf20.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_in_xf20.mov_num                         AS voucher_no             -- 伝票番号
         ,xmril_in_xf20.line_number                     AS line_no                -- 行番号
         ,xmrih_in_xf20.delivery_no                     AS delivery_no            -- 配送番号
         ,xmrih_in_xf20.instruction_post_code           AS loct_code              -- 部署コード
         ,xlc_in_xf20.location_name                     AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xmrih_in_xf20.schedule_ship_date              AS leaving_date           -- 入出庫日_発日
         ,xmrih_in_xf20.schedule_arrival_date           AS arrival_date           -- 入出庫日_着日
         ,xmrih_in_xf20.schedule_arrival_date           AS standard_date          -- 基準日（着日）
         ,xilv_in_xf202.segment1                        AS ukebaraisaki_code      -- 受払先コード
         ,xilv_in_xf202.description                     AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_in_xf202.segment1                        AS deliver_to_no          -- 配送先コード
         ,xilv_in_xf202.description                     AS deliver_to_name        -- 配送先名
         ,CASE WHEN xmld_in_xf20.mov_lot_dtl_id IS NULL THEN xmril_in_xf20.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                          xmld_in_xf20.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_in_xf20.mov_lot_dtl_id IS NULL THEN xmril_in_xf20.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                          xmld_in_xf20.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_xf20              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf20              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_xf20               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf20              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf20             -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf20             -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf20              -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_in_xf202             -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_xf20               -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_in_xf20.doc_type                         = 'XFER'                  -- 移動積送あり
     AND  xrpm_in_xf20.use_div_invent                   = 'Y'
     AND  xrpm_in_xf20.rcv_pay_div                      = '1'                     -- 受入
     --移動依頼/指示ヘッダ(アドオン)の条件
     AND  xmrih_in_xf20.mov_type                        = '1'                     -- 積送あり
     AND  NVL( xmrih_in_xf20.comp_actual_flg, 'N' )     = 'N'                     -- 実績未計上
     AND  xmrih_in_xf20.status                          = '04'                    -- 出庫報告有
     --移動依頼/指示明細(アドオン)との結合
     AND  NVL( xmril_in_xf20.delete_flg, 'N' )          = 'N'                     -- 無効明細以外
     AND  xmrih_in_xf20.mov_hdr_id                      = xmril_in_xf20.mov_hdr_id
     --移動ロット詳細取得
     AND  xmld_in_xf20.document_type_code               = '20'                    -- 移動
     AND  xmld_in_xf20.record_type_code                 = '20'                    -- 出庫実績
     AND  xmril_in_xf20.mov_line_id                     = xmld_in_xf20.mov_line_id
     --品目マスタ情報取得
     AND  xmril_in_xf20.item_id                         = ximv_in_xf20.item_id
     AND  xmrih_in_xf20.schedule_arrival_date          >= ximv_in_xf20.start_date_active
     AND  xmrih_in_xf20.schedule_arrival_date          <= ximv_in_xf20.end_date_active
     --ロット情報取得
     AND  xmld_in_xf20.item_id                          = ilm_in_xf20.item_id
     AND  xmld_in_xf20.lot_id                           = ilm_in_xf20.lot_id
     --OPM保管場所情報取得
     AND  xmrih_in_xf20.ship_to_locat_id                = xilv_in_xf20.inventory_location_id
     --OPM保管場所情報2取得
     AND  xmrih_in_xf20.shipped_locat_id                = xilv_in_xf202.inventory_location_id
     --部署名取得(外部結合とする)
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_in_xf20.instruction_post_code           = xlc_in_xf20.location_code(+)
--     AND  xmrih_in_xf20.schedule_arrival_date          >= xlc_in_xf20.start_date_active(+)
--     AND  xmrih_in_xf20.schedule_arrival_date          <= xlc_in_xf20.end_date_active(+)
     AND  xmrih_in_xf20.instruction_post_code           = xlc_in_xf20.location_code
     AND  xmrih_in_xf20.schedule_arrival_date          >= xlc_in_xf20.start_date_active
     AND  xmrih_in_xf20.schedule_arrival_date          <= xlc_in_xf20.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ４．移動入庫予定(出庫報告有 積送あり)  END ]
UNION ALL
  -------------------------------------------------------------
  -- ５．生産入庫予定
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr.new_div_invent                     AS reason_code            -- 事由コード
         ,xilv_in_pr.whse_code                          AS whse_code              -- 倉庫コード
         ,xilv_in_pr.segment1                           AS location_code          -- 保管場所コード
         ,xilv_in_pr.description                        AS location               -- 保管場所名
         ,xilv_in_pr.short_name                         AS location_s_name        -- 保管場所略称
         ,ximv_in_pr.item_id                            AS item_id                -- 品目ID
         ,ximv_in_pr.item_no                            AS item_no                -- 品目コード
         ,ximv_in_pr.item_name                          AS item_name              -- 品目名
         ,ximv_in_pr.item_short_name                    AS item_short_name        -- 品目略称
         ,ximv_in_pr.num_of_cases                       AS case_content           -- ケース入数
         ,ximv_in_pr.lot_ctl                            AS lot_ctl                -- ロット管理区分
         ,ilm_in_pr.lot_id                              AS lot_id                 -- ロットID
         ,ilm_in_pr.lot_no                              AS lot_no                 -- ロットNo
         ,ilm_in_pr.attribute1                          AS manufacture_date       -- 製造年月日
         ,ilm_in_pr.attribute2                          AS uniqe_sign             -- 固有記号
         ,ilm_in_pr.attribute3                          AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_in_pr.batch_no                            AS voucher_no             -- 伝票番号
         ,gmd_in_pr.line_no                             AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_in_pr.attribute2                          AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,gbh_in_pr.plan_start_date                     AS leaving_date           -- 入出庫日_発日
         ,gbh_in_pr.plan_start_date                     AS arrival_date           -- 入出庫日_着日
         ,gbh_in_pr.plan_start_date                     AS standard_date          -- 基準日（着日）
         ,grb_in_pr.routing_no                          AS ukebaraisaki_code      -- 受払先コード
         ,grt_in_pr.routing_desc                        AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,gmd_in_pr.plan_qty                            AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,gmd_in_pr.plan_qty                            AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_pr                -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr                -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_pr                 -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr                -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr                 -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_in_pr                 -- 生産原料詳細（標準）バックアップ
         ,gmd_routings_b                                grb_in_pr                 -- 工順マスタ
         ,gmd_routings_tl                               grt_in_pr                 -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr                 -- OPM保留在庫トランザクション（標準）バックアップ
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_pr.doc_type                           = 'PROD'
     AND  xrpm_in_pr.use_div_invent                     = 'Y'
     -- 生産バッチヘッダの条件
     AND  gbh_in_pr.batch_status                        IN ( '1', '2' )           -- 1:保留、2:WIP
     -- 工順マスタとの結合（生産データ取得の条件）
     AND  grb_in_pr.routing_class                       NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
     AND  grb_in_pr.routing_id                          = gbh_in_pr.routing_id
     AND  xrpm_in_pr.routing_class                      = grb_in_pr.routing_class
     -- 生産原料詳細との結合
     AND  gmd_in_pr.line_type                           IN ( 1, 2 )               -- 1:完成品、2:副産物
     AND  gbh_in_pr.batch_id                            = gmd_in_pr.batch_id
     AND  xrpm_in_pr.line_type                          = gmd_in_pr.line_type
     AND (   ( ( gmd_in_pr.attribute5 IS NULL     ) AND ( xrpm_in_pr.hit_in_div IS NULL ) )
          OR ( ( gmd_in_pr.attribute5 IS NOT NULL ) AND ( xrpm_in_pr.hit_in_div = gmd_in_pr.attribute5 ) )
         )
     -- OPM保留在庫トランザクションとの結合
     AND  itp_in_pr.delete_mark                         = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_in_pr.completed_ind                       = 0                       -- 完了していない(⇒予定)
     AND  itp_in_pr.reverse_id                          IS NULL
     AND  itp_in_pr.doc_type                            = xrpm_in_pr.doc_type
     AND  itp_in_pr.line_id                             = gmd_in_pr.material_detail_id
     AND  itp_in_pr.location                            = grb_in_pr.attribute9
     AND  itp_in_pr.item_id                             = gmd_in_pr.item_id
     -- 品目マスタとの結合
     AND  gmd_in_pr.item_id                             = ximv_in_pr.item_id
     AND  gbh_in_pr.plan_start_date                    >= ximv_in_pr.start_date_active
     AND  gbh_in_pr.plan_start_date                    <= ximv_in_pr.end_date_active
     -- ロット情報取得
     AND  ximv_in_pr.item_id                            = ilm_in_pr.item_id
     AND  itp_in_pr.lot_id                              = ilm_in_pr.lot_id
     -- OPM保管場所情報取得
     AND  grb_in_pr.attribute9                          = xilv_in_pr.segment1
     -- 工順マスタ日本語との結合(受払先名取得)
     AND  grt_in_pr.language                            = 'JA'
     AND  grb_in_pr.routing_id                          = grt_in_pr.routing_id
  -- [ ５．生産入庫予定  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ６．生産入庫予定 品目振替 品種振替
  -- 【注】以下のSQLは変更次第で処理速度が遅くなります
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr70.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_pr70.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_pr70.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_pr70.description                      AS location               -- 保管場所名
         ,xilv_in_pr70.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_pr70.item_id                          AS item_id                -- 品目ID
         ,ximv_in_pr70.item_no                          AS item_no                -- 品目コード
         ,ximv_in_pr70.item_name                        AS item_name              -- 品目名
         ,ximv_in_pr70.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_pr70.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_pr70.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_pr70.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_pr70.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_pr70.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_pr70.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_in_pr70.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_in_pr70.batch_no                          AS voucher_no             -- 伝票番号
         ,gmd_in_pr70a.line_no                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_in_pr70.attribute2                        AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,itp_in_pr70.trans_date                        AS leaving_date           -- 入出庫日_発日
         ,itp_in_pr70.trans_date                        AS arrival_date           -- 入出庫日_着日
         ,itp_in_pr70.trans_date                        AS standard_date          -- 基準日（着日）
         ,grb_in_pr70.routing_no                        AS ukebaraisaki_code      -- 受払先コード
         ,grt_in_pr70.routing_desc                      AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,gmd_in_pr70a.plan_qty                         AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,gmd_in_pr70a.plan_qty                         AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_pr70              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr70              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_pr70               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr70              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr70               -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_in_pr70a              -- 生産原料詳細（標準）バックアップ(振替先)
         ,xxcmn_gme_material_details_arc                gmd_in_pr70b              -- 生産原料詳細（標準）バックアップ(振替元)
         ,gmd_routings_b                                grb_in_pr70               -- 工順マスタ
         ,gmd_routings_tl                               grt_in_pr70               -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr70               -- OPM保留在庫トランザクション（標準）バックアップ
         ,xxskz_item_class_v                            xicv_in_pr70b             -- OPM品目カテゴリ割当情報VIEW5(振替元)
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_pr70.doc_type                         = 'PROD'
     AND  xrpm_in_pr70.use_div_invent                   = 'Y'
     -- 工順マスタとの結合（品目振替データ取得の条件）
     AND  grb_in_pr70.routing_class                     = '70'                    -- 品目振替
     AND  gbh_in_pr70.routing_id                        = grb_in_pr70.routing_id
     AND  xrpm_in_pr70.routing_class                    = grb_in_pr70.routing_class
     -- 生産原料詳細(振替先)との結合
     AND  gmd_in_pr70a.line_type                        = 1                       -- 振替先
     AND  gbh_in_pr70.batch_id                          = gmd_in_pr70a.batch_id
     AND  xrpm_in_pr70.line_type                        = gmd_in_pr70a.line_type
     -- 生産原料詳細(振替元)との結合
     AND  gmd_in_pr70b.line_type                        = -1                      -- 振替元
     AND  gbh_in_pr70.batch_id                          = gmd_in_pr70b.batch_id
     AND  gmd_in_pr70a.batch_id                         = gmd_in_pr70b.batch_id   -- ←処理速度UPに有効
     -- OPM保留在庫トランザクションとの結合
     AND  itp_in_pr70.delete_mark                       = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_in_pr70.completed_ind                     = 0                       -- 完了していない(⇒予定)
     AND  itp_in_pr70.reverse_id                        IS NULL
     AND  itp_in_pr70.lot_id                           <> 0                       -- 資材はあり得ない
     AND  itp_in_pr70.doc_type                          = xrpm_in_pr70.doc_type
     AND  itp_in_pr70.doc_id                            = gmd_in_pr70a.batch_id   -- ←処理速度UPに有効
     AND  itp_in_pr70.doc_line                          = gmd_in_pr70a.line_no    -- ←処理速度UPに有効
     AND  itp_in_pr70.line_type                         = gmd_in_pr70a.line_type  -- ←処理速度UPに有効
     AND  itp_in_pr70.line_id                           = gmd_in_pr70a.material_detail_id
     AND  itp_in_pr70.item_id                           = ximv_in_pr70.item_id
     -- OPM品目情報VIEW
     AND  gmd_in_pr70a.item_id                          = ximv_in_pr70.item_id
     AND  itp_in_pr70.trans_date                       >= ximv_in_pr70.start_date_active
     AND  itp_in_pr70.trans_date                       <= ximv_in_pr70.end_date_active
     -- OPM品目カテゴリ割当情報VIEW5(振替先、振替元)
     AND  gmd_in_pr70b.item_id                          = xicv_in_pr70b.item_id
     AND (    xrpm_in_pr70.item_div_ahead               = ximv_in_pr70.item_class_code   -- 振替先
          AND xrpm_in_pr70.item_div_origin              = xicv_in_pr70b.item_class_code  -- 振替元
          AND (   ( ximv_in_pr70.item_class_code       <> xicv_in_pr70b.item_class_code )
               OR ( ximv_in_pr70.item_class_code        = xicv_in_pr70b.item_class_code )
              )
         )
     -- OPMロットマスタ情報取得
     AND  ximv_in_pr70.item_id                          = ilm_in_pr70.item_id
     AND  itp_in_pr70.lot_id                            = ilm_in_pr70.lot_id
     -- OPM保管場所情報取得
     AND  itp_in_pr70.whse_code                         = xilv_in_pr70.whse_code
     AND  itp_in_pr70.location                          = xilv_in_pr70.segment1
     -- 工順マスタ日本語との結合(受払先名取得)
     AND  grt_in_pr70.language                          = 'JA'
     AND  grb_in_pr70.routing_id                        = grt_in_pr70.routing_id
  -- [ ６．生産入庫予定 品目振替 品種振替  END ] --
-- << 入庫予定 END >>
UNION ALL
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--■ 【出庫予定】                                                     ■
--■    １．移動出庫予定(指示 積送あり)                               ■
--■    ２．移動出庫予定(指示 積送なし)                               ■
--■    ３．移動出庫予定(入庫報告有 積送あり)                         ■
--■    ４．受注出荷予定                                              ■
--■    ５．有償出荷予定                                              ■
--■    ６．生産原料投入予定                                          ■
--■    ７．生産出庫予定 品目振替 品種振替                            ■
--■    ８．相手先在庫出庫予定                                        ■
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  -------------------------------------------------------------
  -- １．移動出庫予定(指示 積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf.new_div_invent                    AS reason_code            -- 事由コード
         ,xilv_out_xf.whse_code                         AS whse_code              -- 倉庫コード
         ,xilv_out_xf.segment1                          AS location_code          -- 保管場所コード
         ,xilv_out_xf.description                       AS location               -- 保管場所名
         ,xilv_out_xf.short_name                        AS location_s_name        -- 保管場所略称
         ,ximv_out_xf.item_id                           AS item_id                -- 品目ID
         ,ximv_out_xf.item_no                           AS item_no                -- 品目コード
         ,ximv_out_xf.item_name                         AS item_name              -- 品目名
         ,ximv_out_xf.item_short_name                   AS item_short_name        -- 品目略称
         ,ximv_out_xf.num_of_cases                      AS case_content           -- ケース入数
         ,ximv_out_xf.lot_ctl                           AS lot_ctl                -- ロット管理区分
         ,ilm_out_xf.lot_id                             AS lot_id                 -- ロットID
         ,ilm_out_xf.lot_no                             AS lot_no                 -- ロットNo
         ,ilm_out_xf.attribute1                         AS manufacture_date       -- 製造年月日
         ,ilm_out_xf.attribute2                         AS uniqe_sign             -- 固有記号
         ,ilm_out_xf.attribute3                         AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_out_xf.mov_num                          AS voucher_no             -- 伝票番号
         ,xmril_out_xf.line_number                      AS line_no                -- 行番号
         ,xmrih_out_xf.delivery_no                      AS delivery_no            -- 配送番号
         ,xmrih_out_xf.instruction_post_code            AS loct_code              -- 部署コード
         ,xlc_out_xf.location_name                      AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xmrih_out_xf.schedule_ship_date               AS leaving_date           -- 入出庫日_発日
         ,xmrih_out_xf.schedule_arrival_date            AS arrival_date           -- 入出庫日_着日
         ,xmrih_out_xf.schedule_ship_date               AS standard_date          -- 基準日（発日）
         ,xilv_out_xf2.segment1                         AS ukebaraisaki_code      -- 受払先コード
         ,xilv_out_xf2.description                      AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_out_xf2.segment1                         AS deliver_to_no          -- 配送先コード
         ,xilv_out_xf2.description                      AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,CASE WHEN xmld_out_xf.mov_lot_dtl_id IS NULL THEN xmril_out_xf.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                         xmld_out_xf.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_out_xf.mov_lot_dtl_id IS NULL THEN xmril_out_xf.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                         xmld_out_xf.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_xf               -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf               -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_xf                -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf               -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf              -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf              -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf               -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_out_xf2              -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_xf                -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_xf.doc_type                         = 'XFER'                   -- 移動積送あり
     AND  xrpm_out_xf.use_div_invent                   = 'Y'
     AND  xrpm_out_xf.rcv_pay_div                      = '-1'                     -- 払出
     --移動依頼/指示ヘッダの条件
     AND  xmrih_out_xf.comp_actual_flg                 = 'N'                      -- 実績未計上
     AND  xmrih_out_xf.status                          IN ( '02'                  -- 依頼済
                                                           ,'03' )                -- 調整中
     AND  xmrih_out_xf.mov_type                        = '1'
     --移動依頼/指示明細との結合
     AND  xmril_out_xf.delete_flg                      = 'N'                      -- OFF
     AND  xmrih_out_xf.mov_hdr_id                      = xmril_out_xf.mov_hdr_id
     --品目マスタとの結合
     AND  xmril_out_xf.item_id                         = ximv_out_xf.item_id
     AND  xmrih_out_xf.schedule_ship_date             >= ximv_out_xf.start_date_active --適用開始日
     AND  xmrih_out_xf.schedule_ship_date             <= ximv_out_xf.end_date_active   --適用終了日
     --移動ロット詳細取得
     AND  xmld_out_xf.document_type_code               = '20'                     -- 移動
     AND  xmld_out_xf.record_type_code                 = '10'                     -- 指示
     AND  xmril_out_xf.mov_line_id                     = xmld_out_xf.mov_line_id
     --ロット情報取得
     AND  xmld_out_xf.item_id                          = ilm_out_xf.item_id
     AND  xmld_out_xf.lot_id                           = ilm_out_xf.lot_id
     --保管場所情報取得
     AND  xmrih_out_xf.shipped_locat_id                = xilv_out_xf.inventory_location_id
     --受払先情報取得
     AND  xmrih_out_xf.ship_to_locat_id                = xilv_out_xf2.inventory_location_id
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_out_xf.instruction_post_code           = xlc_out_xf.location_code(+)
--     AND  xmrih_out_xf.schedule_ship_date             >= xlc_out_xf.start_date_active(+)
--     AND  xmrih_out_xf.schedule_ship_date             <= xlc_out_xf.end_date_active(+)
     AND  xmrih_out_xf.instruction_post_code           = xlc_out_xf.location_code
     AND  xmrih_out_xf.schedule_ship_date             >= xlc_out_xf.start_date_active
     AND  xmrih_out_xf.schedule_ship_date             <= xlc_out_xf.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ １．移動出庫予定(指示 積送あり)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ２．移動出庫予定(指示 積送なし)
  -------------------------------------------------------------
  SELECT
          xrpm_out_tr.new_div_invent                    AS reason_code            -- 事由コード
         ,xilv_out_tr.whse_code                         AS whse_code              -- 倉庫コード
         ,xilv_out_tr.segment1                          AS location_code          -- 保管場所コード
         ,xilv_out_tr.description                       AS location               -- 保管場所名
         ,xilv_out_tr.short_name                        AS location_s_name        -- 保管場所略称
         ,ximv_out_tr.item_id                           AS item_id                -- 品目ID
         ,ximv_out_tr.item_no                           AS item_no                -- 品目コード
         ,ximv_out_tr.item_name                         AS item_name              -- 品目名
         ,ximv_out_tr.item_short_name                   AS item_short_name        -- 品目略称
         ,ximv_out_tr.num_of_cases                      AS case_content           -- ケース入数
         ,ximv_out_tr.lot_ctl                           AS lot_ctl                -- ロット管理区分
         ,ilm_out_tr.lot_id                             AS lot_id                 -- ロットID
         ,ilm_out_tr.lot_no                             AS lot_no                 -- ロットNo
         ,ilm_out_tr.attribute1                         AS manufacture_date       -- 製造年月日
         ,ilm_out_tr.attribute2                         AS uniqe_sign             -- 固有記号
         ,ilm_out_tr.attribute3                         AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_out_tr.mov_num                          AS voucher_no             -- 伝票番号
         ,xmril_out_tr.line_number                      AS line_no                -- 行番号
         ,xmrih_out_tr.delivery_no                      AS delivery_no            -- 配送番号
         ,xmrih_out_tr.instruction_post_code            AS loct_code              -- 部署コード
         ,xlc_out_tr.location_name                      AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xmrih_out_tr.schedule_ship_date               AS leaving_date           -- 入出庫日_発日
         ,xmrih_out_tr.schedule_arrival_date            AS arrival_date           -- 入出庫日_着日
         ,xmrih_out_tr.schedule_ship_date               AS standard_date          -- 基準日（発日）
         ,xilv_out_tr2.segment1                         AS ukebaraisaki_code      -- 受払先コード
         ,xilv_out_tr2.description                      AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_out_tr2.segment1                         AS deliver_to_no          -- 配送先コード
         ,xilv_out_tr2.description                      AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,CASE WHEN xmld_out_tr.mov_lot_dtl_id IS NULL THEN xmril_out_tr.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                         xmld_out_tr.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_out_tr.mov_lot_dtl_id IS NULL THEN xmril_out_tr.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                         xmld_out_tr.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_tr               -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_tr               -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_tr                -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_tr               -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_tr              -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_tr              -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_tr               -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_out_tr2              -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_tr                -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_tr.doc_type                          = 'TRNI'                  -- 移動積送なし
     AND  xrpm_out_tr.use_div_invent                    = 'Y'
     AND  xrpm_out_tr.rcv_pay_div                       = '-1'                    -- 払出
     --移動依頼/指示ヘッダの条件
     AND  xmrih_out_tr.comp_actual_flg                  = 'N'                     -- 実績未計上
     AND  xmrih_out_tr.status                           IN ( '02'                 -- 依頼済
                                                            ,'03' )               -- 調整中
     AND  xmrih_out_tr.mov_type                         = '2'
     --移動依頼/指示明細との結合
     AND  xmril_out_tr.delete_flg                       = 'N'                     -- OFF
     AND  xmrih_out_tr.mov_hdr_id                       = xmril_out_tr.mov_hdr_id
     --移動ロット詳細取得
     AND  xmld_out_tr.document_type_code                = '20'                    -- 移動
     AND  xmld_out_tr.record_type_code                  = '10'                    -- 指示
     AND  xmril_out_tr.mov_line_id                      = xmld_out_tr.mov_line_id
     --品目マスタとの結合
     AND  xmril_out_tr.item_id                          = ximv_out_tr.item_id
     AND  xmrih_out_tr.schedule_ship_date              >= ximv_out_tr.start_date_active --適用開始日
     AND  xmrih_out_tr.schedule_ship_date              <= ximv_out_tr.end_date_active   --適用終了日
     --ロット情報取得
     AND  xmld_out_tr.item_id                           = ilm_out_tr.item_id
     AND  xmld_out_tr.lot_id                            = ilm_out_tr.lot_id
     --保管場所情報取得
     AND  xmrih_out_tr.shipped_locat_id                 = xilv_out_tr.inventory_location_id
     --受払先情報取得
     AND  xmrih_out_tr.ship_to_locat_id                 = xilv_out_tr2.inventory_location_id
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_out_tr.instruction_post_code            = xlc_out_tr.location_code(+)
--     AND  xmrih_out_tr.schedule_ship_date              >= xlc_out_tr.start_date_active(+)
--     AND  xmrih_out_tr.schedule_ship_date              <= xlc_out_tr.end_date_active(+)
     AND  xmrih_out_tr.instruction_post_code            = xlc_out_tr.location_code
     AND  xmrih_out_tr.schedule_ship_date              = xlc_out_tr.start_date_active
     AND  xmrih_out_tr.schedule_ship_date              = xlc_out_tr.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ２．移動出庫予定(指示 積送なし)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ３．移動出庫予定(入庫報告有 積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf20.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_xf20.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_xf20.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_xf20.description                     AS location               -- 保管場所名
         ,xilv_out_xf20.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_xf20.item_id                         AS item_id                -- 品目ID
         ,ximv_out_xf20.item_no                         AS item_no                -- 品目コード
         ,ximv_out_xf20.item_name                       AS item_name              -- 品目名
         ,ximv_out_xf20.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_xf20.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_xf20.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_xf20.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_xf20.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_xf20.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_xf20.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_xf20.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_out_xf20.mov_num                        AS voucher_no             -- 伝票番号
         ,xmril_out_xf20.line_number                    AS line_no                -- 行番号
         ,xmrih_out_xf20.delivery_no                    AS delivery_no            -- 配送番号
         ,xmrih_out_xf20.instruction_post_code          AS loct_code              -- 部署コード
         ,xlc_out_xf20.location_name                    AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xmrih_out_xf20.schedule_ship_date             AS leaving_date           -- 入出庫日_発日
         ,xmrih_out_xf20.schedule_arrival_date          AS arrival_date           -- 入出庫日_着日
         ,xmrih_out_xf20.schedule_ship_date             AS standard_date          -- 基準日（発日）
         ,xilv_out_xf202.segment1                       AS ukebaraisaki_code      -- 受払先コード
         ,xilv_out_xf202.description                    AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分
         ,xilv_out_xf202.segment1                       AS deliver_to_no          -- 配送先コード
         ,xilv_out_xf202.description                    AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,CASE WHEN xmld_out_xf20.mov_lot_dtl_id IS NULL THEN xmril_out_xf20.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                           xmld_out_xf20.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS leaving_quantity       -- 出庫数
         ,CASE WHEN xmld_out_xf20.mov_lot_dtl_id IS NULL THEN xmril_out_xf20.instruct_qty     -- ロット割当無しなら品目単位の数量
               ELSE                                           xmld_out_xf20.actual_quantity   -- ロット割当有りならロット単位の数量
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_xf20             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf20             -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_xf20              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf20             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf20            -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf20            -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf20             -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_out_xf202            -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_xf20              -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_xf20.doc_type                        = 'XFER'                  -- 移動積送あり
     AND  xrpm_out_xf20.use_div_invent                  = 'Y'
     AND  xrpm_out_xf20.rcv_pay_div                     = '-1'                    -- 払出
     --移動依頼/指示ヘッダの条件
     AND  xmrih_out_xf20.comp_actual_flg                = 'N'                     -- 実績未計上
     AND  xmrih_out_xf20.status                         = '05'                    -- 入庫報告有
     AND  xmrih_out_xf20.mov_type                       = '1'                     -- 積送あり
     --移動依頼/指示明細との結合
     AND  xmril_out_xf20.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_xf20.mov_hdr_id                     = xmril_out_xf20.mov_hdr_id
     --移動ロット詳細取得
     AND  xmld_out_xf20.document_type_code              = '20'                    -- 移動
     AND  xmld_out_xf20.record_type_code                = '30'                    -- 入庫実績
     AND  xmril_out_xf20.mov_line_id                    = xmld_out_xf20.mov_line_id
     --品目マスタとの結合
     AND  xmril_out_xf20.item_id                        = ximv_out_xf20.item_id
     AND  xmrih_out_xf20.schedule_ship_date            >= ximv_out_xf20.start_date_active --適用開始日
     AND  xmrih_out_xf20.schedule_ship_date            <= ximv_out_xf20.end_date_active   --適用終了日
     --ロット情報取得
     AND  xmld_out_xf20.item_id                         = ilm_out_xf20.item_id
     AND  xmld_out_xf20.lot_id                          = ilm_out_xf20.lot_id
     --保管場所情報取得
     AND  xmrih_out_xf20.shipped_locat_id               = xilv_out_xf20.inventory_location_id
     --受払先情報取得
     AND  xmrih_out_xf20.ship_to_locat_id               = xilv_out_xf202.inventory_location_id
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_out_xf20.instruction_post_code          = xlc_out_xf20.location_code(+)
--     AND  xmrih_out_xf20.schedule_ship_date            >= xlc_out_xf20.start_date_active(+)
--     AND  xmrih_out_xf20.schedule_ship_date            <= xlc_out_xf20.end_date_active(+)
     AND  xmrih_out_xf20.instruction_post_code          = xlc_out_xf20.location_code
     AND  xmrih_out_xf20.schedule_ship_date            >= xlc_out_xf20.start_date_active
     AND  xmrih_out_xf20.schedule_ship_date            <= xlc_out_xf20.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ３．移動出庫予定(入庫報告有 積送あり)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ４．受注出荷予定
  -------------------------------------------------------------
  SELECT
          xrpm_out_om.new_div_invent                    AS reason_code            -- 事由コード
         ,xilv_out_om.whse_code                         AS whse_code              -- 倉庫コード
         ,xilv_out_om.segment1                          AS location_code          -- 保管場所コード
         ,xilv_out_om.description                       AS location               -- 保管場所名
         ,xilv_out_om.short_name                        AS location_s_name        -- 保管場所略称
         ,ximv_out_om_s.item_id                         AS item_id                -- 品目ID
         ,ximv_out_om_s.item_no                         AS item_no                -- 品目コード
         ,ximv_out_om_s.item_name                       AS item_name              -- 品目名
         ,ximv_out_om_s.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_om_s.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_om_s.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_om.lot_id                             AS lot_id                 -- ロットID
         ,ilm_out_om.lot_no                             AS lot_no                 -- ロットNo
         ,ilm_out_om.attribute1                         AS manufacture_date       -- 製造年月日
         ,ilm_out_om.attribute2                         AS uniqe_sign             -- 固有記号
         ,ilm_out_om.attribute3                         AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xoha_out_om.request_no                        AS voucher_no             -- 伝票番号
         ,xola_out_om.order_line_number                 AS line_no                -- 行番号
         ,xoha_out_om.delivery_no                       AS delivery_no            -- 配送番号
         ,xoha_out_om.performance_management_dept       AS loct_code              -- 部署コード
         ,xlc_out_om.location_name                      AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xoha_out_om.schedule_ship_date                AS leaving_date           -- 入出庫日_発日
         ,xoha_out_om.schedule_arrival_date             AS arrival_date           -- 入出庫日_着日
         ,xoha_out_om.schedule_ship_date                AS standard_date          -- 基準日（発日）
         ,CASE WHEN xcst_out_om.customer_class_code = '10' THEN xoha_out_om.head_sales_branch  --顧客コードが顧客であれば管轄拠点を表示
               ELSE                                             xoha_out_om.customer_code      --顧客コードが拠点であればその拠点を表示
          END                                           AS ukebaraisaki_code      -- 受払先コード
         ,CASE WHEN xcst_out_om.customer_class_code = '10' THEN xcst_out_om_h.party_name       --顧客コードが顧客であれば管轄拠点名を表示
               ELSE                                             xcst_out_om.party_name         --顧客コードが拠点であればその拠点名を表示
          END                                           AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分
         ,xpas_out_om.party_site_number                 AS deliver_to_no          -- 配送先コード
         ,xpas_out_om.party_site_name                   AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,xmld_out_om.actual_quantity                   AS leaving_quantity       -- 出庫数
         ,xmld_out_om.actual_quantity                   AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_om               -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_om_s             -- OPM品目情報VIEW(出荷品目)
         ,ic_lots_mst                                   ilm_out_om                -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_om               -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_out_om               -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_out_om               -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_om               -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_out_om               -- 受注タイプ
         ,xxskz_item_mst2_v                             ximv_out_om_r             -- OPM品目情報VIEW(依頼品目)
         ,xxskz_cust_accounts2_v                        xcst_out_om               -- 受払先(拠点)取得用
         ,xxskz_cust_accounts2_v                        xcst_out_om_h             -- 受払先(管轄拠点)取得用
         ,xxskz_party_sites2_v                          xpas_out_om               -- 配送先名取得用
         ,xxskz_locations2_v                            xlc_out_om                -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_om.doc_type                          = 'OMSO'
     AND  xrpm_out_om.use_div_invent                    = 'Y'
     AND  xrpm_out_om.shipment_provision_div            = '1'                     -- 出荷依頼
     --受注タイプの条件（含む：受払区分アドオンマスタの絞込み条件）
     AND  otta_out_om.attribute1                        = '1'                     -- 出荷依頼
     AND  (   xrpm_out_om.ship_prov_rcv_pay_category    IS NULL
           OR xrpm_out_om.ship_prov_rcv_pay_category    = otta_out_om.attribute11
          )
     --受注ヘッダの条件
     AND  xoha_out_om.req_status                        = '03'                    -- 締め済
     AND  NVL( xoha_out_om.actual_confirm_class, 'N' )  = 'N'                     -- 実績未計上
     AND  xoha_out_om.latest_external_flag              = 'Y'                     -- ON
     AND  otta_out_om.transaction_type_id               = xoha_out_om.order_type_id
     --受注明細との結合
     AND  NVL( xola_out_om.delete_flag, 'N' )           = 'N'                     -- 無効明細以外
     AND  xoha_out_om.order_header_id                   = xola_out_om.order_header_id
     --移動ロット詳細取得
     AND  xmld_out_om.document_type_code                = '10'                    -- 出荷依頼
     AND  xmld_out_om.record_type_code                  = '10'                    -- 指示
     AND  xola_out_om.order_line_id                     = xmld_out_om.mov_line_id
     --品目マスタ(出荷品目)との結合
     AND  xola_out_om.shipping_inventory_item_id        = ximv_out_om_s.inventory_item_id
     AND  xoha_out_om.schedule_ship_date               >= ximv_out_om_s.start_date_active --適用開始日
     AND  xoha_out_om.schedule_ship_date               <= ximv_out_om_s.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om.item_div_origin, 'Dummy' )   = DECODE( ximv_out_om_s.item_class_code,'5','5','Dummy' ) --振替元品目区分 = 出荷品目区分
     --品目マスタ(依頼品目)との結合
     AND  xola_out_om.request_item_id                   = ximv_out_om_r.inventory_item_id
     AND  xoha_out_om.schedule_ship_date               >= ximv_out_om_r.start_date_active --適用開始日
     AND  xoha_out_om.schedule_ship_date               <= ximv_out_om_r.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om.item_div_ahead , 'Dummy' )   = DECODE( ximv_out_om_r.item_class_code,'5','5','Dummy' ) --振替先品目区分 = 依頼品目区分
     --ロット情報取得（ロット割当てされていないデータも出力対照とする為に外部結合を行う）
     AND  xmld_out_om.item_id                           = ilm_out_om.item_id
     AND  xmld_out_om.lot_id                            = ilm_out_om.lot_id
     --保管場所情報取得
     AND  xoha_out_om.deliver_from_id                   = xilv_out_om.inventory_location_id
     --受払先情報取得（拠点）
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--     AND  xoha_out_om.customer_id                       = xcst_out_om.party_id
     AND  xpas_out_om.party_id                          = xcst_out_om.party_id
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
     AND  xoha_out_om.schedule_ship_date               >= xcst_out_om.start_date_active --適用開始日
     AND  xoha_out_om.schedule_ship_date               <= xcst_out_om.end_date_active   --適用終了日
     --受払先情報取得（管轄拠点）
     AND  xoha_out_om.head_sales_branch                 = xcst_out_om_h.party_number(+)
     AND  xoha_out_om.schedule_ship_date               >= xcst_out_om_h.start_date_active(+) --適用開始日
     AND  xoha_out_om.schedule_ship_date               <= xcst_out_om_h.end_date_active(+)   --適用終了日
     --配送先取得
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--     AND  xoha_out_om.deliver_to_id                     = xpas_out_om.party_site_id
     AND  xoha_out_om.deliver_to                        = xpas_out_om.party_site_number
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
     AND  xoha_out_om.schedule_ship_date               >= xpas_out_om.start_date_active --適用開始日
     AND  xoha_out_om.schedule_ship_date               <= xpas_out_om.end_date_active   --適用終了日
     --部署名取得
     AND  xoha_out_om.performance_management_dept       = xlc_out_om.location_code(+)
     AND  xoha_out_om.schedule_ship_date               >= xlc_out_om.start_date_active(+)
     AND  xoha_out_om.schedule_ship_date               <= xlc_out_om.end_date_active(+)
  -- [ ４．受注出荷予定  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ５．有償出荷予定
  -------------------------------------------------------------
  SELECT
          xrpm_out_om2.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_out_om2.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_out_om2.segment1                         AS location_code          -- 保管場所コード
         ,xilv_out_om2.description                      AS location               -- 保管場所名
         ,xilv_out_om2.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_out_om2_s.item_id                        AS item_id                -- 品目ID
         ,ximv_out_om2_s.item_no                        AS item_no                -- 品目コード
         ,ximv_out_om2_s.item_name                      AS item_name              -- 品目名
         ,ximv_out_om2_s.item_short_name                AS item_short_name        -- 品目略称
         ,ximv_out_om2_s.num_of_cases                   AS case_content           -- ケース入数
         ,ximv_out_om2_s.lot_ctl                        AS lot_ctl                -- ロット管理区分
         ,ilm_out_om2.lot_id                            AS lot_id                 -- ロットID
         ,ilm_out_om2.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_out_om2.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_out_om2.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_out_om2.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xoha_out_om2.request_no                       AS voucher_no             -- 伝票番号
         ,xola_out_om2.order_line_number                AS line_no                -- 行番号
         ,xoha_out_om2.delivery_no                      AS delivery_no            -- 配送番号
         ,xoha_out_om2.performance_management_dept      AS loct_code              -- 部署コード
         ,xlc_out_om2.location_name                     AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xoha_out_om2.schedule_ship_date               AS leaving_date           -- 入出庫日_発日
         ,xoha_out_om2.schedule_arrival_date            AS arrival_date           -- 入出庫日_着日
         ,xoha_out_om2.schedule_ship_date               AS standard_date          -- 基準日（発日）
         ,xoha_out_om2.vendor_site_code                 AS ukebaraisaki_code      -- 受払先コード
         ,xvsv_out_om2.vendor_site_name                 AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,CASE WHEN otta_out_om2.order_category_code = 'RETURN' THEN xmld_out_om2.actual_quantity * -1
               ELSE                                                  xmld_out_om2.actual_quantity
          END                                           AS leaving_quantity       -- 出庫数
         ,CASE WHEN otta_out_om2.order_category_code = 'RETURN' THEN xmld_out_om2.actual_quantity * -1
               ELSE                                                  xmld_out_om2.actual_quantity
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_om2              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_om2_s            -- OPM品目情報VIEW(出荷品目)
         ,ic_lots_mst                                   ilm_out_om2               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_om2              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_out_om2              -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_out_om2              -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_om2              -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_out_om2              -- 受注タイプ
         ,xxskz_item_mst2_v                             ximv_out_om2_r            -- OPM品目情報VIEW(依頼品目)
         ,xxskz_vendor_sites_v                          xvsv_out_om2              -- 仕入先サイト情報VIEW(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_om2               -- 部署名取得用
  WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_om2.doc_type                         = 'OMSO'
     AND  xrpm_out_om2.use_div_invent                   = 'Y'
     AND  xrpm_out_om2.shipment_provision_div           = '2'       -- 支給依頼
     --受注タイプの条件（含む：受払区分アドオンマスタの絞込み条件）
     AND  otta_out_om2.attribute1                       = '2'       -- 支給依頼
     AND (   xrpm_out_om2.ship_prov_rcv_pay_category    IS NULL
          OR xrpm_out_om2.ship_prov_rcv_pay_category    = otta_out_om2.attribute11
         )
     --受注ヘッダの条件
     AND  xoha_out_om2.req_status                       = '07'      -- 受領済
     AND  NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- 実績未計上
     AND  xoha_out_om2.latest_external_flag             = 'Y'       -- ON
     AND  otta_out_om2.transaction_type_id              = xoha_out_om2.order_type_id
     --受注明細との結合
     AND  xola_out_om2.delete_flag                      = 'N'       -- OFF
     AND  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
     --移動ロット詳細取得
     AND  xmld_out_om2.document_type_code               = '30'      -- 支給指示
     AND  xmld_out_om2.record_type_code                 = '10'      -- 指示
     AND  xola_out_om2.order_line_id                    = xmld_out_om2.mov_line_id
     --品目マスタ(出荷品目)との結合
     AND  xola_out_om2.shipping_inventory_item_id       = ximv_out_om2_s.inventory_item_id
     AND  xoha_out_om2.schedule_ship_date              >= ximv_out_om2_s.start_date_active --適用開始日
     AND  xoha_out_om2.schedule_ship_date              <= ximv_out_om2_s.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om2.item_div_origin,'Dummy' )   = DECODE( ximv_out_om2_s.item_class_code,'5','5','Dummy' ) --振替元品目区分 = 出荷品目区分
     --品目マスタ(依頼品目)との結合
     AND  xola_out_om2.request_item_id                  = ximv_out_om2_r.inventory_item_id
     AND  xoha_out_om2.schedule_ship_date              >= ximv_out_om2_r.start_date_active --適用開始日
     AND  xoha_out_om2.schedule_ship_date              <= ximv_out_om2_r.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om2.item_div_ahead ,'Dummy' )   = DECODE( ximv_out_om2_r.item_class_code,'5','5','Dummy' ) --振替先品目区分 = 依頼品目区分
     --品目カテゴリ割当情報(出荷品目・依頼品目)結合条件
     AND  (  (     xola_out_om2.shipping_inventory_item_id = xola_out_om2.request_item_id               -- 品目振替ではない
               AND xrpm_out_om2.prod_div_origin            IS NULL
               AND xrpm_out_om2.prod_div_ahead             IS NULL
              )
           OR (    xola_out_om2.shipping_inventory_item_id <> xola_out_om2.request_item_id              -- 品目振替
               AND ximv_out_om2_s.item_class_code          = '5'                                        -- 製品
               AND ximv_out_om2_r.item_class_code          = '5'                                        -- 製品
               AND xrpm_out_om2.prod_div_origin            IS NOT NULL
               AND xrpm_out_om2.prod_div_ahead             IS NOT NULL
              )
           OR (    xola_out_om2.shipping_inventory_item_id <> xola_out_om2.request_item_id              -- 品目振替
               AND ( ximv_out_om2_s.item_class_code <> '5' OR ximv_out_om2_r.item_class_code <> '5' )   -- 製品ではない
               AND xrpm_out_om2.prod_div_origin            IS NULL
               AND xrpm_out_om2.prod_div_ahead             IS NULL
              )
          )
     --ロット情報取得
     AND  xmld_out_om2.item_id                          = ilm_out_om2.item_id
     AND  xmld_out_om2.lot_id                           = ilm_out_om2.lot_id
     --保管場所情報取得
     AND  xoha_out_om2.deliver_from_id                  = xilv_out_om2.inventory_location_id
     --受払先情報（仕入先サイト情報）取得
     AND  xoha_out_om2.vendor_site_id                   = xvsv_out_om2.vendor_site_id
     AND  xoha_out_om2.schedule_ship_date              >= xvsv_out_om2.start_date_active --適用開始日
     AND  xoha_out_om2.schedule_ship_date              <= xvsv_out_om2.end_date_active   --適用終了日
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xoha_out_om2.performance_management_dept      = xlc_out_om2.location_code(+)
--     AND  xoha_out_om2.schedule_ship_date              >= xlc_out_om2.start_date_active(+)
--     AND  xoha_out_om2.schedule_ship_date              <= xlc_out_om2.end_date_active(+)
     AND  xoha_out_om2.performance_management_dept      = xlc_out_om2.location_code
     AND  xoha_out_om2.schedule_ship_date              >= xlc_out_om2.start_date_active
     AND  xoha_out_om2.schedule_ship_date              <= xlc_out_om2.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ５．有償出荷予定  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ６．生産原料投入予定
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr.new_div_invent                    AS reason_code            -- 事由コード
         ,xilv_out_pr.whse_code                         AS whse_code              -- 倉庫コード
         ,xilv_out_pr.segment1                          AS location_code          -- 保管場所コード
         ,xilv_out_pr.description                       AS location               -- 保管場所名
         ,xilv_out_pr.short_name                        AS location_s_name        -- 保管場所略称
         ,ximv_out_pr.item_id                           AS item_id                -- 品目ID
         ,ximv_out_pr.item_no                           AS item_no                -- 品目コード
         ,ximv_out_pr.item_name                         AS item_name              -- 品目名
         ,ximv_out_pr.item_short_name                   AS item_short_name        -- 品目略称
         ,ximv_out_pr.num_of_cases                      AS case_content           -- ケース入数
         ,ximv_out_pr.lot_ctl                           AS lot_ctl                -- ロット管理区分
         ,ilm_out_pr.lot_id                             AS lot_id                 -- ロットID
         ,ilm_out_pr.lot_no                             AS lot_no                 -- ロットNo
         ,ilm_out_pr.attribute1                         AS manufacture_date       -- 製造年月日
         ,ilm_out_pr.attribute2                         AS uniqe_sign             -- 固有記号
         ,ilm_out_pr.attribute3                         AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_out_pr.batch_no                           AS voucher_no             -- 伝票番号
         ,gmd_out_pr.line_no                            AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_out_pr.attribute2                         AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,gbh_out_pr.plan_start_date                    AS leaving_date           -- 入出庫日_発日
         ,gbh_out_pr.plan_start_date                    AS arrival_date           -- 入出庫日_着日
         ,gbh_out_pr.plan_start_date                    AS standard_date          -- 基準日（発日）
         ,grb_out_pr.routing_no                         AS ukebaraisaki_code      -- 受払先コード
         ,grt_out_pr.routing_desc                       AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,itp_out_pr.trans_qty * -1                     AS leaving_quantity       -- 出庫数
         ,itp_out_pr.trans_qty * -1                     AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_pr               -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr               -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_pr                -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr               -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr                -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_out_pr                -- 生産原料詳細（標準）バックアップ
         ,gmd_routings_b                                grb_out_pr                -- 工順マスタ
         ,gmd_routings_tl                               grt_out_pr                -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr                -- OPM保留在庫トランザクション（標準）バックアップ
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_pr.doc_type                          = 'PROD'
     AND  xrpm_out_pr.use_div_invent                    = 'Y'
     -- 工順マスタとの結合（生産データ取得の条件）
     AND  grb_out_pr.routing_class                      NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
     AND  gbh_out_pr.routing_id                         = grb_out_pr.routing_id
     AND  xrpm_out_pr.routing_class                     = grb_out_pr.routing_class
     -- 生産バッチヘッダの条件
     AND  gbh_out_pr.batch_status                       IN ( '1', '2' )           -- 1:保留、2:WIP
     --生産原料詳細の結合
     AND  gmd_out_pr.line_type                          = -1                      -- -1:原料
     AND  gbh_out_pr.batch_id                           = gmd_out_pr.batch_id
     AND  gmd_out_pr.line_type                          = xrpm_out_pr.line_type
     AND (   ( ( gmd_out_pr.attribute5 IS NULL     ) AND ( xrpm_out_pr.hit_in_div IS NULL ) )
          OR ( ( gmd_out_pr.attribute5 IS NOT NULL ) AND ( xrpm_out_pr.hit_in_div = gmd_out_pr.attribute5 ) )
         )
     --保留在庫トランザクションの取得
     AND  itp_out_pr.delete_mark                        = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_out_pr.completed_ind                      = 0                       -- 完了していない(⇒予定)
     AND  itp_out_pr.reverse_id                         IS NULL
     AND  itp_out_pr.doc_type                           = xrpm_out_pr.doc_type
     AND  itp_out_pr.line_id                            = gmd_out_pr.material_detail_id
     AND  itp_out_pr.location                           = grb_out_pr.attribute9
     AND  itp_out_pr.item_id                            = gmd_out_pr.item_id
     --品目マスタとの結合
     AND  itp_out_pr.item_id                            = ximv_out_pr.item_id
     AND  itp_out_pr.trans_date                        >= ximv_out_pr.start_date_active --適用開始日
     AND  itp_out_pr.trans_date                        <= ximv_out_pr.end_date_active   --適用終了日
     --ロット情報取得
     AND  itp_out_pr.item_id                            = ilm_out_pr.item_id
     AND  itp_out_pr.lot_id                             = ilm_out_pr.lot_id
     --保管場所情報取得
     AND  grb_out_pr.attribute9                         = xilv_out_pr.segment1
     --工順マスタ日本語取得
     AND  grt_out_pr.language                           = 'JA'
     AND  grb_out_pr.routing_id                         = grt_out_pr.routing_id
  -- [ ６．生産原料投入予定  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ７．生産出庫予定 品目振替 品種振替
  -- 【注】以下のSQLは変更次第で処理速度が遅くなります
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr70.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_pr70.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_pr70.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_pr70.description                     AS location               -- 保管場所名
         ,xilv_out_pr70.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_pr70.item_id                         AS item_id                -- 品目ID
         ,ximv_out_pr70.item_no                         AS item_no                -- 品目コード
         ,ximv_out_pr70.item_name                       AS item_name              -- 品目名
         ,ximv_out_pr70.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_pr70.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_pr70.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_pr70.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_pr70.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_pr70.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_pr70.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_pr70.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_out_pr70.batch_no                         AS voucher_no             -- 伝票番号
         ,gmd_out_pr70a.line_no                         AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_out_pr70.attribute2                       AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,itp_out_pr70.trans_date                       AS leaving_date           -- 入出庫日_発日
         ,itp_out_pr70.trans_date                       AS arrival_date           -- 入出庫日_着日
         ,itp_out_pr70.trans_date                       AS standard_date          -- 基準日（発日）
         ,grb_out_pr70.routing_no                       AS ukebaraisaki_code      -- 受払先コード
         ,grt_out_pr70.routing_desc                     AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,gmd_out_pr70a.plan_qty                        AS leaving_quantity       -- 出庫数
         ,gmd_out_pr70a.plan_qty                        AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_pr70             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr70             -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_pr70              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr70             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr70              -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_out_pr70a             -- 生産原料詳細（標準）バックアップ(振替元)
         ,xxcmn_gme_material_details_arc                gmd_out_pr70b             -- 生産原料詳細（標準）バックアップ(振替先)
         ,gmd_routings_b                                grb_out_pr70              -- 工順マスタ
         ,gmd_routings_tl                               grt_out_pr70              -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr70              -- OPM保留在庫トランザクション（標準）バックアップ
         ,xxskz_item_class_v                            xicv_out_pr70b            -- OPM品目カテゴリ割当情報VIEW5(振替先)
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_pr70.doc_type                        = 'PROD'
     AND  xrpm_out_pr70.use_div_invent                  = 'Y'
     -- 工順マスタとの結合（品目振替データ取得の条件）
     AND  grb_out_pr70.routing_class                    = '70'                    -- 品目振替
     AND  gbh_out_pr70.routing_id                       = grb_out_pr70.routing_id
     AND  xrpm_out_pr70.routing_class                   = grb_out_pr70.routing_class
     --生産バッチ・生産原料詳細(振替元)の結合条件
     AND  gmd_out_pr70a.line_type                       = -1                      -- 振替元
     AND  gbh_out_pr70.batch_id                         = gmd_out_pr70a.batch_id
     AND  xrpm_out_pr70.line_type                       = gmd_out_pr70a.line_type
     --生産バッチ・生産原料詳細(振替先)の結合条件
     AND  gmd_out_pr70b.line_type                       = 1                       -- 振替先
     AND  gbh_out_pr70.batch_id                         = gmd_out_pr70b.batch_id
     AND  gmd_out_pr70a.batch_id                        = gmd_out_pr70b.batch_id  -- ←処理速度UPに有効
     --保留在庫トランザクションの取得
     AND  itp_out_pr70.delete_mark                      = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_out_pr70.completed_ind                    = 0                       -- 完了していない(⇒予定)
     AND  itp_out_pr70.reverse_id                       IS NULL
     AND  itp_out_pr70.lot_id                          <> 0
     AND  itp_out_pr70.doc_type                         = xrpm_out_pr70.doc_type
     AND  itp_out_pr70.doc_id                           = gmd_out_pr70a.batch_id  -- ←処理速度UPに有効
     AND  itp_out_pr70.doc_line                         = gmd_out_pr70a.line_no   -- ←処理速度UPに有効
     AND  itp_out_pr70.line_type                        = gmd_out_pr70a.line_type -- ←処理速度UPに有効
     AND  itp_out_pr70.line_id                          = gmd_out_pr70a.material_detail_id
     AND  itp_out_pr70.item_id                          = ximv_out_pr70.item_id
     --品目マスタとの結合
     AND  gmd_out_pr70a.item_id                         = ximv_out_pr70.item_id
     AND  itp_out_pr70.trans_date                      >= ximv_out_pr70.start_date_active --適用開始日
     AND  itp_out_pr70.trans_date                      <= ximv_out_pr70.end_date_active   --適用終了日
     -- OPM品目カテゴリ割当情報VIEW5(振替先、振替元)
     AND  gmd_out_pr70b.item_id                         = xicv_out_pr70b.item_id
     AND (    xrpm_out_pr70.item_div_origin             = ximv_out_pr70.item_class_code   -- 振替元
          AND xrpm_out_pr70.item_div_ahead              = xicv_out_pr70b.item_class_code  -- 振替先
          AND (   ( ximv_out_pr70.item_class_code      <> xicv_out_pr70b.item_class_code )
               OR ( ximv_out_pr70.item_class_code       = xicv_out_pr70b.item_class_code )
              )
         )
     --ロット情報取得
     AND  ximv_out_pr70.item_id                         = ilm_out_pr70.item_id
     AND  itp_out_pr70.lot_id                           = ilm_out_pr70.lot_id
     -- OPM保管場所情報取得
     AND  itp_out_pr70.whse_code                        = xilv_out_pr70.whse_code
     AND  itp_out_pr70.location                         = xilv_out_pr70.segment1
     --工順マスタ日本語取得
     AND  grt_out_pr70.language                         = 'JA'
     AND  grb_out_pr70.routing_id                       = grt_out_pr70.routing_id
  -- [ ７．生産出庫予定 品目振替 品種振替  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ８．相手先在庫出庫予定
  -------------------------------------------------------------
  SELECT
          xrpm_out_ad.new_div_invent                    AS reason_code            -- 事由コード
         ,xilv_out_ad.whse_code                         AS whse_code              -- 倉庫コード
         ,xilv_out_ad.segment1                          AS location_code          -- 保管場所コード
         ,xilv_out_ad.description                       AS location               -- 保管場所名
         ,xilv_out_ad.short_name                        AS location_s_name        -- 保管場所略称
         ,ximv_out_ad.item_id                           AS item_id                -- 品目ID
         ,ximv_out_ad.item_no                           AS item_no                -- 品目コード
         ,ximv_out_ad.item_name                         AS item_name              -- 品目名
         ,ximv_out_ad.item_short_name                   AS item_short_name        -- 品目略称
         ,ximv_out_ad.num_of_cases                      AS case_content           -- ケース入数
         ,ximv_out_ad.lot_ctl                           AS lot_ctl                -- ロット管理区分
         ,ilm_out_ad.lot_id                             AS lot_id                 -- ロットID
         ,ilm_out_ad.lot_no                             AS lot_no                 -- ロットNo
         ,ilm_out_ad.attribute1                         AS manufacture_date       -- 製造年月日
         ,ilm_out_ad.attribute2                         AS uniqe_sign             -- 固有記号
         ,ilm_out_ad.attribute3                         AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,pha_out_ad.segment1                           AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,pha_out_ad.attribute10                        AS loct_code              -- 部署コード
         ,xlc_out_ad.location_name                      AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS leaving_date        -- 入出庫日_発日
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS arrival_date        -- 入出庫日_着日
         ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' )   AS standard_date       -- 基準日（発日）
         ,xvv_out_ad.segment1                           AS ukebaraisaki_code      -- 受払先コード
         ,xvv_out_ad.vendor_name                        AS ukebaraisaki_name      -- 受払先名
         ,'1'                                           AS status                 -- 予定実績区分（1:予定）
         ,xilv_out_ad.segment1                          AS deliver_to_no          -- 配送先コード
         ,xilv_out_ad.description                       AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,pla_out_ad.quantity                           AS leaving_quantity       -- 出庫数
         ,pla_out_ad.quantity                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_ad               -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad               -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_ad                -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_ad               -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,po_headers_all                                pha_out_ad                -- 発注ヘッダ
         ,po_lines_all                                  pla_out_ad                -- 発注明細
         ,xxinv_mov_lot_details                         xmld_out_ad               -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_vendors_v                               xvv_out_ad                -- 仕入先情報VIEW(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_ad                -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_ad.doc_type                          = 'ADJI'
     AND  xrpm_out_ad.reason_code                       = 'X977'                  -- 相手先在庫
     AND  xrpm_out_ad.rcv_pay_div                       = '-1'                    -- 払出
     AND  xrpm_out_ad.use_div_invent                    = 'Y'
     --発注ヘッダの条件
     AND  pha_out_ad.attribute11                        = '3'
     AND  pha_out_ad.attribute1                         IN ( '20'                 -- 発注作成済
                                                            ,'25' )               -- 受入あり
     --発注明細の結合
     AND  NVL( pla_out_ad.attribute13, 'N' )            <> 'Y'    --未承諾
     AND  NVL( pla_out_ad.cancel_flag, 'N' )            <> 'Y'
     AND  pha_out_ad.po_header_id                       = pla_out_ad.po_header_id
     --品目マスタとの結合
     AND  pla_out_ad.item_id                            = ximv_out_ad.inventory_item_id
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= ximv_out_ad.start_date_active --適用開始日
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= ximv_out_ad.end_date_active   --適用終了日
     --移動ロット詳細取得
     AND  xmld_out_ad.document_type_code                = '50'                    -- '発注'
     AND  xmld_out_ad.record_type_code                  = '10'                    -- '指示'
     AND  pla_out_ad.po_line_id                         = xmld_out_ad.mov_line_id
     --ロット情報取得
     AND  ximv_out_ad.item_id                           = ilm_out_ad.item_id
     AND  xmld_out_ad.lot_id                            = ilm_out_ad.lot_id
     --保管場所情報の取得
     AND  pla_out_ad.attribute12                        = xilv_out_ad.segment1
     --仕入先情報の取得
     AND  pha_out_ad.vendor_id                          = xvv_out_ad.vendor_id    -- 仕入先情報VIEW
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xvv_out_ad.start_date_active --適用開始日
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xvv_out_ad.end_date_active   --適用終了日
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  pha_out_ad.attribute10                        = xlc_out_ad.location_code(+)
--     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xlc_out_ad.start_date_active(+)
--     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xlc_out_ad.end_date_active(+)
     AND  pha_out_ad.attribute10                        = xlc_out_ad.location_code
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) >= xlc_out_ad.start_date_active
     AND  TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) <= xlc_out_ad.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ８．相手先在庫出庫予定  END ] --
-- << 出庫予定 END >>
UNION ALL
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--■ 【入庫実績】                                                     ■
--■    １．発注受入実績                                              ■
--■    ２．移動入庫実績(積送あり)                                    ■
--■    ３．移動入庫実績(積送なし)                                    ■
--■    ４．生産入庫実績                                              ■
--■    ５．生産入庫実績 品目振替 品種振替                            ■
--■    ６．生産入庫実績 解体                                         ■
--■    ７．倉替返品 入庫実績                                         ■
--■    ８．在庫調整 入庫実績(相手先在庫)                             ■
--■    ９．在庫調整 入庫実績(外注出来高)                             ■
--■  １０．在庫調整 入庫実績(浜岡入庫)                               ■
--■  １１．在庫調整 入庫実績(仕入先返品)                             ■
--■  １２．在庫調整 入庫実績(上記以外)                               ■
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  -------------------------------------------------------------
  -- １．発注受入実績
  -------------------------------------------------------------
  SELECT
          xrpm_in_po_e.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_po_e.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_po_e.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_po_e.description                      AS location               -- 保管場所名
         ,xilv_in_po_e.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_po_e.item_id                          AS item_id                -- 品目ID
         ,ximv_in_po_e.item_no                          AS item_no                -- 品目コード
         ,ximv_in_po_e.item_name                        AS item_name              -- 品目名
         ,ximv_in_po_e.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_po_e.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_po_e.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_po_e.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_po_e.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_po_e.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_po_e.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_in_po_e.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,pha_in_po_e.segment1                          AS voucher_no             -- 伝票番号
         ,pla_in_po_e.line_num                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,xrart_in_po_e.department_code                 AS loct_code              -- 部署コード
         ,xlc_in_po_e.location_name                     AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xrart_in_po_e.txns_date                       AS leaving_date           -- 入出庫日_発日
         ,xrart_in_po_e.txns_date                       AS arrival_date           -- 入出庫日_着日
         ,xrart_in_po_e.txns_date                       AS standard_date          -- 基準日（着日）
         ,xvv_in_po_e.segment1                          AS ukebaraisaki_code      -- 受払先コード
         ,xvv_in_po_e.vendor_name                       AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_in_po_e.segment1                         AS deliver_to_no          -- 配送先コード
         ,xilv_in_po_e.description                      AS deliver_to_name        -- 配送先名
         ,xrart_in_po_e.quantity                        AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,xrart_in_po_e.quantity                        AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_po_e              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_po_e              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_po_e               -- OPMロットマスタ -- <---- ここまで共通
         ,xxcmn_rcv_pay_mst                             xrpm_in_po_e              -- 受払区分アドオンマスタ
         ,po_headers_all                                pha_in_po_e               -- 発注ヘッダ
         ,po_lines_all                                  pla_in_po_e               -- 発注明細
         ,xxpo_rcv_and_rtn_txns                         xrart_in_po_e             -- 受入返品実績(アドオン)
         ,xxskz_vendors2_v                              xvv_in_po_e               -- 仕入先情報VIEW(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_po_e               -- 部署名取得用
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_po_e.doc_type                         = 'PORC'
     AND  xrpm_in_po_e.source_document_code             = 'PO'
     AND  xrpm_in_po_e.use_div_invent                   = 'Y'
     AND  xrpm_in_po_e.transaction_type                 = 'DELIVER'
     -- 発注ヘッダの条件
     AND  pha_in_po_e.attribute1                        IN ( '25'                 -- 受入あり
                                                           , '30'                 -- 数量確定済
                                                           , '35' )               -- 金額確定済
     -- 発注明細との結合
     AND  pla_in_po_e.attribute13                       = 'Y'                     -- 承諾済
     AND  pla_in_po_e.cancel_flag                      <> 'Y'                     -- キャンセル以外
     AND  pha_in_po_e.po_header_id                      = pla_in_po_e.po_header_id
     -- 受入返品実績(アドオン)との結合
     AND  xrart_in_po_e.txns_type                       = '1'                     -- 受入
     AND  pha_in_po_e.segment1                          = xrart_in_po_e.source_document_number
     AND  pla_in_po_e.line_num                          = xrart_in_po_e.source_document_line_num
     -- 品目マスタとの結合
     AND  xrart_in_po_e.item_id                         = ximv_in_po_e.item_id
     AND  xrart_in_po_e.txns_date                      >= ximv_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= ximv_in_po_e.end_date_active
     -- ロット情報取得
     AND  ximv_in_po_e.item_id                          = ilm_in_po_e.item_id
     AND (   ( ximv_in_po_e.lot_ctl = 1  AND ilm_in_po_e.lot_id = xrart_in_po_e.lot_id )  -- ロット管理品
          OR ( ximv_in_po_e.lot_ctl = 0  AND ilm_in_po_e.lot_id = 0 )                     -- 非ロット管理品
         )
     -- 保管場所情報取得
     AND  pha_in_po_e.attribute5                        = xilv_in_po_e.segment1
     -- 取引先情報取得
     AND  pha_in_po_e.vendor_id                         = xvv_in_po_e.vendor_id
     AND  xrart_in_po_e.txns_date                      >= xvv_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= xvv_in_po_e.end_date_active
     -- 部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xrart_in_po_e.department_code                 = xlc_in_po_e.location_code(+)
--     AND  xrart_in_po_e.txns_date                      >= xlc_in_po_e.start_date_active(+)
--     AND  xrart_in_po_e.txns_date                      <= xlc_in_po_e.end_date_active(+)
     AND  xrart_in_po_e.department_code                 = xlc_in_po_e.location_code
     AND  xrart_in_po_e.txns_date                      >= xlc_in_po_e.start_date_active
     AND  xrart_in_po_e.txns_date                      <= xlc_in_po_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ １．発注受入実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ２．移動入庫実績(積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_in_xf_e.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_xf_e.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_xf_e.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_xf_e.description                      AS location               -- 保管場所名
         ,xilv_in_xf_e.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_xf_e.item_id                          AS item_id                -- 品目ID
         ,ximv_in_xf_e.item_no                          AS item_no                -- 品目コード
         ,ximv_in_xf_e.item_name                        AS item_name              -- 品目名
         ,ximv_in_xf_e.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_xf_e.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_xf_e.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_xf_e.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_xf_e.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_xf_e.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_xf_e.attribute2                        AS uniqe_sign             -- 固有記
         ,ilm_in_xf_e.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_in_xf_e.mov_num                         AS voucher_no             -- 伝票番号
         ,xmril_in_xf_e.line_number                     AS line_no                -- 行番号
         ,xmrih_in_xf_e.delivery_no                     AS delivery_no            -- 配送番号
         ,xmrih_in_xf_e.instruction_post_code           AS loct_code              -- 部署コード
         ,xlc_in_xf_e.location_name                     AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xmrih_in_xf_e.actual_ship_date                AS leaving_date           -- 入出庫日_発日
         ,xmrih_in_xf_e.actual_arrival_date             AS arrival_date           -- 入出庫日_着日
         ,xmrih_in_xf_e.actual_arrival_date             AS standard_date          -- 基準日（着日）
         ,xilv_in_xf_e2.segment1                        AS ukebaraisaki_code      -- 受払先コード
         ,xilv_in_xf_e2.description                     AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_in_xf_e2.segment1                        AS deliver_to_no          -- 配送先コード
         ,xilv_in_xf_e2.description                     AS deliver_to_name        -- 配送先名
         ,xmld_in_xf_e.actual_quantity                  AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,xmld_in_xf_e.actual_quantity                  AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_xf_e              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_xf_e              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_xf_e               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_xf_e              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_xf_e             -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_xf_e             -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_xf_e              -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_in_xf_e2             -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_xf_e               -- 部署名取得用
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_xf_e.doc_type                         = 'XFER'                  --  移動積送あり
     AND  xrpm_in_xf_e.use_div_invent                   = 'Y'
     AND  xrpm_in_xf_e.rcv_pay_div                      = '1'
     -- 移動依頼/指示ヘッダ(アドオン)の条件
     AND  xmrih_in_xf_e.mov_type                        = '1'                     -- 積送あり
     AND  xmrih_in_xf_e.status                          IN ( '06', '05' )         -- 06:入出庫報告有、05:入庫報告有
     -- 移動依頼/指示明細(アドオン)との結合
     AND  xmril_in_xf_e.delete_flg                      = 'N'                     -- OFF
     AND  xmrih_in_xf_e.mov_hdr_id                      = xmril_in_xf_e.mov_hdr_id
     -- 移動ロット詳細(アドオン)との結合
     AND  xmld_in_xf_e.document_type_code               = '20'                    -- 移動
     AND  xmld_in_xf_e.record_type_code                 = '30'                    -- 入庫実績
     AND  xmril_in_xf_e.mov_line_id                     = xmld_in_xf_e.mov_line_id
     -- 品目マスタとの結合
     AND  xmril_in_xf_e.item_id                         = ximv_in_xf_e.item_id
     AND  xmrih_in_xf_e.actual_arrival_date            >= ximv_in_xf_e.start_date_active
     AND  xmrih_in_xf_e.actual_arrival_date            <= ximv_in_xf_e.end_date_active
     -- ロット情報取得
     AND  xmril_in_xf_e.item_id                         = ilm_in_xf_e.item_id
     AND  xmld_in_xf_e.lot_id                           = ilm_in_xf_e.lot_id
     -- OPM保管場所情報取得
     AND  xmrih_in_xf_e.ship_to_locat_id                = xilv_in_xf_e.inventory_location_id
     -- OPM保管場所情報取得2
     AND  xmrih_in_xf_e.shipped_locat_id                = xilv_in_xf_e2.inventory_location_id
     -- 部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_in_xf_e.instruction_post_code           = xlc_in_xf_e.location_code(+)
--     AND  xmrih_in_xf_e.actual_arrival_date            >= xlc_in_xf_e.start_date_active(+)
--     AND  xmrih_in_xf_e.actual_arrival_date            <= xlc_in_xf_e.end_date_active(+)
     AND  xmrih_in_xf_e.instruction_post_code           = xlc_in_xf_e.location_code
     AND  xmrih_in_xf_e.actual_arrival_date            >= xlc_in_xf_e.start_date_active
     AND  xmrih_in_xf_e.actual_arrival_date            <= xlc_in_xf_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ２．移動入庫実績(積送あり)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ３．移動入庫実績(積送なし)
  -------------------------------------------------------------
  SELECT
          xrpm_in_tr_e.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_tr_e.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_tr_e.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_tr_e.description                      AS location               -- 保管場所名
         ,xilv_in_tr_e.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_tr_e.item_id                          AS item_id                -- 品目ID
         ,ximv_in_tr_e.item_no                          AS item_no                -- 品目コード
         ,ximv_in_tr_e.item_name                        AS item_name              -- 品目名
         ,ximv_in_tr_e.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_tr_e.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_tr_e.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_tr_e.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_tr_e.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_tr_e.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_tr_e.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_in_tr_e.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_in_tr_e.mov_num                         AS voucher_no             -- 伝票番号
         ,xmril_in_tr_e.line_number                     AS line_no                -- 行番号
         ,xmrih_in_tr_e.delivery_no                     AS delivery_no            -- 配送番号
         ,xmrih_in_tr_e.instruction_post_code           AS loct_code              -- 部署コード
         ,xlc_in_tr_e.location_name                     AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xmrih_in_tr_e.actual_ship_date                AS leaving_date           -- 入出庫日_発日
         ,xmrih_in_tr_e.actual_arrival_date             AS arrival_date           -- 入出庫日_着日
         ,xmrih_in_tr_e.actual_arrival_date             AS standard_date          -- 基準日（着日）
         ,xilv_in_tr_e2.segment1                        AS ukebaraisaki_code      -- 受払先コード
         ,xilv_in_tr_e2.description                     AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_in_tr_e2.segment1                        AS deliver_to_no          -- 配送先コード
         ,xilv_in_tr_e2.description                     AS deliver_to_name        -- 配送先名
         ,xmld_in_tr_e.actual_quantity                  AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,xmld_in_tr_e.actual_quantity                  AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_tr_e              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_tr_e              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_tr_e               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_tr_e              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_in_tr_e             -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_in_tr_e             -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_tr_e              -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_in_tr_e2             -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_tr_e               -- 部署名取得用
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_tr_e.doc_type                         = 'TRNI'                  -- 移動積送なし
     AND  xrpm_in_tr_e.use_div_invent                   = 'Y'
     AND  xrpm_in_tr_e.rcv_pay_div                      = '1'
     -- 移動依頼/指示ヘッダ(アドオン)の条件
     AND  xmrih_in_tr_e.mov_type                        = '2'                     -- 積送なし
     AND  xmrih_in_tr_e.status                          IN ( '06', '05' )         -- 06:入出庫報告有、05:入庫報告有
     -- 移動依頼/指示明細(アドオン)との結合
     AND  xmril_in_tr_e.delete_flg                      = 'N'                     -- OFF
     AND  xmrih_in_tr_e.mov_hdr_id                      = xmril_in_tr_e.mov_hdr_id
     -- 移動ロット詳細(アドオン)との結合
     AND  xmld_in_tr_e.document_type_code               = '20'                    -- 移動
     AND  xmld_in_tr_e.record_type_code                 = '30'                    -- 入庫実績
     AND  xmril_in_tr_e.mov_line_id                     = xmld_in_tr_e.mov_line_id
     -- 品目マスタとの結合
     AND  xmril_in_tr_e.item_id                         = ximv_in_tr_e.item_id
     AND  xmrih_in_tr_e.actual_arrival_date            >= ximv_in_tr_e.start_date_active
     AND  xmrih_in_tr_e.actual_arrival_date            <= ximv_in_tr_e.end_date_active
     -- ロット情報取得
     AND  xmril_in_tr_e.item_id                         = ilm_in_tr_e.item_id
     AND  xmld_in_tr_e.lot_id                           = ilm_in_tr_e.lot_id
     -- OPM保管場所情報取得
     AND  xmrih_in_tr_e.ship_to_locat_id                = xilv_in_tr_e.inventory_location_id
     -- OPM保管場所情報取得2
     AND  xmrih_in_tr_e.shipped_locat_id                = xilv_in_tr_e2.inventory_location_id
     -- 部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_in_tr_e.instruction_post_code           = xlc_in_tr_e.location_code(+)
--     AND  xmrih_in_tr_e.actual_arrival_date            >= xlc_in_tr_e.start_date_active(+)
--     AND  xmrih_in_tr_e.actual_arrival_date            <= xlc_in_tr_e.end_date_active(+)
     AND  xmrih_in_tr_e.instruction_post_code           = xlc_in_tr_e.location_code
     AND  xmrih_in_tr_e.actual_arrival_date            >= xlc_in_tr_e.start_date_active
     AND  xmrih_in_tr_e.actual_arrival_date            <= xlc_in_tr_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ３．移動入庫実績(積送なし)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ４．生産入庫実績
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e.new_div_invent                   AS reason_code            -- 事由コード
         ,xilv_in_pr_e.whse_code                        AS whse_code              -- 倉庫コード
         ,xilv_in_pr_e.segment1                         AS location_code          -- 保管場所コード
         ,xilv_in_pr_e.description                      AS location               -- 保管場所名
         ,xilv_in_pr_e.short_name                       AS location_s_name        -- 保管場所略称
         ,ximv_in_pr_e.item_id                          AS item_id                -- 品目ID
         ,ximv_in_pr_e.item_no                          AS item_no                -- 品目コード
         ,ximv_in_pr_e.item_name                        AS item_name              -- 品目名
         ,ximv_in_pr_e.item_short_name                  AS item_short_name        -- 品目略称
         ,ximv_in_pr_e.num_of_cases                     AS case_content           -- ケース入数
         ,ximv_in_pr_e.lot_ctl                          AS lot_ctl                -- ロット管理区分
         ,ilm_in_pr_e.lot_id                            AS lot_id                 -- ロットID
         ,ilm_in_pr_e.lot_no                            AS lot_no                 -- ロットNo
         ,ilm_in_pr_e.attribute1                        AS manufacture_date       -- 製造年月日
         ,ilm_in_pr_e.attribute2                        AS uniqe_sign             -- 固有記号
         ,ilm_in_pr_e.attribute3                        AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_in_pr_e.batch_no                          AS voucher_no             -- 伝票番号
         ,gmd_in_pr_e.line_no                           AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_in_pr_e.attribute2                        AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,itp_in_pr_e.trans_date                        AS leaving_date           -- 入出庫日_発日
         ,itp_in_pr_e.trans_date                        AS arrival_date           -- 入出庫日_着日
         ,itp_in_pr_e.trans_date                        AS standard_date          -- 基準日（着日）
         ,grb_in_pr_e.routing_no                        AS ukebaraisaki_code      -- 受払先コード
         ,grt_in_pr_e.routing_desc                      AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,itp_in_pr_e.trans_qty                         AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,itp_in_pr_e.trans_qty                         AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e              -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e              -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_pr_e               -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e              -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e               -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e               -- 生産原料詳細（標準）バックアップ
         ,gmd_routings_b                                grb_in_pr_e               -- 工順マスタ
         ,gmd_routings_tl                               grt_in_pr_e               -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e               -- OPM保留在庫トランザクション（標準）バックアップ
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_pr_e.doc_type                         = 'PROD'
     AND  xrpm_in_pr_e.use_div_invent                   = 'Y'
     -- 工順マスタとの結合（生産データ取得の条件）
     AND  grb_in_pr_e.routing_class                     NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
     AND  grb_in_pr_e.routing_id                        = gbh_in_pr_e.routing_id
     AND  xrpm_in_pr_e.routing_class                    = grb_in_pr_e.routing_class
     -- 生産原料詳細との結合
     AND  gmd_in_pr_e.line_type                         IN ( 1, 2 )               -- 1:完成品、2:副産物
     AND  gbh_in_pr_e.batch_id                          = gmd_in_pr_e.batch_id
     AND  xrpm_in_pr_e.line_type                        = gmd_in_pr_e.line_type
     AND (   ( ( gmd_in_pr_e.attribute5 IS NULL     ) AND ( xrpm_in_pr_e.hit_in_div IS NULL ) )
          OR ( ( gmd_in_pr_e.attribute5 IS NOT NULL ) AND ( xrpm_in_pr_e.hit_in_div = gmd_in_pr_e.attribute5 ) )
         )
     -- OPM保留在庫トランザクションとの結合
     AND  itp_in_pr_e.delete_mark                       = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_in_pr_e.completed_ind                     = 1                       -- 完了(⇒実績)
     AND  itp_in_pr_e.reverse_id                        IS NULL
     AND  itp_in_pr_e.doc_type                          = xrpm_in_pr_e.doc_type
     AND  itp_in_pr_e.line_id                           = gmd_in_pr_e.material_detail_id
     AND  itp_in_pr_e.item_id                           = ximv_in_pr_e.item_id
     -- 品目マスタとの結合
     AND  itp_in_pr_e.item_id                           = ximv_in_pr_e.item_id
     AND  itp_in_pr_e.trans_date                       >= ximv_in_pr_e.start_date_active
     AND  itp_in_pr_e.trans_date                       <= ximv_in_pr_e.end_date_active
     -- ロット情報取得
     AND  ximv_in_pr_e.item_id                          = ilm_in_pr_e.item_id
     AND  itp_in_pr_e.lot_id                            = ilm_in_pr_e.lot_id
     -- OPM保管場所情報取得
     AND  grb_in_pr_e.attribute9                        = xilv_in_pr_e.segment1
     -- 工順マスタ日本語との結合(受払先名取得)
     AND  grt_in_pr_e.language                          = 'JA'
     AND  grb_in_pr_e.routing_id                        = grt_in_pr_e.routing_id
  -- [ ４．生産入庫実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ５．生産入庫実績 品目振替 品種振替
  -- 【注】以下のSQLは変更次第で処理速度が遅くなります
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e70.new_div_invent                 AS reason_code            -- 事由コード
         ,xilv_in_pr_e70.whse_code                      AS whse_code              -- 倉庫コード
         ,xilv_in_pr_e70.segment1                       AS location_code          -- 保管場所コード
         ,xilv_in_pr_e70.description                    AS location               -- 保管場所名
         ,xilv_in_pr_e70.short_name                     AS location_s_name        -- 保管場所略称
         ,ximv_in_pr_e70.item_id                        AS item_id                -- 品目ID
         ,ximv_in_pr_e70.item_no                        AS item_no                -- 品目コード
         ,ximv_in_pr_e70.item_name                      AS item_name              -- 品目名
         ,ximv_in_pr_e70.item_short_name                AS item_short_name        -- 品目略称
         ,ximv_in_pr_e70.num_of_cases                   AS case_content           -- ケース入数
         ,ximv_in_pr_e70.lot_ctl                        AS lot_ctl                -- ロット管理区分
         ,ilm_in_pr_e70.lot_id                          AS lot_id                 -- ロットID
         ,ilm_in_pr_e70.lot_no                          AS lot_no                 -- ロットNo
         ,ilm_in_pr_e70.attribute1                      AS manufacture_date       -- 製造年月日
         ,ilm_in_pr_e70.attribute2                      AS uniqe_sign             -- 固有記号
         ,ilm_in_pr_e70.attribute3                      AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_in_pr_e70.batch_no                        AS voucher_no             -- 伝票番号
         ,gmd_in_pr_e70a.line_no                        AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_in_pr_e70.attribute2                      AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,itp_in_pr_e70.trans_date                      AS leaving_date           -- 入出庫日_発日
         ,itp_in_pr_e70.trans_date                      AS arrival_date           -- 入出庫日_着日
         ,itp_in_pr_e70.trans_date                      AS standard_date          -- 基準日（着日）
         ,grb_in_pr_e70.routing_no                      AS ukebaraisaki_code      -- 受払先コード
         ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,itp_in_pr_e70.trans_qty                       AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,itp_in_pr_e70.trans_qty                       AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e70            -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e70            -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_pr_e70             -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e70            -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e70             -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70a            -- 生産原料詳細（標準）バックアップ(振替先)
         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70b            -- 生産原料詳細（標準）バックアップ(振替元)
         ,gmd_routings_b                                grb_in_pr_e70             -- 工順マスタ
         ,gmd_routings_tl                               grt_in_pr_e70             -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e70             -- OPM保留在庫トランザクション（標準）バックアップ
         ,xxskz_item_class_v                            xicv_in_pr_e70b           -- OPM品目カテゴリ割当情報VIEW5(振替元)
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_pr_e70.doc_type                       = 'PROD'
     AND  xrpm_in_pr_e70.use_div_invent                 = 'Y'
     -- 工順マスタとの結合（品目振替データ取得の条件）
     AND  grb_in_pr_e70.routing_class                   = '70'                    -- 品目振替
     AND  gbh_in_pr_e70.routing_id                      = grb_in_pr_e70.routing_id
     AND  xrpm_in_pr_e70.routing_class                  = grb_in_pr_e70.routing_class
     -- 生産原料詳細(振替先)との結合
     AND  gmd_in_pr_e70a.line_type                      = 1                       -- 振替先
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70a.batch_id
     AND  xrpm_in_pr_e70.line_type                      = gmd_in_pr_e70a.line_type
     -- 生産原料詳細(振替元)との結合
     AND  gmd_in_pr_e70b.line_type                      = -1                      -- 振替元
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70b.batch_id
     AND  gmd_in_pr_e70a.batch_id                       = gmd_in_pr_e70b.batch_id -- ←処理速度UPに有効
     -- OPM保留在庫トランザクションとの結合
     AND  itp_in_pr_e70.delete_mark                     = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_in_pr_e70.completed_ind                   = 1                       -- 完了(⇒実績)
     AND  itp_in_pr_e70.reverse_id                      IS NULL
     AND  itp_in_pr_e70.lot_id                         <> 0
     AND  itp_in_pr_e70.doc_type                        = xrpm_in_pr_e70.doc_type
     AND  itp_in_pr_e70.doc_id                          = gmd_in_pr_e70a.batch_id  -- ←処理速度UPに有効
     AND  itp_in_pr_e70.doc_line                        = gmd_in_pr_e70a.line_no   -- ←処理速度UPに有効
     AND  itp_in_pr_e70.line_type                       = gmd_in_pr_e70a.line_type -- ←処理速度UPに有効
     AND  itp_in_pr_e70.line_id                         = gmd_in_pr_e70a.material_detail_id
     AND  itp_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     -- OPM品目情報VIEW
     AND  gmd_in_pr_e70a.item_id                        = ximv_in_pr_e70.item_id
     AND  itp_in_pr_e70.trans_date                     >= ximv_in_pr_e70.start_date_active
     AND  itp_in_pr_e70.trans_date                     <= ximv_in_pr_e70.end_date_active
     -- OPM品目カテゴリ割当情報VIEW5(振替先、振替元)
     AND  gmd_in_pr_e70b.item_id                        = xicv_in_pr_e70b.item_id
     AND (    xrpm_in_pr_e70.item_div_ahead             = ximv_in_pr_e70.item_class_code   -- 振替先
          AND xrpm_in_pr_e70.item_div_origin            = xicv_in_pr_e70b.item_class_code  -- 振替元
          AND (   ( ximv_in_pr_e70.item_class_code    <> xicv_in_pr_e70b.item_class_code )
               OR ( ximv_in_pr_e70.item_class_code     = xicv_in_pr_e70b.item_class_code )
              )
         )
     -- OPMロットマスタ情報取得
     AND  ximv_in_pr_e70.item_id                        = ilm_in_pr_e70.item_id
     AND  itp_in_pr_e70.lot_id                          = ilm_in_pr_e70.lot_id
     -- OPM保管場所情報取得
     AND  itp_in_pr_e70.whse_code                       = xilv_in_pr_e70.whse_code
     AND  itp_in_pr_e70.location                        = xilv_in_pr_e70.segment1
     -- 工順マスタ日本語との結合(受払先名取得)
     AND  grt_in_pr_e70.language                        = 'JA'
     AND  grb_in_pr_e70.routing_id                      = grt_in_pr_e70.routing_id
  -- [ ５．生産入庫実績 品目振替 品種振替  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ６．生産入庫実績 解体
  -------------------------------------------------------------
  SELECT
          xrpm_in_pr_e70.new_div_invent                 AS reason_code            -- 事由コード
         ,xilv_in_pr_e70.whse_code                      AS whse_code              -- 倉庫コード
         ,xilv_in_pr_e70.segment1                       AS location_code          -- 保管場所コード
         ,xilv_in_pr_e70.description                    AS location               -- 保管場所名
         ,xilv_in_pr_e70.short_name                     AS location_s_name        -- 保管場所略称
         ,ximv_in_pr_e70.item_id                        AS item_id                -- 品目ID
         ,ximv_in_pr_e70.item_no                        AS item_no                -- 品目コード
         ,ximv_in_pr_e70.item_name                      AS item_name              -- 品目名
         ,ximv_in_pr_e70.item_short_name                AS item_short_name        -- 品目略称
         ,ximv_in_pr_e70.num_of_cases                   AS case_content           -- ケース入数
         ,ximv_in_pr_e70.lot_ctl                        AS lot_ctl                -- ロット管理区分
         ,ilm_in_pr_e70.lot_id                          AS lot_id                 -- ロットID
         ,ilm_in_pr_e70.lot_no                          AS lot_no                 -- ロットNo
         ,ilm_in_pr_e70.attribute1                      AS manufacture_date       -- 製造年月日
         ,ilm_in_pr_e70.attribute2                      AS uniqe_sign             -- 固有記号
         ,ilm_in_pr_e70.attribute3                      AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_in_pr_e70.batch_no                        AS voucher_no             -- 伝票番号
         ,gmd_in_pr_e70.line_no                         AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_in_pr_e70.attribute2                      AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,itp_in_pr_e70.trans_date                      AS leaving_date           -- 入出庫日_発日
         ,itp_in_pr_e70.trans_date                      AS arrival_date           -- 入出庫日_着日
         ,itp_in_pr_e70.trans_date                      AS standard_date          -- 基準日（着日）
         ,grb_in_pr_e70.routing_no                      AS ukebaraisaki_code      -- 受払コード
         ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,itp_in_pr_e70.trans_qty                       AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,itp_in_pr_e70.trans_qty                       AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_pr_e70            -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_pr_e70            -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_pr_e70             -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_pr_e70            -- 受払区分アドオンマスタ -- <---- ここまで共通
--Mod 2013/3/19 V1.1 Start 解体データがバックアップされるまでは元テーブル参照
--         ,xxcmn_gme_batch_header_arc                    gbh_in_pr_e70             -- 生産バッチヘッダ（標準）バックアップ
--         ,xxcmn_gme_material_details_arc                gmd_in_pr_e70             -- 生産原料詳細（標準）バックアップ
         ,gme_batch_header                              gbh_in_pr_e70             -- 生産バッチ
         ,gme_material_details                          gmd_in_pr_e70             -- 生産原料詳細
         ,gmd_routings_b                                grb_in_pr_e70             -- 工順マスタ
         ,gmd_routings_tl                               grt_in_pr_e70             -- 工順マスタ日本語
--         ,xxcmn_ic_tran_pnd_arc                         itp_in_pr_e70             -- OPM保留在庫トランザクション（標準）バックアップ
         ,ic_tran_pnd                                   itp_in_pr_e70             -- OPM保留在庫トランザクション
--Mod 2013/3/19 V1.1 End
   WHERE
     -- 受払区分アドオンマスタの条件
          xrpm_in_pr_e70.doc_type                       = 'PROD'
     AND  xrpm_in_pr_e70.use_div_invent                 = 'Y'
     -- 工順マスタとの結合（解体データ取得の条件）
     AND  grb_in_pr_e70.routing_class                   IN ( '61', '62' )         -- 解体
     AND  gbh_in_pr_e70.routing_id                      = grb_in_pr_e70.routing_id
     AND  xrpm_in_pr_e70.routing_class                  = grb_in_pr_e70.routing_class
     -- 生産原料詳細との結合
     AND  gmd_in_pr_e70.line_type                       = 1                       -- 完成品
     AND  gbh_in_pr_e70.batch_id                        = gmd_in_pr_e70.batch_id
     AND  xrpm_in_pr_e70.line_type                      = gmd_in_pr_e70.line_type
     -- OPM保留在庫トランザクションとの結合
     AND  itp_in_pr_e70.delete_mark                     = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_in_pr_e70.completed_ind                   = 1                       -- 完了(⇒実績)
     AND  itp_in_pr_e70.reverse_id                      IS NULL
     AND  itp_in_pr_e70.doc_type                        = xrpm_in_pr_e70.doc_type
     AND  itp_in_pr_e70.line_id                         = gmd_in_pr_e70.material_detail_id
     AND  itp_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     -- 品目マスタとの結合
     AND  gmd_in_pr_e70.item_id                         = ximv_in_pr_e70.item_id
     AND  itp_in_pr_e70.trans_date                      >= ximv_in_pr_e70.start_date_active
     AND  itp_in_pr_e70.trans_date                      <= ximv_in_pr_e70.end_date_active
     -- OPMロットマスタ情報取得
     AND  ximv_in_pr_e70.item_id                        = ilm_in_pr_e70.item_id
     AND  itp_in_pr_e70.lot_id                          = ilm_in_pr_e70.lot_id
     -- OPM保管場所情報取得
     AND  itp_in_pr_e70.whse_code                       = xilv_in_pr_e70.whse_code
     AND  itp_in_pr_e70.location                        = xilv_in_pr_e70.segment1
     -- 工順マスタ日本語との結合(受払先名取得)
     AND  grt_in_pr_e70.language                        = 'JA'
     AND  grb_in_pr_e70.routing_id                      = grt_in_pr_e70.routing_id
  -- [ ６．生産入庫実績 解体  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ７．倉替返品 入庫実績
  -------------------------------------------------------------
  SELECT
          xrpm_in_po_e_rma.new_div_invent               AS reason_code            -- 事由コード
         ,xilv_in_po_e_rma.whse_code                    AS whse_code              -- 倉庫コード
         ,xilv_in_po_e_rma.segment1                     AS location_code          -- 保管場所コード
         ,xilv_in_po_e_rma.description                  AS location               -- 保管場所名
         ,xilv_in_po_e_rma.short_name                   AS location_s_name        -- 保管場所略称
         ,ximv_in_po_e_rma.item_id                      AS item_id                -- 品目ID
         ,ximv_in_po_e_rma.item_no                      AS item_no                -- 品目コード
         ,ximv_in_po_e_rma.item_name                    AS item_name              -- 品目名
         ,ximv_in_po_e_rma.item_short_name              AS item_short_name        -- 品目略称
         ,ximv_in_po_e_rma.num_of_cases                 AS case_content           -- ケース入数
         ,ximv_in_po_e_rma.lot_ctl                      AS lot_ctl                -- ロット管理区分
         ,ilm_in_po_e_rma.lot_id                        AS lot_id                 -- ロットID
         ,ilm_in_po_e_rma.lot_no                        AS lot_no                 -- ロットNo
         ,ilm_in_po_e_rma.attribute1                    AS manufacture_date       -- 製造年月日
         ,ilm_in_po_e_rma.attribute2                    AS uniqe_sign             -- 固有記号
         ,ilm_in_po_e_rma.attribute3                    AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xoha_in_po_e_rma.request_no                   AS voucher_no             -- 伝票番号
         ,xola_in_po_e_rma.order_line_number            AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,xoha_in_po_e_rma.performance_management_dept  AS loct_code              -- 部署コード
         ,xlc_in_po_e_rma.location_name                 AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,xoha_in_po_e_rma.shipped_date                 AS leaving_date           -- 入出庫日_発日
         ,xoha_in_po_e_rma.arrival_date                 AS arrival_date           -- 入出庫日_着日
         ,xoha_in_po_e_rma.arrival_date                 AS standard_date          -- 基準日（着日）
         ,xoha_in_po_e_rma.customer_code                AS ukebaraisaki_code      -- 受払先コード
         ,xcst_in_po_e_rma.party_name                   AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xpas_in_po_e_rma.party_site_number            AS deliver_to_no          -- 配送先コード
         ,xpas_in_po_e_rma.party_site_name              AS deliver_to_name        -- 配送先名
         ,CASE WHEN otta_in_po_e_rma.order_category_code = 'ORDER' THEN xmld_in_po_e_rma.actual_quantity * -1
               ELSE                                                     xmld_in_po_e_rma.actual_quantity
          END                                           AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,CASE WHEN otta_in_po_e_rma.order_category_code = 'ORDER' THEN xmld_in_po_e_rma.actual_quantity * -1
               ELSE                                                     xmld_in_po_e_rma.actual_quantity
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_in_po_e_rma          -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_po_e_rma          -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_po_e_rma           -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_in_po_e_rma          -- 受払区分アドオンマスタ <---- ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_in_po_e_rma          -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_in_po_e_rma          -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_in_po_e_rma          -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_in_po_e_rma          -- 受注タイプ
         ,xxskz_cust_accounts2_v                        xcst_in_po_e_rma          -- 受払先
         ,xxskz_party_sites2_v                          xpas_in_po_e_rma          -- SKYLINK用中間VIEW 配送先情報VIEW2
         ,xxskz_locations2_v                            xlc_in_po_e_rma           -- 部署名取得用
   WHERE
     -- 受払区分アドオンマスタの条件
         (   (     xrpm_in_po_e_rma.doc_type              = 'OMSO'
              AND  otta_in_po_e_rma.order_category_code   = 'ORDER')
          OR (     xrpm_in_po_e_rma.doc_type              = 'PORC'
              AND  xrpm_in_po_e_rma.source_document_code  = 'RMA'
              AND  otta_in_po_e_rma.order_category_code   = 'RETURN'
             )
         )
     AND  xrpm_in_po_e_rma.use_div_invent               = 'Y'
     AND  xrpm_in_po_e_rma.rcv_pay_div                  = '1'                     -- 受入
     -- 受注タイプとの結合
     AND  otta_in_po_e_rma.attribute1                   = '3'                     -- 倉替返品
     AND  otta_in_po_e_rma.attribute1                   = xrpm_in_po_e_rma.shipment_provision_div
     AND  otta_in_po_e_rma.attribute11                  IN ( '03', '04' )
     AND  otta_in_po_e_rma.attribute11                  = xrpm_in_po_e_rma.ship_prov_rcv_pay_category
                                                                                  -- ↑受払区分アドオンを複数読まない為
     -- 受注ヘッダ(アドオン)との結合
     AND  xoha_in_po_e_rma.req_status                   = '04'                    -- 出荷実績計上済
     AND  xoha_in_po_e_rma.latest_external_flag         = 'Y'                     -- ON
     AND  otta_in_po_e_rma.transaction_type_id          = xoha_in_po_e_rma.order_type_id
     -- 受注明細(アドオン)との結合
     AND  xola_in_po_e_rma.delete_flag                  = 'N'                     -- OFF
     AND  xoha_in_po_e_rma.order_header_id              = xola_in_po_e_rma.order_header_id
     -- 移動ロット詳細(アドオン)との結合
     AND  xmld_in_po_e_rma.document_type_code           = '10'                    -- 出荷依頼
     AND  xmld_in_po_e_rma.record_type_code             = '20'                    -- 出庫実績
     AND  xola_in_po_e_rma.order_line_id                = xmld_in_po_e_rma.mov_line_id
     -- OPM品目情報VIEW取得
     AND  xola_in_po_e_rma.shipping_inventory_item_id   = ximv_in_po_e_rma.inventory_item_id
     AND  xoha_in_po_e_rma.arrival_date                >= ximv_in_po_e_rma.start_date_active
     AND  xoha_in_po_e_rma.arrival_date                <= ximv_in_po_e_rma.end_date_active
     -- OPMロットマスタ取得
     AND  ilm_in_po_e_rma.item_id                       = ximv_in_po_e_rma.item_id
     AND  ilm_in_po_e_rma.lot_id                        = xmld_in_po_e_rma.lot_id
     -- OPM保管場所情報VIEW取得
     AND  xoha_in_po_e_rma.deliver_from_id              = xilv_in_po_e_rma.inventory_location_id
     -- 受払先情報取得
     AND  xoha_in_po_e_rma.customer_id                  = xcst_in_po_e_rma.party_id
     AND  xoha_in_po_e_rma.arrival_date                >= xcst_in_po_e_rma.start_date_active --適用開始日
     AND  xoha_in_po_e_rma.arrival_date                <= xcst_in_po_e_rma.end_date_active   --適用終了日
     -- 配送先取得
     AND  xoha_in_po_e_rma.result_deliver_to_id         = xpas_in_po_e_rma.party_site_id
     AND  xoha_in_po_e_rma.arrival_date                >= xpas_in_po_e_rma.start_date_active
     AND  xoha_in_po_e_rma.arrival_date                <= xpas_in_po_e_rma.end_date_active
     -- 部署名取得
     AND  xoha_in_po_e_rma.performance_management_dept  = xlc_in_po_e_rma.location_code(+)
     AND  xoha_in_po_e_rma.arrival_date                >= xlc_in_po_e_rma.start_date_active(+)
     AND  xoha_in_po_e_rma.arrival_date                <= xlc_in_po_e_rma.end_date_active(+)
  -- [ ７．倉替返品 入庫実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ８．在庫調整 入庫実績(相手先在庫)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x97.reason_code                  AS reason_code            -- 事由コード
         ,xilv_in_ad_e_x97.whse_code                    AS whse_code              -- 倉庫コード
         ,xilv_in_ad_e_x97.segment1                     AS location_code          -- 保管場所コード
         ,xilv_in_ad_e_x97.description                  AS location               -- 保管場所名
         ,xilv_in_ad_e_x97.short_name                   AS location_s_name        -- 保管場所略称
         ,ximv_in_ad_e_x97.item_id                      AS item_id                -- 品目ID
         ,ximv_in_ad_e_x97.item_no                      AS item_no                -- 品目コード
         ,ximv_in_ad_e_x97.item_name                    AS item_name              -- 品目名
         ,ximv_in_ad_e_x97.item_short_name              AS item_short_name        -- 品目略称
         ,ximv_in_ad_e_x97.num_of_cases                 AS case_content           -- ケース入数
         ,ximv_in_ad_e_x97.lot_ctl                      AS lot_ctl                -- ロット管理区分
         ,ilm_in_ad_e_x97.lot_id                        AS lot_id                 -- ロットID
         ,ilm_in_ad_e_x97.lot_no                        AS lot_no                 -- ロットNo
         ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date       -- 製造年月日
         ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign             -- 固有記号
         ,ilm_in_ad_e_x97.attribute3                    AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_in_ad_e_x97.journal_no                   AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,NULL                                          AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,sitc_in_ad_e_x97.tran_date                    AS leaving_date           -- 入出庫日_発日
         ,sitc_in_ad_e_x97.tran_date                    AS arrival_date           -- 入出庫日_着日
         ,sitc_in_ad_e_x97.tran_date                    AS standard_date          -- 基準日（着日）
         ,sitc_in_ad_e_x97.reason_code                  AS ukebaraisaki_code      -- 受払先コード（事由コード）
         ,flv_in_ad_e_x97.meaning                       AS ukebaraisaki_name      -- 受払先名（事由コード名）
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,sitc_in_ad_e_x97.quantity                     AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,sitc_in_ad_e_x97.quantity                     AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x97          -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x97          -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x97           -- OPMロットマスタ -- <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_in_ad_e_x97.new_div_invent    reason_code               -- 事由コード
                    ,ijm_in_ad_e_x97.journal_no         journal_no                -- ジャーナルNo
                    ,itc_in_ad_e_x97.location           loct_code                 -- 保管場所コード
                    ,itc_in_ad_e_x97.trans_date         tran_date                 -- 取引日
                    ,itc_in_ad_e_x97.item_id            item_id                   -- 品目ID
                    ,itc_in_ad_e_x97.lot_id             lot_id                    -- ロットID
                    ,SUM( itc_in_ad_e_x97.trans_qty )   quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x97          -- 受払区分アドオンマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x97           -- OPM完了在庫トランザクション（標準）バックアップ
                    ,ic_jrnl_mst                        ijm_in_ad_e_x97           -- OPMジャーナルマスタ
                    ,ic_adjs_jnl                        iaj_in_ad_e_x97           -- OPM在庫調整ジャーナル
              WHERE
                -- 受払区分アドオンマスタの条件
                     xrpm_in_ad_e_x97.doc_type          = 'ADJI'
                AND  xrpm_in_ad_e_x97.reason_code       = 'X977'                  -- 相手先在庫
                AND  xrpm_in_ad_e_x97.rcv_pay_div       = '1'                     -- 受入
                AND  xrpm_in_ad_e_x97.use_div_invent    = 'Y'
                -- OPM完了在庫トランザクションとの結合
                AND  itc_in_ad_e_x97.doc_type           = xrpm_in_ad_e_x97.doc_type
                AND  itc_in_ad_e_x97.reason_code        = xrpm_in_ad_e_x97.reason_code
                AND  SIGN( itc_in_ad_e_x97.trans_qty )  = xrpm_in_ad_e_x97.rcv_pay_div
                -- OPM在庫調整ジャーナルとの結合
                AND  itc_in_ad_e_x97.doc_type           = iaj_in_ad_e_x97.trans_type
                AND  itc_in_ad_e_x97.doc_id             = iaj_in_ad_e_x97.doc_id   -- OPM在庫調整ジャーナル抽出条件
                AND  itc_in_ad_e_x97.doc_line           = iaj_in_ad_e_x97.doc_line -- OPM在庫調整ジャーナル抽出条件
                -- OPMジャーナルマスタとの結合
                AND  ijm_in_ad_e_x97.attribute1         IS NULL                      -- OPMジャーナルマスタ.実績IDがNULL
                AND  iaj_in_ad_e_x97.journal_id         = ijm_in_ad_e_x97.journal_id -- OPMジャーナルマスタ抽出条件
             GROUP BY
                     xrpm_in_ad_e_x97.new_div_invent                              -- 事由コード
                    ,ijm_in_ad_e_x97.journal_no                                   -- ジャーナルNo
                    ,itc_in_ad_e_x97.location                                     -- 保管場所コード
                    ,itc_in_ad_e_x97.trans_date                                   -- 取引日
                    ,itc_in_ad_e_x97.item_id                                      -- 品目ID
                    ,itc_in_ad_e_x97.lot_id                                       -- ロットID
          )                                             sitc_in_ad_e_x97
         ,fnd_lookup_values                             flv_in_ad_e_x97           -- クイックコード(受払先名取得用)
   WHERE
     -- OPM品目情報VIEW取得
          sitc_in_ad_e_x97.item_id                      = ximv_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.tran_date                   >= ximv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= ximv_in_ad_e_x97.end_date_active
     -- OPMロットマスタ取得
     AND  sitc_in_ad_e_x97.item_id                      = ilm_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.lot_id                       = ilm_in_ad_e_x97.lot_id
     -- OPM保管場所情報取得
     AND  sitc_in_ad_e_x97.loct_code                    = xilv_in_ad_e_x97.segment1
     -- クイックコード(受払先名取得)
     AND  flv_in_ad_e_x97.lookup_type                   = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_x97.language                      = 'JA'
     AND  flv_in_ad_e_x97.lookup_code                   = sitc_in_ad_e_x97.reason_code
  -- [ ８．在庫調整 入庫実績(相手先在庫)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ９．在庫調整 入庫実績(外注出来高)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x97.reason_code                  AS reason_code            -- 事由コード
         ,xilv_in_ad_e_x97.whse_code                    AS whse_code              -- 倉庫コード
         ,xilv_in_ad_e_x97.segment1                     AS location_code          -- 保管場所コード
         ,xilv_in_ad_e_x97.description                  AS location               -- 保管場所名
         ,xilv_in_ad_e_x97.short_name                   AS location_s_name        -- 保管場所略称
         ,ximv_in_ad_e_x97.item_id                      AS item_id                -- 品目ID
         ,ximv_in_ad_e_x97.item_no                      AS item_no                -- 品目コード
         ,ximv_in_ad_e_x97.item_name                    AS item_name              -- 品目名
         ,ximv_in_ad_e_x97.item_short_name              AS item_short_name        -- 品目略称
         ,ximv_in_ad_e_x97.num_of_cases                 AS case_content           -- ケース入数
         ,ximv_in_ad_e_x97.lot_ctl                      AS lot_ctl                -- ロット管理区分
         ,ilm_in_ad_e_x97.lot_id                        AS lot_id                 -- ロットID
         ,ilm_in_ad_e_x97.lot_no                        AS lot_no                 -- ロットNo
         ,ilm_in_ad_e_x97.attribute1                    AS manufacture_date       -- 製造年月日
         ,ilm_in_ad_e_x97.attribute2                    AS uniqe_sign             -- 固有記号
         ,ilm_in_ad_e_x97.attribute3                    AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_in_ad_e_x97.journal_no                   AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,NULL                                          AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,sitc_in_ad_e_x97.tran_date                    AS leaving_date           -- 入出庫日_発日
         ,sitc_in_ad_e_x97.tran_date                    AS arrival_date           -- 入出庫日_着日
         ,sitc_in_ad_e_x97.tran_date                    AS standard_date          -- 基準日（着日）
         ,xvv_in_ad_e_x97.segment1                      AS ukebaraisaki_code      -- 受払先コード
         ,xvv_in_ad_e_x97.vendor_name                   AS ukebaraisaki_name      -- 受払先
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,sitc_in_ad_e_x97.quantity                     AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,sitc_in_ad_e_x97.quantity                     AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x97          -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x97          -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x97           -- OPMロットマスタ <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_in_ad_e_x97.new_div_invent    reason_code               -- 事由コー
                    ,ijm_in_ad_e_x97.journal_no         journal_no                -- ジャーナルNo
                    ,itc_in_ad_e_x97.location           loct_code                 -- 保管場所コード
                    ,xvst_in_ad_e_x97.vendor_id         vendor_id                 -- 取引先ID
                    ,itc_in_ad_e_x97.trans_date         tran_date                 -- 取引日
                    ,itc_in_ad_e_x97.item_id            item_id                   -- 品目ID
                    ,itc_in_ad_e_x97.lot_id             lot_id                    -- ロットID
                    ,SUM( itc_in_ad_e_x97.trans_qty )   quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x97          -- 受払区分アドオンマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x97           -- OPM完了在庫トランザクション（標準）バックアップ
                    ,ic_jrnl_mst                        ijm_in_ad_e_x97           -- OPMジャーナルマスタ
                    ,ic_adjs_jnl                        iaj_in_ad_e_x97           -- OPM在庫調整ジャーナル
                    ,xxpo_vendor_supply_txns            xvst_in_ad_e_x97          -- 外注出来高実績
              WHERE
                -- 受払区分アドオンマスタの条件
                     xrpm_in_ad_e_x97.doc_type          = 'ADJI'
                AND  xrpm_in_ad_e_x97.reason_code       = 'X977'                  -- 相手先在庫
                AND  xrpm_in_ad_e_x97.rcv_pay_div       = '1'                     -- 受入
                AND  xrpm_in_ad_e_x97.use_div_invent    = 'Y'
                -- OPM完了在庫トランザクションとの結合
                AND  itc_in_ad_e_x97.doc_type           = xrpm_in_ad_e_x97.doc_type
                AND  itc_in_ad_e_x97.reason_code        = xrpm_in_ad_e_x97.reason_code
                -- OPM在庫調整ジャーナルとの結合
                AND  itc_in_ad_e_x97.doc_type           = iaj_in_ad_e_x97.trans_type
                AND  itc_in_ad_e_x97.doc_id             = iaj_in_ad_e_x97.doc_id   -- OPM在庫調整ジャーナル抽出条件
                AND  itc_in_ad_e_x97.doc_line           = iaj_in_ad_e_x97.doc_line -- OPM在庫調整ジャーナル抽出条件
                -- OPMジャーナルマスタとの結合
                AND  ijm_in_ad_e_x97.attribute1         IS NOT NULL                  -- OPMジャーナルマスタ.実績IDがNULLでない
                AND  iaj_in_ad_e_x97.journal_id         = ijm_in_ad_e_x97.journal_id -- OPMジャーナルマスタ抽出条件
                -- 外注出来高実績との結合
                AND  TO_NUMBER(ijm_in_ad_e_x97.attribute1) = xvst_in_ad_e_x97.txns_id -- 実績ID
             GROUP BY
                     xrpm_in_ad_e_x97.new_div_invent                              -- 事由コード
                    ,ijm_in_ad_e_x97.journal_no                                   -- ジャーナルNo
                    ,itc_in_ad_e_x97.location                                     -- 保管場所コード
                    ,xvst_in_ad_e_x97.vendor_id                                   -- 取引先ID
                    ,itc_in_ad_e_x97.trans_date                                   -- 取引日
                    ,itc_in_ad_e_x97.item_id                                      -- 品目ID
                    ,itc_in_ad_e_x97.lot_id                                       -- ロットID
          )                                             sitc_in_ad_e_x97
         ,xxskz_vendors2_v                              xvv_in_ad_e_x97           -- 仕入先情報(受払先名取得用)
   WHERE
     -- OPM品目情報VIEW取得
          sitc_in_ad_e_x97.item_id                      = ximv_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.tran_date                   >= ximv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= ximv_in_ad_e_x97.end_date_active
     -- OPMロットマスタ取得
     AND  sitc_in_ad_e_x97.item_id                      = ilm_in_ad_e_x97.item_id
     AND  sitc_in_ad_e_x97.lot_id                       = ilm_in_ad_e_x97.lot_id
     -- OPM保管場所情報取得
     AND  sitc_in_ad_e_x97.loct_code                    = xilv_in_ad_e_x97.segment1
     -- 受払先取得
     AND  sitc_in_ad_e_x97.vendor_id                    = xvv_in_ad_e_x97.vendor_id
     AND  sitc_in_ad_e_x97.tran_date                   >= xvv_in_ad_e_x97.start_date_active
     AND  sitc_in_ad_e_x97.tran_date                   <= xvv_in_ad_e_x97.end_date_active
  -- [ ９．在庫調整 入庫実績(外注出来高)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- １０．在庫調整 入庫実績(浜岡入庫)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_x9.reason_code                   AS reason_code            -- 事由コード
         ,xilv_in_ad_e_x9.whse_code                     AS whse_code              -- 倉庫コード
         ,xilv_in_ad_e_x9.segment1                      AS location_code          -- 保管場所コード
         ,xilv_in_ad_e_x9.description                   AS location               -- 保管場所名
         ,xilv_in_ad_e_x9.short_name                    AS location_s_name        -- 保管場所略称
         ,ximv_in_ad_e_x9.item_id                       AS item_id                -- 品目ID
         ,ximv_in_ad_e_x9.item_no                       AS item_no                -- 品目コード
         ,ximv_in_ad_e_x9.item_name                     AS item_name              -- 品目名
         ,ximv_in_ad_e_x9.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_in_ad_e_x9.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_in_ad_e_x9.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_in_ad_e_x9.lot_id                         AS lot_id                 -- ロットID
         ,ilm_in_ad_e_x9.lot_no                         AS lot_no                 -- ロットNo
         ,ilm_in_ad_e_x9.attribute1                     AS manufacture_date       -- 製造年月日
         ,ilm_in_ad_e_x9.attribute2                     AS uniqe_sign             -- 固有記号
         ,ilm_in_ad_e_x9.attribute3                     AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_in_ad_e_x9.entry_num                     AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,sitc_in_ad_e_x9.dept_code                     AS loct_code              -- 部署コード
         ,xlc_in_ad_e_x9.location_name                  AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,sitc_in_ad_e_x9.tran_date                     AS leaving_date           -- 入出庫日_発日
         ,sitc_in_ad_e_x9.tran_date                     AS arrival_date           -- 入出庫日_着日
         ,sitc_in_ad_e_x9.tran_date                     AS standard_date          -- 基準日（着日）
         ,sitc_in_ad_e_x9.reason_code                   AS ukebaraisaki_code      -- 受払先コード
         ,flv_in_ad_e_x9.meaning                        AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,sitc_in_ad_e_x9.quantity                      AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,sitc_in_ad_e_x9.quantity                      AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x9           -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x9           -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x9            -- OPMロットマスタ <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_in_ad_e_x9.new_div_invent     reason_code               -- 事由コード
                    ,xnpt_in_ad_e_x9.entry_number       entry_num                 -- 伝票番号
                    ,itc_in_ad_e_x9.location            loct_code                 -- 保管場所コード
                    ,xnpt_in_ad_e_x9.department_code    dept_code                 -- 部署コード
                    ,itc_in_ad_e_x9.trans_date          tran_date                 -- 取引日
                    ,itc_in_ad_e_x9.item_id             item_id                   -- 品目ID
                    ,itc_in_ad_e_x9.lot_id              lot_id                    -- ロットID
                    ,SUM( itc_in_ad_e_x9.trans_qty )    quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_x9           -- 受払区分アドオンマスタ
                    ,ic_adjs_jnl                        iaj_in_ad_e_x9            -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst                        ijm_in_ad_e_x9            -- OPMジャーナルマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_x9            -- OPM完了在庫トランザクション（標準）バックアップ
                    ,xxpo_namaha_prod_txns              xnpt_in_ad_e_x9           -- 生葉実績（アドオン）
              WHERE
                -- 受払区分アドオンマスタの条件
                     xrpm_in_ad_e_x9.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_x9.reason_code        = 'X988'                  -- 浜岡入庫
                AND  xrpm_in_ad_e_x9.rcv_pay_div        = '1'                     -- 受入
                AND  xrpm_in_ad_e_x9.use_div_invent     = 'Y'
                -- OPM完了在庫トランザクションとの結合
                AND  itc_in_ad_e_x9.doc_type            = xrpm_in_ad_e_x9.doc_type
                AND  itc_in_ad_e_x9.reason_code         = xrpm_in_ad_e_x9.reason_code
                -- OPM在庫調整ジャーナルとの結合
                AND  itc_in_ad_e_x9.doc_type            = iaj_in_ad_e_x9.trans_type
                AND  itc_in_ad_e_x9.doc_id              = iaj_in_ad_e_x9.doc_id
                AND  itc_in_ad_e_x9.doc_line            = iaj_in_ad_e_x9.doc_line
                -- OPMジャーナルマスタとの結合
                AND  ijm_in_ad_e_x9.attribute1          IS NOT NULL
                AND  iaj_in_ad_e_x9.journal_id          = ijm_in_ad_e_x9.journal_id
                -- 生葉実績（アドオン）との結合
                AND  ijm_in_ad_e_x9.attribute1          = xnpt_in_ad_e_x9.entry_number
             GROUP BY
                     xrpm_in_ad_e_x9.new_div_invent                               -- 事由コード
                    ,xnpt_in_ad_e_x9.entry_number                                 -- 伝票番号
                    ,itc_in_ad_e_x9.location                                      -- 保管場所コード
                    ,xnpt_in_ad_e_x9.department_code                              -- 部署コード
                    ,itc_in_ad_e_x9.trans_date                                    -- 取引日
                    ,itc_in_ad_e_x9.item_id                                       -- 品目ID
                    ,itc_in_ad_e_x9.lot_id                                        -- ロットID
          )                                             sitc_in_ad_e_x9
         ,fnd_lookup_values                             flv_in_ad_e_x9            -- クイックコード(受払先名取得用)
         ,xxskz_locations2_v                            xlc_in_ad_e_x9            -- 部署名取得用
   WHERE
     -- OPM品目情報取得
          sitc_in_ad_e_x9.item_id                       = ximv_in_ad_e_x9.item_id
     AND  sitc_in_ad_e_x9.tran_date                    >= ximv_in_ad_e_x9.start_date_active
     AND  sitc_in_ad_e_x9.tran_date                    <= ximv_in_ad_e_x9.end_date_active
     -- OPMロットマスタ取得
     AND  sitc_in_ad_e_x9.item_id                       = ilm_in_ad_e_x9.item_id
     AND  sitc_in_ad_e_x9.lot_id                        = ilm_in_ad_e_x9.lot_id
     -- OPM保管場所情報取得
     AND  sitc_in_ad_e_x9.loct_code                     = xilv_in_ad_e_x9.segment1
     -- クイックコード(受払先名取得)
     AND  flv_in_ad_e_x9.lookup_type                    = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_x9.language                       = 'JA'
     AND  flv_in_ad_e_x9.lookup_code                    = sitc_in_ad_e_x9.reason_code
     -- 部署コード取得(SYSDATEで検索)
     AND  sitc_in_ad_e_x9.dept_code                     = xlc_in_ad_e_x9.location_code(+)
     AND  sitc_in_ad_e_x9.tran_date                    >= xlc_in_ad_e_x9.start_date_active(+)
     AND  sitc_in_ad_e_x9.tran_date                    <= xlc_in_ad_e_x9.end_date_active(+)
  -- [ １０．在庫調整 入庫実績(浜岡入庫)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- １１．在庫調整 入庫実績(仕入先返品)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          srart_in_ad_e_x2.reason_code                  AS reason_code            -- 事由コード
         ,xilv_in_ad_e_x2.whse_code                     AS whse_code              -- 倉庫コード
         ,xilv_in_ad_e_x2.segment1                      AS location_code          -- 保管場所コード
         ,xilv_in_ad_e_x2.description                   AS location               -- 保管場所名
         ,xilv_in_ad_e_x2.short_name                    AS location_s_name        -- 保管場所略称
         ,ximv_in_ad_e_x2.item_id                       AS item_id                -- 品目ID
         ,ximv_in_ad_e_x2.item_no                       AS item_no                -- 品目コード
         ,ximv_in_ad_e_x2.item_name                     AS item_name              -- 品目名
         ,ximv_in_ad_e_x2.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_in_ad_e_x2.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_in_ad_e_x2.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_in_ad_e_x2.lot_id                         AS lot_id                 -- ロットID
         ,ilm_in_ad_e_x2.lot_no                         AS lot_no                 -- ロットNo
         ,ilm_in_ad_e_x2.attribute1                     AS manufacture_date       -- 製造年月日
         ,ilm_in_ad_e_x2.attribute2                     AS uniqe_sign             -- 固有記号
         ,ilm_in_ad_e_x2.attribute3                     AS expiration_date        -- 賞味期限 -- <-- ここまで共通
         ,srart_in_ad_e_x2.rcv_rtn_num                  AS voucher_no             -- 伝票番号
         ,srart_in_ad_e_x2.line_no                      AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,srart_in_ad_e_x2.dept_code                    AS loct_code              -- 部署コード
         ,xlc_in_ad_e_x2.location_name                  AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,srart_in_ad_e_x2.tran_date                    AS leaving_date           -- 入出庫日_発日
         ,srart_in_ad_e_x2.tran_date                    AS arrival_date           -- 入出庫日_着日
         ,srart_in_ad_e_x2.tran_date                    AS standard_date          -- 基準日（発日）
         ,xvv_in_ad_e_x2.segment1                       AS ukebaraisaki_code      -- 受払先コード
         ,xvv_in_ad_e_x2.vendor_name                    AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_in_ad_e_x2.segment1                      AS deliver_to_no          -- 配送先コード
         ,xilv_in_ad_e_x2.description                   AS deliver_to_name        -- 配送先名
         ,srart_in_ad_e_x2.quantity                     AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,srart_in_ad_e_x2.quantity                     AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_x2           -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_x2           -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_x2            -- OPMロットマスタ -- <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_in_ad_e_x2.new_div_invent       reason_code             -- 事由コード
                    ,xrart_in_ad_e_x2.rcv_rtn_number      rcv_rtn_num             -- 受入返品番号
                    ,xrart_in_ad_e_x2.rcv_rtn_line_number line_no                 -- 行番号
                    ,itc_in_ad_e_x2.location              loct_code               -- 保管場所コード
                    ,xrart_in_ad_e_x2.department_code     dept_code               -- 部署コード
                    ,xrart_in_ad_e_x2.vendor_id           vendor_id               -- 取引先ID
                    ,itc_in_ad_e_x2.trans_date            tran_date               -- 取引日
                    ,itc_in_ad_e_x2.item_id               item_id                 -- 品目ID
                    ,itc_in_ad_e_x2.lot_id                lot_id                  -- ロットID
                    ,SUM( itc_in_ad_e_x2.trans_qty )      quantity                -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                    xrpm_in_ad_e_x2         -- 受払区分アドオンマスタ
                    ,ic_adjs_jnl                          iaj_in_ad_e_x2          -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst                          ijm_in_ad_e_x2          -- OPMジャーナルマスタ
                    ,xxcmn_ic_tran_cmp_arc                itc_in_ad_e_x2          -- OPM完了在庫トランザクション（標準）バックアップ
                    ,xxpo_rcv_and_rtn_txns                xrart_in_ad_e_x2        -- 受入返品実績（アドオン）
              WHERE
                --受払区分アドオンマスタの条件
                     xrpm_in_ad_e_x2.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_x2.reason_code        = 'X201'                  -- 仕入返品出庫
                AND  xrpm_in_ad_e_x2.rcv_pay_div        = '1'                     -- 受入
                AND  xrpm_in_ad_e_x2.use_div_invent     = 'Y'
                --完了在庫トランザクションの条件
                AND  itc_in_ad_e_x2.doc_type            = xrpm_in_ad_e_x2.doc_type
                AND  itc_in_ad_e_x2.reason_code         = xrpm_in_ad_e_x2.reason_code
                --在庫調整ジャーナルの取得
                AND  itc_in_ad_e_x2.doc_type            = iaj_in_ad_e_x2.trans_type
                AND  itc_in_ad_e_x2.doc_id              = iaj_in_ad_e_x2.doc_id
                AND  itc_in_ad_e_x2.doc_line            = iaj_in_ad_e_x2.doc_line
                --ジャーナルマスタの取得
                AND  ijm_in_ad_e_x2.attribute1          IS NOT NULL
                AND  iaj_in_ad_e_x2.journal_id          = ijm_in_ad_e_x2.journal_id
                --受入返品実績の取得
                AND  TO_NUMBER( ijm_in_ad_e_x2.attribute1 ) = xrart_in_ad_e_x2.txns_id
             GROUP BY
                     xrpm_in_ad_e_x2.new_div_invent
                    ,xrart_in_ad_e_x2.rcv_rtn_number, xrart_in_ad_e_x2.rcv_rtn_line_number
                    ,itc_in_ad_e_x2.location, xrart_in_ad_e_x2.department_code
                    ,xrart_in_ad_e_x2.vendor_id, itc_in_ad_e_x2.trans_date
                    ,itc_in_ad_e_x2.item_id, itc_in_ad_e_x2.lot_id
          )                                             srart_in_ad_e_x2
         ,xxskz_vendors_v                               xvv_in_ad_e_x2            -- 仕入先情報VIEW
         ,xxskz_locations2_v                            xlc_in_ad_e_x2            -- 部署名取得用
   WHERE
     --品目マスタとの結合
          srart_in_ad_e_x2.item_id                      = ximv_in_ad_e_x2.item_id
     AND  srart_in_ad_e_x2.tran_date                   >= ximv_in_ad_e_x2.start_date_active --適用開始日
     AND  srart_in_ad_e_x2.tran_date                   <= ximv_in_ad_e_x2.end_date_active   --適用終了日
     --ロット情報取得
     AND  srart_in_ad_e_x2.item_id                      = ilm_in_ad_e_x2.item_id
     AND  srart_in_ad_e_x2.lot_id                       = ilm_in_ad_e_x2.lot_id
     --保管場所情報取得
     AND  srart_in_ad_e_x2.loct_code                    = xilv_in_ad_e_x2.segment1
     --受払先(仕入先情報)取得
     AND  srart_in_ad_e_x2.vendor_id                    = xvv_in_ad_e_x2.vendor_id
     AND  srart_in_ad_e_x2.tran_date                   >= xvv_in_ad_e_x2.start_date_active --適用開始日
     AND  srart_in_ad_e_x2.tran_date                   <= xvv_in_ad_e_x2.end_date_active   --適用終了日
     --部署名取得
     AND  srart_in_ad_e_x2.dept_code                    = xlc_in_ad_e_x2.location_code
     AND  srart_in_ad_e_x2.tran_date                   >= xlc_in_ad_e_x2.start_date_active
     AND  srart_in_ad_e_x2.tran_date                   <= xlc_in_ad_e_x2.end_date_active
  -- [ １１．在庫調整 入庫実績(仕入先返品)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- １２．在庫調整 入庫実績(上記以外)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_in_ad_e_xx.reason_code                   AS reason_code            -- 事由コード
         ,xilv_in_ad_e_xx.whse_code                     AS whse_code              -- 倉庫コード
         ,xilv_in_ad_e_xx.segment1                      AS location_code          -- 保管場所コード
         ,xilv_in_ad_e_xx.description                   AS location               -- 保管場所名
         ,xilv_in_ad_e_xx.short_name                    AS location_s_name        -- 保管場所略称
         ,ximv_in_ad_e_xx.item_id                       AS item_id                -- 品目ID
         ,ximv_in_ad_e_xx.item_no                       AS item_no                -- 品目コード
         ,ximv_in_ad_e_xx.item_name                     AS item_name              -- 品目名
         ,ximv_in_ad_e_xx.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_in_ad_e_xx.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_in_ad_e_xx.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_in_ad_e_xx.lot_id                         AS lot_id                 -- ロットID
         ,ilm_in_ad_e_xx.lot_no                         AS lot_no                 -- ロットNo
         ,ilm_in_ad_e_xx.attribute1                     AS manufacture_date       -- 製造年月日
         ,ilm_in_ad_e_xx.attribute2                     AS uniqe_sign             -- 固有記号
         ,ilm_in_ad_e_xx.attribute3                     AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_in_ad_e_xx.journal_no                    AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,NULL                                          AS loct_name              -- 部署名
         ,'1'                                           AS in_out_kbn             -- 入出庫区分（1:入庫）
         ,sitc_in_ad_e_xx.tran_date                     AS leaving_date           -- 入出庫日_発日
         ,sitc_in_ad_e_xx.tran_date                     AS arrival_date           -- 入出庫日_着日
         ,sitc_in_ad_e_xx.tran_date                     AS standard_date          -- 基準日（着日）
         ,sitc_in_ad_e_xx.reason_code                   AS ukebaraisaki_code      -- 受払先コード
         ,flv_in_ad_e_xx.meaning                        AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,sitc_in_ad_e_xx.quantity                      AS stock_quantity         -- 入庫数
         ,0                                             AS leaving_quantity       -- 出庫数
         ,sitc_in_ad_e_xx.quantity                      AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_in_ad_e_xx           -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_in_ad_e_xx           -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_in_ad_e_xx            -- OPMロットマスタ <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_in_ad_e_xx.new_div_invent     reason_code               -- 事由コード
                    ,ijm_in_ad_e_xx.journal_no          journal_no                -- ジャーナルNo
                    ,itc_in_ad_e_xx.location            loct_code                 -- 保管場所コード
                    ,itc_in_ad_e_xx.trans_date          tran_date                 -- 取引日
                    ,itc_in_ad_e_xx.item_id             item_id                   -- 品目ID
                    ,itc_in_ad_e_xx.lot_id              lot_id                    -- ロットID
                    ,SUM( itc_in_ad_e_xx.trans_qty )    quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_in_ad_e_xx           -- 受払区分アドオンマスタ
                    ,ic_adjs_jnl                        iaj_in_ad_e_xx            -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst                        ijm_in_ad_e_xx            -- OPMジャーナルマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_in_ad_e_xx            -- OPM完了在庫トランザクション（標準）バックアップ
              WHERE
                -- 受払区分アドオンマスタの条件
                     xrpm_in_ad_e_xx.doc_type           = 'ADJI'
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X977'                 -- 相手先在庫
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X988'                 -- 浜岡入庫
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X123'                 -- 移動実績訂正（出庫）
                AND  xrpm_in_ad_e_xx.reason_code        <> 'X201'                 -- 仕入先返品
                AND  xrpm_in_ad_e_xx.rcv_pay_div        = '1'                     -- 受入
                AND  xrpm_in_ad_e_xx.use_div_invent     = 'Y'
                -- OPM完了在庫トランザクションとの結合
                AND  itc_in_ad_e_xx.doc_type            = xrpm_in_ad_e_xx.doc_type
                AND  itc_in_ad_e_xx.reason_code         = xrpm_in_ad_e_xx.reason_code
                -- OPM在庫調整ジャーナルとの結合
                AND  itc_in_ad_e_xx.doc_type            = iaj_in_ad_e_xx.trans_type
                AND  itc_in_ad_e_xx.doc_id              = iaj_in_ad_e_xx.doc_id
                AND  itc_in_ad_e_xx.doc_line            = iaj_in_ad_e_xx.doc_line
                -- OPMジャーナルマスタとの結合
                AND  iaj_in_ad_e_xx.journal_id          = ijm_in_ad_e_xx.journal_id
             GROUP BY
                     xrpm_in_ad_e_xx.new_div_invent                               -- 事由コード
                    ,ijm_in_ad_e_xx.journal_no                                    -- ジャーナルNo
                    ,itc_in_ad_e_xx.location                                      -- 保管場所コード
                    ,itc_in_ad_e_xx.trans_date                                    -- 取引日
                    ,itc_in_ad_e_xx.item_id                                       -- 品目ID
                    ,itc_in_ad_e_xx.lot_id                                        -- ロットID
          )                                             sitc_in_ad_e_xx
         ,fnd_lookup_values                             flv_in_ad_e_xx            -- クイックコード(受払先名取得用)
   WHERE
     -- OPM品目情報取得
          sitc_in_ad_e_xx.item_id                       = ximv_in_ad_e_xx.item_id
     AND  sitc_in_ad_e_xx.tran_date                    >= ximv_in_ad_e_xx.start_date_active
     AND  sitc_in_ad_e_xx.tran_date                    <= ximv_in_ad_e_xx.end_date_active
     -- OPMロットマスタ取得
     AND  sitc_in_ad_e_xx.item_id                       = ilm_in_ad_e_xx.item_id
     AND  sitc_in_ad_e_xx.lot_id                        = ilm_in_ad_e_xx.lot_id
     -- OPM保管場所情報取得
     AND  sitc_in_ad_e_xx.loct_code                     = xilv_in_ad_e_xx.segment1
     -- クイックコード(受払先名取得)
     AND  flv_in_ad_e_xx.lookup_type                    = 'XXCMN_NEW_DIVISION'
     AND  flv_in_ad_e_xx.language                       = 'JA'
     AND  flv_in_ad_e_xx.lookup_code                    = sitc_in_ad_e_xx.reason_code
  -- [ １２．在庫調整 入庫実績(上記以外)  END ] --
-- << 入庫実績 END >>
UNION ALL
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--■ 【出庫実績】                                                     ■
--■    １．移動出庫実績(積送あり)                                    ■
--■    ２．移動出庫実績(積送なし)                                    ■
--■    ３．生産出庫実績                                              ■
--■    ４．生産出庫実績 品目振替 品種振替                            ■
--■    ５．生産出庫実績 解体                                         ■
--■    ６．受注出荷実績                                              ■
--■    ７．有償出荷実績                                              ■
--■    ８．在庫調整 出庫実績(出荷 見本出庫 廃却出庫)                 ■
--■    ９．在庫調整 出庫実績(相手先在庫)                             ■
--■  １０．相手先在庫出庫実績                                        ■
--■  １１．在庫調整 出庫実績(上記以外)                               ■
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  -------------------------------------------------------------
  -- １．移動出庫実績(積送あり)
  -------------------------------------------------------------
  SELECT
          xrpm_out_xf_e.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_xf_e.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_xf_e.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_xf_e.description                     AS location               -- 保管場所名
         ,xilv_out_xf_e.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_xf_e.item_id                         AS item_id                -- 品目ID
         ,ximv_out_xf_e.item_no                         AS item_no                -- 品目コード
         ,ximv_out_xf_e.item_name                       AS item_name              -- 品目名
         ,ximv_out_xf_e.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_xf_e.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_xf_e.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_xf_e.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_xf_e.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_xf_e.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_xf_e.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_xf_e.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_out_xf_e.mov_num                        AS voucher_no             -- 伝票番号
         ,xmril_out_xf_e.line_number                    AS line_no                -- 行番号
         ,xmrih_out_xf_e.delivery_no                    AS delivery_no            -- 配送番号
         ,xmrih_out_xf_e.instruction_post_code          AS loct_code              -- 部署コード
         ,xlc_out_xf_e.location_name                    AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xmrih_out_xf_e.actual_ship_date               AS leaving_date           -- 入出庫日_発日
         ,xmrih_out_xf_e.actual_arrival_date            AS arrival_date           -- 入出庫日_着日
         ,xmrih_out_xf_e.actual_ship_date               AS standard_date          -- 基準日（発日）
         ,xilv_out_xf_e2.segment1                       AS ukebaraisaki_code      -- 受払先コード
         ,xilv_out_xf_e2.description                    AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_out_xf_e2.segment1                       AS deliver_to_no          -- 配送先コード
         ,xilv_out_xf_e2.description                    AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,xmld_out_xf_e.actual_quantity                 AS leaving_quantity       -- 出庫数
         ,xmld_out_xf_e.actual_quantity                 AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_xf_e             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_xf_e             -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_xf_e              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_xf_e             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_xf_e            -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_xf_e            -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_xf_e             -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_out_xf_e2            -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_xf_e              -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_xf_e.doc_type                        = 'XFER'                  -- 移動積送あり
     AND  xrpm_out_xf_e.use_div_invent                  = 'Y'
     AND  xrpm_out_xf_e.rcv_pay_div                     = '-1'
     --移動依頼/指示ヘッダの条件
     AND  xmrih_out_xf_e.mov_type                       = '1'                     -- 積送あり
     AND  xmrih_out_xf_e.status                         IN ( '06', '04' )         -- 06:入出庫報告有、04:出庫報告有
     --移動依頼/指示明細との結合
     AND  xmril_out_xf_e.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_xf_e.mov_hdr_id                     = xmril_out_xf_e.mov_hdr_id
     --品目マスタとの結合
     AND  xmril_out_xf_e.item_id                        = ximv_out_xf_e.item_id
     AND  xmrih_out_xf_e.actual_ship_date              >= ximv_out_xf_e.start_date_active --適用開始日
     AND  xmrih_out_xf_e.actual_ship_date              <= ximv_out_xf_e.end_date_active   --適用終了日
     --移動ロット詳細取得
     AND  xmld_out_xf_e.document_type_code              = '20'                    -- 移動
     AND  xmld_out_xf_e.record_type_code                = '20'                    -- 出庫実績
     AND  xmril_out_xf_e.mov_line_id                    = xmld_out_xf_e.mov_line_id
     --ロット情報取得
     AND  xmril_out_xf_e.item_id                        = ilm_out_xf_e.item_id
     AND  xmld_out_xf_e.lot_id                          = ilm_out_xf_e.lot_id
     --保管場所情報取得
     AND  xmrih_out_xf_e.shipped_locat_id               = xilv_out_xf_e.inventory_location_id
     --受払先情報取得
     AND  xmrih_out_xf_e.ship_to_locat_id               = xilv_out_xf_e2.inventory_location_id
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_out_xf_e.instruction_post_code          = xlc_out_xf_e.location_code(+)
--     AND  xmrih_out_xf_e.actual_ship_date              >= xlc_out_xf_e.start_date_active(+)
--     AND  xmrih_out_xf_e.actual_ship_date              <= xlc_out_xf_e.end_date_active(+)
     AND  xmrih_out_xf_e.instruction_post_code          = xlc_out_xf_e.location_code
     AND  xmrih_out_xf_e.actual_ship_date              >= xlc_out_xf_e.start_date_active
     AND  xmrih_out_xf_e.actual_ship_date              <= xlc_out_xf_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ １．移動出庫実績(積送あり)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ２．移動出庫実績(積送なし)
  -------------------------------------------------------------
  SELECT
          xrpm_out_tr_e.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_tr_e.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_tr_e.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_tr_e.description                     AS location               -- 保管場所名
         ,xilv_out_tr_e.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_tr_e.item_id                         AS item_id                -- 品目ID
         ,ximv_out_tr_e.item_no                         AS item_no                -- 品目コード
         ,ximv_out_tr_e.item_name                       AS item_name              -- 品目名
         ,ximv_out_tr_e.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_tr_e.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_tr_e.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_tr_e.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_tr_e.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_tr_e.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_tr_e.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_tr_e.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xmrih_out_tr_e.mov_num                        AS voucher_no             -- 伝票番号
         ,xmril_out_tr_e.line_number                    AS line_no                -- 行番号
         ,xmrih_out_tr_e.delivery_no                    AS delivery_no            -- 配送番号
         ,xmrih_out_tr_e.instruction_post_code          AS loct_code              -- 部署コード
         ,xlc_out_tr_e.location_name                    AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xmrih_out_tr_e.actual_ship_date               AS leaving_date           -- 入出庫日_発日
         ,xmrih_out_tr_e.actual_arrival_date            AS arrival_date           -- 入出庫日_着日
         ,xmrih_out_tr_e.actual_ship_date               AS standard_date          -- 基準日（発日）
         ,xilv_out_tr_e2.segment1                       AS ukebaraisaki_code      -- 受払先コード
         ,xilv_out_tr_e2.description                    AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_out_tr_e2.segment1                       AS deliver_to_no          -- 配送先コード
         ,xilv_out_tr_e2.description                    AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,xmld_out_tr_e.actual_quantity                 AS leaving_quantity       -- 出庫数
         ,xmld_out_tr_e.actual_quantity                 AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_tr_e             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_tr_e             -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_tr_e              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_tr_e             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_mov_req_instr_hdrs_arc                  xmrih_out_tr_e            -- 移動依頼/指示ヘッダ（アドオン）バックアップ
         ,xxcmn_mov_req_instr_lines_arc                 xmril_out_tr_e            -- 移動依頼/指示明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_tr_e             -- 移動ロット詳細（アドオン）バックアップ
         ,xxskz_item_locations2_v                       xilv_out_tr_e2            -- OPM保管場所情報VIEW2(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_tr_e              -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_tr_e.doc_type                        = 'TRNI'                  -- 移動積送なし
     AND  xrpm_out_tr_e.use_div_invent                  = 'Y'
     AND  xrpm_out_tr_e.rcv_pay_div                     = '-1'
     --移動依頼/指示ヘッダの条件
     AND  xmrih_out_tr_e.mov_type                       = '2'                     -- 積送なし
     AND  xmrih_out_tr_e.status                         IN ( '06', '04' )         -- 06:入出庫報告有、04:出庫報告有
     --移動依頼/指示明細との結合
     AND  xmril_out_tr_e.delete_flg                     = 'N'                     -- OFF
     AND  xmrih_out_tr_e.mov_hdr_id                     = xmril_out_tr_e.mov_hdr_id
     --移動ロット詳細取得
     AND  xmld_out_tr_e.document_type_code              = '20'                    -- 移動
     AND  xmld_out_tr_e.record_type_code                = '20'                    -- 出庫実績
     AND  xmld_out_tr_e.mov_line_id                     = xmril_out_tr_e.mov_line_id
     --品目マスタとの結合
     AND  xmril_out_tr_e.item_id                        = ximv_out_tr_e.item_id
     AND  xmrih_out_tr_e.actual_ship_date              >= ximv_out_tr_e.start_date_active --適用開始日
     AND  xmrih_out_tr_e.actual_ship_date              <= ximv_out_tr_e.end_date_active   --適用終了日
     --ロット情報取得
     AND  xmril_out_tr_e.item_id                        = ilm_out_tr_e.item_id
     AND  xmld_out_tr_e.lot_id                          = ilm_out_tr_e.lot_id
     --保管場所情報取得
     AND  xmrih_out_tr_e.shipped_locat_id               = xilv_out_tr_e.inventory_location_id
     --受払先情報取得
     AND  xmrih_out_tr_e.ship_to_locat_id               = xilv_out_tr_e2.inventory_location_id
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xmrih_out_tr_e.instruction_post_code          = xlc_out_tr_e.location_code(+)
--     AND  xmrih_out_tr_e.actual_ship_date              >= xlc_out_tr_e.start_date_active(+)
--     AND  xmrih_out_tr_e.actual_ship_date              <= xlc_out_tr_e.end_date_active(+)
     AND  xmrih_out_tr_e.instruction_post_code          = xlc_out_tr_e.location_code
     AND  xmrih_out_tr_e.actual_ship_date              >= xlc_out_tr_e.start_date_active
     AND  xmrih_out_tr_e.actual_ship_date              <= xlc_out_tr_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ２．移動出庫実績(積送なし)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ３．生産出庫実績
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_pr_e.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_pr_e.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_pr_e.description                     AS location               -- 保管場所名
         ,xilv_out_pr_e.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_pr_e.item_id                         AS item_id                -- 品目ID
         ,ximv_out_pr_e.item_no                         AS item_no                -- 品目コード
         ,ximv_out_pr_e.item_name                       AS item_name              -- 品目名
         ,ximv_out_pr_e.item_short_name                 AS item_short_name        -- 品目略称
         ,ximv_out_pr_e.num_of_cases                    AS case_content           -- ケース入数
         ,ximv_out_pr_e.lot_ctl                         AS lot_ctl                -- ロット管理区分
         ,ilm_out_pr_e.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_pr_e.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_pr_e.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_pr_e.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_pr_e.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_out_pr_e.batch_no                         AS voucher_no             -- 伝票番号
         ,gmd_out_pr_e.line_no                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_out_pr_e.attribute2                       AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,itp_out_pr_e.trans_date                       AS leaving_date           -- 入出庫日_発日
         ,itp_out_pr_e.trans_date                       AS arrival_date           -- 入出庫日_着日
         ,itp_out_pr_e.trans_date                       AS standard_date          -- 基準日（発日）
         ,grb_out_pr_e.routing_no                       AS ukebaraisaki_code      -- 受払先コード
         ,grt_out_pr_e.routing_desc                     AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,itp_out_pr_e.trans_qty * -1                   AS leaving_quantity       -- 出庫数
         ,itp_out_pr_e.trans_qty * -1                   AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e             -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_pr_e              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e              -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e              -- 生産原料詳細（標準）バックアップ
         ,gmd_routings_b                                grb_out_pr_e              -- 工順マスタ
         ,gmd_routings_tl                               grt_out_pr_e              -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e              -- OPM保留在庫トランザクション（標準）バックアップ
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_pr_e.doc_type                        = 'PROD'
     AND  xrpm_out_pr_e.use_div_invent                  = 'Y'
     -- 工順マスタとの結合（生産データ取得の条件）
     AND  grb_out_pr_e.routing_class                    NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
     AND  gbh_out_pr_e.routing_id                       = grb_out_pr_e.routing_id
     AND  xrpm_out_pr_e.routing_class                   = grb_out_pr_e.routing_class
     --生産原料詳細の結合
     AND  gmd_out_pr_e.line_type                        = -1                      -- 投入品
     AND  gbh_out_pr_e.batch_id                         = gmd_out_pr_e.batch_id
     AND  gmd_out_pr_e.line_type                        = xrpm_out_pr_e.line_type
     AND (   ( ( gmd_out_pr_e.attribute5 IS NULL     ) AND ( xrpm_out_pr_e.hit_in_div IS NULL ) )
          OR ( ( gmd_out_pr_e.attribute5 IS NOT NULL ) AND ( xrpm_out_pr_e.hit_in_div = gmd_out_pr_e.attribute5 ) )
         )
     --保留在庫トランザクションの取得
     AND  itp_out_pr_e.delete_mark                      = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_out_pr_e.completed_ind                    = 1                       -- 完了(⇒実績)
     AND  itp_out_pr_e.reverse_id                       IS NULL
     AND  itp_out_pr_e.doc_type                         = xrpm_out_pr_e.doc_type
     AND  itp_out_pr_e.line_id                          = gmd_out_pr_e.material_detail_id
     AND  itp_out_pr_e.item_id                          = gmd_out_pr_e.item_id
     --品目マスタとの結合
     AND  itp_out_pr_e.item_id                          = ximv_out_pr_e.item_id
     AND  itp_out_pr_e.trans_date                      >= ximv_out_pr_e.start_date_active --適用開始日
     AND  itp_out_pr_e.trans_date                      <= ximv_out_pr_e.end_date_active   --適用終了日
     --ロット情報取得
     AND  itp_out_pr_e.item_id                          = ilm_out_pr_e.item_id
     AND  itp_out_pr_e.lot_id                           = ilm_out_pr_e.lot_id
     --保管場所情報取得
     AND  grb_out_pr_e.attribute9                       = xilv_out_pr_e.segment1
     --工順マスタ日本語取得
     AND  grt_out_pr_e.language                         = 'JA'
     AND  grb_out_pr_e.routing_id                       = grt_out_pr_e.routing_id
  -- [ ３．生産出庫実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ４．生産出庫実績 品目振替 品種振替
  -- 【注】以下のSQLは変更次第で処理速度が遅くなります
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e70.new_div_invent                AS reason_code            -- 事由コード
         ,xilv_out_pr_e70.whse_code                     AS whse_code              -- 倉庫コード
         ,xilv_out_pr_e70.segment1                      AS location_code          -- 保管場所コード
         ,xilv_out_pr_e70.description                   AS location               -- 保管場所名
         ,xilv_out_pr_e70.short_name                    AS location_s_name        -- 保管場所略称
         ,ximv_out_pr_e70.item_id                       AS item_id                -- 品目ID
         ,ximv_out_pr_e70.item_no                       AS item_no                -- 品目コード
         ,ximv_out_pr_e70.item_name                     AS item_name              -- 品目名
         ,ximv_out_pr_e70.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_out_pr_e70.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_out_pr_e70.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_out_pr_e70.lot_id                         AS lot_id                 -- ロットID
         ,ilm_out_pr_e70.lot_no                         AS lot_no                 -- ロットNo
         ,ilm_out_pr_e70.attribute1                     AS manufacture_date       -- 製造年月日
         ,ilm_out_pr_e70.attribute2                     AS uniqe_sign             -- 固有記号
         ,ilm_out_pr_e70.attribute3                     AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_out_pr_e70.batch_no                       AS voucher_no             -- 伝票番号
         ,gmd_out_pr_e70a.line_no                       AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_out_pr_e70.attribute2                     AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,itp_out_pr_e70.trans_date                     AS leaving_date           -- 入出庫日_発日
         ,itp_out_pr_e70.trans_date                     AS arrival_date           -- 入出庫日_着日
         ,itp_out_pr_e70.trans_date                     AS standard_date          -- 基準日（発日）
         ,grb_out_pr_e70.routing_no                     AS ukebaraisaki_code      -- 受払先コード
         ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,itp_out_pr_e70.trans_qty * -1                 AS leaving_quantity       -- 出庫数
         ,itp_out_pr_e70.trans_qty * -1                 AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e70           -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e70           -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_pr_e70            -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e70           -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e70            -- 生産バッチヘッダ（標準）バックアップ
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70a           -- 生産原料詳細（標準）バックアップ(振替元)
         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70b           -- 生産原料詳細（標準）バックアップ(振替先)
         ,gmd_routings_b                                grb_out_pr_e70            -- 工順マスタ
         ,gmd_routings_tl                               grt_out_pr_e70            -- 工順マスタ日本語
         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e70            -- OPM保留在庫トランザクション（標準）バックアップ
         ,xxskz_item_class_v                            xicv_out_pr_e70b          -- OPM品目カテゴリ割当情報VIEW5(振替先)
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_pr_e70.doc_type                      = 'PROD'
     AND  xrpm_out_pr_e70.use_div_invent                = 'Y'
     -- 工順マスタとの結合（品目振替データ取得の条件）
     AND  grb_out_pr_e70.routing_class                  = '70'                    -- 品目振替
     AND  gbh_out_pr_e70.routing_id                     = grb_out_pr_e70.routing_id
     AND  xrpm_out_pr_e70.routing_class                 = grb_out_pr_e70.routing_class
     --生産バッチ・生産原料詳細(振替元)の結合条件
     AND  gmd_out_pr_e70a.line_type                     = -1                      -- 振替元
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70a.batch_id
     AND  xrpm_out_pr_e70.line_type                     = gmd_out_pr_e70a.line_type
     --生産バッチ・生産原料詳細(振替先)の結合条件
     AND  gmd_out_pr_e70b.line_type                     = 1                       -- 振替先
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70b.batch_id
     AND  gmd_out_pr_e70a.batch_id                      = gmd_out_pr_e70b.batch_id -- ←処理速度UPに有効
     --保留在庫トランザクションの取得
     AND  itp_out_pr_e70.delete_mark                    = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_out_pr_e70.completed_ind                  = 1                       -- 完了(⇒実績)
     AND  itp_out_pr_e70.reverse_id                     IS NULL
     AND  itp_out_pr_e70.lot_id                        <> 0
     AND  itp_out_pr_e70.doc_type                       = xrpm_out_pr_e70.doc_type
     AND  itp_out_pr_e70.doc_id                         = gmd_out_pr_e70a.batch_id  -- ←処理速度UPに有効
     AND  itp_out_pr_e70.doc_line                       = gmd_out_pr_e70a.line_no   -- ←処理速度UPに有効
     AND  itp_out_pr_e70.line_type                      = gmd_out_pr_e70a.line_type -- ←処理速度UPに有効
     AND  itp_out_pr_e70.line_id                        = gmd_out_pr_e70a.material_detail_id
     AND  itp_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     --品目マスタとの結合
     AND  gmd_out_pr_e70a.item_id                       = ximv_out_pr_e70.item_id
     AND  itp_out_pr_e70.trans_date                    >= ximv_out_pr_e70.start_date_active --適用開始日
     AND  itp_out_pr_e70.trans_date                    <= ximv_out_pr_e70.end_date_active   --適用終了日
     -- OPM品目カテゴリ割当情報VIEW5(振替先、振替元)
     AND  gmd_out_pr_e70b.item_id                       = xicv_out_pr_e70b.item_id
     AND (    xrpm_out_pr_e70.item_div_origin           = ximv_out_pr_e70.item_class_code   -- 振替元
          AND xrpm_out_pr_e70.item_div_ahead            = xicv_out_pr_e70b.item_class_code  -- 振替先
          AND (   ( ximv_out_pr_e70.item_class_code   <> xicv_out_pr_e70b.item_class_code )
               OR ( ximv_out_pr_e70.item_class_code    = xicv_out_pr_e70b.item_class_code )
              )
         )
     --ロット情報取得
     AND  ximv_out_pr_e70.item_id                       = ilm_out_pr_e70.item_id
     AND  itp_out_pr_e70.lot_id                         = ilm_out_pr_e70.lot_id
     -- OPM保管場所情報取得
     AND  itp_out_pr_e70.whse_code                      = xilv_out_pr_e70.whse_code
     AND  itp_out_pr_e70.location                       = xilv_out_pr_e70.segment1
     --工順マスタ日本語取得
     AND  grt_out_pr_e70.language                       = 'JA'
     AND  grb_out_pr_e70.routing_id                     = grt_out_pr_e70.routing_id
  -- [ ４．生産出庫実績 品目振替 品種振替  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ５．生産出庫実績 解体
  -------------------------------------------------------------
  SELECT
          xrpm_out_pr_e70.new_div_invent                AS reason_code            -- 事由コード
         ,xilv_out_pr_e70.whse_code                     AS whse_code              -- 倉庫コード
         ,xilv_out_pr_e70.segment1                      AS location_code          -- 保管場所コード
         ,xilv_out_pr_e70.description                   AS location               -- 保管場所名
         ,xilv_out_pr_e70.short_name                    AS location_s_name        -- 保管場所略称
         ,ximv_out_pr_e70.item_id                       AS item_id                -- 品目ID
         ,ximv_out_pr_e70.item_no                       AS item_no                -- 品目コード
         ,ximv_out_pr_e70.item_name                     AS item_name              -- 品目名
         ,ximv_out_pr_e70.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_out_pr_e70.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_out_pr_e70.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_out_pr_e70.lot_id                         AS lot_id                 -- ロットID
         ,ilm_out_pr_e70.lot_no                         AS lot_no                 -- ロットNo
         ,ilm_out_pr_e70.attribute1                     AS manufacture_date       -- 製造年月日
         ,ilm_out_pr_e70.attribute2                     AS uniqe_sign             -- 固有記号
         ,ilm_out_pr_e70.attribute3                     AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,gbh_out_pr_e70.batch_no                       AS voucher_no             -- 伝票番号
         ,gmd_out_pr_e70.line_no                        AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,gbh_out_pr_e70.attribute2                     AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,itp_out_pr_e70.trans_date                     AS leaving_date           -- 入出庫日_発日
         ,itp_out_pr_e70.trans_date                     AS arrival_date           -- 入出庫日_着日
         ,itp_out_pr_e70.trans_date                     AS standard_date          -- 基準日（発日）
         ,grb_out_pr_e70.routing_no                     AS ukebaraisaki_code      -- 受払コード
         ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,itp_out_pr_e70.trans_qty * -1                 AS leaving_quantity       -- 出庫数
         ,itp_out_pr_e70.trans_qty * -1                 AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_pr_e70           -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_pr_e70           -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_pr_e70            -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_pr_e70           -- 受払区分アドオンマスタ -- <---- ここまで共通
--Mod 2013/3/19 V1.1 Start 解体データがバックアップされるまでは元テーブル参照
--         ,xxcmn_gme_batch_header_arc                    gbh_out_pr_e70            -- 生産バッチヘッダ（標準）バックアップ
--         ,xxcmn_gme_material_details_arc                gmd_out_pr_e70            -- 生産原料詳細（標準）バックアップ
         ,gme_batch_header                              gbh_out_pr_e70            -- 生産バッチ
         ,gme_material_details                          gmd_out_pr_e70            -- 生産原料詳細
         ,gmd_routings_b                                grb_out_pr_e70            -- 工順マスタ
         ,gmd_routings_tl                               grt_out_pr_e70            -- 工順マスタ日本語
--         ,xxcmn_ic_tran_pnd_arc                         itp_out_pr_e70            -- OPM保留在庫トランザクション（標準）バックアップ
         ,ic_tran_pnd                                   itp_out_pr_e70            -- OPM保留在庫トランザクション
--Mod 2013/3/19 V1.1 End
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_pr_e70.doc_type                      = 'PROD'
     AND  xrpm_out_pr_e70.use_div_invent                = 'Y'
     -- 工順マスタとの結合（解体データ取得の条件）
     AND  grb_out_pr_e70.routing_class                  IN ( '61', '62' )         -- 解体
     AND  gbh_out_pr_e70.routing_id                     = grb_out_pr_e70.routing_id
     AND  xrpm_out_pr_e70.routing_class                 = grb_out_pr_e70.routing_class
     --生産バッチ/生産原料詳細の結合
     AND  gmd_out_pr_e70.line_type                      = -1                      -- 投入品
     AND  gbh_out_pr_e70.batch_id                       = gmd_out_pr_e70.batch_id
     AND  xrpm_out_pr_e70.line_type                     = gmd_out_pr_e70.line_type
     --保留在庫トランザクションの取得
     AND  itp_out_pr_e70.delete_mark                    = 0                       -- 有効チェック(OPM保留在庫)
     AND  itp_out_pr_e70.completed_ind                  = 1                       -- 完了(⇒実績)
     AND  itp_out_pr_e70.reverse_id                     IS NULL
     AND  itp_out_pr_e70.doc_type                       = xrpm_out_pr_e70.doc_type
     AND  itp_out_pr_e70.line_id                        = gmd_out_pr_e70.material_detail_id
     AND  itp_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     --品目マスタとの結合
     AND  gmd_out_pr_e70.item_id                        = ximv_out_pr_e70.item_id
     AND  itp_out_pr_e70.trans_date                    >= ximv_out_pr_e70.start_date_active --適用開始日
     AND  itp_out_pr_e70.trans_date                    <= ximv_out_pr_e70.end_date_active   --適用終了日
     --ロット情報取得
     AND  ximv_out_pr_e70.item_id                       = ilm_out_pr_e70.item_id
     AND  itp_out_pr_e70.lot_id                         = ilm_out_pr_e70.lot_id
     --保管場所情報取得
     AND  itp_out_pr_e70.whse_code                      = xilv_out_pr_e70.whse_code
     AND  itp_out_pr_e70.location                       = xilv_out_pr_e70.segment1
     --工順マスタ日本語取得
     AND  grt_out_pr_e70.language                       = 'JA'
     AND  grb_out_pr_e70.routing_id                     = grt_out_pr_e70.routing_id
  -- [ ５．生産出庫実績 解体  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ６．受注出荷実績
  -------------------------------------------------------------
  SELECT
          xrpm_out_om_e.new_div_invent                  AS reason_code            -- 事由コード
         ,xilv_out_om_e.whse_code                       AS whse_code              -- 倉庫コード
         ,xilv_out_om_e.segment1                        AS location_code          -- 保管場所コード
         ,xilv_out_om_e.description                     AS location               -- 保管場所名
         ,xilv_out_om_e.short_name                      AS location_s_name        -- 保管場所略称
         ,ximv_out_om_e_s.item_id                       AS item_id                -- 品目ID
         ,ximv_out_om_e_s.item_no                       AS item_no                -- 品目コード
         ,ximv_out_om_e_s.item_name                     AS item_name              -- 品目名
         ,ximv_out_om_e_s.item_short_name               AS item_short_name        -- 品目略称
         ,ximv_out_om_e_s.num_of_cases                  AS case_content           -- ケース入数
         ,ximv_out_om_e_s.lot_ctl                       AS lot_ctl                -- ロット管理区分
         ,ilm_out_om_e.lot_id                           AS lot_id                 -- ロットID
         ,ilm_out_om_e.lot_no                           AS lot_no                 -- ロットNo
         ,ilm_out_om_e.attribute1                       AS manufacture_date       -- 製造年月日
         ,ilm_out_om_e.attribute2                       AS uniqe_sign             -- 固有記号
         ,ilm_out_om_e.attribute3                       AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xoha_out_om_e.request_no                      AS voucher_no             -- 伝票番号
         ,xola_out_om_e.order_line_number               AS line_no                -- 行番号
         ,xoha_out_om_e.delivery_no                     AS delivery_no            -- 配送番号
         ,xoha_out_om_e.performance_management_dept     AS loct_code              -- 部署コード
         ,xlc_out_om_e.location_name                    AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xoha_out_om_e.shipped_date                    AS leaving_date           -- 入出庫日_発日
         ,xoha_out_om_e.arrival_date                    AS arrival_date           -- 入出庫日_着日
         ,xoha_out_om_e.shipped_date                    AS standard_date          -- 基準日（発日）
         ,CASE WHEN xcst_out_om_e.customer_class_code = '10' THEN xoha_out_om_e.head_sales_branch  --顧客コードが顧客であれば管轄拠点を表示
               ELSE                                               xoha_out_om_e.customer_code      --顧客コードが拠点であればその拠点を表示
          END                                           AS ukebaraisaki_code      -- 受払先コード
         ,CASE WHEN xcst_out_om_e.customer_class_code = '10' THEN xcst_out_om_e_h.party_name       --顧客コードが顧客であれば管轄拠点名を表示
               ELSE                                               xcst_out_om_e.party_name         --顧客コードが拠点であればその拠点名を表示
          END                                           AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xpas_out_om_e.party_site_number               AS deliver_to_no          -- 配送先コード
         ,xpas_out_om_e.party_site_name                 AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,xmld_out_om_e.actual_quantity                 AS leaving_quantity       -- 出庫数
         ,xmld_out_om_e.actual_quantity                 AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_om_e             -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_om_e_s           -- OPM品目情報VIEW(出荷品目)
         ,ic_lots_mst                                   ilm_out_om_e              -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_om_e             -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_out_om_e             -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_out_om_e             -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_om_e             -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_out_om_e             -- 受注タイプ
         ,xxskz_item_mst2_v                             ximv_out_om_e_r           -- OPM品目情報VIEW(依頼品目)
         ,xxskz_cust_accounts2_v                        xcst_out_om_e             -- 受払先(拠点)取得用
         ,xxskz_cust_accounts2_v                        xcst_out_om_e_h           -- 受払先(管轄拠点)取得用
         ,xxskz_party_sites2_v                          xpas_out_om_e             -- 配送先名取得用
         ,xxskz_locations2_v                            xlc_out_om_e              -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件(受注タイプ結合)
          xrpm_out_om_e.doc_type                        = 'OMSO'
     AND  xrpm_out_om_e.use_div_invent                  = 'Y'
     AND  xrpm_out_om_e.stock_adjustment_div            = '1'
     AND  xrpm_out_om_e.shipment_provision_div          = '1'                     -- 出荷依頼
     --受注タイプの条件（含む：受払区分アドオンマスタの絞込み条件）
     AND  otta_out_om_e.attribute1                      = '1'                     -- 出荷依頼
     AND  otta_out_om_e.order_category_code             = 'ORDER'
     AND  xrpm_out_om_e.stock_adjustment_div            = otta_out_om_e.attribute4
     AND  (   xrpm_out_om_e.ship_prov_rcv_pay_category  IS NULL
           OR xrpm_out_om_e.ship_prov_rcv_pay_category  = otta_out_om_e.attribute11
          )
     --受注ヘッダの条件
     AND  xoha_out_om_e.req_status                      = '04'                    -- 出荷実績計上済
     AND  xoha_out_om_e.latest_external_flag            = 'Y'                     -- ON
     AND  otta_out_om_e.transaction_type_id             = xoha_out_om_e.order_type_id
     --受注明細との結合
     AND  xola_out_om_e.delete_flag                     = 'N'                     -- 無効明細以外
     AND  xoha_out_om_e.order_header_id                 = xola_out_om_e.order_header_id
     --移動ロット詳細取得
     AND  xmld_out_om_e.document_type_code              = '10'                    -- 出荷依頼
     AND  xmld_out_om_e.record_type_code                = '20'                    -- 出庫実績
     AND  xola_out_om_e.order_line_id                   = xmld_out_om_e.mov_line_id
     --品目マスタ(出荷品目)との結合
     AND  xmld_out_om_e.item_id                         = ximv_out_om_e_s.item_id
     AND  xoha_out_om_e.shipped_date                   >= ximv_out_om_e_s.start_date_active --適用開始日
     AND  xoha_out_om_e.shipped_date                   <= ximv_out_om_e_s.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om_e.item_div_origin, 'Dummy' ) = DECODE( ximv_out_om_e_s.item_class_code,'5','5','Dummy' ) --振替元品目区分 = 出荷品目区分
     --品目マスタ(依頼品目)との結合
     AND  xola_out_om_e.request_item_id                 = ximv_out_om_e_r.inventory_item_id
     AND  xoha_out_om_e.shipped_date                   >= ximv_out_om_e_r.start_date_active --適用開始日
     AND  xoha_out_om_e.shipped_date                   <= ximv_out_om_e_r.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om_e.item_div_ahead , 'Dummy' ) = DECODE( ximv_out_om_e_r.item_class_code,'5','5','Dummy' ) --振替先品目区分 = 依頼品目区分
     --ロット情報取得
     AND  xmld_out_om_e.item_id                         = ilm_out_om_e.item_id
     AND  xmld_out_om_e.lot_id                          = ilm_out_om_e.lot_id
     --保管場所情報取得
     AND  xoha_out_om_e.deliver_from_id                 = xilv_out_om_e.inventory_location_id
     --受払先情報取得（拠点）
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--     AND  xoha_out_om_e.customer_id                     = xcst_out_om_e.party_id
     AND  xpas_out_om_e.party_id                        = xcst_out_om_e.party_id
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
     AND  xoha_out_om_e.shipped_date                   >= xcst_out_om_e.start_date_active --適用開始日
     AND  xoha_out_om_e.shipped_date                   <= xcst_out_om_e.end_date_active   --適用終了日
     --受払先情報取得（管轄拠点）
     AND  xoha_out_om_e.head_sales_branch               = xcst_out_om_e_h.party_number(+)
     AND  xoha_out_om_e.schedule_ship_date             >= xcst_out_om_e_h.start_date_active(+) --適用開始日
     AND  xoha_out_om_e.schedule_ship_date             <= xcst_out_om_e_h.end_date_active(+)   --適用終了日
     --配送先取得
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--     AND  xoha_out_om_e.result_deliver_to_id            = xpas_out_om_e.party_site_id
     AND  xoha_out_om_e.result_deliver_to               = xpas_out_om_e.party_site_number
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
     AND  xoha_out_om_e.shipped_date                   >= xpas_out_om_e.start_date_active --適用開始日
     AND  xoha_out_om_e.shipped_date                   <= xpas_out_om_e.end_date_active   --適用終了日
     --部署名取得
     AND  xoha_out_om_e.performance_management_dept     = xlc_out_om_e.location_code(+)
     AND  xoha_out_om_e.shipped_date                   >= xlc_out_om_e.start_date_active(+)
     AND  xoha_out_om_e.shipped_date                   <= xlc_out_om_e.end_date_active(+)
  -- [ ６．受注出荷実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ７．有償出荷実績
  -------------------------------------------------------------
  SELECT
          xrpm_out_om2_e.new_div_invent                 AS reason_code            -- 事由コード
         ,xilv_out_om2_e.whse_code                      AS whse_code              -- 倉庫コード
         ,xilv_out_om2_e.segment1                       AS location_code          -- 保管場所コード
         ,xilv_out_om2_e.description                    AS location               -- 保管場所名
         ,xilv_out_om2_e.short_name                     AS location_s_name        -- 保管場所略称
         ,ximv_out_om2_e_s.item_id                      AS item_id                -- 品目ID
         ,ximv_out_om2_e_s.item_no                      AS item_no                -- 品目コード
         ,ximv_out_om2_e_s.item_name                    AS item_name              -- 品目名
         ,ximv_out_om2_e_s.item_short_name              AS item_short_name        -- 品目略称
         ,ximv_out_om2_e_s.num_of_cases                 AS case_content           -- ケース入数
         ,ximv_out_om2_e_s.lot_ctl                      AS lot_ctl                -- ロット管理区分
         ,ilm_out_om2_e.lot_id                          AS lot_id                 -- ロットID
         ,ilm_out_om2_e.lot_no                          AS lot_no                 -- ロットNo
         ,ilm_out_om2_e.attribute1                      AS manufacture_date       -- 製造年月日
         ,ilm_out_om2_e.attribute2                      AS uniqe_sign             -- 固有記号
         ,ilm_out_om2_e.attribute3                      AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,xoha_out_om2_e.request_no                     AS voucher_no             -- 伝票番号
         ,xola_out_om2_e.order_line_number              AS line_no                -- 行番号
         ,xoha_out_om2_e.delivery_no                    AS delivery_no            -- 配送番号
         ,xoha_out_om2_e.performance_management_dept    AS loct_code              -- 部署コード
         ,xlc_out_om2_e.location_name                   AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xoha_out_om2_e.shipped_date                   AS leaving_date           -- 入出庫日_発日
-- *----------* 2009/04/23 M.Nomura update start *----------*
--         ,xoha_out_om2_e.arrival_date                   AS arrival_date           -- 入出庫日_着日
         ,NVL(xoha_out_om2_e.arrival_date,
              xoha_out_om2_e.shipped_date)              AS arrival_date           -- 入出庫日_着日
-- *----------* 2009/04/23 M.Nomura update end   *----------*
         ,xoha_out_om2_e.shipped_date                   AS standard_date          -- 基準日（発日）
         ,xoha_out_om2_e.vendor_site_code               AS ukebaraisaki_code      -- 受払先コード
         ,xvsv_out_om2_e.vendor_site_name               AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,CASE WHEN otta_out_om2_e.order_category_code = 'RETURN' THEN xmld_out_om2_e.actual_quantity * -1
               ELSE                                                    xmld_out_om2_e.actual_quantity
          END                                           AS leaving_quantity       -- 出庫数
         ,CASE WHEN otta_out_om2_e.order_category_code = 'RETURN' THEN xmld_out_om2_e.actual_quantity * -1
               ELSE                                                    xmld_out_om2_e.actual_quantity
          END                                           AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_om2_e            -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_om2_e_s          -- OPM品目情報VIEW(出荷品目)
         ,ic_lots_mst                                   ilm_out_om2_e             -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_om2_e            -- 受払区分アドオンマスタ -- <---- ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_out_om2_e            -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_out_om2_e            -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_om2_e            -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_out_om2_e            -- 受注タイプ
         ,xxskz_item_mst2_v                             ximv_out_om2_e_r          -- OPM品目情報VIEW(依頼品目)
         ,xxskz_vendor_sites_v                          xvsv_out_om2_e            -- 仕入先サイト情報VIEW(受払先名取得用)
         ,xxskz_locations2_v                            xlc_out_om2_e             -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件(受注タイプ結合)
         (   (     xrpm_out_om2_e.doc_type              = 'OMSO'
              AND  otta_out_om2_e.order_category_code   = 'ORDER')
          OR (     xrpm_out_om2_e.doc_type              = 'PORC'
              AND  xrpm_out_om2_e.source_document_code  = 'RMA'
              AND  otta_out_om2_e.order_category_code   = 'RETURN'
             )
         )
     AND  xrpm_out_om2_e.use_div_invent                 = 'Y'
     AND  xrpm_out_om2_e.shipment_provision_div         = '2'                     -- 支給依頼
     --受注タイプの条件（含む：受払区分アドオンマスタの絞込み条件）
     AND  otta_out_om2_e.attribute1                     = '2'                     -- 支給依頼
     AND (   xrpm_out_om2_e.ship_prov_rcv_pay_category  = otta_out_om2_e.attribute11
          OR xrpm_out_om2_e.ship_prov_rcv_pay_category  IS NULL
         )
     --受注ヘッダの条件
     AND  xoha_out_om2_e.req_status                     = '08'                    -- 出荷実績計上済
     AND  xoha_out_om2_e.latest_external_flag           = 'Y'                     -- ON
     AND  otta_out_om2_e.transaction_type_id            = xoha_out_om2_e.order_type_id
     --受注明細との結合
     AND  xola_out_om2_e.delete_flag                    = 'N'                     -- OFF
     AND  xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
     --移動ロット詳細取得
     AND  xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
     AND  xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
     AND  xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
     --品目マスタ(出荷品目)との結合
     AND  xmld_out_om2_e.item_id                        = ximv_out_om2_e_s.item_id
     AND  xoha_out_om2_e.shipped_date                  >= ximv_out_om2_e_s.start_date_active --適用開始日
     AND  xoha_out_om2_e.shipped_date                  <= ximv_out_om2_e_s.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om2_e.item_div_origin,'Dummy' ) = DECODE(ximv_out_om2_e_s.item_class_code,'5','5','Dummy') --振替元品目区分 = 出荷品目区分
     --品目マスタ(依頼品目)との結合
     AND  xola_out_om2_e.request_item_id                = ximv_out_om2_e_r.inventory_item_id
     AND  xoha_out_om2_e.shipped_date                  >= ximv_out_om2_e_r.start_date_active --適用開始日
     AND  xoha_out_om2_e.shipped_date                  <= ximv_out_om2_e_r.end_date_active   --適用終了日
     AND  NVL( xrpm_out_om2_e.item_div_ahead ,'Dummy' ) = DECODE(ximv_out_om2_e_r.item_class_code,'5','5','Dummy') --振替先品目区分 = 依頼品目区分
     --品目カテゴリ・品目カテゴリ割当情報(出荷品目/依頼品目)追加条件
     AND (   (    xola_out_om2_e.shipping_inventory_item_id = xola_out_om2_e.request_item_id               -- 品目振替ではない
              AND xrpm_out_om2_e.prod_div_origin IS NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NULL
             )
          OR (    xola_out_om2_e.shipping_inventory_item_id <> xola_out_om2_e.request_item_id              -- 品目振替
              AND ximv_out_om2_e_s.item_class_code = '5'  AND  ximv_out_om2_e_r.item_class_code = '5'      -- 製品
              AND xrpm_out_om2_e.prod_div_origin IS NOT NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NOT NULL
             )
          OR (    xola_out_om2_e.shipping_inventory_item_id <> xola_out_om2_e.request_item_id              -- 品目振替
              AND ( ximv_out_om2_e_s.item_class_code <> '5'  OR  ximv_out_om2_e_r.item_class_code <> '5')  -- 製品
              AND   xrpm_out_om2_e.prod_div_origin IS NULL  AND  xrpm_out_om2_e.prod_div_ahead IS NULL )
         )
     --ロット情報取得
     AND  xmld_out_om2_e.item_id                        = ilm_out_om2_e.item_id
     AND  xmld_out_om2_e.lot_id                         = ilm_out_om2_e.lot_id
     --保管場所情報取得
     AND  xoha_out_om2_e.deliver_from_id                = xilv_out_om2_e.inventory_location_id
     --受払先(仕入先サイト情報)取得
     AND  xvsv_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
     AND  xoha_out_om2_e.shipped_date                  >= xvsv_out_om2_e.start_date_active --適用開始日
     AND  xoha_out_om2_e.shipped_date                  <= xvsv_out_om2_e.end_date_active   --適用終了日
     --部署名取得
-- 2010/01/05 T.Yoshimoto Mod Start E_本稼動#831
--     AND  xoha_out_om2_e.performance_management_dept    = xlc_out_om2_e.location_code(+)
--     AND  xoha_out_om2_e.shipped_date                  >= xlc_out_om2_e.start_date_active(+)
--     AND  xoha_out_om2_e.shipped_date                  <= xlc_out_om2_e.end_date_active(+)
     AND  xoha_out_om2_e.performance_management_dept    = xlc_out_om2_e.location_code
     AND  xoha_out_om2_e.shipped_date                  >= xlc_out_om2_e.start_date_active
     AND  xoha_out_om2_e.shipped_date                  <= xlc_out_om2_e.end_date_active
-- 2010/01/05 T.Yoshimoto Mod End E_本稼動#831
  -- [ ７．有償出荷実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ８．在庫調整 出庫実績(出荷 見本出庫 廃却出庫)
  -------------------------------------------------------------
  SELECT
          xrpm_out_om3_e.new_div_invent                 AS reason_code            -- 事由コード
         ,xilv_out_om3_e.whse_code                      AS whse_code              -- 倉庫コード
         ,xilv_out_om3_e.segment1                       AS location_code          -- 保管場所コード
         ,xilv_out_om3_e.description                    AS location               -- 保管場所名
         ,xilv_out_om3_e.short_name                     AS location_s_name        -- 保管場所略称
         ,ximv_out_om3_e.item_id                        AS item_id                -- 品目ID
         ,ximv_out_om3_e.item_no                        AS item_no                -- 品目コード
         ,ximv_out_om3_e.item_name                      AS item_name              -- 品目名
         ,ximv_out_om3_e.item_short_name                AS item_short_name        -- 品目略称
         ,ximv_out_om3_e.num_of_cases                   AS case_content           -- ケース入数
         ,ximv_out_om3_e.lot_ctl                        AS lot_ctl                -- ロット管理区分
         ,ilm_out_om3_e.lot_id                          AS lot_id                 -- ロットID
         ,ilm_out_om3_e.lot_no                          AS lot_no                 -- ロットNo
         ,ilm_out_om3_e.attribute1                      AS manufacture_date       -- 製造年月日
         ,ilm_out_om3_e.attribute2                      AS uniqe_sign             -- 固有記号
         ,ilm_out_om3_e.attribute3                      AS expiration_date        -- 賞味期限 -- <--ここまで共通
         ,xoha_out_om3_e.request_no                     AS voucher_no             -- 伝票番号
         ,xola_out_om3_e.order_line_number              AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,xoha_out_om3_e.performance_management_dept    AS loct_code              -- 部署コード
         ,xlc_out_om3_e.location_name                   AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,xoha_out_om3_e.shipped_date                   AS leaving_date           -- 入出庫日_発日
         ,xoha_out_om3_e.arrival_date                   AS arrival_date           -- 入出庫日_着日
         ,xoha_out_om3_e.shipped_date                   AS standard_date          -- 基準日（発日）
         ,xoha_out_om3_e.customer_code                  AS ukebaraisaki_code      -- 受払先コード
         ,xcst_out_om3_e.party_name                     AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xpas_out_om3_e.party_site_number              AS deliver_to_no          -- 配送先コード
         ,xpas_out_om3_e.party_site_name                AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,xmld_out_om3_e.actual_quantity                AS leaving_quantity       -- 出庫数
         ,xmld_out_om3_e.actual_quantity                AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations2_v                       xilv_out_om3_e            -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_om3_e            -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_om3_e             -- OPMロットマスタ
         ,xxcmn_rcv_pay_mst                             xrpm_out_om3_e            -- 受払区分アドオンマスタ -- <--ここまで共通
         ,xxcmn_order_headers_all_arc                   xoha_out_om3_e            -- 受注ヘッダ（アドオン）バックアップ
         ,xxcmn_order_lines_all_arc                     xola_out_om3_e            -- 受注明細（アドオン）バックアップ
         ,xxcmn_mov_lot_details_arc                     xmld_out_om3_e            -- 移動ロット詳細（アドオン）バックアップ
         ,oe_transaction_types_all                      otta_out_om3_e            -- 受注タイプ
         ,xxskz_cust_accounts2_v                        xcst_out_om3_e            -- 受払先
         ,xxskz_party_sites2_v                          xpas_out_om3_e            -- 配送先名取得用
         ,xxskz_locations2_v                            xlc_out_om3_e             -- 部署名取得用
   WHERE
     --受払区分アドオンマスタの条件
          xrpm_out_om3_e.doc_type                       = 'OMSO'
     AND  xrpm_out_om3_e.use_div_invent                 = 'Y'
     AND  xrpm_out_om3_e.stock_adjustment_div           = '2'
     AND  xrpm_out_om3_e.ship_prov_rcv_pay_category    IN ( '01' , '02' )
     --受注タイプ取得
     AND  otta_out_om3_e.attribute1                     = '1'       -- 出荷依頼
     AND  otta_out_om3_e.order_category_code            = 'ORDER'
     AND  xrpm_out_om3_e.stock_adjustment_div           = otta_out_om3_e.attribute4
     AND  xrpm_out_om3_e.ship_prov_rcv_pay_category     = otta_out_om3_e.attribute11
     --受注ヘッダの条件
     AND  xoha_out_om3_e.req_status                     = '04'      -- 出荷実績計上済
     AND  xoha_out_om3_e.latest_external_flag           = 'Y'       -- ON
     AND  otta_out_om3_e.transaction_type_id            = xoha_out_om3_e.order_type_id
     --受注明細との結合
     AND  xola_out_om3_e.delete_flag                    = 'N'       -- OFF
     AND  xoha_out_om3_e.order_header_id                = xola_out_om3_e.order_header_id
     --移動ロット詳細取得
     AND  xmld_out_om3_e.document_type_code             = '10'      -- 出荷依頼
     AND  xmld_out_om3_e.record_type_code               = '20'      -- 出庫実績
     AND  xola_out_om3_e.order_line_id                  = xmld_out_om3_e.mov_line_id
     --品目マスタとの結合
     AND  xmld_out_om3_e.item_id                        = ximv_out_om3_e.item_id
     AND  xoha_out_om3_e.shipped_date                  >= ximv_out_om3_e.start_date_active --適用開始日
     AND  xoha_out_om3_e.shipped_date                  <= ximv_out_om3_e.end_date_active   --適用終了日
     --ロット情報取得
     AND  xmld_out_om3_e.item_id                        = ilm_out_om3_e.item_id
     AND  xmld_out_om3_e.lot_id                         = ilm_out_om3_e.lot_id
     --保管場所情報取得
     AND  xoha_out_om3_e.deliver_from_id                = xilv_out_om3_e.inventory_location_id
     --受払先情報取得
     AND  xoha_out_om3_e.customer_id                    = xcst_out_om3_e.party_id
     AND  xoha_out_om3_e.shipped_date                  >= xcst_out_om3_e.start_date_active --適用開始日
     AND  xoha_out_om3_e.shipped_date                  <= xcst_out_om3_e.end_date_active   --適用終了日
     --配送先取得
     AND  xoha_out_om3_e.result_deliver_to_id           = xpas_out_om3_e.party_site_id
     AND  xoha_out_om3_e.shipped_date                  >= xpas_out_om3_e.start_date_active --適用開始日
     AND  xoha_out_om3_e.shipped_date                  <= xpas_out_om3_e.end_date_active   --適用終了日
     --部署名取得
     AND  xoha_out_om3_e.performance_management_dept    = xlc_out_om3_e.location_code(+)
     AND  xoha_out_om3_e.shipped_date                  >= xlc_out_om3_e.start_date_active(+)
     AND  xoha_out_om3_e.shipped_date                  <= xlc_out_om3_e.end_date_active(+)
  -- [ ８．在庫調整 出庫実績(出荷 見本出庫 廃却出庫)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- ９．在庫調整 出庫実績(相手先在庫)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_x97.reason_code                 AS reason_code            -- 事由コード
         ,xilv_out_ad_e_x97.whse_code                   AS whse_code              -- 倉庫コード
         ,xilv_out_ad_e_x97.segment1                    AS location_code          -- 保管場所コード
         ,xilv_out_ad_e_x97.description                 AS location               -- 保管場所名
         ,xilv_out_ad_e_x97.short_name                  AS location_s_name        -- 保管場所略称
         ,ximv_out_ad_e_x97.item_id                     AS item_id                -- 品目ID
         ,ximv_out_ad_e_x97.item_no                     AS item_no                -- 品目コード
         ,ximv_out_ad_e_x97.item_name                   AS item_name              -- 品目名
         ,ximv_out_ad_e_x97.item_short_name             AS item_short_name        -- 品目略称
         ,ximv_out_ad_e_x97.num_of_cases                AS case_content           -- ケース入数
         ,ximv_out_ad_e_x97.lot_ctl                     AS lot_ctl                -- ロット管理区分
         ,ilm_out_ad_e_x97.lot_id                       AS lot_id                 -- ロットID
         ,ilm_out_ad_e_x97.lot_no                       AS lot_no                 -- ロットNo
         ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date       -- 製造年月日
         ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign             -- 固有記号
         ,ilm_out_ad_e_x97.attribute3                   AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_out_ad_e_x97.journal_no                  AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,NULL                                          AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,sitc_out_ad_e_x97.tran_date                   AS leaving_date           -- 入出庫日_発日
         ,sitc_out_ad_e_x97.tran_date                   AS arrival_date           -- 入出庫日_着日
         ,sitc_out_ad_e_x97.tran_date                   AS standard_date          -- 基準日（発日）
         ,sitc_out_ad_e_x97.reason_code                 AS ukebaraisaki_code      -- 受払先コード
         ,flv_out_ad_e_x97.meaning                      AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード
         ,NULL                                          AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,sitc_out_ad_e_x97.quantity * -1               AS leaving_quantity       -- 出庫数
         ,sitc_out_ad_e_x97.quantity * -1               AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_x97         -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_x97         -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_x97          -- OPMロットマスタ -- <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_out_ad_e_x97.new_div_invent   reason_code               -- 事由コード
                    ,ijm_out_ad_e_x97.journal_no        journal_no                -- ジャーナルNo
                    ,itc_out_ad_e_x97.location          loct_code                 -- 保管場所コード
                    ,itc_out_ad_e_x97.trans_date        tran_date                 -- 取引日
                    ,itc_out_ad_e_x97.item_id           item_id                   -- 品目ID
                    ,itc_out_ad_e_x97.lot_id            lot_id                    -- ロットID
                    ,SUM( itc_out_ad_e_x97.trans_qty )  quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_x97         -- 受払区分アドオンマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_x97          -- OPM完了在庫トランザクション（標準）バックアップ
                    ,ic_jrnl_mst                        ijm_out_ad_e_x97          -- OPMジャーナルマスタ
                    ,ic_adjs_jnl                        iaj_out_ad_e_x97          -- OPM在庫調整ジャーナル
              WHERE
                --受払区分アドオンマスタの条件
                     xrpm_out_ad_e_x97.doc_type         = 'ADJI'
                AND  xrpm_out_ad_e_x97.reason_code      = 'X977'                  -- 相手先在庫
                AND  xrpm_out_ad_e_x97.rcv_pay_div      = '-1'                    -- 払出
                AND  xrpm_out_ad_e_x97.use_div_invent   = 'Y'
                --完了在庫トランザクションの条件
                AND  itc_out_ad_e_x97.doc_type          = xrpm_out_ad_e_x97.doc_type
                AND  itc_out_ad_e_x97.reason_code       = xrpm_out_ad_e_x97.reason_code
                AND  SIGN( itc_out_ad_e_x97.trans_qty ) = xrpm_out_ad_e_x97.rcv_pay_div
                --在庫調整ジャーナルの取得
                AND  itc_out_ad_e_x97.doc_type          = iaj_out_ad_e_x97.trans_type
                AND  itc_out_ad_e_x97.doc_id            = iaj_out_ad_e_x97.doc_id     -- OPM在庫調整ジャーナル抽出条件
                AND  itc_out_ad_e_x97.doc_line          = iaj_out_ad_e_x97.doc_line   -- OPM在庫調整ジャーナル抽出条件
                --ジャーナルマスタの取得
                AND  ijm_out_ad_e_x97.attribute1        IS NULL                       -- OPMジャーナルマスタ.実績IDがNULL
                AND  ijm_out_ad_e_x97.journal_id        = iaj_out_ad_e_x97.journal_id -- OPMジャーナルマスタ抽出条件
             GROUP BY
                     xrpm_out_ad_e_x97.new_div_invent                             -- 事由コード
                    ,ijm_out_ad_e_x97.journal_no                                  -- ジャーナルNo
                    ,itc_out_ad_e_x97.location                                    -- 保管場所コード
                    ,itc_out_ad_e_x97.trans_date                                  -- 取引日
                    ,itc_out_ad_e_x97.item_id                                     -- 品目ID
                    ,itc_out_ad_e_x97.lot_id                                      -- ロットID
          )                                             sitc_out_ad_e_x97
         ,fnd_lookup_values                             flv_out_ad_e_x97          -- クイックコード(受払先名取得用)
   WHERE
     --品目マスタ(出荷品目)との結合
          sitc_out_ad_e_x97.item_id                     = ximv_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.tran_date                  >= ximv_out_ad_e_x97.start_date_active --適用開始日
     AND  sitc_out_ad_e_x97.tran_date                  <= ximv_out_ad_e_x97.end_date_active   --適用終了日
     --ロット情報取得
     AND  sitc_out_ad_e_x97.item_id                     = ilm_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.lot_id                      = ilm_out_ad_e_x97.lot_id
     --保管場所情報取得
     AND  sitc_out_ad_e_x97.loct_code                   = xilv_out_ad_e_x97.segment1
     --受払先情報取得
     AND  flv_out_ad_e_x97.lookup_type                  = 'XXCMN_NEW_DIVISION'
     AND  flv_out_ad_e_x97.language                     = 'JA'
     AND  flv_out_ad_e_x97.lookup_code                  = sitc_out_ad_e_x97.reason_code
  -- [ ９．在庫調整 出庫実績(相手先在庫)  END ] --
UNION ALL
  -------------------------------------------------------------
  -- １０．相手先在庫出庫実績
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_x97.reason_code                 AS reason_code            -- 事由コード
         ,xilv_out_ad_e_x97.whse_code                   AS whse_code              -- 倉庫コード
         ,xilv_out_ad_e_x97.segment1                    AS location_code          -- 保管場所コード
         ,xilv_out_ad_e_x97.description                 AS location               -- 保管場所名
         ,xilv_out_ad_e_x97.short_name                  AS location_s_name        -- 保管場所略称
         ,ximv_out_ad_e_x97.item_id                     AS item_id                -- 品目ID
         ,ximv_out_ad_e_x97.item_no                     AS item_no                -- 品目コード
         ,ximv_out_ad_e_x97.item_name                   AS item_name              -- 品目名
         ,ximv_out_ad_e_x97.item_short_name             AS item_short_name        -- 品目略称
         ,ximv_out_ad_e_x97.num_of_cases                AS case_content           -- ケース入数
         ,ximv_out_ad_e_x97.lot_ctl                     AS lot_ctl                -- ロット管理区分
         ,ilm_out_ad_e_x97.lot_id                       AS lot_id                 -- ロットID
         ,ilm_out_ad_e_x97.lot_no                       AS lot_no                 -- ロットNo
         ,ilm_out_ad_e_x97.attribute1                   AS manufacture_date       -- 製造年月日
         ,ilm_out_ad_e_x97.attribute2                   AS uniqe_sign             -- 固有記号
         ,ilm_out_ad_e_x97.attribute3                   AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_out_ad_e_x97.rcv_rtn_num                 AS voucher_no             -- 伝票番号
         ,sitc_out_ad_e_x97.line_no                     AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,sitc_out_ad_e_x97.dept_code                   AS loct_code              -- 部署コード
         ,xlc_out_ad_e_x97.location_name                AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,sitc_out_ad_e_x97.tran_date                   AS leaving_date           -- 入出庫日_発日
         ,sitc_out_ad_e_x97.tran_date                   AS arrival_date           -- 入出庫日_着日
         ,sitc_out_ad_e_x97.tran_date                   AS standard_date          -- 基準日（発日）
         ,xvv_out_ad_e_x97.segment1                     AS ukebaraisaki_code      -- 受払先コード
         ,xvv_out_ad_e_x97.vendor_name                  AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,xilv_out_ad_e_x97.segment1                    AS deliver_to_no          -- 配送先コード
         ,xilv_out_ad_e_x97.description                 AS deliver_to_name        -- 配送先名
         ,0                                             AS stock_quantity         -- 入庫数
         ,sitc_out_ad_e_x97.quantity * -1               AS leaving_quantity       -- 出庫数
         ,sitc_out_ad_e_x97.quantity * -1               AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_x97         -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_x97         -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_x97          -- OPMロットマスタ
         ,(  -- 対象データを集計
             SELECT
                     xrpm_out_ad_e_x97.new_div_invent       reason_code           -- 事由コード
                    ,xrart_out_ad_e_x97.rcv_rtn_number      rcv_rtn_num           -- 受入返品番号
                    ,xrart_out_ad_e_x97.rcv_rtn_line_number line_no               -- 行番号
                    ,itc_out_ad_e_x97.location              loct_code             -- 保管場所コード
                    ,xrart_out_ad_e_x97.department_code     dept_code             -- 部署コード
                    ,xrart_out_ad_e_x97.vendor_id           vendor_id             -- 取引先ID
                    ,itc_out_ad_e_x97.trans_date            tran_date             -- 取引日
                    ,itc_out_ad_e_x97.item_id               item_id               -- 品目ID
                    ,itc_out_ad_e_x97.lot_id                lot_id                -- ロットID
                    ,SUM( itc_out_ad_e_x97.trans_qty )      quantity              -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_x97         -- 受払区分アドオンマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_x97          -- OPM完了在庫トランザクション（標準）バックアップ -- <---- ここまで共通
                    ,ic_jrnl_mst                        ijm_out_ad_e_x97          -- OPMジャーナルマスタ
                    ,ic_adjs_jnl                        iaj_out_ad_e_x97          -- OPM在庫調整ジャーナル
                    ,xxpo_rcv_and_rtn_txns              xrart_out_ad_e_x97        -- 受入返品実績アドオン
              WHERE
                --受払区分アドオンマスタの条件(受注タイプ結合)
                     xrpm_out_ad_e_x97.doc_type         = 'ADJI'
                AND  xrpm_out_ad_e_x97.reason_code      = 'X977'                  -- 相手先在庫
                AND  xrpm_out_ad_e_x97.rcv_pay_div      = '-1'                    -- 払出
                AND  xrpm_out_ad_e_x97.use_div_invent   = 'Y'
                --完了在庫トランザクションとの結合
                AND  itc_out_ad_e_x97.doc_type          = xrpm_out_ad_e_x97.doc_type
                AND  itc_out_ad_e_x97.reason_code       = xrpm_out_ad_e_x97.reason_code
                --在庫調整ジャーナルとの結合
                AND  itc_out_ad_e_x97.doc_type          = iaj_out_ad_e_x97.trans_type
                AND  itc_out_ad_e_x97.doc_id            = iaj_out_ad_e_x97.doc_id       -- OPM在庫調整ジャーナル抽出条件
                AND  itc_out_ad_e_x97.doc_line          = iaj_out_ad_e_x97.doc_line     -- OPM在庫調整ジャーナル抽出条件
                --ジャーナルマスタとの結合
                AND  ijm_out_ad_e_x97.attribute1        IS NOT NULL                     -- OPMジャーナルマスタ.実績IDがNULLでない
                AND  ijm_out_ad_e_x97.attribute4        IS NULL                         -- (入出庫照会より)
                AND  iaj_out_ad_e_x97.journal_id        = ijm_out_ad_e_x97.journal_id   -- OPMジャーナルマスタ抽出条件
                --受入返品実績アドオンとの結合
                AND  TO_NUMBER(ijm_out_ad_e_x97.attribute1)  = xrart_out_ad_e_x97.txns_id    -- 実績ID
             GROUP BY
                     xrpm_out_ad_e_x97.new_div_invent                             -- 事由コード
                    ,xrart_out_ad_e_x97.rcv_rtn_number                            -- 受入返品番号
                    ,xrart_out_ad_e_x97.rcv_rtn_line_number                       -- 行番号
                    ,itc_out_ad_e_x97.location                                    -- 保管場所コード
                    ,xrart_out_ad_e_x97.department_code                           -- 部署コード
                    ,xrart_out_ad_e_x97.vendor_id                                 -- 取引先ID
                    ,itc_out_ad_e_x97.trans_date                                  -- 取引日
                    ,itc_out_ad_e_x97.item_id                                     -- 品目ID
                    ,itc_out_ad_e_x97.lot_id                                      -- ロットID
          )                                             sitc_out_ad_e_x97
         ,xxskz_vendors_v                               xvv_out_ad_e_x97          -- 仕入先情報
         ,xxskz_locations2_v                            xlc_out_ad_e_x97          -- 部署名取得用
   WHERE
     --品目マスタとの結合
          sitc_out_ad_e_x97.item_id                     = ximv_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.tran_date                  >= ximv_out_ad_e_x97.start_date_active --適用開始日
     AND  sitc_out_ad_e_x97.tran_date                  <= ximv_out_ad_e_x97.end_date_active   --適用終了日
     --ロット情報取得
     AND  sitc_out_ad_e_x97.item_id                     = ilm_out_ad_e_x97.item_id
     AND  sitc_out_ad_e_x97.lot_id                      = ilm_out_ad_e_x97.lot_id
     --保管場所情報取得
     AND  sitc_out_ad_e_x97.loct_code                   = xilv_out_ad_e_x97.segment1
     --受払先(仕入先情報)取得
     AND  sitc_out_ad_e_x97.vendor_id                  = xvv_out_ad_e_x97.vendor_id          -- 仕入先ID
     AND  sitc_out_ad_e_x97.tran_date                  >= xvv_out_ad_e_x97.start_date_active --適用開始日
     AND  sitc_out_ad_e_x97.tran_date                  <= xvv_out_ad_e_x97.end_date_active   --適用終了日
     --部署名取得
     AND  sitc_out_ad_e_x97.dept_code                   = xlc_out_ad_e_x97.location_code
     AND  sitc_out_ad_e_x97.tran_date                  >= xlc_out_ad_e_x97.start_date_active
     AND  sitc_out_ad_e_x97.tran_date                  <= xlc_out_ad_e_x97.end_date_active
  -- [ １０．相手先在庫出庫実績  END ] --
UNION ALL
  -------------------------------------------------------------
  -- １１．在庫調整 出庫実績(上記以外)
  --  ※OPM完了在庫トランザクションでデータ分割する為、集計を行う
  -------------------------------------------------------------
  SELECT
          sitc_out_ad_e_xx.reason_code                  AS reason_code            -- 事由コード
         ,xilv_out_ad_e_xx.whse_code                    AS whse_code              -- 倉庫コード
         ,xilv_out_ad_e_xx.segment1                     AS location_code          -- 保管場所コード
         ,xilv_out_ad_e_xx.description                  AS location               -- 保管場所名
         ,xilv_out_ad_e_xx.short_name                   AS location_s_name        -- 保管場所略称
         ,ximv_out_ad_e_xx.item_id                      AS item_id                -- 品目ID
         ,ximv_out_ad_e_xx.item_no                      AS item_no                -- 品目コード
         ,ximv_out_ad_e_xx.item_name                    AS item_name              -- 品目名
         ,ximv_out_ad_e_xx.item_short_name              AS item_short_name        -- 品目略称
         ,ximv_out_ad_e_xx.num_of_cases                 AS case_content           -- ケース入数
         ,ximv_out_ad_e_xx.lot_ctl                      AS lot_ctl                -- ロット管理区分
         ,ilm_out_ad_e_xx.lot_id                        AS lot_id                 -- ロットID
         ,ilm_out_ad_e_xx.lot_no                        AS lot_no                 -- ロットNo
         ,ilm_out_ad_e_xx.attribute1                    AS manufacture_date       -- 製造年月日
         ,ilm_out_ad_e_xx.attribute2                    AS uniqe_sign             -- 固有記号
         ,ilm_out_ad_e_xx.attribute3                    AS expiration_date        -- 賞味期限 -- <---- ここまで共通
         ,sitc_out_ad_e_xx.journal_no                   AS voucher_no             -- 伝票番号
         ,NULL                                          AS line_no                -- 行番号
         ,NULL                                          AS delivery_no            -- 配送番号
         ,NULL                                          AS loct_code              -- 部署コード
         ,NULL                                          AS loct_name              -- 部署名
         ,'2'                                           AS in_out_kbn             -- 入出庫区分（2:出庫）
         ,sitc_out_ad_e_xx.tran_date                    AS leaving_date           -- 入出庫日_発日
         ,sitc_out_ad_e_xx.tran_date                    AS arrival_date           -- 入出庫日_着日
         ,sitc_out_ad_e_xx.tran_date                    AS standard_date          -- 基準日（発日）
         ,sitc_out_ad_e_xx.reason_code                  AS ukebaraisaki_code      -- 受払先コード
         ,flv_out_ad_e_xx.meaning                       AS ukebaraisaki_name      -- 受払先名
         ,'2'                                           AS status                 -- 予定実績区分（2:実績）
         ,NULL                                          AS deliver_to_no          -- 配送先コード 
         ,NULL                                          AS deliver_to_name        -- 配送先名 
         ,0                                             AS stock_quantity         -- 入庫数 
         ,sitc_out_ad_e_xx.quantity * -1                AS leaving_quantity       -- 出庫数
         ,sitc_out_ad_e_xx.quantity * -1                AS quantity               -- 入出庫数
    FROM
          xxskz_item_locations_v                        xilv_out_ad_e_xx          -- OPM保管場所情報VIEW
         ,xxskz_item_mst2_v                             ximv_out_ad_e_xx          -- OPM品目情報VIEW
         ,ic_lots_mst                                   ilm_out_ad_e_xx           -- OPMロットマスタ -- <---- ここまで共通
         ,(  -- 対象データを集計
             SELECT
                     xrpm_out_ad_e_xx.new_div_invent    reason_code               -- 事由コード
                    ,ijm_out_ad_e_xx.journal_no         journal_no                -- ジャーナルNo
                    ,itc_out_ad_e_xx.location           loct_code                 -- 保管場所コード
                    ,itc_out_ad_e_xx.trans_date         tran_date                 -- 取引日
                    ,itc_out_ad_e_xx.item_id            item_id                   -- 品目ID
                    ,itc_out_ad_e_xx.lot_id             lot_id                    -- ロットID
                    ,SUM( itc_out_ad_e_xx.trans_qty )   quantity                  -- 入出庫数（集計値）
               FROM
                     xxcmn_rcv_pay_mst                  xrpm_out_ad_e_xx          -- 受払区分アドオンマスタ
                    ,ic_adjs_jnl                        iaj_out_ad_e_xx           -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst                        ijm_out_ad_e_xx           -- OPMジャーナルマスタ
                    ,xxcmn_ic_tran_cmp_arc              itc_out_ad_e_xx           -- OPM完了在庫トランザクション（標準）バックアップ
              WHERE
                --受払区分アドオンマスタの条件
                     xrpm_out_ad_e_xx.doc_type          = 'ADJI'
                AND  xrpm_out_ad_e_xx.reason_code      <> 'X977'                  -- 相手先在庫
                AND  xrpm_out_ad_e_xx.reason_code      <> 'X123'                  -- 移動実績訂正（入庫）
                AND  xrpm_out_ad_e_xx.rcv_pay_div       = '-1'                    -- 払出
                AND  xrpm_out_ad_e_xx.use_div_invent    = 'Y'
                --完了在庫トランザクションの条件
                AND  itc_out_ad_e_xx.doc_type           = xrpm_out_ad_e_xx.doc_type
                AND  itc_out_ad_e_xx.reason_code        = xrpm_out_ad_e_xx.reason_code
                --在庫調整ジャーナルの取得
                AND  itc_out_ad_e_xx.doc_type           = iaj_out_ad_e_xx.trans_type
                AND  itc_out_ad_e_xx.doc_id             = iaj_out_ad_e_xx.doc_id
                AND  itc_out_ad_e_xx.doc_line           = iaj_out_ad_e_xx.doc_line
                --ジャーナルマスタの取得
                AND  iaj_out_ad_e_xx.journal_id         = ijm_out_ad_e_xx.journal_id
             GROUP BY
                     xrpm_out_ad_e_xx.new_div_invent                              -- 事由コード
                    ,ijm_out_ad_e_xx.journal_no                                   -- ジャーナルNo
                    ,itc_out_ad_e_xx.location                                     -- 保管場所コード
                    ,itc_out_ad_e_xx.trans_date                                   -- 取引日
                    ,itc_out_ad_e_xx.item_id                                      -- 品目ID
                    ,itc_out_ad_e_xx.lot_id                                       -- ロットID
          )                                             sitc_out_ad_e_xx
         ,fnd_lookup_values                             flv_out_ad_e_xx           -- クイックコード(受払先名取得用)
   WHERE
     --品目マスタ(出荷品目)との結合
          sitc_out_ad_e_xx.item_id                      = ximv_out_ad_e_xx.item_id
     AND  sitc_out_ad_e_xx.tran_date                   >= ximv_out_ad_e_xx.start_date_active --適用開始日
     AND  sitc_out_ad_e_xx.tran_date                   <= ximv_out_ad_e_xx.end_date_active   --適用終了日
     --ロット情報取得
     AND  sitc_out_ad_e_xx.item_id                      = ilm_out_ad_e_xx.item_id
     AND  sitc_out_ad_e_xx.lot_id                       = ilm_out_ad_e_xx.lot_id
     --保管場所情報取得
     AND  sitc_out_ad_e_xx.loct_code                    = xilv_out_ad_e_xx.segment1
     --受払先情報取得
     AND  flv_out_ad_e_xx.lookup_type                   = 'XXCMN_NEW_DIVISION'
     AND  flv_out_ad_e_xx.language                      = 'JA'
     AND  flv_out_ad_e_xx.lookup_code                   = sitc_out_ad_e_xx.reason_code
  -- [ １１．在庫調整 出庫実績(上記以外)  END ] --
-- << 出庫実績 END >>
/
COMMENT ON TABLE APPS.XXSKZ_INOUT_TRANS_V IS 'XXSKZ_入出庫情報_中間VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.reason_code       IS '事由コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.whse_code         IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location_code     IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location          IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.location_s_name   IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_id           IS '品目ID'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_no           IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_name         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.item_short_name   IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.case_content      IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_ctl           IS 'ロット管理区分'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_no            IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.lot_id            IS 'ロットID'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.manufacture_date  IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.uniqe_sign        IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.expiration_date   IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.voucher_no        IS '伝票番号'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.line_no           IS '行番号'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.delivery_no       IS '配送番号'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.loct_code         IS '部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.loct_name         IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.in_out_kbn        IS '入出庫区分'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.leaving_date      IS '入出庫日_発日'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.arrival_date      IS '入出庫日_着日'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.standard_date     IS '基準日'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.ukebaraisaki_code IS '受払先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.ukebaraisaki_name IS '受払先名'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.status            IS '予定実績区分'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.deliver_to_no     IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.deliver_to_name   IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.stock_quantity    IS '入庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.leaving_quantity  IS '出庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_INOUT_TRANS_V.quantity          IS '入出庫数'
/
