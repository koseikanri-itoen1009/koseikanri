/*************************************************************************
 * 
 * View  Name      : XXSKZ_iΪIF_ξ{_V
 * Description     : XXSKZ_iΪIF_ξ{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_iΪIF_ξ{_V
(
SEQΤ
,XVζͺ
,XVζͺΌ
,iΪR[h
,iΪΌ
,iΌͺΜ
,iΌJiΌ
,_QR[h
,V_QR[h
,QR[h_KpJnϊ
,­τQR[h
,}[PpQR[h
,_θΏ
,V_θΏ
,θΏ_KpJnϊ
,_W΄Ώ
,V_W΄Ώ
,W΄Ώ_KpJnϊ
,_cΖ΄Ώ
,V_cΖ΄Ώ
,cΖ΄Ώ_KpJnϊ
,_ΑοΕ¦
,V_ΑοΕ¦
,ΑοΕ¦_KpJnϊ
,¦ζͺ
,¦ζͺΌ
,P[Xό
,€i»iζͺ
,€i»iζͺΌ
,NET
,dΚ_ΜΟ
,€iζͺ
,€iζͺΌ
,oζͺ
,oζͺΌ
,eiΌR[h
,eiΌR[hΌ
,eiΌR[hͺΜ
,γΞΫζͺ
,γΞΫζͺΌ
,JANR[h
,­»’Jnϊ
,p~ζͺ
,p~ζͺΌ
,p~_»’~ϊ
,΄ΏgpΚ
,΄Ώ
,Δ»ο
,ήο
,οο
,OΗο
,ΫΗο
,»ΜΌoο
,\υ
,\υP
,\υQ
,\υR
)
AS
SELECT
 XII.seq_number                      --SEQΤ
,XII.proc_code                       --XVζͺ
,CASE XII.proc_code                  --XVζͺΌ
    WHEN 1 THEN 'o^'
    WHEN 2 THEN 'XV'
    WHEN 3 THEN 'ν'
 END                                 --XVζͺΌ
,XII.item_code                       --iΪR[h
,XII.item_name                       --iΪΌ
,XII.item_short_name                 --iΌͺΜ
,XII.item_name_alt                   --iΌJiΌ
,XII.old_crowd_code                  --_QR[h
,XII.new_crowd_code                  --V_QR[h
,XII.crowd_start_date                --QR[h_KpJnϊ
,XII.policy_group_code               --­τQR[h
,XII.marke_crowd_code                --}[PpQR[h
,NVL( TO_NUMBER( XII.old_price ), 0 )
                                     --_θΏ
,NVL( TO_NUMBER( XII.new_price ), 0 )
                                     --V_θΏ
,XII.price_start_date                --θΏ_KpJnϊ
,NVL( TO_NUMBER( XII.old_standard_cost ), 0 )
                                     --_W΄Ώ
,NVL( TO_NUMBER( XII.new_standard_cost ), 0 )
                                     --V_W΄Ώ
,XII.standard_start_date             --W΄Ώ_KpJnϊ
,NVL( TO_NUMBER( XII.old_business_cost ), 0 )
                                     --_cΖ΄Ώ
,NVL( TO_NUMBER( XII.new_business_cost ), 0 )
                                     --V_cΖ΄Ώ
,XII.business_start_date             --cΖ΄Ώ_KpJnϊ
,NVL( TO_NUMBER( XII.old_tax ), 0 )  --_ΑοΕ¦
,NVL( TO_NUMBER( XII.new_tax ), 0 )  --V_ΑοΕ¦
,XII.tax_start_date                  --ΑοΕ¦_KpJnϊ
,XII.rate_code                       --¦ζͺ
,FLV_RIT.meaning                     --¦ζͺΌ
,NVL( TO_NUMBER( XII.case_num ), 0 ) --P[Xό
,XII.product_div_code                --€i»iζͺ
,FLV_SSK.meaning                     --€i»iζͺΌ
,NVL( TO_NUMBER( XII.net ), 0 )      --NET
,NVL( TO_NUMBER( XII.weight_volume ), 0 )
                                     --dΚ_ΜΟ
,XII.arti_div_code                   --€iζͺ
,FLV_SK.meaning                      --€iζͺΌ
,XII.div_tea_code                    --oζͺ
,FLV_BAR.meaning                     --oζͺΌ
,XII.parent_item_code                --eiΌR[h
,XIMV.item_name                      --eiΌR[hΌ
,XIMV.item_short_name                --eiΌR[hͺΜ
,XII.sale_obj_code                   --γΞΫζͺ
,FLV_URI.meaning                     --γΞΫζͺΌ
,XII.jan_code                        --JANR[h
,XII.sale_start_date                 --­»’Jnϊ
,XII.abolition_code                  --p~ζͺ
,CASE XII.abolition_code             --p~ζͺΌ
    WHEN '0' THEN 'ζ΅'
    WHEN '1' THEN 'p~'
 END
,XII.abolition_date                  --p~_»’~ϊ
,NVL( TO_NUMBER( XII.raw_mate_consumption ), 0 )
                                     --΄ΏgpΚ
,NVL( TO_NUMBER( XII.raw_material_cost ), 0 )
                                     --΄Ώ
,NVL( TO_NUMBER( XII.agein_cost ), 0 )
                                     --Δ»ο
,NVL( TO_NUMBER( XII.material_cost ), 0 )
                                     --ήο
,NVL( TO_NUMBER( XII.pack_cost ), 0 )
                                     --οο
,NVL( TO_NUMBER( XII.out_order_cost ), 0 )
                                     --OΗο
,NVL( TO_NUMBER( XII.safekeep_cost ), 0 )
                                     --ΫΗο
,NVL( TO_NUMBER( XII.other_expense_cost ), 0 )
                                     --»ΜΌoο
,NVL( TO_NUMBER( XII.spare ), 0 )
                                     --\υ
,NVL( TO_NUMBER( XII.spare1 ), 0 )
                                     --\υP
,NVL( TO_NUMBER( XII.spare2 ), 0 )
                                     --\υQ
,NVL( TO_NUMBER( XII.spare3 ), 0 )
                                     --\υR
FROM    xxcmn_item_if       XII      --iΪC^tF[X_V
       ,xxskz_item_mst2_v   XIMV     --eiΪΌζΎp
       ,fnd_lookup_values   FLV_RIT  --¦ζͺΌζΎ
       ,fnd_lookup_values   FLV_SSK  --€i»iζͺΌζΎ
       ,fnd_lookup_values   FLV_SK   --€iζͺΌζΎ
       ,fnd_lookup_values   FLV_BAR  --oζͺΌζΎ
       ,fnd_lookup_values   FLV_URI  --γΞΫζͺΌζΎ
WHERE
    XII.parent_item_code = XIMV.item_no(+)      --eiΪΌζΎp
AND XIMV.start_date_active(+) <= NVL(XII.sale_start_date,SYSDATE)
AND XIMV.end_date_active(+)   >= NVL(XII.sale_start_date,SYSDATE)
AND FLV_RIT.language(+) = 'JA'                  --¦ζͺΌζΎp
AND FLV_RIT.lookup_type(+) = 'XXCMN_RATE'
AND FLV_RIT.lookup_code(+) = XII.rate_code
AND FLV_SSK.language(+) = 'JA'                  --€i»iζͺΌζΎp
AND FLV_SSK.lookup_type(+) = 'XXCMN_PRODUCT_OR_NOT'
AND FLV_SSK.lookup_code(+) = XII.product_div_code
AND FLV_SK.language(+) = 'JA'                   --€iζͺΌζΎp
AND FLV_SK.lookup_type(+) = 'XXWIP_ITEM_TYPE'
AND FLV_SK.lookup_code(+) = XII.arti_div_code
AND FLV_BAR.language(+) = 'JA'                  --oζͺΌζΎp
AND FLV_BAR.lookup_type(+) = 'XXCMN_BARACHA'
AND FLV_BAR.lookup_code(+) = XII.div_tea_code
AND FLV_URI.language(+) = 'JA'                  --γΞΫζͺΌζΎp
AND FLV_URI.lookup_type(+) = 'XXCMN_SALES_TARGET_CLASS'
AND FLV_URI.lookup_code(+) = XII.sale_obj_code
/
COMMENT ON TABLE APPS.XXSKZ_iΪIF_ξ{_V IS 'XXSKZ_iΪIF (ξ{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.SEQΤ               IS 'SEQΤ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.XVζͺ              IS 'XVζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.XVζͺΌ            IS 'XVζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.iΪR[h            IS 'iΪR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.iΪΌ                IS 'iΪΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.iΌͺΜ              IS 'iΌͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.iΌJiΌ            IS 'iΌJiΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V._QR[h           IS '_QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.V_QR[h           IS 'V_QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.QR[h_KpJnϊ   IS 'QR[h_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.­τQR[h          IS '­τQR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.}[PpQR[h      IS '}[PpQR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V._θΏ               IS '_θΏ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.V_θΏ               IS 'V_θΏ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.θΏ_KpJnϊ       IS 'θΏ_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V._W΄Ώ           IS '_W΄Ώ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.V_W΄Ώ           IS 'V_W΄Ώ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.W΄Ώ_KpJnϊ   IS 'W΄Ώ_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V._cΖ΄Ώ           IS '_cΖ΄Ώ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.V_cΖ΄Ώ           IS 'V_cΖ΄Ώ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.cΖ΄Ώ_KpJnϊ   IS 'cΖ΄Ώ_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V._ΑοΕ¦           IS '_ΑοΕ¦'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.V_ΑοΕ¦           IS 'V_ΑοΕ¦'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.ΑοΕ¦_KpJnϊ   IS 'ΑοΕ¦_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.¦ζͺ                IS '¦ζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.¦ζͺΌ              IS '¦ζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.P[Xό            IS 'P[Xό'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.€i»iζͺ          IS '€i»iζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.€i»iζͺΌ        IS '€i»iζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.NET                   IS 'NET'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.dΚ_ΜΟ             IS 'dΚ_ΜΟ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.€iζͺ              IS '€iζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.€iζͺΌ            IS '€iζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.oζͺ            IS 'oζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.oζͺΌ          IS 'oζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.eiΌR[h          IS 'eiΌR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.eiΌR[hΌ        IS 'eiΌR[hΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.eiΌR[hͺΜ      IS 'eiΌR[hͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.γΞΫζͺ          IS 'γΞΫζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.γΞΫζͺΌ        IS 'γΞΫζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.JANR[h             IS 'JANR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.­»’Jnϊ        IS '­»’Jnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.p~ζͺ              IS 'p~ζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.p~ζͺΌ            IS 'p~ζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.p~_»’~ϊ       IS 'p~_»’~ϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.΄ΏgpΚ            IS '΄ΏgpΚ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.΄Ώ                  IS '΄Ώ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.Δ»ο                IS 'Δ»ο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.ήο                IS 'ήο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.οο                IS 'οο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.OΗο            IS 'OΗο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.ΫΗο                IS 'ΫΗο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.»ΜΌoο            IS '»ΜΌoο'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.\υ                  IS '\υ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.\υP                IS '\υP'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.\υQ                IS '\υQ'
/
COMMENT ON COLUMN APPS.XXSKZ_iΪIF_ξ{_V.\υR                IS '\υR'
/
