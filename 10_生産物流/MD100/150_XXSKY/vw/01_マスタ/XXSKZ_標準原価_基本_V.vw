/*************************************************************************
 * 
 * View  Name      : XXSKZ_標準原価_基本_V
 * Description     : XXSKZ_標準原価_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_標準原価_基本_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,倉庫コード
,倉庫名
,カレンダ
,カレンダ名
,期間
,期間名
,有効開始日
,有効終了日
,原価方法
,原価方法名
,コンポーネント区分名
,分析コード
,分析コード名
,コンポーネント原価
,確定フラグ
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT  
        XPCV.prod_class_code           --商品区分
       ,XPCV.prod_class_name           --商品区分名
       ,XICV.item_class_code           --品目区分
       ,XICV.item_class_name           --品目区分名
       ,XCCV.crowd_code                --群コード
       ,XIMV.item_no                   --品目コード
       ,XIMV.item_name                 --品目名
       ,XIMV.item_short_name           --品目略称
       ,CCD.whse_code                  --倉庫コード
       ,IWM.whse_name                  --倉庫名
       ,CCD.calendar_code              --カレンダ
       ,CCHT.calendar_desc             --カレンダ名
       ,CCD.period_code                --期間
       ,CCDD.period_desc               --期間名
       ,TRUNC( CCDD.start_date )       --有効開始日
       ,TRUNC( CCDD.end_date )         --有効終了日
       ,CCD.cost_mthd_code             --原価方法
       ,CMM.cost_mthd_desc             --原価方法名
       ,CCMT.cost_cmpntcls_desc        --コンポーネント区分名
       ,CCD.cost_analysis_code         --分析コード
       ,CAM.cost_analysis_desc         --分析コード名
       ,CCD.cmpnt_cost                 --コンポーネント原価
       ,CCD.rollover_ind               --確定フラグ
       ,FU_CB.user_name                --作成者
       ,TO_CHAR( CCD.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --作成日
       ,FU_LU.user_name                --最終更新者
       ,TO_CHAR( CCD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --最終更新日
       ,FU_LL.user_name                --最終更新ログイン
  FROM  cm_cmpt_dtl         CCD       --品目原価マスタ
       ,xxskz_prod_class_v  XPCV      --SKYLINK用 OPM品目区分VIEW(商品区分)
       ,xxskz_item_class_v  XICV      --SKYLINK用 OPM品目区分VIEW(品目区分)
       ,xxskz_crowd_code_v  XCCV      --SKYLINK用 OPM品目区分VIEW(群コード)
       ,xxskz_item_mst_v    XIMV      --OPM品目情報VIEW
       ,ic_whse_mst         IWM       --OPM倉庫マスタ
       ,cm_cldr_hdr_tl      CCHT      --カレンダ
       ,cm_cldr_dtl         CCDD      --期間
       ,cm_mthd_mst         CMM       --原価
       ,cm_cmpt_mst_tl      CCMT      --コンポーネント
       ,cm_alys_mst         CAM       --分析
       ,fnd_user            FU_CB     --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user            FU_LU     --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user            FU_LL     --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins          FL_LL     --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE  CCD.item_id = XPCV.item_id(+)
   AND  CCD.item_id = XICV.item_id(+)
   AND  CCD.item_id = XCCV.item_id(+)
   AND  CCD.item_id = XIMV.item_id(+)
   AND  CCD.whse_code = IWM.whse_code(+)
   AND  CCD.calendar_code = CCHT.calendar_code(+)
   AND  CCHT.language(+) = 'JA'
   AND  CCD.calendar_code = CCDD.calendar_code(+)
   AND  CCD.period_code   = CCDD.period_code(+)
   AND  CCD.cost_mthd_code = CMM.cost_mthd_code(+)
   AND  CCD.cost_cmpntcls_id = CCMT.cost_cmpntcls_id(+)
   AND  CCMT.language(+) = 'JA'
   AND  CCD.cost_analysis_code = CAM.cost_analysis_code(+)
   AND  CCD.created_by        = FU_CB.user_id(+)
   AND  CCD.last_updated_by   = FU_LU.user_id(+)
   AND  CCD.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_標準原価_基本_V IS 'SKYLINK用標準原価（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.商品区分             IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.商品区分名           IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.品目区分             IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.品目区分名           IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.群コード             IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.品目コード           IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.品目名               IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.品目略称             IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.倉庫コード           IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.倉庫名               IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.カレンダ             IS 'カレンダ'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.カレンダ名           IS 'カレンダ名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.期間                 IS '期間'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.期間名               IS '期間名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.有効開始日           IS '有効開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.有効終了日           IS '有効終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.原価方法             IS '原価方法'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.原価方法名           IS '原価方法名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.コンポーネント区分名 IS 'コンポーネント区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.分析コード           IS '分析コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.分析コード名         IS '分析コード名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.コンポーネント原価   IS 'コンポーネント原価'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.確定フラグ           IS '確定フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.作成者               IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.作成日               IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.最終更新者           IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.最終更新日           IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価_基本_V.最終更新ログイン     IS '最終更新ログイン'
/