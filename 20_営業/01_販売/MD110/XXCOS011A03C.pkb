CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (body)
 * Description      : [i\èf[^Ìì¬ðs¤
 * MD.050           : [i\èf[^ì¬ (MD050_COS_011_A03)
 * Version          : 1.33
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_param            p[^`FbN(A-1)
 *  init                   ú(A-2)
 *  get_manual_order       èüÍf[^o^(A-3)
 *  output_header          t@Cú(A-4)
 *  input_edi_order        EDIóîño(A-5)
 *  format_data            f[^¬`(A-7)
 *  edit_data              f[^ÒW(A-6)
 *  output_data            t@CoÍ(A-8)
 *  output_footer          t@CI¹(A-9)
 *  update_edi_order       EDIóîñXV(A-10)
 *  generate_edi_trans     EDI[i\èMt@Cì¬(A-3...A-10)
 *  release_edi_trans      EDI[i\èMÏÝð(A-12)
 *  submain                CvV[W
 *  main                   RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Fujimoto       VKì¬
 *  2009/02/20    1.1   H.Fujimoto       sïNo.106
 *  2009/02/24    1.2   H.Fujimoto       sïNo.126,134
 *  2009/02/25    1.3   H.Fujimoto       sïNo.135
 *  2009/02/25    1.4   H.Fujimoto       sïNo.141
 *  2009/02/27    1.5   H.Fujimoto       sïNo.146,149
 *  2009/03/04    1.6   H.Fujimoto       sïNo.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]R[h·ÏXÎ
 *  2009/05/12    1.8   K.Kiriu          [T1_0677]xì¬Î
 *                                       [T1_0937]íÌJEgÎ
 *  2009/05/22    1.9   M.Sano           [T1_1073]_~[iÚÌÊÚÏXÎ
 *  2009/06/11    1.10  T.Kitajima       [T1_1348]sNoÌðÏX
 *  2009/06/12    1.10  T.Kitajima       [T1_1350]CJ[\\[gðÏX
 *  2009/06/12    1.10  T.Kitajima       [T1_1356]t@CNo¨ÚqAhI.EDI`ÇÔ
 *  2009/06/12    1.10  T.Kitajima       [T1_1357]`[Ôl`FbN
 *  2009/06/12    1.10  T.Kitajima       [T1_1358]èÔÁæª0¨00,1¨01,2¨02
 *  2009/06/19    1.10  T.Kitajima       [T1_1436]óf[^AcÆPÊiÝÇÁ
 *  2009/06/24    1.10  T.Kitajima       [T1_1359]Ê·ZÎ
 *  2009/07/08    1.10  M.Sano           [T1_1357]r[wEÎ
 *  2009/07/10    1.10  N.Maeda          [000063]îñæªÉæéf[^ì¬ÎÛÌ§äÇÁ
 *                                       [000064]óDFFÚÇÁÉº¤AAgÚÇÁ
 *  2009/07/13    1.10  N.Maeda          [T1_1359]r[wEÎ
 *  2009/07/21    1.11  K.Kiriu          [0000644]´¿àzÌ[Î
 *  2009/07/24    1.11  K.Kiriu          [T1_1359]r[wEÎ
 *  2009/08/10    1.11  K.Kiriu          [0000438]wEÎ
 *  2009/09/03    1.12  N.Maeda          [0001065]wXXCOS_HEAD_PROD_CLASS_VxÌMainSQLæ
 *  2009/09/25    1.13  N.Maeda          [0001306]`[vWvPÊC³
 *                                       [0001307]o×Êæ¾³e[uC³
 *  2009/10/05    1.14  N.Maeda          [0001464]ó¾×ªÉæée¿Î
 *  2010/03/01    1.15  S.Karikomi       [E_{Ò­_01635]wb_oÍ_C³
 *                                                       JEgPÊÌ¯úÎ
 *  2010/03/09    1.16  S.Karikomi       [E_{Ò­_01637]P¿A¿àzC³
 *  2010/03/11    1.17  S.Karikomi       [E_{Ò­_01848][iúÏXÎ
 *  2010/03/18    1.18  S.Karikomi       [E_{Ò­_01903]P¿A¿àzæ¾æC³
 *                                                       ÎÛ0ÌXe[^XÏXÎ
 *  2010/03/19    1.19  S.Karikomi       [E_{Ò®_01867][iSÒæ¾ÏXÎ
 *  2010/04/15    1.20  N.Abe            [E_{Ò®_01618]G[iÚÌÊæ¾³ÏX(Ver1.9ÌSRg»)
 *  2010/06/11    1.21  S.Niki           [E_{Ò®_03075]_IðÎ
 *  2010/07/08    1.22  S.Niki           [E_{Ò®_02637]ÚqiÚd¡o^Î
 *  2011/02/15    1.23  N.Horigome       [E_{Ò®_02155]NCbNóÌ`[ÔÌC³Î
 *  2011/04/27    1.24  K.Kiriu          [E_{Ò®_07182][i\èf[^ì¬xÎ
 *  2011/09/03    1.25  K.Kiriu          [E_{Ò®_07906]¬ÊBMSÎ
 *  2011/12/15    1.26  T.Yoshimoto      [E_{Ò®_02817]p[^(ð_R[h)ÇÁÎ
 *                                       [E_{Ò®_07554]ó¾×ÌPÊÚÖÌNVLÎ
 *  2012/08/24    1.27  K.Onotsuka       [E_{Ò®_09938]iÚG[bZ[WÌp[^ÇÁÎ
 *  2018/07/03    1.28  K.Kiriu          [E_{Ò®_15116]EDI[i\èf[^oðÉÂ¢ÄiHHTóf[^§äjÎ
 *  2019/06/25    1.29  S.Kuwako         [E_{Ò®_15472]y¸Å¦Î
 *  2019/07/16    1.30  S.Kuwako         [E_{Ò®_15472]y¸Å¦Î_¤iR[hÏ·G[Î
 *  2019/12/19    1.31  N.Koyama         [E_{Ò®_16112]ptH[}XÎ()óúÌúÔiè
 *  2020/01/08    1.32  N.Koyama         [E_{Ò®_16112]ptH[}XÎ(óúÌúÔièÇÁÎ)
 *  2022/12/08    1.33  M.Akachi         [E_{Ò®_18895][i\èf[^ì¬iðpj@\Î
 *
 *****************************************************************************************/
--
--#######################  ÅèO[oèé¾ START   #######################
--
  --Xe[^XER[h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --³í:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --x:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --Ùí:2
  --WHOJ
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
/* 2010/03/19 Ver1.19 Add Start */
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id; --PER_BUSINESS_GROUP_ID
/* 2010/03/19 Ver1.19 Add  End  */
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  Åè END   ##################################
--
--#######################  ÅèO[oÏé¾ START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- ÎÛ
  gn_normal_cnt    NUMBER;                    -- ³í
  gn_error_cnt     NUMBER;                    -- G[
  gn_warn_cnt      NUMBER;                    -- XLbv
--
--################################  Åè END   ##################################
--
--##########################  Åè¤ÊáOé¾ START  ###########################
--
  --*** ¤ÊáO ***
  global_process_expt       EXCEPTION;
  --*** ¤ÊÖáO ***
  global_api_expt           EXCEPTION;
  --*** ¤ÊÖOTHERSáO ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  Åè END   ##################################
--
  -- ===============================
  -- [U[è`áO
  -- ===============================
  global_data_check_expt    EXCEPTION;      -- f[^`FbNÌG[
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- bNG[
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  global_number_err_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_number_err_expt, -6502 );
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
/* 2010/07/08 Ver1.22 Add Start */
  global_item_conv_expt     EXCEPTION;      -- ÚqiÚ`FbNG[
/* 2010/07/08 Ver1.22 Add End */
/* 2019/06/25 Ver1.29 Add Start */
  global_tax_err_expt       EXCEPTION;      -- ÁïÅæ¾G[
/* 2019/06/25 Ver1.29 Add End   */
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A03C'; -- pbP[W¼
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';        -- AvP[V¼
  -- vt@C
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';            -- XXCCP:IFR[hæª_wb_
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';              -- XXCCP:IFR[hæª_f[^
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';            -- XXCCP:IFR[hæª_tb^
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';     -- XXCOS:UTL_MAXsTCY
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_OM_DIR';  -- XXCOS:EDIónAEgoEhpfBNgpX
  cv_prf_company_name   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME';         -- XXCOS:ïÐ¼
  cv_prf_company_kana   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME_KANA';    -- XXCOS:ïÐ¼Ji
  cv_prf_case_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';        -- XXCOS:P[XPÊR[h
  cv_prf_ball_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_BALL_UOM_CODE';        -- XXCOS:{[PÊR[h
  cv_prf_organization   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';    -- XXCOI:ÝÉgDR[h
  cv_prf_max_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';             -- XXCOS:MAXút
/* 2010/03/19 Ver1.19 Add Start */
  cv_prf_min_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MIN_DATE';             -- XXCOS:MINút
/* 2010/03/19 Ver1.19 Add  End  */
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';            -- GLïv ëID
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                      -- MO:cÆPÊ
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_item_div_h         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H'; -- XXCOS1:{Ð»iæª
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
/*  Ver1.31 Add Start   */
  cv_deli_ord_keep_day  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DELI_ORD_KEEP_DAY'; -- XXCOS:[ipóÛú
/*  Ver1.31 Add End     */
/*  Ver1.32 Add Start   */
  cv_deli_ord_keep_day_e  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DELI_ORD_KEEP_DAY_E'; -- XXCOS:[ipóÛúI¹
/*  Ver1.32 Add End     */
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Add Start
--  cv_prf_dum_stock_out  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DUMMY_STOCK_OUT';  -- XXCOS:EDI[i\è_~[iæª
---- 2009/05/22 Ver1.9 Add End
/* 2010/04/15 Ver1.20 Del End   */
  -- bZ[WR[h
  cv_msg_param_null     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- K{üÍp[^¢ÝèG[bZ[W
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';  -- üÍp[^s³G[bZ[W
  cv_msg_date_reverse   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00005';  -- útt]G[bZ[W
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- vt@Cæ¾G[bZ[W
  cv_msg_mast_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- }X^`FbNG[bZ[W
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IFt@CCAEgè`îñæ¾G[bZ[W
  cv_msg_org_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- ÝÉgDIDæ¾G[bZ[W
  cv_msg_com_fnuc_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';  -- EDI¤ÊÖG[bZ[W
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- t@CI[vG[bZ[W
  cv_msg_base_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00035';  -- _îñæ¾G[bZ[W
  cv_msg_chain_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- `F[Xîñæ¾G[bZ[W
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- bNG[bZ[W
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- f[^oG[bZ[W
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- ÎÛf[^ÈµbZ[W
  cv_msg_product_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12253';  -- ¤iR[hG[bZ[W
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- oÍîñÒWG[bZ[W
  cv_msg_data_upd_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- f[^XVG[bZ[W
  cv_msg_param1         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12251';  -- p[^oÍPbZ[W
  cv_msg_param2         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12264';  -- p[^oÍPbZ[W
  cv_msg_param3         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12252';  -- p[^oÍQbZ[W
  -- bZ[Wp¶ñ
  cv_msg_tkn_param1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12254';  -- ì¬æª
  cv_msg_tkn_param2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12255';  -- EDI`F[XR[h
  cv_msg_tkn_param3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00109';  -- t@C¼
  cv_msg_tkn_param4     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12256';  -- EDI`ÇÔ(t@C¼p)
  cv_msg_tkn_param5     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12257';  -- XÜ[iúFrom
  cv_msg_tkn_param6     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12258';  -- XÜ[iúTo
  cv_msg_tkn_param7     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12259';  -- ú
  cv_msg_tkn_param8     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12260';  -- 
  cv_msg_tkn_param9     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12262';  -- Z^[[iú
  cv_msg_tkn_prf1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- XXCCP:IFR[hæª_wb_
  cv_msg_tkn_prf2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- XXCCP:IFR[hæª_f[^
  cv_msg_tkn_prf3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- XXCCP:IFR[hæª_tb^
  cv_msg_tkn_prf4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00099';  -- XXCOS:UTL_MAXsTCY
  cv_msg_tkn_prf5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00145';  -- XXCOS:EDIónAEgoEhpfBNgpX
  cv_msg_tkn_prf6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00058';  -- XXCOS:ïÐ¼
  cv_msg_tkn_prf7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00098';  -- XXCOS:ïÐ¼Ji
  cv_msg_tkn_prf8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';  -- XXCOS:P[XPÊR[h
  cv_msg_tkn_prf9       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00059';  -- XXCOS:{[PÊR[h
  cv_msg_tkn_prf10      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';  -- XXCOI:ÝÉgDR[h
  cv_msg_tkn_prf11      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAXút
/* 2010/03/19 Ver1.19 Add Start */
  cv_msg_tkn_prf15      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00120';  -- XXCOS:MINút
/* 2010/03/19 Ver1.19 Add  End  */
  cv_msg_tkn_prf12      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';  -- GLïv ëID
  cv_msg_tkn_prf13      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- cÆPÊ
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Add Start
--  cv_msg_tkn_prf14      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12266';  -- XXCOS:EDI[i\è_~[iæª
---- 2009/05/22 Ver1.9 Add End
/* 2010/04/15 Ver1.20 Del End   */
  cv_msg_tkn_column1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12261';  -- f[^íR[h
  cv_msg_l_meaning2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12263';  -- NCbNR[hæ¾ð(EDI}Ìæª)
  cv_msg_tkn_column2    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- EDI}Ìæª
  cv_msg_tkn_tbl1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- NCbNR[h
  cv_msg_tkn_tbl2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';  -- EDIwb_îñe[u
  cv_msg_tkn_tbl3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00115';  -- EDI¾×îñe[u
  cv_msg_tkn_layout     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';  -- ónÚCAEg
  cv_msg_file_nmae      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- t@C¼oÍ
/* 2009/05/12 Ver1.8 Add Start */
  cv_msg_tkn_param10    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12265';  -- EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Add End   */
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  cv_msg_slip_no_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12267';  -- `[ÔlG[
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  cv_msg_category_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --JeSZbgIDæ¾G[bZ[W
  cv_msg_item_div_h     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --{Ð¤iæª
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_get_order_source_id_err CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12268';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
-- ******* 2019/06/25 Ver1.29 Add Start *******
  cv_msg_edi_hdr_id     CONSTANT  VARCHAR2(20)  := 'APP-XXCOS1-12270';  -- bZ[Wp¶ñ(EDIwb_îñID)
  cv_msg_edi_chain_code CONSTANT  VARCHAR2(20)  := 'APP-XXCOS1-12271';  -- bZ[Wp¶ñ(EDI`F[XR[h
  cv_msg_edi_item_code  CONSTANT  VARCHAR2(20)  := 'APP-XXCOS1-00054';  -- bZ[Wp¶ñ(iÚR[h)
  cv_msg_tax_err        CONSTANT  VARCHAR2(20)  := 'APP-XXCOS1-12269';  -- ÁïÅ¦æ¾G[
-- ******* 2019/06/25 Ver1.29 Add Start *******
  -- g[NR[h
  cv_tkn_in_param       CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- üÍp[^¼
  cv_tkn_date_from      CONSTANT VARCHAR2(9)   := 'DATE_FROM';         -- útúÔ`FbNÌJnú
  cv_tkn_date_to        CONSTANT VARCHAR2(7)   := 'DATE_TO';           -- útúÔ`FbNÌI¹ú
  cv_tkn_profile        CONSTANT VARCHAR2(7)   := 'PROFILE';           -- vt@C¼
  cv_tkn_column         CONSTANT VARCHAR2(6)   := 'COLMUN';            -- Ú¼
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';             -- e[u¼i_¼j
  cv_tkn_layout         CONSTANT VARCHAR2(6)   := 'LAYOUT';            -- t@Cè`CAEg¼
  cv_tkn_org_code       CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';      -- ÝÉgDR[h
  cv_tkn_err_msg        CONSTANT VARCHAR2(6)   := 'ERRMSG';            -- ¤ÊÖÌG[bZ[W
  cv_tkn_file_name      CONSTANT VARCHAR2(9)   := 'FILE_NAME';         -- [i\èt@C¼
  cv_tkn_code           CONSTANT VARCHAR2(4)   := 'CODE';              -- _R[h
  cv_tkn_chain_code     CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';   -- `F[XR[h
  cv_tkn_item_code      CONSTANT VARCHAR2(9)   := 'ITEM_CODE';         -- iÚR[h
  cv_tkn_table_name     CONSTANT VARCHAR2(10)  := 'TABLE_NAME';        -- e[u¼i_¼j
  cv_tkn_key_data       CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- L[îñ
  cv_tkn_count          CONSTANT VARCHAR2(5)   := 'COUNT';             -- ÎÛ
  cv_tkn_param01        CONSTANT VARCHAR2(7)   := 'PARAME1';           -- üÍp[^l
  cv_tkn_param02        CONSTANT VARCHAR2(7)   := 'PARAME2';           -- üÍp[^l
  cv_tkn_param03        CONSTANT VARCHAR2(7)   := 'PARAME3';           -- üÍp[^l
  cv_tkn_param04        CONSTANT VARCHAR2(7)   := 'PARAME4';           -- üÍp[^l
  cv_tkn_param05        CONSTANT VARCHAR2(7)   := 'PARAME5';           -- üÍp[^l
  cv_tkn_param06        CONSTANT VARCHAR2(7)   := 'PARAME6';           -- üÍp[^l
  cv_tkn_param07        CONSTANT VARCHAR2(7)   := 'PARAME7';           -- üÍp[^l
  cv_tkn_param08        CONSTANT VARCHAR2(7)   := 'PARAME8';           -- üÍp[^l
  cv_tkn_param09        CONSTANT VARCHAR2(7)   := 'PARAME9';           -- üÍp[^l
  cv_tkn_param10        CONSTANT VARCHAR2(8)   := 'PARAME10';          -- üÍp[^l
  cv_tkn_param11        CONSTANT VARCHAR2(8)   := 'PARAME11';          -- üÍp[^l
/* 2009/05/12 Ver1.8 Add Start */
  cv_tkn_param12        CONSTANT VARCHAR2(8)   := 'PARAME12';          -- üÍp[^l
/* 2009/05/12 Ver1.8 Add End   */
/* 2010/06/11 Ver1.21 Add Start */
  cv_tkn_param13        CONSTANT VARCHAR2(8)   := 'PARAME13';          -- üÍp[^l
/* 2010/06/11 Ver1.21 Add End */
/* 2012/08/20 Ver1.27 Add Start */
  cv_tkn_invoice_number CONSTANT VARCHAR2(14)  := 'INVOICE_NUMBER';    -- `[Ô
/* 2012/08/20 Ver1.27 Add End */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_order_source            CONSTANT VARCHAR2(20) := 'ORDER_SOURCE';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
  -- út
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            -- VXeút
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; -- Æ±ú
  -- f[^æ¾/ÒWpÅèl
  cv_cust_code_base     CONSTANT VARCHAR2(1)   := '1';                 -- Úqæª:_
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                -- Úqæª:Úq
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- Úqæª:`F[X
  cv_cust_status_30     CONSTANT VARCHAR2(2)   := '30';                -- ÚqXe[^X:³FÏ
  cv_cust_status_40     CONSTANT VARCHAR2(2)   := '40';                -- ÚqXe[^X:Úq
  cv_cust_status_90     CONSTANT VARCHAR2(2)   := '90';                -- ÚqXe[^X:~ÙÏ
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- Xe[^X:ÚqLø
  cv_tukzik_div_tuk     CONSTANT VARCHAR2(2)   := '11';                -- ÊßÝÉ^æª:Z^[[i(Êß^Eó)
  cv_tukzik_div_zik     CONSTANT VARCHAR2(2)   := '12';                -- ÊßÝÉ^æª:Z^[[i(ÝÉ^Eó)
  cv_tukzik_div_tnp     CONSTANT VARCHAR2(2)   := '24';                -- ÊßÝÉ^æª:XÜ[i
  cv_data_type_edi      CONSTANT VARCHAR2(2)   := '11';                -- f[^íR[h:óEDI
  cv_medium_class_edi   CONSTANT VARCHAR2(2)   := '00';                -- }Ìæª:EDI
  cv_medium_class_mnl   CONSTANT VARCHAR2(2)   := '01';                -- }Ìæª:èüÍ
  cv_position           CONSTANT VARCHAR2(3)   := '002';               -- EÊ:xX·
  cv_stockout_class_00  CONSTANT VARCHAR2(2)   := '00';                -- iæª:iÈµ
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--  cv_sale_class_all     CONSTANT VARCHAR2(1)   := '0';                 -- èÔÁæª:¼û
  cv_sale_class_all     CONSTANT VARCHAR2(2)   := '00';                -- èÔÁæª:¼û
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
  cv_entity_code_line   CONSTANT VARCHAR2(4)   := 'LINE';              -- GeBeBR[h:LINE
  cv_reason_type        CONSTANT VARCHAR2(11)  := 'CANCEL_CODE';       -- R^Cv:æÁ
  cv_err_reason_code    CONSTANT VARCHAR2(2)   := 'XX';                -- G[æÁR
/* 2010/07/08 Ver1.22 Add Start */
  cv_boot_para          CONSTANT VARCHAR2(1)   := '1';                 -- N®íÊi1:RJgA2:æÊj
/* 2010/07/08 Ver1.22 Add End */
  -- NCbNR[h^Cv
  cv_edi_shipping_exp_t CONSTANT VARCHAR2(28)  := 'XXCOS1_EDI_SHIPPING_EXP_TYPE';  -- ì¬æª
  cv_edi_media_class_t  CONSTANT VARCHAR2(22)  := 'XXCOS1_EDI_MEDIA_CLASS';        -- EDI}Ìæª
  cv_data_type_code_t   CONSTANT VARCHAR2(21)  := 'XXCOS1_DATA_TYPE_CODE';         -- f[^í
  cv_edi_item_err_t     CONSTANT VARCHAR2(24)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';      -- EDIiÚG[^Cv
  cv_edi_create_class   CONSTANT VARCHAR2(23)  := 'XXCOS1_EDI_CREATE_CLASS';       -- EDIì¬³æª
  -- NCbNR[h
  cv_data_type_code_c   CONSTANT VARCHAR2(3)   := '040';               -- f[^í([i\è)
/* 2009/05/12 Ver1.8 Del Start */
/* 2009/02/27 Ver1.5 Add Start */
--  cv_data_type_code_l   CONSTANT VARCHAR2(3)   := '200';               -- f[^í([i\è(x))
/* 2009/02/27 Ver1.5 Add  End  */
/* 2009/05/12 Ver1.8 Del  End  */
  cv_edi_create_class_c CONSTANT VARCHAR2(2)   := '10';                -- EDIì¬³æª(ó)
  -- ì¬æª
  cv_make_class_transe  CONSTANT VARCHAR2(1)   := '1';                 -- M
  cv_make_class_label   CONSTANT VARCHAR2(1)   := '2';                 -- xì¬
  cv_make_class_release CONSTANT VARCHAR2(1)   := '9';                 -- ð
  -- »Ì¼Åèl
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- úttH[}bg(ú)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';          -- úttH[}bg(Ô)
  cv_max_date_format    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- MAXúttH[}bg
/* 2010/03/19 Ver1.19 Add Start */
  cv_min_date_format    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- MINúttH[}bg
/* 2010/03/19 Ver1.19 Add  End  */
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- Åèl:0(VARCHAR2)
  cn_0                  CONSTANT NUMBER        := 0;                   -- Åèl:0(NUMBER)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- Åèl:1(VARCHAR2)
  cn_1                  CONSTANT NUMBER        := 1;                   -- Åèl:1(NUMBER)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- Åèl:2
-- Ver1.28 Add Start
  cv_3                  CONSTANT VARCHAR2(1)   := '3';                 -- Åèl:3
  cv_4                  CONSTANT VARCHAR2(1)   := '4';                 -- Åèl:4
-- Ver1.28 Add End
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- Åèl:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- Åèl:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- Åèl:W
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
  cv_comma              CONSTANT VARCHAR2(1)   := ',';                 -- Åèl:,
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2012/08/23 Ver1.27 Add Start */
  cv_invoice_number     CONSTANT VARCHAR2(16)  := ' A`[R[hF ';  -- Åèl:`[R[hF(ÚqiÚG[bZ[Wp)
  cv_message_end        CONSTANT VARCHAR2(2)   := ' )';                -- Åèl:)(ÚqiÚG[bZ[Wp)
/* 2012/08/23 Ver1.27 Add End */
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := USERENV('LANG'); --LANG
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
  -- f[^ÒW¤ÊÖp
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  -- }Ìæª
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                -- f[^íR[h
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       -- t@CNo
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    -- îñæª
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  -- ú
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  -- 
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     -- _(å)R[h
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     -- _¼(³®¼)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 -- _¼(Ji)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                -- EDI`F[XR[h
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                -- EDI`F[X¼(¿)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            -- EDI`F[X¼(Ji)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    -- `F[XR[h
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    -- `F[X¼(¿)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                -- `F[X¼(Ji)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   --  [R[h
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              --  [\¦¼
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 -- ÚqR[h
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 -- Úq¼(¿)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             -- Úq¼(Ji)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  -- ÐR[h
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  -- Ð¼(¿)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              -- Ð¼(Ji)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     -- XR[h
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     -- X¼(¿)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 -- X¼(Ji)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          -- [üZ^[R[h
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          -- [üZ^[¼(¿)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      -- [üæZ^[¼(Ji)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    -- ­ú
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          -- Z^[[iú
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          -- À[iú
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            -- XÜ[iú
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   -- f[^ì¬ú(EDIf[^)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   -- f[^ì¬(EDIf[^)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 -- `[æª
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     -- ¬ªÞR[h
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     -- ¬ªÞ¼
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    -- ªÞR[h
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    -- ªÞ¼
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       -- åªÞR[h
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       -- åªÞ¼
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   -- èæåR[h
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      -- èæ­Ô
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             -- `FbNfWbgL³æª
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                -- `[Ô
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   -- `FbNfWbg
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    -- À
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  -- óNo(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 -- Áæª
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               -- zæª
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                -- ÖNo
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    -- Aæ
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   -- [gZ[X
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                -- @lR[h
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    -- [J[¼
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     -- næR[h
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     -- næ¼(¿)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 -- næ¼(Ji)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   -- æøæR[h
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   -- æøæ¼(¿)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              -- æøæ¼1(Ji)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              -- æøæ¼2(Ji)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    -- æøæTEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 -- æøæSÒ
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                -- æøæZ(¿)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        -- Í¯æR[h(É¡)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         -- Í¯æR[h(`F[X)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    -- Í¯æ(¿)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               -- Í¯æ1(Ji)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               -- Í¯æ2(Ji)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            -- Í¯æZ(¿)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        -- Í¯æZ(Ji)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                -- Í¯æTEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         --  æR[h
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; --  æÐR[h
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    --  æXR[h
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         --  æ¼(¿)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     --  æ¼(Ji)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      --  æZ(¿)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  --  æZ(Ji)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          --  æTEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           -- óÂ\ú
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      -- eÂ\ú
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 -- æÀNú
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       -- x¥Ïú
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    -- `VJnú
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              -- ¿÷ú
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 -- o×
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        -- [i\èÔ
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    -- ­Ô
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            -- ÄpútÚ1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            -- ÄpútÚ2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            -- ÄpútÚ3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            -- ÄpútÚ4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            -- ÄpútÚ5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        -- üo×æª
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  -- æøææª
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        -- `[àóæª
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          -- P¿gpæª
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  -- Tu¨¬Z^[R[h
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  -- Tu¨¬Z^[R[h¼
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        -- Z^[[iû@
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              -- Z^[pæª
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             -- Z^[qÉæª
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             -- Z^[nææª
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          -- Z^[ü×æª
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   -- f|æª
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    -- TCDCæª
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      -- UPCtO
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          -- êÄæª
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   -- Æ±ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           -- q¼æª
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          -- ÚíÊ
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     -- iißæª
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        -- ßÆHæª
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     -- ¬Ýæª
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     -- ÝÉæª
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        -- ÅIC³êæª
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  --  [æª
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           -- ÇÁEvææª
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            -- o^æª
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                -- Áèæª
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                -- æøæª
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   -- ­æª
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                -- Wv¾×æª
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       -- o×ÄàÈOæª
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                -- o×æª
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        -- ¤iR[hgpæª
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              -- Ïiæª
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      -- T^Aæª
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     -- éæº°ÄÞ
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 -- JeS[R[h
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                -- JeS[æª
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 -- ^èi
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  -- êR[h
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     -- Ú®TC
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         -- EOSEèæª
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      -- [iæÛR[h
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              -- `[àó
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    -- Yt
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             -- tA
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       -- TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 -- CXgAR[h
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      -- ^O
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              -- £
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 -- ¿ûÀ
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              -- `F[XgA[R[h
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        -- Áª°Ý½Ä±°º°ÄÞª®¼Ì
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      -- ¼z^øæ¿
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     -- è`îñ
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   -- Ev1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 -- àR[h
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  -- ­îñ [iJeS[
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 -- dü`Ô
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          -- [iê¼(Ji)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              -- Xoê
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  -- ê¼
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              -- àüÔ
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   -- SÒ¼
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     -- lD
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      -- Åí
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         -- ÁïÅæª
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   -- BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       -- IDR[h
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               -- SÝXR[h
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               -- SÝX¼
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              -- iÊÔ
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        -- Ev2
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              -- lDû@
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 -- ©R
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               -- Awb_
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               -- Dwb_
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    -- uhR[h
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     -- CR[h
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    -- NXR[h
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     -- A|1
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     -- B|1
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     -- C|1
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     -- D|1
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     -- E|1
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     -- A|2
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     -- B|2
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     -- C|2
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     -- D|2
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     -- E|2
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     -- A|3
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     -- B|3
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     -- C|3
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     -- D|3
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     -- E|3
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     -- F|1
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     -- G|1
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     -- H|1
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     -- I|1
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     -- J|1
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     -- K|1
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     -- L|1
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     -- F|2
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     -- G|2
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     -- H|2
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     -- I|2
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     -- J|2
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     -- K|2
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     -- L|2
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     -- F|3
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     -- G|3
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     -- H|3
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     -- I|3
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     -- J|3
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     -- K|3
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     -- L|3
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    -- `F[XÅLGA(wb_)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       -- óÖAÔ(¼)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       -- sNo
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                -- iæª
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               -- iR
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           -- ¤iR[h(É¡)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 -- ¤iR[h1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 -- ¤iR[h2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      -- JANR[h
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      -- ITFR[h
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            -- à ITFR[h
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             -- P[X¤iR[h
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             -- {[¤iR[h
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        -- ¤iR[hií
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    -- ¤iæª
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  -- ¤i¼(¿)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             -- ¤i¼1(Ji)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             -- ¤i¼2(Ji)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                -- Ki1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                -- Ki2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   -- ü
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  -- P[Xü
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   -- {[ü
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    -- F
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     -- TCY
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               -- Ü¡úÀú
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  -- »¢ú
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 -- ­PÊ
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              -- o×PÊ
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               -- «ïPÊ
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     -- ø
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    -- øæª
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                -- Æ
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      -- PÊ
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              -- P¿æª
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         -- e«ïÔ
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                -- «ïÔ
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            -- ¤iQR[h
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           -- P[XðÌsÂtO
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    -- P[Xæª
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                -- ­Ê(o)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                -- ­Ê(P[X)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                -- ­Ê({[)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 -- ­Ê(vAo)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             -- o×Ê(o)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             -- o×Ê(P[X)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             -- o×Ê({[)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           -- o×Ê(pbg)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              -- o×Ê(vAo)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             -- iÊ(o)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             -- iÊ(P[X)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             -- iÊ({[)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              -- iÊ(vAo)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      -- P[XÂû
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       -- IR(o)Âû
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              -- ´P¿(­)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           -- ´P¿(o×)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                -- ´¿àz(­)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             -- ´¿àz(o×)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             -- ´¿àz(i)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 -- P¿
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               -- ¿àz(­)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            -- ¿àz(o×)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            -- ¿àz(i)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           -- A(SÝX)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           -- D(SÝX)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           -- KiîñEs«
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          -- KiîñE³
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           -- KiîñE
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          -- KiîñEdÊ
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       -- Äpøp¬Ú1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       -- Äpøp¬Ú2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       -- Äpøp¬Ú3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       -- Äpøp¬Ú4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       -- Äpøp¬Ú5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       -- Äpøp¬Ú6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       -- Äpøp¬Ú7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       -- Äpøp¬Ú8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       -- Äpøp¬Ú9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      -- Äpøp¬Ú10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             -- ÄptÁÚ1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             -- ÄptÁÚ2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             -- ÄptÁÚ3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             -- ÄptÁÚ4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             -- ÄptÁÚ5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             -- ÄptÁÚ6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             -- ÄptÁÚ7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             -- ÄptÁÚ8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             -- ÄptÁÚ9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            -- ÄptÁÚ10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      -- `F[XÅLGA(¾×)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        -- (`[v)­Ê(o)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        -- (`[v)­Ê(P[X)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        -- (`[v)­Ê({[)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         -- (`[v)­Ê(vAo)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     -- (`[v)o×Ê(o)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     -- (`[v)o×Ê(P[X)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     -- (`[v)o×Ê({[)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   -- (`[v)o×Ê(pbg)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      -- (`[v)o×Ê(vAo)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     -- (`[v)iÊ(o)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     -- (`[v)iÊ(P[X)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     -- (`[v)iÊ({[)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      -- (`[v)iÊ(vAo)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              -- (`[v)P[XÂû
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    -- (`[v)IR(o)Âû
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        -- (`[v)´¿àz(­)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     -- (`[v)´¿àz(o×)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     -- (`[v)´¿àz(i)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       -- (`[v)¿àz(­)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    -- (`[v)¿àz(o×)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    -- (`[v)¿àz(i)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          -- (v)­Ê(o)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          -- (v)­Ê(P[X)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          -- (v)­Ê({[)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           -- (v)­Ê(vAo)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       -- (v)o×Ê(o)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       -- (v)o×Ê(P[X)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       -- (v)o×Ê({[)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     -- (v)o×Ê(pbg)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        -- (v)o×Ê(vAo)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       -- (v)iÊ(o)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       -- (v)iÊ(P[X)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       -- (v)iÊ({[)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        -- (v)iÊ(vAo)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                -- (v)P[XÂû
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      -- (v)IR(o)Âû
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          -- (v)´¿àz(­)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       -- (v)´¿àz(o×)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       -- (v)´¿àz(i)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         -- (v)¿àz(­)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      -- (v)¿àz(o×)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      -- (v)¿àz(i)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                -- g[^s
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             -- g[^`[
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    -- `F[XÅLGA(tb^)
/* 2009/04/28 Ver1.7 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     -- \õGA
/* 2009/04/28 Ver1.7 Add End   */
/* 2011/09/03 Ver1.25 Add Start */
  cv_bms_header_data          CONSTANT VARCHAR2(50)  := 'BMS_HEADER_DATA';               -- ¬Êalrwb_f[^
  cv_bms_line_data            CONSTANT VARCHAR2(50)  := 'BMS_LINE_DATA';                 -- ¬Êalr¾×f[^
/* 2011/09/03 Ver1.25 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_online                   CONSTANT VARCHAR2(50)  := 'Online';                        -- ó\[X(ONLINE)
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
/* 2010/03/19 Ver1.19 Add Start */
  cv_emp                      CONSTANT VARCHAR2(100) := 'EMP';                           -- ]Æõ
  ct_enabled_flg_y            CONSTANT fnd_lookup_values.enabled_flag%TYPE := 'Y';       -- gpÂ\
/* 2010/03/19 Ver1.19 Add  End  */
/* 2019/06/25 Ver1.29 Add Start */
  cv_non_tax                  CONSTANT  VARCHAR(10)  := '4';         -- ñÛÅ
  cv_out_tax                  CONSTANT  VARCHAR(10)  := '1';         -- OÅ
  cv_ins_slip_tax             CONSTANT  VARCHAR(10)  := '2';         -- àÅ(`[ÛÅ)
  cv_ins_bid_tax              CONSTANT  VARCHAR(10)  := '3';         -- àÅ(P¿Ý)
  cv_tkn_down                 CONSTANT  VARCHAR2(20) := 'DOWN';      -- ØÌÄ
  cv_tkn_up                   CONSTANT  VARCHAR2(20) := 'UP';        -- Øã°
  cv_tkn_nearest              CONSTANT  VARCHAR2(20) := 'NEAREST';   -- lÌÜü
/* 2019/06/25 Ver1.29 Add  End  */
--
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
  gt_f_handle           UTL_FILE.FILE_TYPE;                            -- t@Cnh
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;       -- t@CCAEg
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
  -- t@CoÍÚp
  gv_f_o_date           CHAR(8);                                       -- ú
  gv_f_o_time           CHAR(6);                                       -- 
  gn_organization_id    NUMBER;                                        -- ÝÉgDID
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;                -- Å¦
  gt_edi_media_class    fnd_lookup_values_vl.lookup_code%TYPE;         -- EDI}Ìæª
  gt_data_type_code     fnd_lookup_values_vl.lookup_code%TYPE;         -- f[^íR[h
  -- e[uJE^
  gn_dat_rec_cnt        NUMBER;                                        -- oÍf[^p
  gn_head_cnt           NUMBER;                                        -- EDIwb_îñp
  gn_line_cnt           NUMBER;                                        -- EDI¾×îñp
  -- ð»èA¤ÊÖp
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    -- EDIAgiÚR[hæª
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         -- ÚqID(`F[X)
  gt_from_series        fnd_lookup_values_vl.attribute1%TYPE;          -- IF³Æ±nñR[h
  gt_edi_c_code         xxcos_edi_headers.edi_chain_code%TYPE;         -- EDI`F[XR[h
  gt_edi_f_number       xxcmm_cust_accounts.edi_forward_number%TYPE;   -- EDI`ÇÔ
  gt_shop_date_from     xxcos_edi_headers.shop_delivery_date%TYPE;     -- XÜ[iúFrom
  gt_shop_date_to       xxcos_edi_headers.shop_delivery_date%TYPE;     -- XÜ[iúTo
  gt_sale_class         xxcos_edi_headers.ar_sale_class%TYPE;          -- èÔÁæª
  gt_area_code          xxcmm_cust_accounts.edi_district_code%TYPE;    -- næR[h
/* 2010/03/19 Ver1.19 Add Start */
  gt_delivery_charge    xxcos_edi_headers.vendor_charge%TYPE;          -- [iSÒ
/* 2010/03/19 Ver1.19 Add  End  */
/* 2010/06/11 Ver1.21 Add Start */
  gt_slct_base_code     xxcmm_cust_accounts.delivery_base_code%TYPE;   -- [i_R[h
/* 2010/06/11 Ver1.21 Add End */
  -- vt@Cl
  gv_if_header          VARCHAR2(2);                                   -- wb_R[hæª
  gv_if_data            VARCHAR2(2);                                   -- f[^R[hæª
  gv_if_footer          VARCHAR2(2);                                   -- tb^R[hæª
  gv_utl_m_line         VARCHAR2(100);                                 -- UTL_MAXsTCY
  gv_outbound_d         VARCHAR2(100);                                 -- AEgoEhpfBNgpX
  gv_company_name       VARCHAR2(100);                                 -- ïÐ¼
  gv_company_kana       VARCHAR2(100);                                 -- ïÐ¼Ji
  gv_case_uom_code      VARCHAR2(3);                                   -- P[XPÊR[h
  gv_ball_uom_code      VARCHAR2(3);                                   -- {[PÊR[h
  gv_organization       VARCHAR2(3);                                   -- ÝÉgDR[h
  gd_max_date           DATE;                                          -- MAXút
/* 2010/03/19 Ver1.19 Add Start */
  gd_min_date           DATE;                                          -- MINút
/* 2010/03/19 Ver1.19 Add  End  */
/*  Ver1.31 Add Start   */
    gn_deli_ord_keep_day  NUMBER;                                      -- [ipóÛú
/*  Ver1.31 Add End     */
/*  Ver1.32 Add Start   */
    gn_deli_ord_keep_day_e  NUMBER;                                    -- [ipóÛúI¹
/*  Ver1.32 Add End     */
  gn_bks_id             NUMBER;                                        -- ïv ëID
  gn_org_id             NUMBER;                                        -- cÆPÊ
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Add Start
--  gn_dum_stock_out      VARCHAR2(3);                                   -- EDI[i\è_~[iæª
---- 2009/05/22 Ver1.9 Add End
/* 2010/04/15 Ver1.20 Del End   */
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
   gt_category_set_id      mtl_category_sets_tl.category_set_id%TYPE;          --JeSZbgID
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    gt_order_source_online oe_order_sources.order_source_id%TYPE;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
-- ******* 2019/06/25 1.29 S.Kuwako ADD START ******* --
  gv_tkn1               VARCHAR2(5000);                                -- L[îñÒWp
  gv_tax_round_rule     VARCHAR2(30);                                  -- Åà|[
-- ******* 2019/06/25 1.29 S.Kuwako ADD  END  ******* --
--
  -- ===============================
  -- [U[è`O[oJ[\é¾
  -- ===============================
  -- EDIóf[^
  CURSOR edi_order_cur
  IS
    SELECT 
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
           /*+ USE_NL(XEH) */
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
           xeh.edi_header_info_id               edi_header_info_id             -- EDIwb_îñ.EDIwb_îñID
          ,xeh.medium_class                     medium_class                   -- EDIwb_îñ.}Ìæª
          ,xeh.data_type_code                   data_type_code                 -- EDIwb_îñ.f[^íR[h
          ,xeh.file_no                          file_no                        -- EDIwb_îñ.t@CNo
          ,xeh.info_class                       info_class                     -- EDIwb_îñ.îñæª
          ,xca3.delivery_base_code              delivery_base_code             -- Úq}X^.[i_R[h
          ,hp1.party_name                       base_name                      -- _}X^.Úq¼Ì
          ,hp1.organization_name_phonetic       base_name_phonetic             -- _}X^.Úq¼Ì(Ji)
          ,xeh.edi_chain_code                   edi_chain_code                 -- EDIwb_îñ.dch`F[XR[h
          ,hp2.party_name                       edi_chain_name                 -- `F[X}X^.Úq¼Ì
          ,xeh.edi_chain_name_alt               edi_chain_name_alt             -- EDIwb_îñ.dch`F[X¼(Ji)
          ,hp2.organization_name_phonetic       edi_chain_name_phonetic        -- `F[X}X^.Úq¼Ì(Ji)
          ,xca3.chain_store_code                edi_chain_store_code           -- Úq}X^.`F[XR[h(EDI)
          ,hca3.account_number                  account_number                 -- Úq}X^.ÚqR[h
          ,hp3.party_name                       customer_name                  -- Úq}X^.Úq¼Ì
          ,hp3.organization_name_phonetic       customer_name_phonetic         -- Úq}X^.Úq¼Ì(Ji)
          ,xeh.company_code                     company_code                   -- EDIwb_îñ.ÐR[h
          ,xeh.company_name                     company_name                   -- EDIwb_îñ.Ð¼(¿)
          ,xeh.company_name_alt                 company_name_alt               -- EDIwb_îñ.Ð¼(Ji)
          ,xeh.shop_code                        shop_code                      -- EDIwb_îñ.XR[h
          ,xca3.cust_store_name                 cust_store_name                -- Úq}X^.ÚqXÜ¼Ì
          ,xeh.shop_name_alt                    shop_name_alt                  -- EDIwb_îñ.X¼(Ji)
          ,hp3.organization_name_phonetic       shop_name_phonetic             -- Úq}X^.Úq¼Ì(Ji)
          ,xeh.delivery_center_code             delivery_center_code           -- EDIwb_îñ.[üZ^[R[h
          ,xeh.delivery_center_name             delivery_center_name           -- EDIwb_îñ.[üZ^[¼(¿)
          ,xeh.delivery_center_name_alt         delivery_center_name_alt       -- EDIwb_îñ.[üZ^[¼(Ji)
          ,xeh.order_date                       order_date                     -- EDIwb_îñ.­ú
          ,xeh.center_delivery_date             center_delivery_date           -- EDIwb_îñ.Z^[[iú
          ,xeh.result_delivery_date             result_delivery_date           -- EDIwb_îñ.À[iú
/* 2010/03/11 Ver1.17 Mod Start */
--          ,xeh.shop_delivery_date               shop_delivery_date             -- EDIwb_îñ.XÜ[iú
          ,ooha.request_date                    shop_delivery_date             -- ówb_.vú
/* 2010/03/11 Ver1.17 Mod  End  */
          ,xeh.data_creation_date_edi_data      data_creation_date_edi_data    -- EDIwb_îñ.f[^ì¬ú(dchf[^)
          ,xeh.data_creation_time_edi_data      data_creation_time_edi_data    -- EDIwb_îñ.f[^ì¬(dchf[^)
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute5,xeh.invoice_class) invoice_class                  -- EDIwb_îñ.`[æª
--          ,xeh.invoice_class                    invoice_class                  -- EDIwb_îñ.`[æª
-- ****************************** 2009/07/10 1.10 N.Maeda   MOD  END  *****************************--
          ,xeh.small_classification_code        small_classification_code      -- EDIwb_îñ.¬ªÞR[h
          ,xeh.small_classification_name        small_classification_name      -- EDIwb_îñ.¬ªÞ¼
          ,xeh.middle_classification_code       middle_classification_code     -- EDIwb_îñ.ªÞR[h
          ,xeh.middle_classification_name       middle_classification_name     -- EDIwb_îñ.ªÞ¼
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute20,xeh.big_classification_code) big_classification_code  -- EDIwb_îñ.åªÞR[h
          ,CASE
             WHEN  ( xeh.big_classification_code = ooha.attribute20 ) THEN
               xeh.big_classification_name
             ELSE
               NULL
           END
                                                big_classification_name        -- EDIwb_îñ.åªÞ¼
--          ,xeh.big_classification_code          big_classification_code        -- EDIwb_îñ.åªÞR[h
--          ,xeh.big_classification_name          big_classification_name        -- EDIwb_îñ.åªÞ¼
-- ****************************** 2009/07/10 1.10 N.Maeda    MOD  END  *****************************--
          ,xeh.other_party_department_code      other_party_department_code    -- EDIwb_îñ.èæåR[h
          ,xeh.other_party_order_number         other_party_order_number       -- EDIwb_îñ.èæ­Ô
          ,xeh.check_digit_class                check_digit_class              -- EDIwb_îñ.`FbNfWbgL³æª
/* 2011/02/15 Ver1.23 N.Horigome Mod START */
--          ,xeh.invoice_number                   invoice_number                 -- EDIwb_îñ.`[Ô
          ,ooha.cust_po_number                   invoice_number                 -- ówb_.Úq­Ô
/* 2011/02/15 Ver1.23 N.Horigome Mod END   */
          ,xeh.check_digit                      check_digit                    -- EDIwb_îñ.`FbNfWbg
          ,xeh.close_date                       close_date                     -- EDIwb_îñ.À
          ,ooha.order_number                    order_number                   -- ówb_.óÔ
          ,xeh.ar_sale_class                    ar_sale_class                  -- EDIwb_îñ.Áæª
          ,xeh.delivery_classe                  delivery_classe                -- EDIwb_îñ.zæª
          ,xeh.opportunity_no                   opportunity_no                 -- EDIwb_îñ.Öm
          ,xeh.contact_to                       contact_to                     -- EDIwb_îñ.Aæ
          ,xeh.route_sales                      route_sales                    -- EDIwb_îñ.[gZ[X
          ,xeh.corporate_code                   corporate_code                 -- EDIwb_îñ.@lR[h
          ,xeh.maker_name                       maker_name                     -- EDIwb_îñ.[J[¼
          ,xeh.area_code                        area_code                      -- EDIwb_îñ.næR[h
          ,xca3.edi_district_code               edi_district_code              -- Úq}X^.EDInæR[h
          ,xeh.area_name                        area_name                      -- EDIwb_îñ.næ¼(¿)
          ,xca3.edi_district_name               edi_district_name              -- Úq}X^.EDInæ¼
          ,xeh.area_name_alt                    area_name_alt                  -- EDIwb_îñ.næ¼(Ji)
          ,xca3.edi_district_kana               edi_district_kana              -- Úq}X^.EDInæ¼Ji
          ,xeh.vendor_code                      vendor_code                    -- EDIwb_îñ.æøæR[h
          ,xca3.torihikisaki_code               torihikisaki_code              -- Úq}X^.æøæR[h
          ,xeh.vendor_name1_alt                 vendor_name1_alt               -- EDIwb_îñ.æøæ¼P(Ji)
          ,xeh.vendor_name2_alt                 vendor_name2_alt               -- EDIwb_îñ.æøæ¼Q(Ji)
/* 2010/03/19 Ver1.19 Mod Start */
--          ,papf.last_name                       last_name                      -- ]Æõ}X^.Ji©
--          ,papf.first_name                      first_name                     -- ]Æõ}X^.Ji¼
          ,CASE
             WHEN ( gt_delivery_charge IS NOT NULL ) THEN
               gt_delivery_charge
             ELSE
               NVL( ( SELECT SUBSTRB( papf.last_name || papf.first_name ,1 ,12 ) full_name          -- ]Æõ}X^DJi©¼
                       FROM   per_all_people_f         papf                                         -- ]Æõ}X^
                             ,per_all_assignments_f    paaf                                         -- ]Æõ}X^
                       WHERE  paaf.effective_start_date <= cd_process_date                          -- ]ÆõÏ½À.KpJnú<=Æ±út
                       AND    paaf.effective_end_date   >= cd_process_date                          -- ]ÆõÏ½À.KpI¹ú>=Æ±út
                       AND    papf.person_id             = paaf.person_id                           -- ]ÆõÏ½À.]ÆõID=]ÆõÏ½À.]ÆõID
                       AND    papf.attribute11           = cv_position                              -- ]ÆõÏ½À.EÊ(V)='002'(xX·)
                       AND    papf.effective_start_date <= cd_process_date                          -- ]ÆõÏ½À.KpJnú<=Æ±út
                       AND    papf.effective_end_date   >= cd_process_date                          -- ]ÆõÏ½À.KpI¹ú>=Æ±út
                       AND    paaf.ass_attribute5        = xca3.delivery_base_code                  -- ]ÆõÏ½À.®º°ÄÞ=ÚqÇÁîñ.[i_º°ÄÞ
                       AND    ROWNUM                     = 1
                     ) ,
                     ( SELECT SUBSTRB( papf.last_name || papf.first_name ,1 ,12 ) full_name         -- ]Æõ}X^DJi©¼
                       FROM   jtf_rs_salesreps         jrs                                          -- jtf_rs_salesreps
                             ,jtf_rs_resource_extns    jrre                                         -- \[X}X^
                             ,per_person_types         ppt                                          -- ]Æõ^Cv}X^
                             ,per_all_people_f         papf                                         -- ]Æõ}X^
                       WHERE  jrs.resource_id            = jrre.resource_id
                       AND    jrre.source_id             = papf.person_id
                       AND    TRUNC(ooha.request_date)   BETWEEN NVL( papf.effective_start_date, gd_min_date )
                                                         AND     NVL( papf.effective_end_date, gd_max_date )
                       AND    papf.person_type_id        = ppt.person_type_id
                       AND    ppt.business_group_id      = cn_per_business_group_id
                       AND    ppt.system_person_type     = cv_emp
                       AND    ppt.active_flag            = ct_enabled_flg_y
                       AND    jrs.salesrep_id            = ooha.salesrep_id
                       AND    jrs.org_id                 = ooha.org_id
                     )
                  )
           END                                  full_name                      -- ]Æõ}X^DJi©¼
/* 2010/03/19 Ver1.19 Mod  End  */
          ,hl1.state                            state                          -- _}X^.s¹{§
          ,hl1.city                             city                           -- _}X^.sEæ
          ,hl1.address1                         address1                       -- _}X^.ZP
          ,hl1.address2                         address2                       -- _}X^.ZQ
          ,hl1.address_lines_phonetic           address_lines_phonetic         -- _}X^.dbÔ
          ,xeh.deliver_to_code_itouen           deliver_to_code_itouen         -- EDIwb_îñ.Í¯æR[h(É¡)
          ,xeh.deliver_to_code_chain            deliver_to_code_chain          -- EDIwb_îñ.Í¯æR[h(`F[X)
          ,xeh.deliver_to                       deliver_to                     -- EDIwb_îñ.Í¯æ(¿)
          ,xeh.deliver_to1_alt                  deliver_to1_alt                -- EDIwb_îñ.Í¯æP(Ji)
          ,xeh.deliver_to2_alt                  deliver_to2_alt                -- EDIwb_îñ.Í¯æQ(Ji)
          ,xeh.deliver_to_address               deliver_to_address             -- EDIwb_îñ.Í¯æZ(¿)
          ,xeh.deliver_to_address_alt           deliver_to_address_alt         -- EDIwb_îñ.Í¯æZ(Ji)
          ,xeh.deliver_to_tel                   deliver_to_tel                 -- EDIwb_îñ.Í¯æsdk
          ,xeh.balance_accounts_code            balance_accounts_code          -- EDIwb_îñ. æR[h
          ,xeh.balance_accounts_company_code    balance_accounts_company_code  -- EDIwb_îñ. æÐR[h
          ,xeh.balance_accounts_shop_code       balance_accounts_shop_code     -- EDIwb_îñ. æXR[h
          ,xeh.balance_accounts_name            balance_accounts_name          -- EDIwb_îñ. æ¼(¿)
          ,xeh.balance_accounts_name_alt        balance_accounts_name_alt      -- EDIwb_îñ. æ¼(Ji)
          ,xeh.balance_accounts_address         balance_accounts_address       -- EDIwb_îñ. æZ(¿)
          ,xeh.balance_accounts_address_alt     balance_accounts_address_alt   -- EDIwb_îñ. æZ(Ji)
          ,xeh.balance_accounts_tel             balance_accounts_tel           -- EDIwb_îñ. æsdk
          ,xeh.order_possible_date              order_possible_date            -- EDIwb_îñ.óÂ\ú
          ,xeh.permission_possible_date         permission_possible_date       -- EDIwb_îñ.eÂ\ú
          ,xeh.forward_month                    forward_month                  -- EDIwb_îñ.æÀNú
          ,xeh.payment_settlement_date          payment_settlement_date        -- EDIwb_îñ.x¥Ïú
          ,xeh.handbill_start_date_active       handbill_start_date_active     -- EDIwb_îñ.`VJnú
          ,xeh.billing_due_date                 billing_due_date               -- EDIwb_îñ.¿÷ú
          ,xeh.shipping_time                    shipping_time                  -- EDIwb_îñ.o×
          ,xeh.delivery_schedule_time           delivery_schedule_time         -- EDIwb_îñ.[i\èÔ
          ,xeh.order_time                       order_time                     -- EDIwb_îñ.­Ô
          ,xeh.general_date_item1               general_date_item1             -- EDIwb_îñ.ÄpútÚP
          ,xeh.general_date_item2               general_date_item2             -- EDIwb_îñ.ÄpútÚQ
          ,xeh.general_date_item3               general_date_item3             -- EDIwb_îñ.ÄpútÚR
          ,xeh.general_date_item4               general_date_item4             -- EDIwb_îñ.ÄpútÚS
          ,xeh.general_date_item5               general_date_item5             -- EDIwb_îñ.ÄpútÚT
          ,xeh.arrival_shipping_class           arrival_shipping_class         -- EDIwb_îñ.üo×æª
          ,xeh.vendor_class                     vendor_class                   -- EDIwb_îñ.æøææª
          ,xeh.invoice_detailed_class           invoice_detailed_class         -- EDIwb_îñ.`[àóæª
          ,xeh.unit_price_use_class             unit_price_use_class           -- EDIwb_îñ.P¿gpæª
          ,xeh.sub_distribution_center_code     sub_distribution_center_code   -- EDIwb_îñ.Tu¨¬Z^[R[h
          ,xeh.sub_distribution_center_name     sub_distribution_center_name   -- EDIwb_îñ.Tu¨¬Z^[R[h¼
          ,xeh.center_delivery_method           center_delivery_method         -- EDIwb_îñ.Z^[[iû@
          ,xeh.center_use_class                 center_use_class               -- EDIwb_îñ.Z^[pæª
          ,xeh.center_whse_class                center_whse_class              -- EDIwb_îñ.Z^[qÉæª
          ,xeh.center_area_class                center_area_class              -- EDIwb_îñ.Z^[nææª
          ,xeh.center_arrival_class             center_arrival_class           -- EDIwb_îñ.Z^[ü×æª
          ,xeh.depot_class                      depot_class                    -- EDIwb_îñ.f|æª
          ,xeh.tcdc_class                       tcdc_class                     -- EDIwb_îñ.sbcbæª
          ,xeh.upc_flag                         upc_flag                       -- EDIwb_îñ.tobtO
          ,xeh.simultaneously_class             simultaneously_class           -- EDIwb_îñ.êÄæª
          ,xeh.business_id                      business_id                    -- EDIwb_îñ.Æ±hc
          ,xeh.whse_directly_class              whse_directly_class            -- EDIwb_îñ.q¼æª
          ,xeh.premium_rebate_class             premium_rebate_class           -- EDIwb_îñ.iißæª
          ,xeh.item_type                        item_type                      -- EDIwb_îñ.ÚíÊ
          ,xeh.cloth_house_food_class           cloth_house_food_class         -- EDIwb_îñ.ßÆHæª
          ,xeh.mix_class                        mix_class                      -- EDIwb_îñ.¬Ýæª
          ,xeh.stk_class                        stk_class                      -- EDIwb_îñ.ÝÉæª
          ,xeh.last_modify_site_class           last_modify_site_class         -- EDIwb_îñ.ÅIC³êæª
          ,xeh.report_class                     report_class                   -- EDIwb_îñ. [æª
          ,xeh.addition_plan_class              addition_plan_class            -- EDIwb_îñ.ÇÁEvææª
          ,xeh.registration_class               registration_class             -- EDIwb_îñ.o^æª
          ,xeh.specific_class                   specific_class                 -- EDIwb_îñ.Áèæª
          ,xeh.dealings_class                   dealings_class                 -- EDIwb_îñ.æøæª
          ,xeh.order_class                      order_class                    -- EDIwb_îñ.­æª
          ,xeh.sum_line_class                   sum_line_class                 -- EDIwb_îñ.Wv¾×æª
          ,xeh.shipping_guidance_class          shipping_guidance_class        -- EDIwb_îñ.o×ÄàÈOæª
          ,xeh.shipping_class                   shipping_class                 -- EDIwb_îñ.o×æª
          ,xeh.product_code_use_class           product_code_use_class         -- EDIwb_îñ.¤iR[hgpæª
          ,xeh.cargo_item_class                 cargo_item_class               -- EDIwb_îñ.Ïiæª
          ,xeh.ta_class                         ta_class                       -- EDIwb_îñ.s^`æª
          ,xeh.plan_code                        plan_code                      -- EDIwb_îñ.éæR[h
          ,xeh.category_code                    category_code                  -- EDIwb_îñ.JeS[R[h
          ,xeh.category_class                   category_class                 -- EDIwb_îñ.JeS[æª
          ,xeh.carrier_means                    carrier_means                  -- EDIwb_îñ.^èi
          ,xeh.counter_code                     counter_code                   -- EDIwb_îñ.êR[h
          ,xeh.move_sign                        move_sign                      -- EDIwb_îñ.Ú®TC
          ,xeh.eos_handwriting_class            eos_handwriting_class          -- EDIwb_îñ.dnrEèæª
          ,xeh.delivery_to_section_code         delivery_to_section_code       -- EDIwb_îñ.[iæÛR[h
          ,xeh.invoice_detailed                 invoice_detailed               -- EDIwb_îñ.`[àó
          ,xeh.attach_qty                       attach_qty                     -- EDIwb_îñ.Yt
          ,xeh.other_party_floor                other_party_floor              -- EDIwb_îñ.tA
          ,xeh.text_no                          text_no                        -- EDIwb_îñ.sdwsm
          ,xeh.in_store_code                    in_store_code                  -- EDIwb_îñ.CXgAR[h
          ,xeh.tag_data                         tag_data                       -- EDIwb_îñ.^O
          ,xeh.competition_code                 competition_code               -- EDIwb_îñ.£
          ,xeh.billing_chair                    billing_chair                  -- EDIwb_îñ.¿ûÀ
          ,xeh.chain_store_code                 chain_store_code               -- EDIwb_îñ.`F[XgA[R[h
          ,xeh.chain_store_short_name           chain_store_short_name         -- EDIwb_îñ.`F[XgA[R[hª®¼Ì
          ,xeh.direct_delivery_rcpt_fee         direct_delivery_rcpt_fee       -- EDIwb_îñ.¼z^øæ¿
          ,xeh.bill_info                        bill_info                      -- EDIwb_îñ.è`îñ
          ,xeh.description                      description                    -- EDIwb_îñ.Ev
          ,xeh.interior_code                    interior_code                  -- EDIwb_îñ.àR[h
          ,xeh.order_info_delivery_category     order_info_delivery_category   -- EDIwb_îñ.­îñ@[iJeS[
          ,xeh.purchase_type                    purchase_type                  -- EDIwb_îñ.dü`Ô
          ,xeh.delivery_to_name_alt             delivery_to_name_alt           -- EDIwb_îñ.[iê¼(Ji)
          ,xeh.shop_opened_site                 shop_opened_site               -- EDIwb_îñ.Xoê
          ,xeh.counter_name                     counter_name                   -- EDIwb_îñ.ê¼
          ,xeh.extension_number                 extension_number               -- EDIwb_îñ.àüÔ
          ,xeh.charge_name                      charge_name                    -- EDIwb_îñ.SÒ¼
          ,xeh.price_tag                        price_tag                      -- EDIwb_îñ.lD
          ,xeh.tax_type                         tax_type                       -- EDIwb_îñ.Åí
-- ******* 2019/06/25 Ver1.29 MOD Start *******
--          ,xeh.consumption_tax_class            consumption_tax_class          -- EDIwb_îñ.ÁïÅæª
          ,xca3.tax_div                         consumption_tax_class          -- ÚqÇÁîñ.ÁïÅæª
-- ******* 2019/06/25 Ver1.29 MOD End *******
          ,xeh.brand_class                      brand_class                    -- EDIwb_îñ.aq
          ,xeh.id_code                          id_code                        -- EDIwb_îñ.hcR[h
          ,xeh.department_code                  department_code                -- EDIwb_îñ.SÝXR[h
          ,xeh.department_name                  department_name                -- EDIwb_îñ.SÝX¼
          ,xeh.item_type_number                 item_type_number               -- EDIwb_îñ.iÊÔ
          ,xeh.description_department           description_department         -- EDIwb_îñ.Ev(SÝX)
          ,xeh.price_tag_method                 price_tag_method               -- EDIwb_îñ.lDû@
          ,xeh.reason_column                    reason_column                  -- EDIwb_îñ.©R
          ,xeh.a_column_header                  a_column_header                -- EDIwb_îñ.`wb_
          ,xeh.d_column_header                  d_column_header                -- EDIwb_îñ.cwb_
          ,xeh.brand_code                       brand_code                     -- EDIwb_îñ.uhR[h
          ,xeh.line_code                        line_code                      -- EDIwb_îñ.CR[h
          ,xeh.class_code                       class_code                     -- EDIwb_îñ.NXR[h
          ,xeh.a1_column                        a1_column                      -- EDIwb_îñ.`|P
          ,xeh.b1_column                        b1_column                      -- EDIwb_îñ.a|P
          ,xeh.c1_column                        c1_column                      -- EDIwb_îñ.b|P
          ,xeh.d1_column                        d1_column                      -- EDIwb_îñ.c|P
          ,xeh.e1_column                        e1_column                      -- EDIwb_îñ.d|P
          ,xeh.a2_column                        a2_column                      -- EDIwb_îñ.`|Q
          ,xeh.b2_column                        b2_column                      -- EDIwb_îñ.a|Q
          ,xeh.c2_column                        c2_column                      -- EDIwb_îñ.b|Q
          ,xeh.d2_column                        d2_column                      -- EDIwb_îñ.c|Q
          ,xeh.e2_column                        e2_column                      -- EDIwb_îñ.d|Q
          ,xeh.a3_column                        a3_column                      -- EDIwb_îñ.`|R
          ,xeh.b3_column                        b3_column                      -- EDIwb_îñ.a|R
          ,xeh.c3_column                        c3_column                      -- EDIwb_îñ.b|R
          ,xeh.d3_column                        d3_column                      -- EDIwb_îñ.c|R
          ,xeh.e3_column                        e3_column                      -- EDIwb_îñ.d|R
          ,xeh.f1_column                        f1_column                      -- EDIwb_îñ.e|P
          ,xeh.g1_column                        g1_column                      -- EDIwb_îñ.f|P
          ,xeh.h1_column                        h1_column                      -- EDIwb_îñ.g|P
          ,xeh.i1_column                        i1_column                      -- EDIwb_îñ.h|P
          ,xeh.j1_column                        j1_column                      -- EDIwb_îñ.i|P
          ,xeh.k1_column                        k1_column                      -- EDIwb_îñ.j|P
          ,xeh.l1_column                        l1_column                      -- EDIwb_îñ.k|P
          ,xeh.f2_column                        f2_column                      -- EDIwb_îñ.e|Q
          ,xeh.g2_column                        g2_column                      -- EDIwb_îñ.f|Q
          ,xeh.h2_column                        h2_column                      -- EDIwb_îñ.g|Q
          ,xeh.i2_column                        i2_column                      -- EDIwb_îñ.h|Q
          ,xeh.j2_column                        j2_column                      -- EDIwb_îñ.i|Q
          ,xeh.k2_column                        k2_column                      -- EDIwb_îñ.j|Q
          ,xeh.l2_column                        l2_column                      -- EDIwb_îñ.k|Q
          ,xeh.f3_column                        f3_column                      -- EDIwb_îñ.e|R
          ,xeh.g3_column                        g3_column                      -- EDIwb_îñ.f|R
          ,xeh.h3_column                        h3_column                      -- EDIwb_îñ.g|R
          ,xeh.i3_column                        i3_column                      -- EDIwb_îñ.h|R
          ,xeh.j3_column                        j3_column                      -- EDIwb_îñ.i|R
          ,xeh.k3_column                        k3_column                      -- EDIwb_îñ.j|R
          ,xeh.l3_column                        l3_column                      -- EDIwb_îñ.k|R
          ,xeh.chain_peculiar_area_header       chain_peculiar_area_header     -- EDIwb_îñ.`F[XÅLGA(wb_[)
          ,xeh.total_line_qty                   total_line_qty                 -- EDIwb_îñ.g[^s
          ,xeh.total_invoice_qty                total_invoice_qty              -- EDIwb_îñ.g[^`[
          ,xeh.chain_peculiar_area_footer       chain_peculiar_area_footer     -- EDIwb_îñ.`F[XÅLGA(tb^[)
          ,xeh.order_forward_flag               order_forward_flag             -- EDIwb_îñ.óAgÏtO
          ,xeh.creation_class                   creation_class                 -- EDIwb_îñ.ì¬³æª
          ,xeh.edi_delivery_schedule_flag       edi_delivery_schedule_flag     -- EDIwb_îñ.EDI[i\èMÏtO
          ,xeh.price_list_header_id             price_list_header_id           -- EDIwb_îñ.¿i\wb_ID
          ,xel.edi_line_info_id                 edi_line_info_id               -- EDI¾×îñ.EDI¾×îñID
          ,xel.line_no                          line_no                        -- EDI¾×îñ.sm
/* 2011/04/27 Ver1.24 Del Start */
--          ,DECODE(flvv1.attribute1, cv_y, ore.reason_code,
--                                          cv_err_reason_code)
--                                                stockout_class                 -- ÏXR.iæª
/* 2011/04/27 Ver1.24 Del End   */
          ,xel.stockout_reason                  stockout_reason                -- EDI¾×îñ.iR
          ,oola.ordered_item                    ordered_item                   -- ó¾×.óiÚ
          ,xel.product_code1                    product_code1                  -- EDI¾×îñ.¤iR[hP
          ,xel.product_code2                    product_code2                  -- EDI¾×îñ.¤iR[hQ
          ,iimb.attribute21                     opf_jan_code                   -- noliÚ}X^.JANR[h
          ,xsib.case_jan_code                   case_jan_code                  -- DisciÚAhI.P[XJANR[h
          ,xel.itf_code                         itf_code                       -- EDI¾×îñ.hseR[h
          ,iimb.attribute22                     opm_itf_code                   -- noliÚ}X^.ITFR[h
          ,xel.extension_itf_code               extension_itf_code             -- EDI¾×îñ.à hseR[h
          ,xel.case_product_code                case_product_code              -- EDI¾×îñ.P[X¤iR[h
          ,xel.ball_product_code                ball_product_code              -- EDI¾×îñ.{[¤iR[h
          ,xel.product_code_item_type           product_code_item_type         -- EDI¾×îñ.¤iR[hií
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--          ,xhpcv.item_div_h_code                item_div_h_code                -- {Ð¤iæªr[.{Ð¤iæª
          ,mcb.segment1                         item_div_h_code                -- {Ð¤iæªr[.{Ð¤iæª
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
          ,xel.product_name                     product_name                   -- EDI¾×îñ.¤i¼(¿)
/* 2009/03/04 Ver1.6 Add Start */
          ,msib.description                     item_name                      -- DisciÚ.Ev
/* 2009/03/04 Ver1.6 Add  End  */
          ,xel.product_name1_alt                product_name1_alt              -- EDI¾×îñ.¤i¼P(Ji)
          ,xel.product_name2_alt                product_name2_alt              -- EDI¾×îñ.¤i¼Q(Ji)
          ,SUBSTRB(ximb.item_name_alt, 1, 15)   item_name_alt                  -- iÚ_¤i¼QiJij
          ,xel.item_standard1                   item_standard1                 -- EDI¾×îñ.KiP
          ,xel.item_standard2                   item_standard2                 -- EDI¾×îñ.KiQ
          ,SUBSTRB(ximb.item_name_alt, 16, 15)  item_name_alt2                 -- iÚ_KiQ
          ,xel.qty_in_case                      qty_in_case                    -- EDI¾×îñ.ü
          ,iimb.attribute11                     num_of_case                    -- noliÚ}X^.P[Xü
          ,xel.num_of_ball                      num_of_ball                    -- EDI¾×îñ.{[ü
          ,xsib.bowl_inc_num                    bowl_inc_num                   -- DisciÚAhI.{[ü
          ,xel.item_color                       item_color                     -- EDI¾×îñ.F
          ,xel.item_size                        item_size                      -- EDI¾×îñ.TCY
          ,xel.expiration_date                  expiration_date                -- EDI¾×îñ.Ü¡úÀú
          ,xel.product_date                     product_date                   -- EDI¾×îñ.»¢ú
          ,xel.order_uom_qty                    order_uom_qty                  -- EDI¾×îñ.­PÊ
          ,xel.shipping_uom_qty                 shipping_uom_qty               -- EDI¾×îñ.o×PÊ
          ,xel.packing_uom_qty                  packing_uom_qty                -- EDI¾×îñ.«ïPÊ
          ,xel.deal_code                        deal_code                      -- EDI¾×îñ.ø
          ,xel.deal_class                       deal_class                     -- EDI¾×îñ.øæª
          ,xel.collation_code                   collation_code                 -- EDI¾×îñ.Æ
          ,xel.uom_code                         uom_code                       -- EDI¾×îñ.PÊ
          ,xel.unit_price_class                 unit_price_class               -- EDI¾×îñ.P¿æª
          ,xel.parent_packing_number            parent_packing_number          -- EDI¾×îñ.e«ïÔ
          ,xel.packing_number                   packing_number                 -- EDI¾×îñ.«ïÔ
          ,xel.product_group_code               product_group_code             -- EDI¾×îñ.¤iQR[h
          ,xel.case_dismantle_flag              case_dismantle_flag            -- EDI¾×îñ.P[XðÌsÂtO
          ,xel.case_class                       case_class                     -- EDI¾×îñ.P[Xæª
          ,xel.indv_order_qty                   indv_order_qty                 -- EDI¾×îñ.­Ê(o)
          ,xel.case_order_qty                   case_order_qty                 -- EDI¾×îñ.­Ê(P[X)
          ,xel.ball_order_qty                   ball_order_qty                 -- EDI¾×îñ.­Ê({[)
          ,xel.sum_order_qty                    sum_order_qty                  -- EDI¾×îñ.­Ê(vAo)
          ,xel.indv_shipping_qty                indv_shipping_qty              -- EDI¾×îñ.o×Ê(o)
          ,xel.case_shipping_qty                case_shipping_qty              -- EDI¾×îñ.o×Ê(P[X)
          ,xel.ball_shipping_qty                ball_shipping_qty              -- EDI¾×îñ.o×Ê({[)
          ,xel.pallet_shipping_qty              pallet_shipping_qty            -- EDI¾×îñ.o×Ê(pbg)
          ,xel.sum_shipping_qty                 sum_shipping_qty               -- EDI¾×îñ.o×Ê(vAo)
          ,xel.indv_stockout_qty                indv_stockout_qty              -- EDI¾×îñ.iÊ(o)
          ,xel.case_stockout_qty                case_stockout_qty              -- EDI¾×îñ.iÊ(P[X)
          ,xel.ball_stockout_qty                ball_stockout_qty              -- EDI¾×îñ.iÊ({[)
          ,xel.sum_stockout_qty                 sum_stockout_qty               -- EDI¾×îñ.iÊ(vAo)
          ,xel.case_qty                         case_qty                       -- EDI¾×îñ.P[XÂû
          ,xel.fold_container_indv_qty          fold_container_indv_qty        -- EDI¾×îñ.IR(o)Âû
          ,xel.order_unit_price                 order_unit_price               -- EDI¾×îñ.´P¿(­)
          ,oola.unit_selling_price              unit_selling_price             -- ó¾×.ÌP¿
          ,xel.order_cost_amt                   order_cost_amt                 -- EDI¾×îñ.´¿àz(­)
          ,xel.shipping_cost_amt                shipping_cost_amt              -- EDI¾×îñ.´¿àz(o×)
          ,xel.stockout_cost_amt                stockout_cost_amt              -- EDI¾×îñ.´¿àz(i)
/* 2010/03/18 Ver1.18 Mod Start */
--          ,xel.selling_price                    selling_price                  -- EDI¾×îñ.P¿
          ,CASE
             WHEN ( ooha.order_source_id = gt_order_source_online ) THEN
               TO_NUMBER ( oola.attribute10 )
             ELSE
               xel.selling_price
           END                                  selling_price
--          ,xel.order_price_amt                  order_price_amt                -- EDI¾×îñ.¿àz(­)
          ,CASE
             WHEN ( ooha.order_source_id = gt_order_source_online ) THEN
               TO_NUMBER ( oola.attribute10 * oola.ordered_quantity )
             ELSE
               xel.order_price_amt
           END                                  order_price_amt
/* 2010/03/18 Ver1.18 Mod  End  */
          ,xel.shipping_price_amt               shipping_price_amt             -- EDI¾×îñ.¿àz(o×)
          ,xel.stockout_price_amt               stockout_price_amt             -- EDI¾×îñ.¿àz(i)
          ,xel.a_column_department              a_column_department            -- EDI¾×îñ.`(SÝX)
          ,xel.d_column_department              d_column_department            -- EDI¾×îñ.c(SÝX)
          ,xel.standard_info_depth              standard_info_depth            -- EDI¾×îñ.KiîñEs«
          ,xel.standard_info_height             standard_info_height           -- EDI¾×îñ.KiîñE³
          ,xel.standard_info_width              standard_info_width            -- EDI¾×îñ.KiîñE
          ,xel.standard_info_weight             standard_info_weight           -- EDI¾×îñ.KiîñEdÊ
          ,xel.general_succeeded_item1          general_succeeded_item1        -- EDI¾×îñ.Äpøp¬ÚP
          ,xel.general_succeeded_item2          general_succeeded_item2        -- EDI¾×îñ.Äpøp¬ÚQ
          ,xel.general_succeeded_item3          general_succeeded_item3        -- EDI¾×îñ.Äpøp¬ÚR
          ,xel.general_succeeded_item4          general_succeeded_item4        -- EDI¾×îñ.Äpøp¬ÚS
          ,xel.general_succeeded_item5          general_succeeded_item5        -- EDI¾×îñ.Äpøp¬ÚT
          ,xel.general_succeeded_item6          general_succeeded_item6        -- EDI¾×îñ.Äpøp¬ÚU
          ,xel.general_succeeded_item7          general_succeeded_item7        -- EDI¾×îñ.Äpøp¬ÚV
          ,xel.general_succeeded_item8          general_succeeded_item8        -- EDI¾×îñ.Äpøp¬ÚW
          ,xel.general_succeeded_item9          general_succeeded_item9        -- EDI¾×îñ.Äpøp¬ÚX
          ,xel.general_succeeded_item10         general_succeeded_item10       -- EDI¾×îñ.Äpøp¬ÚPO
          ,xel.general_add_item1                general_add_item1              -- EDI¾×îñ.ÄptÁÚP
          ,xel.general_add_item2                general_add_item2              -- EDI¾×îñ.ÄptÁÚQ
          ,xel.general_add_item3                general_add_item3              -- EDI¾×îñ.ÄptÁÚR
          ,xel.general_add_item4                general_add_item4              -- EDI¾×îñ.ÄptÁÚS
          ,xel.general_add_item5                general_add_item5              -- EDI¾×îñ.ÄptÁÚT
          ,xel.general_add_item6                general_add_item6              -- EDI¾×îñ.ÄptÁÚU
          ,xel.general_add_item7                general_add_item7              -- EDI¾×îñ.ÄptÁÚV
          ,xel.general_add_item8                general_add_item8              -- EDI¾×îñ.ÄptÁÚW
          ,xel.general_add_item9                general_add_item9              -- EDI¾×îñ.ÄptÁÚX
          ,xel.general_add_item10               general_add_item10             -- EDI¾×îñ.ÄptÁÚPO
          ,xel.chain_peculiar_area_line         chain_peculiar_area_line       -- EDI¾×îñ.`F[XÅLGA(¾×)
          ,xel.item_code                        item_code                      -- EDI¾×îñ.iÚR[h
          ,xel.line_uom                         line_uom                       -- EDI¾×îñ.¾×PÊ
          ,xel.order_connection_line_number     order_connection_line_number   -- EDI¾×îñ.óÖA¾×Ô
-- ******* 2009/10/05 1.14 N.Maeda MOD START ******* --
--          ,oola.ordered_quantity                ordered_quantity               -- ó¾×.óÊ
          ,CASE
             WHEN ( ooha.order_source_id = gt_order_source_online ) THEN
               oola.ordered_quantity
             ELSE
               ( SELECT SUM ( oola_ilv.ordered_quantity ) ordered_quantity
                 FROM   oe_order_lines_all oola_ilv
                 WHERE  oola_ilv.header_id    = oola.header_id
                 AND    oola_ilv.org_id       = oola.org_id
                 AND    NVL ( oola_ilv.global_attribute3 , oola_ilv.line_id ) = oola.line_id
                 AND    NVL ( oola_ilv.global_attribute4 , oola_ilv.orig_sys_line_ref ) = oola.orig_sys_line_ref
               )
           END                                  ordered_quantity
-- ******* 2009/10/05 1.14 N.Maeda MOD  END  ******* --
-- ******* 2019/06/25 1.29 S.Kuwako MOD  START  ******* --
--          ,xtrv.tax_rate                        tax_rate                       -- ÁïÅ¦r[.ÁïÅ¦
          ,( CASE WHEN xca3.tax_div  = cv_non_tax THEN
                   ( SELECT xtv1.tax_rate
                       FROM xxcos_tax_v  xtv1
                      WHERE xtv1.tax_class       = xca3.tax_div
                       AND  xtv1.set_of_books_id = gn_bks_id
                       AND  TRUNC(oola.request_date) BETWEEN NVL(xtv1.start_date_active,TRUNC(oola.request_date))
                                                         AND NVL(xtv1.end_date_active,TRUNC(oola.request_date))
                       AND  cn_1 = ( SELECT COUNT(*)
                                       FROM xxcos_tax_v  xtv2
                                      WHERE xtv2.tax_class       = xca3.tax_div
                                        AND xtv2.set_of_books_id = gn_bks_id
                                        AND TRUNC(oola.request_date) BETWEEN NVL(xtv2.start_date_active,TRUNC(oola.request_date))
                                                                         AND NVL(xtv2.end_date_active,TRUNC(oola.request_date)))
                   )
                  WHEN xca3.tax_div != cv_non_tax THEN
                   ( SELECT xrtr1.tax_rate
                       FROM xxcos_reduced_tax_rate_v xrtr1
-- ******* 2019/07/16 1.30 S.Kuwako MOD  START  ******* --
--                      WHERE xrtr1.item_code  = xel.item_code
                      WHERE xrtr1.item_code  = oola.ordered_item
-- ******* 2019/07/16 1.30 S.Kuwako MOD  END    ******* --
                        AND TRUNC(oola.request_date) BETWEEN NVL(xrtr1.start_date,TRUNC(oola.request_date))
                                                         AND NVL(xrtr1.end_date,TRUNC(oola.request_date))
                        AND TRUNC(oola.request_date) BETWEEN NVL(xrtr1.start_date_histories,TRUNC(oola.request_date))
                                                         AND NVL(xrtr1.end_date_histories,TRUNC(oola.request_date))
                        AND cn_1 = ( SELECT COUNT(*)
                                       FROM xxcos_reduced_tax_rate_v xrtr2
-- ******* 2019/07/16 1.30 S.Kuwako MOD  START  ******* --
--                                      WHERE xrtr2.item_code  = xel.item_code
                                      WHERE xrtr2.item_code  = oola.ordered_item
-- ******* 2019/07/16 1.30 S.Kuwako MOD  END    ******* --
                                        AND TRUNC(oola.request_date) BETWEEN NVL(xrtr2.start_date,TRUNC(oola.request_date))
                                                                         AND NVL(xrtr2.end_date,TRUNC(oola.request_date))
                                        AND TRUNC(oola.request_date) BETWEEN NVL(xrtr2.start_date_histories,TRUNC(oola.request_date))
                                                                         AND NVL(xrtr2.end_date_histories,TRUNC(oola.request_date)))
                   )
             END
           )                                      tax_rate                       -- ÁïÅ¦r[.ÁïÅ¦AÜ½ÍiÚÊÁïÅr[.ÁïÅ¦
-- ******* 2019/06/25 1.29 S.Kuwako MOD  END  ******* --
--****************************** 2009/06/11 1.10 T.Kitajima ADD START ******************************--
          ,xca3.edi_forward_number              edi_forward_number             -- ÚqÇÁîñ.EDI`ÇÔ
--****************************** 2009/06/11 1.10 T.Kitajima ADD  END ******************************--
--****************************** 2009/06/24 1.10 T.Kitajima ADD START ******************************--
          ,oola.order_quantity_uom              order_quantity_uom             -- ó¾×.PÊ
--****************************** 2009/06/24 1.10 T.Kitajima ADD  END ******************************--
/* 2011/04/26 Ver1.24 Add Start */
          ,oola.line_id                         line_id                        -- ó¾×.àID
/* 2011/04/26 Ver1.24 Add End   */
/* 2011/09/03 Ver1.25 Add Start */
          ,xeh.bms_header_data                  bms_header_data               -- ¬Êalrwb_f[^
          ,xel.bms_line_data                    bms_line_data                 -- ¬Êalr¾×f[^
/* 2011/09/03 Ver1.25 Add End   */
    FROM   xxcos_edi_headers                    xeh    -- EDIwb_îñ
          ,xxcos_edi_lines                      xel    -- EDI¾×îñ
          ,oe_order_headers_all                 ooha   -- ówb_
          ,oe_order_lines_all                   oola   -- ó¾×
          ,hz_cust_accounts                     hca1   -- _}X^
          ,xxcmm_cust_accounts                  xca1   -- _ÇÁîñ
          ,hz_parties                           hp1    -- _p[eB
          ,hz_party_sites                       hps1   -- _p[eBTCg
          ,hz_locations                         hl1    -- _Æ
          ,hz_cust_acct_sites_all               hcas1  -- _Ýn
          ,hz_cust_accounts                     hca2   -- `F[X}X^
          ,xxcmm_cust_accounts                  xca2   -- `F[XÇÁîñ
          ,hz_parties                           hp2    -- `F[Xp[eB
          ,hz_cust_accounts                     hca3   -- Úq}X^
          ,xxcmm_cust_accounts                  xca3   -- ÚqÇÁîñ
          ,hz_parties                           hp3    -- Úqp[eB
-- ******* 2019/06/25 1.29 S.Kuwako Del  START  ******* --
--          ,xxcos_tax_rate_v                     xtrv   -- ÁïÅ¦r[
-- ******* 2019/06/25 1.29 S.Kuwako Del  END  ******* --
/* 2010/06/11 Ver1.21 Delete Start */
--          ,xxcos_login_base_info_v              xlbiv  -- _(Ç³)r[
/* 2010/06/11 Ver1.21 Delete End */
/* 2010/03/19 Ver1.19 Del Start */
--          ,per_all_people_f                     papf   -- ]Æõ}X^
--          ,per_all_assignments_f                paaf   -- ]Æõ}X^
/* 2010/03/19 Ver1.19 Del  End  */
          ,ic_item_mst_b                        iimb   -- noliÚ}X^
          ,xxcmn_item_mst_b                     ximb   -- noliÚAhI
          ,mtl_system_items_b                   msib   -- DisciÚ}X^
          ,xxcmm_system_items_b                 xsib   -- DisciÚAhI
-- ******* 2009/09/03 1.12 N.Maeda DEL START ******* --
--          ,xxcos_head_prod_class_v              xhpcv  -- {Ð¤iæªr[
-- ******* 2009/09/03 1.12 N.Maeda DEL  END  ******* --
/* 2011/04/27 Ver1.24 Del Start */
--          ,(SELECT ore1.reason_code             reason_code
--                  ,ore1.entity_id               entity_id
--            FROM   oe_reasons                   ore1
--/* 2009/08/10 Ver1.11 Mod Start */
----                  ,(SELECT ore2.entity_id           entity_id
--                  ,(SELECT /*+ INDEX( ore2 xxcos_oe_reasons_n04 ) */
--                           ore2.entity_id           entity_id
--/* 2009/08/10 Ver1.11 Mod Start */
--                          ,MAX(ore2.creation_date)  creation_date
--                    FROM   oe_reasons               ore2
--                    WHERE  ore2.reason_type = cv_reason_type
--                    AND    ore2.entity_code = cv_entity_code_line
--                    GROUP BY ore2.entity_id
--                   )                            ore_max
--            WHERE  ore1.entity_id     = ore_max.entity_id
--            AND    ore1.creation_date = ore_max.creation_date
--           )                                    ore    -- ÏXR
--          ,fnd_lookup_values_vl                 flvv1  -- RR[h}X^
/* 2011/04/27 Ver1.24 Del End   */
-- ******* 2009/09/03 1.12 N.Maeda ADD START ******* --
          ,mtl_item_categories            mic
          ,mtl_categories_b               mcb
-- ******* 2009/09/03 1.12 N.Maeda ADD  END  ******* --
    WHERE  xeh.edi_header_info_id         = xel.edi_header_info_id            -- EDIÍ¯ÀÞîñ.EDIÍ¯ÀÞîñID=EDI¾×îñ.EDIÍ¯ÀÞîñID
    AND    xeh.creation_class             =                                   -- EDIÍ¯ÀÞîñ.ì¬³æª='01'(óÃÞ°À)
         ( SELECT flvv.meaning   creation_class
           FROM   fnd_lookup_values_vl  flvv
           WHERE  flvv.lookup_type        = cv_edi_create_class
           AND    flvv.lookup_code        = cv_edi_create_class_c
           AND    flvv.enabled_flag       = cv_y                -- Lø
           AND (( flvv.start_date_active IS NULL )
           OR   ( flvv.start_date_active <= cd_process_date ))
           AND (( flvv.end_date_active   IS NULL )
           OR   ( flvv.end_date_active   >= cd_process_date ))  -- Æ±útªFROM-TOà
         )
    AND    xeh.edi_delivery_schedule_flag = cv_n                              -- EDIÍ¯ÀÞîñ.EDI[i\èMÏÌ×¸Þ='N'(¢M)
    AND    xeh.data_type_code             = cv_data_type_edi                  -- EDIÍ¯ÀÞîñ.ÃÞ°Àíº°ÄÞ='11'(óEDI)
    AND    xeh.edi_chain_code             = gt_edi_c_code                     -- EDIÍ¯ÀÞîñ.EDIÁª°ÝXº°ÄÞ=inÊß×Ò°À.EDIÁª°ÝXº°ÄÞ
/* 2010/03/11 Ver1.17 Mod Start */
--    AND    TRUNC(xeh.shop_delivery_date)    BETWEEN gt_shop_date_from         -- EDIÍ¯ÀÞîñ.XÜ[iú BETWEEN inÊß×Ò°À.XÜ[iúFrom
--                                                AND gt_shop_date_to           --                            AND inÊß×Ò°À.XÜ[iúTo
    AND    TRUNC(ooha.request_date)         BETWEEN gt_shop_date_from         -- óÍ¯ÀÞ.vú BETWEEN inÊß×Ò°À.XÜ[iúFrom
                                                AND gt_shop_date_to           --                            AND inÊß×Ò°À.XÜ[iúTo
/* 2010/03/11 Ver1.17 Mod  End  */
    AND  ( gt_sale_class                 IS NULL                              -- inÊß×Ò°À.èÔÁæª IS NULL
    OR     gt_sale_class                  = cv_sale_class_all                 -- inÊß×Ò°À.èÔÁæª='0'(¼û)
    OR     xeh.ar_sale_class              = gt_sale_class )                   -- EDIÍ¯ÀÞîñ.Áæª=inÊß×Ò°À.èÔÁæª
    AND    ooha.sold_to_org_id            = hca3.cust_account_id              -- óÍ¯ÀÞ.ÚqID=ÚqÏ½À.ÚqID
    AND    hca3.customer_class_code       = cv_cust_code_cust                 -- ÚqÏ½À.Úqæª='10'(Úq)
    AND    xca3.tsukagatazaiko_div       IN (cv_tukzik_div_tuk,               -- ÚqÏ½À.ÊßÝÉ^æª IN ('11'(¾ÝÀ°[i(Êß^¥ó)),
                                             cv_tukzik_div_zik,               --                            '12'(¾ÝÀ°[i(ÝÉ^¥ó)),
                                             cv_tukzik_div_tnp)               --                            '24'(XÜ[i))
    AND    xca3.chain_store_code          = gt_edi_c_code                     -- ÚqÏ½À.Áª°ÝXº°ÄÞ(EDI)=inÊß×Ò°À.EDIÁª°ÝXº°ÄÞ
    AND    xca3.edi_forward_number        = gt_edi_f_number                   -- ÚqÏ½À.EDI`ÇÔ=inÊß×Ò°À.EDI`ÇÔ
    AND  ( gt_area_code                  IS NULL                              -- inÊß×Ò°À.næº°ÄÞ IS NULL
    OR     xca3.edi_district_code         = gt_area_code )                    -- ÚqÏ½À.næº°ÄÞ=inÊß×Ò°À.næº°ÄÞ
-- ******* 2019/06/25 1.29 S.Kuwako Del  START  ******* --
--    AND    hca3.cust_account_id           = xtrv.cust_account_id              -- ÚqÏ½À.ÚqID=ÁïÅ¦ËÞ­°.ÚqID
--    AND    xca3.tax_div                   = xtrv.tax_div                      -- ÚqÏ½À.ÁïÅæª=ÁïÅ¦ËÞ­°.ÁïÅæª
--    AND    xtrv.set_of_books_id           = gn_bks_id                         -- ÁïÅ¦ËÞ­°.GLïv ëID=[A-2].GLïv ëID
--    AND    TRUNC(oola.request_date)      >= xtrv.start_date_active            -- ó¾×.vú>=ÁïÅ¦ËÞ­°.KpJnú
--    AND    TRUNC(oola.request_date)      <= NVL(xtrv.end_date_active,         -- ó¾×.vú<=NVL(ÁïÅ¦ËÞ­°.KpI¹ú,
--                                                gd_max_date)                  --                      [A-2].MAXút)
-- ******* 2019/06/25 1.29 S.Kuwako Del  END    ******* --
/* 2009/02/25 Ver1.3 Add Start */
-- ******* 2019/06/25 1.29 S.Kuwako Del  START  ******* --
--    AND    TRUNC(oola.request_date)      >= xtrv.tax_start_date               -- ó¾×.vú>=ÁïÅ¦ËÞ­°.ÅJnú
--    AND    TRUNC(oola.request_date)      <= NVL(xtrv.tax_end_date,            -- ó¾×.vú<=NVL(ÁïÅ¦ËÞ­°.ÅI¹ú,
--                                                gd_max_date)                  --                      [A-2].MAXút)
-- ******* 2019/06/25 1.29 S.Kuwako Del  END   ******* --
/* 2009/02/25 Ver1.3 Add  End  */
    AND    xeh.edi_chain_code             = xca2.chain_store_code             -- EDIÍ¯ÀÞîñ.EDIÁª°ÝXº°ÄÞ=Áª°ÝXÏ½À.Áª°ÝXº°ÄÞ(EDI)
    AND    hca2.customer_class_code       = cv_cust_code_chain                -- Áª°ÝXÏ½À.Úqæª='18'(Áª°ÝX)
/* 2009/02/20 Ver1.1 Mod Start */
--  AND (( xca2.handwritten_slip_div      = cv_n                              -- Áª°ÝXÏ½À.è`[`æª='N'(èMÎÛO)
    AND (( xca2.handwritten_slip_div      = cv_2                              -- Áª°ÝXÏ½À.è`[`æª='2'(èMÎÛO)
    AND    xeh.medium_class               = cv_medium_class_edi )             -- EDIÍ¯ÀÞîñ.}Ìæª='00'(EDI)
--  OR     xca2.handwritten_slip_div      = cv_y )                            -- Áª°ÝXÏ½À.è`[`æª='Y'(èMÎÛ)
-- Ver1.28 Mod Start
--    OR     xca2.handwritten_slip_div      = cv_1 )                            -- Áª°ÝXÏ½À.è`[`æª='1'(èMÎÛ)
          OR
          (
            (
              ( xca2.handwritten_slip_div   = cv_1 )                           -- Áª°ÝXÏ½À.èMÎÛ='1' (NCbNóÌÝ)
              AND
              ( xeh.medium_class = cv_medium_class_edi OR ooha.global_attribute5 IS NULL ) --EDIÆNCbNó
            )
            OR
            (
              ( xca2.handwritten_slip_div   = cv_3 )                           -- Áª°ÝXÏ½À.èMÎÛ='3' (HHTæèAg³ê½óÌÝ)
              AND
              ( xeh.medium_class = cv_medium_class_edi OR ooha.global_attribute5 = cv_1 )  -- EDIÆHHT
            )
            OR
            ( xca2.handwritten_slip_div   = cv_4 )                             -- Áª°ÝXÏ½À.èMÎÛ='4' (¼û)ÆEDI
          )
        )
-- Ver1.28 Mod End
/* 2009/02/20 Ver1.1 Mod  End  */
    AND    hca2.cust_account_id           = xca2.customer_id                  -- Áª°ÝXÏ½À.ÚqID=Áª°ÝXÇÁîñ.ÚqID
    AND    hca1.account_number            = xca3.delivery_base_code           -- _Ï½À.Úqº°ÄÞ=ÚqÏ½À.[i_º°ÄÞ
    AND    hca1.customer_class_code       = cv_cust_code_base                 -- _Ï½À.Úqæª='1'(_)
    AND    hca1.party_id                  = hp1.party_id                      -- _Ï½À.Êß°Ã¨ID=_Êß°Ã¨.Êß°Ã¨ID
    AND    hcas1.cust_account_id          = hca1.cust_account_id              -- _Ýn.ÚqID=ÚqÏ½À.ÚqID
    AND    hps1.location_id               = hl1.location_id                   -- _Êß°Ã¨»²Ä.ÝnID=_Æ.ÝnID
    AND    hps1.party_site_id             = hcas1.party_site_id               -- _Êß°Ã¨»²Ä.Êß°Ã¨»²ÄID=_Ýn.Êß°Ã¨»²ÄID
    AND    hcas1.org_id                   = gn_org_id                         -- _Ýn.gDID=[A-2].cÆPÊ
    AND    hca1.cust_account_id           = xca1.customer_id                  -- _Ï½À.ÚqID=_ÇÁîñ.ÚqID
    AND    hca3.cust_account_id           = xca3.customer_id                  -- ÚqÏ½À.ÚqID=ÚqÇÁîñ.ÚqID
    AND    hca2.party_id                  = hp2.party_id                      -- Áª°ÝXÏ½À.Êß°Ã¨ID=Áª°ÝXÊß°Ã¨.Êß°Ã¨ID
    AND    hp2.duns_number_c             <> cv_cust_status_90                 -- Áª°ÝXÊß°Ã¨.Úq½Ã°À½<>'90'(~ÙÏ)
    AND    hca3.party_id                  = hp3.party_id                      -- ÚqÏ½À.Êß°Ã¨ID=ÚqÊß°Ã¨.Êß°Ã¨ID
/* 2010/06/11 Ver1.21 Mod Start */
--    AND    xca3.delivery_base_code        = xlbiv.base_code                   -- ÚqÇÁîñ.[i_º°ÄÞ=_(Ç³)ËÞ­°._º°ÄÞ
    AND    xca3.delivery_base_code        = gt_slct_base_code                 -- ÚqÇÁîñ.[i_º°ÄÞ=üÍÊß×Ò°À.oÍ_º°ÄÞ
/* 2010/06/11 Ver1.21 Mod End */
/* 2010/03/19 Ver1.19 Del Start */
--    AND    xca3.delivery_base_code        = paaf.ass_attribute5               -- ÚqÇÁîñ.[i_º°ÄÞ=]ÆõÏ½À.®º°ÄÞ
--    AND    paaf.effective_start_date     <= cd_process_date                   -- ]ÆõÏ½À.KpJnú<=Æ±út
--    AND    paaf.effective_end_date       >= cd_process_date                   -- ]ÆõÏ½À.KpI¹ú>=Æ±út
--    AND    papf.person_id                 = paaf.person_id                    -- ]ÆõÏ½À.]ÆõID=]ÆõÏ½À.]ÆõID
--    AND    papf.attribute11               = cv_position                       -- ]ÆõÏ½À.EÊ(V)='002'(xX·)
--    AND    papf.effective_start_date     <= cd_process_date                   -- ]ÆõÏ½À.KpJnú<=Æ±út
--    AND    papf.effective_end_date       >= cd_process_date                   -- ]ÆõÏ½À.KpI¹ú>=Æ±út
/* 2010/03/19 Ver1.19 Del  End  */
--****************************** 2009/06/19 1.10 T.Kitajima MOD START ******************************--
    AND    ooha.org_id                    = gn_org_id                         -- óÍ¯ÀÞ.gDID=[A-2].cÆPÊ
--****************************** 2009/06/19 1.10 T.Kitajima MOD  END  ******************************--
    AND    ooha.header_id                 = oola.header_id                    -- óÍ¯ÀÞ.óÍ¯ÀÞID=ó¾×.óÍ¯ÀÞID
    AND    ooha.orig_sys_document_ref     = xeh.order_connection_number       -- óÍ¯ÀÞ.O¼½ÃÑóÖAÔ=EDIÍ¯ÀÞîñ.óÖAÔ
    AND    oola.orig_sys_line_ref         = xel.order_connection_line_number  -- ó¾×.O¼½ÃÑó¾×Ô=EDI¾×îñ.óÖA¾×Ô
--****************************** 2009/06/11 1.10 T.Kitajima MOD START ******************************--
--    AND    xel.line_no                    = oola.line_number                  -- EDI¾×îñ.sNo=ó¾×.¾×Ô
    AND    xel.order_connection_line_number
                                          = oola.orig_sys_line_ref            -- EDI¾×îñ.óÖA¾×Ô = ó¾×.O¼½ÃÑó¾×Ô
--****************************** 2009/06/11 1.10 T.Kitajima MOD  END  ******************************--
    AND    oola.inventory_item_id         = msib.inventory_item_id            -- ó¾×.iÚID=DisciÚÏ½À.iÚID
    AND    msib.segment1                  = iimb.item_no                      -- DisciÚÏ½À.iÚº°ÄÞ=OPMiÚÏ½À.iÚº°ÄÞ
    AND    iimb.item_id                   = ximb.item_id                      -- OPMiÚÏ½À.iÚID=OPMiÚ±ÄÞµÝ.iÚID
    AND    ximb.start_date_active        <= cd_process_date                   -- OPMiÚ±ÄÞµÝ.KpJnú<=Æ±út
    AND    ximb.end_date_active          >= cd_process_date                   -- OPMiÚ±ÄÞµÝ.KpI¹ú>=Æ±út
    AND    msib.organization_id           = gn_organization_id                -- DisciÚÏ½À.gDID=[A-2].ÝÉgDID
    AND    msib.segment1                  = xsib.item_code                    -- DisciÚÏ½À.iÚº°ÄÞ=DisciÚ±ÄÞµÝ.iÚº°ÄÞ
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--    AND    msib.inventory_item_id         = xhpcv.inventory_item_id           -- DisciÚÏ½À.iÚID={Ð¤iæªËÞ­°.iÚID
    AND msib.organization_id = gn_organization_id
    AND gn_organization_id = mic.organization_id
    AND msib.inventory_item_id = mic.inventory_item_id
    AND mic.category_set_id    = gt_category_set_id
    AND mic.category_id        = mcb.category_id
    AND ( mcb.disable_date IS NULL OR mcb.disable_date > cd_process_date )
    AND   mcb.enabled_flag   = 'Y'      -- JeSLøtO
    AND   cd_process_date BETWEEN NVL(mcb.start_date_active, cd_process_date)
                                     AND   NVL(mcb.end_date_active, cd_process_date)
    AND   msib.enabled_flag  = 'Y'      -- iÚ}X^LøtO
    AND   cd_process_date BETWEEN NVL(msib.start_date_active, cd_process_date)
                                     AND  NVL(msib.end_date_active, cd_process_date)
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
/* 2011/04/27 Ver1.24 Del Start */
--    AND    ore.entity_id(+)               = oola.line_id                      -- ÏXR.ID=ó¾×.¾×ID
--    AND    flvv1.lookup_type(+)           = cv_reason_type                    -- Rº°ÄÞÏ½À.À²Ìß=ÏXR
--    AND    flvv1.lookup_code(+)           = ore.reason_code                   -- Rº°ÄÞÏ½À.º°ÄÞ=ÏXR.Rº°ÄÞ
--    AND (( flvv1.start_date_active IS NULL )
--    OR   ( flvv1.start_date_active <= cd_process_date ))
--    AND (( flvv1.end_date_active   IS NULL )
--    OR   ( flvv1.end_date_active   >= cd_process_date ))                      -- Æ±útªFROM-TOà
/* 2011/04/27 Ver1.24 Del End   */
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD START ******************************--
    AND (( ooha.global_attribute3 IS NULL )
    OR   ( ooha.global_attribute3 = '02' ) )
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD  END  ******************************--
/*  Ver1.31 Add Start   */
    AND ooha.ordered_date            >= cd_process_date - gn_deli_ord_keep_day                    -- óÍ¯ÀÞ.óú BETWEEN vt@CÎÛúÔ
/*  Ver1.32 Mod Start   */
--    AND ooha.ordered_date             < cd_process_date + 1                                     -- Æ±út
    AND ooha.ordered_date            < cd_process_date + gn_deli_ord_keep_day_e + 1               -- Æ±út + vt@CÎÛúÔI¹
/*  Ver1.32 Mod End   */
/*  Ver1.31 Add End   */
    ORDER BY
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--           xeh.invoice_number                 -- EDIwb_îñ.`[Ô
--          ,xel.line_no                        -- EDI¾×îñ.sm
           xeh.delivery_center_code            --1.EDIwb_îñ.[üZ^[R[h
          ,xeh.shop_code                       --2.EDIwb_îñ.XR[h
--/* 2011/02/15 Ver1.23 N.Horigome Mod START */
--          ,xeh.invoice_number                  --3.EDIwb_îñ.`[Ô
          ,ooha.cust_po_number                 --3.ówb_.ówb_.Úq­Ô
--/* 2011/02/15 Ver1.23 N.Horigome Mod END   */
-- ********* 2009/09/25 1.13 N.Maeda ADD START ********* --
          ,xeh.edi_header_info_id              -- EDIwb_îñ.EDIwb_îñID
-- ********* 2009/09/25 1.13 N.Maeda ADD  END  ********* --
          ,xel.line_no                         --4.EDI¾×îñ.sNo
          ,xel.packing_number                  --5.EDI¾×îñ.«ïÔ
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
    FOR UPDATE OF
           xeh.edi_header_info_id             -- EDIwb_îñ
          ,xel.edi_header_info_id             -- EDI¾×îñ
          NOWAIT
    ;
--
  -- ===============================
  -- [U[è`O[oRECORD^é¾
  -- ===============================
  -- wb_îñ
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE  -- [i_R[h
   ,delivery_base_name        hz_parties.party_name%TYPE                   -- [i_¼
   ,delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE   -- [i_Ji
   ,edi_chain_name            hz_parties.party_name%TYPE                   -- EDI`F[X¼
   ,edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE   -- EDI`F[XJi
  );
--
  -- `[Êv
  TYPE g_invoice_total_rtype IS RECORD(
    indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- ­Ê(o)
   ,case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- ­Ê(P[X)
   ,ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- ­Ê({[)
   ,sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- ­Ê(vAo)
   ,indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- o×Ê(o)
   ,case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- o×Ê(P[X)
   ,ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- o×Ê({[)
   ,pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- o×Ê(pbg)
   ,sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- o×Ê(vAo)
   ,indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- iÊ(o)
   ,case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- iÊ(P[X)
   ,ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- iÊ({[)
   ,sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- iÊ(vAo)
   ,case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- P[XÂû
   ,order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- ´¿àz(­)
   ,shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- ´¿àz(o×)
   ,stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- ´¿àz(i)
   ,order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- ¿àz(­)
   ,shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- ¿àz(o×)
   ,stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- ¿àz(i)
  );
--
  -- EDIwb_îñ
  TYPE g_edi_header_rtype IS RECORD(
    edi_header_info_id           xxcos_edi_headers.edi_header_info_id%TYPE           -- EDIwb_îñID
   ,process_date                 xxcos_edi_headers.process_date%TYPE                 -- ú
   ,process_time                 xxcos_edi_headers.process_time%TYPE                 -- 
   ,base_code                    xxcos_edi_headers.base_code%TYPE                    -- _(å)R[h
   ,base_name                    xxcos_edi_headers.base_name%TYPE                    -- _¼(³®¼)
   ,base_name_alt                xxcos_edi_headers.base_name_alt%TYPE                -- _¼(Ji)
   ,customer_code                xxcos_edi_headers.customer_code%TYPE                -- ÚqR[h
   ,customer_name                xxcos_edi_headers.customer_name%TYPE                -- Úq¼(¿)
   ,customer_name_alt            xxcos_edi_headers.customer_name_alt%TYPE            -- Úq¼(Ji)
   ,shop_code                    xxcos_edi_headers.shop_code%TYPE                    -- XR[h
   ,shop_name                    xxcos_edi_headers.shop_name%TYPE                    -- X¼(¿)
   ,shop_name_alt                xxcos_edi_headers.shop_name_alt%TYPE                -- X¼(Ji)
   ,center_delivery_date         xxcos_edi_headers.center_delivery_date%TYPE         -- Z^[[iú
   ,order_no_ebs                 xxcos_edi_headers.order_no_ebs%TYPE                 -- óNo(EBS)
   ,contact_to                   xxcos_edi_headers.contact_to%TYPE                   -- Aæ
   ,area_code                    xxcos_edi_headers.area_code%TYPE                    -- næR[h
   ,area_name                    xxcos_edi_headers.area_name%TYPE                    -- næ¼(¿)
   ,area_name_alt                xxcos_edi_headers.area_name_alt%TYPE                -- næ¼(Ji)
   ,vendor_code                  xxcos_edi_headers.vendor_code%TYPE                  -- æøæR[h
   ,vendor_name                  xxcos_edi_headers.vendor_name%TYPE                  -- æøæ¼(¿)
   ,vendor_name1_alt             xxcos_edi_headers.vendor_name1_alt%TYPE             -- æøæ¼1(Ji)
   ,vendor_name2_alt             xxcos_edi_headers.vendor_name2_alt%TYPE             -- æøæ¼2(Ji)
   ,vendor_tel                   xxcos_edi_headers.vendor_tel%TYPE                   -- æøæTEL
   ,vendor_charge                xxcos_edi_headers.vendor_charge%TYPE                -- æøæSÒ
   ,vendor_address               xxcos_edi_headers.vendor_address%TYPE               -- æøæZ(¿)
   ,delivery_schedule_time       xxcos_edi_headers.delivery_schedule_time%TYPE       -- [i\èÔ
   ,carrier_means                xxcos_edi_headers.carrier_means%TYPE                -- ^èi
   ,eos_handwriting_class        xxcos_edi_headers.eos_handwriting_class%TYPE        -- EOS¥èæª
   ,invoice_indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- (`[v)­Ê(o)
   ,invoice_case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- (`[v)­Ê(P[X)
   ,invoice_ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- (`[v)­Ê({[)
   ,invoice_sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- (`[v)­Ê(vAo)
   ,invoice_indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- (`[v)o×Ê(o)
   ,invoice_case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- (`[v)o×Ê(P[X)
   ,invoice_ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- (`[v)o×Ê({[)
   ,invoice_pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- (`[v)o×Ê(pbg)
   ,invoice_sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- (`[v)o×Ê(vAo)
   ,invoice_indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- (`[v)iÊ(o)
   ,invoice_case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- (`[v)iÊ(P[X)
   ,invoice_ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- (`[v)iÊ({[)
   ,invoice_sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- (`[v)iÊ(vAo)
   ,invoice_case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- (`[v)P[XÂû
   ,invoice_fold_container_qty   xxcos_edi_headers.invoice_fold_container_qty%TYPE   -- (`[v)IR(o)Âû
   ,invoice_order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- (`[v)´¿àz(­)
   ,invoice_shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- (`[v)´¿àz(o×)
   ,invoice_stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- (`[v)´¿àz(i)
   ,invoice_order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- (`[v)¿àz(­)
   ,invoice_shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- (`[v)¿àz(o×)
   ,invoice_stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- (`[v)¿àz(i)
/* 2010/03/09 Ver1.16 Add Start */
   ,total_order_price_amt        xxcos_edi_headers.total_order_price_amt%TYPE        -- (v)¿àz(­)
   ,total_shipping_price_amt     xxcos_edi_headers.total_shipping_price_amt%TYPE     -- (v)¿àz(o×)
/* 2010/03/09 Ver1.16 Add  End  */
   ,edi_delivery_schedule_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE   -- EDI[i\èMÏtO
  );
--
  -- EDI¾×îñ
  TYPE g_edi_line_rtype IS RECORD(
    edi_line_info_id     xxcos_edi_lines.edi_line_info_id%TYPE     -- EDI¾×îñID
   ,edi_header_info_id   xxcos_edi_lines.edi_header_info_id%TYPE   -- EDIwb_îñID
   ,line_no              xxcos_edi_lines.line_no%TYPE              -- sNo
   ,stockout_class       xxcos_edi_lines.stockout_class%TYPE       -- iæª
   ,stockout_reason      xxcos_edi_lines.stockout_reason%TYPE      -- iR
   ,product_code_itouen  xxcos_edi_lines.product_code_itouen%TYPE  -- ¤iR[h(É¡)
   ,jan_code             xxcos_edi_lines.jan_code%TYPE             -- JANR[h
   ,itf_code             xxcos_edi_lines.itf_code%TYPE             -- ITFR[h
   ,prod_class           xxcos_edi_lines.prod_class%TYPE           -- ¤iæª
   ,product_name         xxcos_edi_lines.product_name%TYPE         -- ¤i¼(¿)
   ,product_name2_alt    xxcos_edi_lines.product_name2_alt%TYPE    -- ¤i¼2(Ji)
   ,item_standard2       xxcos_edi_lines.item_standard2%TYPE       -- Ki2
   ,num_of_cases         xxcos_edi_lines.num_of_cases%TYPE         -- P[Xü
   ,num_of_ball          xxcos_edi_lines.num_of_ball%TYPE          -- {[ü
   ,indv_order_qty       xxcos_edi_lines.indv_order_qty%TYPE       -- ­Ê(o)
   ,case_order_qty       xxcos_edi_lines.case_order_qty%TYPE       -- ­Ê(P[X)
   ,ball_order_qty       xxcos_edi_lines.ball_order_qty%TYPE       -- ­Ê({[)
   ,sum_order_qty        xxcos_edi_lines.sum_order_qty%TYPE        -- ­Ê(vAo)
   ,indv_shipping_qty    xxcos_edi_lines.indv_shipping_qty%TYPE    -- o×Ê(o)
   ,case_shipping_qty    xxcos_edi_lines.case_shipping_qty%TYPE    -- o×Ê(P[X)
   ,ball_shipping_qty    xxcos_edi_lines.ball_shipping_qty%TYPE    -- o×Ê({[)
   ,pallet_shipping_qty  xxcos_edi_lines.pallet_shipping_qty%TYPE  -- o×Ê(pbg)
   ,sum_shipping_qty     xxcos_edi_lines.sum_shipping_qty%TYPE     -- o×Ê(vAo)
   ,indv_stockout_qty    xxcos_edi_lines.indv_stockout_qty%TYPE    -- iÊ(o)
   ,case_stockout_qty    xxcos_edi_lines.case_stockout_qty%TYPE    -- iÊ(P[X)
   ,ball_stockout_qty    xxcos_edi_lines.ball_stockout_qty%TYPE    -- iÊ({[)
   ,sum_stockout_qty     xxcos_edi_lines.sum_stockout_qty%TYPE     -- iÊ(vAo)
   ,shipping_unit_price  xxcos_edi_lines.shipping_unit_price%TYPE  -- ´P¿(o×)
   ,shipping_cost_amt    xxcos_edi_lines.shipping_cost_amt%TYPE    -- ´¿àz(o×)
   ,stockout_cost_amt    xxcos_edi_lines.stockout_cost_amt%TYPE    -- ´¿àz(i)
   ,shipping_price_amt   xxcos_edi_lines.shipping_price_amt%TYPE   -- ¿àz(o×)
   ,stockout_price_amt   xxcos_edi_lines.stockout_price_amt%TYPE   -- ¿àz(i)
   ,general_add_item1    xxcos_edi_lines.general_add_item1%TYPE    -- ÄptÁÚ1
   ,general_add_item2    xxcos_edi_lines.general_add_item2%TYPE    -- ÄptÁÚ2
   ,general_add_item3    xxcos_edi_lines.general_add_item3%TYPE    -- ÄptÁÚ3
/* 2019/06/25 Ver1.29 Add Start */
   ,general_add_item10   xxcos_edi_lines.general_add_item10%TYPE   -- ÄptÁÚ10
/* 2019/06/25 Ver1.29 Add End   */
   ,item_code            xxcos_edi_lines.item_code%TYPE            -- iÚR[h
  );
--
  -- R[hè`
  gt_header_data        g_header_data_rtype;    -- wb_îñ
--
  -- ===============================
  -- [U[è`O[oTABLE^é¾
  -- ===============================
  TYPE g_edi_order_cur_ttype  IS TABLE OF edi_order_cur%ROWTYPE  INDEX BY BINARY_INTEGER;  -- EDIóf[^
  TYPE g_edi_header_ttype     IS TABLE OF g_edi_header_rtype     INDEX BY BINARY_INTEGER;  -- EDIwb_îñ
  TYPE g_edi_line_ttype       IS TABLE OF g_edi_line_rtype       INDEX BY BINARY_INTEGER;  -- EDI¾×îñ
  TYPE g_data_record_ttype    IS TABLE OF VARCHAR2(32767)        INDEX BY BINARY_INTEGER;  -- ÒWãÌf[^æ¾p
  TYPE g_data_ttype           IS TABLE OF xxcos_common2_pkg.g_layout_ttype  INDEX BY BINARY_INTEGER;  -- [i\èf[^
--
  -- e[uè`
  gt_edi_order_tab    g_edi_order_cur_ttype;  -- EDIóf[^
  gt_edi_header_tab   g_edi_header_ttype;     -- EDIwb_îñ
  gt_edi_line_tab     g_edi_line_ttype;       -- EDI¾×îñ
  gt_data_record_tab  g_data_record_ttype;    -- ÒWãÌf[^æ¾p
  gt_data_tab         g_data_ttype;           -- [i\èf[^
--
  /**********************************************************************************
   * Procedure Name   : check_param
   * Description      : p[^`FbN(A-1)
   ***********************************************************************************/
  PROCEDURE check_param(
    iv_file_name        IN  VARCHAR2,     --   1.t@C¼
    iv_make_class       IN  VARCHAR2,     --   2.ì¬æª
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI`ÇÔ
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI`ÇÔ(t@C¼p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,     --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,     --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,     --   9.næR[h
    iv_center_date      IN  VARCHAR2,     --  10.Z^[[iú
    iv_delivery_time    IN  VARCHAR2,     --  11.[i
    iv_delivery_charge  IN  VARCHAR2,     --  12.[iSÒ
    iv_carrier_means    IN  VARCHAR2,     --  13.Aèi
    iv_proc_date        IN  VARCHAR2,     --  14.ú
    iv_proc_time        IN  VARCHAR2,     --  15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
    iv_cancel_bace_code IN  VARCHAR2,     --  16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2010/06/11 Ver1.21 Add Start */
    iv_slct_base_code   IN  VARCHAR2,     --  17.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
/* 2010/07/08 Ver1.22 Add Start */
    lv_err_flag  VARCHAR2(1);     -- G[íÊ
/* 2010/07/08 Ver1.22 Add End */
    lv_errbuf    VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode   VARCHAR2(1);     -- ^[ER[h
    lv_errmsg    VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_param_msg   VARCHAR2(5000);  -- p[^[oÍp
    lv_tkn_value1  VARCHAR2(50);    -- g[Næ¾p1
    lv_tkn_value2  VARCHAR2(50);    -- g[Næ¾p2
    ln_err_chk     NUMBER(1);       -- G[`FbNp
    lv_err_msg     VARCHAR2(5000);  -- G[oÍp
    lt_make_class  fnd_lookup_values_vl.meaning%TYPE;  -- ì¬æª
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- RJgÌ¤ÊÌúoÍ
    --==============================================================
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- uì¬æªvªA'M'©'xì¬'Ìê
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- p[^oÍbZ[Wæ¾
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- AvP[V
                        ,iv_name         => cv_msg_param1      -- p[^[oÍ
                        ,iv_token_name1  => cv_tkn_param01     -- g[NR[hP
                        ,iv_token_value1 => iv_make_class      -- ì¬æª
                        ,iv_token_name2  => cv_tkn_param02     -- g[NR[hQ
                        ,iv_token_value2 => iv_edi_c_code      -- EDI`F[XR[h
                        ,iv_token_name3  => cv_tkn_param03     -- g[NR[hR
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_value3 => iv_edi_f_number    -- EDI`ÇÔ
--                        ,iv_token_name4  => cv_tkn_param04     -- g[NR[hS
--                        ,iv_token_value4 => iv_shop_date_from  -- XÜ[iúFrom
--                        ,iv_token_name5  => cv_tkn_param05     -- g[NR[hT
--                        ,iv_token_value5 => iv_shop_date_to    -- XÜ[iúTo
--                        ,iv_token_name6  => cv_tkn_param06     -- g[NR[hU
--                        ,iv_token_value6 => iv_sale_class      -- èÔÁæª
--                        ,iv_token_name7  => cv_tkn_param07     -- g[NR[hV
--                        ,iv_token_value7 => iv_area_code       -- næR[h
--                        ,iv_token_name8  => cv_tkn_param08     -- g[NR[hW
--                        ,iv_token_value8 => iv_center_date     -- Z^[[iú
                        ,iv_token_value3 => iv_edi_f_number_f  -- EDI`ÇÔ(t@C¼p)
                        ,iv_token_name4  => cv_tkn_param04     -- g[NR[hS
                        ,iv_token_value4 => iv_edi_f_number_s  -- EDI`ÇÔ(oðp)
                        ,iv_token_name5  => cv_tkn_param05     -- g[NR[hT
                        ,iv_token_value5 => iv_shop_date_from  -- XÜ[iúFrom
                        ,iv_token_name6  => cv_tkn_param06     -- g[NR[hU
                        ,iv_token_value6 => iv_shop_date_to    -- XÜ[iúTo
                        ,iv_token_name7  => cv_tkn_param07     -- g[NR[hV
                        ,iv_token_value7 => iv_sale_class      -- èÔÁæª
                        ,iv_token_name8  => cv_tkn_param08     -- g[NR[hW
                        ,iv_token_value8 => iv_area_code       -- næR[h
                        ,iv_token_name9  => cv_tkn_param09     -- g[NR[hX
                        ,iv_token_value9 => iv_center_date     -- Z^[[iú
/* 2009/05/12 Ver1.8 Mod End   */
                      );
      lv_param_msg := lv_param_msg ||
                      xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- AvP[V
                        ,iv_name         => cv_msg_param2       -- p[^[oÍ
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_name1  => cv_tkn_param09      -- g[NR[hX
                        ,iv_token_name1  => cv_tkn_param10      -- g[NR[hPO
                        ,iv_token_value1 => iv_delivery_time    -- [i
--                        ,iv_token_name2  => cv_tkn_param10      -- g[NR[hPO
                        ,iv_token_name2  => cv_tkn_param11      -- g[NR[hPP
                        ,iv_token_value2 => iv_delivery_charge  -- [iSÒ
--                        ,iv_token_name3  => cv_tkn_param11      -- g[NR[hPP
                        ,iv_token_name3  => cv_tkn_param12      -- g[NR[hPQ
                        ,iv_token_value3 => iv_carrier_means    -- Aèi
/* 2010/06/11 Ver1.21 Add Start */
                        ,iv_token_name4  => cv_tkn_param13      -- g[NR[hPR
                        ,iv_token_value4 => iv_slct_base_code   -- oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
/* 2009/05/12 Ver1.8 Mod End   */
                      );
    -- uì¬æªvªA'ð'Ìê
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- p[^oÍbZ[Wæ¾
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- AvP[V
                        ,iv_name         => cv_msg_param3       -- p[^[oÍ
                        ,iv_token_name1  => cv_tkn_param01      -- g[NR[hP
                        ,iv_token_value1 => iv_make_class       -- ì¬æª
                        ,iv_token_name2  => cv_tkn_param02      -- g[NR[hQ
                        ,iv_token_value2 => iv_edi_c_code       -- EDI`F[XR[h
                        ,iv_token_name3  => cv_tkn_param03      -- g[NR[hR
                        ,iv_token_value3 => iv_proc_date        -- ú
                        ,iv_token_name4  => cv_tkn_param04      -- g[NR[hS
                        ,iv_token_value4 => iv_proc_time        -- 
/* 2011/12/15 Ver1.26 T.Yoshimoto Mod Start E_{Ò®_02871 */
                        ,iv_token_name5  => cv_tkn_param05      -- g[NR[hT
                        ,iv_token_value5 => iv_cancel_bace_code -- ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Mod End */
                      );
    END IF;
    -- p[^ðbZ[WÉoÍ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- p[^ðOÉoÍ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add Start */
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
    -- t@C¼bZ[Wæ¾
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- AvP[V
                      ,iv_name         => cv_msg_file_nmae   -- t@C¼oÍ
                      ,iv_token_name1  => cv_tkn_file_name   -- g[NR[hP
                      ,iv_token_value1 => iv_file_name       -- t@C¼
                    );
    -- t@C¼ðbZ[WÉoÍ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    ln_err_chk := cn_0;  -- G[`FbNpÏÌú»
--
    --==============================================================
    -- K{`FbN
    --==============================================================
    -- uì¬æªvªANULLÌê
    IF ( iv_make_class IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- AvP[V
                         ,iv_name         => cv_msg_tkn_param1  -- ì¬æª
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- AvP[V
                      ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                      ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                      ,iv_token_value1 => lv_tkn_value1      -- ì¬æª
                     );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- uEDI`F[XR[hvªANULLÌê
    IF ( iv_edi_c_code IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- AvP[V
                         ,iv_name         => cv_msg_tkn_param2  -- EDI`F[XR[h
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- AvP[V
                      ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                      ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                      ,iv_token_value1 => lv_tkn_value1      -- EDI`F[XR[h
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    --==============================================================
    -- ì¬æªàe`FbN
    --==============================================================
    BEGIN
      SELECT flvv.meaning     meaning     -- ì¬æª
      INTO   lt_make_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_shipping_exp_t
      AND    flvv.lookup_code        = iv_make_class
      AND    flvv.enabled_flag       = cv_y                -- Lø
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- Æ±útªFROM-TOà
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- AvP[V
                           ,iv_name         => cv_msg_tkn_param1  -- ì¬æª
                         );
        -- bZ[Wæ¾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application    -- AvP[V
                        ,iv_name         => cv_msg_param_err  -- üÍp[^s³G[bZ[W
                        ,iv_token_name1  => cv_tkn_in_param   -- üÍp[^¼
                        ,iv_token_value1 => lv_tkn_value1     -- ì¬æª
                      );
        -- bZ[WÉoÍ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- uì¬æªvªA'M'©'xì¬'ÌêÌ`FbN
    --==============================================================
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- ut@C¼vuEDI`ÇÔ(t@C¼p)vuEDI`ÇÔ(oðp)vuXÜ[iúFromvuXÜ[iúTovÌ¢¸ê©ªANullÌê
      IF ( iv_file_name      IS NULL )
/* 2009/05/12 Ver1.8 Mod Start */
--      OR ( iv_edi_f_number   IS NULL )
      OR ( iv_edi_f_number_f IS NULL )
      OR ( iv_edi_f_number_s IS NULL )
/* 2009/05/12 Ver1.8 Mod End   */
      OR ( iv_shop_date_from IS NULL )
      OR ( iv_shop_date_to   IS NULL )
      THEN
        -- ut@C¼vªANULLÌê
        IF ( iv_file_name IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param3  -- t@C¼
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- t@C¼
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- uEDI`ÇÔ(t@C¼p)vªANULLÌê
/* 2009/05/12 Ver1.8 Mod Start */
--        IF ( iv_edi_f_number IS NULL ) THEN
        IF ( iv_edi_f_number_f IS NULL ) THEN
/* 2009/05/12 Ver1.8 Mod End   */
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param4  -- EDI`ÇÔ(t@C¼p)
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- EDI`ÇÔ(t@C¼p)
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
/* 2009/05/12 Ver1.8 Add Start */
        -- uEDI`ÇÔ(oðp)vªANULLÌê
        IF ( iv_edi_f_number_s IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param10 -- EDI`ÇÔ(oðp)
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- EDI`ÇÔ(oðp)
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
/* 2009/05/12 Ver1.8 Add End   */
--
        -- uXÜ[iúFromvªANULLÌê
        IF ( iv_shop_date_from IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param5  -- XÜ[iúFrom
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- XÜ[iúFrom
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- uXÜ[iúTovªANULLÌê
        IF ( iv_shop_date_to IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param6  -- XÜ[iúTo
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- XÜ[iúTo
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
--
      -- uXÜ[iúFromvªuXÜ[iúTovæè¢útÌê
      IF ( iv_shop_date_from > iv_shop_date_to ) THEN
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- AvP[V
                           ,iv_name         => cv_msg_tkn_param5  -- XÜ[iúFrom
                         );
        -- g[Næ¾
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- AvP[V
                           ,iv_name         => cv_msg_tkn_param6  -- XÜ[iúTo
                         );
        -- bZ[Wæ¾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- AvP[V
                        ,iv_name         => cv_msg_date_reverse  -- útt]G[bZ[W
                        ,iv_token_name1  => cv_tkn_date_from     -- útúÔ`FbNÌJnú
                        ,iv_token_value1 => lv_tkn_value1        -- XÜ[iúFrom
                        ,iv_token_name2  => cv_tkn_date_to       -- útúÔ`FbNÌI¹ú
                        ,iv_token_value2 => lv_tkn_value2        -- XÜ[iúTo
                      );
        -- bZ[WÉoÍ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- G[Lè
      END IF;
--
      -- uZ^[[iúvªüÍ³êÄ¢ÄA
      -- uZ^[[iúvªuXÜ[iúTovæè¢útÌê
      IF  ( iv_center_date IS NOT NULL )
      AND ( iv_center_date > iv_shop_date_to )
      THEN
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- AvP[V
                           ,iv_name         => cv_msg_tkn_param9  -- Z^[[iú
                         );
        -- g[Næ¾
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- AvP[V
                           ,iv_name         => cv_msg_tkn_param6  -- XÜ[iúTo
                         );
        -- bZ[Wæ¾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- AvP[V
                        ,iv_name         => cv_msg_date_reverse  -- útt]G[bZ[W
                        ,iv_token_name1  => cv_tkn_date_from     -- útúÔ`FbNÌJnú
                        ,iv_token_value1 => lv_tkn_value1        -- Z^[[iú
                        ,iv_token_name2  => cv_tkn_date_to       -- útúÔ`FbNÌI¹ú
                        ,iv_token_value2 => lv_tkn_value2        -- XÜ[iúTo
                      );
        -- bZ[WÉoÍ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- G[Lè
      END IF;
    END IF;
--
    --==============================================================
    -- uì¬æªvªA'ð'ÌêÌ`FbN
    --==============================================================
    IF ( iv_make_class = cv_make_class_release ) THEN
      -- uúvuvÌ¢¸ê©ªANullÌê
      IF ( iv_proc_date IS NULL )
      OR ( iv_proc_time IS NULL )
      THEN
        -- uúvªANULLÌê
        IF ( iv_proc_date IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param7  -- ú
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- ú
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- uvªANULLÌê
        IF ( iv_proc_time IS NULL ) THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- AvP[V
                             ,iv_name         => cv_msg_tkn_param8  -- 
                           );
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- AvP[V
                          ,iv_name         => cv_msg_param_null  -- K{üÍp[^¢ÝèG[bZ[W
                          ,iv_token_name1  => cv_tkn_in_param    -- üÍp[^¼
                          ,iv_token_value1 => lv_tkn_value1      -- 
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
    END IF;
--
    --==============================================================
    -- G[Ìê
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
    END IF;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END check_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    iv_make_class IN  VARCHAR2,     --   ì¬æª
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_tkn_value1  VARCHAR2(50);    -- g[Næ¾p1
    lv_tkn_value2  VARCHAR2(50);    -- g[Næ¾p2
    ln_err_chk     NUMBER(1);       -- G[`FbNp
    lv_err_msg     VARCHAR2(5000);  -- G[oÍp
    lv_l_meaning   fnd_lookup_values_vl.meaning%TYPE;  -- NCbNR[hðæ¾p
    lv_dummy       VARCHAR2(1);     -- CAEgè`ÌCSVwb_[p(t@C^CvªÅè·ÈÌÅgp³êÈ¢)
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
    lt_item_div_h  fnd_profile_option_values.profile_option_value%TYPE;  -- {Ð»iæª
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
    -- uì¬æªvªA'ð'Ìê
    IF ( iv_make_class = cv_make_class_release ) THEN
      RETURN;
    END IF;
--
    ln_err_chk     := cn_0;  -- G[`FbNpÏÌú»
    -- JE^Ìú»
    gn_dat_rec_cnt := cn_0;  -- oÍf[^p
    gn_head_cnt    := cn_0;  -- EDIwb_îñp
    gn_line_cnt    := cn_0;  -- EDI¾×îñp
--
    --==============================================================
    -- VXeútæ¾
    --==============================================================
    gv_f_o_date := TO_CHAR( cd_sysdate, cv_date_format );  -- ú
    gv_f_o_time := TO_CHAR( cd_sysdate, cv_time_format );  -- 
--
    --==============================================================
    -- vt@Cîñæ¾
    --==============================================================
    -- wb_R[hæª
    gv_if_header := FND_PROFILE.VALUE( cv_prf_if_header );
    IF ( gv_if_header IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf1  -- XXCCP:IFR[hæª_wb_
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- f[^R[hæª
    gv_if_data := FND_PROFILE.VALUE( cv_prf_if_data );
    IF ( gv_if_data IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf2  -- XXCCP:IFR[hæª_f[^
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- tb^R[hæª
    gv_if_footer := FND_PROFILE.VALUE( cv_prf_if_footer );
    IF ( gv_if_footer IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf3  -- XXCCP:IFR[hæª_tb^
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- UTL_MAXsTCY
    gv_utl_m_line := FND_PROFILE.VALUE( cv_prf_utl_m_line );
    IF ( gv_utl_m_line IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf4  -- XXCOS:UTL_MAXsTCY
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- AEgoEhpfBNgpX
    gv_outbound_d := FND_PROFILE.VALUE( cv_prf_outbound_d );
    IF ( gv_outbound_d IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf5  -- XXCOS:EDIónAEgoEhpfBNgpX
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- ïÐ¼
    gv_company_name := FND_PROFILE.VALUE( cv_prf_company_name );
    IF ( gv_company_name IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf6  -- XXCOS:ïÐ¼
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- ïÐ¼Ji
    gv_company_kana := FND_PROFILE.VALUE( cv_prf_company_kana );
    IF ( gv_company_kana IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf7  -- XXCOS:ïÐ¼Ji
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- P[XPÊR[h
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom_code );
    IF ( gv_case_uom_code IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf8  -- XXCOS:P[XPÊR[h
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- {[PÊR[h
    gv_ball_uom_code := FND_PROFILE.VALUE( cv_prf_ball_uom_code );
    IF ( gv_ball_uom_code IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf9  -- XXCOS:{[PÊR[h
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- ÝÉgDR[h
    gv_organization := FND_PROFILE.VALUE( cv_prf_organization );
    IF ( gv_organization IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf10  -- XXCOI:ÝÉgDR[h
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- MAXút
    gd_max_date := TO_DATE( FND_PROFILE.VALUE( cv_prf_max_date ), cv_max_date_format );
    IF ( gd_max_date IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf11  -- XXCOS:MAXút
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
/* 2010/03/19 Ver1.19 Add Start */
    -- MINút
    gd_min_date := TO_DATE( FND_PROFILE.VALUE( cv_prf_min_date ), cv_min_date_format );
    IF ( gd_min_date IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf15  -- XXCOS:MINút
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
/* 2010/03/19 Ver1.19 Add  End  */
--
    -- ïv ëID
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    IF ( gn_bks_id IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf12  -- GLïv ëID
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    -- cÆPÊ
    gn_org_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_tkn_prf13  -- cÆPÊ
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Add Start
--    gn_dum_stock_out := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_dum_stock_out ) );
--    IF ( gn_dum_stock_out IS NULL ) THEN
--      -- g[Næ¾
--      lv_tkn_value1 := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_application    -- AvP[V
--                         ,iv_name         => cv_msg_tkn_prf14  -- EDI[i\è_~[iæª
--                       );
--      -- bZ[Wæ¾
--      lv_err_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_application  -- AvP[V
--                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
--                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
--                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
--                    );
--      -- bZ[WÉoÍ
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_err_msg
--      );
--      ln_err_chk := cn_1;  -- G[Lè
--    END IF;
---- 2009/05/22 Ver1.9 Add End
/* 2010/04/15 Ver1.20 Del End   */
    --==============================================================
    -- }X^îñæ¾
    --==============================================================
    -- f[^íîñ
    BEGIN
      SELECT flvv.meaning     meaning     -- f[^í
            ,flvv.attribute1  attribute1  -- IF³Æ±nñR[h
      INTO   gt_data_type_code
            ,gt_from_series
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_data_type_code_t
/* 2009/05/12 Ver1.8 Mod Start */
/* 2009/02/27 Ver1.5 Mod Start */
      AND    flvv.lookup_code        = cv_data_type_code_c
--      AND (( iv_make_class           = cv_make_class_transe
--      AND    flvv.lookup_code        = cv_data_type_code_c )
--      OR   ( iv_make_class           = cv_make_class_label
--     AND    flvv.lookup_code        = cv_data_type_code_l ))
/* 2009/02/27 Ver1.5 Mod  End  */
/* 2009/05/12 Ver1.8 Mod  End  */
      AND    flvv.enabled_flag       = cv_y                -- Lø
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- Æ±útªFROM-TOà
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- AvP[V
                           ,iv_name         => cv_msg_tkn_tbl1  -- NCbNR[h
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- AvP[V
                           ,iv_name         => cv_msg_tkn_column1  -- f[^íR[h
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- AvP[V
                        ,iv_name         => cv_msg_mast_err  -- }X^`FbNG[bZ[W
                        ,iv_token_name1  => cv_tkn_table     -- g[NR[hP
                        ,iv_token_value1 => lv_tkn_value1    -- NCbNR[h
                        ,iv_token_name2  => cv_tkn_column    -- g[NR[hQ
                        ,iv_token_value2 => lv_tkn_value2    -- f[^íR[h
                      );
        -- bZ[WÉoÍ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- G[Lè
    END;
--
    -- EDI}Ìæª
    BEGIN
      -- bZ[Wæèàeðæ¾
      lv_l_meaning := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- AvP[V
                        ,iv_name         => cv_msg_l_meaning2  -- NCbNR[hæ¾ð(EDI}Ìæª)
                      );
      -- NCbNR[hæ¾
      SELECT flvv.lookup_code      lookup_code
      INTO   gt_edi_media_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_media_class_t
      AND    flvv.meaning            = lv_l_meaning
      AND    flvv.enabled_flag       = cv_y                -- Lø
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- Æ±útªFROM-TOà
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- AvP[V
                           ,iv_name         => cv_msg_tkn_tbl1  -- NCbNR[h
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- AvP[V
                           ,iv_name         => cv_msg_tkn_column2  -- EDI}Ìæª
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- AvP[V
                        ,iv_name         => cv_msg_mast_err  -- }X^`FbNG[bZ[W
                        ,iv_token_name1  => cv_tkn_table     -- g[NR[hP
                        ,iv_token_value1 => lv_tkn_value1    -- NCbNR[h
                        ,iv_token_name2  => cv_tkn_column    -- g[NR[hQ
                        ,iv_token_value2 => lv_tkn_value2    -- EDI}Ìæª
                      );
        -- bZ[WÉoÍ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- G[Lè
    END;
--
    --==============================================================
    -- t@CCAEgîñæ¾
    --==============================================================
    -- CAEgè`îñ
    xxcos_common2_pkg.get_layout_info(
       iv_file_type        =>  cv_0                -- t@C`®(Åè·)
      ,iv_layout_class     =>  cv_0                -- îñæª(ón)
      ,ov_data_type_table  =>  gt_data_type_table  -- f[^^\
      ,ov_csv_header       =>  lv_dummy            -- CSVwb_
      ,ov_errbuf           =>  lv_errbuf           -- G[bZ[W
      ,ov_retcode          =>  lv_retcode          -- ^[R[h
      ,ov_errmsg           =>  lv_errmsg           -- [U[EG[EbZ[W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- AvP[V
                         ,iv_name         => cv_msg_tkn_layout  -- ónÚCAEg
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       -- AvP[V
                      ,iv_name         => cv_msg_file_inf_err  -- IFt@CCAEgè`îñæ¾G[bZ[W
                      ,iv_token_name1  => cv_tkn_layout        -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1        -- ónÚCAEg
                   );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
    --==============================================================
    -- ÝÉgDIDæ¾
    --==============================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_organization  -- ÝÉgDR[h
                          );
    IF ( gn_organization_id IS NULL ) THEN
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application   -- AvP[V
                      ,iv_name         => cv_msg_org_err   -- ÝÉgDIDæ¾G[bZ[W
                      ,iv_token_name1  => cv_tkn_org_code  -- g[NR[hP
                      ,iv_token_value1 => gv_organization  -- ÝÉgDR[h
                   );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
--
-- ********** 2009/09/03 1.12 N.Maeda ADD START ********** --
    -- =============================================================
    -- vt@CuXXCOS:{Ð¤iæªvæ¾
    -- =============================================================
    lt_item_div_h := FND_PROFILE.VALUE(ct_item_div_h);
--
    IF ( lt_item_div_h IS NULL ) THEN
--
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- AvP[V
                         ,iv_name         => cv_msg_item_div_h  -- {Ð»iæª
                       );
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => lv_tkn_value1   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      lv_errbuf  := lv_err_msg;
      ln_err_chk := cn_1;  -- G[Lè
--
    ELSE
      -- =============================================================
      -- JeSZbgIDæ¾
      -- =============================================================
      BEGIN
        SELECT  mcst.category_set_id
        INTO    gt_category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
      EXCEPTION
        WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_msg_category_err
                           );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- G[Lè
      END;
--
    END IF;
-- ********** 2009/09/03 1.12 N.Maeda ADD  END  ********** --
--
/*  Ver1.31 Add Start   */
    -- [ipóÛú
    gn_deli_ord_keep_day      := TO_NUMBER( FND_PROFILE.VALUE( cv_deli_ord_keep_day ) );
    IF ( gn_deli_ord_keep_day IS NULL ) THEN
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => cv_deli_ord_keep_day   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
/*  Ver1.31 Add End   */
/*  Ver1.32 Add Start   */
    -- [ipóÛúI¹
    gn_deli_ord_keep_day_e      := TO_NUMBER( FND_PROFILE.VALUE( cv_deli_ord_keep_day_e ) );
    IF ( gn_deli_ord_keep_day_e IS NULL ) THEN
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- AvP[V
                      ,iv_name         => cv_msg_prf_err  -- vt@Cæ¾G[
                      ,iv_token_name1  => cv_tkn_profile  -- g[NR[hP
                      ,iv_token_value1 => cv_deli_ord_keep_day_e   -- vt@C¼
                    );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- G[Lè
    END IF;
/*  Ver1.32 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    BEGIN
      SELECT oos.order_source_id     order_source_id    -- ó\[XID
      INTO   gt_order_source_online
      FROM   oe_order_sources        oos                -- ó\[Xe[u
      WHERE  oos.name                = cv_online
      AND    oos.enabled_flag        = cv_y;
    EXCEPTION
      WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_get_order_source_id_err,
                           iv_token_name1  =>  cv_order_source,
                           iv_token_value1 =>  cv_online
                           );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- G[Lè
      END;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
    --==============================================================
    -- G[Ìê
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_data_check_expt;
    END IF;
--
  EXCEPTION
    -- *** f[^`FbNG[ ***
    WHEN global_data_check_expt THEN
      -- lªNULLAàµ­ÍÎÛO
      IF ( lv_errbuf IS NULL ) THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- »Ì¼áO
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_manual_order
   * Description      : èüÍf[^o^(A-3)
   ***********************************************************************************/
  PROCEDURE get_manual_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI`ÇÔ(oðp)
    iv_shop_date_from   IN  VARCHAR2,     --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,     --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,     --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,     --   9.næR[h
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_manual_order'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
/* 2010/07/08 Ver1.22 Add Start */
    lv_err_flag VARCHAR2(1);     -- G[íÊ
/* 2010/07/08 Ver1.22 Add End */
    lv_errbuf   VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode  VARCHAR2(1);     -- ^[ER[h
    lv_errmsg   VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_tkn_value1  VARCHAR2(50);    -- g[Næ¾p1
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- èüÍf[^o^
    --==============================================================
    xxcos_edi_common_pkg.edi_manual_order_acquisition(
       iv_edi_chain_code          => iv_edi_c_code                               -- EDI`F[XR[h
      ,iv_edi_forward_number      => iv_edi_f_number                             -- EDI`ÇÔ
      ,id_shop_delivery_date_from => TO_DATE(iv_shop_date_from, cv_date_format)  -- XÜ[iú(From)
      ,id_shop_delivery_date_to   => TO_DATE(iv_shop_date_to, cv_date_format)    -- XÜ[iú(To)
      ,iv_regular_ar_sale_class   => iv_sale_class                               -- èÔÁæª
      ,iv_area_code               => iv_area_code                                -- næR[h
      ,id_center_delivery_date    => NULL                                        -- Z^[[iú
      ,in_organization_id         => gn_organization_id                          -- ÝÉgDID
/* 2010/07/08 Ver1.22 Add Start */
      ,iv_boot_flag               => cv_boot_para                                -- N®íÊ(1FRJg)
      ,ov_err_flag                => lv_err_flag                                 -- G[íÊ
/* 2010/07/08 Ver1.22 Add End */
      ,ov_errbuf                  => lv_errbuf                                   -- G[EbZ[W
      ,ov_retcode                 => lv_retcode                                  -- ^[ER[h
      ,ov_errmsg                  => lv_errmsg                                   -- [U[EG[EbZ[W
    );
/* 2010/07/08 Ver1.22 Mod Start */
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      -- bZ[Wæ¾
--      ov_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_application       -- AvP[V
--                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI¤ÊÖG[bZ[W
--                     ,iv_token_name1  => cv_tkn_err_msg       -- g[NR[hP
--                     ,iv_token_value1 => lv_errmsg            -- G[EbZ[W
--                   );
--      RAISE global_api_others_expt;
--    END IF;
    -- ^[R[hª³íÈOÌê
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_item_conv_expt;
    END IF;
/* 2010/07/08 Ver1.22 Mod End */
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
/* 2010/07/08 Ver1.22 Add Start */
    -- *** ÚqiÚ`FbNáOnh ***
    WHEN global_item_conv_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
/* 2010/07/08 Ver1.22 Add End */
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END get_manual_order;
--
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : t@Cú(A-4)
   ***********************************************************************************/
  PROCEDURE output_header(
    iv_file_name        IN  VARCHAR2,     --   1.t@C¼
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI`ÇÔ(t@C¼p)
/* 2010/06/11 Ver1.21 Add Start */
    iv_iv_slct_base_code IN VARCHAR2,     --   16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
/* 2011/09/03 Ver1.25 Mod Start */
--/* 2009/04/28 Ver1.7 Mod Start */
----    lv_header_output  VARCHAR2(1000);  -- wb_[oÍp
--    lv_header_output  VARCHAR2(5000);  -- wb_[oÍp
    lv_header_output  VARCHAR2(32767);  -- wb_[oÍp
--/* 2009/04/28 Ver1.7 Mod End   */
/* 2011/09/03 Ver1.25 Mod End   */
    ln_dummy          NUMBER;          -- wb_oÍÌR[hp(gp³êÈ¢)
--
    -- *** [JEJ[\ ***
    -- _îñ
    CURSOR cust_base_cur
    IS
      SELECT  hca.account_number             delivery_base_code      -- [i_R[h
             ,hp.party_name                  delivery_base_name      -- [i_¼
             ,hp.organization_name_phonetic  delivery_base_phonetic  -- [i_¼Ji
      FROM    hz_cust_accounts        hca   -- _(Úq)
             ,hz_parties              hp    -- _(p[eB)
             ,hz_party_sites          hps   -- p[eBTCg
             ,hz_cust_acct_sites_all  hcas  -- ÚqÝn
      WHERE   hcas.party_site_id  = hps.party_site_id     -- (ÚqÝn = p[eBTCg)
      AND     hca.cust_account_id = hcas.cust_account_id  -- (_(Úq) = ÚqÝn)
      AND     hca.party_id        = hp.party_id           -- (_(Úq) = _(p[eB))
      AND     hcas.org_id         = gn_org_id             -- cÆPÊ
/* 2010/06/11 Ver1.21 Add Start */
      AND     hca.account_number  = iv_iv_slct_base_code
/* 2010/06/11 Ver1.21 Add End */
/* 2010/02/26 Ver1.15 Mod Start */
--                ( SELECT  xca1.delivery_base_code
--                  FROM    hz_cust_accounts     hca1  -- Úq
--                         ,hz_parties           hp1   -- p[eB
--                         ,xxcmm_cust_accounts  xca1  -- ÚqÇÁîñ
--                  WHERE   hp1.duns_number_c       IN (cv_cust_status_30   -- ÚqXe[^X(³FÏ)
--                                                     ,cv_cust_status_40)  -- ÚqXe[^X(Úq)
--                  AND     hca1.party_id            =  hp1.party_id        -- (Úq = p[eB)
--                  AND     hca1.status              =  cv_status_a         -- Xe[^X(ÚqLø)
--                  AND     hca1.customer_class_code =  cv_cust_code_cust   -- Úqæª(Úq)
--                  AND     hca1.cust_account_id     =  xca1.customer_id    -- (Úq = ÚqÇÁ)
--                  AND     xca1.chain_store_code    =  iv_edi_c_code       -- EDI`F[XR[h
--                  AND     ROWNUM                   =  cn_1
--                )
/* 2010/06/11 Ver1.21 Del Start */
--                ( SELECT xuif.base_code  AS base_code     -- OC[U[Ì_R[h(V)
--                  FROM   xxcos_user_info_v xuif           -- [Uîñr[
--                  WHERE  xuif.user_id = cn_created_by     -- OC[U[
--                )
/* 2010/06/11 Ver1.21 Del End */
/* 2010/02/26 Ver1.15 Mod  End  */
      ;
    -- EDI`F[Xîñ
    CURSOR edi_chain_cur
    IS
      SELECT  hp.party_name                  edi_chain_name      -- EDI`F[X¼
             ,hp.organization_name_phonetic  edi_chain_phonetic  -- EDI`F[X¼Ji
      FROM    hz_parties           hp    -- p[eB
             ,hz_cust_accounts     hca   -- Úq
             ,xxcmm_cust_accounts  xca   -- ÚqÇÁîñ
      WHERE   hca.party_id            = hp.party_id         -- (Úq = p[eB)
      AND     hca.customer_class_code = cv_cust_code_chain  -- Úqæª(`F[X)
      AND     hca.cust_account_id     = xca.customer_id     -- (Úq = ÚqÇÁ)
      AND     hca.status              = cv_status_a         -- Xe[^X(ÚqLø)
      AND     xca.chain_store_code    = iv_edi_c_code       -- EDI`F[XR[h
      ;
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
    --==============================================================
    -- t@CI[v
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                        location      =>  gv_outbound_d  -- AEgoEhpfBNgpX
                       ,filename      =>  iv_file_name   -- t@C¼
                       ,open_mode     =>  cv_w           -- I[v[h
                       ,max_linesize  =>  gv_utl_m_line  -- MAXTCY
                     );
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- AvP[V
                       ,iv_name         => cv_msg_file_o_err  -- EDI¤ÊÖG[bZ[W
                       ,iv_token_name1  => cv_tkn_file_name   -- g[NR[hP
                       ,iv_token_value1 => iv_file_name       -- t@C¼
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- wb_R[hoÍ
    --==============================================================
    -- _îñæ¾
    OPEN  cust_base_cur;
    FETCH cust_base_cur
      INTO  gt_header_data.delivery_base_code        -- [i_R[h
           ,gt_header_data.delivery_base_name        -- [i_¼
           ,gt_header_data.delivery_base_phonetic    -- [i_¼Ji
    ;
    -- f[^ªæ¾Å«È¢êG[
    IF ( cust_base_cur%NOTFOUND )THEN
      CLOSE cust_base_cur;
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- AvP[V
                     ,iv_name         => cv_msg_base_inf_err  -- _îñæ¾G[bZ[W
                     ,iv_token_name1  => cv_tkn_code          -- g[NR[hP
                     ,iv_token_value1 => iv_edi_c_code        -- EDI`F[XR[h
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE cust_base_cur;
--
    -- EDI`F[Xîñæ¾
    OPEN  edi_chain_cur;
    FETCH edi_chain_cur
      INTO  gt_header_data.edi_chain_name           -- EDI`F[X¼
           ,gt_header_data.edi_chain_name_phonetic  -- EDI`F[XJi
    ;
    -- f[^ªæ¾Å«È¢êG[
    IF ( edi_chain_cur%NOTFOUND )THEN
      CLOSE edi_chain_cur;
      -- bZ[W
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- AvP[V
                     ,iv_name         => cv_msg_chain_inf_err -- `F[Xîñæ¾G[bZ[W
                     ,iv_token_name1  => cv_tkn_chain_code    -- g[NR[hP
                     ,iv_token_value1 => iv_edi_c_code        -- EDI`F[XR[h
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE edi_chain_cur;
--
    --==============================================================
    -- EDIwb_t^
    --==============================================================
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_header    -- t^æª
      ,iv_from_series     =>  gt_from_series  -- IF³Æ±nñR[h
      ,iv_base_code       =>  gt_header_data.delivery_base_code
/* 2009/02/24 Ver1.2 Mod Start */
--    ,iv_base_name       =>  gt_header_data.delivery_base_name
      ,iv_base_name       =>  SUBSTRB(gt_header_data.delivery_base_name, 1, 40)
      ,iv_chain_code      =>  iv_edi_c_code
--    ,iv_chain_name      =>  gt_header_data.edi_chain_name
      ,iv_chain_name      =>  SUBSTRB(gt_header_data.edi_chain_name, 1, 40)
/* 2009/02/24 Ver1.2 Mod  End  */
      ,iv_data_kind       =>  gt_data_type_code
      ,iv_row_number      =>  iv_edi_f_number
      ,in_num_of_records  =>  ln_dummy
      ,ov_retcode         =>  lv_retcode
      ,ov_output          =>  lv_header_output
      ,ov_errbuf          =>  lv_errbuf
      ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- bZ[Wæ¾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- AvP[V
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI¤ÊÖG[bZ[W
                     ,iv_token_name1  => cv_tkn_err_msg       -- g[NR[hP
                     ,iv_token_value1 => lv_errmsg            -- G[EbZ[W
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- t@CoÍ
    --==============================================================
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- t@Cnh
      ,buffer => lv_header_output  -- oÍ¶(wb_)
    );
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : input_edi_order
   * Description      : EDIóf[^o(A-5)
   ***********************************************************************************/
  PROCEDURE input_edi_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI`ÇÔ(oðp)
    iv_shop_date_from   IN  VARCHAR2,     --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,     --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,     --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,     --   9.næR[h
/* 2010/03/19 Ver1.19 Add Start */
    iv_delivery_charge  IN  VARCHAR2,     --  12.[iSÒ
/* 2010/03/19 Ver1.19 Add  End  */
/* 2010/06/11 Ver1.21 Add Start */
    iv_slct_base_code   IN  VARCHAR2,     --  16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_edi_order'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_tkn_value1  VARCHAR2(50);    -- g[Næ¾p1
    lv_tkn_value2  VARCHAR2(50);    -- g[Næ¾p2
    lv_err_msg     VARCHAR2(5000);  -- G[oÍp
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- üÍp[^ððÖÝè
    --==============================================================
    gt_edi_c_code     := iv_edi_c_code;                               -- EDI`F[XR[h
    gt_edi_f_number   := iv_edi_f_number;                             -- EDI`ÇÔ
    gt_shop_date_from := TO_DATE(iv_shop_date_from, cv_date_format);  -- XÜ[iúFrom
    gt_shop_date_to   := TO_DATE(iv_shop_date_to, cv_date_format);    -- XÜ[iúTo
    gt_sale_class     := iv_sale_class;                               -- èÔÁæª
    gt_area_code      := iv_area_code;                                -- næR[h
/* 2010/03/19 Ver1.19 Add Start */
    gt_delivery_charge := iv_delivery_charge;                         -- [iSÒ
/* 2010/03/19 Ver1.19 Add  End  */
/* 2010/06/11 Ver1.21 Add Start */
    gt_slct_base_code  := iv_slct_base_code;                          -- oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
--
    --==============================================================
    -- EDIóf[^o
    --==============================================================
    BEGIN
      OPEN  edi_order_cur;
      FETCH edi_order_cur BULK COLLECT INTO gt_edi_order_tab;
      CLOSE edi_order_cur;
    EXCEPTION
      -- *** bNG[ ***
      WHEN lock_expt THEN
        -- J[\N[Y
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- AvP[V
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIwb_îñe[u
                         );
        -- bZ[Wæ¾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- AvP[V
                       ,iv_name         => cv_msg_lock_err    -- bNG[bZ[W
                       ,iv_token_name1  => cv_tkn_table       -- g[NR[hP
                       ,iv_token_value1 => lv_tkn_value1      -- EDIwb_îñe[u
                     );
        RAISE global_api_others_expt;
--
      -- *** OTHERSáOnh ***
      WHEN OTHERS THEN
        -- J[\N[Y
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- AvP[V
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIwb_îñe[u
                         );
        -- bZ[Wæ¾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- AvP[V
                       ,iv_name         => cv_msg_data_get_err  -- f[^oG[bZ[W
                       ,iv_token_name1  => cv_tkn_table_name    -- g[NR[hP
                       ,iv_token_value1 => lv_tkn_value1        -- EDIwb_îñe[u
                       ,iv_token_name2  => cv_tkn_key_data      -- g[NR[hQ
                       ,iv_token_value2 => iv_edi_c_code        -- EDI`F[XR[h
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- ÎÛR[hæ¾
    --==============================================================
    gn_target_cnt := gt_edi_order_tab.COUNT;
    IF ( gn_target_cnt = cn_0 ) THEN
      -- bZ[Wæ¾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application    -- AvP[V
                      ,iv_name         => cv_msg_no_target  -- ÎÛf[^ÈµbZ[W
                   );
      -- bZ[WÉoÍ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    END IF;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END input_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : format_data
   * Description      : f[^¬`(A-7)
   ***********************************************************************************/
  PROCEDURE format_data(
    iv_make_class       IN  VARCHAR2,               --   2.ì¬æª
    ir_total_rec        IN  g_invoice_total_rtype,  -- `[v
    it_head_id          IN  xxcos_edi_headers.edi_header_info_id%TYPE,          -- EDIwb_îñID
    it_delivery_flag    IN  xxcos_edi_headers.edi_delivery_schedule_flag%TYPE,  -- EDI[i\èMÏtO
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'format_data'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
    --==============================================================
    -- EDIwb_îñÒW
    --==============================================================
    gn_head_cnt := gn_head_cnt + cn_1;
    gt_edi_header_tab(gn_head_cnt).edi_header_info_id          := it_head_id;                                     -- EDIwb_îñID
    gt_edi_header_tab(gn_head_cnt).process_date                := TO_DATE(gv_f_o_date, cv_date_format);           -- ú
    gt_edi_header_tab(gn_head_cnt).process_time                := gv_f_o_time;                                    -- 
    gt_edi_header_tab(gn_head_cnt).base_code                   := gt_data_tab(cn_1)(cv_base_code);                -- _(å)R[h
/* 2009/02/24 Ver1.2 Mod Start */
--  gt_edi_header_tab(gn_head_cnt).base_name                   := gt_data_tab(cn_1)(cv_base_name);                -- _¼(³®¼)
--  gt_edi_header_tab(gn_head_cnt).base_name_alt               := gt_data_tab(cn_1)(cv_base_name_alt);            -- _¼(Ji)
    gt_edi_header_tab(gn_head_cnt).base_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_base_name), 1, 40);      -- _¼(³®¼)
    gt_edi_header_tab(gn_head_cnt).base_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_base_name_alt), 1, 25);  -- _¼(Ji)
    gt_edi_header_tab(gn_head_cnt).customer_code               := gt_data_tab(cn_1)(cv_cust_code);                -- ÚqR[h
--  gt_edi_header_tab(gn_head_cnt).customer_name               := gt_data_tab(cn_1)(cv_cust_name);                -- Úq¼(¿)
--  gt_edi_header_tab(gn_head_cnt).customer_name_alt           := gt_data_tab(cn_1)(cv_cust_name_alt);            -- Úq¼(Ji)
    gt_edi_header_tab(gn_head_cnt).customer_name               := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name), 1, 100);     -- Úq¼(¿)
    gt_edi_header_tab(gn_head_cnt).customer_name_alt           := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name_alt), 1, 50);  -- Úq¼(Ji)
    gt_edi_header_tab(gn_head_cnt).shop_code                   := gt_data_tab(cn_1)(cv_shop_code);                -- XR[h
--  gt_edi_header_tab(gn_head_cnt).shop_name                   := gt_data_tab(cn_1)(cv_shop_name);                -- X¼(¿)
--  gt_edi_header_tab(gn_head_cnt).shop_name_alt               := gt_data_tab(cn_1)(cv_shop_name_alt);            -- X¼(Ji)
    gt_edi_header_tab(gn_head_cnt).shop_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name), 1, 40);      -- X¼(¿)
    gt_edi_header_tab(gn_head_cnt).shop_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name_alt), 1, 20);  -- X¼(Ji)
    gt_edi_header_tab(gn_head_cnt).center_delivery_date        := TO_DATE(gt_data_tab(cn_1)(cv_cent_delv_date), cv_date_format);  -- Z^[[iú
    gt_edi_header_tab(gn_head_cnt).order_no_ebs                := gt_data_tab(cn_1)(cv_order_no_ebs);             -- óNo(EBS)
    gt_edi_header_tab(gn_head_cnt).contact_to                  := gt_data_tab(cn_1)(cv_contact_to);               -- Aæ
    gt_edi_header_tab(gn_head_cnt).area_code                   := gt_data_tab(cn_1)(cv_area_code);                -- næR[h
--  gt_edi_header_tab(gn_head_cnt).area_name                   := gt_data_tab(cn_1)(cv_area_name);                -- næ¼(¿)
--  gt_edi_header_tab(gn_head_cnt).area_name_alt               := gt_data_tab(cn_1)(cv_area_name_alt);            -- næ¼(Ji)
    gt_edi_header_tab(gn_head_cnt).area_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_area_name), 1, 40);      -- næ¼(¿)
    gt_edi_header_tab(gn_head_cnt).area_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_area_name_alt), 1, 20);  -- næ¼(Ji)
    gt_edi_header_tab(gn_head_cnt).vendor_code                 := gt_data_tab(cn_1)(cv_vendor_code);              -- æøæR[h
--  gt_edi_header_tab(gn_head_cnt).vendor_name                 := gt_data_tab(cn_1)(cv_vendor_name);              -- æøæ¼(¿)
--  gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := gt_data_tab(cn_1)(cv_vendor_name1_alt);         -- æøæ¼1(Ji)
--  gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := gt_data_tab(cn_1)(cv_vendor_name2_alt);         -- æøæ¼2(Ji)
    gt_edi_header_tab(gn_head_cnt).vendor_name                 := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name), 1, 40);       -- æøæ¼(¿)
    gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name1_alt), 1, 20);  -- æøæ¼1(Ji)
    gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name2_alt), 1, 20);  -- æøæ¼2(Ji)
--  gt_edi_header_tab(gn_head_cnt).vendor_tel                  := gt_data_tab(cn_1)(cv_vendor_tel);               -- æøæTEL
--  gt_edi_header_tab(gn_head_cnt).vendor_charge               := gt_data_tab(cn_1)(cv_vendor_charge);            -- æøæSÒ
--  gt_edi_header_tab(gn_head_cnt).vendor_address              := gt_data_tab(cn_1)(cv_vendor_address);           -- æøæZ(¿)
    gt_edi_header_tab(gn_head_cnt).vendor_tel                  := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_tel), 1, 12);      -- æøæTEL
    gt_edi_header_tab(gn_head_cnt).vendor_charge               := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_charge), 1, 12);   -- æøæSÒ
    gt_edi_header_tab(gn_head_cnt).vendor_address              := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_address), 1, 40);  -- æøæZ(¿)
/* 2009/02/24 Ver1.2 Mod  End  */
    gt_edi_header_tab(gn_head_cnt).delivery_schedule_time      := gt_data_tab(cn_1)(cv_delv_schedule_time);       -- [i\èÔ
    gt_edi_header_tab(gn_head_cnt).carrier_means               := gt_data_tab(cn_1)(cv_carrier_means);            -- ^èi
    gt_edi_header_tab(gn_head_cnt).eos_handwriting_class       := gt_data_tab(cn_1)(cv_eos_handwriting_class);    -- EOS¥èæª
    gt_edi_header_tab(gn_head_cnt).invoice_indv_order_qty      := ir_total_rec.indv_order_qty;                    -- (`[v)­Ê(o)
    gt_edi_header_tab(gn_head_cnt).invoice_case_order_qty      := ir_total_rec.case_order_qty;                    -- (`[v)­Ê(P[X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_order_qty      := ir_total_rec.ball_order_qty;                    -- (`[v)­Ê({[)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_order_qty       := ir_total_rec.sum_order_qty;                     -- (`[v)­Ê(vAo)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_shipping_qty   := ir_total_rec.indv_shipping_qty;                 -- (`[v)o×Ê(o)
    gt_edi_header_tab(gn_head_cnt).invoice_case_shipping_qty   := ir_total_rec.case_shipping_qty;                 -- (`[v)o×Ê(P[X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_shipping_qty   := ir_total_rec.ball_shipping_qty;                 -- (`[v)o×Ê({[)
    gt_edi_header_tab(gn_head_cnt).invoice_pallet_shipping_qty := ir_total_rec.pallet_shipping_qty;               -- (`[v)o×Ê(pbg)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_shipping_qty    := ir_total_rec.sum_shipping_qty;                  -- (`[v)o×Ê(vAo)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_stockout_qty   := ir_total_rec.indv_stockout_qty;                 -- (`[v)iÊ(o)
    gt_edi_header_tab(gn_head_cnt).invoice_case_stockout_qty   := ir_total_rec.case_stockout_qty;                 -- (`[v)iÊ(P[X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_stockout_qty   := ir_total_rec.ball_stockout_qty;                 -- (`[v)iÊ({[)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_stockout_qty    := ir_total_rec.sum_stockout_qty;                  -- (`[v)iÊ(vAo)
    gt_edi_header_tab(gn_head_cnt).invoice_case_qty            := ir_total_rec.case_qty;                          -- (`[v)P[XÂû
    gt_edi_header_tab(gn_head_cnt).invoice_fold_container_qty  := gt_data_tab(cn_1)(cv_invc_fold_container_qty);  -- (`[v)IR(o)Âû
    gt_edi_header_tab(gn_head_cnt).invoice_order_cost_amt      := ir_total_rec.order_cost_amt;                    -- (`[v)´¿àz(­)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_cost_amt   := ir_total_rec.shipping_cost_amt;                 -- (`[v)´¿àz(o×)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_cost_amt   := ir_total_rec.stockout_cost_amt;                 -- (`[v)´¿àz(i)
    gt_edi_header_tab(gn_head_cnt).invoice_order_price_amt     := ir_total_rec.order_price_amt;                   -- (`[v)¿àz(­)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_price_amt  := ir_total_rec.shipping_price_amt;                -- (`[v)¿àz(o×)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_price_amt  := ir_total_rec.stockout_price_amt;                -- (`[v)¿àz(i)
/* 2010/03/09 Ver1.16 Add Start */
    gt_edi_header_tab(gn_head_cnt).total_order_price_amt       := ir_total_rec.order_price_amt;                   -- (v)¿àz(­)
    gt_edi_header_tab(gn_head_cnt).total_shipping_price_amt    := ir_total_rec.shipping_price_amt;                -- (v)¿àz(o×)
/* 2009/03/09 Ver1.16 Add  End  */
    -- uì¬æªvªA'M'Ìê
    IF ( iv_make_class = cv_make_class_transe ) THEN
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := cv_y;                                         -- EDI[i\èMÏtO
    ELSE
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := it_delivery_flag;                             -- EDI[i\èMÏtO
    END IF;
--
    <<format_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_tab.COUNT LOOP
      --==============================================================
      -- `[vÒW
      --==============================================================
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_order_qty)   := ir_total_rec.indv_order_qty;       -- (`[v)­Ê(o)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_order_qty)   := ir_total_rec.case_order_qty;       -- (`[v)­Ê(P[X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_order_qty)   := ir_total_rec.ball_order_qty;       -- (`[v)­Ê({[)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_order_qty)    := ir_total_rec.sum_order_qty;        -- (`[v)­Ê(vAo)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_ship_qty)    := ir_total_rec.indv_shipping_qty;    -- (`[v)o×Ê(o)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_ship_qty)    := ir_total_rec.case_shipping_qty;    -- (`[v)o×Ê(P[X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_ship_qty)    := ir_total_rec.ball_shipping_qty;    -- (`[v)o×Ê({[)
      gt_data_tab(ln_loop_cnt)(cv_invc_pallet_ship_qty)  := ir_total_rec.pallet_shipping_qty;  -- (`[v)o×Ê(pbg)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_ship_qty)     := ir_total_rec.sum_shipping_qty;     -- (`[v)o×Ê(vAo)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_stkout_qty)  := ir_total_rec.indv_stockout_qty;    -- (`[v)iÊ(o)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_stkout_qty)  := ir_total_rec.case_stockout_qty;    -- (`[v)iÊ(P[X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_stkout_qty)  := ir_total_rec.ball_stockout_qty;    -- (`[v)iÊ({[)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_stkout_qty)   := ir_total_rec.sum_stockout_qty;     -- (`[v)iÊ(vAo)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_qty)         := ir_total_rec.case_qty;             -- (`[v)P[XÂû
      gt_data_tab(ln_loop_cnt)(cv_invc_order_cost_amt)   := ir_total_rec.order_cost_amt;       -- (`[v)´¿àz(­)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_cost_amt)    := ir_total_rec.shipping_cost_amt;    -- (`[v)´¿àz(o×)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_cost_amt)  := ir_total_rec.stockout_cost_amt;    -- (`[v)´¿àz(i)
      gt_data_tab(ln_loop_cnt)(cv_invc_order_price_amt)  := ir_total_rec.order_price_amt;      -- (`[v)¿àz(­)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_price_amt)   := ir_total_rec.shipping_price_amt;   -- (`[v)¿àz(o×)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_price_amt) := ir_total_rec.stockout_price_amt;   -- (`[v)¿àz(i)
/* 2010/03/09 Ver1.16 Add Start */
      gt_data_tab(ln_loop_cnt)(cv_t_order_price_amt)     := ir_total_rec.order_price_amt;      -- (v)¿àz(­)
      gt_data_tab(ln_loop_cnt)(cv_t_ship_price_amt)      := ir_total_rec.shipping_price_amt;   -- (v)¿àz(o×)
/* 2009/03/09 Ver1.16 Add  End  */
--
      --==============================================================
      -- f[^¬`
      --==============================================================
      gn_dat_rec_cnt := gn_dat_rec_cnt + cn_1;
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
           iv_edit_data        =>  gt_data_tab(ln_loop_cnt)            -- oÍf[^îñ
          ,iv_file_type        =>  cv_0                                -- t@C`®(Åè·)
          ,iv_data_type_table  =>  gt_data_type_table                  -- CAEgè`îñ
          ,iv_record_type      =>  gv_if_data                          -- f[^R[h¯Êq
          ,ov_data_record      =>  gt_data_record_tab(gn_dat_rec_cnt)  -- f[^R[h
          ,ov_errbuf           =>  lv_errbuf                           -- G[bZ[W
          ,ov_retcode          =>  lv_retcode                          -- ^[R[h
          ,ov_errmsg           =>  lv_errmsg                           -- [UEG[bZ[W
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- bZ[Wæ¾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- AvP[V
                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI¤ÊÖG[bZ[W
                         ,iv_token_name1  => cv_tkn_err_msg       -- g[NR[hP
                         ,iv_token_value1 => lv_errmsg            -- G[EbZ[W
                       );
          RAISE global_api_others_expt;
      END;
--
    END LOOP format_loop;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END format_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_data
   * Description      : f[^ÒW(A-6)
   ***********************************************************************************/
  PROCEDURE edit_data(
    iv_make_class       IN  VARCHAR2,     --   2.ì¬æª
    iv_center_date      IN  VARCHAR2,     --   9.Z^[[iú
    iv_delivery_time    IN  VARCHAR2,     --  10.[i
    iv_delivery_charge  IN  VARCHAR2,     --  11.[iSÒ
    iv_carrier_means    IN  VARCHAR2,     --  12.Aèi
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_data'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_07554 */
    cv_uom_hon         CONSTANT VARCHAR2(2)   := '{';                 -- Åèl:{
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
--
    -- *** [JÏ ***
    lv_tkn_value1      VARCHAR2(50);    -- g[Næ¾p1
    lv_tkn_value2      VARCHAR2(50);    -- g[Næ¾p2
    lv_err_msg         VARCHAR2(5000);  -- G[oÍp
    ln_err_chk         NUMBER(1);       -- G[`FbNp
    ln_data_cnt        NUMBER;          -- f[^
    lv_product_code    VARCHAR2(16);    -- ¤iR[h
    lv_jan_code        VARCHAR2(16);    -- JANR[h
    lv_case_jan_code   VARCHAR2(16);    -- P[XJANR[h
/* 2010/07/08 Ver1.22 Add Start */
    lv_err_flag        VARCHAR2(1);     -- G[tO
/* 2010/07/08 Ver1.22 Add End */
    ln_dummy_item      NUMBER;          -- DUMMYiÚ
    lt_invoice_number  xxcos_edi_headers.invoice_number%TYPE;              -- `[Ô
    lt_header_id       xxcos_edi_headers.edi_header_info_id%TYPE;          -- EDIwb_îñID
    lt_delivery_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE;  -- EDI[i\èMÏtO
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
    ln_invoice_number  NUMBER;          -- l`FbNp
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
/* 2011/04/27 Ver1.24 Add Start */
    ln_reason_id      oe_reasons.reason_id%TYPE;          --RR[hæ¾p(_~[)
    lv_select_flag    fnd_lookup_values.attribute1%TYPE;  --RR[hæ¾p(IðÂ\tO)
/* 2011/04/27 Ver1.24 Add End   */
/* 2019/06/25 Ver1.29 Add Start */
    ln_tax_rate        NUMBER;          -- ÁïÅ¦Zop
/* 2019/06/25 Ver1.29 Add End   */
--
    -- *** [JEJ[\ ***
    CURSOR dummy_item_cur
    IS
      SELECT flvv.lookup_code      dummy_item_code  -- _~[iÚR[h
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_item_err_t
      AND    flvv.enabled_flag       = cv_y                -- Lø
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- Æ±útªFROM-TOà
      ;
--
    -- *** [JER[h ***
    l_invoice_total_rec  g_invoice_total_rtype;
--
    -- *** [JEe[u ***
    TYPE lt_dummy_item_ttype  IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE  INDEX BY BINARY_INTEGER;  -- DUMMYiÚ
    lt_dummy_item_tab  lt_dummy_item_ttype;
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
    --==============================================================
    -- ú»
    --==============================================================
    ln_err_chk        := cn_0;
    ln_data_cnt       := cn_0;
    lt_invoice_number := gt_edi_order_tab(cn_1).invoice_number;
    lt_header_id      := gt_edi_order_tab(cn_1).edi_header_info_id;
    lt_delivery_flag  := gt_edi_order_tab(cn_1).edi_delivery_schedule_flag;
    -- `[Êv
    l_invoice_total_rec.indv_order_qty      := cn_0;  -- ­Ê(o)
    l_invoice_total_rec.case_order_qty      := cn_0;  -- ­Ê(P[X)
    l_invoice_total_rec.ball_order_qty      := cn_0;  -- ­Ê({[)
    l_invoice_total_rec.sum_order_qty       := cn_0;  -- ­Ê(vAo)
    l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- o×Ê(o)
    l_invoice_total_rec.case_shipping_qty   := cn_0;  -- o×Ê(P[X)
    l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- o×Ê({[)
    l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- o×Ê(pbg)
    l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- o×Ê(vAo)
    l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- iÊ(o)
    l_invoice_total_rec.case_stockout_qty   := cn_0;  -- iÊ(P[X)
    l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- iÊ({[)
    l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- iÊ(vAo)
    l_invoice_total_rec.case_qty            := cn_0;  -- P[XÂû
    l_invoice_total_rec.order_cost_amt      := cn_0;  -- ´¿àz(­)
    l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- ´¿àz(o×)
    l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- ´¿àz(i)
    l_invoice_total_rec.order_price_amt     := cn_0;  -- ¿àz(­)
    l_invoice_total_rec.shipping_price_amt  := cn_0;  -- ¿àz(o×)
    l_invoice_total_rec.stockout_price_amt  := cn_0;  -- ¿àz(i)
--
    -- DUMMYiÚæ¾
    OPEN  dummy_item_cur;
    FETCH dummy_item_cur BULK COLLECT INTO lt_dummy_item_tab;
    CLOSE dummy_item_cur;
--
    <<edit_loop>>
    FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
      lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
      --l`FbN
      BEGIN
        IF INSTR( lt_invoice_number , '.' ) > 0 THEN
          RAISE global_number_err_expt;
        END IF;
        ln_invoice_number := TO_NUMBER( SUBSTRB( lt_invoice_number, 1,1) );
        ln_invoice_number := TO_NUMBER( lt_invoice_number );
      EXCEPTION
        WHEN global_number_err_expt THEN
--****************************** 2009/07/08 1.10 M.Sano     ADD START ******************************--
          gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt  := gn_target_cnt - gn_error_cnt;
--****************************** 2009/07/08 1.10 M.Sano     ADD  END  ******************************--
          ov_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application                                -- AvP[V
                          ,iv_name         => cv_msg_slip_no_err                            -- `[ÔlG[
                          ,iv_token_name1  => cv_tkn_param01                                -- üÍp[^¼
                          ,iv_token_value1 => lt_invoice_number                             -- `[Ô
                          ,iv_token_name2  => cv_tkn_param02                                -- üÍp[^¼
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).order_number    -- óÔ
                        );
          RAISE global_api_others_expt;
      END;
--****************************** 2019/06/25 1.29 S.Kuwako   ADD START ******************************--
      --ÁïÅ`FbN
      BEGIN
        IF ( gt_edi_order_tab(ln_loop_cnt).tax_rate IS NULL ) THEN
          ln_err_chk  := cn_1;        --G[ è
          RAISE global_tax_err_expt;
        END IF;
      EXCEPTION
        WHEN global_tax_err_expt THEN
            gn_error_cnt := gn_error_cnt + 1;
            gn_warn_cnt  := gn_target_cnt - gn_error_cnt;
            -- L[îñÌÒW
            xxcos_common_pkg.makeup_key_info(
                               iv_item_name1  => xxccp_common_pkg.get_msg( cv_application,cv_msg_edi_hdr_id )
                              ,iv_data_value1 => gt_edi_order_tab(ln_loop_cnt).edi_header_info_id
                              ,iv_item_name2  => xxccp_common_pkg.get_msg( cv_application,cv_msg_edi_chain_code )
                              ,iv_data_value2 => gt_edi_order_tab(ln_loop_cnt).edi_chain_code
                              ,iv_item_name3  => xxccp_common_pkg.get_msg( cv_application,cv_msg_edi_item_code  )
                              ,iv_data_value3 => gt_edi_order_tab(ln_loop_cnt).item_code
                              ,ov_key_info    => gv_tkn1             -- L[îñ
                              ,ov_errbuf      => lv_errbuf           -- G[EbZ[WG[
                              ,ov_retcode     => lv_retcode          -- ^[R[h
                              ,ov_errmsg      => lv_errmsg           -- [U[EG[EbZ[W
            );
            -- bZ[W
            lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application     -- AvP[V
                              ,iv_name         => cv_msg_tax_err     -- ÁïÅæ¾G[
                              ,iv_token_name1  => cv_tkn_key_data    -- L[îñ
                              ,iv_token_value1 => gv_tkn1
                          );
            -- bZ[WoÍ(ós)
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
            -- bZ[WoÍ
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
      END;
--****************************** 2019/06/25 1.29 S.Kuwako   ADD  END  ******************************--
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      -- uEDIwb_îñIDvªuCNµ½ê
      IF ( lt_header_id <> gt_edi_order_tab(ln_loop_cnt).edi_header_info_id ) THEN
--      -- u`[ÔvªuCNµ½ê
--      IF ( lt_invoice_number <> gt_edi_order_tab(ln_loop_cnt).invoice_number ) THEN
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
        --==============================================================
        -- f[^¬`(A-7)
        --==============================================================
        format_data(
           iv_make_class        -- 2.ì¬æª
          ,l_invoice_total_rec  -- `[v
          ,lt_header_id         -- EDIwb_îñID
          ,lt_delivery_flag     -- EDI[i\èMÏtO
          ,lv_errbuf            -- G[EbZ[W           --# Åè #
          ,lv_retcode           -- ^[ER[h             --# Åè #
          ,lv_errmsg            -- [U[EG[EbZ[W --# Åè #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- NA
        --==============================================================
        gt_data_tab.DELETE;
        ln_data_cnt       := cn_0;
        lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
        lt_header_id      := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;
        lt_delivery_flag  := gt_edi_order_tab(ln_loop_cnt).edi_delivery_schedule_flag;
        -- `[Êv
        l_invoice_total_rec.indv_order_qty      := cn_0;  -- ­Ê(o)
        l_invoice_total_rec.case_order_qty      := cn_0;  -- ­Ê(P[X)
        l_invoice_total_rec.ball_order_qty      := cn_0;  -- ­Ê({[)
        l_invoice_total_rec.sum_order_qty       := cn_0;  -- ­Ê(vAo)
        l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- o×Ê(o)
        l_invoice_total_rec.case_shipping_qty   := cn_0;  -- o×Ê(P[X)
        l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- o×Ê({[)
        l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- o×Ê(pbg)
        l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- o×Ê(vAo)
        l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- iÊ(o)
        l_invoice_total_rec.case_stockout_qty   := cn_0;  -- iÊ(P[X)
        l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- iÊ({[)
        l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- iÊ(vAo)
        l_invoice_total_rec.case_qty            := cn_0;  -- P[XÂû
        l_invoice_total_rec.order_cost_amt      := cn_0;  -- ´¿àz(­)
        l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- ´¿àz(o×)
        l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- ´¿àz(i)
        l_invoice_total_rec.order_price_amt     := cn_0;  -- ¿àz(­)
        l_invoice_total_rec.shipping_price_amt  := cn_0;  -- ¿àz(o×)
        l_invoice_total_rec.stockout_price_amt  := cn_0;  -- ¿àz(i)
      END IF;
--
      ln_data_cnt := ln_data_cnt + cn_1;
--
--****************************** 2019/06/25 1.29 S.Kuwako ADD START ******************************--
      -- Åà|[æ¾
      BEGIN
        SELECT  /*+ INDEX(xchvw.cust_hier.ship_hzca_1 hz_cust_accounts_u2) */
                xchvw.bill_tax_round_rule   bill_tax_round_rule         -- Åà|[
          INTO  gv_tax_round_rule
          FROM  xxcos_cust_hierarchy_v  xchvw                           -- ÚqKwr[
         WHERE  xchvw.ship_account_number  =  gt_edi_order_tab(ln_loop_cnt).account_number   -- ÚqKwr[.o×æÚqR[hEDIóf[^.ÚqR[h
        ;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--****************************** 2019/06/25 1.29 S.Kuwako ADD END   ******************************--
      --==============================================================
      -- [i\èf[^ÒW
      --==============================================================
      -- wb_
      gt_data_tab(ln_data_cnt)(cv_medium_class)             := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- }Ìæª
      gt_data_tab(ln_data_cnt)(cv_data_type_code)           := gt_data_type_code;                                               -- ÃÞ°Àíº°ÄÞ
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).file_no;                           -- Ì§²ÙNo
      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).edi_forward_number;                -- Ì§²ÙNo
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
      gt_data_tab(ln_data_cnt)(cv_info_class)               := gt_edi_order_tab(ln_loop_cnt).info_class;                        -- îñæª
      gt_data_tab(ln_data_cnt)(cv_process_date)             := gv_f_o_date;                                                     -- ú
      gt_data_tab(ln_data_cnt)(cv_process_time)             := gv_f_o_time;                                                     -- ú
      gt_data_tab(ln_data_cnt)(cv_base_code)                := gt_edi_order_tab(ln_loop_cnt).delivery_base_code;                -- _(å)º°ÄÞ
/* 2009/02/24 Ver1.2 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_base_name)                := gt_edi_order_tab(ln_loop_cnt).base_name;                         -- _¼(³®¼)
--    gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := gt_edi_order_tab(ln_loop_cnt).base_name_phonetic;                -- _¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_base_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);           -- _¼(³®¼)
      gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name_phonetic, 1, 100);  -- _¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_code)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_code;                    -- EDIÁª°ÝXº°ÄÞ
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_name;                    -- EDIÁª°ÝX¼(¿)
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic);      -- EDIÁª°ÝX¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).edi_chain_name, 1, 100);   -- EDIÁª°ÝX¼(¿)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic), 1, 100); -- EDIÁª°ÝX¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_chain_code)               := NULL;                                                            -- Áª°ÝXº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_chain_name)               := NULL;                                                            -- Áª°ÝX¼(¿)
      gt_data_tab(ln_data_cnt)(cv_chain_name_alt)           := NULL;                                                            -- Áª°ÝX¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_report_code)              := NULL;                                                            --  [º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_report_show_name)         := NULL;                                                            --  [\¦¼
      gt_data_tab(ln_data_cnt)(cv_cust_code)                := gt_edi_order_tab(ln_loop_cnt).account_number;                    -- Úqº°ÄÞ
--    gt_data_tab(ln_data_cnt)(cv_cust_name)                := gt_edi_order_tab(ln_loop_cnt).customer_name;                     -- Úq¼(¿)
--    gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic;            -- Úq¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_cust_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name, 1, 100);           -- Úq¼(¿)
      gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic, 1, 100);  -- Úq¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_comp_code)                := gt_edi_order_tab(ln_loop_cnt).company_code;                      -- Ðº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_comp_name)                := gt_edi_order_tab(ln_loop_cnt).company_name;                      -- Ð¼(¿)
      gt_data_tab(ln_data_cnt)(cv_comp_name_alt)            := gt_edi_order_tab(ln_loop_cnt).company_name_alt;                  -- Ð¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_shop_code)                := gt_edi_order_tab(ln_loop_cnt).shop_code;                         -- Xº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_shop_name)                := gt_edi_order_tab(ln_loop_cnt).cust_store_name;                   -- X¼(¿)
--    gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic);           -- X¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic), 1, 100);      -- X¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_code)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_code;              -- [ü¾ÝÀ°º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_name;              -- [ü¾ÝÀ°¼(¿)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name_alt)       := gt_edi_order_tab(ln_loop_cnt).delivery_center_name_alt;          -- [üæ¾ÝÀ°¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_order_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_date, cv_date_format);                   -- ­ú
      gt_data_tab(ln_data_cnt)(cv_cent_delv_date)           := NVL(iv_center_date,
                                                               TO_CHAR(gt_edi_order_tab(ln_loop_cnt).center_delivery_date, cv_date_format));        -- ¾ÝÀ°[iú
      gt_data_tab(ln_data_cnt)(cv_result_delv_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).result_delivery_date, cv_date_format);         -- À[iú
      gt_data_tab(ln_data_cnt)(cv_shop_delv_date)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).shop_delivery_date, cv_date_format);           -- XÜ[iú
      gt_data_tab(ln_data_cnt)(cv_dc_date_edi_data)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).data_creation_date_edi_data, cv_date_format);  -- ÃÞ°Àì¬ú(EDIÃÞ°À)
      gt_data_tab(ln_data_cnt)(cv_dc_time_edi_data)         := gt_edi_order_tab(ln_loop_cnt).data_creation_time_edi_data;       -- ÃÞ°Àì¬(EDIÃÞ°À)
      gt_data_tab(ln_data_cnt)(cv_invc_class)               := gt_edi_order_tab(ln_loop_cnt).invoice_class;                     -- `[æª
      gt_data_tab(ln_data_cnt)(cv_small_classif_code)       := gt_edi_order_tab(ln_loop_cnt).small_classification_code;         -- ¬ªÞº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_small_classif_name)       := gt_edi_order_tab(ln_loop_cnt).small_classification_name;         -- ¬ªÞ¼
      gt_data_tab(ln_data_cnt)(cv_middle_classif_code)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_code;        -- ªÞº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_middle_classif_name)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_name;        -- ªÞ¼
      gt_data_tab(ln_data_cnt)(cv_big_classif_code)         := gt_edi_order_tab(ln_loop_cnt).big_classification_code;           -- åªÞº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_big_classif_name)         := gt_edi_order_tab(ln_loop_cnt).big_classification_name;           -- åªÞ¼
      gt_data_tab(ln_data_cnt)(cv_op_department_code)       := gt_edi_order_tab(ln_loop_cnt).other_party_department_code;       -- èæåº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_op_order_number)          := gt_edi_order_tab(ln_loop_cnt).other_party_order_number;          -- èæ­Ô
      gt_data_tab(ln_data_cnt)(cv_check_digit_class)        := gt_edi_order_tab(ln_loop_cnt).check_digit_class;                 -- Áª¯¸ÃÞ¼Þ¯ÄL³æª
      gt_data_tab(ln_data_cnt)(cv_invc_number)              := gt_edi_order_tab(ln_loop_cnt).invoice_number;                    -- `[Ô
      gt_data_tab(ln_data_cnt)(cv_check_digit)              := gt_edi_order_tab(ln_loop_cnt).check_digit;                       -- Áª¯¸ÃÞ¼Þ¯Ä
      gt_data_tab(ln_data_cnt)(cv_close_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).close_date, cv_date_format);  -- À
      gt_data_tab(ln_data_cnt)(cv_order_no_ebs)             := gt_edi_order_tab(ln_loop_cnt).order_number;                      -- óNo(EBS)
      gt_data_tab(ln_data_cnt)(cv_ar_sale_class)            := gt_edi_order_tab(ln_loop_cnt).ar_sale_class;                     -- Áæª
      gt_data_tab(ln_data_cnt)(cv_delv_classe)              := gt_edi_order_tab(ln_loop_cnt).delivery_classe;                   -- zæª
      gt_data_tab(ln_data_cnt)(cv_opportunity_no)           := gt_edi_order_tab(ln_loop_cnt).opportunity_no;                    -- ÖNo
      gt_data_tab(ln_data_cnt)(cv_contact_to)               := NVL(gt_edi_order_tab(ln_loop_cnt).contact_to,
                                                                   gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic);       -- Aæ
      gt_data_tab(ln_data_cnt)(cv_route_sales)              := gt_edi_order_tab(ln_loop_cnt).route_sales;                       -- Ù°Ä¾°Ù½
      gt_data_tab(ln_data_cnt)(cv_corporate_code)           := gt_edi_order_tab(ln_loop_cnt).corporate_code;                    -- @lº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_maker_name)               := gt_edi_order_tab(ln_loop_cnt).maker_name;                        -- Ò°¶°¼
      gt_data_tab(ln_data_cnt)(cv_area_code)                := NVL(gt_edi_order_tab(ln_loop_cnt).area_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_code);            -- næº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_area_name)                := gt_edi_order_tab(ln_loop_cnt).edi_district_name;                 -- næ¼(¿)
      gt_data_tab(ln_data_cnt)(cv_area_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).area_name_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_kana);            -- næ¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_vendor_code)              := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).torihikisaki_code);            -- æøæº°ÄÞ
--    gt_data_tab(ln_data_cnt)(cv_vendor_name)              := gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name;      -- æøæ¼(¿)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
--                                                                 gv_company_kana);                                            -- æøæ¼1(¶Å)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).base_name_phonetic);           -- æøæ¼2(¶Å)
      gt_data_tab(ln_data_cnt)(cv_vendor_name)              := SUBSTRB(gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);  -- æøæ¼(¿)
      gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
                                                                   gv_company_kana), 1, 100);                                   -- æøæ¼1(¶Å)
      gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).base_name_phonetic), 1, 100);  -- æøæ¼2(¶Å)
      gt_data_tab(ln_data_cnt)(cv_vendor_tel)               := gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic;            -- æøæTEL
/* 2010/03/19 Ver1.19 Mod Start */
--      gt_data_tab(ln_data_cnt)(cv_vendor_charge)            := NVL(iv_delivery_charge,
--                                                                   gt_edi_order_tab(ln_loop_cnt).last_name ||
--                                                                   gt_edi_order_tab(ln_loop_cnt).first_name);                   -- æøæSÒ
      gt_data_tab(ln_data_cnt)(cv_vendor_charge)            := gt_edi_order_tab(ln_loop_cnt).full_name;                         -- æøæSÒ
/* 2010/03/19 Ver1.19 Mod  End  */
--    gt_data_tab(ln_data_cnt)(cv_vendor_address)           := gt_edi_order_tab(ln_loop_cnt).state    ||
--                                                             gt_edi_order_tab(ln_loop_cnt).city     ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address1 ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address2;                          -- æøæZ(¿)
      gt_data_tab(ln_data_cnt)(cv_vendor_address)           := SUBSTRB(
                                                               gt_edi_order_tab(ln_loop_cnt).state    ||
                                                               gt_edi_order_tab(ln_loop_cnt).city     ||
                                                               gt_edi_order_tab(ln_loop_cnt).address1 ||
                                                               gt_edi_order_tab(ln_loop_cnt).address2, 1, 100);                 -- æøæZ(¿)
/* 2009/02/24 Ver1.2 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_itouen)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_itouen;            -- Í¯æº°ÄÞ(É¡)
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_chain)       := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_chain;             -- Í¯æº°ÄÞ(Áª°ÝX)
      gt_data_tab(ln_data_cnt)(cv_delv_to)                  := gt_edi_order_tab(ln_loop_cnt).deliver_to;                        -- Í¯æ(¿)
      gt_data_tab(ln_data_cnt)(cv_delv_to1_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to1_alt;                   -- Í¯æ1(¶Å)
      gt_data_tab(ln_data_cnt)(cv_delv_to2_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to2_alt;                   -- Í¯æ2(¶Å)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address)          := gt_edi_order_tab(ln_loop_cnt).deliver_to_address;                -- Í¯æZ(¿)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address_alt)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_address_alt;            -- Í¯æZ(¶Å)
      gt_data_tab(ln_data_cnt)(cv_delv_to_tel)              := gt_edi_order_tab(ln_loop_cnt).deliver_to_tel;                    -- Í¯æTEL
      gt_data_tab(ln_data_cnt)(cv_bal_acc_code)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_code;             --  æº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_comp_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_company_code;     --  æÐº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_shop_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_shop_code;        --  æXº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name;             --  æ¼(¿)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name_alt)         := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name_alt;         --  æ¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address)          := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address;          --  æZ(¿)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address_alt)      := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address_alt;      --  æZ(¶Å)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_tel)              := gt_edi_order_tab(ln_loop_cnt).balance_accounts_tel;              --  æTEL
      gt_data_tab(ln_data_cnt)(cv_order_possible_date)      := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_possible_date, cv_date_format);         -- óÂ\ú
      gt_data_tab(ln_data_cnt)(cv_perm_possible_date)       := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).permission_possible_date, cv_date_format);    -- eÂ\ú
      gt_data_tab(ln_data_cnt)(cv_forward_month)            := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).forward_month, cv_date_format);               -- æÀNú
      gt_data_tab(ln_data_cnt)(cv_payment_settlement_date)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).payment_settlement_date, cv_date_format);     -- x¥Ïú
      gt_data_tab(ln_data_cnt)(cv_handbill_start_date_act)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).handbill_start_date_active, cv_date_format);  -- Á×¼Jnú
      gt_data_tab(ln_data_cnt)(cv_billing_due_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).billing_due_date, cv_date_format);            -- ¿÷ú
      gt_data_tab(ln_data_cnt)(cv_ship_time)                := gt_edi_order_tab(ln_loop_cnt).shipping_time;                     -- o×
      gt_data_tab(ln_data_cnt)(cv_delv_schedule_time)       := iv_delivery_time;                                                -- [i\èÔ
      gt_data_tab(ln_data_cnt)(cv_order_time)               := gt_edi_order_tab(ln_loop_cnt).order_time;                        -- ­Ô
      gt_data_tab(ln_data_cnt)(cv_gen_date_item1)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item1, cv_date_format);  -- ÄpútÚ1
      gt_data_tab(ln_data_cnt)(cv_gen_date_item2)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item2, cv_date_format);  -- ÄpútÚ2
      gt_data_tab(ln_data_cnt)(cv_gen_date_item3)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item3, cv_date_format);  -- ÄpútÚ3
      gt_data_tab(ln_data_cnt)(cv_gen_date_item4)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item4, cv_date_format);  -- ÄpútÚ4
      gt_data_tab(ln_data_cnt)(cv_gen_date_item5)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item5, cv_date_format);  -- ÄpútÚ5
      gt_data_tab(ln_data_cnt)(cv_arrival_ship_class)       := gt_edi_order_tab(ln_loop_cnt).arrival_shipping_class;            -- üo×æª
      gt_data_tab(ln_data_cnt)(cv_vendor_class)             := gt_edi_order_tab(ln_loop_cnt).vendor_class;                      -- æøææª
      gt_data_tab(ln_data_cnt)(cv_invc_detailed_class)      := gt_edi_order_tab(ln_loop_cnt).invoice_detailed_class;            -- `[àóæª
      gt_data_tab(ln_data_cnt)(cv_unit_price_use_class)     := gt_edi_order_tab(ln_loop_cnt).unit_price_use_class;              -- P¿gpæª
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_code)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_code;      -- »ÌÞ¨¬¾ÝÀ°º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_name)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_name;      -- »ÌÞ¨¬¾ÝÀ°º°ÄÞ¼
      gt_data_tab(ln_data_cnt)(cv_cent_delv_method)         := gt_edi_order_tab(ln_loop_cnt).center_delivery_method;            -- ¾ÝÀ°[iû@
      gt_data_tab(ln_data_cnt)(cv_cent_use_class)           := gt_edi_order_tab(ln_loop_cnt).center_use_class;                  -- ¾ÝÀ°pæª
      gt_data_tab(ln_data_cnt)(cv_cent_whse_class)          := gt_edi_order_tab(ln_loop_cnt).center_whse_class;                 -- ¾ÝÀ°qÉæª
      gt_data_tab(ln_data_cnt)(cv_cent_area_class)          := gt_edi_order_tab(ln_loop_cnt).center_area_class;                 -- ¾ÝÀ°nææª
      gt_data_tab(ln_data_cnt)(cv_cent_arrival_class)       := gt_edi_order_tab(ln_loop_cnt).center_arrival_class;              -- ¾ÝÀ°ü×æª
      gt_data_tab(ln_data_cnt)(cv_depot_class)              := gt_edi_order_tab(ln_loop_cnt).depot_class;                       -- ÃÞÎßæª
      gt_data_tab(ln_data_cnt)(cv_tcdc_class)               := gt_edi_order_tab(ln_loop_cnt).tcdc_class;                        -- TCDCæª
      gt_data_tab(ln_data_cnt)(cv_upc_flag)                 := gt_edi_order_tab(ln_loop_cnt).upc_flag;                          -- UPCÌ×¸Þ
      gt_data_tab(ln_data_cnt)(cv_simultaneously_class)     := gt_edi_order_tab(ln_loop_cnt).simultaneously_class;              -- êÄæª
      gt_data_tab(ln_data_cnt)(cv_business_id)              := gt_edi_order_tab(ln_loop_cnt).business_id;                       -- Æ±ID
      gt_data_tab(ln_data_cnt)(cv_whse_directly_class)      := gt_edi_order_tab(ln_loop_cnt).whse_directly_class;               -- q¼æª
      gt_data_tab(ln_data_cnt)(cv_premium_rebate_class)     := gt_edi_order_tab(ln_loop_cnt).premium_rebate_class;              -- ÚíÊ
      gt_data_tab(ln_data_cnt)(cv_item_type)                := gt_edi_order_tab(ln_loop_cnt).item_type;                         -- iißæª
      gt_data_tab(ln_data_cnt)(cv_cloth_house_food_class)   := gt_edi_order_tab(ln_loop_cnt).cloth_house_food_class;            -- ßÆHæª
      gt_data_tab(ln_data_cnt)(cv_mix_class)                := gt_edi_order_tab(ln_loop_cnt).mix_class;                         -- ¬Ýæª
      gt_data_tab(ln_data_cnt)(cv_stk_class)                := gt_edi_order_tab(ln_loop_cnt).stk_class;                         -- ÝÉæª
      gt_data_tab(ln_data_cnt)(cv_last_modify_site_class)   := gt_edi_order_tab(ln_loop_cnt).last_modify_site_class;            -- ÅIC³êæª
      gt_data_tab(ln_data_cnt)(cv_report_class)             := gt_edi_order_tab(ln_loop_cnt).report_class;                      --  [æª
      gt_data_tab(ln_data_cnt)(cv_addition_plan_class)      := gt_edi_order_tab(ln_loop_cnt).addition_plan_class;               -- ÇÁ¥vææª
      gt_data_tab(ln_data_cnt)(cv_registration_class)       := gt_edi_order_tab(ln_loop_cnt).registration_class;                -- o^æª
      gt_data_tab(ln_data_cnt)(cv_specific_class)           := gt_edi_order_tab(ln_loop_cnt).specific_class;                    -- Áèæª
      gt_data_tab(ln_data_cnt)(cv_dealings_class)           := gt_edi_order_tab(ln_loop_cnt).dealings_class;                    -- æøæª
      gt_data_tab(ln_data_cnt)(cv_order_class)              := gt_edi_order_tab(ln_loop_cnt).order_class;                       -- ­æª
      gt_data_tab(ln_data_cnt)(cv_sum_line_class)           := gt_edi_order_tab(ln_loop_cnt).sum_line_class;                    -- Wv¾×æª
      gt_data_tab(ln_data_cnt)(cv_ship_guidance_class)      := gt_edi_order_tab(ln_loop_cnt).shipping_guidance_class;           -- o×ÄàÈOæª
      gt_data_tab(ln_data_cnt)(cv_ship_class)               := gt_edi_order_tab(ln_loop_cnt).shipping_class;                    -- o×æª
      gt_data_tab(ln_data_cnt)(cv_prod_code_use_class)      := gt_edi_order_tab(ln_loop_cnt).product_code_use_class;            -- ¤iº°ÄÞgpæª
      gt_data_tab(ln_data_cnt)(cv_cargo_item_class)         := gt_edi_order_tab(ln_loop_cnt).cargo_item_class;                  -- Ïiæª
      gt_data_tab(ln_data_cnt)(cv_ta_class)                 := gt_edi_order_tab(ln_loop_cnt).ta_class;                          -- T/Aæª
      gt_data_tab(ln_data_cnt)(cv_plan_code)                := gt_edi_order_tab(ln_loop_cnt).plan_code;                         -- éæº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_category_code)            := gt_edi_order_tab(ln_loop_cnt).category_code;                     -- ¶ÃºÞØ°º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_category_class)           := gt_edi_order_tab(ln_loop_cnt).category_class;                    -- ¶ÃºÞØ°æª
      gt_data_tab(ln_data_cnt)(cv_carrier_means)            := iv_carrier_means;                                                -- ^èi
      gt_data_tab(ln_data_cnt)(cv_counter_code)             := gt_edi_order_tab(ln_loop_cnt).counter_code;                      -- êº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_move_sign)                := gt_edi_order_tab(ln_loop_cnt).move_sign;                         -- Ú®»²Ý
      gt_data_tab(ln_data_cnt)(cv_eos_handwriting_class)    := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- EOS¥èæª
      gt_data_tab(ln_data_cnt)(cv_delv_to_section_code)     := gt_edi_order_tab(ln_loop_cnt).delivery_to_section_code;          -- [iæÛº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_invc_detailed)            := gt_edi_order_tab(ln_loop_cnt).invoice_detailed;                  -- `[àó
      gt_data_tab(ln_data_cnt)(cv_attach_qty)               := gt_edi_order_tab(ln_loop_cnt).attach_qty;                        -- Yt
      gt_data_tab(ln_data_cnt)(cv_op_floor)                 := gt_edi_order_tab(ln_loop_cnt).other_party_floor;                 -- ÌÛ±
      gt_data_tab(ln_data_cnt)(cv_text_no)                  := gt_edi_order_tab(ln_loop_cnt).text_no;                           -- TEXTNo
      gt_data_tab(ln_data_cnt)(cv_in_store_code)            := gt_edi_order_tab(ln_loop_cnt).in_store_code;                     -- ²Ý½Ä±º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_tag_data)                 := gt_edi_order_tab(ln_loop_cnt).tag_data;                          -- À¸Þ
      gt_data_tab(ln_data_cnt)(cv_competition_code)         := gt_edi_order_tab(ln_loop_cnt).competition_code;                  -- £
      gt_data_tab(ln_data_cnt)(cv_billing_chair)            := gt_edi_order_tab(ln_loop_cnt).billing_chair;                     -- ¿ûÀ
      gt_data_tab(ln_data_cnt)(cv_chain_store_code)         := gt_edi_order_tab(ln_loop_cnt).chain_store_code;                  -- Áª°Ý½Ä±°º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_chain_store_short_name)   := gt_edi_order_tab(ln_loop_cnt).chain_store_short_name;            -- Áª°Ý½Ä±°º°ÄÞª®¼Ì
      gt_data_tab(ln_data_cnt)(cv_direct_delv_rcpt_fee)     := gt_edi_order_tab(ln_loop_cnt).direct_delivery_rcpt_fee;          -- ¼z/øæ¿
      gt_data_tab(ln_data_cnt)(cv_bill_info)                := gt_edi_order_tab(ln_loop_cnt).bill_info;                         -- è`îñ
      gt_data_tab(ln_data_cnt)(cv_description)              := gt_edi_order_tab(ln_loop_cnt).description;                       -- Ev1
      gt_data_tab(ln_data_cnt)(cv_interior_code)            := gt_edi_order_tab(ln_loop_cnt).interior_code;                     -- àº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_order_info_delv_category) := gt_edi_order_tab(ln_loop_cnt).order_info_delivery_category;      -- ­îñ [i¶ÃºÞØ°
      gt_data_tab(ln_data_cnt)(cv_purchase_type)            := gt_edi_order_tab(ln_loop_cnt).purchase_type;                     -- dü`Ô
      gt_data_tab(ln_data_cnt)(cv_delv_to_name_alt)         := gt_edi_order_tab(ln_loop_cnt).delivery_to_name_alt;              -- [iê¼(¶Å)
      gt_data_tab(ln_data_cnt)(cv_shop_opened_site)         := gt_edi_order_tab(ln_loop_cnt).shop_opened_site;                  -- Xoê
      gt_data_tab(ln_data_cnt)(cv_counter_name)             := gt_edi_order_tab(ln_loop_cnt).counter_name;                      -- ê¼
      gt_data_tab(ln_data_cnt)(cv_extension_number)         := gt_edi_order_tab(ln_loop_cnt).extension_number;                  -- àüÔ
      gt_data_tab(ln_data_cnt)(cv_charge_name)              := gt_edi_order_tab(ln_loop_cnt).charge_name;                       -- SÒ¼
      gt_data_tab(ln_data_cnt)(cv_price_tag)                := gt_edi_order_tab(ln_loop_cnt).price_tag;                         -- lD
      gt_data_tab(ln_data_cnt)(cv_tax_type)                 := gt_edi_order_tab(ln_loop_cnt).tax_type;                          -- Åí
      gt_data_tab(ln_data_cnt)(cv_consumption_tax_class)    := gt_edi_order_tab(ln_loop_cnt).consumption_tax_class;             -- ÁïÅæª
      gt_data_tab(ln_data_cnt)(cv_brand_class)              := gt_edi_order_tab(ln_loop_cnt).brand_class;                       -- BR
      gt_data_tab(ln_data_cnt)(cv_id_code)                  := gt_edi_order_tab(ln_loop_cnt).id_code;                           -- IDº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_department_code)          := gt_edi_order_tab(ln_loop_cnt).department_code;                   -- SÝXº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_department_name)          := gt_edi_order_tab(ln_loop_cnt).department_name;                   -- SÝX¼
      gt_data_tab(ln_data_cnt)(cv_item_type_number)         := gt_edi_order_tab(ln_loop_cnt).item_type_number;                  -- iÊÔ
      gt_data_tab(ln_data_cnt)(cv_description_department)   := gt_edi_order_tab(ln_loop_cnt).description_department;            -- Ev2
      gt_data_tab(ln_data_cnt)(cv_price_tag_method)         := gt_edi_order_tab(ln_loop_cnt).price_tag_method;                  -- lDû@
      gt_data_tab(ln_data_cnt)(cv_reason_column)            := gt_edi_order_tab(ln_loop_cnt).reason_column;                     -- ©R
      gt_data_tab(ln_data_cnt)(cv_a_column_header)          := gt_edi_order_tab(ln_loop_cnt).a_column_header;                   -- AÍ¯ÀÞ
      gt_data_tab(ln_data_cnt)(cv_d_column_header)          := gt_edi_order_tab(ln_loop_cnt).d_column_header;                   -- DÍ¯ÀÞ
      gt_data_tab(ln_data_cnt)(cv_brand_code)               := gt_edi_order_tab(ln_loop_cnt).brand_code;                        -- ÌÞ×ÝÄÞº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_line_code)                := gt_edi_order_tab(ln_loop_cnt).line_code;                         -- ×²Ýº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_class_code)               := gt_edi_order_tab(ln_loop_cnt).class_code;                        -- ¸×½º°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_a1_column)                := gt_edi_order_tab(ln_loop_cnt).a1_column;                         -- A-1
      gt_data_tab(ln_data_cnt)(cv_b1_column)                := gt_edi_order_tab(ln_loop_cnt).b1_column;                         -- B-1
      gt_data_tab(ln_data_cnt)(cv_c1_column)                := gt_edi_order_tab(ln_loop_cnt).c1_column;                         -- C-1
      gt_data_tab(ln_data_cnt)(cv_d1_column)                := gt_edi_order_tab(ln_loop_cnt).d1_column;                         -- D-1
      gt_data_tab(ln_data_cnt)(cv_e1_column)                := gt_edi_order_tab(ln_loop_cnt).e1_column;                         -- E-1
      gt_data_tab(ln_data_cnt)(cv_a2_column)                := gt_edi_order_tab(ln_loop_cnt).a2_column;                         -- A-2
      gt_data_tab(ln_data_cnt)(cv_b2_column)                := gt_edi_order_tab(ln_loop_cnt).b2_column;                         -- B-2
      gt_data_tab(ln_data_cnt)(cv_c2_column)                := gt_edi_order_tab(ln_loop_cnt).c2_column;                         -- C-2
      gt_data_tab(ln_data_cnt)(cv_d2_column)                := gt_edi_order_tab(ln_loop_cnt).d2_column;                         -- D-2
      gt_data_tab(ln_data_cnt)(cv_e2_column)                := gt_edi_order_tab(ln_loop_cnt).e2_column;                         -- E-2
      gt_data_tab(ln_data_cnt)(cv_a3_column)                := gt_edi_order_tab(ln_loop_cnt).a3_column;                         -- A-3
      gt_data_tab(ln_data_cnt)(cv_b3_column)                := gt_edi_order_tab(ln_loop_cnt).b3_column;                         -- B-3
      gt_data_tab(ln_data_cnt)(cv_c3_column)                := gt_edi_order_tab(ln_loop_cnt).c3_column;                         -- C-3
      gt_data_tab(ln_data_cnt)(cv_d3_column)                := gt_edi_order_tab(ln_loop_cnt).d3_column;                         -- D-3
      gt_data_tab(ln_data_cnt)(cv_e3_column)                := gt_edi_order_tab(ln_loop_cnt).e3_column;                         -- E-3
      gt_data_tab(ln_data_cnt)(cv_f1_column)                := gt_edi_order_tab(ln_loop_cnt).f1_column;                         -- F-1
      gt_data_tab(ln_data_cnt)(cv_g1_column)                := gt_edi_order_tab(ln_loop_cnt).g1_column;                         -- G-1
      gt_data_tab(ln_data_cnt)(cv_h1_column)                := gt_edi_order_tab(ln_loop_cnt).h1_column;                         -- H-1
      gt_data_tab(ln_data_cnt)(cv_i1_column)                := gt_edi_order_tab(ln_loop_cnt).i1_column;                         -- I-1
      gt_data_tab(ln_data_cnt)(cv_j1_column)                := gt_edi_order_tab(ln_loop_cnt).j1_column;                         -- J-1
      gt_data_tab(ln_data_cnt)(cv_k1_column)                := gt_edi_order_tab(ln_loop_cnt).k1_column;                         -- K-1
      gt_data_tab(ln_data_cnt)(cv_l1_column)                := gt_edi_order_tab(ln_loop_cnt).l1_column;                         -- L-1
      gt_data_tab(ln_data_cnt)(cv_f2_column)                := gt_edi_order_tab(ln_loop_cnt).f2_column;                         -- F-2
      gt_data_tab(ln_data_cnt)(cv_g2_column)                := gt_edi_order_tab(ln_loop_cnt).g2_column;                         -- G-2
      gt_data_tab(ln_data_cnt)(cv_h2_column)                := gt_edi_order_tab(ln_loop_cnt).h2_column;                         -- H-2
      gt_data_tab(ln_data_cnt)(cv_i2_column)                := gt_edi_order_tab(ln_loop_cnt).i2_column;                         -- I-2
      gt_data_tab(ln_data_cnt)(cv_j2_column)                := gt_edi_order_tab(ln_loop_cnt).j2_column;                         -- J-2
      gt_data_tab(ln_data_cnt)(cv_k2_column)                := gt_edi_order_tab(ln_loop_cnt).k2_column;                         -- K-2
      gt_data_tab(ln_data_cnt)(cv_l2_column)                := gt_edi_order_tab(ln_loop_cnt).l2_column;                         -- L-2
      gt_data_tab(ln_data_cnt)(cv_f3_column)                := gt_edi_order_tab(ln_loop_cnt).f3_column;                         -- F-3
      gt_data_tab(ln_data_cnt)(cv_g3_column)                := gt_edi_order_tab(ln_loop_cnt).g3_column;                         -- G-3
      gt_data_tab(ln_data_cnt)(cv_h3_column)                := gt_edi_order_tab(ln_loop_cnt).h3_column;                         -- H-3
      gt_data_tab(ln_data_cnt)(cv_i3_column)                := gt_edi_order_tab(ln_loop_cnt).i3_column;                         -- I-3
      gt_data_tab(ln_data_cnt)(cv_j3_column)                := gt_edi_order_tab(ln_loop_cnt).j3_column;                         -- J-3
      gt_data_tab(ln_data_cnt)(cv_k3_column)                := gt_edi_order_tab(ln_loop_cnt).k3_column;                         -- K-3
      gt_data_tab(ln_data_cnt)(cv_l3_column)                := gt_edi_order_tab(ln_loop_cnt).l3_column;                         -- L-3
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_header)    := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_header;        -- Áª°ÝXÅL´Ø±(Í¯ÀÞ)
      gt_data_tab(ln_data_cnt)(cv_order_connection_number)  := NULL;                                                            -- óÖAÔ
--
      -- ¾×
      gt_data_tab(ln_data_cnt)(cv_line_no)                  := gt_edi_order_tab(ln_loop_cnt).line_no;                      -- sNo
      -- _~[iÚ`FbN
      ln_dummy_item := cn_0;
      <<dummy_item_loop>>
      FOR ln_dummy_item_loop_cnt IN 1 .. lt_dummy_item_tab.COUNT LOOP
        IF ( gt_edi_order_tab(ln_loop_cnt).ordered_item = lt_dummy_item_tab(ln_dummy_item_loop_cnt) ) THEN
          ln_dummy_item := cn_1;
          EXIT;
        END IF;
      END LOOP dummy_item_loop;
      -- u¤iR[h(É¡)vªA_~[iÚÌê
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := NULL;                                                       -- ¤iº°ÄÞ(É¡)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := NULL;                                                       -- ¤i¼(¿)
/* 2009/03/04 Ver1.6 Add  End  */
      -- ãLÈOÌê
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := gt_edi_order_tab(ln_loop_cnt).ordered_item;                 -- ¤iº°ÄÞ(É¡)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := gt_edi_order_tab(ln_loop_cnt).item_name;                    -- ¤i¼(¿)
/* 2009/03/04 Ver1.6 Add  End  */
      END IF;
      gt_data_tab(ln_data_cnt)(cv_prod_code1)               := gt_edi_order_tab(ln_loop_cnt).product_code1;                -- ¤iº°ÄÞ1
      -- u}ÌæªvªA'èüÍ'Å©ÂAu¤iR[hQvªANULLÌê
      IF  ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl )
      AND ( gt_edi_order_tab(ln_loop_cnt).product_code2 IS NULL )
      THEN
        --iÚR[hÏ·iEBS¨EDI)
        xxcos_common2_pkg.conv_edi_item_code(
           iv_edi_chain_code   =>  gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDI`F[XR[h
          ,iv_item_code        =>  gt_edi_order_tab(ln_loop_cnt).item_code       -- iÚR[h
          ,iv_organization_id  =>  gn_organization_id                            -- ÝÉgDID
          ,iv_uom_code         =>  gt_edi_order_tab(ln_loop_cnt).line_uom        -- PÊR[h
          ,ov_product_code2    =>  lv_product_code                               -- ¤iR[hQ
          ,ov_jan_code         =>  lv_jan_code                                   -- JANR[h
          ,ov_case_jan_code    =>  lv_case_jan_code                              -- P[XJANR[h
/* 2010/07/08 Ver1.22 Add Start */
          ,ov_err_flag         =>  lv_err_flag                                   -- G[íÊ
/* 2010/07/08 Ver1.22 Add End */
          ,ov_errbuf           =>  lv_errbuf                                     -- G[bZ[W
          ,ov_retcode          =>  lv_retcode                                    -- ^[R[h
          ,ov_errmsg           =>  lv_errmsg                                     -- [U[EG[EbZ[W
        );
/* 2010/07/08 Ver1.22 Mod Start */
--        IF ( lv_retcode <> cv_status_normal ) THEN
--          -- bZ[Wæ¾
--          ov_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_application       -- AvP[V
--                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI¤ÊÖG[bZ[W
--                         ,iv_token_name1  => cv_tkn_err_msg       -- g[NR[hP
--                         ,iv_token_value1 => lv_errmsg            -- G[EbZ[W
--                       );
--          RAISE global_api_others_expt;
--        END IF;
        -- ^[R[hª³íÈOÌê
        IF ( lv_retcode <> cv_status_normal ) THEN
/* 2012/08/23 Ver1.27 Add Start */
          -- G[bZ[WÌöÉYÌ`[Ôð\¦·é
          lv_errbuf := REPLACE(lv_errbuf
                             , cv_message_end
                             , cv_invoice_number || gt_edi_order_tab(ln_loop_cnt).invoice_number || cv_message_end);
          lv_errmsg := REPLACE(lv_errmsg
                             , cv_message_end
                             , cv_invoice_number || gt_edi_order_tab(ln_loop_cnt).invoice_number || cv_message_end);
/* 2012/08/23 Ver1.27 Add End */
          RAISE global_item_conv_expt;
        END IF;
/* 2010/07/08 Ver1.22 Mod End */
        -- æ¾µ½¤iR[hªANULLÌê
        IF ( lv_product_code IS NULL ) THEN
          -- bZ[Wæ¾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      -- AvP[V
                          ,iv_name         => cv_msg_product_err  -- ¤iR[hG[bZ[W
                          ,iv_token_name1  => cv_tkn_chain_code   -- g[NR[hP
                          ,iv_token_value1 => gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDI`F[XR[h
                          ,iv_token_name2  => cv_tkn_item_code    -- g[NR[hQ
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).item_code       -- iÚR[h
/* 2012/08/20 Ver1.27 Add Start */
                          ,iv_token_name3  => cv_tkn_invoice_number -- g[NR[hR
                          ,iv_token_value3 => gt_edi_order_tab(ln_loop_cnt).invoice_number  -- `[Ô
/* 2012/08/20 Ver1.27 Add End */
                        );
          -- bZ[WÉoÍ
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  -- G[Lè
        END IF;
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := lv_product_code;                                            -- ¤iº°ÄÞ2
      -- ãLÈOÌê
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := gt_edi_order_tab(ln_loop_cnt).product_code2;                -- ¤iº°ÄÞ2
      END IF;
      -- u¾×PÊvªA'P[XPÊR[h'Ìê
      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).case_jan_code;                -- JANº°ÄÞ
      -- ãLÈOÌê
      ELSE
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).opf_jan_code;                 -- JANº°ÄÞ
      END IF;
      gt_data_tab(ln_data_cnt)(cv_itf_code)                 := NVL(gt_edi_order_tab(ln_loop_cnt).itf_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).opm_itf_code);            -- ITFº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_extension_itf_code)       := gt_edi_order_tab(ln_loop_cnt).extension_itf_code;           -- à ITFº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_case_prod_code)           := gt_edi_order_tab(ln_loop_cnt).case_product_code;            -- ¹°½¤iº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_ball_prod_code)           := gt_edi_order_tab(ln_loop_cnt).ball_product_code;            -- ÎÞ°Ù¤iº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_prod_code_item_type)      := gt_edi_order_tab(ln_loop_cnt).product_code_item_type;       -- ¤iº°ÄÞií
      gt_data_tab(ln_data_cnt)(cv_prod_class)               := gt_edi_order_tab(ln_loop_cnt).item_div_h_code;              -- ¤iæª
/* 2009/03/04 Ver1.6 Del Start */
--    gt_data_tab(ln_data_cnt)(cv_prod_name)                := gt_edi_order_tab(ln_loop_cnt).product_name;                 -- ¤i¼(¿)
/* 2009/03/04 Ver1.6 Del  End  */
      gt_data_tab(ln_data_cnt)(cv_prod_name1_alt)           := gt_edi_order_tab(ln_loop_cnt).product_name1_alt;            -- ¤i¼1(¶Å)
      gt_data_tab(ln_data_cnt)(cv_prod_name2_alt)           := NVL(gt_edi_order_tab(ln_loop_cnt).product_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt);           -- ¤i¼2(¶Å)
      gt_data_tab(ln_data_cnt)(cv_item_standard1)           := gt_edi_order_tab(ln_loop_cnt).item_standard1;               -- Ki1
      gt_data_tab(ln_data_cnt)(cv_item_standard2)           := NVL(gt_edi_order_tab(ln_loop_cnt).item_standard2,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt2);          -- Ki2
      gt_data_tab(ln_data_cnt)(cv_qty_in_case)              := gt_edi_order_tab(ln_loop_cnt).qty_in_case;                  -- ü
      gt_data_tab(ln_data_cnt)(cv_num_of_cases)             := gt_edi_order_tab(ln_loop_cnt).num_of_case;                  -- ¹°½ü
      gt_data_tab(ln_data_cnt)(cv_num_of_ball)              := NVL(gt_edi_order_tab(ln_loop_cnt).num_of_ball,
                                                                   gt_edi_order_tab(ln_loop_cnt).bowl_inc_num);            -- ÎÞ°Ùü
      gt_data_tab(ln_data_cnt)(cv_item_color)               := gt_edi_order_tab(ln_loop_cnt).item_color;                   -- F
      gt_data_tab(ln_data_cnt)(cv_item_size)                := gt_edi_order_tab(ln_loop_cnt).item_size;                    -- »²½Þ
      gt_data_tab(ln_data_cnt)(cv_expiration_date)          := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).expiration_date, cv_date_format);  -- Ü¡úÀú
      gt_data_tab(ln_data_cnt)(cv_prod_date)                := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).product_date, cv_date_format);     -- »¢ú
      gt_data_tab(ln_data_cnt)(cv_order_uom_qty)            := gt_edi_order_tab(ln_loop_cnt).order_uom_qty;                -- ­PÊ
      gt_data_tab(ln_data_cnt)(cv_ship_uom_qty)             := gt_edi_order_tab(ln_loop_cnt).shipping_uom_qty;             -- o×PÊ
      gt_data_tab(ln_data_cnt)(cv_packing_uom_qty)          := gt_edi_order_tab(ln_loop_cnt).packing_uom_qty;              -- «ïPÊ
      gt_data_tab(ln_data_cnt)(cv_deal_code)                := gt_edi_order_tab(ln_loop_cnt).deal_code;                    -- ø
      gt_data_tab(ln_data_cnt)(cv_deal_class)               := gt_edi_order_tab(ln_loop_cnt).deal_class;                   -- øæª
      gt_data_tab(ln_data_cnt)(cv_collation_code)           := gt_edi_order_tab(ln_loop_cnt).collation_code;               -- Æ
      gt_data_tab(ln_data_cnt)(cv_uom_code)                 := gt_edi_order_tab(ln_loop_cnt).uom_code;                     -- PÊ
      gt_data_tab(ln_data_cnt)(cv_unit_price_class)         := gt_edi_order_tab(ln_loop_cnt).unit_price_class;             -- P¿æª
      gt_data_tab(ln_data_cnt)(cv_parent_packing_number)    := gt_edi_order_tab(ln_loop_cnt).parent_packing_number;        -- e«ïÔ
      gt_data_tab(ln_data_cnt)(cv_packing_number)           := gt_edi_order_tab(ln_loop_cnt).packing_number;               -- «ïÔ
      gt_data_tab(ln_data_cnt)(cv_prod_group_code)          := gt_edi_order_tab(ln_loop_cnt).product_group_code;           -- ¤iQº°ÄÞ
      gt_data_tab(ln_data_cnt)(cv_case_dismantle_flag)      := gt_edi_order_tab(ln_loop_cnt).case_dismantle_flag;          -- ¹°½ðÌsÂÌ×¸Þ
      gt_data_tab(ln_data_cnt)(cv_case_class)               := gt_edi_order_tab(ln_loop_cnt).case_class;                   -- ¹°½æª
      -- u}ÌæªvªA'èüÍ'Ìê
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        -- u¾×PÊvªA'P[XPÊR[h'Ìê
        IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- ­Ê(ÊÞ×)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(¹°½)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- ­Ê(ÎÞ°Ù)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(v¤ÊÞ×)
        -- u¾×PÊvªA'{[PÊR[h'Ìê
        ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- ­Ê(ÊÞ×)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- ­Ê(¹°½)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(ÎÞ°Ù)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(v¤ÊÞ×)
        -- ãLÈOÌê
        ELSE
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(ÊÞ×)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- ­Ê(¹°½)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- ­Ê(ÎÞ°Ù)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ­Ê(v¤ÊÞ×)
        END IF;
      -- ãLÈOÌê
      ELSE
        gt_data_tab(ln_data_cnt)(cv_indv_order_qty)         := gt_edi_order_tab(ln_loop_cnt).indv_order_qty;               -- ­Ê(ÊÞ×)
        gt_data_tab(ln_data_cnt)(cv_case_order_qty)         := gt_edi_order_tab(ln_loop_cnt).case_order_qty;               -- ­Ê(¹°½)
        gt_data_tab(ln_data_cnt)(cv_ball_order_qty)         := gt_edi_order_tab(ln_loop_cnt).ball_order_qty;               -- ­Ê(ÎÞ°Ù)
        gt_data_tab(ln_data_cnt)(cv_sum_order_qty)          := gt_edi_order_tab(ln_loop_cnt).sum_order_qty;                -- ­Ê(v¤ÊÞ×)
      END IF;
--
--****************************** 2009/06/24 1.10 T.Kitajima MOD START ******************************--
--      -- u¾×PÊvªA'P[XPÊR[h'Ìê
--      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- o×Ê(ÊÞ×)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(¹°½)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- o×Ê(ÎÞ°Ù)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(v¤ÊÞ×)
--      -- u¾×PÊvªA'{[PÊR[h'Ìê
--      ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- o×Ê(ÊÞ×)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- o×Ê(¹°½)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(ÎÞ°Ù)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(v¤ÊÞ×)
--      -- ãLÈOÌê
--      ELSE
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(ÊÞ×)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- o×Ê(¹°½)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- o×Ê(ÎÞ°Ù)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(v¤ÊÞ×)
--      END IF;
--
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(v¤ÊÞ×)
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- o×Ê(v¤ÊÞ×)
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).sum_shipping_qty;             -- o×Ê(v¤ÊÞ×)
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
--
      xxcos_common2_pkg.convert_quantity(
/* 2009/07/24 Ver1.11 Mod Start */
--               iv_uom_code             => gt_data_tab(ln_data_cnt)(cv_uom_code)               --IN :PÊR[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_07554 */
--               iv_uom_code             => gt_edi_order_tab(ln_loop_cnt).order_quantity_uom --IN :PÊR[h
               iv_uom_code             => NVL( gt_edi_order_tab(ln_loop_cnt).order_quantity_uom
                                              ,cv_uom_hon
                                             )                                             --IN :PÊR[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2009/07/24 Ver1.11 Mod End   */
              ,in_case_qty             => gt_data_tab(ln_data_cnt)(cv_num_of_cases)        --IN :P[Xü
              ,in_ball_qty             => NVL( gt_edi_order_tab(ln_loop_cnt).num_of_ball
                                              ,gt_edi_order_tab(ln_loop_cnt).bowl_inc_num
                                             )                                             --IN :{[ü
              ,in_sum_indv_order_qty   => gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        --IN :­Ê(vEo)
              ,in_sum_shipping_qty     => gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)        --IN :o×Ê(vEo)
              ,on_indv_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)       --OUT:o×Ê(o)
              ,on_case_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_case_ship_qty)       --OUT:o×Ê(P[X)
              ,on_ball_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)       --OUT:o×Ê({[)
              ,on_indv_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)     --OUT:iÊ(o)
              ,on_case_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)     --OUT:iÊ(P[X)
              ,on_ball_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)     --OUT:iÊ({[)
              ,on_sum_stockout_qty     => gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)      --OUT:iÊ(vEo)
              ,ov_errbuf               => lv_errbuf                                        --OUT:G[EbZ[WG[ #Åè#
              ,ov_retcode              => lv_retcode                                       --OUT:^[ER[h         #Åè#
              ,ov_errmsg               => lv_errmsg                                        --[U[EG[EbZ[W #Åè#
              );
      IF ( lv_retcode = cv_status_error ) THEN
--        lv_errmsg := lv_errbuf;
        RAISE global_api_expt;
      END IF;
--****************************** 2009/06/24 1.10 T.Kitajima MOD  END  ******************************--
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Add Start
--      -- ¤iR[h(É¡)vªA_~[iÚÌêASÄ"0"ÉÏX
--      IF ( ln_dummy_item = cn_1) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- o×Ê(ÊÞ×)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- o×Ê(¹°½)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- o×Ê(ÎÞ°Ù)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := cn_0;                                                       -- o×Ê(v¤ÊÞ×)
--      END IF;
---- 2009/05/22 Ver1.9 Add End
/* 2010/04/15 Ver1.20 Del End   */
      gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty)          := NULL;                                                       -- o×Ê(ÊßÚ¯Ä)
--****************************** 2009/06/24 1.10 T.Kitajima DEL START ******************************--
--/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_indv_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);                 -- iÊ(ÊÞ×)
--    gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_case_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_case_ship_qty);                 -- iÊ(¹°½)
--    gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_ball_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);                 -- iÊ(ÎÞ°Ù)
--    gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := gt_data_tab(ln_data_cnt)(cv_sum_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);                  -- iÊ(v¤ÊÞ×)
--      gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);         -- iÊ(ÊÞ×)
--      gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);         -- iÊ(¹°½)
--      gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);         -- iÊ(ÎÞ°Ù)
--      gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);          -- iÊ(v¤ÊÞ×)
--/* 2009/02/25 Ver1.4 Mod  End  */
--****************************** 2009/06/24 1.10 T.Kitajima DEL  END  ******************************--
      -- iÊ(óÊ|o×Ê)OÌê
      IF ( gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty) = cn_0 ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := cv_stockout_class_00;                                       -- iæª
      ELSE
/* 2011/04/27 Ver1.24 Mod Start */
--        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gt_edi_order_tab(ln_loop_cnt).stockout_class;               -- iæª
        --ú»
        ln_reason_id                              := NULL;
        gt_data_tab(ln_data_cnt)(cv_stkout_class) := NULL;
        lv_select_flag                            := NULL;
        --RR[h}X^f[^æ¾¤ÊÖæèRR[hðæ¾·é
        xxcos_common2_pkg.get_reason_data(
           gt_edi_order_tab(ln_loop_cnt).line_id      -- ó¾×ID
          ,ln_reason_id                               -- RR[h}X^àID
          ,gt_data_tab(ln_data_cnt)(cv_stkout_class)  -- RR[h
          ,lv_select_flag                             -- IðÂ\tO
          ,lv_errbuf                                  -- G[EbZ[WG[     #Åè#
          ,lv_retcode                                 -- ^[ER[h             #Åè#
          ,lv_errmsg                                  -- [U[EG[EbZ[W #Åè#
        );
--
        --IðÂ\tOª'N'(NULL)ÌêÍARR[hÍG[æÁR
        IF ( NVL(lv_select_flag, cv_n ) = cv_n ) THEN
          gt_data_tab(ln_data_cnt)(cv_stkout_class) := cv_err_reason_code;
        END IF;
--
/* 2011/04/27 Ver1.24 Mod End   */
      END IF;
/* 2010/04/15 Ver1.20 Del Start */
---- 2009/05/22 Ver1.9 Mod Start
--      -- ¤iR[h(É¡)vªA_~[iÚÌêAvt@ClÉC³
--      IF ( ln_dummy_item = cn_1) THEN
--        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gn_dum_stock_out;                                           -- iæª
--      END IF;
---- 2009/05/22 Ver1.9 Mod End
/* 2010/04/15 Ver1.20 Del End   */
      gt_data_tab(ln_data_cnt)(cv_stkout_reason)            := NULL;                                                       -- iR
      gt_data_tab(ln_data_cnt)(cv_case_qty)                 := gt_edi_order_tab(ln_loop_cnt).case_qty;                     -- ¹°½Âû
      gt_data_tab(ln_data_cnt)(cv_fold_container_indv_qty)  := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;      -- µØºÝ(ÊÞ×)Âû
      gt_data_tab(ln_data_cnt)(cv_order_unit_price)         := gt_edi_order_tab(ln_loop_cnt).order_unit_price;             -- ´P¿(­)
      gt_data_tab(ln_data_cnt)(cv_ship_unit_price)          := gt_edi_order_tab(ln_loop_cnt).unit_selling_price;           -- ´P¿(o×)
      gt_data_tab(ln_data_cnt)(cv_order_cost_amt)           := gt_edi_order_tab(ln_loop_cnt).order_cost_amt;               -- ´¿àz(­)
/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_ship_unit_price);               -- ´¿àz(o×)
--    gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)          := gt_data_tab(ln_data_cnt)(cv_order_cost_amt)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);                 -- ´¿àz(i)
/* 2009/07/21 Ver1.11 Mod Start */
--      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
--                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0);       -- ´¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := TRUNC(NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0));      -- ´¿àz(o×)
/* 2009/07/21 Ver1.11 Mod End   */
/* 2009/02/27 Ver1.5 Mod Start */
      -- u}ÌæªvªA'èüÍ'Ìê
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := cn_0;                                                       -- ´¿àz(i)
      ELSE
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0)
                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);         -- ´¿àz(i)
      END IF;
/* 2009/02/27 Ver1.5 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_selling_price)            := gt_edi_order_tab(ln_loop_cnt).selling_price;                -- P¿
      gt_data_tab(ln_data_cnt)(cv_order_price_amt)          := gt_edi_order_tab(ln_loop_cnt).order_price_amt;              -- ¿àz(­)
--    gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- ¿àz(o×)
--    gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- ¿àz(i)
      gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- ¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- ¿àz(i)
/* 2009/02/25 Ver1.4 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_a_column_department)      := gt_edi_order_tab(ln_loop_cnt).a_column_department;          -- A(SÝX)
      gt_data_tab(ln_data_cnt)(cv_d_column_department)      := gt_edi_order_tab(ln_loop_cnt).d_column_department;          -- D(SÝX)
      gt_data_tab(ln_data_cnt)(cv_standard_info_depth)      := gt_edi_order_tab(ln_loop_cnt).standard_info_depth;          -- Kiîñ¥s«
      gt_data_tab(ln_data_cnt)(cv_standard_info_height)     := gt_edi_order_tab(ln_loop_cnt).standard_info_height;         -- Kiîñ¥³
      gt_data_tab(ln_data_cnt)(cv_standard_info_width)      := gt_edi_order_tab(ln_loop_cnt).standard_info_width;          -- Kiîñ¥
      gt_data_tab(ln_data_cnt)(cv_standard_info_weight)     := gt_edi_order_tab(ln_loop_cnt).standard_info_weight;         -- Kiîñ¥dÊ
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item1)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item1;      -- Äpøp¬Ú1
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item2)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item2;      -- Äpøp¬Ú2
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item3)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item3;      -- Äpøp¬Ú3
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item4)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item4;      -- Äpøp¬Ú4
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item5)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item5;      -- Äpøp¬Ú5
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item6)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item6;      -- Äpøp¬Ú6
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item7)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item7;      -- Äpøp¬Ú7
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item8)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item8;      -- Äpøp¬Ú8
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item9)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item9;      -- Äpøp¬Ú9
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item10)           := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item10;     -- Äpøp¬Ú10
      gt_data_tab(ln_data_cnt)(cv_gen_add_item1)            := gt_edi_order_tab(ln_loop_cnt).tax_rate;                     -- ÄptÁÚ1
      gt_data_tab(ln_data_cnt)(cv_gen_add_item2)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 1, 10);
                                                                                                                           -- ÄptÁÚ2
      gt_data_tab(ln_data_cnt)(cv_gen_add_item3)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 11, 10);
                                                                                                                           -- ÄptÁÚ3
      gt_data_tab(ln_data_cnt)(cv_gen_add_item4)            := gt_edi_order_tab(ln_loop_cnt).general_add_item4;            -- ÄptÁÚ4
      gt_data_tab(ln_data_cnt)(cv_gen_add_item5)            := gt_edi_order_tab(ln_loop_cnt).general_add_item5;            -- ÄptÁÚ5
      gt_data_tab(ln_data_cnt)(cv_gen_add_item6)            := gt_edi_order_tab(ln_loop_cnt).general_add_item6;            -- ÄptÁÚ6
      gt_data_tab(ln_data_cnt)(cv_gen_add_item7)            := gt_edi_order_tab(ln_loop_cnt).general_add_item7;            -- ÄptÁÚ7
      gt_data_tab(ln_data_cnt)(cv_gen_add_item8)            := gt_edi_order_tab(ln_loop_cnt).general_add_item8;            -- ÄptÁÚ8
      gt_data_tab(ln_data_cnt)(cv_gen_add_item9)            := gt_edi_order_tab(ln_loop_cnt).general_add_item9;            -- ÄptÁÚ9
/* 2019/06/25 Ver1.29 Mod Start */
--      gt_data_tab(ln_data_cnt)(cv_gen_add_item10)           := gt_edi_order_tab(ln_loop_cnt).general_add_item10;           -- ÄptÁÚ10
      -- ´¿àz(o×)ªNULLAÜ½Í0Ìê
      IF (( gt_data_tab(ln_data_cnt)(cv_ship_cost_amt) IS NULL )
          OR ( gt_data_tab(ln_data_cnt)(cv_ship_cost_amt) = 0  ))  THEN
            gt_data_tab(ln_data_cnt)(cv_gen_add_item10)     := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);
      ELSE
        -- ÁïÅ¦Zo
        ln_tax_rate := gt_data_tab(ln_data_cnt)(cv_gen_add_item1) / 100;
        
        -- ÁïÅæªªàÅ(P¿Ý)Ìê
        IF   ( gt_data_tab(ln_data_cnt)(cv_consumption_tax_class) = cv_ins_bid_tax ) THEN
                gt_data_tab(ln_data_cnt)(cv_gen_add_item10) := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt) -
                                                                 ( gt_data_tab(ln_data_cnt)(cv_ship_cost_amt) / ( 1 + ln_tax_rate ));
        ELSE
        -- ÁïÅæªªàÅ(P¿Ý)ÈOÌê
                gt_data_tab(ln_data_cnt)(cv_gen_add_item10) := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt) * ln_tax_rate;
        END IF;
      END IF;                                                                                                              -- ÄptÁÚ10
      --[
      IF ( gt_data_tab(ln_data_cnt)(cv_gen_add_item10)  <>  TRUNC(gt_data_tab(ln_data_cnt)(cv_gen_add_item10)) ) THEN
        IF ( gv_tax_round_rule  =  cv_tkn_down  )    THEN  -- ØÌÄ
             --¬I_ÈºÌØÌÄ
             gt_data_tab(ln_data_cnt)(cv_gen_add_item10)   := TRUNC( gt_data_tab(ln_data_cnt)(cv_gen_add_item10));
        ELSIF
           ( gv_tax_round_rule  =  cv_tkn_up    )    THEN  -- Øã°
             --¬_ÈºÌØã°
             IF ( SIGN( gt_data_tab(ln_data_cnt)(cv_gen_add_item10) )  <>  -1 )  THEN
               gt_data_tab(ln_data_cnt)(cv_gen_add_item10) := TRUNC( gt_data_tab(ln_data_cnt)(cv_gen_add_item10) ) + 1;
             ELSE
               gt_data_tab(ln_data_cnt)(cv_gen_add_item10) := TRUNC( gt_data_tab(ln_data_cnt)(cv_gen_add_item10) ) - 1;
             END IF;
        ELSIF
           ( gv_tax_round_rule = cv_tkn_nearest )    THEN  -- lÌÜü
               gt_data_tab(ln_data_cnt)(cv_gen_add_item10) := ROUND( gt_data_tab(ln_data_cnt)(cv_gen_add_item10) );
        END IF;
      END IF;
/* 2019/06/25 Ver1.29 Mod End */
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_line)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_line;     -- Áª°ÝXÅL´Ø±(¾×)
--
      -- tb^
      gt_data_tab(ln_data_cnt)(cv_invc_indv_order_qty)        := NULL;  -- (`[v)­Ê(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_case_order_qty)        := NULL;  -- (`[v)­Ê(¹°½)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_order_qty)        := NULL;  -- (`[v)­Ê(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_order_qty)         := NULL;  -- (`[v)­Ê(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_ship_qty)         := NULL;  -- (`[v)o×Ê(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_case_ship_qty)         := NULL;  -- (`[v)o×Ê(¹°½)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_ship_qty)         := NULL;  -- (`[v)o×Ê(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_invc_pallet_ship_qty)       := NULL;  -- (`[v)o×Ê(ÊßÚ¯Ä)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_ship_qty)          := NULL;  -- (`[v)o×Ê(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_stkout_qty)       := NULL;  -- (`[v)iÊ(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_case_stkout_qty)       := NULL;  -- (`[v)iÊ(¹°½)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_stkout_qty)       := NULL;  -- (`[v)iÊ(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_stkout_qty)        := NULL;  -- (`[v)iÊ(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_invc_case_qty)              := NULL;  -- (`[v)¹°½Âû
      gt_data_tab(ln_data_cnt)(cv_invc_fold_container_qty)    := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;     -- (`[v)µØºÝ(ÊÞ×)Âû
      gt_data_tab(ln_data_cnt)(cv_invc_order_cost_amt)        := NULL;  -- (`[v)´¿àz(­)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_cost_amt)         := NULL;  -- (`[v)´¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_cost_amt)       := NULL;  -- (`[v)´¿àz(i)
      gt_data_tab(ln_data_cnt)(cv_invc_order_price_amt)       := NULL;  -- (`[v)¿àz(­)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_price_amt)        := NULL;  -- (`[v)¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_price_amt)      := NULL;  -- (`[v)¿àz(i)
      gt_data_tab(ln_data_cnt)(cv_t_indv_order_qty)           := NULL;  -- (v)­Ê(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_case_order_qty)           := NULL;  -- (v)­Ê(¹°½)
      gt_data_tab(ln_data_cnt)(cv_t_ball_order_qty)           := NULL;  -- (v)­Ê(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_t_sum_order_qty)            := NULL;  -- (v)­Ê(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_indv_ship_qty)            := NULL;  -- (v)o×Ê(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_case_ship_qty)            := NULL;  -- (v)o×Ê(¹°½)
      gt_data_tab(ln_data_cnt)(cv_t_ball_ship_qty)            := NULL;  -- (v)o×Ê(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_t_pallet_ship_qty)          := NULL;  -- (v)o×Ê(ÊßÚ¯Ä)
      gt_data_tab(ln_data_cnt)(cv_t_sum_ship_qty)             := NULL;  -- (v)o×Ê(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_indv_stkout_qty)          := NULL;  -- (v)iÊ(ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_case_stkout_qty)          := NULL;  -- (v)iÊ(¹°½)
      gt_data_tab(ln_data_cnt)(cv_t_ball_stkout_qty)          := NULL;  -- (v)iÊ(ÎÞ°Ù)
      gt_data_tab(ln_data_cnt)(cv_t_sum_stkout_qty)           := NULL;  -- (v)iÊ(v¤ÊÞ×)
      gt_data_tab(ln_data_cnt)(cv_t_case_qty)                 := NULL;  -- (v)¹°½Âû
      gt_data_tab(ln_data_cnt)(cv_t_fold_container_qty)       := NULL;  -- (v)µØºÝ(ÊÞ×)Âû
      gt_data_tab(ln_data_cnt)(cv_t_order_cost_amt)           := NULL;  -- (v)´¿àz(­)
      gt_data_tab(ln_data_cnt)(cv_t_ship_cost_amt)            := NULL;  -- (v)´¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_cost_amt)          := NULL;  -- (v)´¿àz(i)
      gt_data_tab(ln_data_cnt)(cv_t_order_price_amt)          := NULL;  -- (v)¿àz(­)
      gt_data_tab(ln_data_cnt)(cv_t_ship_price_amt)           := NULL;  -- (v)¿àz(o×)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_price_amt)         := NULL;  -- (v)¿àz(i)
      gt_data_tab(ln_data_cnt)(cv_t_line_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_line_qty;              -- Ä°ÀÙs
      gt_data_tab(ln_data_cnt)(cv_t_invc_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_invoice_qty;           -- Ä°ÀÙ`[
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_footer)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_footer;  -- Áª°ÝXÅL´Ø±(Ì¯À)
/* 2009/04/28 Ver1.7 Add Start */
      gt_data_tab(ln_data_cnt)(cv_attribute)                  := NULL;  -- \õGA
/* 2009/04/28 Ver1.7 Add End   */
/* 2011/09/03 Ver1.25 Add Start */
      gt_data_tab(ln_data_cnt)(cv_bms_header_data)            := gt_edi_order_tab(ln_loop_cnt).bms_header_data;  --¬Êalrwb_f[^
      gt_data_tab(ln_data_cnt)(cv_bms_line_data)              := gt_edi_order_tab(ln_loop_cnt).bms_line_data;    --¬Êalr¾×f[^
/* 2011/09/03 Ver1.25 Add End   */
--
      --==============================================================
      -- `[ÊvZo
      --==============================================================
/* 2009/02/25 Ver1.4 Mod Start */
/*
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_order_qty);    -- ­Ê(o)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_order_qty);    -- ­Ê(P[X)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_order_qty);    -- ­Ê({[)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_order_qty);     -- ­Ê(vAo)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);     -- o×Ê(o)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_ship_qty);     -- o×Ê(P[X)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);     -- o×Ê({[)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);   -- o×Ê(pbg)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);      -- o×Ê(vAo)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);   -- iÊ(o)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);   -- iÊ(P[X)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);   -- iÊ({[)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);    -- iÊ(vAo)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_qty);          -- P[XÂû
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_cost_amt);    -- ´¿àz(­)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);     -- ´¿àz(o×)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);   -- ´¿àz(i)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_price_amt);   -- ¿àz(­)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_price_amt);    -- ¿àz(o×)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);  -- ¿àz(i)
*/
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0);    -- ­Ê(o)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0);    -- ­Ê(P[X)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0);    -- ­Ê({[)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0);     -- ­Ê(vAo)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);     -- o×Ê(o)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);     -- o×Ê(P[X)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);     -- o×Ê({[)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty), 0);   -- o×Ê(pbg)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);      -- o×Ê(vAo)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty), 0);   -- iÊ(o)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_stkout_qty), 0);   -- iÊ(P[X)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty), 0);   -- iÊ({[)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0);    -- iÊ(vAo)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_qty), 0);          -- P[XÂû
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0);    -- ´¿àz(­)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);     -- ´¿àz(o×)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt), 0);   -- ´¿àz(i)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_price_amt), 0);   -- ¿àz(­)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_price_amt), 0);    -- ¿àz(o×)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_price_amt), 0);  -- ¿àz(i)
/* 2009/02/25 Ver1.4 Mod  End  */
--
      --==============================================================
      -- EDI¾×îñÒW
      --==============================================================
      gt_edi_line_tab(ln_loop_cnt).edi_line_info_id    := gt_edi_order_tab(ln_loop_cnt).edi_line_info_id;     -- EDI¾×îñID
      gt_edi_line_tab(ln_loop_cnt).edi_header_info_id  := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;   -- EDIwb_îñID
      gt_edi_line_tab(ln_loop_cnt).line_no             := gt_data_tab(ln_data_cnt)(cv_line_no);               -- sm
      gt_edi_line_tab(ln_loop_cnt).stockout_class      := gt_data_tab(ln_data_cnt)(cv_stkout_class);          -- iæª
      gt_edi_line_tab(ln_loop_cnt).stockout_reason     := gt_data_tab(ln_data_cnt)(cv_stkout_reason);         -- iR
      gt_edi_line_tab(ln_loop_cnt).product_code_itouen := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- ¤iR[h(É¡)
      gt_edi_line_tab(ln_loop_cnt).jan_code            := gt_data_tab(ln_data_cnt)(cv_jan_code);              -- JANR[h
      gt_edi_line_tab(ln_loop_cnt).itf_code            := gt_data_tab(ln_data_cnt)(cv_itf_code);              -- ITFR[h
      gt_edi_line_tab(ln_loop_cnt).prod_class          := gt_data_tab(ln_data_cnt)(cv_prod_class);            -- ¤iæª
      gt_edi_line_tab(ln_loop_cnt).product_name        := gt_data_tab(ln_data_cnt)(cv_prod_name);             -- ¤i¼(¿)
      gt_edi_line_tab(ln_loop_cnt).product_name2_alt   := gt_data_tab(ln_data_cnt)(cv_prod_name2_alt);        -- ¤i¼2(Ji)
      gt_edi_line_tab(ln_loop_cnt).item_standard2      := gt_data_tab(ln_data_cnt)(cv_item_standard2);        -- Ki2
      gt_edi_line_tab(ln_loop_cnt).num_of_cases        := gt_data_tab(ln_data_cnt)(cv_num_of_cases);          -- P[Xü
      gt_edi_line_tab(ln_loop_cnt).num_of_ball         := gt_data_tab(ln_data_cnt)(cv_num_of_ball);           -- {[ü
      gt_edi_line_tab(ln_loop_cnt).indv_order_qty      := gt_data_tab(ln_data_cnt)(cv_indv_order_qty);        -- ­Ê(o)
      gt_edi_line_tab(ln_loop_cnt).case_order_qty      := gt_data_tab(ln_data_cnt)(cv_case_order_qty);        -- ­Ê(P[X)
      gt_edi_line_tab(ln_loop_cnt).ball_order_qty      := gt_data_tab(ln_data_cnt)(cv_ball_order_qty);        -- ­Ê({[)
      gt_edi_line_tab(ln_loop_cnt).sum_order_qty       := gt_data_tab(ln_data_cnt)(cv_sum_order_qty);         -- ­Ê(vAo)
      gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);         -- o×Ê(o)
      gt_edi_line_tab(ln_loop_cnt).case_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_case_ship_qty);         -- o×Ê(P[X)
      gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);         -- o×Ê({[)
      gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty := gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);       -- o×Ê(pbg)
      gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty    := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);          -- o×Ê(vAo)
      gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);       -- iÊ(o)
      gt_edi_line_tab(ln_loop_cnt).case_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);       -- iÊ(P[X)
      gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);       -- iÊ({[)
      gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty    := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);        -- iÊ(vAo)
      gt_edi_line_tab(ln_loop_cnt).shipping_unit_price := gt_data_tab(ln_data_cnt)(cv_ship_unit_price);       -- ´P¿(o×)
      gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt   := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);         -- ´¿àz(o×)
      gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt   := gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);       -- ´¿àz(i)
      gt_edi_line_tab(ln_loop_cnt).shipping_price_amt  := gt_data_tab(ln_data_cnt)(cv_ship_price_amt);        -- ¿àz(o×)
      gt_edi_line_tab(ln_loop_cnt).stockout_price_amt  := gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);      -- ¿àz(i)
      gt_edi_line_tab(ln_loop_cnt).general_add_item1   := gt_data_tab(ln_data_cnt)(cv_gen_add_item1);         -- ÄptÁÚ1
      gt_edi_line_tab(ln_loop_cnt).general_add_item2   := gt_data_tab(ln_data_cnt)(cv_gen_add_item2);         -- ÄptÁÚ2
      gt_edi_line_tab(ln_loop_cnt).general_add_item3   := gt_data_tab(ln_data_cnt)(cv_gen_add_item3);         -- ÄptÁÚ3
/* 2019/06/25 Ver1.29 Add Start */
      gt_edi_line_tab(ln_loop_cnt).general_add_item10  := gt_data_tab(ln_data_cnt)(cv_gen_add_item10);        -- ÄptÁÚ10
/* 2019/06/25 Ver1.29 Add  End  */
      gt_edi_line_tab(ln_loop_cnt).item_code           := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- iÚR[h
    END LOOP edit_loop;
--
    --==============================================================
    -- G[Ìê
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- f[^¬`(A-7)
    --==============================================================
    format_data(
       iv_make_class        -- 2.ì¬æª
      ,l_invoice_total_rec  -- `[v
      ,lt_header_id         -- EDIwb_îñID
      ,lt_delivery_flag     -- EDI[i\èMÏtO
      ,lv_errbuf            -- G[EbZ[W           --# Åè #
      ,lv_retcode           -- ^[ER[h             --# Åè #
      ,lv_errmsg            -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
/* 2010/07/08 Ver1.22 Add Start */
    -- *** ÚqiÚ`FbNáOnh ***
    WHEN global_item_conv_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
/* 2010/07/08 Ver1.22 Add End */
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END edit_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : t@CoÍ(A-8)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- t@CoÍ
    --==============================================================
    <<output_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_record_tab.COUNT LOOP
      -- f[^oÍ
      UTL_FILE.PUT_LINE(
         file   => gt_f_handle                      -- t@Cnh
        ,buffer => gt_data_record_tab(ln_loop_cnt)  -- oÍ¶(f[^)
      );
      -- ³íJEg
      gn_normal_cnt := gn_normal_cnt + cn_1;
    END LOOP output_loop;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : t@CI¹(A-9)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
/* 2011/09/03 Ver1.25 Mod Start */
--/* 2009/04/28 Ver1.7 Mod Start */
----    lv_footer_output  VARCHAR2(1000);  -- tb^oÍp
--    lv_footer_output  VARCHAR2(5000);  -- tb^oÍp
    lv_footer_output  VARCHAR2(32767);  -- tb^oÍp
--/* 2009/04/28 Ver1.7 Mod End   */
/* 2011/09/03 Ver1.25 Mod End   */
    lv_dummy1         VARCHAR2(1);     -- IF³Æ±nñR[h(tb^ÅÍgpµÈ¢)
    lv_dummy2         VARCHAR2(1);     -- _R[h(tb^ÅÍgpµÈ¢)
    lv_dummy3         VARCHAR2(1);     -- _¼Ì(tb^ÅÍgpµÈ¢)
    lv_dummy4         VARCHAR2(1);     -- `F[XR[h(tb^ÅÍgpµÈ¢)
    lv_dummy5         VARCHAR2(1);     -- `F[X¼Ì(tb^ÅÍgpµÈ¢)
    lv_dummy6         VARCHAR2(1);     -- f[^íR[h(tb^ÅÍgpµÈ¢)
    lv_dummy7         VARCHAR2(1);     -- ÀñÔ(tb^ÅÍgpµÈ¢)
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- ¤ÊÖÄÑoµ
    --==============================================================
    -- EDIwb_Etb^t^
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_footer      -- t^æª
      ,iv_from_series     =>  lv_dummy1         -- IF³Æ±nñR[h
      ,iv_base_code       =>  lv_dummy2         -- _R[h
      ,iv_base_name       =>  lv_dummy3         -- _¼Ì
      ,iv_chain_code      =>  lv_dummy4         -- `F[XR[h
      ,iv_chain_name      =>  lv_dummy5         -- `F[X¼Ì
/* 2011/09/03 Ver1.25 Mod Start */
--      ,iv_data_kind       =>  lv_dummy6         -- f[^íR[h
      ,iv_data_kind       =>  gt_data_type_code -- f[^íR[h
/* 2011/09/03 Ver1.25 Mod End   */
      ,iv_row_number      =>  lv_dummy7         -- ÀñÔ
      ,in_num_of_records  =>  gn_target_cnt     -- R[h
      ,ov_retcode         =>  lv_retcode        -- ^[R[h
      ,ov_output          =>  lv_footer_output  -- tb^R[h
      ,ov_errbuf          =>  lv_errbuf         -- G[bZ[W
      ,ov_errmsg          =>  lv_errmsg         -- [U[EG[EbZ[W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- bZ[Wæ¾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- AvP[V
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI¤ÊÖG[bZ[W
                     ,iv_token_name1  => cv_tkn_err_msg       -- g[NR[hP
                     ,iv_token_value1 => lv_errmsg            -- G[EbZ[W
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- t@CoÍ
    --==============================================================
    -- tb^oÍ
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- t@Cnh
      ,buffer => lv_footer_output  -- oÍ¶(tb^)
    );
--
    --==============================================================
    -- t@CN[Y
    --==============================================================
    UTL_FILE.FCLOSE(
       file => gt_f_handle
    );
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : update_edi_order
   * Description      : EDIóîñXV(A-10)
   ***********************************************************************************/
  PROCEDURE update_edi_order(
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_edi_order'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_tkn_value1      VARCHAR2(50);    -- g[Næ¾p1
    lv_tkn_value2      VARCHAR2(50);    -- g[Næ¾p2
    lv_err_msg         VARCHAR2(5000);  -- G[oÍp
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- EDIwb_îñXV
    --==============================================================
    <<update_header_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_header_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_headers  xeh
        SET    xeh.process_date                = gt_edi_header_tab(ln_loop_cnt).process_date                 -- ú
              ,xeh.process_time                = gt_edi_header_tab(ln_loop_cnt).process_time                 -- 
              ,xeh.base_code                   = gt_edi_header_tab(ln_loop_cnt).base_code                    -- _(å)R[h
              ,xeh.base_name                   = gt_edi_header_tab(ln_loop_cnt).base_name                    -- _¼(³®¼)
              ,xeh.base_name_alt               = gt_edi_header_tab(ln_loop_cnt).base_name_alt                -- _¼(Ji)
              ,xeh.customer_code               = gt_edi_header_tab(ln_loop_cnt).customer_code                -- ÚqR[h
              ,xeh.customer_name               = gt_edi_header_tab(ln_loop_cnt).customer_name                -- Úq¼(¿)
              ,xeh.customer_name_alt           = gt_edi_header_tab(ln_loop_cnt).customer_name_alt            -- Úq¼(Ji)
              ,xeh.shop_name                   = gt_edi_header_tab(ln_loop_cnt).shop_name                    -- X¼(¿)
              ,xeh.shop_name_alt               = gt_edi_header_tab(ln_loop_cnt).shop_name_alt                -- X¼(Ji)
              ,xeh.center_delivery_date        = gt_edi_header_tab(ln_loop_cnt).center_delivery_date         -- Z^[[iú
              ,xeh.order_no_ebs                = gt_edi_header_tab(ln_loop_cnt).order_no_ebs                 -- óNo(EBS)
              ,xeh.contact_to                  = gt_edi_header_tab(ln_loop_cnt).contact_to                   -- Aæ
              ,xeh.area_code                   = gt_edi_header_tab(ln_loop_cnt).area_code                    -- næR[h
              ,xeh.area_name                   = gt_edi_header_tab(ln_loop_cnt).area_name                    -- næ¼(¿)
              ,xeh.area_name_alt               = gt_edi_header_tab(ln_loop_cnt).area_name_alt                -- næ¼(Ji)
              ,xeh.vendor_code                 = gt_edi_header_tab(ln_loop_cnt).vendor_code                  -- æøæR[h
              ,xeh.vendor_name                 = gt_edi_header_tab(ln_loop_cnt).vendor_name                  -- æøæ¼(¿)
              ,xeh.vendor_name1_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name1_alt             -- æøæ¼1(Ji)
              ,xeh.vendor_name2_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name2_alt             -- æøæ¼2(Ji)
              ,xeh.vendor_tel                  = gt_edi_header_tab(ln_loop_cnt).vendor_tel                   -- æøæTEL
              ,xeh.vendor_charge               = gt_edi_header_tab(ln_loop_cnt).vendor_charge                -- æøæSÒ
              ,xeh.vendor_address              = gt_edi_header_tab(ln_loop_cnt).vendor_address               -- æøæZ(¿)
              ,xeh.delivery_schedule_time      = gt_edi_header_tab(ln_loop_cnt).delivery_schedule_time       -- [i\èÔ
              ,xeh.carrier_means               = gt_edi_header_tab(ln_loop_cnt).carrier_means                -- ^èi
              ,xeh.eos_handwriting_class       = gt_edi_header_tab(ln_loop_cnt).eos_handwriting_class        -- EOS¥èæª
              ,xeh.invoice_indv_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_indv_order_qty       -- (`[v)­Ê(o)
              ,xeh.invoice_case_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_case_order_qty       -- (`[v)­Ê(P[X)
              ,xeh.invoice_ball_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_ball_order_qty       -- (`[v)­Ê({[)
              ,xeh.invoice_sum_order_qty       = gt_edi_header_tab(ln_loop_cnt).invoice_sum_order_qty        -- (`[v)­Ê(vAo)
              ,xeh.invoice_indv_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_shipping_qty    -- (`[v)o×Ê(o)
              ,xeh.invoice_case_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_shipping_qty    -- (`[v)o×Ê(P[X)
              ,xeh.invoice_ball_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_shipping_qty    -- (`[v)o×Ê({[)
              ,xeh.invoice_pallet_shipping_qty = gt_edi_header_tab(ln_loop_cnt).invoice_pallet_shipping_qty  -- (`[v)o×Ê(pbg)
              ,xeh.invoice_sum_shipping_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_shipping_qty     -- (`[v)o×Ê(vAo)
              ,xeh.invoice_indv_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_stockout_qty    -- (`[v)iÊ(o)
              ,xeh.invoice_case_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_stockout_qty    -- (`[v)iÊ(P[X)
              ,xeh.invoice_ball_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_stockout_qty    -- (`[v)iÊ({[)
              ,xeh.invoice_sum_stockout_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_stockout_qty     -- (`[v)iÊ(vAo)
              ,xeh.invoice_case_qty            = gt_edi_header_tab(ln_loop_cnt).invoice_case_qty             -- (`[v)P[XÂû
              ,xeh.invoice_fold_container_qty  = gt_edi_header_tab(ln_loop_cnt).invoice_fold_container_qty   -- (`[v)IR(o)Âû
              ,xeh.invoice_order_cost_amt      = gt_edi_header_tab(ln_loop_cnt).invoice_order_cost_amt       -- (`[v)´¿àz(­)
              ,xeh.invoice_shipping_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_cost_amt    -- (`[v)´¿àz(o×)
              ,xeh.invoice_stockout_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_cost_amt    -- (`[v)´¿àz(i)
              ,xeh.invoice_order_price_amt     = gt_edi_header_tab(ln_loop_cnt).invoice_order_price_amt      -- (`[v)¿àz(­)
              ,xeh.invoice_shipping_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_price_amt   -- (`[v)¿àz(o×)
              ,xeh.invoice_stockout_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_price_amt   -- (`[v)¿àz(i)
/* 2010/03/09 Ver1.16 Add Start */
              ,xeh.total_order_price_amt       = gt_edi_header_tab(ln_loop_cnt).total_order_price_amt        -- (v)¿àz(­)
              ,xeh.total_shipping_price_amt    = gt_edi_header_tab(ln_loop_cnt).total_shipping_price_amt     -- (v)¿àz(o×)
/* 2010/03/09 Ver1.16 Add  End  */
              ,xeh.edi_delivery_schedule_flag  = gt_edi_header_tab(ln_loop_cnt).edi_delivery_schedule_flag   -- EDI[i\èMÏtO
              ,xeh.last_updated_by             = cn_last_updated_by                                          -- ÅIXVÒ
              ,xeh.last_update_date            = cd_last_update_date                                         -- ÅIXVú
              ,xeh.last_update_login           = cn_last_update_login                                        -- ÅIXVÛ¸Þ²Ý
              ,xeh.request_id                  = cn_request_id                                               -- vID
              ,xeh.program_application_id      = cn_program_application_id                                   -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
              ,xeh.program_id                  = cn_program_id                                               -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
              ,xeh.program_update_date         = cd_program_update_date                                      -- ÌßÛ¸Þ×ÑXVú
        WHERE  xeh.edi_header_info_id          = gt_edi_header_tab(ln_loop_cnt).edi_header_info_id           -- EDIwb_îñID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- AvP[V
                             ,iv_name         => cv_msg_tkn_tbl2  -- EDIwb_îñe[u
                           );
          -- bZ[Wæ¾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- AvP[V
                         ,iv_name         => cv_msg_data_upd_err  -- f[^XVG[bZ[W
                         ,iv_token_name1  => cv_tkn_table_name    -- g[NR[hP
                         ,iv_token_value1 => lv_tkn_value1        -- EDIwb_îñe[u
                         ,iv_token_name2  => cv_tkn_key_data      -- g[NR[hQ
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_header_loop;
--
    --==============================================================
    -- EDI¾×îñXV
    --==============================================================
    <<update_line_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_line_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_lines  xel
        SET    xel.stockout_class          = gt_edi_line_tab(ln_loop_cnt).stockout_class       -- iæª
              ,xel.stockout_reason         = gt_edi_line_tab(ln_loop_cnt).stockout_reason      -- iR
              ,xel.product_code_itouen     = gt_edi_line_tab(ln_loop_cnt).product_code_itouen  -- ¤iR[h(É¡)
              ,xel.jan_code                = gt_edi_line_tab(ln_loop_cnt).jan_code             -- JANR[h
              ,xel.itf_code                = gt_edi_line_tab(ln_loop_cnt).itf_code             -- ITFR[h
              ,xel.prod_class              = gt_edi_line_tab(ln_loop_cnt).prod_class           -- ¤iæª
              ,xel.product_name            = gt_edi_line_tab(ln_loop_cnt).product_name         -- ¤i¼(¿)
              ,xel.product_name2_alt       = gt_edi_line_tab(ln_loop_cnt).product_name2_alt    -- ¤i¼2(Ji)
              ,xel.item_standard2          = gt_edi_line_tab(ln_loop_cnt).item_standard2       -- Ki2
              ,xel.num_of_cases            = gt_edi_line_tab(ln_loop_cnt).num_of_cases         -- P[Xü
              ,xel.num_of_ball             = gt_edi_line_tab(ln_loop_cnt).num_of_ball          -- {[ü
              ,xel.indv_order_qty          = gt_edi_line_tab(ln_loop_cnt).indv_order_qty       -- ­Ê(o)
              ,xel.case_order_qty          = gt_edi_line_tab(ln_loop_cnt).case_order_qty       -- ­Ê(P[X)
              ,xel.ball_order_qty          = gt_edi_line_tab(ln_loop_cnt).ball_order_qty       -- ­Ê({[)
              ,xel.sum_order_qty           = gt_edi_line_tab(ln_loop_cnt).sum_order_qty        -- ­Ê(vAo)
              ,xel.indv_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty    -- o×Ê(o)
              ,xel.case_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).case_shipping_qty    -- o×Ê(P[X)
              ,xel.ball_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty    -- o×Ê({[)
              ,xel.pallet_shipping_qty     = gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty  -- o×Ê(pbg)
              ,xel.sum_shipping_qty        = gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty     -- o×Ê(vAo)
              ,xel.indv_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty    -- iÊ(o)
              ,xel.case_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).case_stockout_qty    -- iÊ(P[X)
              ,xel.ball_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty    -- iÊ({[)
              ,xel.sum_stockout_qty        = gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty     -- iÊ(vAo)
              ,xel.shipping_unit_price     = gt_edi_line_tab(ln_loop_cnt).shipping_unit_price  -- ´P¿(o×)
              ,xel.shipping_cost_amt       = gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt    -- ´¿àz(o×)
              ,xel.stockout_cost_amt       = gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt    -- ´¿àz(i)
              ,xel.shipping_price_amt      = gt_edi_line_tab(ln_loop_cnt).shipping_price_amt   -- ¿àz(o×)
              ,xel.stockout_price_amt      = gt_edi_line_tab(ln_loop_cnt).stockout_price_amt   -- ¿àz(i)
              ,xel.general_add_item1       = gt_edi_line_tab(ln_loop_cnt).general_add_item1    -- ÄptÁÚ1
              ,xel.general_add_item2       = gt_edi_line_tab(ln_loop_cnt).general_add_item2    -- ÄptÁÚ2
              ,xel.general_add_item3       = gt_edi_line_tab(ln_loop_cnt).general_add_item3    -- ÄptÁÚ3
-- ******* 2019/06/25 1.29 S.Kuwako ADD  START  ******* --
              ,xel.general_add_item10      = gt_edi_line_tab(ln_loop_cnt).general_add_item10   -- ÄptÁÚ10
-- ******* 2019/06/25 1.29 S.Kuwako ADD  END    ******* --
              ,xel.item_code               = gt_edi_line_tab(ln_loop_cnt).item_code            -- iÚR[h
              ,xel.last_updated_by         = cn_last_updated_by                                -- ÅIXVÒ
              ,xel.last_update_date        = cd_last_update_date                               -- ÅIXVú
              ,xel.last_update_login       = cn_last_update_login                              -- ÅIXVÛ¸Þ²Ý
              ,xel.request_id              = cn_request_id                                     -- vID
              ,xel.program_application_id  = cn_program_application_id                         -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
              ,xel.program_id              = cn_program_id                                     -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
              ,xel.program_update_date     = cd_program_update_date                            -- ÌßÛ¸Þ×ÑXVú
        WHERE  xel.edi_line_info_id        = gt_edi_line_tab(ln_loop_cnt).edi_line_info_id     -- EDI¾×îñID
        AND    xel.edi_header_info_id      = gt_edi_line_tab(ln_loop_cnt).edi_header_info_id   -- EDIwb_îñID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- g[Næ¾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- AvP[V
                             ,iv_name         => cv_msg_tkn_tbl3  -- EDIwb_îñe[u
                           );
          -- bZ[Wæ¾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- AvP[V
                         ,iv_name         => cv_msg_data_upd_err  -- f[^XVG[bZ[W
                         ,iv_token_name1  => cv_tkn_table_name    -- g[NR[hP
                         ,iv_token_value1 => lv_tkn_value1        -- EDIwb_îñe[u
                         ,iv_token_name2  => cv_tkn_key_data      -- g[NR[hQ
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_line_loop;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END update_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : generate_edi_trans
   * Description      : EDI[i\èMt@Cì¬(A-3...A-10)
   ***********************************************************************************/
  PROCEDURE generate_edi_trans(
    iv_file_name        IN  VARCHAR2,     --   1.t@C¼
    iv_make_class       IN  VARCHAR2,     --   2.ì¬æª
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI`ÇÔ
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI`ÇÔ(t@C¼p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,     --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,     --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,     --   9.næR[h
    iv_center_date      IN  VARCHAR2,     --  10.Z^[[iú
    iv_delivery_time    IN  VARCHAR2,     --  11.[i
    iv_delivery_charge  IN  VARCHAR2,     --  12.[iSÒ
    iv_carrier_means    IN  VARCHAR2,     --  13.Aèi
/* 2010/06/11 Ver1.21 Add Start */
    iv_slct_base_code   IN  VARCHAR2,     --  16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'generate_edi_trans'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
--
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    --==============================================================
    -- èüÍf[^o^(A-3)
    --==============================================================
    get_manual_order(
       iv_edi_c_code       --  3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI`ÇÔ
      ,iv_edi_f_number_s   --  5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.XÜ[iúFrom
      ,iv_shop_date_to     --  7.XÜ[iúTo
      ,iv_sale_class       --  8.èÔÁæª
      ,iv_area_code        --  9.næR[h
      ,lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- t@Cú(A-4)
    --==============================================================
    output_header(
       iv_file_name        --  1.t@C¼
      ,iv_edi_c_code       --  3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI`ÇÔ
      ,iv_edi_f_number_f   --  4.EDI`ÇÔ(t@C¼p)
/* 2009/05/12 Ver1.8 Mod End   */
/* 2010/06/11 Ver1.21 Add Start */
      , iv_slct_base_code  --  16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
      ,lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- EDIóîño(A-5)
    --==============================================================
    input_edi_order(
       iv_edi_c_code       --  3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI`ÇÔ
      ,iv_edi_f_number_s   --  5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.XÜ[iúFrom
      ,iv_shop_date_to     --  7.XÜ[iúTo
      ,iv_sale_class       --  8.èÔÁæª
      ,iv_area_code        --  9.næR[h
/* 2010/03/19 Ver1.19 Add Start */
      ,iv_delivery_charge  --  12.[iSÒ
/* 2010/03/19 Ver1.19 Add  End  */
/* 2010/06/11 Ver1.21 Add Start */
      ,iv_slct_base_code   --  16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
      ,lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
      --==============================================================
      -- f[^ÒW(A-6)
      --==============================================================
      edit_data(
         iv_make_class       --  2.ì¬æª
        ,iv_center_date      --  9.Z^[[iú
        ,iv_delivery_time    -- 10.[i
        ,iv_delivery_charge  -- 11.[iSÒ
        ,iv_carrier_means    -- 12.Aèi
        ,lv_errbuf           -- G[EbZ[W           --# Åè #
        ,lv_retcode          -- ^[ER[h             --# Åè #
        ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      -- t@CoÍ(A-8)
      --==============================================================
      output_data(
         lv_errbuf           -- G[EbZ[W           --# Åè #
        ,lv_retcode          -- ^[ER[h             --# Åè #
        ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- t@CI¹(A-9)
    --==============================================================
    output_footer(
       lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
    --==============================================================
    -- EDIóîñXV(A-10)
    --==============================================================
      update_edi_order(
         lv_errbuf           -- G[EbZ[W           --# Åè #
        ,lv_retcode          -- ^[ER[h             --# Åè #
        ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END generate_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : release_edi_trans
   * Description      : EDI[i\èMÏÝð(A-12)
   ***********************************************************************************/
  PROCEDURE release_edi_trans(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
    iv_proc_date        IN  VARCHAR2,     --  14.ú
    iv_proc_time        IN  VARCHAR2,     --  15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
    iv_cancel_bace_code IN  VARCHAR2,      -- 16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'release_edi_trans'; -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    lv_tkn_value1  VARCHAR2(50);    -- g[Næ¾p1
--
/* 2009/05/12 Ver1.8 Add Start */
    -- *** [JTABLE^ ***
    TYPE l_header_id_ttype IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE INDEX BY BINARY_INTEGER;
    lt_update_header_id    l_header_id_ttype;
/* 2009/05/12 Ver1.8 Add Start */
--
    -- *** [JEJ[\ ***
    CURSOR edi_header_lock_cur
    IS
      SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDIwb_îñ.EDIwb_îñID
      FROM   xxcos_edi_headers       xeh                                             -- EDIwb_îñ
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- üÍp[^Ìú
      AND    xeh.process_time               = iv_proc_time                           -- üÍp[^Ì
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- üÍp[^ÌEDI`F[XR[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
      AND    xeh.base_code                  = iv_cancel_bace_code                    -- üÍp[^Ìð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- MÏ
      FOR UPDATE OF
             xeh.edi_header_info_id  NOWAIT
    ;
--
    -- *** [JER[h ***
/* 2009/05/12 Ver1.8 Del Start */
--    lt_edi_header_lock  edi_header_lock_cur%ROWTYPE;
/* 2009/05/12 Ver1.8 Del End   */
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ***************************************
    -- ***        ÀÌLq             ***
    -- ***       ¤ÊÖÌÄÑoµ        ***
    -- ***************************************
--
    -- EDIwb_îñe[uðsbN
    OPEN  edi_header_lock_cur;
/* 2009/05/12 Ver1.8 Mod Start */
--    FETCH edi_header_lock_cur INTO lt_edi_header_lock;
    FETCH edi_header_lock_cur BULK COLLECT INTO lt_update_header_id;
    -- oæ¾
/* 2010/03/01 Ver1.15 Del Start */
--    gn_target_cnt := edi_header_lock_cur%ROWCOUNT;
/* 2010/03/01 Ver1.15 Del  End  */
/* 2009/05/12 Ver1.8 Mod End */
    CLOSE edi_header_lock_cur;
/* 2010/03/01 Ver1.15 Add Start */
    SELECT COUNT(1)                                                                 -- ¾×
    INTO   gn_target_cnt                                                            -- ÎÛ
    FROM   xxcos_edi_lines  xel                                                     -- EDI¾×îñe[u
    WHERE  xel.edi_header_info_id IN (
                                       SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDIwb_îñ.EDIwb_îñID
                                       FROM   xxcos_edi_headers       xeh                                             -- EDIwb_îñ
                                       WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- üÍp[^Ìú
                                       AND    xeh.process_time               = iv_proc_time                           -- üÍp[^Ì
                                       AND    xeh.edi_chain_code             = iv_edi_c_code                          -- üÍp[^ÌEDI`F[XR[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
                                       AND    xeh.base_code                  = iv_cancel_bace_code                    -- üÍp[^Ìð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
                                       AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- MÏ
                                     );                                              -- EDIwb_îñID = bNðæ¾µ½EDIwb_îñID
/* 2010/03/01 Ver1.15 Add  End  */
--
    -- EDIwb_îñe[uðXV
    BEGIN
      UPDATE xxcos_edi_headers  xeh                                                  -- EDIwb_îñ
      SET    xeh.edi_delivery_schedule_flag = cv_n                                   -- EDI[i\èMÏtO
            ,xeh.last_updated_by            = cn_last_updated_by                     -- ÅIXVÒ
            ,xeh.last_update_date           = cd_last_update_date                    -- ÅIXVú
            ,xeh.last_update_login          = cn_last_update_login                   -- ÅIXVÛ¸Þ²Ý
            ,xeh.request_id                 = cn_request_id                          -- vID
            ,xeh.program_application_id     = cn_program_application_id              -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
            ,xeh.program_id                 = cn_program_id                          -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
            ,xeh.program_update_date        = cd_program_update_date                 -- ÌßÛ¸Þ×ÑXVú
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- üÍp[^Ìú
      AND    xeh.process_time               = iv_proc_time                           -- üÍp[^Ì
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- üÍp[^ÌEDI`F[XR[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
      AND    xeh.base_code                  = iv_cancel_bace_code                    -- üÍp[^Ìð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- MÏ
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- g[Næ¾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- AvP[V
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIwb_îñe[u
                         );
        -- bZ[Wæ¾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- AvP[V
                       ,iv_name         => cv_msg_data_upd_err  -- f[^XVG[bZ[W
                       ,iv_token_name1  => cv_tkn_table_name    -- g[NR[hP
                       ,iv_token_value1 => lv_tkn_value1        -- EDIwb_îñe[u
                       ,iv_token_name2  => cv_tkn_key_data      -- g[NR[hQ
/* 2011/12/15 Ver1.26 T.Yoshimoto Mod Start E_{Ò®_02871 */
                       --,iv_token_value2 => iv_edi_c_code        -- üÍp[^ÌEDI`F[XR[h
                       ,iv_token_value2 => iv_edi_c_code || cv_comma || iv_cancel_bace_code  -- üÍp[^ÌEDI`F[XR[hyÑAð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Mod End */
                     );
        RAISE global_api_others_expt;
    END;
--
/* 2009/05/12 Ver1.8 Add Start */
    -- ³íæ¾
    gn_normal_cnt := gn_target_cnt;
/* 2009/05/12 Ver1.8 Add End */
--
  EXCEPTION
    -- *** bNG[ ***
    WHEN lock_expt THEN
      -- J[\N[Y
      IF ( edi_header_lock_cur%ISOPEN ) THEN
        CLOSE edi_header_lock_cur;
      END IF;
      -- g[Næ¾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- AvP[V
                         ,iv_name         => cv_msg_tkn_tbl2  -- EDIwb_îñe[u
                       );
      -- bZ[Wæ¾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     -- AvP[V
                     ,iv_name         => cv_msg_lock_err    -- bNG[bZ[W
                     ,iv_token_name1  => cv_tkn_table       -- g[NR[hP
                     ,iv_token_value1 => lv_tkn_value1      -- EDIwb_îñe[u
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END release_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : CvV[W
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name        IN  VARCHAR2,     --   1.t@C¼
    iv_make_class       IN  VARCHAR2,     --   2.ì¬æª
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI`ÇÔ
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI`ÇÔ(t@C¼p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,     --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,     --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,     --   9.næR[h
    iv_center_date      IN  VARCHAR2,     --  10.Z^[[iú
    iv_delivery_time    IN  VARCHAR2,     --  11.[i
    iv_delivery_charge  IN  VARCHAR2,     --  12.[iSÒ
    iv_carrier_means    IN  VARCHAR2,     --  13.Aèi
    iv_proc_date        IN  VARCHAR2,     --  14.ú
    iv_proc_time        IN  VARCHAR2,     --  15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
    iv_cancel_bace_code IN  VARCHAR2,     --  16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2010/06/11 Ver1.21 Add Start */
    iv_slct_base_code   IN  VARCHAR2,     --  17.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
    ov_errbuf           OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode          OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg           OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
  IS
--
--#####################  Åè[JèÏé¾ START   ####################
--
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(5000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
--
    -- O[oÏÌú»
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050Ìt[}ð\·           ***
    --***      ªòÆÌÄÑoµðs¤     ***
    --*********************************************
--
    -- ===============================
    -- p[^`FbN(A-1)
    -- ===============================
    check_param(
       iv_file_name        --  1.t@C¼
      ,iv_make_class       --  2.ì¬æª
      ,iv_edi_c_code       --  3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI`ÇÔ
      ,iv_edi_f_number_f   --  4.EDI`ÇÔ(t@C¼p)
      ,iv_edi_f_number_s   --  5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.XÜ[iúFrom
      ,iv_shop_date_to     --  7.XÜ[iúTo
      ,iv_sale_class       --  8.èÔÁæª
      ,iv_area_code        --  9.næR[h
      ,iv_center_date      -- 10.Z^[[iú
      ,iv_delivery_time    -- 11.[i
      ,iv_delivery_charge  -- 12.[iSÒ
      ,iv_carrier_means    -- 13.Aèi
      ,iv_proc_date        -- 14.ú
      ,iv_proc_time        -- 15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
      ,iv_cancel_bace_code -- 16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2010/06/11 Ver1.21 Add Start */
      ,iv_slct_base_code   -- 17.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
      ,lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ú(A-2)
    -- ===============================
    init(
       iv_make_class       --  2.ì¬æª
      ,lv_errbuf           -- G[EbZ[W           --# Åè #
      ,lv_retcode          -- ^[ER[h             --# Åè #
      ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- uì¬æªvªA'M'©'xì¬'Ìê
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- ===============================
      -- EDI[i\èMt@Cì¬(A-3...A-10)
      -- ===============================
      generate_edi_trans(
         iv_file_name        --  1.t@C¼
        ,iv_make_class       --  2.ì¬æª
        ,iv_edi_c_code       --  3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--        ,iv_edi_f_number     --  4.EDI`ÇÔ
        ,iv_edi_f_number_f   --  4.EDI`ÇÔ(t@C¼p)
        ,iv_edi_f_number_s   --  5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
        ,iv_shop_date_from   --  6.XÜ[iúFrom
        ,iv_shop_date_to     --  7.XÜ[iúTo
        ,iv_sale_class       --  8.èÔÁæª
        ,iv_area_code        --  9.næR[h
        ,iv_center_date      -- 10.Z^[[iú
        ,iv_delivery_time    -- 11.[i
        ,iv_delivery_charge  -- 12.[iSÒ
        ,iv_carrier_means    -- 13.Aèi
/* 2010/06/11 Ver1.21 Add Start */
        ,iv_slct_base_code   -- 16.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
        ,lv_errbuf           -- G[EbZ[W           --# Åè #
        ,lv_retcode          -- ^[ER[h             --# Åè #
        ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- t@CªOPEN³êÄ¢éêN[Y
        IF ( UTL_FILE.IS_OPEN( file => gt_f_handle )) THEN
          UTL_FILE.FCLOSE( file => gt_f_handle );
        END IF;
        RAISE global_process_expt;
      END IF;
--
    -- uì¬æªvªA'ð'Ìê
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- ===============================
      -- EDI[i\èMÏÝð(A-12)
      -- ===============================
      release_edi_trans(
         iv_edi_c_code       --  3.EDI`F[XR[h
        ,iv_proc_date        -- 13.ú
        ,iv_proc_time        -- 15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
        ,iv_cancel_bace_code -- 16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
        ,lv_errbuf           -- G[EbZ[W           --# Åè #
        ,lv_retcode          -- ^[ER[h             --# Åè #
        ,lv_errmsg           -- [U[EG[EbZ[W --# Åè #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
      -- *** CÓÅáOðLq·é ****
      -- J[\ÌN[Yð±±ÉLq·é
--
--#################################  ÅèáO START   ###################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  Åè END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : RJgÀst@Co^vV[W
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      --   G[EbZ[W  --# Åè #
    retcode             OUT VARCHAR2,      --   ^[ER[h    --# Åè #
    iv_file_name        IN  VARCHAR2,      --   1.t@C¼
    iv_make_class       IN  VARCHAR2,      --   2.ì¬æª
    iv_edi_c_code       IN  VARCHAR2,      --   3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,      --   4.EDI`ÇÔ
    iv_edi_f_number_f   IN  VARCHAR2,      --   4.EDI`ÇÔ(t@C¼p)
    iv_edi_f_number_s   IN  VARCHAR2,      --   5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,      --   6.XÜ[iúFrom
    iv_shop_date_to     IN  VARCHAR2,      --   7.XÜ[iúTo
    iv_sale_class       IN  VARCHAR2,      --   8.èÔÁæª
    iv_area_code        IN  VARCHAR2,      --   9.næR[h
    iv_center_date      IN  VARCHAR2,      --  10.Z^[[iú
    iv_delivery_time    IN  VARCHAR2,      --  11.[i
    iv_delivery_charge  IN  VARCHAR2,      --  12.[iSÒ
    iv_carrier_means    IN  VARCHAR2,      --  13.Aèi
    iv_proc_date        IN  VARCHAR2,      --  14.ú
/* 2010/06/11 Ver1.21 Mod Start */
--    iv_proc_time        IN  VARCHAR2       --  15.
/* Ver1.33 Mod Start */
--    iv_proc_time        IN  VARCHAR2,      --  15.
--/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
--    iv_cancel_bace_code IN  VARCHAR2,      --  16.ð_R[h
    iv_cancel_bace_code IN  VARCHAR2,      --  15.ð_R[h
    iv_proc_time        IN  VARCHAR2,      --  16.
/* Ver1.33 Mod End */
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
    iv_slct_base_code   IN  VARCHAR2       --  17.oÍ_R[h
/* 2010/06/11 Ver1.21 Mod End */
  )
--
--
--###########################  Åè START   ###########################
--
  IS
--
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- vO¼
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- AhIF¤ÊEIFÌæ
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- ÎÛbZ[W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- ¬÷bZ[W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- G[bZ[W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- XLbvbZ[W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- bZ[Wpg[N¼
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ³íI¹bZ[W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- xI¹bZ[W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- G[I¹S[obN
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- G[EbZ[W
    lv_retcode         VARCHAR2(1);     -- ^[ER[h
    lv_errmsg          VARCHAR2(5000);  -- [U[EG[EbZ[W
    lv_message_code    VARCHAR2(100);   -- I¹bZ[WR[h
    --
  BEGIN
--
--###########################  Åè START   #####################################################
--
    -- ÅèoÍ
    -- RJgwb_bZ[WoÍÖÌÄÑoµ
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  Åè END   #############################
--
    -- ===============================================
    -- submainÌÄÑoµiÀÛÌÍsubmainÅs¤j
    -- ===============================================
    submain(
       iv_file_name        --   1.t@C¼
      ,iv_make_class       --   2.ì¬æª
      ,iv_edi_c_code       --   3.EDI`F[XR[h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --   4.EDI`ÇÔ
      ,iv_edi_f_number_f   --   4.EDI`ÇÔ(t@C¼p)
      ,iv_edi_f_number_s   --   5.EDI`ÇÔ(oðp)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --   6.XÜ[iúFrom
      ,iv_shop_date_to     --   7.XÜ[iúTo
      ,iv_sale_class       --   8.èÔÁæª
      ,iv_area_code        --   9.næR[h
      ,iv_center_date      --  10.Z^[[iú
      ,iv_delivery_time    --  11.[i
      ,iv_delivery_charge  --  12.[iSÒ
      ,iv_carrier_means    --  13.Aèi
      ,iv_proc_date        --  14.ú
      ,iv_proc_time        --  15.
/* 2011/12/15 Ver1.26 T.Yoshimoto Add Start E_{Ò®_02871 */
      ,iv_cancel_bace_code --  16.ð_R[h
/* 2011/12/15 Ver1.26 T.Yoshimoto Add End */
/* 2010/06/11 Ver1.21 Add Start */
      ,iv_slct_base_code   --  17.oÍ_R[h
/* 2010/06/11 Ver1.21 Add End */
      ,lv_errbuf   -- G[EbZ[W           --# Åè #
      ,lv_retcode  -- ^[ER[h             --# Åè #
      ,lv_errmsg   -- [U[EG[EbZ[W --# Åè #
    );
--
    --G[oÍ
    IF (lv_retcode = cv_status_error) THEN
/* 2009/02/24 Ver1.2 Mod Start */
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --[U[EG[bZ[W
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --G[bZ[W
      );
--  END IF;
      --ós}ü
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ós}ü
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
/* 2009/02/24 Ver1.2 Mod  End  */
/* 2010/03/18 Ver1.18 Add Start */
    --ÎÛª0Å^[R[hª³íÌêAI¹Xe[^XðuxvÆ·é
    IF ( gn_target_cnt = cn_0 ) 
         AND ( lv_retcode = cv_status_normal ) THEN
      lv_retcode := cv_status_warn;
    END IF;
/* 2010/03/18 Ver1.18 Add  End  */
    --ÎÛoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --¬÷oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --G[oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --XLbvoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/02/24 Ver1.2 Add Start */
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
    --
    --I¹bZ[W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --Xe[^XZbg
    retcode := lv_retcode;
    --I¹Xe[^XªG[ÌêÍROLLBACK·é
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  Åè END   #######################################################
--
END XXCOS011A03C;
/
