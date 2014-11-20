/*************************************************************************
 * 
 * View  Name      : XXSKZ_受入実績IF_基本_V
 * Description     : XXSKZ_受入実績IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_受入実績IF_基本_V
(
元文書番号
,取引先コード
,取引先名
,納入日
,納入先コード
,納入先名
,元文書明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名称
,品目略称
,ロットNO
,製造日
,固有記号
,指示数量
,明細摘要
,受入日
,受入数量
,単位コード
,受入明細摘要
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        XRTI.source_document_number      --元文書番号
       ,XRTI.vendor_code                 --取引先コード
       ,XRTI.vendor_name                 --取引先名
       ,XRTI.promised_date               --納入日
       ,XRTI.location_code               --納入先コード
       ,XRTI.location_name               --納入先名
       ,XRTI.source_document_line_num    --元文書明細番号
       ,XPCV.prod_class_code             --商品区分
       ,XPCV.prod_class_name             --商品区分名
       ,XICV.item_class_code             --品目区分
       ,XICV.item_class_name             --品目区分名
       ,XCCV.crowd_code                  --群コード
       ,XRTI.item_code                   --品目コード
       ,XRTI.item_name                   --品目名称
       ,XIM2V.item_short_name            --品目略称
       ,XRTI.lot_number                  --ロットNo
       ,XRTI.producted_date              --製造日
       ,XRTI.koyu_code                   --固有記号
       ,XRTI.quantity                    --指示数量
       ,XRTI.po_line_description         --明細摘要
       ,XRTI.rcv_date                    --受入日
       ,XRTI.rcv_quantity                --受入数量
       ,XRTI.rcv_quantity_uom            --単位コード
       ,XRTI.rcv_line_description        --受入明細摘要
       ,FU_CB.user_name                  --作成者
       ,TO_CHAR( XRTI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --作成日
       ,FU_LU.user_name                  --最終更新者
       ,TO_CHAR( XRTI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --最終更新日
       ,FU_LL.user_name                  --最終更新ログイン
  FROM  xxpo_rcv_txns_interface XRTI     --受入実績インターフェース
       ,xxskz_prod_class_v      XPCV     --SKYLINK用中間VIEW OPM品目区分VIEW(商品区分)
       ,xxskz_item_class_v      XICV     --SKYLINK用中間VIEW OPM品目区分VIEW(品目区分)
       ,xxskz_crowd_code_v      XCCV     --SKYLINK用中間VIEW OPM品目区分VIEW(群コード)
       ,xxskz_item_mst2_v       XIM2V    --SKYLINK用中間VIEW OPM品目情報VIEW2(品目名)
       ,fnd_user                FU_CB    --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                FU_LU    --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                FU_LL    --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins              FL_LL    --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  XRTI.item_code             = XIM2V.item_no(+)
   AND  XIM2V.start_date_active(+) <= XRTI.promised_date
   AND  XIM2V.end_date_active(+)   >= XRTI.promised_date
   AND  XIM2V.item_id              = XPCV.item_id(+)
   AND  XIM2V.item_id              = XICV.item_id(+)
   AND  XIM2V.item_id              = XCCV.item_id(+)
   AND  XRTI.created_by            = FU_CB.user_id(+)
   AND  XRTI.last_updated_by       = FU_LU.user_id(+)
   AND  XRTI.last_update_login     = FL_LL.login_id(+)
   AND  FL_LL.user_id              = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_受入実績IF_基本_V IS 'SKYLINK用受入実績インターフェース（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.元文書番号       IS '元文書番号'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.取引先コード     IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.取引先名         IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.納入日           IS '納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.納入先コード     IS '納入先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.納入先名         IS '納入先名'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.元文書明細番号   IS '元文書明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.品目名称         IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.ロットNO         IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.製造日           IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.固有記号         IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.指示数量         IS '指示数量'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.明細摘要         IS '明細摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.受入日           IS '受入日'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.受入数量         IS '受入数量'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.単位コード       IS '単位コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.受入明細摘要     IS '受入明細摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_受入実績IF_基本_V.最終更新ログイン IS '最終更新ログイン'
/
