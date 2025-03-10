/*************************************************************************
 * 
 * View  Name      : XXSKZ__IF_ξ{_V
 * Description     : XXSKZ__IF_ξ{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ__IF_ξ{_V
(
 SEQΤ
,XVζͺ
,XVζͺΌ
,_R[h
,_Ό
,_ͺΜ
,_JiΌ
,Z
,XΦΤ
,XΦΤQ
,dbΤ
,FAXΤ
,_{R[h
,V_{R[h
,{_KpJnϊ
,_ΐΡL³ζͺ
,_ΐΡL³ζͺΌ
,oΙΗ³ζͺ
,oΙΗ³ζͺΌ
,{_nζΌ
,qΦΞΫΒΫζͺ
,qΦΞΫΒΫζͺΌ
,[L³ζͺ
,[L³ζͺΌ
,\υ
)
AS
SELECT 
        XPI.seq_number                      --SEQΤ
       ,XPI.proc_code                       --XVζͺ
       ,CASE XPI.proc_code                  --XVζͺΌ
            WHEN    1   THEN    'o^'
            WHEN    2   THEN    'XV'
            WHEN    3   THEN    'ν'
        END                     proc_name
       ,XPI.base_code                       --_R[h
       ,XPI.party_name                      --_Ό
       ,XPI.party_short_name                --_ͺΜ
       ,XPI.party_name_alt                  --_JiΌ
       ,XPI.address                         --Z
       ,XPI.ZIP                             --XΦΤ
       ,XPI.ZIP2                            --XΦΤQ
       ,XPI.phone                           --dbΤ
       ,XPI.fax                             --FAXΤ
       ,XPI.old_division_code               --_{R[h
       ,XPI.new_division_code               --V_{R[h
       ,XPI.division_start_date             --{_KpJnϊ
       ,XPI.location_rel_code               --_ΐΡL³ζͺ
       ,FLV01.meaning                       --_ΐΡL³ζͺΌ
       ,XPI.ship_mng_code                   --oΙΗ³ζͺ
       ,FLV02.meaning                       --oΙΗ³ζͺΌ
       ,XPI.district_code                   --{_nζΌ
       ,XPI.warehouse_code                  --qΦΞΫΒΫζͺ
       ,FLV03.meaning                       --qΦΞΫΒΫζͺΌ
       ,XPI.terminal_code                   --[L³ζͺ
       ,CASE XPI.terminal_code              --[L³ζͺΌ
            WHEN    '0' THEN    '³'
            WHEN    '1' THEN    'L'
        END                 terminal_name
       ,XPI.spare                           --\υ
  FROM  xxcmn_party_if      XPI             --_C^tF[X
       ,fnd_lookup_values   FLV01           --_ΐΡL³ζͺΌζΎp
       ,fnd_lookup_values   FLV02           --oΙΗ³ζͺΌζΎp
       ,fnd_lookup_values   FLV03           --qΦΞΫΒΫζͺΌζΎp
 WHERE
   --_ΐΡL³ζͺΌζΎπ
        FLV01.language(+)       = 'JA'
   AND  FLV01.lookup_type(+)    = 'XXCMN_BASE_RESULTS_CLASS'
   AND  FLV01.lookup_code(+)    = XPI.location_rel_code
   --oΙΗ³ζͺΌζΎπ
   AND  FLV02.language(+)       = 'JA'
   AND  FLV02.lookup_type(+)    = 'XXCMN_SHIPMENT_MANAGEMENT'
   AND  FLV02.lookup_code(+)    = XPI.ship_mng_code
   --qΦΞΫΒΫζͺΌζΎπ
   AND  FLV03.language(+)       = 'JA'
   AND  FLV03.lookup_type(+)    = 'XXCMN_INV_OBJEC_CLASS'
   AND  FLV03.lookup_code(+)    = XPI.warehouse_code
/
COMMENT ON TABLE APPS.XXSKZ__IF_ξ{_V                       IS 'SKYLINKp_IFiξ{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.SEQΤ              IS 'SEQΤ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.XVζͺ             IS 'XVζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.XVζͺΌ           IS 'XVζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._R[h           IS '_R[h'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._Ό               IS '_Ό'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._ͺΜ             IS '_ͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._JiΌ           IS '_JiΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.Z                 IS 'Z'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.XΦΤ             IS 'XΦΤ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.XΦΤQ           IS 'XΦΤQ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.dbΤ             IS 'dbΤ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.FAXΤ              IS 'FAXΤ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._{R[h        IS '_{R[h'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.V_{R[h        IS 'V_{R[h'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.{_KpJnϊ      IS '{_KpJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._ΐΡL³ζͺ     IS '_ΐΡL³ζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V._ΐΡL³ζͺΌ   IS '_ΐΡL³ζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.oΙΗ³ζͺ       IS 'oΙΗ³ζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.oΙΗ³ζͺΌ     IS 'oΙΗ³ζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.{_nζΌ          IS '{_nζΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.qΦΞΫΒΫζͺ     IS 'qΦΞΫΒΫζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.qΦΞΫΒΫζͺΌ   IS 'qΦΞΫΒΫζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.[L³ζͺ         IS '[L³ζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.[L³ζͺΌ       IS '[L³ζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ__IF_ξ{_V.\υ                 IS '\υ'
/