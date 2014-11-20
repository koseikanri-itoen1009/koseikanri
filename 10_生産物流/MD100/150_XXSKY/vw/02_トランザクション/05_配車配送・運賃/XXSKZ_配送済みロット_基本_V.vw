/*************************************************************************
 * 
 * View  Name      : XXSKZ_配送済みロット_基本_V
 * Description     : XXSKZ_配送済みロット_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_配送済みロット_基本_V
(
 配送先コード
,配送先名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,出庫日
,最大製造年月日
,最大賞味期限
)
AS
SELECT
        XPS2V.party_site_number                             deliver_to          --配送先コード
       ,XPS2V.party_site_name                               deliver_name        --配送先名
       ,XPCV.prod_class_code                                prod_class_code     --商品区分
       ,XPCV.prod_class_name                                prod_class_name     --商品区分名
       ,XICV.item_class_code                                item_class_code     --品目区分
       ,XICV.item_class_name                                item_class_name     --品目区分名
       ,XCCV.crowd_code                                     crowd_code          --群コード
       ,XIM2V.item_no                                       item_code           --品目コード
       ,XIM2V.item_name                                     item_name           --品目名
       ,XIM2V.item_short_name                               item_short_name     --品目略称
       ,SSHP.shipped_date                                   shipped_date        --出庫日
       ,SSHP.max_lot_date                                   max_lot_date        --最大製造年月日
       ,SSHP.max_best_bfr_date                              max_best_bfr_date   --最大賞味期限
  FROM (
          SELECT
                  SHIP.deliver_to_id                        deliver_to_id       --配送先ID
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                 ,SHIP.deliver_to                           deliver_to          --配送先コード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                 ,SHIP.item_id                              item_id             --品目ID
                 ,MAX( SHIP.shipped_date )                  shipped_date        --出庫日
                 ,MAX( SHIP.lot_date )                      max_lot_date        --最大製造年月日
                 ,MAX( SHIP.best_bfr_date )                 max_best_bfr_date   --最大賞味期限
            FROM
                 ( --出荷情報から対象データを抽出
                   SELECT
                           NVL( XOHA.result_deliver_to_id, XOHA.deliver_to_id )
                                                            deliver_to_id       --配送先ID
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                          ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )
                                                            deliver_to          --配送先コード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                          ,XMLD.item_id                     item_id             --品目ID
                          ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )
                                                            shipped_date        --出庫日
                          ,TO_DATE( ILM.attribute1 )        lot_date            --製造年月日
                          ,TO_DATE( ILM.attribute3 )        best_bfr_date       --賞味期限
                     FROM
                           xxcmn_order_headers_all_arc          XOHA            --受注ヘッダ（アドオン）バックアップ
                          ,oe_transaction_types_all         OTTA                --受注タイプマスタ
                          ,xxcmn_order_lines_all_arc            XOLA            --受注明細（アドオン）バックアップ
                          ,xxcmn_mov_lot_details_arc            XMLD            --移動ロット詳細（アドオン）バックアップ
                          ,ic_lots_mst                      ILM                 --ロット情報取得用
                    WHERE
                      --出荷情報抽出条件
                           OTTA.attribute1                  = '1'               --出荷
                      AND  OTTA.attribute4                  = '1'               --通常出荷(見本･廃棄出荷を含まない)
                      --受注ヘッダアドオンとの結合
                      AND  XOHA.req_status                  IN ('03', '04')     --'03:締め済'、'04:実績計上済'
                      AND  XOHA.latest_external_flag        = 'Y'
                      AND  XOHA.deliver_to_id               IS NOT NULL         --破棄のデータ等は除外
                      AND  XOHA.order_type_id               = OTTA.transaction_type_id
                      --受注明細アドオンとの結合
                      AND  NVL( XOLA.delete_flag, 'N' )    <> 'Y'               --無効明細以外
                      AND  XOHA.order_header_id             = XOLA.order_header_id
                      --移動ロット詳細アドオンとの結合
                      AND  XMLD.document_type_code          = '10'              --出荷依頼
                      AND  XMLD.record_type_code            = DECODE( XOHA.req_status
                                                                    , '04', '20'    --ステータス '04:実績計上済' の場合は '20:実績'
                                                                    , '10' )        --                         上記以外は '10:指示'
                      AND  XOLA.order_line_id               = XMLD.mov_line_id
                      --ロットマスタとの結合
                      AND  XMLD.item_id                     = ILM.item_id(+)
                      AND  XMLD.lot_id                      = ILM.lot_id(+)
                 )    SHIP
          GROUP BY
                  SHIP.deliver_to_id                        --配送先ID
-- *----------* 2009/06/23 本番#1438対応 start *----------*
                 ,SHIP.deliver_to                           --配送先コード
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
                 ,SHIP.item_id                              --品目ID
       )                           SSHP                     --各トランザクション情報
       ,xxskz_prod_class_v         XPCV                     --商品区分取得用
       ,xxskz_item_class_v         XICV                     --品目区分取得用
       ,xxskz_crowd_code_v         XCCV                     --群コード取得用
       ,xxskz_item_mst2_v          XIM2V                    --SKYLINK用中間VIEW OPM品目情報VIEW2
       ,xxskz_party_sites2_v       XPS2V                    --SKYLINK用中間VIEW 配送先情報VIEW2
 WHERE
   --品目情報取得条件
        SSHP.item_id               = XIM2V.item_id(+)
   AND  SSHP.shipped_date         >= XIM2V.start_date_active(+)
   AND  SSHP.shipped_date         <= XIM2V.end_date_active(+)
   --商品・品目・群情報取得条件
   AND  SSHP.item_id               = XPCV.item_id(+)        --商品区分
   AND  SSHP.item_id               = XICV.item_id(+)        --品目区分
   AND  SSHP.item_id               = XCCV.item_id(+)        --群コード
   --配送先名取得条件
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--   AND  SSHP.deliver_to_id         = XPS2V.party_site_id(+)
   AND  SSHP.deliver_to            = XPS2V.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
   AND  SSHP.shipped_date         >= XPS2V.start_date_active(+)
   AND  SSHP.shipped_date         <= XPS2V.end_date_active(+)
/
COMMENT ON TABLE APPS.XXSKZ_配送済みロット_基本_V IS 'SKYLINK用配送済みロットマスタ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.配送先コード IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.配送先名 IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.出庫日 IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.最大製造年月日 IS '最大製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_配送済みロット_基本_V.最大賞味期限 IS '最大賞味期限'
/
