CREATE OR REPLACE VIEW APPS.XXSKY_o×Ë÷ß_î{_V
(
 ÷ßRJgID
,ó^Cv
,o×³ÛÇê
,o×³ÛÇê¼
,¤iæª
,¤iæª¼
,_
,_¼
,_JeS
,_JeS¼
,¶Y¨¬LT
,o×\èú
,÷ß_ðæª
,÷ß_ðæª¼
,÷ßÀ{ú
,îR[hæª
,îR[hæª¼
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT 
        XTC.concurrent_id                                       --÷ßRJgID
       ,CASE XTC.order_type_id                                  --ó^Cv
            WHEN    -999    THEN    'ALL'
            ELSE                    OTTT.name
        END                         transaction_type_name
       ,XTC.deliver_from                                        --o×³ÛÇê
       ,XILV.description            deliver_from_name           --o×³ÛÇê¼
       ,XTC.prod_class                                          --¤iæª
       ,FLV01.meaning               prod_class_name             --¤iæª¼
       ,XTC.sales_branch                                        --_
       ,XCA2V.party_name            sales_branch_name           --_¼
       ,XTC.sales_branch_category                               --_JeS
       ,FLV02.meaning               sales_branch_category_name  --_JeS¼
       ,CASE XTC.lead_time_day                                  --ó^Cv
            WHEN    -999    THEN    'ALL'                       --¶Y¨¬LT
            ELSE                    TO_CHAR(XTC.lead_time_day, 'FM9999')
        END                         lead_time_day
       ,XTC.schedule_ship_date                                  --o×\èú
       ,XTC.tighten_release_class                               --÷ß_ðæª
       ,FLV03.meaning               tighten_release_class_name  --÷ß_ðæª¼
       ,TO_CHAR( XTC.tightening_date, 'YYYY/MM/DD HH24:MI:SS')
                                                                --÷ßÀ{ú
       ,XTC.base_record_class                                   --îR[hæª
       ,CASE XTC.base_record_class                              --îR[hæª¼
            WHEN    'Y' THEN    'îR[h'
            WHEN    'N' THEN    '»êÈO'
        END                         base_record_class_name
       ,FU_CB.user_name             created_by_name             --CREATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XTC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                    creation_date               --ì¬ú
       ,FU_LU.user_name             last_updated_by_name        --LAST_UPDATED_BYÌ[U[¼(OCÌüÍR[h)
       ,TO_CHAR( XTC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                    last_update_date            --XVú
       ,FU_LL.user_name             last_update_login_name      --LAST_UPDATE_LOGINÌ[U[¼(OCÌüÍR[h)
  FROM  xxwsh_tightening_control    XTC                         --o×Ë÷ßÇiAhIj
       ,oe_transaction_types_tl     OTTT                        --ó^Cv¼æ¾p
       ,xxsky_item_locations_v      XILV                        --SKYLINKpÔVIEW o×³ÛÇê¼æ¾VIEW
       ,xxsky_cust_accounts2_v      XCA2V                       --SKYLINKpÔVIEW _¼æ¾VIEW
       ,fnd_lookup_values           FLV01                       --¤iæª¼æ¾p
       ,fnd_lookup_values           FLV02                       --_JeS¼æ¾p
       ,fnd_lookup_values           FLV03                       --÷ß_ðæª¼æ¾p
       ,fnd_user                    FU_CB                       --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                    FU_LU                       --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                    FU_LL                       --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins                  FL_LL                       --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
 WHERE
    --ó^Cv¼(oÉ`Ô)æ¾ð
        OTTT.language(+)            = 'JA'
   AND  OTTT.transaction_type_id(+) =  XTC.order_type_id
    --o×³ÛÇê¼æ¾ð
   AND  XILV.segment1(+)            =  XTC.deliver_from
    --_¼æ¾ð
   AND  XCA2V.party_number(+)       =  XTC.sales_branch
   AND  XCA2V.start_date_active(+)  <= XTC.tightening_date
   AND  XCA2V.end_date_active(+)    >= XTC.tightening_date
    --¤iæª¼æ¾ð
   AND  FLV01.language(+)           =  'JA'
   AND  FLV01.lookup_type(+)        =  'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        =  XTC.prod_class
   --_JeS¼æ¾ð
   AND  FLV02.language(+)           =  'JA'
   AND  FLV02.lookup_type(+)        =  'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV02.lookup_code(+)        =  XTC.sales_branch_category
    --÷ß_ðæª¼æ¾ð
   AND  FLV03.language(+)           =  'JA'
   AND  FLV03.lookup_type(+)        =  'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV03.lookup_code(+)        =  XTC.tighten_release_class
   --WHOJæ¾
   AND  XTC.created_by              =  FU_CB.user_id(+)
   AND  XTC.last_updated_by         =  FU_LU.user_id(+)
   AND  XTC.last_update_login       =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_o×Ë÷ß_î{_V                     IS 'SKYLINKpo×Ë÷ßiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.÷ßRJgID IS '÷ßRJgID'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ó^Cv         IS 'ó^Cv'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.o×³ÛÇê     IS 'o×³ÛÇê'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.o×³ÛÇê¼   IS 'o×³ÛÇê¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.¤iæª           IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.¤iæª¼         IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V._               IS '_'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V._¼             IS '_¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V._JeS       IS '_JeS'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V._JeS¼     IS '_JeS¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.¶Y¨¬LT         IS '¶Y¨¬LT'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.o×\èú         IS 'o×\èú'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.÷ß_ðæª      IS '÷ß_ðæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.÷ß_ðæª¼    IS '÷ß_ðæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.÷ßÀ{ú       IS '÷ßÀ{ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.îR[hæª   IS 'îR[hæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.îR[hæª¼ IS 'îR[hæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ì¬Ò             IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ì¬ú             IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ÅIXVÒ         IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ÅIXVú         IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_o×Ë÷ß_î{_V.ÅIXVOC   IS 'ÅIXVOC'
/                                                                       
