/*************************************************************************
 * 
 * View  Name      : XXSKZ_入出庫情報_数量_V
 * Description     : XXSKZ_入出庫情報_数量_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_入出庫情報_数量_V
(
 名義コード
,名義
,伝票番号
,行番号
,事由コード
,事由コード名
,倉庫コード
,保管場所コード
,保管場所名
,保管場所略称
,部署コード
,部署名
,商品区分コード
,商品区分名
,品目区分コード
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNo
,製造年月日
,固有記号
,賞味期限
,ケース入数
,入出庫区分
,入出庫日_発日
,入出庫日_着日
,受払先コード
,受払先名
,予定実績区分
,配送先コード
,配送先名
,入庫数
,出庫数
,配送番号
)
AS
SELECT
        IWM.attribute1                                          AS cust_stc_whse          --名義コード
       ,FLV01.meaning                                           AS cust_stc_whse_name     --名義
       ,XIOT.voucher_no                                         AS voucher_no             --伝票番号
       ,XIOT.line_no                                            AS line_no                --行番号
       ,XIOT.reason_code                                        AS reason_code            --事由コード
       ,FLV02.meaning                                           AS reason_code_name       --事由コード名
       ,XIOT.whse_code                                          AS whse_code              --倉庫コード
       ,XIOT.location_code                                      AS location_code          --保管場所コード
       ,XIOT.location                                           AS location               --保管場所名
       ,XIOT.location_s_name                                    AS location_s_name        --保管場所略称
       ,XIOT.loct_code                                          AS loct_code              --部署コード
       ,XIOT.loct_name                                          AS loct_name              --部署名
       ,XPCV.prod_class_code                                    AS prod_class_code        --商品区分コード
       ,XPCV.prod_class_name                                    AS prod_class_name        --商品区分名
       ,XICV.item_class_code                                    AS item_class_code        --品目区分コード
       ,XICV.item_class_name                                    AS item_class_name        --品目区分名
       ,XCCV.crowd_code                                         AS crowd_code             --群コード
       ,XIOT.item_no                                            AS item_no                --品目コード
       ,XIOT.item_name                                          AS item_name              --品目名
       ,XIOT.item_short_name                                    AS item_short_name        --品目略称
        --ロット情報は非ロット管理品の場合表示しない
       ,NVL( DECODE( XIOT.lot_no, 'DEFAULTLOT', '0', XIOT.lot_no ), '0' )
                                                                AS lot_no                 --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.manufacture_date  --ロット管理品   →製造年月日を取得
             ELSE NULL                                         --非ロット管理品 →NULL
        END                                                     AS manufacture_date       --製造年月日
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.uniqe_sign        --ロット管理品   →固有記号を取得
             ELSE NULL                                         --非ロット管理品 →NULL
        END                                                     AS uniqe_sign             --固有記号
       ,CASE WHEN XIOT.lot_ctl = 1 THEN XIOT.expiration_date   --ロット管理品   →賞味期限
             ELSE NULL                                         --非ロット管理品 →NULL
        END                                                     AS expiration_date        --賞味期限
       ,XIOT.case_content                                       AS case_content           --ケース入数
       ,CASE WHEN XIOT.in_out_kbn = 1 THEN '入庫'              --入出庫区分コードが1:入庫
             WHEN XIOT.in_out_kbn = 2 THEN '出庫'              --入出庫区分コードが2:出庫
        END                                                     AS in_out_kbn_name        --入出庫区分
       ,XIOT.leaving_date                                       AS leaving_date           --入出庫日_発日
       ,XIOT.arrival_date                                       AS arrival_date           --入出庫日_着日
       ,XIOT.ukebaraisaki_code                                  AS ukebaraisaki_code      --受払先コード
       ,XIOT.ukebaraisaki_name                                  AS ukebaraisaki_name      --受払先名
       ,CASE WHEN XIOT.status = '1' THEN '予定'                --予定実績区分コードが1:予定
             WHEN XIOT.status = '2' THEN '実績'                --予定実績区分コードが2:実績
        END                                                     AS yojitu_kbn_name        --予定実績区分
       ,XIOT.deliver_to_no                                      AS deliver_to_no          --配送先コード
       ,XIOT.deliver_to_name                                    AS deliver_to_name        --配送先名
       ,ROUND( NVL( XIOT.stock_quantity  , 0 ), 3 )             AS stock_quantity         --入庫数
       ,ROUND( NVL( XIOT.leaving_quantity, 0 ), 3 )             AS leaving_quantity       --出庫数
       ,XIOT.delivery_no                                        AS delivery_no            --配送番号
  FROM
        xxskz_inout_trans_v           XIOT    --入出庫情報（中間VIEW）
       ,xxskz_prod_class_v            XPCV    --商品区分取得用
       ,xxskz_item_class_v            XICV    --品目区分取得用
       ,xxskz_crowd_code_v            XCCV    --群コード取得用
       ,ic_whse_mst                   IWM     --倉庫マスタ
       ,fnd_lookup_values             FLV01   --名義取得用
       ,fnd_lookup_values             FLV02   --事由コード名取得用
 WHERE
   --商品区分取得
        XIOT.item_id = XPCV.item_id(+)
   --品目区分取得
   AND  XIOT.item_id = XICV.item_id(+)
   --群コード取得
   AND  XIOT.item_id = XCCV.item_id(+)
   --倉庫情報取得
   AND  XIOT.whse_code = IWM.whse_code(+)
   --【クイックコード】名義取得
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV01.lookup_code(+) = IWM.attribute1
   --【クイックコード】事由コード名取得
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV02.lookup_code(+) = XIOT.reason_code
/
COMMENT ON TABLE APPS.XXSKZ_入出庫情報_数量_V IS 'XXSKZ_入出庫情報 (数量) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.名義コード     IS '名義コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.名義           IS '名義'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.伝票番号       IS '伝票番号'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.行番号         IS '行番号'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.事由コード     IS '事由コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.事由コード名   IS '事由コード名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.倉庫コード     IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.保管場所コード IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.保管場所名     IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.保管場所略称   IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.部署コード     IS '部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.部署名         IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.商品区分コード IS '商品区分コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.品目区分コード IS '品目区分コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.群コード       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.品目コード     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.品目名         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.品目略称       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.ロットNo       IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.製造年月日     IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.固有記号       IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.賞味期限       IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.ケース入数     IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.入出庫区分     IS '入出庫区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.入出庫日_発日  IS '入出庫日_発日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.入出庫日_着日  IS '入出庫日_着日'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.受払先コード   IS '受払先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.受払先名       IS '受払先名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.予定実績区分   IS '予定実績区分'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.配送先コード   IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.配送先名       IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.入庫数         IS '入庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.出庫数         IS '出庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_入出庫情報_数量_V.配送番号       IS '配送番号'
/
