CREATE OR REPLACE VIEW APPS.XXSKY_i¿¸Ëîñ_î{_V
(
 ¸ËNO
,¸íÊ
,¸íÊ¼
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,QR[h
,iÚR[h
,iÚ¼
,iÚªÌ
,bgNO
,æª
,æª¼
,düæR[h
,düæ¼
,CNO
,C¼
,»¢ú
,ÅLL
,Ü¡úÀ
,¸úÔ
,Ê
,[üú
,¸\èúP
,¸úP
,ÊP
,Ê¼P
,¸\èúQ
,¸úQ
,ÊQ
,Ê¼Q
,¸\èúR
,¸úR
,ÊR
,Ê¼R
,õl
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        XQI.qt_inspect_req_no                               --¸ËNo
       ,XQI.inspect_class                                   --¸íÊ
       ,CASE XQI.inspect_class                              --¸íÊ¼
            WHEN    '1' THEN    '¶Y'
            WHEN    '2' THEN    '­dü'
        END                     inspect_name
       ,XPCV.prod_class_code                                --¤iæª
       ,XPCV.prod_class_name                                --¤iæª¼
       ,XICV.item_class_code                                --iÚæª
       ,XICV.item_class_name                                --iÚæª¼
       ,XCCV.crowd_code                                     --QR[h
       ,XIM2V.item_no                                       --iÚR[h
       ,XIM2V.item_name                                     --iÚ¼
       ,XIM2V.item_short_name                               --iÚªÌ
       ,ILM.lot_no                                          --bgNo
       ,XQI.division                                        --æª
       ,CASE XQI.division                                   --æª¼
            WHEN    '1' THEN    '¶Y'
            WHEN    '2' THEN    '­'
            WHEN    '3' THEN    'bgîñ'
            WHEN    '4' THEN    'Oo'
            WHEN    '5' THEN    'r»¢'
        END                     division_name
       ,CASE XQI.division                                   --düæR[h
            WHEN    '1' THEN    NULL
            ELSE                XQI.vendor_line
        END                     vendor_line
       ,CASE XQI.division                                   --düæ¼
            WHEN    '1' THEN    NULL
            ELSE                XV2V.vendor_name
        END                     vendor_name
       ,CASE XQI.division                                   --CNo
            WHEN    '1' THEN    XQI.vendor_line
            ELSE                NULL
        END                     line_no
       ,CASE XQI.division                                   --C¼
            WHEN    '1' THEN    GRT.routing_desc
            ELSE                NULL
        END                     line_name
       ,ILM.attribute1                                      --»¢ú
       ,ILM.attribute2                                      --ÅLL
       ,ILM.attribute3                                      --Ü¡úÀ
       ,XQI.inspect_period                                  --¸úÔ
       ,XQI.qty                                             --Êú
       ,XQI.prod_dely_date                                  --[üú
       ,XQI.inspect_due_date1                               --¸\èúP
       ,XQI.test_date1                                      --¸úP
       ,XQI.qt_effect1                                      --ÊP
       ,FLV01.meaning           qt_effect_name1             --Ê¼PQ
       ,XQI.inspect_due_date2                               --¸\èúQ
       ,XQI.test_date2                                      --¸úQ
       ,XQI.qt_effect2                                      --ÊQ
       ,FLV02.meaning           qt_effect_name2             --Ê¼QR
       ,XQI.inspect_due_date3                               --¸\èúR
       ,XQI.test_date3                                      --¸úR
       ,XQI.qt_effect3                                      --ÊR
       ,FLV03.meaning           qt_effect_name3             --Ê¼R
       ,ILM.attribute18                                     --õl
       ,FU_CB.user_name         created_by_name             --CREATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XQI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --ì¬ú
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XQI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --XVú
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGINÌ[U[¼(OCÌüÍR[h)
  FROM  xxwip_qt_inspection     XQI                         --i¿¸ËîñAhI
       ,xxsky_prod_class_v      XPCV                        --SKYLINKpÔVIEW ¤iæªæ¾VIEW
       ,xxsky_item_class_v      XICV                        --SKYLINKpÔVIEW iÚ¤iæªæ¾VIEW
       ,xxsky_crowd_code_v      XCCV                        --SKYLINKpÔVIEW QR[hæ¾VIEW
       ,xxsky_item_mst2_v       XIM2V                       --SKYLINKpÔVIEW OPMiÚîñVIEW2
       ,ic_lots_mst             ILM                         --bgNoæ¾p
       ,xxsky_vendors2_v        XV2V                        --SKYLINKpÔVIEW düææ¾VIEW
       ,gmd_routings_b          GRB                         --C¼æ¾p
       ,gmd_routings_tl         GRT                         --C¼æ¾p
       ,fnd_lookup_values       FLV01                       --Ê¼Pæ¾p
       ,fnd_lookup_values       FLV02                       --Ê¼Qæ¾p
       ,fnd_lookup_values       FLV03                       --Ê¼R¼æ¾p
       ,fnd_user                FU_CB                       --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                FU_LU                       --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                FU_LL                       --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins              FL_LL                       --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
 WHERE
    --iÚR[hAiÚ¼AiÚªÌæ¾ð
        XIM2V.item_id(+)            =  XQI.item_id
   AND  XIM2V.start_date_active(+)  <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XIM2V.end_date_active(+)    >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --¤iæªA¤iæª¼æ¾ð
   AND  XPCV.item_id(+)             =  XQI.item_id
    --iÚæªAiÚæª¼æ¾ð
   AND  XICV.item_id(+)             =  XQI.item_id
    --QR[hæ¾ð
   AND  XCCV.item_id(+)             =  XQI.item_id
    --bgNoæ¾ð
   AND  ILM.item_id(+)              =  XQI.item_id
   AND  ILM.lot_id(+)               =  XQI.lot_id
    --düæ¼æ¾ð
   AND  XV2V.segment1(+)            =  XQI.vendor_line
   AND  XV2V.start_date_active(+)   <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XV2V.end_date_active(+)     >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --C¼æ¾ð
   AND  GRB.routing_no(+)           =  XQI.vendor_line
   AND  GRB.routing_vers(+)         =  1
   AND  GRT.language(+)             =  'JA'
   AND  GRT.routing_id(+)           =  GRB.routing_id
    --Ê¼Pæ¾ð
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV01.lookup_code(+)        = XQI.qt_effect1
    --Ê¼Qæ¾ð
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV02.lookup_code(+)        = XQI.qt_effect2
    --Ê¼Ræ¾ð
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV03.lookup_code(+)        = XQI.qt_effect3
   --WHOJæ¾
   AND  XQI.created_by              = FU_CB.user_id(+)
   AND  XQI.last_updated_by         = FU_LU.user_id(+)
   AND  XQI.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_i¿¸Ëîñ_î{_V IS 'SKYLINKpi¿¸Ëîñiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸ËNO IS '¸ËNo'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸íÊ IS '¸íÊ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸íÊ¼ IS '¸íÊ¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¤iæª IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¤iæª¼ IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.iÚæª IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.iÚæª¼ IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.QR[h IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.iÚR[h IS 'iÚR[h'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.iÚ¼ IS 'iÚ¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.iÚªÌ IS 'iÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.bgNO IS 'bgNo'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.æª IS 'æª'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.æª¼ IS 'æª¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.düæR[h IS 'düæR[h'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.düæ¼ IS 'düæ¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.CNO IS 'CNo'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.C¼ IS 'C¼'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.»¢ú IS '»¢ú'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÅLL IS 'ÅLL'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.Ü¡úÀ IS 'Ü¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸úÔ IS '¸úÔ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.Ê IS 'Ê'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.[üú IS '[üú'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸\èúP IS '¸\èúP'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸úP IS '¸úP'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÊP IS 'ÊP'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.Ê¼P IS 'Ê¼P'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸\èúQ IS '¸\èúQ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸úQ IS '¸úQ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÊQ IS 'ÊQ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.Ê¼Q IS 'Ê¼Q'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸\èúR IS '¸\èúR'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.¸úR IS '¸úR'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÊR IS 'ÊR'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.Ê¼R IS 'Ê¼R'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.õl IS 'õl'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ì¬Ò IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ì¬ú IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÅIXVÒ IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÅIXVú IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_i¿¸Ëîñ_î{_V.ÅIXVOC IS 'ÅIXVOC'
/
