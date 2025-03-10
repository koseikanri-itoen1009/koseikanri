CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A01C (body)
 * Description      : [if[^Ìæðs¤
 * MD.050           : HHT[if[^æ (MD050_COS_001_A01)
 * Version          : 1.31
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  dlv_data_receive       [if[^o(A-1)
 *  data_check             f[^Ã«`FbN(A-2)
 *  error_data_register    G[f[^o^(A-3)
 *  header_data_register   [iwb_e[uÖf[^o^(A-4)
 *  lines_data_register    [i¾×e[uÖf[^o^(A-5)
 *  work_data_delete       [Ne[uR[hí(A-6)
 *  table_lock             e[ubN(A-7)
 *  dlv_data_delete        [iwb_E¾×e[uR[hí(A-8)
 *  submain                CvV[W
 *  main                   RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.0   S.Miyakoshi      VKì¬
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]SÝXHHTæªÏXÉÎ
 *                                       [COS_004]G[XgÖÌAgf[^Ìsï­¶ÉÎ
 *  2009/02/05    1.2   S.Miyakoshi      [COS_034]iÚIDÌoÚðÏX
 *  2009/02/20    1.3   S.Miyakoshi      p[^ÌOt@CoÍÎ
 *  2009/02/26    1.4   S.Miyakoshi      ]ÆõÌðÇÎ(xxcos_rs_info_v)
 *  2009/04/03    1.5   T.Kitajima       [T1_0247]HHTG[Xgo^f[^s³Î
 *                                       [T1_0256]ÛÇêæ¾û@C³Î
 *  2009/04/06    1.6   T.Kitajima       [T1_0329]TASKo^G[Î
 *  2009/04/09    1.7   N.Maeda          [T1_0465]Úq¼ÌA_¼ÌÌ§äÇÁ
 *  2009/04/10    1.8   T.Kitajima       [T1_0248]SÝXðÏX
 *  2009/04/10    1.9   N.Maeda          [T1_0257]\[Xidæ¾e[uÏX
 *  2009/04/14    1.10  T.Kitajima       [T1_0344]¬ÑÒR[hA[iÒR[h`FbNdlÏX
 *  2009/04/20    1.11  T.Kitajima       [T1_0592]SÝXæÊíÊ`FbNí
 *  2009/05/01    1.12  T.Kitajima       [T1_0268]CHARÚÌTRIMÎ
 *  2009/05/15    1.13  N.Maeda          [T1_1007]G[f[^o^l(óNo.(HHT))ÌÏX
 *  2009/05/15    1.14  N.Maeda          [T1_0752]KâLøîño^¤ÊÖÌø(Kâú)ðC³
 *                                       [T1_1011]G[XgoÍp_¼ÌÌæ¾ðÏX
 *                                       [T1_0977]]Æõ}X^ÆÚq}X^Ìæ¾ª
 *  2009/09/01    1.15  N.Maeda          [0000929]\[XIDæ¾ðÏX[¬ÑÒË[iÒ]
 *                                                H/CÃ«`FbNÌÀsðC³
 *  2009/10/01    1.16  N.Maeda          [0001378]G[Xgo^o^wè
 *  2009/10/30    1.17  M.Sano           [0001373]QÆViewÏX[xxcos_rs_info_v Ë xxcos_rs_info2_v]
 *  2009/11/25    1.18  N.Maeda          [E_{Ò®_00053] H/CÌ®«`FbNí
 *  2009/12/01    1.19  M.Sano           [E_{Ò®_00234] ¬ÑÒA[iÒÌÃ«`FbNC³
 *  2009/12/10    1.20  M.Sano           [E_{Ò®_00108] ¤ÊÖïvúÔîñæ¾ÙíI¹ÌC³
 *  2010/01/18    1.21  M.Uehara         [E_{Ò®_01128] J[hæªÝèÌJ[hïÐ¶Ý`FbNÇÁ
 *  2010/01/27    1.22  N.Maeda          [E_{Ò®_01321] J[hïÐæ¾ÏzñÝè
 *  2010/01/27    1.23  N.Maeda          [E_{Ò®_01191] N®[h3([i[Np[W)ðÇÁ
 *  2010/02/04    1.24  Y.Kuboshima      [E_T4_00195] ïvJ_ðAR Ë INVÉC³
 *  2011/02/03    1.25  Y.Kanami         [E_{Ò®_02624] f[^Ã«`FbNÌÚqîñæ¾ÌðÇÁ
 *  2011/03/16    1.26  S.Ochiai         [E_{Ò®_06589,06590] ãæªXiâUjÌÂ
 *                                                              I[_[NoÌÇÁ
 *  2013/09/06    1.27  R.Watanabe       [E_{Ò®_10904I]ÁïÅæªÌQÆæÏX
 *  2016/03/01    1.28  S.Niki           [E_{Ò®_13480] [i`FbNXgÎ
 *  2017/04/19    1.29  N.Watanabe       [E_{Ò®_14025] HHT©çÌVXeútAgÇÁ
 *  2017/12/18    1.30  S.Yamashita      [E_{Ò®_14486] HHT©çÌKâæªAgÇÁ
 *  2019/07/26    1.31  S.Kuwako         [E_{Ò®_15472] y¸Å¦Î(HHTÇÁÎ)
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  Åè END   ##################################
--
  -- ===============================
  -- [U[è`áO
  -- ===============================
  -- bNG[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- NCbNR[hæ¾G[
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A01C';         -- pbP[W¼
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';                -- AvP[V¼
--
  -- vt@C
  -- XXCOS:[if[^æp[WúZoîú
  cv_prf_purge_date  CONSTANT VARCHAR2(50)  := 'XXCOS1_DLV_PURGE_DATE';
  -- XXCOI:ÝÉgDR[h
  cv_prf_orga_code   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';
  -- XXCOS:MAXút
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
--
  -- G[R[h
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';     -- bNG[
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';     -- ÎÛf[^³µG[
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';     -- vt@Cæ¾G[
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';     -- XXCOS:MAXút
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- QÆR[h}X^
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001';     -- f[^oG[bZ[W
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';     -- }X^`FbNG[
  cv_msg_disagree    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10003';     -- ¬ÑÒÌ®_G[
  cv_msg_belong      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10004';     -- [iÒÌ®_G[
  cv_msg_use         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10005';     -- ÚgpsÂG[
  cv_msg_status      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10006';     -- ÚqXe[^XG[
  cv_msg_base        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10008';     -- ÚqÌã_R[hG[
  cv_msg_class       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10009';     -- üÍæªEÆÔ¬ªÞ®«G[
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- [iúARïvúÔG[
  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- [iúæÎÛúÔOG[
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
  cv_msg_adjust      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10011';     -- [iEûút®«G[
  cv_msg_future      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10012';     -- [iú¢úG[
  cv_msg_scope       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10013';     -- ûúÍÍG[
  cv_msg_time        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10014';     -- Ô`®G[
  cv_msg_object      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10015';     -- iÚãÎÛæªG[
  cv_msg_item        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10017';     -- iÚXe[^XG[
  cv_msg_convert     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10018';     -- îÊ·ZG[
  cv_msg_vd          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10019';     -- VDîñK{G[
  cv_msg_colm        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10020';     -- RNosêvG[
  cv_msg_hc          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10021';     -- H/CsêvG[
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10022';     -- f[^ÇÁG[bZ[W
  cv_msg_del         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10023';     -- f[^íG[bZ[W
  cv_msg_orga        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';     -- ÝÉgDIDæ¾G[
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';     -- Æ±úæ¾G[
  cv_msg_del_h       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10026';     -- wb_í
  cv_msg_del_l       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10027';     -- ¾×í
  cv_msg_para        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10028';     -- p[^oÍbZ[W
  cv_msg_mode1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10029';     -- [iW[iæ[h
  cv_msg_mode2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10030';     -- [if[^p[W[h
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_msg_mode3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13513';     -- [i[Ne[uí[h
  cv_msg_mode3_comp  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13514';     -- [i[Ne[uímFbZ[W
  cv_msg_wh_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13515';     -- wb_[Ne[uíbZ[W
  cv_msg_wl_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13516';     -- ¾×[Ne[uíbZ[W
  cv_msg_no_del_target CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13517';    -- [Ne[uíÎÛf[^ÈµbZ[W
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_msg_head_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10031';     -- [iwb_e[u
  cv_msg_line_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10032';     -- [i¾×e[u
  cv_msg_headwk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10033';     -- [iwb_[Ne[u
  cv_msg_linewk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10034';     -- [i¾×[Ne[u
  cv_msg_err_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10035';     -- HHTG[Xg [[Ne[u
  cv_msg_lock_table  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10036';     -- [iwb_e[uyÑ[i¾×e[u
  cv_msg_lock_work   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10037';     -- wb_[Ne[uyÑ¾×[Ne[u
  cv_msg_cus_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10038';     -- Úq}X^
  cv_msg_cus_code    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10039';     -- ÚqR[h
  cv_msg_item_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10040';     -- iÚ}X^
  cv_msg_item_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';     -- iÚR[h
  cv_msg_card        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10042';     -- J[hæª
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';     -- üÍæª
  cv_msg_tax         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10044';     -- ÁïÅæª
  cv_msg_depart      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10045';     -- SÝXæÊíÊ
  cv_msg_sale        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10046';     -- ãæª
  cv_msg_h_c         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10047';     -- H/C
  cv_msg_orga_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';     -- ÝÉgDR[h
  cv_msg_purge_date  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10049';     -- [if[^æp[WúZoîú
  cv_msg_delivery    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10050';     -- [if[^
  cv_msg_return      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13501';     -- Ôif[^
  cv_msg_tar_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13502';     -- wb_ÎÛ
  cv_msg_tar_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13503';     -- ¾×ÎÛ
  cv_msg_nor_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13504';     -- wb_¬÷
  cv_msg_nor_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13505';     -- ¾×¬÷
  cv_msg_keep_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13506';     -- a¯æR[h
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13507';     -- NCbNR[hæ¾G[bZ[W
  cv_msg_cust_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13508';     -- ÚqXe[^X
  cv_msg_busi_low    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13509';     -- ÆÔi¬ªÞj
  cv_msg_item_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13510';     -- iÚXe[^X
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
  cv_msg_emp_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00051';     -- ]Æõ}X^
  cv_msg_paf_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00173';     -- ¬ÑÒR[h
  cv_msg_dlv_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00174';     -- [iÒR[h
  cv_err_msg_get_resource_id  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13511'; --\[XIDæ¾G[
--****************************** 2009/05/15 1.14 N.Maeda ADD END ********************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_msg_card_company CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13512';     -- J[hïÐ¢ÝèG[bZ[W
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  cv_msg_discnt_tax  CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00222';     -- løÅæª
  cv_err_msg_discnt_tax       CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-13518'; -- løÅæªG[
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
  -- g[N
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE';                -- e[u¼
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';               -- e[uñ¼
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';                 -- NCbNR[h^Cv
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';              -- vt@C¼
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';                -- 
  cv_tkn_para1       CONSTANT VARCHAR2(20)  := 'PARAME1';              -- p[^
  cv_tkn_para2       CONSTANT VARCHAR2(20)  := 'PARAME2';              -- àe
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';                    -- »èY
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';                    -- »èN
  cv_default         CONSTANT VARCHAR2(1)   := '0';                    -- ftHgl0
  cv_hit             CONSTANT VARCHAR2(1)   := '1';                    -- tO»è
  cv_daytime         CONSTANT VARCHAR2(1)   := '1';                    -- ÔN®[h1
  cv_night           CONSTANT VARCHAR2(1)   := '2';                    -- éÔN®[h2
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_truncate        CONSTANT VARCHAR2(1)   := '3';                    -- N®[h3([i[Np[W)
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_depart          CONSTANT VARCHAR2(1)   := '1';                    -- SÝXpHHTæª1FSÝX
  cv_general         CONSTANT VARCHAR2(1)   := NULL;                   -- SÝXpHHTæªNULLFêÊ_
--****************************** 2009/05/15 1.13 N.Maeda ADD START  *****************************--
  ct_order_no_ebs_0  CONSTANT xxcos_dlv_headers.order_no_ebs%TYPE := 0; -- óNo.(EBS) = 0
--****************************** 2009/05/15 1.13 N.Maeda ADD  END   *****************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START  *****************************--
  cv_shot_date_type  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_type       CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  lv_time_type       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  cv_spe_cha         CONSTANT VARCHAR2(1)   := ' ';
  cv_time_cha        CONSTANT VARCHAR2(1)   := ':';
--****************************** 2009/05/15 1.14 N.Maeda ADD  END   *****************************--
-- ******* 2009/10/01 N.Maeda ADD START ********* --
  cv_user_lang       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- ******* 2009/10/01 N.Maeda ADD  END  ********* --
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_card            CONSTANT VARCHAR2(1)   := '1';                    -- J[hæª1:J[h
  cv_cash            CONSTANT VARCHAR2(1)   := '0';                    -- J[hæª0:»à
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
-- Ver.1.28 ADD Start
  cv_hht_received    CONSTANT VARCHAR2(1)   := 'Y';                    -- HHTóMtOY:HHTóMf[^
-- Ver.1.28 ADD End
--
  -- NCbNR[h^Cv
  cv_qck_typ_status  CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_STATUS_MST_001_A01';   -- ÚqXe[^X
  cv_qck_typ_a01     CONSTANT VARCHAR2(30)  := 'XXCOS_001_A01_%';                 -- NCbNR[hFR[h
  cv_qck_typ_card    CONSTANT VARCHAR2(30)  := 'XXCOS1_CARD_SALE_CLASS';          -- J[hæª
  cv_qck_typ_input   CONSTANT VARCHAR2(30)  := 'XXCOS1_INPUT_CLASS';              -- üÍæª
  cv_qck_typ_gyotai  CONSTANT VARCHAR2(30)  := 'XXCOS1_GYOTAI_SHO_MST_001_A01';   -- ÆÔi¬ªÞj
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- ÁïÅæª
  cv_qck_typ_depart  CONSTANT VARCHAR2(30)  := 'XXCOS1_DEPARTMENT_SCREEN_CLASS';  -- SÝXæÊíÊ
  cv_qck_typ_item    CONSTANT VARCHAR2(30)  := 'XXCOS1_ITEM_STATUS_MST_001_A01';  -- iÚXe[^X
  cv_qck_typ_sale    CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';               -- ãæª
  cv_qck_typ_hc      CONSTANT VARCHAR2(30)  := 'XXCOS1_HC_CLASS';                 -- H/C
  cv_qck_typ_cus     CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_CLASS_MST_001_A01';    -- Úqæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  cv_qck_typ_tax_cd  CONSTANT VARCHAR2(30)  := 'XXCFO1_TAX_CODE';                -- ÁïÅR[hiy¸Å¦Îpj
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  --tH[}bg
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE`®
--
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
  -- [iwb_[Ne[uf[^i[pÏ
  TYPE g_rec_headwk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_headers.order_no_hht%TYPE,            -- óNo.iHHT)
      order_no_ebs      xxcos_dlv_headers.order_no_ebs%TYPE,            -- óNo.iEBSj
      base_code         xxcos_dlv_headers.base_code%TYPE,               -- _R[h
      perform_code      xxcos_dlv_headers.performance_by_code%TYPE,     -- ¬ÑÒR[h
      dlv_by_code       xxcos_dlv_headers.dlv_by_code%TYPE,             -- [iÒR[h
      hht_invoice_no    xxcos_dlv_headers.hht_invoice_no%TYPE,          -- HHT`[No.
      dlv_date          xxcos_dlv_headers.dlv_date%TYPE,                -- [iú
      inspect_date      xxcos_dlv_headers.inspect_date%TYPE,            -- ûú
      sales_class       xxcos_dlv_headers.sales_classification%TYPE,    -- ãªÞæª
      sales_invoice     xxcos_dlv_headers.sales_invoice%TYPE,           -- ã`[æª
      card_class        xxcos_dlv_headers.card_sale_class%TYPE,         -- J[hæª
      dlv_time          xxcos_dlv_headers.dlv_time%TYPE,                -- Ô
      change_time_100   xxcos_dlv_headers.change_out_time_100%TYPE,     -- ÂèKØêÔ100~
      change_time_10    xxcos_dlv_headers.change_out_time_10%TYPE,      -- ÂèKØêÔ10~
      cus_number        xxcos_dlv_headers.customer_number%TYPE,         -- ÚqR[h
      input_class       xxcos_dlv_headers.input_class%TYPE,             -- üÍæª
      tax_class         xxcos_dlv_headers.consumption_tax_class%TYPE,   -- ÁïÅæª
      total_amount      xxcos_dlv_headers.total_amount%TYPE,            -- vàz
      sale_discount     xxcos_dlv_headers.sale_discount_amount%TYPE,    -- ãløz
      sales_tax         xxcos_dlv_headers.sales_consumption_tax%TYPE,   -- ãÁïÅz
      tax_include       xxcos_dlv_headers.tax_include%TYPE,             -- Åàz
      keep_in_code      xxcos_dlv_headers.keep_in_code%TYPE,            -- a¯æR[h
-- 2011/03/16 Ver.1.26 S.Ochiai MOD Start
--      depart_screen     xxcos_dlv_headers.department_screen_class%TYPE  -- SÝXæÊíÊ
      depart_screen     xxcos_dlv_headers.department_screen_class%TYPE, -- SÝXæÊíÊ
-- Ver.1.28 MOD Start
--      order_number      xxcos_dlv_headers.order_number%TYPE             -- I[_[No
      order_number      xxcos_dlv_headers.order_number%TYPE,            -- I[_[No
      ttl_sales_amt     xxcos_dlv_headers.total_sales_amt%TYPE,         -- Ìàz
      cs_ttl_sales_amt  xxcos_dlv_headers.cash_total_sales_amt%TYPE,    -- »àèg[^Ìàz
      pp_ttl_sales_amt  xxcos_dlv_headers.ppcard_total_sales_amt%TYPE,  -- PPJ[hg[^Ìàz
      id_ttl_sales_amt  xxcos_dlv_headers.idcard_total_sales_amt%TYPE,  -- IDJ[hg[^Ìàz
-- Ver.1.28 MOD End
-- Ver.1.29 MOD Start
      hht_input_date    xxcos_dlv_headers.hht_input_date%TYPE           -- HHTüÍú
-- Ver.1.29 MOD End
-- Ver.1.30 ADD Start
     ,visit_class1      xxcos_dlv_headers_work.visit_class1%TYPE        -- Kâæª1
     ,visit_class2      xxcos_dlv_headers_work.visit_class2%TYPE        -- Kâæª2
     ,visit_class3      xxcos_dlv_headers_work.visit_class3%TYPE        -- Kâæª3
     ,visit_class4      xxcos_dlv_headers_work.visit_class4%TYPE        -- Kâæª4
     ,visit_class5      xxcos_dlv_headers_work.visit_class5%TYPE        -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
     ,discount_tax_class xxcos_dlv_headers_work.discount_tax_class%TYPE -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
-- 2011/03/16 Ver.1.26 S.Ochiai MOD End
    );
  TYPE g_tab_headwk_data IS TABLE OF g_rec_headwk_data INDEX BY PLS_INTEGER;
--
  -- [i¾×[Ne[uf[^i[pÏ
  TYPE g_rec_linewk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_lines.order_no_hht%TYPE,              -- óNo.iHHTj
      line_no_hht       xxcos_dlv_lines.line_no_hht%TYPE,               -- sNo.iHHTj
      order_no_ebs      xxcos_dlv_lines.order_no_ebs%TYPE,              -- óNo.iEBSj
      line_num_ebs      xxcos_dlv_lines.line_number_ebs%TYPE,           -- ¾×Ô(EBS)
      item_code_self    xxcos_dlv_lines.item_code_self%TYPE,            -- i¼R[hi©Ðj
      case_number       xxcos_dlv_lines.case_number%TYPE,               -- P[X
      quantity          xxcos_dlv_lines.quantity%TYPE,                  -- Ê
      sale_class        xxcos_dlv_lines.sale_class%TYPE,                -- ãæª
      wholesale_unit    xxcos_dlv_lines.wholesale_unit_ploce%TYPE,      -- µP¿
      selling_price     xxcos_dlv_lines.selling_price%TYPE,             -- P¿
      column_no         xxcos_dlv_lines.column_no%TYPE,                 -- RNo.
      h_and_c           xxcos_dlv_lines.h_and_c%TYPE,                   -- H/C
      sold_out_class    xxcos_dlv_lines.sold_out_class%TYPE,            -- Øæª
      sold_out_time     xxcos_dlv_lines.sold_out_time%TYPE,             -- ØÔ
      cash_and_card     xxcos_dlv_lines.cash_and_card%TYPE              -- »àEJ[h¹pz
    );
  TYPE g_tab_linewk_data IS TABLE OF g_rec_linewk_data INDEX BY PLS_INTEGER;
--
  -- _R[hAÚqR[hÌÃ«`FbNFoÚi[pÏ
  TYPE g_rec_select_cus IS RECORD
    (
      customer_name   hz_cust_accounts.account_name%TYPE,              -- Úq¼Ì
      customer_id     hz_cust_accounts.cust_account_id%TYPE,           -- ÚqID
      party_id        hz_cust_accounts.party_id%TYPE,                  -- p[eBID
      sale_base       xxcmm_cust_accounts.sale_base_code%TYPE,         -- ã_R[h
      past_sale_base  xxcmm_cust_accounts.past_sale_base_code%TYPE,    -- Oã_R[h
      cus_status      hz_parties.duns_number_c%TYPE,                   -- ÚqXe[^X
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--      charge_person   jtf_rs_resource_extns.source_number%TYPE,        -- ScÆõ
--****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- \[XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
      bus_low_type    xxcmm_cust_accounts.business_low_type%TYPE,      -- ÆÔi¬ªÞj
      base_name       hz_cust_accounts.account_name%TYPE,              -- _¼Ì
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE            -- SÝXpHHTæª
      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE,            -- SÝXpHHTæª
--****************************** 2010/01/18 1.21 M.Uehara MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--      base_perf       per_all_assignments_f.ass_attribute5%TYPE,       -- _R[hi¬ÑÒj
--      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- _R[hi[iÒj
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      card_company    xxcmm_cust_accounts.card_company%TYPE            -- J[hïÐ
--****************************** 2010/01/18 1.21 M.Uehara ADD END *******************************--
    );
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--  
--  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(9);
  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(15);
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  -- ¬ÑÒR[hÌÃ«`FbNFoÚi[pÏ
  TYPE g_rec_select_perf IS RECORD
    (
      base_perf       per_all_assignments_f.ass_attribute5%TYPE        -- _R[hi¬ÑÒj
    );
  TYPE g_tab_select_perf IS TABLE OF g_rec_select_perf INDEX BY VARCHAR2(30);
--
  -- [iÒR[hÌÃ«`FbNFoÚi[pÏ
  TYPE g_rec_select_dlv  IS RECORD
    (
      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- \[XID
      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- _R[hi[iÒj
    );
  TYPE g_tab_select_dlv IS TABLE OF g_rec_select_dlv INDEX BY VARCHAR2(30);
--
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  -- iÚR[hÌÃ«`FbNFoÚi[pÏ
  TYPE g_rec_select_item IS RECORD
    (
      item_id          mtl_system_items_b.inventory_item_id%TYPE,              -- iÚID
      primary_measure  mtl_system_items_b.primary_unit_of_measure%TYPE,        -- îPÊ
      in_case          ic_item_mst_b.attribute11%TYPE,                         -- P[Xü
      sale_object      ic_item_mst_b.attribute26%TYPE,                         -- ãÎÛæª
      item_status      xxcmm_system_items_b.item_status%TYPE                   -- iÚXe[^X
    );
  TYPE g_tab_select_item IS TABLE OF g_rec_select_item INDEX BY VARCHAR2(7);
--
  -- VDR}X^ÆÌ®«`FbNFoÚi[pÏ
  TYPE g_rec_select_vd IS RECORD
    (
      column_no      xxcoi_mst_vd_column.column_no%TYPE,              -- RNo.
      hot_cold       xxcoi_mst_vd_column.hot_cold%TYPE                -- H/C
    );
  TYPE g_tab_select_vd IS TABLE OF g_rec_select_vd INDEX BY VARCHAR2(18);
--
  -- [iwb_f[^o^pÏ
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_dlv_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- óNo.iHHT)
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_dlv_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- óNo.iEBSj
  TYPE g_tab_head_base_code         IS TABLE OF xxcos_dlv_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- _R[h
  TYPE g_tab_head_perform_code      IS TABLE OF xxcos_dlv_headers.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- ¬ÑÒR[h
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_dlv_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- [iÒR[h
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_dlv_headers.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT`[No.
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_dlv_headers.dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- [iú
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_dlv_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- ûú
  TYPE g_tab_head_sales_class       IS TABLE OF xxcos_dlv_headers.sales_classification%TYPE
    INDEX BY PLS_INTEGER;   -- ãªÞæª
  TYPE g_tab_head_sales_invoice     IS TABLE OF xxcos_dlv_headers.sales_invoice%TYPE
    INDEX BY PLS_INTEGER;   -- ã`[æª
  TYPE g_tab_head_card_class        IS TABLE OF xxcos_dlv_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- J[hæª
  TYPE g_tab_head_dlv_time          IS TABLE OF xxcos_dlv_headers.dlv_time%TYPE
    INDEX BY PLS_INTEGER;   -- Ô
  TYPE g_tab_head_change_time_100   IS TABLE OF xxcos_dlv_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   -- ÂèKØêÔ100~
  TYPE g_tab_head_change_time_10    IS TABLE OF xxcos_dlv_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   -- ÂèKØêÔ10~
  TYPE g_tab_head_cus_number        IS TABLE OF xxcos_dlv_headers.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- ÚqR[h
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_dlv_headers.system_class%TYPE
    INDEX BY PLS_INTEGER;   -- ÆÔæª
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_dlv_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- üÍæª
  TYPE g_tab_head_tax_class         IS TABLE OF xxcos_dlv_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- ÁïÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  TYPE g_tab_head_discnt_tax_class  IS TABLE OF xxcos_dlv_headers.discount_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_dlv_headers.total_amount%TYPE
    INDEX BY PLS_INTEGER;   -- vàz
  TYPE g_tab_head_sale_discount     IS TABLE OF xxcos_dlv_headers.sale_discount_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ãløz
  TYPE g_tab_head_sales_tax         IS TABLE OF xxcos_dlv_headers.sales_consumption_tax%TYPE
    INDEX BY PLS_INTEGER;   -- ãÁïÅz
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_dlv_headers.tax_include%TYPE
    INDEX BY PLS_INTEGER;   -- Åàz
  TYPE g_tab_head_keep_in_code      IS TABLE OF xxcos_dlv_headers.keep_in_code%TYPE
    INDEX BY PLS_INTEGER;   -- a¯æR[h
  TYPE g_tab_head_depart_screen     IS TABLE OF xxcos_dlv_headers.department_screen_class%TYPE
    INDEX BY PLS_INTEGER;   -- SÝXæÊíÊ
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
  TYPE g_tab_head_order_number      IS TABLE OF xxcos_dlv_headers.order_number%TYPE
    INDEX BY PLS_INTEGER;   -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
  TYPE g_tab_head_ttl_sales_amt     IS TABLE OF xxcos_dlv_headers.total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- Ìàz
  TYPE g_tab_head_cs_ttl_sales_amt  IS TABLE OF xxcos_dlv_headers.cash_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- »àèg[^Ìàz
  TYPE g_tab_head_pp_ttl_sales_amt  IS TABLE OF xxcos_dlv_headers.ppcard_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- PPJ[hg[^Ìàz
  TYPE g_tab_head_id_ttl_sales_amt  IS TABLE OF xxcos_dlv_headers.idcard_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- IDJ[hg[^Ìàz
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
  TYPE g_tab_head_hht_input_date    IS TABLE OF xxcos_dlv_headers.hht_input_date%TYPE
    INDEX BY PLS_INTEGER;   -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
  TYPE g_tab_head_visit_class1      IS TABLE OF xxcos_dlv_headers_work.visit_class1%TYPE
    INDEX BY PLS_INTEGER;   -- Kâæª1
  TYPE g_tab_head_visit_class2      IS TABLE OF xxcos_dlv_headers_work.visit_class2%TYPE
    INDEX BY PLS_INTEGER;   -- Kâæª2
  TYPE g_tab_head_visit_class3      IS TABLE OF xxcos_dlv_headers_work.visit_class3%TYPE
    INDEX BY PLS_INTEGER;   -- Kâæª3
  TYPE g_tab_head_visit_class4      IS TABLE OF xxcos_dlv_headers_work.visit_class4%TYPE
    INDEX BY PLS_INTEGER;   -- Kâæª4
  TYPE g_tab_head_visit_class5      IS TABLE OF xxcos_dlv_headers_work.visit_class5%TYPE
    INDEX BY PLS_INTEGER;   -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  TYPE g_tab_head_discount_tax_class IS TABLE OF xxcos_dlv_headers_work.discount_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  -- [i¾×f[^o^pÏ
  TYPE g_tab_line_order_no_hht     IS TABLE OF xxcos_dlv_lines.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- óNo.iHHTj
  TYPE g_tab_line_line_no_hht      IS TABLE OF xxcos_dlv_lines.line_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- sNo.iHHTj
  TYPE g_tab_line_order_no_ebs     IS TABLE OF xxcos_dlv_lines.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- óNo.iEBSj
  TYPE g_tab_line_line_num_ebs     IS TABLE OF xxcos_dlv_lines.line_number_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- ¾×Ô(EBS)
  TYPE g_tab_line_item_code_self   IS TABLE OF xxcos_dlv_lines.item_code_self%TYPE
    INDEX BY PLS_INTEGER;   -- i¼R[hi©Ðj
  TYPE g_tab_line_content          IS TABLE OF xxcos_dlv_lines.content%TYPE
    INDEX BY PLS_INTEGER;   -- ü
  TYPE g_tab_line_item_id          IS TABLE OF xxcos_dlv_lines.inventory_item_id%TYPE
    INDEX BY PLS_INTEGER;   -- iÚID
  TYPE g_tab_line_standard_unit    IS TABLE OF xxcos_dlv_lines.standard_unit%TYPE
    INDEX BY PLS_INTEGER;   -- îPÊ
  TYPE g_tab_line_case_number      IS TABLE OF xxcos_dlv_lines.case_number%TYPE
    INDEX BY PLS_INTEGER;   -- P[X
  TYPE g_tab_line_quantity         IS TABLE OF xxcos_dlv_lines.quantity%TYPE
    INDEX BY PLS_INTEGER;   -- Ê
  TYPE g_tab_line_sale_class       IS TABLE OF xxcos_dlv_lines.sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- ãæª
  TYPE g_tab_line_wholesale_unit   IS TABLE OF xxcos_dlv_lines.wholesale_unit_ploce%TYPE
    INDEX BY PLS_INTEGER;   -- µP¿
  TYPE g_tab_line_selling_price    IS TABLE OF xxcos_dlv_lines.selling_price%TYPE
    INDEX BY PLS_INTEGER;   -- P¿
  TYPE g_tab_line_column_no        IS TABLE OF xxcos_dlv_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- RNo.
  TYPE g_tab_line_h_and_c          IS TABLE OF xxcos_dlv_lines.h_and_c%TYPE
    INDEX BY PLS_INTEGER;   -- H/C
  TYPE g_tab_line_sold_out_class   IS TABLE OF xxcos_dlv_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   -- Øæª
  TYPE g_tab_line_sold_out_time    IS TABLE OF xxcos_dlv_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   -- ØÔ
  TYPE g_tab_line_replenish_num    IS TABLE OF xxcos_dlv_lines.replenish_number%TYPE
    INDEX BY PLS_INTEGER;   -- â[
  TYPE g_tab_line_cash_and_card    IS TABLE OF xxcos_dlv_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   -- »àEJ[h¹pz
--
  -- G[f[^i[pÏ
  TYPE g_tab_err_base_code           IS TABLE OF xxcos_rep_hht_err_list.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- _R[h
  TYPE g_tab_err_base_name           IS TABLE OF xxcos_rep_hht_err_list.base_name%TYPE
    INDEX BY PLS_INTEGER;   -- _¼Ì
  TYPE g_tab_err_data_name           IS TABLE OF xxcos_rep_hht_err_list.data_name%TYPE
    INDEX BY PLS_INTEGER;   -- f[^¼Ì
  TYPE g_tab_err_order_no_hht        IS TABLE OF xxcos_rep_hht_err_list.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- óNO(HHT)
  TYPE g_tab_err_entry_number        IS TABLE OF xxcos_rep_hht_err_list.entry_number%TYPE
    INDEX BY PLS_INTEGER;   -- `[NO
  TYPE g_tab_err_line_no             IS TABLE OF xxcos_rep_hht_err_list.line_no%TYPE
    INDEX BY PLS_INTEGER;   -- sNO
  TYPE g_tab_err_order_no_ebs        IS TABLE OF xxcos_rep_hht_err_list.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- óNO(EBS)
  TYPE g_tab_err_party_num           IS TABLE OF xxcos_rep_hht_err_list.party_num%TYPE
    INDEX BY PLS_INTEGER;   -- ÚqR[h
  TYPE g_tab_err_customer_name       IS TABLE OF xxcos_rep_hht_err_list.customer_name%TYPE
    INDEX BY PLS_INTEGER;   -- Úq¼
  TYPE g_tab_err_payment_dlv_date    IS TABLE OF xxcos_rep_hht_err_list.payment_dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- üà/[iú
  TYPE g_tab_err_perform_by_code     IS TABLE OF xxcos_rep_hht_err_list.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- ¬ÑÒR[h
  TYPE g_tab_err_item_code           IS TABLE OF xxcos_rep_hht_err_list.item_code%TYPE
    INDEX BY PLS_INTEGER;   -- iÚR[h
  TYPE g_tab_err_error_message       IS TABLE OF xxcos_rep_hht_err_list.error_message%TYPE
    INDEX BY PLS_INTEGER;   -- G[àe
--
  -- KâELøÀÑo^pÏ
  TYPE g_tab_resource_id             IS TABLE OF jtf_rs_resource_extns.resource_id%TYPE
    INDEX BY PLS_INTEGER;   -- \[XID
  TYPE g_tab_party_id                IS TABLE OF hz_parties.party_id%TYPE
    INDEX BY PLS_INTEGER;   -- p[eBID
  TYPE g_tab_party_name              IS TABLE OF hz_parties.party_name%TYPE
    INDEX BY PLS_INTEGER;   -- Úq¼Ì
  TYPE g_tab_cus_status              IS TABLE OF hz_parties.duns_number_c%TYPE
    INDEX BY PLS_INTEGER;   -- ÚqXe[^X
--
  -- NCbNR[hi[p
  -- ÚqXe[^Xi[pÏ
  TYPE g_tab_qck_status   IS TABLE OF  hz_parties.duns_number_c%TYPE                  INDEX BY PLS_INTEGER;
  -- J[hæªi[pÏ
  TYPE g_tab_qck_card     IS TABLE OF  xxcos_dlv_headers.card_sale_class%TYPE         INDEX BY PLS_INTEGER;
  -- üÍæªigpÂ\Úji[pÏ
  TYPE g_tab_qck_inp_able IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- üÍæªi[if[^ji[pÏ
  TYPE g_tab_qck_inp_dlv  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- üÍæªiÔif[^ji[pÏ
  TYPE g_tab_qck_inp_ret  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- üÍæªitVD[iE©®zãji[pÏ
  TYPE g_tab_qck_inp_auto IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- ÆÔi¬ªÞji[pÏ
  TYPE g_tab_qck_busi     IS TABLE OF  xxcmm_cust_accounts.business_low_type%TYPE     INDEX BY PLS_INTEGER;
  -- ÁïÅæªi[pÏ
  TYPE g_tax_class IS RECORD
    (
      tax_cl   xxcos_dlv_headers.consumption_tax_class%TYPE              -- Ï·OÌÁïÅæª
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--      dff3     xxcos_dlv_headers.consumption_tax_class%TYPE               -- Ï·ãÌÁïÅæª
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
    );
  TYPE g_tab_qck_tax      IS TABLE OF  g_tax_class   INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  -- SÝXæÊíÊi[pÏ
--  TYPE g_tab_qck_depart   IS TABLE OF  xxcos_dlv_headers.department_screen_class%TYPE INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  -- iÚXe[^Xi[pÏ
  TYPE g_tab_qck_item     IS TABLE OF  xxcmm_system_items_b.item_status%TYPE          INDEX BY PLS_INTEGER;
  -- ãæªi[pÏ
  TYPE g_tab_qck_sale     IS TABLE OF  xxcos_dlv_lines.sale_class%TYPE                INDEX BY PLS_INTEGER;
  -- H/Ci[pÏ
  TYPE g_tab_qck_hc       IS TABLE OF  xxcos_dlv_lines.h_and_c%TYPE                   INDEX BY PLS_INTEGER;
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  -- løÅæªpÏ
  TYPE g_tab_qck_discnt_tax_class
                          IS TABLE OF  xxcos_dlv_headers.discount_tax_class%TYPE      INDEX BY PLS_INTEGER;
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
  -- [iwb_e[uo^f[^
  gt_head_order_no_hht      g_tab_head_order_no_hht;        -- óNo.iHHTj
  gt_head_order_no_ebs      g_tab_head_order_no_ebs;        -- óNo.iEBSj
  gt_head_base_code         g_tab_head_base_code;           -- _R[h
  gt_head_perform_code      g_tab_head_perform_code;        -- ¬ÑÒR[h
  gt_head_dlv_by_code       g_tab_head_dlv_by_code;         -- [iÒR[h
  gt_head_hht_invoice_no    g_tab_head_hht_invoice_no;      -- HHT`[No.
  gt_head_dlv_date          g_tab_head_dlv_date;            -- [iú
  gt_head_inspect_date      g_tab_head_inspect_date;        -- ûú
  gt_head_sales_class       g_tab_head_sales_class;         -- ãªÞæª
  gt_head_sales_invoice     g_tab_head_sales_invoice;       -- ã`[æª
  gt_head_card_class        g_tab_head_card_class;          -- J[hæª
  gt_head_dlv_time          g_tab_head_dlv_time;            -- Ô
  gt_head_change_time_100   g_tab_head_change_time_100;     -- ÂèKØêÔ100~
  gt_head_change_time_10    g_tab_head_change_time_10;      -- ÂèKØêÔ10~
  gt_head_cus_number        g_tab_head_cus_number;          -- ÚqR[h
  gt_head_system_class      g_tab_head_system_class;        -- ÆÔæª
  gt_head_input_class       g_tab_head_input_class;         -- üÍæª
  gt_head_tax_class         g_tab_head_tax_class;           -- ÁïÅæª
  gt_head_total_amount      g_tab_head_total_amount;        -- vàz
  gt_head_sale_discount     g_tab_head_sale_discount;       -- ãløz
  gt_head_sales_tax         g_tab_head_sales_tax;           -- ãÁïÅz
  gt_head_tax_include       g_tab_head_tax_include;         -- Åàz
  gt_head_keep_in_code      g_tab_head_keep_in_code;        -- a¯æR[h
  gt_head_depart_screen     g_tab_head_depart_screen;       -- SÝXæÊíÊ
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
  gt_head_order_number      g_tab_head_order_number;        -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
  gt_head_ttl_sales_amt     g_tab_head_ttl_sales_amt;       -- Ìàz
  gt_head_cs_ttl_sales_amt  g_tab_head_cs_ttl_sales_amt;    -- »àèg[^Ìàz
  gt_head_pp_ttl_sales_amt  g_tab_head_pp_ttl_sales_amt;    -- PPJ[hg[^Ìàz
  gt_head_id_ttl_sales_amt  g_tab_head_id_ttl_sales_amt;    -- IDJ[hg[^Ìàz
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
  gt_head_hht_input_date    g_tab_head_hht_input_date;      -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
  gt_head_visit_class1      g_tab_head_visit_class1;        -- Kâæª1
  gt_head_visit_class2      g_tab_head_visit_class2;        -- Kâæª2
  gt_head_visit_class3      g_tab_head_visit_class3;        -- Kâæª3
  gt_head_visit_class4      g_tab_head_visit_class4;        -- Kâæª4
  gt_head_visit_class5      g_tab_head_visit_class5;        -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  gt_head_discount_tax_class g_tab_head_discount_tax_class; -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  -- [i¾×e[uo^f[^
  gt_line_order_no_hht      g_tab_line_order_no_hht;        -- óNo.iHHTj
  gt_line_line_no_hht       g_tab_line_line_no_hht;         -- sNo.iHHTj
  gt_line_order_no_ebs      g_tab_line_order_no_ebs;        -- óNo.iEBSj
  gt_line_line_num_ebs      g_tab_line_line_num_ebs;        -- ¾×Ô(EBS)
  gt_line_item_code_self    g_tab_line_item_code_self;      -- i¼R[hi©Ðj
  gt_line_content           g_tab_line_content;             -- ü
  gt_line_item_id           g_tab_line_item_id;             -- iÚID
  gt_line_standard_unit     g_tab_line_standard_unit;       -- îPÊ
  gt_line_case_number       g_tab_line_case_number;         -- P[X
  gt_line_quantity          g_tab_line_quantity;            -- Ê
  gt_line_sale_class        g_tab_line_sale_class;          -- ãæª
  gt_line_wholesale_unit    g_tab_line_wholesale_unit;      -- µP¿
  gt_line_selling_price     g_tab_line_selling_price;       -- P¿
  gt_line_column_no         g_tab_line_column_no;           -- RNo.
  gt_line_h_and_c           g_tab_line_h_and_c;             -- H/C
  gt_line_sold_out_class    g_tab_line_sold_out_class;      -- Øæª
  gt_line_sold_out_time     g_tab_line_sold_out_time;       -- ØÔ
  gt_line_replenish_num     g_tab_line_replenish_num;       -- â[
  gt_line_cash_and_card     g_tab_line_cash_and_card;       -- »àEJ[h¹pz
--
  -- HHTG[Xg [[Ne[uo^f[^
  gt_err_base_code          g_tab_err_base_code;            -- _R[h
  gt_err_base_name          g_tab_err_base_name;            -- _¼Ì
  gt_err_data_name          g_tab_err_data_name;            -- f[^¼Ì
  gt_err_order_no_hht       g_tab_err_order_no_hht;         -- óNO(HHT)
  gt_err_entry_number       g_tab_err_entry_number;         -- `[NO
  gt_err_line_no            g_tab_err_line_no;              -- sNO
  gt_err_order_no_ebs       g_tab_err_order_no_ebs;         -- óNO(EBS)
  gt_err_party_num          g_tab_err_party_num;            -- ÚqR[h
  gt_err_customer_name      g_tab_err_customer_name;        -- Úq¼
  gt_err_payment_dlv_date   g_tab_err_payment_dlv_date;     -- üà/[iú
  gt_err_perform_by_code    g_tab_err_perform_by_code;      -- ¬ÑÒR[h
  gt_err_item_code          g_tab_err_item_code;            -- iÚR[h
  gt_err_error_message      g_tab_err_error_message;        -- G[àe
--
  -- KâELøÀÑo^pÏ
  gt_resource_id            g_tab_resource_id;              -- \[XID
  gt_party_id               g_tab_party_id;                 -- p[eBID
  gt_party_name             g_tab_party_name;               -- Úq¼Ì
  gt_cus_status             g_tab_cus_status;               -- ÚqXe[^X
--
  gt_headers_work_data      g_tab_headwk_data;              -- [iwb_[Ne[uof[^
  gt_lines_work_data        g_tab_linewk_data;              -- [i¾×[Ne[uof[^
  gt_select_cus             g_tab_select_cus;               -- _R[hAÚqR[hÌÃ«`FbNFoÚ
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  gt_select_perf            g_tab_select_perf;              -- ¬ÑÒR[hÌÃ«`FbNFoÚ
  gt_select_dlv             g_tab_select_dlv;               -- [iÒR[hÌÃ«`FbNFoÚ
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  gt_select_item            g_tab_select_item;              -- iÚR[hÌÃ«`FbNFoÚ
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--  gt_select_vd              g_tab_select_vd;                -- VDR}X^ÆÌ®«`FbNFoÚ
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
  gt_qck_status             g_tab_qck_status;               -- ÚqXe[^X
  gt_qck_card               g_tab_qck_card;                 -- J[hæª
  gt_qck_inp_able           g_tab_qck_inp_able;             -- üÍæªigpÂ\Új
  gt_qck_inp_dlv            g_tab_qck_inp_dlv;              -- üÍæªi[if[^j
  gt_qck_inp_ret            g_tab_qck_inp_ret;              -- üÍæªiÔif[^j
  gt_qck_inp_auto           g_tab_qck_inp_auto;             -- üÍæªitVD[iE©®zãj
  gt_qck_busi               g_tab_qck_busi;                 -- ÆÔi¬ªÞj
  gt_qck_tax                g_tab_qck_tax;                  -- ÁïÅæª
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  gt_qck_depart             g_tab_qck_depart;               -- SÝXæÊíÊ
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  gt_qck_item               g_tab_qck_item;                 -- iÚXe[^X
  gt_qck_sale               g_tab_qck_sale;                 -- ãæª
  gt_qck_hc                 g_tab_qck_hc;                   -- H/C
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
  gt_qck_discnt_tax_class   g_tab_qck_discnt_tax_class;     -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
  gn_purge_date             NUMBER;                         -- p[Wîú
  gn_orga_id                NUMBER;                         -- ÝÉgDID
  gd_max_date               DATE;                           -- MAXút
  gd_process_date           DATE;                           -- Æ±ú
  gv_mode                   VARCHAR2(1);                    -- N®[h
  gn_tar_cnt_h              NUMBER;                         -- wb_ÎÛ
  gn_tar_cnt_l              NUMBER;                         -- ¾×ÎÛ
  gn_nor_cnt_h              NUMBER;                         -- wb_¬÷
  gn_nor_cnt_l              NUMBER;                         -- ¾×¬÷
  gn_del_cnt_h              NUMBER;                         -- wb_í
  gn_del_cnt_l              NUMBER;                         -- ¾×í
  gv_tkn1                   VARCHAR2(50);                   -- G[bZ[Wpg[NP
  gv_tkn2                   VARCHAR2(50);                   -- G[bZ[Wpg[NQ
  gv_tkn3                   VARCHAR2(50);                   -- G[bZ[Wpg[NR
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  gn_wh_del_count           NUMBER;                         -- wb_[Ní
  gn_wl_del_count           NUMBER;                         -- ¾×[Ní
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú(A-0)
   ***********************************************************************************/
  PROCEDURE init(
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
    --==============================================================
    -- up[^oÍbZ[WvðoÍ
    --==============================================================
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    IF ( gv_mode = cv_daytime ) THEN      -- Ô[h
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode1 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- bZ[WO
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
    ELSIF ( gv_mode = cv_night ) THEN   -- éÔ[h
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode2 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- bZ[WO
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- N®Ì
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode3 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- bZ[WO
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
    END IF;
--
    --ós}ü
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
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
   * Procedure Name   : dlv_data_receive
   * Description      : [if[^o(A-1)
   ***********************************************************************************/
  PROCEDURE dlv_data_receive(
    on_target_cnt     OUT NUMBER,           --   oiwb_j
    on_line_cnt       OUT NUMBER,           --   oi¾×j
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_receive'; -- vO¼
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
    lv_max_date      VARCHAR2(50);      -- MAXút
    lv_orga_code     VARCHAR2(10);      -- ÝÉgDR[h
    ld_process_date  DATE;              -- Æ±ú
--
    -- *** [JEJ[\ ***
--
    -- *** [JER[h ***
    -- [iwb_[Ne[uf[^o
    CURSOR get_headers_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT headers.order_no_hht             order_no_hht,             -- óNo.iHHT)
--             headers.order_no_ebs             order_no_ebs,             -- óNo.iEBSj
--             headers.base_code                base_code,                -- _R[h
--             headers.performance_by_code      performance_by_code,      -- ¬ÑÒR[h
--             headers.dlv_by_code              dlv_by_code,              -- [iÒR[h
--             headers.hht_invoice_no           hht_invoice_no,           -- HHT`[No.
--             headers.dlv_date                 dlv_date,                 -- [iú
--             headers.inspect_date             inspect_date,             -- ûú
--             headers.sales_classification     sales_classification,     -- ãªÞæª
--             headers.sales_invoice            sales_invoice,            -- ã`[æª
--             headers.card_sale_class          card_sale_class,          -- J[hæª
--             headers.dlv_time                 dlv_time,                 -- Ô
--             headers.change_out_time_100      change_out_time_100,      -- ÂèKØêÔ100~
--             headers.change_out_time_10       change_out_time_10,       -- ÂèKØêÔ10~
--             headers.customer_number          customer_number,          -- ÚqR[h
--             headers.input_class              input_class,              -- üÍæª
--             headers.consumption_tax_class    consumption_tax_class,    -- ÁïÅæª
--             headers.total_amount             total_amount,             -- vàz
--             headers.sale_discount_amount     sale_discount_amount,     -- ãløz
--             headers.sales_consumption_tax    sales_consumption_tax,    -- ãÁïÅz
--             headers.tax_include              tax_include,              -- Åàz
--             headers.keep_in_code             keep_in_code,             -- a¯æR[h
--             headers.department_screen_class  department_screen_class   -- SÝXæÊíÊ
--      FROM   xxcos_dlv_headers_work           headers                   -- [iwb_[Ne[u
--      ORDER BY order_no_hht
--      FOR UPDATE NOWAIT;
      SELECT headers.order_no_hht                    order_no_hht,             -- óNo.iHHT)
             headers.order_no_ebs                    order_no_ebs,             -- óNo.iEBSj
             TRIM( headers.base_code )               base_code,                -- _R[h
             TRIM( headers.performance_by_code )     performance_by_code,      -- ¬ÑÒR[h
             TRIM( headers.dlv_by_code )             dlv_by_code,              -- [iÒR[h
             TRIM( headers.hht_invoice_no )          hht_invoice_no,           -- HHT`[No.
             headers.dlv_date                        dlv_date,                 -- [iú
             headers.inspect_date                    inspect_date,             -- ûú
             TRIM( headers.sales_classification )    sales_classification,     -- ãªÞæª
             TRIM( headers.sales_invoice )           sales_invoice,            -- ã`[æª
             TRIM( headers.card_sale_class )         card_sale_class,          -- J[hæª
             TRIM( headers.dlv_time )                dlv_time,                 -- Ô
             TRIM( headers.change_out_time_100 )     change_out_time_100,      -- ÂèKØêÔ100~
             TRIM( headers.change_out_time_10 )      change_out_time_10,       -- ÂèKØêÔ10~
             TRIM( headers.customer_number )         customer_number,          -- ÚqR[h
             TRIM( headers.input_class )             input_class,              -- üÍæª
             TRIM( headers.consumption_tax_class )   consumption_tax_class,    -- ÁïÅæª
             headers.total_amount                    total_amount,             -- vàz
             headers.sale_discount_amount            sale_discount_amount,     -- ãløz
             headers.sales_consumption_tax           sales_consumption_tax,    -- ãÁïÅz
             headers.tax_include                     tax_include,              -- Åàz
             TRIM( headers.keep_in_code )            keep_in_code,             -- a¯æR[h
-- 2011/03/16 Ver.1.26 S.Ochiai MOD Start
--             TRIM( headers.department_screen_class ) department_screen_class   -- SÝXæÊíÊ
             TRIM( headers.department_screen_class ) department_screen_class,  -- SÝXæÊíÊ
-- Ver.1.28 MOD Start
--             headers.order_number                    order_number              -- I[_[No
             headers.order_number                    order_number,             -- I[_[No
             headers.total_sales_amt                 ttl_sales_amt,            -- Ìàz
             headers.cash_total_sales_amt            cs_ttl_sales_amt,         -- »àèg[^Ìàz
             headers.ppcard_total_sales_amt          pp_ttl_sales_amt,         -- PPJ[hg[^Ìàz
             headers.idcard_total_sales_amt          id_ttl_sales_amt,         -- IDJ[hg[^Ìàz
-- Ver.1.28 MOD End
-- Ver.1.29 ADD Start
             headers.hht_input_date                  hht_input_date            -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
            ,headers.visit_class1                    visit_class1              -- Kâæª1
            ,headers.visit_class2                    visit_class2              -- Kâæª2
            ,headers.visit_class3                    visit_class3              -- Kâæª3
            ,headers.visit_class4                    visit_class4              -- Kâæª4
            ,headers.visit_class5                    visit_class5              -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
            ,headers.discount_tax_class              discount_tax_class        -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
-- 2011/03/16 Ver.1.26 S.Ochiai MOD End
      FROM   xxcos_dlv_headers_work           headers                   -- [iwb_[Ne[u
      ORDER BY order_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- [i¾×[Ne[uf[^o
    CURSOR get_lines_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT lines.order_no_hht           order_no_hht,           -- óNo.iHHTj
--             lines.line_no_hht            line_no_hht,            -- sNo.iHHTj
--             lines.order_no_ebs           order_no_ebs,           -- óNo.iEBSj
--             lines.line_number_ebs        line_number_ebs,        -- ¾×Ô(EBS)
--             lines.item_code_self         item_code_self,         -- i¼R[hi©Ðj
--             lines.case_number            case_number,            -- P[X
--             lines.quantity               quantity,               -- Ê
--             lines.sale_class             sale_class,             -- ãæª
--             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- µP¿
--             lines.selling_price          selling_price,          -- P¿
--             lines.column_no              column_no,              -- RNo.
--             lines.h_and_c                h_and_c,                -- H/C
--             lines.sold_out_class         sold_out_class,         -- Øæª
--             lines.sold_out_time          sold_out_time,          -- ØÔ
--             lines.cash_and_card          cash_and_card           -- »àEJ[h¹pz
--      FROM   xxcos_dlv_lines_work         lines                   -- [i¾×[Ne[u
--      ORDER BY order_no_hht, line_no_hht
--      FOR UPDATE NOWAIT;
      SELECT lines.order_no_hht           order_no_hht,           -- óNo.iHHTj
             lines.line_no_hht            line_no_hht,            -- sNo.iHHTj
             lines.order_no_ebs           order_no_ebs,           -- óNo.iEBSj
             lines.line_number_ebs        line_number_ebs,        -- ¾×Ô(EBS)
             TRIM( lines.item_code_self ) item_code_self,         -- i¼R[hi©Ðj
             lines.case_number            case_number,            -- P[X
             lines.quantity               quantity,               -- Ê
             TRIM( lines.sale_class )     sale_class,             -- ãæª
             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- µP¿
             lines.selling_price          selling_price,          -- P¿
             TRIM( lines.column_no )      column_no,              -- RNo.
             TRIM( lines.h_and_c )        h_and_c,                -- H/C
             TRIM( lines.sold_out_class ) sold_out_class,         -- Øæª
             TRIM( lines.sold_out_time )  sold_out_time,          -- ØÔ
             lines.cash_and_card          cash_and_card           -- »àEJ[h¹pz
      FROM   xxcos_dlv_lines_work         lines                   -- [i¾×[Ne[u
      ORDER BY order_no_hht, line_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- NCbNR[hæ¾FÚqXe[^X
    CURSOR get_cus_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type = cv_qck_typ_status
      AND     look_val.lookup_code LIKE cv_qck_typ_a01
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type = cv_qck_typ_status
--      AND     look_val.lookup_code LIKE cv_qck_typ_a01
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FJ[hæª
    CURSOR get_card_sales_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_card
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_card
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FüÍæªigpÂ\Új
    CURSOR get_input_enabled_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FüÍæªi[if[^j
    CURSOR get_input_dlv_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FüÍæªiÔif[^j
    CURSOR get_input_return_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_no;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_no;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FüÍæªitVD[iE©®zãj
    CURSOR get_input_auto_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute2   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute2   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FÆÔi¬ªÞj
    CURSOR get_gyotai_sho_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_gyotai
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_gyotai
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FÁïÅæª
    CURSOR get_tax_class_cur
    IS
-- ********** 2013/09/06 1.27 R.Watanabe MOD START ******** --
--      SELECT  look_val.lookup_code  lookup_code
      SELECT  SUBSTRB(look_val.attribute1,1,1)  lookup_code
-- ********** 2013/09/06 1.27 R.Watanabe MOD END ******** --
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--              look_val.attribute3   attribute3
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_tax
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_tax
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- NCbNR[hæ¾FSÝXæÊíÊ
--    CURSOR get_depart_screen_cur
--    IS
--      SELECT  look_val.lookup_code  lookup_code
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_depart
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- NCbNR[hæ¾FiÚXe[^X
    CURSOR get_item_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_item
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_item
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾Fãæª
    CURSOR get_sale_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_sale
      AND     look_val.attribute1   = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_sale
--      AND     look_val.attribute1   = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- NCbNR[hæ¾FH/C
    CURSOR get_hc_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_hc
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_hc
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
    -- NCbNR[hæ¾FløÅæª
    CURSOR get_discnt_tax_class_cur
    IS
      SELECT  lookup_val.lookup_code lookup_code
      FROM    fnd_lookup_values     lookup_val
      WHERE   lookup_val.language = cv_user_lang
      AND     lookup_val.lookup_type  = cv_qck_typ_tax_cd
      AND     gd_process_date      >= NVL(lookup_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(lookup_val.end_date_active, gd_max_date)
      ;
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oú»
    on_target_cnt :=0;
    on_line_cnt   :=0;
--
    --==============================================================
    -- vt@CÌæ¾(XXCOI:ÝÉgDR[h)
    --==============================================================
    lv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
    -- vt@Cæ¾G[Ìê
    IF ( lv_orga_code IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- vt@CÌæ¾(XXCOS:MAXút)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- vt@Cæ¾G[Ìê
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==============================================================
    -- ¤ÊÖÝÉgDIDæ¾ÌÄÑoµ
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( lv_orga_code );
--
    -- ÝÉgDIDæ¾G[Ìê
    IF ( gn_orga_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ¤ÊÖÆ±úæ¾ÌÄÑoµ
    --==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- Æ±úæ¾G[Ìê
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- NCbNR[hÌæ¾
    --==============================================================
    -- NCbNR[hæ¾FÚqXe[^X
    BEGIN
      -- J[\OPEN
      OPEN  get_cus_status_cur;
      -- oNtFb`
      FETCH get_cus_status_cur BULK COLLECT INTO gt_qck_status;
      -- J[\CLOSE
      CLOSE get_cus_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FÚqXe[^X
        IF ( get_cus_status_cur%ISOPEN ) THEN
          CLOSE get_cus_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_status );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cust_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FJ[hæª
    BEGIN
      -- J[\OPEN
      OPEN  get_card_sales_cur;
      -- oNtFb`
      FETCH get_card_sales_cur BULK COLLECT INTO gt_qck_card;
      -- J[\CLOSE
      CLOSE get_card_sales_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FJ[hæª
        IF ( get_card_sales_cur%ISOPEN ) THEN
          CLOSE get_card_sales_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_card );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FüÍæªigpÂ\Új
    BEGIN
      -- J[\OPEN
      OPEN  get_input_enabled_cur;
      -- oNtFb`
      FETCH get_input_enabled_cur BULK COLLECT INTO gt_qck_inp_able;
      -- J[\CLOSE
      CLOSE get_input_enabled_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FüÍæªigpÂ\Új
        IF ( get_input_enabled_cur%ISOPEN ) THEN
          CLOSE get_input_enabled_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FüÍæªi[if[^j
    BEGIN
      -- J[\OPEN
      OPEN  get_input_dlv_cur;
      -- oNtFb`
      FETCH get_input_dlv_cur BULK COLLECT INTO gt_qck_inp_dlv;
      -- J[\CLOSE
      CLOSE get_input_dlv_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FüÍæªi[if[^j
        IF ( get_input_dlv_cur%ISOPEN ) THEN
          CLOSE get_input_dlv_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FüÍæªiÔif[^j
    BEGIN
      -- J[\OPEN
      OPEN  get_input_return_cur;
      -- oNtFb`
      FETCH get_input_return_cur BULK COLLECT INTO gt_qck_inp_ret;
      -- J[\CLOSE
      CLOSE get_input_return_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FüÍæªiÔif[^j
        IF ( get_input_return_cur%ISOPEN ) THEN
          CLOSE get_input_return_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FüÍæªitVD[iE©®zãj
    BEGIN
      -- J[\OPEN
      OPEN  get_input_auto_cur;
      -- oNtFb`
      FETCH get_input_auto_cur BULK COLLECT INTO gt_qck_inp_auto;
      -- J[\CLOSE
      CLOSE get_input_auto_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FüÍæªitVD[iE©®zãj
        IF ( get_input_auto_cur%ISOPEN ) THEN
          CLOSE get_input_auto_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FÆÔi¬ªÞj
    BEGIN
      -- J[\OPEN
      OPEN  get_gyotai_sho_cur;
      -- oNtFb`
      FETCH get_gyotai_sho_cur BULK COLLECT INTO gt_qck_busi;
      -- J[\CLOSE
      CLOSE get_gyotai_sho_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FÆÔi¬ªÞj
        IF ( get_gyotai_sho_cur%ISOPEN ) THEN
          CLOSE get_gyotai_sho_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_gyotai );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi_low );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FÁïÅæª
    BEGIN
      -- J[\OPEN
      OPEN  get_tax_class_cur;
      -- oNtFb`
      FETCH get_tax_class_cur BULK COLLECT INTO gt_qck_tax;
      -- J[\CLOSE
      CLOSE get_tax_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FÁïÅæª
        IF ( get_tax_class_cur%ISOPEN ) THEN
          CLOSE get_tax_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_tax );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
--
        RAISE lookup_types_expt;
    END;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- NCbNR[hæ¾FSÝXæÊíÊ
--    BEGIN
--      -- J[\OPEN
--      OPEN  get_depart_screen_cur;
--      -- oNtFb`
--      FETCH get_depart_screen_cur BULK COLLECT INTO gt_qck_depart;
--      -- J[\CLOSE
--      CLOSE get_depart_screen_cur;
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- J[\CLOSEFNCbNR[hæ¾FSÝXæÊíÊ
--        IF ( get_depart_screen_cur%ISOPEN ) THEN
--          CLOSE get_depart_screen_cur;
--        END IF;
----
--        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_depart );
--        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
----
--        RAISE lookup_types_expt;
--    END;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- NCbNR[hæ¾FiÚXe[^X
    BEGIN
      -- J[\OPEN
      OPEN  get_item_status_cur;
      -- oNtFb`
      FETCH get_item_status_cur BULK COLLECT INTO gt_qck_item;
      -- J[\CLOSE
      CLOSE get_item_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FiÚXe[^X
        IF ( get_item_status_cur%ISOPEN ) THEN
          CLOSE get_item_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_item );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾Fãæª
    BEGIN
      -- J[\OPEN
      OPEN  get_sale_class_cur;
      -- oNtFb`
      FETCH get_sale_class_cur BULK COLLECT INTO gt_qck_sale;
      -- J[\CLOSE
      CLOSE get_sale_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾Fãæª
        IF ( get_sale_class_cur%ISOPEN ) THEN
          CLOSE get_sale_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_sale );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
--
        RAISE lookup_types_expt;
    END;
--
    -- NCbNR[hæ¾FH/C
    BEGIN
      -- J[\OPEN
      OPEN  get_hc_class_cur;
      -- oNtFb`
      FETCH get_hc_class_cur BULK COLLECT INTO gt_qck_hc;
      -- J[\CLOSE
      CLOSE get_hc_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FH/C
        IF ( get_hc_class_cur%ISOPEN ) THEN
          CLOSE get_hc_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_hc );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
--
        RAISE lookup_types_expt;
    END;
--
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
    -- NCbNR[hæ¾FløÅæª
    BEGIN
      -- J[\OPEN
      OPEN  get_discnt_tax_class_cur;
      -- oNtFb`
      FETCH get_discnt_tax_class_cur BULK COLLECT INTO gt_qck_discnt_tax_class;
      -- J[\CLOSE
      CLOSE get_discnt_tax_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- J[\CLOSEFNCbNR[hæ¾FløÅæª
        IF ( get_discnt_tax_class_cur%ISOPEN ) THEN
          CLOSE get_discnt_tax_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_tax_cd );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_discnt_tax );
        RAISE lookup_types_expt;
    END;
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
    --==============================================================
    -- [iwb_[Ne[uf[^æ¾
    --==============================================================
    BEGIN
--
      -- J[\OPEN
      OPEN  get_headers_data_cur;
      -- oNtFb`
      FETCH get_headers_data_cur BULK COLLECT INTO gt_headers_work_data;
      -- oZbg
      on_target_cnt := get_headers_data_cur%ROWCOUNT;
      -- J[\CLOSE
      CLOSE get_headers_data_cur;
--
    EXCEPTION
--
      -- bNG[
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- J[\CLOSEF[iwb_[Ne[uf[^æ¾
        IF ( get_headers_data_cur%ISOPEN ) THEN
          CLOSE get_headers_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- G[if[^oG[j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- [i¾×[Ne[uf[^æ¾
    --==============================================================
    BEGIN
--
      -- J[\OPEN
      OPEN  get_lines_data_cur;
      -- oNtFb`
      FETCH get_lines_data_cur BULK COLLECT INTO gt_lines_work_data;
      -- oZbg
      on_line_cnt := get_lines_data_cur%ROWCOUNT;
      -- J[\CLOSE
      CLOSE get_lines_data_cur;
--
    EXCEPTION
--
      -- bNG[
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- J[\CLOSEF[i¾×[Ne[uf[^æ¾
        IF ( get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- G[if[^oG[j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    WHEN lookup_types_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  gv_tkn1,
                                                                                cv_tkn_type,   gv_tkn2,
                                                                                cv_tkn_colmun, gv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_receive;
--
  /***********************************************************************************
   * Procedure Name   : data_check
   * Description      : f[^Ã«`FbN(A-2)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt       IN  NUMBER,           --   i¾×j
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- vO¼
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
    cv_month     CONSTANT VARCHAR2(5) := 'MONTH';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    cv_ar_class  CONSTANT VARCHAR2(2) := '02';
    cv_inv_class CONSTANT VARCHAR2(2) := '01';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    cv_open      CONSTANT VARCHAR2(4) := 'OPEN';
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
    ct_hht_2     CONSTANT xxcmm_cust_accounts.dept_hht_div%TYPE          := '2';    -- SÝXpHHTæª
    ct_disp_0    CONSTANT xxcos_dlv_headers.department_screen_class%TYPE := '0';    -- SÝXæÊíÊ
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
--
    -- *** [J^   ***
    -- [i¾×f[^êi[pÏ
    TYPE l_rec_line_temp IS RECORD
      (
        order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE,                 -- óNo.(HHT)
        line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE,                  -- sNo.(HHT)
        order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE,                 -- óNo.(EBS)
        line_number          xxcos_dlv_lines.line_number_ebs%TYPE,              -- ¾×Ô(EBS)
        item_code            xxcos_dlv_lines.item_code_self%TYPE,               -- i¼R[h(©Ð)
        content              xxcos_dlv_lines.content%TYPE,                      -- ü
        item_id              xxcos_dlv_lines.inventory_item_id%TYPE,            -- iÚID
        standard_unit        xxcos_dlv_lines.standard_unit%TYPE,                -- îPÊ
        case_number          xxcos_dlv_lines.case_number%TYPE,                  -- P[X
        quantity             xxcos_dlv_lines.quantity%TYPE,                     -- Ê
        sale_class           xxcos_dlv_lines.sale_class%TYPE,                   -- ãæª
        wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE,         -- µP¿
        selling_price        xxcos_dlv_lines.selling_price%TYPE,                -- P¿
        column_no            xxcos_dlv_lines.column_no%TYPE,                    -- RNo.
        h_and_c              xxcos_dlv_lines.h_and_c%TYPE,                      -- H/C
        sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE,               -- Øæª
        sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE,                -- ØÔ
        replenish_num        xxcos_dlv_lines.replenish_number%TYPE,             -- â[
        cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE                 -- »àEJ[h¹pz
      );
    TYPE l_tab_line_temp IS TABLE OF l_rec_line_temp INDEX BY PLS_INTEGER;
--
    -- *** [JÏ ***
    lt_line_temp   l_tab_line_temp;       -- [i¾×f[^êi[p
--
    -- [iwb_f[^Ï
    lt_order_noh_hht        xxcos_dlv_headers.order_no_hht%TYPE;               -- óNo.(HHT)
    lt_order_noh_ebs        xxcos_dlv_headers.order_no_ebs%TYPE;               -- óNo.(EBS)
    lt_base_code            xxcos_dlv_headers.base_code%TYPE;                  -- _R[h
    lt_performance_code     xxcos_dlv_headers.performance_by_code%TYPE;        -- ¬ÑÒR[h
    lt_dlv_code             xxcos_dlv_headers.dlv_by_code%TYPE;                -- [iÒR[h
    lt_hht_invoice_no       xxcos_dlv_headers.hht_invoice_no%TYPE;             -- HHT`[No.
    lt_dlv_date             xxcos_dlv_headers.dlv_date%TYPE;                   -- [iú
    lt_inspect_date         xxcos_dlv_headers.inspect_date%TYPE;               -- ûú
    lt_sales_class          xxcos_dlv_headers.sales_classification%TYPE;       -- ãªÞæª
    lt_sales_invoice        xxcos_dlv_headers.sales_invoice%TYPE;              -- ã`[æª
    lt_card_sale_class      xxcos_dlv_headers.card_sale_class%TYPE;            -- J[hæª
    lt_dlv_time             xxcos_dlv_headers.dlv_time%TYPE;                   -- Ô
    lt_change_out_100       xxcos_dlv_headers.change_out_time_100%TYPE;        -- ÂèKØêÔ100~
    lt_change_out_10        xxcos_dlv_headers.change_out_time_10%TYPE;         -- ÂèKØêÔ10~
    lt_customer_number      xxcos_dlv_headers.customer_number%TYPE;            -- ÚqR[h
    lt_system_class         xxcos_dlv_headers.system_class%TYPE;               -- ÆÔæª
    lt_input_class          xxcos_dlv_headers.input_class%TYPE;                -- üÍæª
    lt_tax_class            xxcos_dlv_headers.consumption_tax_class%TYPE;      -- ÁïÅæª
    lt_total_amount         xxcos_dlv_headers.total_amount%TYPE;               -- vàz
    lt_sale_discount        xxcos_dlv_headers.sale_discount_amount%TYPE;       -- ãløz
    lt_sales_tax            xxcos_dlv_headers.sales_consumption_tax%TYPE;      -- ãÁïÅz
    lt_tax_include          xxcos_dlv_headers.tax_include%TYPE;                -- Åàz
    lt_keep_in_code         xxcos_dlv_headers.keep_in_code%TYPE;               -- a¯æR[h
    lt_department_class     xxcos_dlv_headers.department_screen_class%TYPE;    -- SÝXæÊíÊ
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
    lt_order_number         xxcos_dlv_headers.order_number%TYPE;               -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
    lt_ttl_sales_amt        xxcos_dlv_headers.total_sales_amt%TYPE;          -- Ìàz
    lt_cs_ttl_sales_amt     xxcos_dlv_headers.cash_total_sales_amt%TYPE;     -- »àèg[^Ìàz
    lt_pp_ttl_sales_amt     xxcos_dlv_headers.ppcard_total_sales_amt%TYPE;   -- PPJ[hg[^Ìàz
    lt_id_ttl_sales_amt     xxcos_dlv_headers.idcard_total_sales_amt%TYPE;   -- IDJ[hg[^Ìàz
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
    lt_hht_input_date       xxcos_dlv_headers.hht_input_date%TYPE;           -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
    lt_visit_class1         xxcos_dlv_headers_work.visit_class1%TYPE;        -- Kâæª1
    lt_visit_class2         xxcos_dlv_headers_work.visit_class2%TYPE;        -- Kâæª2
    lt_visit_class3         xxcos_dlv_headers_work.visit_class3%TYPE;        -- Kâæª3
    lt_visit_class4         xxcos_dlv_headers_work.visit_class4%TYPE;        -- Kâæª4
    lt_visit_class5         xxcos_dlv_headers_work.visit_class5%TYPE;        -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
    lt_discnt_tax_class     xxcos_dlv_headers.DISCOUNT_TAX_CLASS%TYPE;       -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
    -- [i¾×f[^Ï
    lt_order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE;                 -- óNo.(HHT)
    lt_line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE;                  -- sNo.(HHT)
    lt_order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE;                 -- óNo.(EBS)
    lt_line_number          xxcos_dlv_lines.line_number_ebs%TYPE;              -- ¾×Ô(EBS)
    lt_item_code            xxcos_dlv_lines.item_code_self%TYPE;               -- i¼R[h(©Ð)
    lt_content              xxcos_dlv_lines.content%TYPE;                      -- ü
    lt_item_id              xxcos_dlv_lines.inventory_item_id%TYPE;            -- iÚID
    lt_standard_unit        xxcos_dlv_lines.standard_unit%TYPE;                -- îPÊ
    lt_case_number          xxcos_dlv_lines.case_number%TYPE;                  -- P[X
    lt_quantity             xxcos_dlv_lines.quantity%TYPE;                     -- Ê
    lt_sale_class           xxcos_dlv_lines.sale_class%TYPE;                   -- ãæª
    lt_wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE;         -- µP¿
    lt_selling_price        xxcos_dlv_lines.selling_price%TYPE;                -- P¿
    lt_column_no            xxcos_dlv_lines.column_no%TYPE;                    -- RNo.
    lt_h_and_c              xxcos_dlv_lines.h_and_c%TYPE;                      -- H/C
    lt_sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE;               -- Øæª
    lt_sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE;                -- ØÔ
    lt_replenish_num        xxcos_dlv_lines.replenish_number%TYPE;             -- â[
    lt_cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE;                -- »àEJ[h¹pz
--
    -- G[f[^Ï
    lt_base_name            xxcos_rep_hht_err_list.base_name%TYPE;             -- _¼Ì
    lt_data_name            xxcos_rep_hht_err_list.data_name%TYPE;             -- f[^¼Ì
    lt_customer_name        xxcos_rep_hht_err_list.customer_name%TYPE;         -- Úq¼
--
    lt_customer_id          hz_cust_accounts.cust_account_id%TYPE;             -- ÚqID
    lt_party_id             hz_parties.party_id%TYPE;                          -- p[eBID
    lt_sale_base            xxcmm_cust_accounts.sale_base_code%TYPE;           -- ã_R[h
    lt_past_sale_base       xxcmm_cust_accounts.past_sale_base_code%TYPE;      -- Oã_R[h
    lt_cus_status           hz_parties.duns_number_c%TYPE;                     -- ÚqXe[^X
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--    lt_charge_person        jtf_rs_resource_extns.source_number%TYPE;          -- ScÆõ
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
    lt_bus_low_type         xxcmm_cust_accounts.business_low_type%TYPE;        -- ÆÔi¬ªÞj
    lt_hht_class            xxcmm_cust_accounts.dept_hht_div%TYPE;             -- SÝXpHHTæª
    lt_base_perf            per_all_assignments_f.ass_attribute5%TYPE;         -- _R[hi¬ÑÒj
    lt_base_dlv             per_all_assignments_f.ass_attribute5%TYPE;         -- _R[hi[iÒj
    lt_in_case              ic_item_mst_b.attribute11%TYPE;                    -- iÚ}X^FP[Xü
    lt_sale_object          ic_item_mst_b.attribute26%TYPE;                    -- iÚ}X^FãÎÛæª
    lt_item_status          xxcmm_system_items_b.item_status%TYPE;             -- iÚ}X^FiÚXe[^X
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
    lt_card_company         xxcmm_cust_accounts.card_company%TYPE;              -- J[hïÐ
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--    lt_vd_column            xxcoi_mst_vd_column.column_no%TYPE;                -- VDR}X^FRNo.
--    lt_vd_hc                xxcoi_mst_vd_column.hot_cold%TYPE;                 -- VDR}X^FH/C
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    lv_err_flag             VARCHAR2(1)  DEFAULT  '0';                         -- G[tO
    lv_err_flag_time        VARCHAR2(1)  DEFAULT  '0';                         -- G[tOiÔ`®»èj
    lv_bad_sale             VARCHAR2(1)  DEFAULT  '0';                         -- ãÎÛæªFãsÂ
    ln_err_no               NUMBER  DEFAULT  '1';                              -- G[zñio[
    ln_line_cnt             NUMBER  DEFAULT  '1';                              -- ¾×`FbNÏÔ
    ln_temp_no              NUMBER  DEFAULT  '1';                              -- ¾×êi[pzñio[
    ln_header_ok_no         NUMBER  DEFAULT  '1';                              -- ³ílzñio[iwb_j
    ln_line_ok_no           NUMBER  DEFAULT  '1';                              -- ³ílzñio[i¾×j
    ld_process_date         DATE;                                              -- JgÌ
-- ******* 2009/10/01 N.Maeda MOD START ********* --
    lv_return_data          xxcos_rep_hht_err_list.data_name%TYPE;             -- Ôif[^
--    lv_return_data          VARCHAR2(10);                                      -- Ôif[^
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
-- ******************** 2009/11/25 1.18 N.Maeda DEL  START  ****************** --
--    lv_column_check         VARCHAR2(18);                                      -- ÚqIDARNo.Ìµ½l
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    ln_time_char            NUMBER;                                            -- ÔÌ¶ñ`FbN
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    lv_status               VARCHAR2(5);                                       -- ARïvúÔ`FbNFXe[^XÌíÞ
--    ln_from_date            DATE;                                              -- ARïvúÔ`FbNFïviFROMj
--    ln_to_date              DATE;                                              -- ARïvúÔ`FbNFïviTOj
    lv_status               VARCHAR2(5);                                       -- INVïvúÔ`FbNFXe[^XÌíÞ
    ln_from_date            DATE;                                              -- INVïvúÔ`FbNFïviFROMj
    ln_to_date              DATE;                                              -- INVïvúÔ`FbNFïviTOj
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    lt_resource_id          jtf_rs_resource_extns.resource_id%TYPE;            -- \[XID
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
    lv_tbl_key              VARCHAR2(20);                                      -- QÆe[uÌL[l
    lv_time_fmt             CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
    lv_index_key            VARCHAR2(15);                                       -- ÚqîñõÌKEY
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
    lv_qck_idx              NUMBER;
    lv_err_flag_discnt_tax  VARCHAR2(1)  DEFAULT  '0';                         -- G[tO(løÅæª»è)
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
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
    -- [vJnFwb_
    FOR ck_no IN 1..gn_tar_cnt_h LOOP
--
      -- G[tOú»
      lv_err_flag := cv_default;
--
      -- f[^æ¾Fwb_
      lt_order_noh_hht    := gt_headers_work_data(ck_no).order_no_hht;        -- óNo.iHHT)
      lt_order_noh_ebs    := gt_headers_work_data(ck_no).order_no_ebs;        -- óNo.iEBSj
      lt_base_code        := gt_headers_work_data(ck_no).base_code;           -- _R[h
      lt_performance_code := gt_headers_work_data(ck_no).perform_code;        -- ¬ÑÒR[h
      lt_dlv_code         := gt_headers_work_data(ck_no).dlv_by_code;         -- [iÒR[h
      lt_hht_invoice_no   := gt_headers_work_data(ck_no).hht_invoice_no;      -- HHT`[No.
      lt_dlv_date         := gt_headers_work_data(ck_no).dlv_date;            -- [iú
      lt_inspect_date     := gt_headers_work_data(ck_no).inspect_date;        -- ûú
      lt_sales_class      := gt_headers_work_data(ck_no).sales_class;         -- ãªÞæª
      lt_sales_invoice    := gt_headers_work_data(ck_no).sales_invoice;       -- ã`[æª
      lt_card_sale_class  := gt_headers_work_data(ck_no).card_class;          -- J[hæª
      lt_dlv_time         := gt_headers_work_data(ck_no).dlv_time;            -- Ô
      lt_change_out_100   := gt_headers_work_data(ck_no).change_time_100;     -- ÂèKØêÔ100~
      lt_change_out_10    := gt_headers_work_data(ck_no).change_time_10;      -- ÂèKØêÔ10~
      lt_customer_number  := gt_headers_work_data(ck_no).cus_number;          -- ÚqR[h
      lt_input_class      := gt_headers_work_data(ck_no).input_class;         -- üÍæª
      lt_tax_class        := gt_headers_work_data(ck_no).tax_class;           -- ÁïÅæª
      lt_total_amount     := gt_headers_work_data(ck_no).total_amount;        -- vàz
      lt_sale_discount    := gt_headers_work_data(ck_no).sale_discount;       -- ãløz
      lt_sales_tax        := gt_headers_work_data(ck_no).sales_tax;           -- ãÁïÅz
      lt_tax_include      := gt_headers_work_data(ck_no).tax_include;         -- Åàz
      lt_keep_in_code     := gt_headers_work_data(ck_no).keep_in_code;        -- a¯æR[h
      lt_department_class := gt_headers_work_data(ck_no).depart_screen;       -- SÝXæÊíÊ
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
      lt_order_number     := gt_headers_work_data(ck_no).order_number;        -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
      lt_ttl_sales_amt    := gt_headers_work_data(ck_no).ttl_sales_amt;       -- Ìàz
      lt_cs_ttl_sales_amt := gt_headers_work_data(ck_no).cs_ttl_sales_amt;    -- »àèg[^Ìàz
      lt_pp_ttl_sales_amt := gt_headers_work_data(ck_no).pp_ttl_sales_amt;    -- PPJ[hg[^Ìàz
      lt_id_ttl_sales_amt := gt_headers_work_data(ck_no).id_ttl_sales_amt;    -- IDJ[hg[^Ìàz
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
      lt_hht_input_date   := gt_headers_work_data(ck_no).hht_input_date;      -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
      lt_visit_class1     := gt_headers_work_data(ck_no).visit_class1;        -- Kâæª1
      lt_visit_class2     := gt_headers_work_data(ck_no).visit_class2;        -- Kâæª2
      lt_visit_class3     := gt_headers_work_data(ck_no).visit_class3;        -- Kâæª3
      lt_visit_class4     := gt_headers_work_data(ck_no).visit_class4;        -- Kâæª4
      lt_visit_class5     := gt_headers_work_data(ck_no).visit_class5;        -- Kâæª5
-- Ver.1.30 ADD End
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
      lt_discnt_tax_class := gt_headers_work_data(ck_no).discount_tax_class;  -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
      -- ú» --
      lt_base_name     := NULL;     -- _¼Ì
      lt_data_name     := NULL;     -- f[^¼Ì
      lt_customer_name := NULL;     -- Úq¼
      lt_bus_low_type  := NULL;     -- ÆÔ¬ªÞ
  /*-----2009/02/03-----END-------------------------------------------------------------------------------*/
      --== f[^¼Ì»è ==--
      -- f[^¼Ìæ¾
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery );
--      lv_return_data := xxccp_common_pkg.get_msg( cv_application, cv_msg_return );
      gv_tkn1        := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery ),1,20);
      lv_return_data := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_return ),1,20);
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
      FOR i IN 1..gt_qck_inp_dlv.COUNT LOOP
        IF ( gt_qck_inp_dlv(i) = lt_input_class ) THEN
          lt_data_name := gv_tkn1;                -- f[^¼ÌZbgF[if[^
          EXIT;
        END IF;
      END LOOP;
--
      FOR i IN 1..gt_qck_inp_ret.COUNT LOOP
        IF ( gt_qck_inp_ret(i) = lt_input_class ) THEN
          lt_data_name := lv_return_data;       -- f[^¼ÌZbgFÔif[^
          EXIT;
        END IF;
      END LOOP;
--
      --==============================================================
      --_R[hAÚqR[hÌÃ«`FbNiwb_j
      --==============================================================
--
--****************************** 2009/05/15 1.14 N.Maeda DEL START ******************************--
--      BEGIN
--****************************** 2009/05/15 1.14 N.Maeda DEL  END  ******************************--
--
        --ÏÌú»
        lt_customer_name   := NULL;
        lt_customer_id     := NULL;
        lt_party_id        := NULL;
        lt_sale_base       := NULL;
        lt_past_sale_base  := NULL;
        lt_cus_status      := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--        lt_charge_person   := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
        lt_resource_id     := NULL;
        lt_bus_low_type    := NULL;
        lt_base_name       := NULL;
        lt_hht_class       := NULL;
        lt_base_perf       := NULL;
        lt_base_dlv        := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        lt_card_company    := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
        -- Úq}X^f[^`FbNpINDEX
        lv_index_key  :=  lt_customer_number||TO_CHAR(lt_dlv_date,'YYYYMM');
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
        --== Úq}X^f[^o ==--
        -- ùÉæ¾ÏÝÌlÅ é©ðmF·éB
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--      IF ( gt_select_cus.EXISTS(lt_customer_number) ) THEN
--        lt_customer_name  := SUBSTRB( gt_select_cus(lt_customer_number).customer_name, 1, 40 );   -- Úq¼Ì
--        lt_customer_id    := gt_select_cus(lt_customer_number).customer_id;     -- ÚqID
--        lt_party_id       := gt_select_cus(lt_customer_number).party_id;        -- p[eBID
--        lt_sale_base      := gt_select_cus(lt_customer_number).sale_base;       -- ã_R[h
--        lt_past_sale_base := gt_select_cus(lt_customer_number).past_sale_base;  -- Oã_R[h
--        lt_cus_status     := gt_select_cus(lt_customer_number).cus_status;      -- ÚqXe[^X
      IF ( gt_select_cus.EXISTS(lv_index_key) ) THEN
        lt_customer_name  := SUBSTRB( gt_select_cus(lv_index_key).customer_name, 1, 40 );   -- Úq¼Ì
        lt_customer_id    := gt_select_cus(lv_index_key).customer_id;     -- ÚqID
        lt_party_id       := gt_select_cus(lv_index_key).party_id;        -- p[eBID
        lt_sale_base      := gt_select_cus(lv_index_key).sale_base;       -- ã_R[h
        lt_past_sale_base := gt_select_cus(lv_index_key).past_sale_base;  -- Oã_R[h
        lt_cus_status     := gt_select_cus(lv_index_key).cus_status;      -- ÚqXe[^X
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--

--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--          lt_charge_person  := gt_select_cus(lt_customer_number).charge_person;   -- ScÆõ
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--        lt_resource_id    := gt_select_cus(lt_customer_number).resource_id;     -- \[XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_bus_low_type   := gt_select_cus(lt_customer_number).bus_low_type;    -- ÆÔi¬ªÞj
--        lt_base_name      := SUBSTRB( gt_select_cus(lt_customer_number).base_name, 1, 30 );       -- _¼Ì
--        lt_hht_class      := gt_select_cus(lt_customer_number).dept_hht_div;    -- SÝXpHHTæª
        lt_bus_low_type   := gt_select_cus(lv_index_key).bus_low_type;                  -- ÆÔi¬ªÞj
        lt_base_name      := SUBSTRB( gt_select_cus(lv_index_key).base_name, 1, 30 );   -- _¼Ì
        lt_hht_class      := gt_select_cus(lv_index_key).dept_hht_div;                  -- SÝXpHHTæª
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        lt_base_perf      := gt_select_cus(lt_customer_number).base_perf;       -- _R[hi¬ÑÒj
--        lt_base_dlv       := gt_select_cus(lt_customer_number).base_dlv;        -- _R[hi[iÒj
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_card_company   := gt_select_cus(lt_customer_number).card_company;    -- J[hïÐ
        lt_card_company   := gt_select_cus(lv_index_key).card_company;              -- J[hïÐ
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      ELSE
--****************************** 2009/05/15 1.14 N.Maeda MOD START ******************************--
--          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- Úq¼Ì
--                 cust.cust_account_id         cust_account_id,                    -- ÚqID
--                 cust.party_id                party_id,                           -- p[eBID
--                 custadd.sale_base_code       sale_base_code,                     -- ã_R[h
--                 custadd.past_sale_base_code  past_sale_base_code,                -- Oã_R[h
--                 parties.duns_number_c        customer_status,                    -- ÚqXe[^X
----****************************** 2009/04/10 1.9 N.Maeda MOD START ******************************--
----                 salesreps.employee_number    employee_number,                    -- ScÆõ
----                 salesreps.resource_id        resource_id,                        -- \[XID
--                 rivp.resource_id             resource_id,                        -- \[XID
----****************************** 2009/04/10 1.9 N.Maeda MOD END ******************************--
--                 custadd.business_low_type    business_low_type,                  -- ÆÔi¬ªÞj
--                 SUBSTRB(base.account_name,1,30)  account_name,                   -- _¼Ì
--                 baseadd.dept_hht_div         dept_hht_div,                       -- SÝXpHHTæª
--                 rivp.base_code               base_code,                          -- _R[hi¬ÑÒj
--                 rivd.base_code               base_code                           -- _R[hi[iÒj
--          INTO   lt_customer_name,
--                 lt_customer_id,
--                 lt_party_id,
--                 lt_sale_base,
--                 lt_past_sale_base,
--                 lt_cus_status,
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 lt_charge_person,
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--                 lt_resource_id,
--                 lt_bus_low_type,
--                 lt_base_name,
--                 lt_hht_class,
--                 lt_base_perf,
--                 lt_base_dlv
--          FROM   hz_cust_accounts     cust,                    -- Úq}X^
--                 hz_cust_accounts     base,                    -- _}X^
--                 hz_parties           parties,                 -- p[eB
--                 xxcmm_cust_accounts  custadd,                 -- ÚqÇÁîñ_Úq
--                 xxcmm_cust_accounts  baseadd,                 -- ÚqÇÁîñ__
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 xxcos_salesreps_v    salesreps,               -- ScÆõview
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--                 xxcos_rs_info_v      rivp,                    -- cÆõîñviewi¬ÑÒj
--                 xxcos_rs_info_v      rivd,                    -- cÆõîñviewi[iÒj
--                 (
--                   SELECT  look_val.meaning      cus
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute1   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) cust_class,   -- Úqæªi'10'(Úq) , '12'(ãl)j
--                 (
--                   SELECT  look_val.meaning      base
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute2   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) base_class    -- Úqæªi'1'(_)j
--          WHERE  cust.customer_class_code = cust_class.cus       -- Úq}X^.Úqæª = '10'(Úq) or '12'(ãl)
--            AND  base.customer_class_code = base_class.base      -- _}X^.Úqæª = '1'(_)
--            AND  cust.account_number      = lt_customer_number   -- Úq}X^.ÚqR[h=oµ½ÚqR[h
--            AND  cust.party_id            = parties.party_id     -- Úq}X^.p[eBID=p[eB.p[eBID
--            AND  cust.cust_account_id     = custadd.customer_id  -- Úq}X^.ÚqID=ÚqÇÁîñ.ÚqID
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  lt_base_code             = base.account_number  -- oµ½_R[h=_}X^.ÚqR[h
----            AND  custadd.sale_base_code   = base.account_number  -- ÚqÇÁîñ_Úq.ã_=_}X^.ÚqR[h
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  base.cust_account_id     = baseadd.customer_id  -- _}X^.ÚqID=ÚqÇÁîñ__.ÚqID
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----            AND  (
----                    salesreps.account_number = lt_customer_number  -- ScÆõview.ÚqÔ = oµ½ÚqR[h
----                  AND                                              -- [iúÌKpÍÍ
----                    lt_dlv_date >= NVL(salesreps.effective_start_date, gd_process_date)
----                  AND
----                    lt_dlv_date <= NVL(salesreps.effective_end_date, gd_max_date)
----                 )
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--            AND  (
--                    rivp.employee_number = lt_performance_code  -- cÆõîñview(¬ÑÒ).ÚqÔ = oµ½¬ÑÒ
--                  AND                                           -- [iúÌKpÍÍ
--                    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivp.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivp.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.paa_effective_end_date
--                 )
--            AND  (
--                    rivd.employee_number = lt_dlv_code          -- cÆõîñview([iÒ).ÚqÔ = oµ½[iÒ
--                  AND                                           -- [iúÌKpÍÍ
--                    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivd.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivd.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.paa_effective_end_date
--                 );
----
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- Úq¼Ì
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- ÚqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- p[eBID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ã_R[h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- Oã_R[h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- ÚqXe[^X
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----          gt_select_cus(lt_customer_number).charge_person  := lt_charge_person;   -- ScÆõ
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- \[XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- ÆÔi¬ªÞj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- _¼Ì
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- SÝXpHHTæª
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- _R[hi¬ÑÒj
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- _R[hi[iÒj
        BEGIN
          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- Úq¼Ì
                 cust.cust_account_id         cust_account_id,                    -- ÚqID
                 cust.party_id                party_id,                           -- p[eBID
                 custadd.sale_base_code       sale_base_code,                     -- ã_R[h
                 custadd.past_sale_base_code  past_sale_base_code,                -- Oã_R[h
                 parties.duns_number_c        customer_status,                    -- ÚqXe[^X
                 custadd.business_low_type    business_low_type,                  -- ÆÔi¬ªÞj
                 SUBSTRB(base.account_name,1,30)  account_name,                   -- _¼Ì
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 baseadd.dept_hht_div         dept_hht_div                        -- SÝXpHHTæª
                 baseadd.dept_hht_div         dept_hht_div,                       -- SÝXpHHTæª
                 custadd.card_company         card_company                        -- J[hïÐ
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          INTO   lt_customer_name,
                 lt_customer_id,
                 lt_party_id,
                 lt_sale_base,
                 lt_past_sale_base,
                 lt_cus_status,
                 lt_bus_low_type,
                 lt_base_name,
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 lt_hht_class
                 lt_hht_class,
                 lt_card_company
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          FROM   hz_cust_accounts     cust,                    -- Úq}X^
                 hz_cust_accounts     base,                    -- _}X^
                 hz_parties           parties,                 -- p[eB
                 xxcmm_cust_accounts  custadd,                 -- ÚqÇÁîñ_Úq
                 xxcmm_cust_accounts  baseadd,                 -- ÚqÇÁîñ__
                 (
                   SELECT  look_val.meaning      cus
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute1   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) cust_class,   -- Úqæªi'10'(Úq) , '12'(ãl)j
                 (
                   SELECT  look_val.meaning      base
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute2   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) base_class    -- Úqæªi'1'(_)j
          WHERE  cust.customer_class_code = cust_class.cus       -- Úq}X^.Úqæª = '10'(Úq) or '12'(ãl)
            AND  base.customer_class_code = base_class.base      -- _}X^.Úqæª = '1'(_)
            AND  cust.account_number      = lt_customer_number   -- Úq}X^.ÚqR[h=oµ½ÚqR[h
            AND  cust.party_id            = parties.party_id     -- Úq}X^.p[eBID=p[eB.p[eBID
            AND  cust.cust_account_id     = custadd.customer_id  -- Úq}X^.ÚqID=ÚqÇÁîñ.ÚqID
            AND  lt_base_code             = base.account_number  -- oµ½_R[h=_}X^.ÚqR[h
            AND  base.cust_account_id     = baseadd.customer_id;  -- _}X^.ÚqID=ÚqÇÁîñ__.ÚqID;
--
--        END IF;
--****************************** 2009/05/15 1.14 N.Maeda MOD  END  ******************************--
--
--
          --== ÚqXe[^X`FbN ==--
          FOR i IN 1..gt_qck_status.COUNT LOOP
            EXIT WHEN gt_qck_status(i) = lt_cus_status;
            IF ( i = gt_qck_status.COUNT ) THEN
              -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_status );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== ã_R[h`FbN ==--
          -- ã_R[hÆOã_R[hÌgp»è
          IF ( TRUNC( lt_dlv_date, cv_month ) < TRUNC( gd_process_date, cv_month ) ) THEN
            lt_sale_base := NVL( lt_past_sale_base, lt_sale_base );
          END IF;
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
        -- êÊ_Ìê
--      IF ( lt_hht_class = cv_general ) THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--        IF ( lt_hht_class IS NULL ) THEN
          IF ( lt_hht_class IS NULL ) 
            OR ( ( lt_hht_class = ct_hht_2 )
                 AND
                 (lt_department_class = ct_disp_0 )
               )
            THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
            -- ã_R[hÃ«`FbN
            IF ( ( lt_sale_base != lt_base_code ) OR ( lt_base_code IS NULL ) ) THEN
              -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                 -- _R[h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);           -- ÚqR[h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);          -- ¬ÑÒR[h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
            END IF;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- OoÍ
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
        END;
--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************-- 
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- Úq¼Ì
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- ÚqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- p[eBID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ã_R[h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- Oã_R[h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- ÚqXe[^X
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- ÆÔi¬ªÞj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- _¼Ì
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- SÝXpHHTæª
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
--          gt_select_cus(lt_customer_number).card_company   := lt_card_company;    -- J[hïÐ
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
        IF ( lv_err_flag <> cv_hit ) THEN
          gt_select_cus(lv_index_key).customer_name  := lt_customer_name;   -- Úq¼Ì
          gt_select_cus(lv_index_key).customer_id    := lt_customer_id;     -- ÚqID
          gt_select_cus(lv_index_key).party_id       := lt_party_id;        -- p[eBID
          gt_select_cus(lv_index_key).sale_base      := lt_sale_base;       -- ã_R[h
          gt_select_cus(lv_index_key).past_sale_base := lt_past_sale_base;  -- Oã_R[h
          gt_select_cus(lv_index_key).cus_status     := lt_cus_status;      -- ÚqXe[^X
          gt_select_cus(lv_index_key).bus_low_type   := lt_bus_low_type;    -- ÆÔi¬ªÞj
          gt_select_cus(lv_index_key).base_name      := lt_base_name;       -- _¼Ì
          gt_select_cus(lv_index_key).dept_hht_div   := lt_hht_class;       -- SÝXpHHTæª
          gt_select_cus(lv_index_key).card_company   := lt_card_company;    -- J[hïÐ
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
        END IF;
--
      END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2009/04/14 1.10 T.Kitajima MOD START ******************************--
--      --==============================================================
--      --¬ÑÒR[hÌÃ«`FbNiwb_j
--      --==============================================================
--      IF ( lt_base_perf != lt_sale_base ) THEN
--        -- OoÍ
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- G[ÏÖi[
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
--        ln_err_no := ln_err_no + 1;
--        -- G[tOXV
--        lv_err_flag := cv_hit;
--      END IF;
--      --==============================================================
--      --[iÒR[hÌÃ«`FbNiwb_j
--      --==============================================================
--      IF ( lt_base_dlv != lt_sale_base ) THEN
--        -- OoÍ
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- G[ÏÖi[
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
--        ln_err_no := ln_err_no + 1;
--        -- G[tOXV
--        lv_err_flag := cv_hit;
--      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- ¬ÑÒR[hoÚe[uÌL[lðæ¾(¬ÑÒR[h,[iú)
        lv_tbl_key   := lt_performance_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- _R[hi¬ÑÒjðæ¾
        lt_base_perf := NULL;
        IF ( gt_select_perf.EXISTS(lv_tbl_key) ) THEN
          lt_base_perf := gt_select_perf(lv_tbl_key).base_perf;  -- [iR[hi¬ÑÒj
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivp.base_code       base_code              -- _R[hi¬ÑÒj
          INTO   lt_base_perf
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- cÆõîñviewi¬ÑÒj
          FROM   xxcos_rs_info2_v     rivp                   -- cÆõîñviewi¬ÑÒj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivp.employee_number = lt_performance_code  -- cÆõîñview(¬ÑÒ).ÚqÔ = oµ½¬ÑÒ
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- [iúÌKpÍÍ
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- zñÉi[
          gt_select_perf(lv_tbl_key).base_perf := lt_base_perf;  -- [iR[hi¬ÑÒj
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --êÊ_ÌêÍ`FbN·éB
        IF ( lt_hht_class IS NULL ) 
          OR ( ( lt_hht_class = ct_hht_2 )
            AND (lt_department_class = ct_disp_0 )
        )
        THEN
          --==============================================================
          --¬ÑÒR[hÌÃ«`FbNiwb_j
          --==============================================================
          IF ( lt_base_perf != lt_sale_base ) THEN
            -- OoÍ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- OoÍ
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
        gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_paf_emp );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                             cv_tkn_table,   gv_tkn1,
                                             cv_tkn_colmun,  gv_tkn2 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END;
--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- ¬ÑÒR[hoÚe[uÌL[lðæ¾(¬ÑÒR[h,[iú)
        lv_tbl_key   := lt_dlv_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- _R[hi[iÒjA\[XIDðæ¾
        lt_resource_id := NULL;
        lt_base_dlv    := NULL;
        IF ( gt_select_dlv.EXISTS(lv_tbl_key) ) THEN
          lt_resource_id := gt_select_dlv(lv_tbl_key).resource_id;  -- \[XID
          lt_base_dlv    := gt_select_dlv(lv_tbl_key).base_dlv;     -- _R[hi[iÒj
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivd.base_code       base_code                           -- _R[hi[iÒj
          INTO   lt_base_dlv
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivd                    -- cÆõîñviewi[iÒj
          FROM   xxcos_rs_info2_v     rivd                   -- cÆõîñviewi[iÒj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivd.employee_number = lt_dlv_code          -- cÆõîñview([iÒ).ÚqÔ = oµ½[iÒ
          AND    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)-- [iúÌKpÍÍ
          AND    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
          AND    lt_dlv_date >= rivd.per_effective_start_date
          AND    lt_dlv_date <= rivd.per_effective_end_date
          AND    lt_dlv_date >= rivd.paa_effective_start_date
          AND    lt_dlv_date <= rivd.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- SQLÉÄæ¾µ½êAÊðzñÉi[
          gt_select_dlv(lv_tbl_key).resource_id := lt_resource_id; -- \[XID
          gt_select_dlv(lv_tbl_key).base_dlv    := lt_base_dlv;    -- _R[hi[iÒj
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --êÊ_ÌêÍ`FbN·éB
        IF ( lt_hht_class IS NULL ) 
        OR ( ( lt_hht_class = ct_hht_2 )
          AND (lt_department_class = ct_disp_0 ) ) THEN
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
          --==============================================================
          --[iÒR[hÌÃ«`FbNiwb_j
          --==============================================================
          IF ( lt_base_dlv != lt_sale_base ) THEN
            -- OoÍ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
        END IF;
--****************************** 2009/04/14 1.10 T.Kitajima MOD  END  ******************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- OoÍ
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
          gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_emp );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                 cv_tkn_table,   gv_tkn1,
                                                 cv_tkn_colmun,  gv_tkn2 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
      END;
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
      -- [iÒR[hÃ«`FbNpzñðõ
      IF (lt_resource_id IS NULL ) THEN
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        BEGIN
          SELECT rivp.resource_id     resource_id            -- \[XID
          INTO   lt_resource_id
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- cÆõîñviewi[iÒj
          FROM   xxcos_rs_info2_v      rivp                  -- cÆõîñviewi[iÒj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          WHERE  rivp.employee_number = lt_dlv_code
--          WHERE  rivp.employee_number = lt_performance_code  -- cÆõîñview(¬ÑÒ).ÚqÔ = oµ½¬ÑÒ
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- [iúÌKpÍÍ
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- æ¾ÊðzñÉi[
          gt_select_dlv(lt_dlv_code).resource_id := lt_resource_id; -- \[XID
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_err_msg_get_resource_id );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
        END;
--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- Úq¼Ì
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- ÚqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- p[eBID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ã_R[h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- Oã_R[h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- ÚqXe[^X
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- \[XID
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- ÆÔi¬ªÞj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- _¼Ì
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- SÝXpHHTæª
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- _R[hi¬ÑÒj
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- _R[hi[iÒj
--        END IF;
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--
      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
      --==============================================================
      --J[hæªÌÃ«`FbNiwb_j
      --==============================================================
      FOR i IN 1..gt_qck_card.COUNT LOOP
        EXIT WHEN gt_qck_card(i) = lt_card_sale_class;
        IF ( i = gt_qck_card.COUNT ) THEN
          -- OoÍ
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      --==============================================================
      --J[hïÐ`FbNiwb_j
      --==============================================================
      IF ( lt_card_sale_class = cv_card AND lt_card_company IS NULL ) THEN
        -- OoÍ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
      --==============================================================
      --üÍæªÌÃ«`FbNiwb_j
      --==============================================================
      IF ( lt_data_name IS NULL ) THEN
        -- OoÍ
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--
      --== üÍæªEÆÔ¬ªÞ®«`FbN ==--
      FOR i IN 1..gt_qck_inp_auto.COUNT LOOP
        IF ( gt_qck_inp_auto(i) = lt_input_class ) THEN
          FOR j IN 1..gt_qck_busi.COUNT LOOP
            EXIT WHEN gt_qck_busi(j) = lt_bus_low_type;
            IF ( j = gt_qck_busi.COUNT ) THEN
              -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_class );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
        END IF;
      END LOOP;
--
      --==============================================================
      --ÁïÅæªÌÃ«`FbNiwb_j
      --==============================================================
--
      FOR i IN 1..gt_qck_tax.COUNT LOOP
        IF ( gt_qck_tax(i).tax_cl = lt_tax_class ) THEN
          EXIT;
        END IF;
        IF ( i = gt_qck_tax.COUNT ) THEN
          -- OoÍ
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--      --== SÝXÌêAa¯æR[hÌZbgESÝXæÊíÊÌÃ«`FbNðs¢Ü·B ==--
----    IF ( lt_hht_class = cv_depart ) THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
----      IF ( lt_hht_class IS NOT NULL ) THEN
--      IF ( lt_hht_class IS NULL ) 
--        OR ( ( lt_hht_class = ct_hht_2 )
--             AND
--             (lt_department_class = ct_disp_0 )
--           )
--        THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
----
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
----        --==============================================================
----        -- a¯æR[hÉÚqR[hðZbgiwb_j
----        --==============================================================
----        lt_keep_in_code := lt_customer_number;
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
--
--       --==============================================================
--        -- SÝXæÊíÊÌÃ«`FbNiwb_j
--        --==============================================================
--        FOR i IN 1..gt_qck_depart.COUNT LOOP
--          EXIT WHEN gt_qck_depart(i) = lt_department_class;
--          IF ( i = gt_qck_depart.COUNT ) THEN
--            -- OoÍ
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
--            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
--            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--            ov_retcode := cv_status_warn;
--            -- G[ÏÖi[
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
--            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
--            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
--            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--            gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
--            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
--            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
--            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--            gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
--            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
--            ln_err_no := ln_err_no + 1;
--            -- G[tOXV
--            lv_err_flag := cv_hit;
--          END IF;
--        END LOOP;
--
--      END IF;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
      --==============================================================
      --[iúÌÃ«`FbNiwb_j
      --==============================================================
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      --== ARïvúÔ`FbN ==--
      --== INVïvúÔ`FbN ==--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
      -- ¤ÊÖïvúÔîñæ¾
      xxcos_common_pkg.get_account_period(
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--        cv_ar_class         -- 02:AR
        cv_inv_class        -- 01:INV
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
       ,lt_dlv_date         -- [iú
       ,lv_status           -- Xe[^X(OPEN or CLOSE)
       ,ln_from_date        -- ïviFROMj
       ,ln_to_date          -- ïviTOj
       ,lv_errbuf           -- G[EbZ[W
       ,lv_retcode          -- ^[ER[h
       ,lv_errmsg           -- [U[EG[EbZ[W
        );
--****************************** 2009/12/10 1.20 M.Sano MOD START *******************************--
----
--      --G[`FbN
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      END IF;
--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      -- ARïvúÔÍÍOÌê
      -- INVïvúÔÍÍOÌê
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
--      IF ( lv_status != cv_open ) THEN
      IF ( lv_status != cv_open OR lv_retcode = cv_status_error ) THEN
--****************************** 2009/12/10 1.20 M.Sano MOD  END  *******************************--
        -- OoÍ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_period );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--
      --== [iEûút®«`FbN ==--
      IF ( lt_dlv_date > lt_inspect_date ) THEN
        -- OoÍ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_adjust );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--
      --== ¢ú`FbN ==--
      IF ( lt_dlv_date > gd_process_date ) THEN
        -- OoÍ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_future );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --ûúÌÃ«`FbNiwb_j
      --==============================================================
      ld_process_date := LAST_DAY( ADD_MONTHS( gd_process_date, 1 ) );
      IF ( lt_inspect_date > ld_process_date ) THEN
        -- OoÍ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_scope );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --ÔÌÃ«`FbNiwb_j
      --==============================================================
      BEGIN
        -- G[tOiÔ`®»èjú»
        lv_err_flag_time := cv_default;
--
        -- ¶ñªÜÜêÄ¢é©
        ln_time_char := TO_NUMBER( lt_dlv_time );
--
        IF ( LENGTHB( lt_dlv_time ) = 4 ) THEN
          IF ( ( substr( lt_dlv_time, 1, 2 ) < 0 ) or ( 24 < substr( lt_dlv_time, 1, 2 ) ) ) THEN
            -- G[tOiÔ`®»èjXV
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( ( substr( lt_dlv_time, 3 ) < 0 ) or ( 59 < substr( lt_dlv_time, 3 ) ) ) THEN
            -- G[tOiÔ`®»èjXV
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( lv_err_flag_time = cv_hit ) THEN
            -- OoÍ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
--
        ELSE
          -- OoÍ
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- OoÍ
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
      END;
--
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
      --==============================================================
      --uløÅæªvÌÃ«`FbNiwb_j
      --==============================================================
      --G[tOú»
      lv_err_flag_discnt_tax := cv_default;
--
      --Løl`FbN
      FOR lv_qck_idx IN 1..gt_qck_discnt_tax_class.COUNT LOOP
        IF ( lt_discnt_tax_class = gt_qck_discnt_tax_class(lv_qck_idx) ) 
        OR ( lt_discnt_tax_class IS NULL )                               THEN
          lv_err_flag_discnt_tax := cv_default;
          EXIT;
        ELSE
          lv_err_flag_discnt_tax := cv_hit;
        END IF;
      END LOOP;
--
      IF ( lv_err_flag_discnt_tax = cv_hit ) THEN
        -- OoÍ
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_discnt_tax );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- G[ÏÖÌi[
        gt_err_base_name(ln_err_no)        := lt_base_name;                     -- _¼Ì
        gt_err_data_name(ln_err_no)        := lt_data_name;                     -- f[^¼Ì
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;                 -- óNO(HHT)
        gt_err_line_no(ln_err_no)          := NULL;                             -- sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;                 -- óNO(EBS)
        gt_err_customer_name(ln_err_no)    := lt_customer_name;                 -- Úq¼
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                      -- üà/[iú
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);        -- _R[h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);  -- `[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);  -- ÚqR[h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5); -- ¬ÑÒR[h
        gt_err_item_code(ln_err_no)        := NULL;                             -- iÚR[h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );      -- G[àe
        ln_err_no := ln_err_no + 1;
        -- G[tOXV
        lv_err_flag := cv_hit;
--
      ELSIF ( lv_err_flag_discnt_tax = cv_default ) THEN
        --ãløzÆÌ®«`FbN
        IF ( lt_sale_discount = 0 ) 
        OR ( lt_sale_discount IS NULL ) THEN
          lv_err_flag_discnt_tax := cv_default;
        ELSIF ( lt_sale_discount > 0 ) AND ( lt_discnt_tax_class IS NOT NULL ) THEN
          lv_err_flag_discnt_tax := cv_default;
        ELSE
          -- OoÍ
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_err_msg_discnt_tax );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- G[ÏÖÌi[
          gt_err_base_name(ln_err_no)        := lt_base_name;                     -- _¼Ì
          gt_err_data_name(ln_err_no)        := lt_data_name;                     -- f[^¼Ì
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;                 -- óNO(HHT)
          gt_err_line_no(ln_err_no)          := NULL;                             -- sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;                 -- óNO(EBS)
          gt_err_customer_name(ln_err_no)    := lt_customer_name;                 -- Úq¼
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                      -- üà/[iú
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);        -- _R[h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);  -- `[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);  -- ÚqR[h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5); -- ¬ÑÒR[h
          gt_err_item_code(ln_err_no)        := NULL;                             -- iÚR[h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );      -- G[àe
          ln_err_no := ln_err_no + 1;
          -- G[tOXV
          lv_err_flag := cv_hit;
        END IF;
      END IF;
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
--
      -- [vJnF¾×
      FOR line_no IN ln_line_cnt..in_line_cnt LOOP
--
        -- f[^æ¾F¾×
        lt_order_nol_hht   := gt_lines_work_data(line_no).order_no_hht;          -- óNo.iHHTj
        lt_line_no_hht     := gt_lines_work_data(line_no).line_no_hht;           -- sNo.iHHTj
        lt_order_nol_ebs   := gt_lines_work_data(line_no).order_no_ebs;          -- óNo.iEBSj
        lt_line_number     := gt_lines_work_data(line_no).line_num_ebs;          -- ¾×Ô(EBS)
        lt_item_code       := gt_lines_work_data(line_no).item_code_self;        -- i¼R[hi©Ðj
        lt_case_number     := gt_lines_work_data(line_no).case_number;           -- P[X
        lt_quantity        := gt_lines_work_data(line_no).quantity;              -- Ê
        lt_sale_class      := gt_lines_work_data(line_no).sale_class;            -- ãæª
        lt_wholesale_price := gt_lines_work_data(line_no).wholesale_unit;        -- µP¿
        lt_selling_price   := gt_lines_work_data(line_no).selling_price;         -- P¿
        lt_column_no       := gt_lines_work_data(line_no).column_no;             -- RNo.
        lt_h_and_c         := gt_lines_work_data(line_no).h_and_c;               -- H/C
        lt_sold_out_class  := gt_lines_work_data(line_no).sold_out_class;        -- Øæª
        lt_sold_out_time   := gt_lines_work_data(line_no).sold_out_time;         -- ØÔ
        lt_cash_and_card   := gt_lines_work_data(line_no).cash_and_card;         -- »àEJ[h¹pz
--
        -- ¾×[vð²¯éð
        EXIT WHEN lt_order_noh_hht != lt_order_nol_hht;
--
        --==============================================================
        --iÚR[hÌÃ«`FbNi¾×j
        --==============================================================
        BEGIN
          --== iÚ}X^f[^o ==--
          -- ùÉæ¾ÏÝÌiÚR[hÅ é©ðmF·éB
          IF ( gt_select_item.EXISTS(lt_item_code) ) THEN
            lt_item_id       := gt_select_item(lt_item_code).item_id;          -- iÚID
            lt_standard_unit := gt_select_item(lt_item_code).primary_measure;  -- îPÊ
            lt_in_case       := gt_select_item(lt_item_code).in_case;          -- P[Xü
            lt_sale_object   := gt_select_item(lt_item_code).sale_object;      -- ãÎÛæª
            lt_item_status   := gt_select_item(lt_item_code).item_status;      -- iÚXe[^X
          ELSE
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--          SELECT ic_item.item_id                   inventory_item_id,        -- iÚID
            SELECT mtl_item.inventory_item_id        inventory_item_id,        -- iÚID
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
                   mtl_item.primary_unit_of_measure  primary_measure,          -- îPÊ
                   ic_item.attribute11               attribute11,              -- P[Xü
                   ic_item.attribute26               attribute26,              -- ãÎÛæª
                   cmm_item.item_status              item_status               -- iÚXe[^X
            INTO   lt_item_id,
                   lt_standard_unit,
                   lt_in_case,
                   lt_sale_object,
                   lt_item_status
            FROM   mtl_system_items_b    mtl_item,
                   ic_item_mst_b         ic_item,
                   xxcmm_system_items_b  cmm_item
            WHERE  mtl_item.segment1        = lt_item_code
              AND  mtl_item.organization_id = gn_orga_id
              AND  mtl_item.segment1        = ic_item.item_no
              AND  mtl_item.segment1        = cmm_item.item_code
              AND  ic_item.item_id          = cmm_item.item_id;
--
            gt_select_item(lt_item_code).item_id         := lt_item_id;         -- iÚID
            gt_select_item(lt_item_code).primary_measure := lt_standard_unit;   -- îPÊ
            gt_select_item(lt_item_code).in_case         := lt_in_case;         -- P[Xü
            gt_select_item(lt_item_code).sale_object     := lt_sale_object;     -- ãÎÛæª
            gt_select_item(lt_item_code).item_status     := lt_item_status;     -- iÚXe[^X
--
          END IF;
--
          --== ãÎÛæª`FbN ==--
          IF ( lt_sale_object = lv_bad_sale ) THEN
            -- OoÍ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_object );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
--
          --== iÚXe[^X`FbN ==--
          FOR i IN 1..gt_qck_item.COUNT LOOP
            EXIT WHEN gt_qck_item(i) = lt_item_status;
            IF ( i = gt_qck_item.COUNT ) THEN
              -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_item );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== â[Zo ==--
          lt_content       := lt_in_case;
          lt_case_number   := NVL( lt_case_number, 0 );
          lt_replenish_num := lt_in_case * lt_case_number + lt_quantity;
          IF ( lt_replenish_num = 0 ) THEN
            -- OoÍ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_convert );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- OoÍ
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
        END;
--
        --==============================================================
        --ãæªÌÃ«`FbNi¾×j
        --==============================================================
        FOR i IN 1..gt_qck_sale.COUNT LOOP
          EXIT WHEN gt_qck_sale(i) = lt_sale_class;
          IF ( i = gt_qck_sale.COUNT ) THEN
            -- OoÍ
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
        END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        --==============================================================
        --J[hïÐ`FbNi¾×j
        --==============================================================
          IF ( lt_card_sale_class <> cv_card AND (NVL(lt_cash_and_card ,0) <> 0)
                                             AND lt_card_company IS NULL ) THEN
            -- OoÍ
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- G[ÏÖi[
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
            ln_err_no := ln_err_no + 1;
            -- G[tOXV
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
        --==============================================================
        --RNo.ÆH/CÌÃ«`FbNi¾×j
        --==============================================================
        FOR j IN 1..gt_qck_busi.COUNT LOOP
          IF ( gt_qck_busi(j) = lt_bus_low_type ) THEN
            --== RNo.ÆH/CÌÝèl`FbN ==--
            IF ( ( lt_column_no IS NULL ) OR ( lt_h_and_c IS NULL ) ) THEN
              -- OoÍ
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_vd );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
              ln_err_no := ln_err_no + 1;
              -- G[tOXV
              lv_err_flag := cv_hit;
            END IF;
--
            --== H/CÌÚ`FbN ==--
            FOR i IN 1..gt_qck_hc.COUNT LOOP
              EXIT WHEN gt_qck_hc(i) = lt_h_and_c;
              IF ( i = gt_qck_hc.COUNT ) THEN
                -- OoÍ
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
                ov_retcode := cv_status_warn;
                -- G[ÏÖi[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
--                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
--                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
--                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
--                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
--                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
                ln_err_no := ln_err_no + 1;
                -- G[tOXV
                lv_err_flag := cv_hit;
              END IF;
            END LOOP;
--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--            --== VDR}X^ÆÌ®«`FbN ==--
--            BEGIN
--              lv_column_check := TO_CHAR( lt_customer_id ) || '_' || lt_column_no;
--              -- ùÉæ¾ÏÝÌlÅ é©ðmF·éB
--              IF ( gt_select_vd.EXISTS(lv_column_check) ) THEN
--                lt_vd_column := gt_select_vd(lv_column_check).column_no;  -- RNo.
--                lt_vd_hc     := gt_select_vd(lv_column_check).hot_cold;   -- H/C
--              ELSE
--                SELECT vd.column_no  column_no,      -- RNo.
--                       vd.hot_cold   hot_cold        -- H/C
--                INTO   lt_vd_column,
--                       lt_vd_hc
--                FROM   xxcoi_mst_vd_column vd
--                WHERE  vd.customer_id = lt_customer_id
--                  AND  vd.column_no   = lt_column_no;
----
--                gt_select_vd(lv_column_check).column_no := lt_vd_column;  -- RNo.
--                gt_select_vd(lv_column_check).hot_cold  := lt_vd_hc;      -- H/C
----
---- *********** 2009/09/01 N.Maeda 1.15 ADD START ************* --
--              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 ADD  END  ************* --
----
--              -- H/CÌ®«`FbN
--              IF ( lt_h_and_c != lt_vd_hc ) THEN
--                -- OoÍ
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_hc );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- G[ÏÖi[
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
--                ln_err_no := ln_err_no + 1;
--                -- G[tOXV
--                lv_err_flag := cv_hit;
--              END IF;
----
---- *********** 2009/09/01 N.Maeda 1.15 DEL START ************* --
----              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 DEL  END  ************* --
----
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                -- OoÍ
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- G[ÏÖi[
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- _R[h
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- _¼Ì
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- f[^¼Ì
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- óNO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- `[NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- sNO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- óNO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- ÚqR[h
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- Úq¼
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- üà/[iú
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ¬ÑÒR[h
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- iÚR[h
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- _R[h
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- `[NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- sNO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- ÚqR[h
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ¬ÑÒR[h
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- iÚR[h
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- G[àe
--                ln_err_no := ln_err_no + 1;
--                -- G[tOXV
--                lv_err_flag := cv_hit;
--            END;
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
--
          END IF;
        END LOOP;
--
        --==============================================================
        --[if[^i¾×jðêi[pÏÖ
        --==============================================================
        lt_line_temp(ln_temp_no).order_nol_hht   := lt_order_nol_hht;        -- óNo.iHHTj
        lt_line_temp(ln_temp_no).line_no_hht     := lt_line_no_hht;          -- sNo.iHHTj
        lt_line_temp(ln_temp_no).order_nol_ebs   := lt_order_nol_ebs;        -- óNo.iEBSj
        lt_line_temp(ln_temp_no).line_number     := lt_line_number;          -- ¾×Ô(EBS)
        lt_line_temp(ln_temp_no).item_code       := lt_item_code;            -- i¼R[hi©Ðj
        lt_line_temp(ln_temp_no).content         := lt_content;              -- ü
        lt_line_temp(ln_temp_no).item_id         := lt_item_id;              -- iÚID
        lt_line_temp(ln_temp_no).standard_unit   := lt_standard_unit;        -- îPÊ
        lt_line_temp(ln_temp_no).case_number     := lt_case_number;          -- P[X
        lt_line_temp(ln_temp_no).quantity        := lt_quantity;             -- Ê
        lt_line_temp(ln_temp_no).sale_class      := lt_sale_class;           -- ãæª
        lt_line_temp(ln_temp_no).wholesale_price := lt_wholesale_price;      -- µP¿
        lt_line_temp(ln_temp_no).selling_price   := lt_selling_price;        -- P¿
        lt_line_temp(ln_temp_no).column_no       := lt_column_no;            -- RNo.
        lt_line_temp(ln_temp_no).h_and_c         := lt_h_and_c;              -- H/C
        lt_line_temp(ln_temp_no).sold_out_class  := lt_sold_out_class;       -- Øæª
        lt_line_temp(ln_temp_no).sold_out_time   := lt_sold_out_time;        -- ØÔ
        lt_line_temp(ln_temp_no).replenish_num   := lt_replenish_num;        -- â[
        lt_line_temp(ln_temp_no).cash_and_card   := lt_cash_and_card;        -- »àEJ[h¹pz
        ln_temp_no := ln_temp_no +1;
--
        -- ¾×`FbNÏÔXV
        ln_line_cnt := ln_line_cnt + 1;
--
      END LOOP;
--
      -- ³ílÏÖf[^ði[
      IF ( lv_err_flag = cv_default ) THEN
        --==============================================================
        --[if[^iwb_jðÏÖi[
        --==============================================================
        gt_head_order_no_hht(ln_header_ok_no)    := lt_order_noh_hht;        -- óNo.iHHTj
        gt_head_order_no_ebs(ln_header_ok_no)    := lt_order_noh_ebs;        -- óNo.iEBSj
        gt_head_base_code(ln_header_ok_no)       := lt_sale_base;            -- _R[h
        gt_head_perform_code(ln_header_ok_no)    := lt_performance_code;     -- ¬ÑÒR[h
        gt_head_dlv_by_code(ln_header_ok_no)     := lt_dlv_code;             -- [iÒR[h
        gt_head_hht_invoice_no(ln_header_ok_no)  := lt_hht_invoice_no;       -- HHT`[No.
        gt_head_dlv_date(ln_header_ok_no)        := lt_dlv_date;             -- [iú
        gt_head_inspect_date(ln_header_ok_no)    := lt_inspect_date;         -- ûú
        gt_head_sales_class(ln_header_ok_no)     := lt_sales_class;          -- ãªÞæª
        gt_head_sales_invoice(ln_header_ok_no)   := lt_sales_invoice;        -- ã`[æª
        gt_head_card_class(ln_header_ok_no)      := lt_card_sale_class;      -- J[hæª
        gt_head_dlv_time(ln_header_ok_no)        := lt_dlv_time;             -- Ô
        gt_head_change_time_100(ln_header_ok_no) := lt_change_out_100;       -- ÂèKØêÔ100~
        gt_head_change_time_10(ln_header_ok_no)  := lt_change_out_10;        -- ÂèKØêÔ10~
        gt_head_cus_number(ln_header_ok_no)      := lt_customer_number;      -- ÚqR[h
        gt_head_system_class(ln_header_ok_no)    := lt_bus_low_type;         -- ÆÔæª
        gt_head_input_class(ln_header_ok_no)     := lt_input_class;          -- üÍæª
        gt_head_tax_class(ln_header_ok_no)       := lt_tax_class;            -- ÁïÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
        gt_head_discount_tax_class(ln_header_ok_no) := lt_discnt_tax_class;  -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
        gt_head_total_amount(ln_header_ok_no)    := lt_total_amount;         -- vàz
        gt_head_sale_discount(ln_header_ok_no)   := lt_sale_discount;        -- ãløz
        gt_head_sales_tax(ln_header_ok_no)       := lt_sales_tax;            -- ãÁïÅz
        gt_head_tax_include(ln_header_ok_no)     := lt_tax_include;          -- Åàz
        gt_head_keep_in_code(ln_header_ok_no)    := lt_keep_in_code;         -- a¯æR[h
        gt_head_depart_screen(ln_header_ok_no)   := lt_department_class;     -- SÝXæÊíÊ
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
        gt_head_order_number(ln_header_ok_no)    := lt_order_number;         -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
        gt_head_ttl_sales_amt(ln_header_ok_no)    := lt_ttl_sales_amt;       -- Ìàz
        gt_head_cs_ttl_sales_amt(ln_header_ok_no) := lt_cs_ttl_sales_amt;    -- »àèg[^Ìàz
        gt_head_pp_ttl_sales_amt(ln_header_ok_no) := lt_pp_ttl_sales_amt;    -- PPJ[hg[^Ìàz
        gt_head_id_ttl_sales_amt(ln_header_ok_no) := lt_id_ttl_sales_amt;    -- IDJ[hg[^Ìàz
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
        gt_head_hht_input_date(ln_header_ok_no)   := lt_hht_input_date;      -- HHTüÍú
-- Ver.1.29 ADD End
-- Ver.1.30 ADD Start
        gt_head_visit_class1(ln_header_ok_no)     := lt_visit_class1;         -- Kâæª1
        gt_head_visit_class2(ln_header_ok_no)     := lt_visit_class2;         -- Kâæª2
        gt_head_visit_class3(ln_header_ok_no)     := lt_visit_class3;         -- Kâæª3
        gt_head_visit_class4(ln_header_ok_no)     := lt_visit_class4;         -- Kâæª4
        gt_head_visit_class5(ln_header_ok_no)     := lt_visit_class5;         -- Kâæª5
-- Ver.1.30 ADD End
        gt_resource_id(ln_header_ok_no)          := lt_resource_id;          -- \[XID
        gt_party_id(ln_header_ok_no)             := lt_party_id;             -- p[eBID
        gt_party_name(ln_header_ok_no)           := lt_customer_name;        -- Úq¼Ì
        gt_cus_status(ln_header_ok_no)           := lt_cus_status;           -- ÚqXe[^X
        ln_header_ok_no := ln_header_ok_no + 1;
--
        --==============================================================
        --[if[^i¾×jðÏÖi[
        --==============================================================
        FOR i IN 1..lt_line_temp.COUNT LOOP
          gt_line_order_no_hht(ln_line_ok_no)   := lt_line_temp(i).order_nol_hht;     -- óNo.iHHTj
          gt_line_line_no_hht(ln_line_ok_no)    := lt_line_temp(i).line_no_hht;       -- sNo.iHHTj
          gt_line_order_no_ebs(ln_line_ok_no)   := lt_line_temp(i).order_nol_ebs;     -- óNo.iEBSj
          gt_line_line_num_ebs(ln_line_ok_no)   := lt_line_temp(i).line_number;       -- ¾×Ô(EBS)
          gt_line_item_code_self(ln_line_ok_no) := lt_line_temp(i).item_code;         -- i¼R[hi©Ðj
          gt_line_content(ln_line_ok_no)        := lt_line_temp(i).content;           -- ü
          gt_line_item_id(ln_line_ok_no)        := lt_line_temp(i).item_id;           -- iÚID
          gt_line_standard_unit(ln_line_ok_no)  := lt_line_temp(i).standard_unit;     -- îPÊ
          gt_line_case_number(ln_line_ok_no)    := lt_line_temp(i).case_number;       -- P[X
          gt_line_quantity(ln_line_ok_no)       := lt_line_temp(i).quantity;          -- Ê
          gt_line_sale_class(ln_line_ok_no)     := lt_line_temp(i).sale_class;        -- ãæª
          gt_line_wholesale_unit(ln_line_ok_no) := lt_line_temp(i).wholesale_price;   -- µP¿
          gt_line_selling_price(ln_line_ok_no)  := lt_line_temp(i).selling_price;     -- P¿
          gt_line_column_no(ln_line_ok_no)      := lt_line_temp(i).column_no;         -- RNo.
          gt_line_h_and_c(ln_line_ok_no)        := lt_line_temp(i).h_and_c;           -- H/C
          gt_line_sold_out_class(ln_line_ok_no) := lt_line_temp(i).sold_out_class;    -- Øæª
          gt_line_sold_out_time(ln_line_ok_no)  := lt_line_temp(i).sold_out_time;     -- ØÔ
          gt_line_replenish_num(ln_line_ok_no)  := lt_line_temp(i).replenish_num;     -- â[
          gt_line_cash_and_card(ln_line_ok_no)  := lt_line_temp(i).cash_and_card;     -- »àEJ[h¹pz
          ln_line_ok_no := ln_line_ok_no + 1;
        END LOOP;
      END IF;
--
      -- [i¾×f[^êi[pÏðú»
      lt_line_temp.DELETE;
      ln_temp_no := 1;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END data_check;
--
  /***********************************************************************************
   * Procedure Name   : error_data_register
   * Description      : G[f[^o^(A-3)
   ***********************************************************************************/
  PROCEDURE error_data_register(
    on_warn_cnt       OUT NUMBER,           --   x
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_data_register'; -- vO¼
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
    -- xú»
    on_warn_cnt := 0;
--
    --==============================================================
    -- HHTG[Xg [[Ne[uÖG[f[^o^
    --==============================================================
    -- xZbg
    on_warn_cnt := gt_err_base_code.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_warn_cnt
        INSERT INTO xxcos_rep_hht_err_list
          (
            record_id,
            base_code,
            base_name,
            origin_shipment,
            data_name,
            order_no_hht,
            invoice_invent_date,
            entry_number,
            line_no,
            order_no_ebs,
            party_num,
            customer_name,
            payment_dlv_date,
            payment_class_name,
            performance_by_code,
            item_code,
            error_message,
            report_group_id,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            xxcos_rep_hht_err_list_s01.NEXTVAL,          -- R[hID
            gt_err_base_code(i),                         -- _R[h
            gt_err_base_name(i),                         -- _¼Ì
            NULL,                                        -- oÉ¤R[h
            gt_err_data_name(i),                         -- f[^¼Ì
            gt_err_order_no_hht(i),                      -- óNOiHHTj
            NULL,                                        -- `[/Iµú
            gt_err_entry_number(i),                      -- `[NO
            gt_err_line_no(i),                           -- sNO
--****************************** 2009/05/15 1.13 N.Maeda MOD START  *****************************--
            DECODE ( gt_err_order_no_ebs(i) ,            -- óNOiEBSj
                     ct_order_no_ebs_0 , NULL ,
                     gt_err_order_no_ebs(i) ) ,
--            gt_err_order_no_ebs(i),                      -- óNOiEBSj
--****************************** 2009/05/15 1.13 N.Maeda MOD  END   *****************************--
            gt_err_party_num(i),                         -- ÚqR[h
            gt_err_customer_name(i),                     -- Úq¼
            gt_err_payment_dlv_date(i),                  -- üà/[iú
            NULL,                                        -- üàæª¼Ì
            gt_err_perform_by_code(i),                   -- ¬ÑÒR[h
            gt_err_item_code(i),                         -- iÚR[h
            gt_err_error_message(i),                     -- G[àe
            NULL,                                        --  [pO[vID
            cn_created_by,                               -- ì¬Ò
            cd_creation_date,                            -- ì¬ú
            cn_last_updated_by,                          -- ÅIXVÒ
            cd_last_update_date,                         -- ÅIXVú
            cn_last_update_login,                        -- ÅIXVOC
            cn_request_id,                               -- vID
            cn_program_application_id,                   -- RJgEvOEAvP[VID
            cn_program_id,                               -- RJgEvOID
            cd_program_update_date                       -- vOXVú
          );
--
    EXCEPTION
--
      -- G[if[^ÇÁG[j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END error_data_register;
--
  /***********************************************************************************
   * Procedure Name   : header_data_register
   * Description      : [iwb_e[uÖf[^o^(A-4)
   ***********************************************************************************/
  PROCEDURE header_data_register(
    on_normal_cnt     OUT NUMBER,           --   [iwb_f[^ì¬
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'header_data_register'; -- vO¼
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
    cv_entry_class  VARCHAR2(1) DEFAULT '3';  -- KâLøîño^FDFF12io^æªj
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
    -- [iwb_f[^ì¬ú»
    on_normal_cnt := 0;
--
    --==============================================================
    -- [iwb_e[uÖf[^o^
    --==============================================================
    -- ¤ÊÖKâLøîño^
    FOR i IN 1..gt_party_id.COUNT LOOP
--
      xxcos_task_pkg.task_entry(
        lv_errbuf                 -- G[EbZ[W
       ,lv_retcode                -- ^[ER[h
       ,lv_errmsg                 -- [U[EG[EbZ[W
       ,gt_resource_id(i)         -- \[XID
       ,gt_party_id(i)            -- p[eBID
       ,gt_party_name(i)          -- p[eB¼ÌiÚq¼Ìj
--****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
       ,TO_DATE(TO_CHAR( gt_head_dlv_date(i) , cv_shot_date_type)
                ||cv_spe_cha||SUBSTR(gt_head_dlv_time(i),1,2)
                ||cv_time_cha||SUBSTR(gt_head_dlv_time(i),3,2) , cv_date_type)
--       ,gt_head_dlv_date(i)       -- Kâú  [iú
--****************************** 2009/05/15 1.14 N.Maeda MOD  END   *****************************--
       ,NULL                      -- Ú×àe
       ,gt_head_total_amount(i)   -- vàz
       ,gt_head_input_class(i)    -- üÍæª
-- Ver.1.30 ADD Start
       ,gt_head_visit_class1(i)   -- DFF1iKâæª1j
       ,gt_head_visit_class2(i)   -- DFF2iKâæª2j
       ,gt_head_visit_class3(i)   -- DFF3iKâæª3j
       ,gt_head_visit_class4(i)   -- DFF4iKâæª4j
       ,gt_head_visit_class5(i)   -- DFF5iKâæª5j
       ,NULL                      -- DFF6iKâæª6j
       ,NULL                      -- DFF7iKâæª7j
       ,NULL                      -- DFF8iKâæª8j
       ,NULL                      -- DFF9iKâæª9j
       ,NULL                      -- DFF10iKâæª10j
-- Ver.1.30 ADD End
       ,cv_entry_class            -- DFF12io^æªj 3
       ,gt_head_order_no_hht(i)   -- DFF13io^³\[XÔj óNo.iHHTj
       ,gt_cus_status(i)          -- DFF14iÚqXe[^Xj
      );
--
      --G[`FbN
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP;
--
--
    --== f[^o^ ==--
    -- [iwb_f[^ì¬Zbg
    on_normal_cnt := gt_head_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_headers
          (
            order_no_hht,
            digestion_ln_number,
            order_no_ebs,
            base_code,
            performance_by_code,
            dlv_by_code,
            hht_invoice_no,
            dlv_date,
            inspect_date,
            sales_classification,
            sales_invoice,
            card_sale_class,
            dlv_time,
            change_out_time_100,
            change_out_time_10,
            customer_number,
            system_class,
            input_class,
            consumption_tax_class,
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
            discount_tax_class,
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
            total_amount,
            sale_discount_amount,
            sales_consumption_tax,
            tax_include,
            keep_in_code,
            department_screen_class,
            red_black_flag,
            stock_forward_flag,
            stock_forward_date,
            results_forward_flag,
            results_forward_date,
            cancel_correct_class,
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
            order_number,
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
            total_sales_amt,
            cash_total_sales_amt,
            ppcard_total_sales_amt,
            idcard_total_sales_amt,
            hht_received_flag,
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
            hht_input_date,
-- Ver.1.29 ADD End
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_head_order_no_hht(i),                     -- óNo.iHHT)
            cv_default,                                  -- }Ô
            gt_head_order_no_ebs(i),                     -- óNo.iEBSj
            gt_head_base_code(i),                        -- _R[h
            gt_head_perform_code(i),                     -- ¬ÑÒR[h
            gt_head_dlv_by_code(i),                      -- [iÒR[h
            gt_head_hht_invoice_no(i),                   -- HHT`[No.
            gt_head_dlv_date(i),                         -- [iú
            gt_head_inspect_date(i),                     -- ûú
            gt_head_sales_class(i),                      -- ãªÞæª
            gt_head_sales_invoice(i),                    -- ã`[æª
            gt_head_card_class(i),                       -- J[hæª
            gt_head_dlv_time(i),                         -- Ô
            gt_head_change_time_100(i),                  -- ÂèKØêÔ100~
            gt_head_change_time_10(i),                   -- ÂèKØêÔ10~
            gt_head_cus_number(i),                       -- ÚqR[h
            gt_head_system_class(i),                     -- ÆÔæª
            gt_head_input_class(i),                      -- üÍæª
            gt_head_tax_class(i),                        -- ÁïÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD START ********* --
            gt_head_discount_tax_class(i),               -- løÅæª
-- ******* 2019/07/26 ver.1.31 S.Kuwako ADD END   ********* --
            gt_head_total_amount(i),                     -- vàz
            gt_head_sale_discount(i),                    -- ãløz
            gt_head_sales_tax(i),                        -- ãÁïÅz
            gt_head_tax_include(i),                      -- Åàz
            gt_head_keep_in_code(i),                     -- a¯æR[h
            gt_head_depart_screen(i),                    -- SÝXæÊíÊ
            cv_hit,                                      -- ÔtO
            cv_default,                                  -- üoÉ]ÏtO
            NULL,                                        -- üoÉ]Ïút
            cv_default,                                  -- ÌÀÑAgÏÝtO
            NULL,                                        -- ÌÀÑAgÏÝút
            NULL,                                        -- æÁEù³æª
-- 2011/03/16 Ver.1.26 S.Ochiai ADD Start
            gt_head_order_number(i),                     -- I[_[No
-- 2011/03/16 Ver.1.26 S.Ochiai ADD End
-- Ver.1.28 ADD Start
            gt_head_ttl_sales_amt(i),                    -- Ìàz
            gt_head_cs_ttl_sales_amt(i),                 -- »àèg[^Ìàz
            gt_head_pp_ttl_sales_amt(i),                 -- PPJ[hg[^Ìàz
            gt_head_id_ttl_sales_amt(i),                 -- IDJ[hg[^Ìàz
            cv_hht_received,                             -- HHTóMtO
-- Ver.1.28 ADD End
-- Ver.1.29 ADD Start
            gt_head_hht_input_date(i),                   -- HHTüÍú
-- Ver.1.29 ADD End
            cn_created_by,                               -- ì¬Ò
            cd_creation_date,                            -- ì¬ú
            cn_last_updated_by,                          -- ÅIXVÒ
            cd_last_update_date,                         -- ÅIXVú
            cn_last_update_login,                        -- ÅIXVOC
            cn_request_id,                               -- vID
            cn_program_application_id,                   -- RJgEvOEAvP[VID
            cn_program_id,                               -- RJgEvOID
            cd_program_update_date                       -- vOXVú
          );
--
    EXCEPTION
--
      -- G[if[^ÇÁG[j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END header_data_register;
--
  /***********************************************************************************
   * Procedure Name   : lines_data_register
   * Description      : [i¾×e[uÖf[^o^(A-5)
   ***********************************************************************************/
  PROCEDURE lines_data_register(
    on_normal_cnt     OUT NUMBER,           --   [i¾×f[^ì¬
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lines_data_register'; -- vO¼
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
    -- [i¾×f[^ì¬ú»
    on_normal_cnt := 0;
--
    --==============================================================
    -- [i¾×e[uÖf[^o^
    --==============================================================
    -- [i¾×f[^ì¬Zbg
    on_normal_cnt := gt_line_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_lines
          (
            order_no_hht,
            line_no_hht,
            digestion_ln_number,
            order_no_ebs,
            line_number_ebs,
            item_code_self,
            content,
            inventory_item_id,
            standard_unit,
            case_number,
            quantity,
            sale_class,
            wholesale_unit_ploce,
            selling_price,
            column_no,
            h_and_c,
            sold_out_class,
            sold_out_time,
            replenish_number,
            cash_and_card,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_line_order_no_hht(i),                     -- óNo.iHHTj
            gt_line_line_no_hht(i),                      -- sNo.iHHTj
            cv_default,                                  -- }Ô
            gt_line_order_no_ebs(i),                     -- óNo.iEBSj
            gt_line_line_num_ebs(i),                     -- ¾×ÔiEBSj
            gt_line_item_code_self(i),                   -- i¼R[hi©Ðj
            gt_line_content(i),                          -- ü
            gt_line_item_id(i),                          -- iÚID
            gt_line_standard_unit(i),                    -- îPÊ
            gt_line_case_number(i),                      -- P[X
            gt_line_quantity(i),                         -- Ê
            gt_line_sale_class(i),                       -- ãæª
            gt_line_wholesale_unit(i),                   -- µP¿
            gt_line_selling_price(i),                    -- P¿
            gt_line_column_no(i),                        -- RNo.
            gt_line_h_and_c(i),                          -- H/C
            gt_line_sold_out_class(i),                   -- Øæª
            gt_line_sold_out_time(i),                    -- ØÔ
            gt_line_replenish_num(i),                    -- â[
            gt_line_cash_and_card(i),                    -- »àEJ[h¹pz
            cn_created_by,                               -- ì¬Ò
            cd_creation_date,                            -- ì¬ú
            cn_last_updated_by,                          -- ÅIXVÒ
            cd_last_update_date,                         -- ÅIXVú
            cn_last_update_login,                        -- ÅIXVOC
            cn_request_id,                               -- vID
            cn_program_application_id,                   -- RJgEvOEAvP[VID
            cn_program_id,                               -- RJgEvOID
            cd_program_update_date                       -- vOXVú
          );
--
    EXCEPTION
--
      -- G[if[^ÇÁG[j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END lines_data_register;
--
  /***********************************************************************************
   * Procedure Name   : work_data_delete
   * Description      : [Ne[uR[hí(A-6)
   ***********************************************************************************/
  PROCEDURE work_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'work_data_delete'; -- vO¼
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
--
    -- [iwb_[NSf[^bN
    CURSOR loc_headers_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_headers_work
    FOR UPDATE NOWAIT;
    -- [i¾×[NSf[^bN
    CURSOR loc_lines_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_lines_work
    FOR UPDATE NOWAIT;
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    --  N®æª3Ìêr¼§äðÀ{
    IF ( gv_mode = cv_truncate ) THEN
--
      -- wb_[NÉr¼§äðÀ{
      BEGIN
--
        OPEN  loc_headers_cur;
        CLOSE loc_headers_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
        -- J[\CLOSE
        IF ( loc_headers_cur%ISOPEN ) THEN
          CLOSE loc_headers_cur;
        END IF;
--
        RAISE global_api_expt;
      END;
--
      -- ¾×[NÉr¼§äðÀ{
      BEGIN
--
        OPEN  loc_lines_cur;
        CLOSE loc_lines_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
          lv_errbuf  := lv_errmsg;
--
          -- J[\CLOSE
          IF ( loc_lines_cur%ISOPEN ) THEN
            CLOSE loc_lines_cur;
          END IF;
--
          RAISE global_api_expt;
      END;
--
    END IF;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
    --==============================================================
    -- [iwb_[Ne[uÌR[hí
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_headers_work';
      DELETE FROM xxcos_dlv_headers_work;
      gn_wh_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- [i¾×[Ne[uÌR[hí
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_lines_work';
      DELETE FROM xxcos_dlv_lines_work;
      gn_wl_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END work_data_delete;
--
  /***********************************************************************************
   * Procedure Name   : table_lock
   * Description      : e[ubN(A-7)
   ***********************************************************************************/
  PROCEDURE table_lock(
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'table_lock'; -- vO¼
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
    lv_purge_date    VARCHAR2(5);  -- p[WZoîú
    ld_process_date  DATE;         -- Æ±ú
--
    -- *** [JEJ[\ ***
    CURSOR headers_lock_cur
    IS
      SELECT head.creation_date  creation_date
      FROM   xxcos_dlv_headers   head
      WHERE  TRUNC( head.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
--
    CURSOR lines_lock_cur
    IS
      SELECT line.creation_date  creation_date
      FROM   xxcos_dlv_lines     line
      WHERE  TRUNC( line.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
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
    --==============================================================
    -- vt@CÌæ¾(XXCOS:[if[^æp[WúZoîú)
    --==============================================================
    lv_purge_date := FND_PROFILE.VALUE( cv_prf_purge_date );
--
    -- vt@Cæ¾G[Ìê
    IF ( lv_purge_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gn_purge_date := TO_NUMBER( lv_purge_date );
    END IF;
--
    --==============================================================
    -- ¤ÊÖÆ±úæ¾ÌÄÑoµ
    --==============================================================
     ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- Æ±úæ¾G[Ìê
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- e[ubN
    --==============================================================
    OPEN  headers_lock_cur;
    CLOSE headers_lock_cur;
--
    OPEN  lines_lock_cur;
    CLOSE lines_lock_cur;
--
  EXCEPTION
--
    -- bNG[
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
--
      IF ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END table_lock;
--
  /***********************************************************************************
   * Procedure Name   : dlv_data_delete
   * Description      : [iwb_E¾×e[uR[hí(A-8)
   ***********************************************************************************/
  PROCEDURE dlv_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   G[EbZ[W           --# Åè #
    ov_retcode        OUT VARCHAR2,         --   ^[ER[h             --# Åè #
    ov_errmsg         OUT VARCHAR2)         --   [U[EG[EbZ[W --# Åè #
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_delete'; -- vO¼
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
    --==============================================================
    -- [iwb_e[uÌsvf[^í
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_headers
      WHERE TRUNC( xxcos_dlv_headers.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_h := SQL%ROWCOUNT;    -- wb_í
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- [i¾×e[uÌsvf[^í
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_lines
      WHERE TRUNC( xxcos_dlv_lines.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_l := SQL%ROWCOUNT;      -- ¾×í
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- íoÍ
    --==============================================================
    -- wb_
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_h, cv_tkn_count, TO_CHAR( gn_del_cnt_h ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ¾×
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_l, cv_tkn_count, TO_CHAR( gn_del_cnt_l ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : CvV[W
   **********************************************************************************/
  PROCEDURE submain(
    iv_mode       IN  VARCHAR2,     --   N®[hi1:Ô or 2:éÔj
    ov_errbuf     OUT VARCHAR2,     --   G[EbZ[W           --# Åè #
    ov_retcode    OUT VARCHAR2,     --   ^[ER[h             --# Åè #
    ov_errmsg     OUT VARCHAR2)     --   [U[EG[EbZ[W --# Åè #
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
    ln_line_cnt   NUMBER;     -- oi[i¾×[Ne[uj
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
    gn_tar_cnt_h  := 0;
    gn_tar_cnt_l  := 0;
    gn_nor_cnt_h  := 0;
    gn_nor_cnt_l  := 0;
    gn_del_cnt_h  := 0;
    gn_del_cnt_l  := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    gn_wh_del_count := 0;
    gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
    --*********************************************
    --***      MD.050Ìt[}ð\·           ***
    --***      ªòÆÌÄÑoµðs¤     ***
    --*********************************************
--
    -- ===============================
    -- ú(A-0)
    -- ===============================
    gv_mode := iv_mode;
    init(
      lv_errbuf,         -- G[EbZ[W           --# Åè #
      lv_retcode,        -- ^[ER[h             --# Åè #
      lv_errmsg);        -- [U[EG[EbZ[W --# Åè #
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
      ov_errmsg   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- G[
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF ( gv_mode = cv_daytime ) THEN    -- ÔN®Ì
--
      -- ============================================
      -- [if[^o(A-1)
      -- ============================================
      dlv_data_receive(
        gn_tar_cnt_h,           -- ÎÛi[iwb_[Ne[uj
        gn_tar_cnt_l,           -- ÎÛi[i¾×[Ne[uj
        lv_errbuf,              -- G[EbZ[W           --# Åè #
        lv_retcode,             -- ^[ER[h             --# Åè #
        lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
      -- G[
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
--
      -- xiÎÛf[^³µG[j
      ELSIF ( gn_tar_cnt_h = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
--
      END IF;
--
      --== ÎÛf[^ª1Èã éêAA-2©çA-6Ìðs¢Ü·B ==--
      IF ( gn_tar_cnt_h >= 1 ) THEN
        -- ============================================
        -- f[^Ã«`FbN(A-2)
        -- ============================================
        data_check(
          gn_tar_cnt_l,           -- i¾×j
          lv_errbuf,              -- G[EbZ[W           --# Åè #
          lv_retcode,             -- ^[ER[h             --# Åè #
          lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_errbuf   :=  lv_errbuf;
          ov_retcode  :=  lv_retcode;
          ov_errmsg   :=  lv_errmsg;
        END IF;
--
        -- G[
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ============================================
        -- G[f[^o^(A-3)
        -- ============================================
        -- Ã«`FbNÅG[ÆÈÁ½f[^ÉÎµÄÈºÌðs¢Ü·B
        IF ( gt_err_base_code IS NOT NULL ) THEN
          error_data_register(
            gn_error_cnt,           -- x
            lv_errbuf,              -- G[EbZ[W           --# Åè #
            lv_retcode,             -- ^[ER[h             --# Åè #
            lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
          --G[
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- [iwb_e[uÖf[^o^(A-4)
        -- ============================================
        -- Ã«`FbNÅG[ÆÈçÈ©Á½f[^ÉÎµÄÈºÌðs¤B
        IF ( gt_head_order_no_hht IS NOT NULL ) THEN
          header_data_register(
            gn_nor_cnt_h,           -- [iwb_f[^ì¬
            lv_errbuf,              -- G[EbZ[W           --# Åè #
            lv_retcode,             -- ^[ER[h             --# Åè #
            lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
          --G[
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- [i¾×e[uÖf[^o^(A-5)
        -- ============================================
        -- Ã«Ì`FbNÅG[ÆÈçÈ©Á½f[^ÉÎµÄÈºÌðs¤B
        IF ( gt_line_order_no_hht IS NOT NULL ) THEN
          lines_data_register(
            gn_nor_cnt_l,           -- [i¾×f[^ì¬
            lv_errbuf,              -- G[EbZ[W           --# Åè #
            lv_retcode,             -- ^[ER[h             --# Åè #
            lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
          --G[
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- [Ne[uR[hí(A-6)
        -- ============================================
        work_data_delete(
          lv_errbuf,              -- G[EbZ[W           --# Åè #
          lv_retcode,             -- ^[ER[h             --# Åè #
          lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
        --G[
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
--
    ELSIF ( gv_mode = cv_night ) THEN    -- éÔN®Ì
--
      -- ============================================
      -- e[ubN(A-7)
      -- ============================================
      table_lock(
        lv_errbuf,              -- G[EbZ[W           --# Åè #
        lv_retcode,             -- ^[ER[h             --# Åè #
        lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
      -- G[
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ============================================
      -- [iwb_E¾×e[uR[hí(A-8)
      -- ============================================
      dlv_data_delete(
        lv_errbuf,              -- G[EbZ[W           --# Åè #
        lv_retcode,             -- ^[ER[h             --# Åè #
        lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
      -- G[
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- N®Ì
      -- ============================================
      -- [Ne[uR[hí(A-6)
      -- ============================================
      work_data_delete(
        lv_errbuf,              -- G[EbZ[W           --# Åè #
        lv_retcode,             -- ^[ER[h             --# Åè #
        lv_errmsg);             -- [U[EG[EbZ[W --# Åè #
--
      --G[
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
--
    END IF;
--
--
  EXCEPTION
--
--#################################  ÅèáO START   ###################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT VARCHAR2,      --   G[EbZ[W  --# Åè #
    retcode       OUT VARCHAR2,      --   ^[ER[h    --# Åè #
    iv_mode       IN  VARCHAR2       --   N®[hi1:Ô or 2:éÔj
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  Åè END   #############################
--
    -- ===============================================
    -- submainÌÄÑoµiÀÛÌÍsubmainÅs¤j
    -- ===============================================
    submain(
       iv_mode     -- N®[h
      ,lv_errbuf   -- G[EbZ[W           --# Åè #
      ,lv_retcode  -- ^[ER[h             --# Åè #
      ,lv_errmsg   -- [U[EG[EbZ[W --# Åè #
    );
--
    --G[oÍ
    IF (lv_retcode = cv_status_error) THEN
      -- ¬÷ú»
      gn_nor_cnt_h := 0;
      gn_nor_cnt_l := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      gn_wh_del_count := 0;
      gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --[U[EG[bZ[W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --G[bZ[W
      );
    END IF;
    --ós}ü
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ÔN®ÌoÍ
    IF ( iv_mode = cv_daytime ) THEN
--
      --wb_ÎÛoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --¾×ÎÛoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --wb_¬÷oÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --¾×¬÷oÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      --wb_[NíoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --¾×[NíoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
      --G[oÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    ELSIF ( iv_mode = cv_truncate ) THEN
      --
      IF ( lv_retcode = cv_status_normal ) THEN
--
        --íÎÛª¶ÝµÈ¢ê
        IF ( gn_wh_del_count = 0 ) AND ( gn_wl_del_count = 0 ) THEN
          --[Ne[uíÎÛf[^ÈµbZ[W
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_no_del_target
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          
        ELSE
--
          --SíbZ[W
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_mode3_comp
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END IF;
      END IF;
      --
      --wb_[NíoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --¾×[NíoÍ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
    END IF;
--
    --I¹bZ[W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS001A01C;
/
