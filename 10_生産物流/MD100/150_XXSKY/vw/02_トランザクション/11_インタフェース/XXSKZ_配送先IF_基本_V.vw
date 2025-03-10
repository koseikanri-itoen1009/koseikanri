/*************************************************************************
 * 
 * View  Name      : XXSKZ_zζIF_ξ{_V
 * Description     : XXSKZ_zζIF_ξ{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_zζIF_ξ{_V
(
 SEQΤ
,XVζͺ
,XVζͺΌ
,_R[h
,_Ό
,zζR[h
,zζΌP
,zζΌQ
,zζZP
,zζZQ
,dbΤ
,FAXΤ
,XΦΤ
,XΦΤQ
,ΪqR[h
,ΪqΌP
,ΪqΌQ
,γ_R[h
,γ_Ό
,_\ργ_R[h
,_\ργ_Ό
,γ`F[X
,γ`F[XΌ
,~q\ΏtO
,~q\ΏtOΌ
,Όζͺ
,ΌζͺΌ
)
AS
SELECT 
        XSI.seq_number                              --SEQΤ
       ,XSI.proc_code                               --XVζͺ
       ,CASE XSI.proc_code                          --XVζͺΌ
            WHEN    1   THEN    'o^'
            WHEN    2   THEN    'XV'
            WHEN    3   THEN    'ν'
        END                     proc_name
       ,XSI.base_code                               --_R[h
       ,XCAV01.party_name       party_name          --_Ό
       ,XSI.ship_to_code                            --zζR[h
       ,XSI.party_site_name1                        --zζΌP
       ,XSI.party_site_name2                        --zζΌQ
       ,XSI.party_site_addr1                        --zζZP
       ,XSI.party_site_addr2                        --zζZQ
       ,XSI.phone                                   --dbΤ
       ,XSI.fax                                     --FAXΤ
       ,XSI.ZIP                                     --XΦΤ
       ,XSI.ZIP2                                    --XΦΤQ
       ,XSI.party_num                               --ΪqR[h
       ,XSI.customer_name1                          --ΪqΌP
       ,XSI.customer_name2                          --ΪqΌQ
       ,XSI.sale_base_code                          --γ_R[h
       ,XCAV02.party_name       sale_base_name      --γ_Ό
       ,XSI.res_sale_base_code                      --_\ργ_R[h
       ,XCAV03.party_name       res_sale_base_name  --_\ργ_Ό
       ,XSI.chain_store                             --γ`F[X
       ,XSI.chain_store_name                        --γ`F[XΌ
       ,XSI.cal_cust_app_flg                        --~q\ΏtO
       ,FLV01.meaning                               --~q\ΏtOΌ
       ,XSI.direct_ship_code                        --Όζͺ
       ,FLV02.meaning                               --ΌζͺΌ
  FROM  xxcmn_site_if           XSI                 --zζC^tF[X
       ,xxskz_cust_accounts_v   XCAV01              --SKYLINKpΤVIEW _R[hζΎVIEW
       ,xxskz_cust_accounts_v   XCAV02              --SKYLINKpΤVIEW _R[hζΎVIEW
       ,xxskz_cust_accounts_v   XCAV03              --SKYLINKpΤVIEW _R[hζΎVIEW
       ,fnd_lookup_values       FLV01               --~q\ΏtOΌζΎp
       ,fnd_lookup_values       FLV02               --ΌζͺΌζΎp
 WHERE
   --_ΌζΎπ
        XCAV01.party_number(+)  = XSI.base_code
   --γ_ΌζΎπ
   AND  XCAV02.party_number(+)  = XSI.sale_base_code
   --_\ργ_ΌζΎπ
   AND  XCAV03.party_number(+)  = XSI.res_sale_base_code
   --~q\ΏtOΌζΎπ
   AND  FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_CUST_ENABLE_FLAG'
   AND  FLV01.lookup_code(+)    = XSI.cal_cust_app_flg
   --ΌζͺΌζΎπ
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_DROP_SHIP_DIV'
   AND  FLV02.lookup_code(+)    = XSI.direct_ship_code
/
COMMENT ON TABLE APPS.XXSKZ_zζIF_ξ{_V                             IS 'SKYLINKpzζIFiξ{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.SEQΤ                    IS 'SEQΤ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.XVζͺ                   IS 'XVζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.XVζͺΌ                 IS 'XVζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V._R[h                 IS '_R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V._Ό                     IS '_Ό'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.zζR[h               IS 'zζR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.zζΌP                 IS 'zζΌP'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.zζΌQ                 IS 'zζΌQ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.zζZP               IS 'zζZP'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.zζZQ               IS 'zζZQ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.dbΤ                   IS 'dbΤ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.FAXΤ                    IS 'FAXΤ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.XΦΤ                   IS 'XΦΤ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.XΦΤQ                 IS 'XΦΤQ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.ΪqR[h                 IS 'ΪqR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.ΪqΌP                   IS 'ΪqΌP'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.ΪqΌQ                   IS 'ΪqΌQ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.γ_R[h         IS 'γ_R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.γ_Ό             IS 'γ_Ό'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V._\ργ_R[h    IS '_\ργ_R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V._\ργ_Ό        IS '_\ργ_Ό'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.γ`F[X             IS 'γ`F[X'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.γ`F[XΌ           IS 'γ`F[XΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.~q\ΏtO           IS '~q\ΏtO'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.~q\ΏtOΌ         IS '~q\ΏtOΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.Όζͺ                   IS 'Όζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_zζIF_ξ{_V.ΌζͺΌ                 IS 'ΌζͺΌ'
/