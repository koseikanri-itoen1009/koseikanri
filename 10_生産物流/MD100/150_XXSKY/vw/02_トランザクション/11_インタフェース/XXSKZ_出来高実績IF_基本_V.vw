/*************************************************************************
 * 
 * View  Name      : XXSKZ_出来高実績IF_基本_V
 * Description     : XXSKZ_出来高実績IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出来高実績IF_基本_V
(
 プラントコード
,プラント名
,手配NO
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,出来高実績数
,受入実績日
,生産日
,製造日
,賞味期限日
)
AS
SELECT 
        XVAI.plant_code                  --プラントコード
       ,SOMT.orgn_name                   --プラント名
       ,XVAI.batch_no                    --手配No
       ,XPCV.prod_class_code             --商品区分
       ,XPCV.prod_class_name             --商品区分名
       ,XICV.item_class_code             --品目区分
       ,XICV.item_class_name             --品目区分名
       ,XCCV.crowd_code                  --群コード
       ,XVAI.item_code                   --品目コード
       ,XIM2V.item_name                  --品目名
       ,XIM2V.item_short_name            --品目略称
       ,XVAI.volume_actual_qty           --出来高実績数
       ,XVAI.rcv_date                    --受入実績日
       ,XVAI.actual_date                 --生産日
       ,XVAI.maker_date                  --製造日
       ,XVAI.expiration_date             --賞味期限日
  FROM  xxwip_volume_actual_if  XVAI     --出来高実績インタフェース
       ,sy_orgn_mst_b           SOMB     --OPMプラントマスタ
       ,sy_orgn_mst_tl          SOMT     --
       ,xxskz_prod_class_v      XPCV     --SKYLINK用中間VIEW 商品区分取得VIEW
       ,xxskz_item_class_v      XICV     --SKYLINK用中間VIEW 品目商品区分取得VIEW
       ,xxskz_crowd_code_v      XCCV     --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v       XIM2V    --SKYLINK用中間VIEW OPM品目情報VIEW2
 WHERE  XVAI.plant_code  =  SOMB.orgn_code(+)
   AND  SOMB.orgn_code   =  SOMT.orgn_code(+)
   AND  SOMT.language(+) =  'JA'
   AND  XVAI.item_code   =  XIM2V.item_no(+)
   AND  XVAI.rcv_date    >= XIM2V.start_date_active(+)
   AND  XVAI.rcv_date    <= XIM2V.end_date_active(+)
   AND  XIM2V.item_id    =  XPCV.item_id(+)
   AND  XIM2V.item_id    =  XICV.item_id(+)
   AND  XIM2V.item_id    =  XCCV.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_出来高実績IF_基本_V                 IS 'SKYLINK用出来高実績IF（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.プラントコード IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.プラント名     IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.手配NO         IS '手配No'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.商品区分       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.品目区分       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.群コード       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.品目コード     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.品目名         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.品目略称       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.出来高実績数   IS '出来高実績数'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.受入実績日     IS '受入実績日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.生産日         IS '生産日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.製造日         IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_出来高実績IF_基本_V.賞味期限日     IS '賞味期限日'
/