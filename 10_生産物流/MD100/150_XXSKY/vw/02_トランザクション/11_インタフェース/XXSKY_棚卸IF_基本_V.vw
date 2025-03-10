CREATE OR REPLACE VIEW APPS.XXSKY_IµIF_î{_V
(
ñ
,ñ¼
,Iµú
,IµqÉ
,IµqÉ¼
,IµAÔ
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,QR[h
,iÚ
,iÚ¼
,iÚªÌ
,bgNO
,»¢ú
,Ü¡úÀ
,ÅLL
,IµP[X
,ü
,Iµo
,P[V
,bNNOP
,bNNOQ
,bNNOR
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
         XSII.report_post_code                  --ñ
        ,XL2V.location_name                     --ñ¼
        ,XSII.invent_date                       --Iµú
        ,XSII.invent_whse_code                  --IµqÉ
        ,IWM.whse_name                          --IµqÉ¼
        ,XSII.invent_seq                        --IµAÔ
        ,XPCV.prod_class_code                   --¤iæª
        ,XPCV.prod_class_name                   --¤iæª¼
        ,XICV.item_class_code                   --iÚæª
        ,XICV.item_class_name                   --iÚæª¼
        ,XCCV.crowd_code                        --QR[h
        ,XSII.item_code                         --iÚ
        ,XIM2V.item_name                        --iÚ¼
        ,XIM2V.item_short_name                  --iÚªÌ
        ,XSII.lot_no                            --bgNo
        ,XSII.maker_date                        --»¢ú
        ,XSII.limit_date                        --Ü¡úÀ
        ,XSII.proper_mark                       --ÅLL
        ,XSII.case_amt                          --IµP[X
        ,XSII.content                           --ü
        ,XSII.loose_amt                         --Iµo
        ,XSII.location                          --P[V
        ,XSII.rack_no1                          --bNNo1
        ,XSII.rack_no2                          --bNNo2
        ,XSII.rack_no3                          --bNNo3
        ,FU_CB.user_name                        --ì¬Ò
        ,TO_CHAR( XSII.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --ì¬ú
        ,FU_LU.user_name                        --ÅIXVÒ
        ,TO_CHAR( XSII.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --ÅIXVú
        ,FU_LL.user_name                        --ÅIXVOC
  FROM   xxinv_stc_inventory_interface  XSII    --IµC^tF[Xe[u(AhI)
        ,xxsky_locations2_v             XL2V    --SKYLINKpÔVIEW ÆîñVIEW2(¼)
        ,ic_whse_mst                    IWM     --qÉ}X^(qÉ¼)
        ,xxsky_prod_class_v             XPCV    --SKYLINKpÔVIEW OPMiÚæªVIEW(¤iæª)
        ,xxsky_item_class_v             XICV    --SKYLINKpÔVIEW OPMiÚæªVIEW(iÚæª)
        ,xxsky_crowd_code_v             XCCV    --SKYLINKpÔVIEW OPMiÚæªVIEW(QR[h)
        ,xxsky_item_mst2_v              XIM2V   --SKYLINKpÔVIEW OPMiÚîñVIEW2(iÚ¼)
        ,fnd_user                       FU_CB   --[U[}X^(CREATED_BY¼Ìæ¾p)
        ,fnd_user                       FU_LU   --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
        ,fnd_user                       FU_LL   --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
        ,fnd_logins                     FL_LL   --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
 WHERE  XSII.report_post_code           = XL2V.location_code(+)
   AND  XL2V.start_date_active(+)       <= XSII.invent_date
   AND  XL2V.end_date_active(+)         >= XSII.invent_date
   AND  XSII.invent_whse_code           = IWM.whse_code(+)
   AND  XSII.item_code                  = XIM2V.item_no(+)
   AND  XIM2V.start_date_active(+)      <= XSII.invent_date
   AND  XIM2V.end_date_active(+)        >= XSII.invent_date
   AND  XIM2V.item_id                   = XPCV.item_id(+)
   AND  XIM2V.item_id                   = XICV.item_id(+)
   AND  XIM2V.item_id                   = XCCV.item_id(+)
   AND  XSII.created_by                 = FU_CB.user_id(+)
   AND  XSII.last_updated_by            = FU_LU.user_id(+)
   AND  XSII.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_IµIF_î{_V IS 'SKYLINKpIµC^[tF[Xiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ñ     IS 'ñ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ñ¼   IS 'ñ¼'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.Iµú       IS 'Iµú'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.IµqÉ     IS 'IµqÉ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.IµqÉ¼   IS 'IµqÉ¼'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.IµAÔ     IS 'IµAÔ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.¤iæª     IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.¤iæª¼   IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.iÚæª     IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.iÚæª¼   IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.QR[h     IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.iÚ         IS 'iÚ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.iÚ¼       IS 'iÚ¼'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.iÚªÌ     IS 'iÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.bgNO     IS 'bgNo'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.»¢ú       IS '»¢ú'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.Ü¡úÀ     IS 'Ü¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ÅLL     IS 'ÅLL'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.IµP[X IS 'IµP[X'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ü         IS 'ü'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.Iµo     IS 'Iµo'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.P[V IS 'P[V'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.bNNOP   IS 'bNNoP'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.bNNOQ   IS 'bNNoQ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.bNNOR   IS 'bNNoR'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ì¬Ò       IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ì¬ú       IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ÅIXVÒ   IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ÅIXVú   IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_IµIF_î{_V.ÅIXVOC     IS 'ÅIXVOC'
/
