CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A10C(body)
 * Description      : KâãvæÇ\iÀsÌ [jpÉT}e[uðì¬µÜ·B
 * MD.050           :  MD050_CSO_019_A10_KâãvæÇWvob`
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ú (A-1)
 *  check_parm             p[^`FbN (A-2)
 *  delete_data            ÎÛf[^í (A-3)
 *  get_day_acct_data      úÊÚqÊf[^æ¾ (A-4)
 *  insert_day_acct_dt     KâãvæÇ\T}e[uÉo^ (A-5)
 *  insert_day_emp_dt      úÊcÆõÊæ¾o^ (A-6)
 *  insert_day_group_dt    úÊcÆO[vÊæ¾o^ (A-7)
 *  insert_day_base_dt     úÊ_^ÛÊæ¾o^ (A-8)
 *  insert_day_area_dt     úÊnæcÆ^Êæ¾o^ (A-9)
 *  insert_mon_acct_dt     ÊÚqÊæ¾o^ (A-10)
 *  insert_mon_emp_dt      ÊcÆõÊæ¾o^ (A-11)
 *  insert_mon_group_dt    ÊcÆO[vÊæ¾o^ (A-12)
 *  insert_mon_base_dt     Ê_^ÛÊæ¾o^ (A-13)
 *  insert_mon_area_dt     ÊnæcÆ^Êæ¾o^ (A-14)
 *  submain                CvV[W
 *  main                   RJgÀst@Co^vV[W
 *                           I¹ (A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-13    1.0   Tomoko.Mori      VKì¬
 *  2009-03-12    1.1   Kazuyo.Hosoi     yáQÎ047E048E057z
 *                                       ÚqæªAXe[^XoðÏXEVKÚql¾Ì»è
 *                                       oðÏX
 *  2009-03-19    1.1   Tomoko.Mori      yáQÎ073z
 *                                       úÊÚqÊãvæîñiÊãvæjæ¾Ìoðsï
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897Î
 *  2009-05-01    1.3   Daisuke.Abe      yãvæoÍÎzT1_0689,T1_0692,T1_0694,T1_0695
 *  2009-05-01    1.3   Daisuke.Abe      yãvæoÍÎzT1_0734,T1_0739,T1_0744,T1_0745
 *  2009-05-01    1.3   Daisuke.Abe      yãvæoÍÎzT1_0751
 *  2009-05-19    1.4   H.Ogawa          áQÔFT1_1024,T1_1037,T1_1038
 *  2009-05-25    1.4   T.Mori           Æ±útAïvúÔJnúªNULLÅ éêA
 *                                       G[bZ[WªoÍ³ê¸AG[I¹µÈ¢
 *  2009-08-28    1.5   Daisuke.Abe      y0001194zptH[}XÎ
 *  2009-11-06    1.6   Kazuo.Satomura   yE_T4_00135(I_E_636)z
 *  2009-12-28    1.7   Kazuyo.Hosoi     yE_{Ò®_00686zÎ
 *  2010-05-14    1.8   SCS g³­÷     yE_{Ò®_02763zÎ
 *  2012-02-17    1.9   SCSKìÄj     yE_{Ò®_08750zÎ
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  Åè END   ##################################
--
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A10C';  -- pbP[W¼
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- AvP[VZk¼
  -- bZ[WR[h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- Æ±útæ¾G[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00430';  -- ïvúÔJnútæ¾G[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- KâãvæÇT}íG[bZ[W
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- úÊÚqÊf[^oG[bZ[W
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00431';  -- KâãvæÇT}o^G[bZ[W
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ³íI¹bZ[W
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- G[I¹bZ[W
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- ÎÛbZ[W
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- ¬÷bZ[W
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- G[bZ[W
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := '';  -- XLbvbZ[W
  /* 2009.11.06 K.Satomura E_T4_00135Î START*/
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00580';  -- ÚqCD^ãS_CDG[
  /* 2009.11.06 K.Satomura E_T4_00135Î END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- üÍp[^K{G[bZ[W
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00250';  -- p[^æª
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- p[^Ã«`FbNG[bZ[W
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- g[NR[h
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage       CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_processing_name  CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  /* 2009.11.06 K.Satomura E_T4_00135Î START*/
  cv_tkn_sum_org_code     CONSTANT VARCHAR2(20) := 'SUM_ORG_CODE';
  cv_tkn_group_base_code  CONSTANT VARCHAR2(20) := 'GROUP_BASE_CODE';
  cv_tkn_sales_date       CONSTANT VARCHAR2(20) := 'SALES_DATE';
  cv_tkn_sqlerrm          CONSTANT VARCHAR2(20) := 'SQLERRM';
  /* 2009.11.06 K.Satomura E_T4_00135Î END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';
  -- bZ[WpÅè¶ñ
  cv_tkn_msg_proc_div     CONSTANT VARCHAR2(200) := 'æª';
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cv_true                 CONSTANT VARCHAR2(10) := 'TRUE';
  cv_null                 CONSTANT VARCHAR2(10) := 'NULL';
  -- DEBUG_LOGpbZ[W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< Æ±úæ¾ >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< ïvúÔJnúæ¾ >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_ar_gl_period_from = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< NXgæ¾ >>';
  cv_debug_msg5_1         CONSTANT VARCHAR2(200) := 'gv_ym_lst_1 = ';
  cv_debug_msg5_2         CONSTANT VARCHAR2(200) := 'gv_ym_lst_2 = ';
  cv_debug_msg5_3         CONSTANT VARCHAR2(200) := 'gv_ym_lst_3 = ';
  cv_debug_msg5_4         CONSTANT VARCHAR2(200) := 'gv_ym_lst_4 = ';
  cv_debug_msg5_5         CONSTANT VARCHAR2(200) := 'gv_ym_lst_5 = ';
  cv_debug_msg5_6         CONSTANT VARCHAR2(200) := 'gv_ym_lst_6 = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< íAoAoÍ >>';
  cv_debug_msg6_1         CONSTANT VARCHAR2(200) := 'gn_delete_cnt = ';
  cv_debug_msg6_2         CONSTANT VARCHAR2(200) := 'gn_extrct_cnt = ';
  cv_debug_msg6_3         CONSTANT VARCHAR2(200) := 'gn_output_cnt = ';
  cv_debug_msg6_4         CONSTANT VARCHAR2(200) := 'gn_warn_cnt = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< úÊÎÛf[^ðíµÜµ½ >>';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< ÊÎÛf[^ðíµÜµ½ >>';
  cv_debug_msg_d_acct     CONSTANT VARCHAR2(200) := '<< úÊÚqÊæ¾o^ >>';
  cv_debug_msg_d_emp      CONSTANT VARCHAR2(200) := '<< úÊcÆõÊæ¾o^ >>';
  cv_debug_msg_d_grp      CONSTANT VARCHAR2(200) := '<< úÊcÆO[vÊæ¾o^ >>';
  cv_debug_msg_d_base     CONSTANT VARCHAR2(200) := '<< úÊ_^ÛÊæ¾o^ >>';
  cv_debug_msg_d_area     CONSTANT VARCHAR2(200) := '<< úÊnæcÆ^Êæ¾o^ >>';
  cv_debug_msg_m_acct     CONSTANT VARCHAR2(200) := '<< ÊÚqÊæ¾o^ >>';
  cv_debug_msg_m_emp      CONSTANT VARCHAR2(200) := '<< ÊcÆõÊæ¾o^ >>';
  cv_debug_msg_m_grp      CONSTANT VARCHAR2(200) := '<< ÊcÆO[vÊæ¾o^ >>';
  cv_debug_msg_m_base     CONSTANT VARCHAR2(200) := '<< Ê_^ÛÊæ¾o^ >>';
  cv_debug_msg_m_area     CONSTANT VARCHAR2(200) := '<< ÊnæcÆ^Êæ¾o^ >>';
  cv_debug_msg_rollback   CONSTANT VARCHAR2(200) := '<< [obNµÜµ½ >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< J[\ðI[vµÜµ½ >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< J[\ðN[YµÜµ½ >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< áOàÅJ[\ðN[YµÜµ½ >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'insert_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'othersáO';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- e[uEr[¼
  cv_xxcso_sum_visit_sale_rep  CONSTANT VARCHAR2(200) := 'KâãvæÇ\T}e[u';
  cv_day_acct_data             CONSTANT VARCHAR2(200) := 'úÊÚqÊf[^';
  cv_day_acct                  CONSTANT VARCHAR2(200) := 'iúÊÚqÊj';
  cv_day_emp                   CONSTANT VARCHAR2(200) := 'iúÊcÆõÊj';
  cv_day_group                 CONSTANT VARCHAR2(200) := 'iúÊcÆO[vÊj';
  cv_day_base                  CONSTANT VARCHAR2(200) := 'iúÊ_Êj';
  cv_day_area                  CONSTANT VARCHAR2(200) := 'iúÊnæcÆÊj';
  cv_mon_acct                  CONSTANT VARCHAR2(200) := 'iÊÚqÊj';
  cv_mon_emp                   CONSTANT VARCHAR2(200) := 'iÊcÆõÊj';
  cv_mon_group                 CONSTANT VARCHAR2(200) := 'iÊcÆO[vÊj';
  cv_mon_base                  CONSTANT VARCHAR2(200) := 'iÊ_Êj';
  cv_mon_area                  CONSTANT VARCHAR2(200) := 'iÊnæcÆÊj';
  -- úæª
  cv_month_date_div_mon        CONSTANT VARCHAR2(1) := '1';       -- u1vÊ
  cv_month_date_div_day        CONSTANT VARCHAR2(1) := '2';       -- u2vúÊ
  -- Úqæª
  cv_customer_class_code_10    CONSTANT VARCHAR2(2) := '10';       -- u10vÚq
  cv_customer_class_code_12    CONSTANT VARCHAR2(2) := '12';       -- u12vãlÚq
  cv_customer_class_code_15    CONSTANT VARCHAR2(2) := '15';       -- u15vñ
  cv_customer_class_code_16    CONSTANT VARCHAR2(2) := '16';       -- u16vâ® æ
  cv_customer_class_code_17    CONSTANT VARCHAR2(2) := '17';       -- u17vvæ
  cv_customer_class_code_13    CONSTANT VARCHAR2(2) := '13';       -- u13v@lÚq
  cv_customer_class_code_14    CONSTANT VARCHAR2(2) := '14';       -- u14v|àÇÚq
  -- ÚqXe[^X
  cv_customer_status_10        CONSTANT VARCHAR2(2) := '10';       -- u10vMCóâ
  cv_customer_status_20        CONSTANT VARCHAR2(2) := '20';       -- u20vMC
  cv_customer_status_25        CONSTANT VARCHAR2(2) := '25';       -- u25vSPÏÏ
  cv_customer_status_30        CONSTANT VARCHAR2(2) := '30';       -- u30v³FÏ
  cv_customer_status_40        CONSTANT VARCHAR2(2) := '40';       -- u40vÚq
  cv_customer_status_50        CONSTANT VARCHAR2(2) := '50';       -- u50vx~
  cv_customer_status_80        CONSTANT VARCHAR2(2) := '80';       -- u80vX³Â 
  cv_customer_status_90        CONSTANT VARCHAR2(2) := '90';       -- u90v~Ï
  cv_customer_status_99        CONSTANT VARCHAR2(2) := '99';       -- u99vÎÛO
  -- KâÎÛæª
  cv_vist_target_div_1         CONSTANT VARCHAR2(1) := '1';        -- u1v
  -- êÊ^©Ì@^MC
  cv_emp_div_gen               CONSTANT VARCHAR2(1) := '1';        -- u1vêÊ
  cv_emp_div_jihan             CONSTANT VARCHAR2(1) := '2';        -- u2v©Ì@
  cv_emp_div_mc                CONSTANT VARCHAR2(1) := '3';        -- u3vMC
  -- [i`Ôæª
  cv_delivery_pattern_cls_5    CONSTANT VARCHAR2(1) := '5';        -- u5v¼_qÉã
  -- LøKâæª
  cv_eff_visit_flag_1          CONSTANT VARCHAR2(1) := '1';        -- u1vLø
  -- WvgDíÞ
  cv_sum_org_type_accnt        CONSTANT VARCHAR2(1) := '1';        -- u1vÚqR[h
  cv_sum_org_type_emp          CONSTANT VARCHAR2(1) := '2';        -- u2v]ÆõÔ
  cv_sum_org_type_group        CONSTANT VARCHAR2(1) := '3';        -- u3vcÆO[v
  cv_sum_org_type_dept         CONSTANT VARCHAR2(1) := '4';        -- u4våR[h
  cv_sum_org_type_area         CONSTANT VARCHAR2(1) := '5';        -- u5vnæcÆR[h
  -- VK|Cgæª
  cv_new_point_div_1           CONSTANT VARCHAR2(1) := '1';        -- u1vVK
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- æª
  cv_process_div_ins           CONSTANT VARCHAR2(1) := '1';        -- u1vì¬
  cv_process_div_del           CONSTANT VARCHAR2(1) := '9';        -- u9ví
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
  gn_delete_cnt        NUMBER;              -- í
  gn_extrct_cnt        NUMBER;              -- o
  gn_output_cnt        NUMBER;              -- oÍ
  -- Æ±ú
  gd_process_date      DATE;
  -- ARïvúÔJnú
  gd_ar_gl_period_from DATE;
  -- NXg
  gv_ym_lst_1          VARCHAR2(8);
  gv_ym_lst_2          VARCHAR2(8);
  gv_ym_lst_3          VARCHAR2(8);
  gv_ym_lst_4          VARCHAR2(8);
  gv_ym_lst_5          VARCHAR2(8);
  gv_ym_lst_6          VARCHAR2(8);
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- p[^i[p
  gv_prm_process_div   VARCHAR2(1);         -- æª
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- [U[è`J[\^
  -- ===============================
  -- úÊÚqÊf[^æ¾pJ[\
  CURSOR g_get_day_acct_data_cur
  IS
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--  SELECT
--    union_res.sum_org_code                sum_org_code         -- ÚqR[h
--    union_res.group_base_code             group_base_code      -- O[v_R[h
--   ,union_res.gvm_type                    gvm_type             -- êÊ^©Ì@^lb
--   ,MAX(union_res.cust_new_num      )     cust_new_num         -- ÚqiVKj
--   ,MAX(union_res.cust_vd_new_num   )     cust_vd_new_num      -- ÚqiVDFVKj
--   ,MAX(union_res.cust_other_new_num)     cust_other_new_num   -- ÚqiVDÈOFVKj
--   ,union_res.sales_date                  sales_date           -- ÌNú^ÌN
--   ,MAX(union_res.tgt_amt              )  tgt_amt              -- ãvæ
--   ,MAX(union_res.tgt_vd_amt           )  tgt_vd_amt           -- ãvæiVDj
--   ,MAX(union_res.tgt_other_amt        )  tgt_other_amt        -- ãvæiVDÈOj
--   ,MAX(union_res.tgt_vis_num          )  tgt_vis_num          -- Kâvæ
--   ,MAX(union_res.tgt_vis_vd_num       )  tgt_vis_vd_num       -- KâvæiVDj
--   ,MAX(union_res.tgt_vis_other_num    )  tgt_vis_other_num    -- KâvæiVDÈOj
--   ,MAX(union_res.rslt_amt             )  rslt_amt             -- ãÀÑ
--   ,MAX(union_res.rslt_new_amt         )  rslt_new_amt         -- ãÀÑiVKj
--   ,MAX(union_res.rslt_vd_new_amt      )  rslt_vd_new_amt      -- ãÀÑiVDFVKj
--   ,MAX(union_res.rslt_vd_amt          )  rslt_vd_amt          -- ãÀÑiVDj
--   ,MAX(union_res.rslt_other_new_amt   )  rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--   ,MAX(union_res.rslt_other_amt       )  rslt_other_amt       -- ãÀÑiVDÈOj
--   ,MAX(union_res.rslt_center_amt      )  rslt_center_amt      -- à¼_QãÀÑ
--   ,MAX(union_res.rslt_center_vd_amt   )  rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--   ,MAX(union_res.rslt_center_other_amt)  rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--   ,MAX(union_res.vis_num              )  vis_num              -- KâÀÑ
--   ,MAX(union_res.vis_new_num          )  vis_new_num          -- KâÀÑiVKj
--   ,MAX(union_res.vis_vd_new_num       )  vis_vd_new_num       -- KâÀÑiVDFVKj
--   ,MAX(union_res.vis_vd_num           )  vis_vd_num           -- KâÀÑiVDj
--   ,MAX(union_res.vis_other_new_num    )  vis_other_new_num    -- KâÀÑiVDÈOFVKj
--   ,MAX(union_res.vis_other_num        )  vis_other_num        -- KâÀÑiVDÈOj
--   ,MAX(union_res.vis_mc_num           )  vis_mc_num           -- KâÀÑiMCj
--   ,MAX(union_res.vis_sales_num        )  vis_sales_num        -- Lø¬
--   ,MAX(union_res.vis_a_num            )  vis_a_num            -- Kâ`
--   ,MAX(union_res.vis_b_num            )  vis_b_num            -- Kâa
--   ,MAX(union_res.vis_c_num            )  vis_c_num            -- Kâb
--   ,MAX(union_res.vis_d_num            )  vis_d_num            -- Kâc
--   ,MAX(union_res.vis_e_num            )  vis_e_num            -- Kâd
--   ,MAX(union_res.vis_f_num            )  vis_f_num            -- Kâe
--   ,MAX(union_res.vis_g_num            )  vis_g_num            -- Kâf
--   ,MAX(union_res.vis_h_num            )  vis_h_num            -- Kâg
--   ,MAX(union_res.vis_i_num            )  vis_i_num            -- Kâú@
--   ,MAX(union_res.vis_j_num            )  vis_j_num            -- Kâi
--   ,MAX(union_res.vis_k_num            )  vis_k_num            -- Kâj
--   ,MAX(union_res.vis_l_num            )  vis_l_num            -- Kâk
--   ,MAX(union_res.vis_m_num            )  vis_m_num            -- Kâl
--   ,MAX(union_res.vis_n_num            )  vis_n_num            -- Kâm
--   ,MAX(union_res.vis_o_num            )  vis_o_num            -- Kân
--   ,MAX(union_res.vis_p_num            )  vis_p_num            -- Kâo
--   ,MAX(union_res.vis_q_num            )  vis_q_num            -- Kâp
--   ,MAX(union_res.vis_r_num            )  vis_r_num            -- Kâq
--   ,MAX(union_res.vis_s_num            )  vis_s_num            -- Kâr
--   ,MAX(union_res.vis_t_num            )  vis_t_num            -- Kâs
--   ,MAX(union_res.vis_u_num            )  vis_u_num            -- Kât
--   ,MAX(union_res.vis_v_num            )  vis_v_num            -- Kâu
--   ,MAX(union_res.vis_w_num            )  vis_w_num            -- Kâv
--   ,MAX(union_res.vis_x_num            )  vis_x_num            -- Kâw
--   ,MAX(union_res.vis_y_num            )  vis_y_num            -- Kâx
--   ,MAX(union_res.vis_z_num            )  vis_z_num            -- Kây
--  FROM
--    (
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- ÚqR[h
--      ,inn_v.gvm_type                   gvm_type             -- êÊ^©Ì@^lb
--      ,inn_v.cust_new_num               cust_new_num         -- ÚqiVKj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- ÚqiVDFVKj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- ÚqiVDÈOFVKj
--      ,inn_v.sales_date                 sales_date           -- ÌNú^ÌN
--      ,inn_v.tgt_amt                    tgt_amt              -- ãvæ
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- ãvæiVDj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- ãvæiVDÈOj
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- Kâvæ
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- KâvæiVDj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- KâvæiVDÈOj
--      ,inn_v.rslt_amt                   rslt_amt             -- ãÀÑ
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- ãÀÑiVKj
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- ãÀÑiVDFVKj
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- ãÀÑiVDj
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- ãÀÑiVDÈOj
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- à¼_QãÀÑ
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--      ,inn_v.vis_num                    vis_num              -- KâÀÑ
--      ,inn_v.vis_new_num                vis_new_num          -- KâÀÑiVKj
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- KâÀÑiVDFVKj
--      ,inn_v.vis_vd_num                 vis_vd_num           -- KâÀÑiVDj
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- KâÀÑiVDÈOFVKj
--      ,inn_v.vis_other_num              vis_other_num        -- KâÀÑiVDÈOj
--      ,inn_v.vis_mc_num                 vis_mc_num           -- KâÀÑiMCj
--      ,inn_v.vis_sales_num              vis_sales_num        -- Lø¬
--      ,inn_v.vis_a_num                  vis_a_num            -- Kâ`
--      ,inn_v.vis_b_num                  vis_b_num            -- Kâa
--      ,inn_v.vis_c_num                  vis_c_num            -- Kâb
--      ,inn_v.vis_d_num                  vis_d_num            -- Kâc
--      ,inn_v.vis_e_num                  vis_e_num            -- Kâd
--      ,inn_v.vis_f_num                  vis_f_num            -- Kâe
--      ,inn_v.vis_g_num                  vis_g_num            -- Kâf
--      ,inn_v.vis_h_num                  vis_h_num            -- Kâg
--      ,inn_v.vis_i_num                  vis_i_num            -- Kâú@
--      ,inn_v.vis_j_num                  vis_j_num            -- Kâi
--      ,inn_v.vis_k_num                  vis_k_num            -- Kâj
--      ,inn_v.vis_l_num                  vis_l_num            -- Kâk
--      ,inn_v.vis_m_num                  vis_m_num            -- Kâl
--      ,inn_v.vis_n_num                  vis_n_num            -- Kâm
--      ,inn_v.vis_o_num                  vis_o_num            -- Kân
--      ,inn_v.vis_p_num                  vis_p_num            -- Kâo
--      ,inn_v.vis_q_num                  vis_q_num            -- Kâp
--      ,inn_v.vis_r_num                  vis_r_num            -- Kâq
--      ,inn_v.vis_s_num                  vis_s_num            -- Kâr
--      ,inn_v.vis_t_num                  vis_t_num            -- Kâs
--      ,inn_v.vis_u_num                  vis_u_num            -- Kât
--      ,inn_v.vis_v_num                  vis_v_num            -- Kâu
--      ,inn_v.vis_w_num                  vis_w_num            -- Kâv
--      ,inn_v.vis_x_num                  vis_x_num            -- Kâw
--      ,inn_v.vis_y_num                  vis_y_num            -- Kâx
--      ,inn_v.vis_z_num                  vis_z_num            -- Kây
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- ÚqR[h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- êÊ^©Ì@^lb
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMMDD') = xasp.plan_date
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- ÚqiVKj
--         ,xasp.plan_date                   sales_date           -- ÌNú^ÌN
--         ,xasp.sales_plan_day_amt          tgt_amt              -- ãvæ
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_day_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- Kâvæ
--         ,NULL                             rslt_amt             -- ãÀÑ
--         ,NULL                             rslt_new_amt         -- ãÀÑiVKj
--         ,NULL                             rslt_vd_new_amt      -- ãÀÑiVDFVKj
--         ,NULL                             rslt_vd_amt          -- ãÀÑiVDj
--         ,NULL                             rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--         ,NULL                             rslt_other_amt       -- ãÀÑiVDÈOj
--         ,NULL                             rslt_center_amt      -- à¼_QãÀÑ
--         ,NULL                             rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--         ,NULL                             rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--         ,NULL                             vis_num              -- KâÀÑ
--         ,NULL                             vis_new_num          -- KâÀÑiVKj
--         ,NULL                             vis_vd_new_num       -- KâÀÑiVDFVKj
--         ,NULL                             vis_vd_num           -- KâÀÑiVDj
--         ,NULL                             vis_other_new_num    -- KâÀÑiVDÈOFVKj
--         ,NULL                             vis_other_num        -- KâÀÑiVDÈOj
--         ,NULL                             vis_mc_num           -- KâÀÑiMCj
--         ,NULL                             vis_sales_num        -- Lø¬
--         ,NULL                             vis_a_num            -- Kâ`
--         ,NULL                             vis_b_num            -- Kâa
--         ,NULL                             vis_c_num            -- Kâb
--         ,NULL                             vis_d_num            -- Kâc
--         ,NULL                             vis_e_num            -- Kâd
--         ,NULL                             vis_f_num            -- Kâe
--         ,NULL                             vis_g_num            -- Kâf
--         ,NULL                             vis_h_num            -- Kâg
--         ,NULL                             vis_i_num            -- Kâú@
--         ,NULL                             vis_j_num            -- Kâi
--         ,NULL                             vis_k_num            -- Kâj
--         ,NULL                             vis_l_num            -- Kâk
--         ,NULL                             vis_m_num            -- Kâl
--         ,NULL                             vis_n_num            -- Kâm
--         ,NULL                             vis_o_num            -- Kân
--         ,NULL                             vis_p_num            -- Kâo
--         ,NULL                             vis_q_num            -- Kâp
--         ,NULL                             vis_r_num            -- Kâq
--         ,NULL                             vis_s_num            -- Kâr
--         ,NULL                             vis_t_num            -- Kâs
--         ,NULL                             vis_u_num            -- Kât
--         ,NULL                             vis_v_num            -- Kâu
--         ,NULL                             vis_w_num            -- Kâv
--         ,NULL                             vis_x_num            -- Kâw
--         ,NULL                             vis_y_num            -- Kâx
--         ,NULL                             vis_z_num            -- Kây
--        FROM
--          xxcso_cust_accounts_v xcav  -- Úq}X^r[
--         ,xxcso_account_sales_plans xasp  -- ÚqÊãvæe[u
--         ,xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
--        WHERE  xcav.account_number = xasp.account_number  -- ÚqR[h
--          AND  xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
--                                  AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- Nú
--          AND  xasp.month_date_div = cv_month_date_div_day  -- úæª
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- ÚqÊãvæe[uiúÊj
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- ÚqR[h
--      ,inn_v.gvm_type                   gvm_type             -- êÊ^©Ì@^lb
--      ,inn_v.cust_new_num               cust_new_num         -- ÚqiVKj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- ÚqiVDFVKj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- ÚqiVDÈOFVKj
--      ,inn_v.sales_date                 sales_date           -- ÌNú^ÌN
--      ,inn_v.tgt_amt                    tgt_amt              -- ãvæ
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- ãvæiVDj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- ãvæiVDÈOj
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- Kâvæ
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- KâvæiVDj
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- KâvæiVDÈOj
--      ,inn_v.rslt_amt                   rslt_amt             -- ãÀÑ
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- ãÀÑiVKj
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- ãÀÑiVDFVKj
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- ãÀÑiVDj
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- ãÀÑiVDÈOj
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- à¼_QãÀÑ
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--      ,inn_v.vis_num                    vis_num              -- KâÀÑ
--      ,inn_v.vis_new_num                vis_new_num          -- KâÀÑiVKj
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- KâÀÑiVDFVKj
--      ,inn_v.vis_vd_num                 vis_vd_num           -- KâÀÑiVDj
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- KâÀÑiVDÈOFVKj
--      ,inn_v.vis_other_num              vis_other_num        -- KâÀÑiVDÈOj
--      ,inn_v.vis_mc_num                 vis_mc_num           -- KâÀÑiMCj
--      ,inn_v.vis_sales_num              vis_sales_num        -- Lø¬
--      ,inn_v.vis_a_num                  vis_a_num            -- Kâ`
--      ,inn_v.vis_b_num                  vis_b_num            -- Kâa
--      ,inn_v.vis_c_num                  vis_c_num            -- Kâb
--      ,inn_v.vis_d_num                  vis_d_num            -- Kâc
--      ,inn_v.vis_e_num                  vis_e_num            -- Kâd
--      ,inn_v.vis_f_num                  vis_f_num            -- Kâe
--      ,inn_v.vis_g_num                  vis_g_num            -- Kâf
--      ,inn_v.vis_h_num                  vis_h_num            -- Kâg
--      ,inn_v.vis_i_num                  vis_i_num            -- Kâú@
--      ,inn_v.vis_j_num                  vis_j_num            -- Kâi
--      ,inn_v.vis_k_num                  vis_k_num            -- Kâj
--      ,inn_v.vis_l_num                  vis_l_num            -- Kâk
--      ,inn_v.vis_m_num                  vis_m_num            -- Kâl
--      ,inn_v.vis_n_num                  vis_n_num            -- Kâm
--      ,inn_v.vis_o_num                  vis_o_num            -- Kân
--      ,inn_v.vis_p_num                  vis_p_num            -- Kâo
--      ,inn_v.vis_q_num                  vis_q_num            -- Kâp
--      ,inn_v.vis_r_num                  vis_r_num            -- Kâq
--      ,inn_v.vis_s_num                  vis_s_num            -- Kâr
--      ,inn_v.vis_t_num                  vis_t_num            -- Kâs
--      ,inn_v.vis_u_num                  vis_u_num            -- Kât
--      ,inn_v.vis_v_num                  vis_v_num            -- Kâu
--      ,inn_v.vis_w_num                  vis_w_num            -- Kâv
--      ,inn_v.vis_x_num                  vis_x_num            -- Kâw
--      ,inn_v.vis_y_num                  vis_y_num            -- Kâx
--      ,inn_v.vis_z_num                  vis_z_num            -- Kây
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- ÚqR[h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- êÊ^©Ì@^lb
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMM') = xasp.year_month
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- ÚqiVKj
--         ,xasp.year_month || '01'          sales_date           -- ÌNú^ÌN
--         ,xasp.sales_plan_month_amt        tgt_amt              -- ãvæ
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_month_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- Kâvæ
--         ,NULL                             rslt_amt             -- ãÀÑ
--         ,NULL                             rslt_new_amt         -- ãÀÑiVKj
--         ,NULL                             rslt_vd_new_amt      -- ãÀÑiVDFVKj
--         ,NULL                             rslt_vd_amt          -- ãÀÑiVDj
--         ,NULL                             rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--         ,NULL                             rslt_other_amt       -- ãÀÑiVDÈOj
--         ,NULL                             rslt_center_amt      -- à¼_QãÀÑ
--         ,NULL                             rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--         ,NULL                             rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--         ,NULL                             vis_num              -- KâÀÑ
--         ,NULL                             vis_new_num          -- KâÀÑiVKj
--         ,NULL                             vis_vd_new_num       -- KâÀÑiVDFVKj
--         ,NULL                             vis_vd_num           -- KâÀÑiVDj
--         ,NULL                             vis_other_new_num    -- KâÀÑiVDÈOFVKj
--         ,NULL                             vis_other_num        -- KâÀÑiVDÈOj
--         ,NULL                             vis_mc_num           -- KâÀÑiMCj
--         ,NULL                             vis_sales_num        -- Lø¬
--         ,NULL                             vis_a_num            -- Kâ`
--         ,NULL                             vis_b_num            -- Kâa
--         ,NULL                             vis_c_num            -- Kâb
--         ,NULL                             vis_d_num            -- Kâc
--         ,NULL                             vis_e_num            -- Kâd
--         ,NULL                             vis_f_num            -- Kâe
--         ,NULL                             vis_g_num            -- Kâf
--         ,NULL                             vis_h_num            -- Kâg
--         ,NULL                             vis_i_num            -- Kâú@
--         ,NULL                             vis_j_num            -- Kâi
--         ,NULL                             vis_k_num            -- Kâj
--         ,NULL                             vis_l_num            -- Kâk
--         ,NULL                             vis_m_num            -- Kâl
--         ,NULL                             vis_n_num            -- Kâm
--         ,NULL                             vis_o_num            -- Kân
--         ,NULL                             vis_p_num            -- Kâo
--         ,NULL                             vis_q_num            -- Kâp
--         ,NULL                             vis_r_num            -- Kâq
--         ,NULL                             vis_s_num            -- Kâr
--         ,NULL                             vis_t_num            -- Kâs
--         ,NULL                             vis_u_num            -- Kât
--         ,NULL                             vis_v_num            -- Kâu
--         ,NULL                             vis_w_num            -- Kâv
--         ,NULL                             vis_x_num            -- Kâw
--         ,NULL                             vis_y_num            -- Kâx
--         ,NULL                             vis_z_num            -- Kây
--        FROM
--          xxcso_cust_accounts_v xcav  -- Úq}X^r[
--         ,xxcso_account_sales_plans xasp  -- ÚqÊãvæe[u
--         ,xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
--        WHERE  xcav.account_number = xasp.account_number  -- ÚqR[h
--          AND  xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')
--                                   AND TO_CHAR(gd_process_date, 'YYYYMM')  -- N
--          AND  xasp.month_date_div = cv_month_date_div_mon  -- úæª
--          AND  EXISTS
--               (
--                SELECT  xasp_m.account_number account_number
--                FROM  xxcso_account_sales_plans xasp_m  -- ÚqÊãvæe[uiÊj
--                WHERE  xasp_m.account_number = xasp.account_number  -- ÚqR[h
--                  AND  xasp_m.year_month = xasp.year_month  -- N
--                  AND  xasp.month_date_div = cv_month_date_div_day  -- úæª
--               )
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- ÚqÊãvæe[uiÊj
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- ÚqR[h
--      ,inn_v.gvm_type                   gvm_type             -- êÊ^©Ì@^lb
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- ÚqiVKj
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- ÚqiVDFVKj
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- ÚqiVDÈOFVKj
--      ,inn_v.sales_date                 sales_date           -- ÌNú^ÌN
--      ,NULL                             tgt_amt              -- ãvæ
--      ,NULL                             tgt_vd_amt           -- ãvæiVDj
--      ,NULL                             tgt_other_amt        -- ãvæiVDÈOj
--      ,NULL                             tgt_vis_num          -- Kâvæ
--      ,NULL                             tgt_vis_vd_num       -- KâvæiVDj
--      ,NULL                             tgt_vis_other_num    -- KâvæiVDÈOj
--      ,SUM(inn_v.pure_amount)           rslt_amt             -- ãÀÑ
--      ,SUM(
--           CASE WHEN (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_new_amt         -- ãÀÑiVKj
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_vd_new_amt      -- ãÀÑiVDFVKj
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN  inn_v.pure_amount
--           END
--          )                            rslt_vd_amt          -- ãÀÑiVDj
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_amt       -- ãÀÑiVDÈOj
--      ,SUM(inn_v.pure_amount_2)         rslt_center_amt      -- à¼_QãÀÑ
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--      ,NULL                             vis_num              -- KâÀÑ
--      ,NULL                             vis_new_num          -- KâÀÑiVKj
--      ,NULL                             vis_vd_new_num       -- KâÀÑiVDFVKj
--      ,NULL                             vis_vd_num           -- KâÀÑiVDj
--      ,NULL                             vis_other_new_num    -- KâÀÑiVDÈOFVKj
--      ,NULL                             vis_other_num        -- KâÀÑiVDÈOj
--      ,NULL                             vis_mc_num           -- KâÀÑiMCj
--      ,NULL                             vis_sales_num        -- Lø¬
--      ,NULL                             vis_a_num            -- Kâ`
--      ,NULL                             vis_b_num            -- Kâa
--      ,NULL                             vis_c_num            -- Kâb
--      ,NULL                             vis_d_num            -- Kâc
--      ,NULL                             vis_e_num            -- Kâd
--      ,NULL                             vis_f_num            -- Kâe
--      ,NULL                             vis_g_num            -- Kâf
--      ,NULL                             vis_h_num            -- Kâg
--      ,NULL                             vis_i_num            -- Kâú@
--      ,NULL                             vis_j_num            -- Kâi
--      ,NULL                             vis_k_num            -- Kâj
--      ,NULL                             vis_l_num            -- Kâk
--      ,NULL                             vis_m_num            -- Kâl
--      ,NULL                             vis_n_num            -- Kâm
--      ,NULL                             vis_o_num            -- Kân
--      ,NULL                             vis_p_num            -- Kâo
--      ,NULL                             vis_q_num            -- Kâp
--      ,NULL                             vis_r_num            -- Kâq
--      ,NULL                             vis_s_num            -- Kâr
--      ,NULL                             vis_t_num            -- Kâs
--      ,NULL                             vis_u_num            -- Kât
--      ,NULL                             vis_v_num            -- Kâu
--      ,NULL                             vis_w_num            -- Kâv
--      ,NULL                             vis_x_num            -- Kâw
--      ,NULL                             vis_y_num            -- Kâx
--      ,NULL                             vis_z_num            -- Kây
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- ÚqR[h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- êÊ^©Ì@^lb
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xsv.delivery_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- ÚqiVKj
--         ,TO_CHAR(xsv.delivery_date, 'YYYYMMDD')
--                                           sales_date           -- ÌNú^ÌN
--         ,xsv.pure_amount                  pure_amount          -- {Ìàz
--         ,CASE WHEN xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--               THEN xsv.pure_amount
--               ELSE NULL
--          END                              pure_amount_2        -- {Ìàz2
--        FROM
--          xxcso_cust_accounts_v xcav  -- Úq}X^r[
--         ,xxcso_sales_v xsv  -- ãÀÑr[
--         ,xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
--        WHERE  xcav.account_number = xsv.account_number  -- ÚqR[h
--          AND  xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                     AND gd_process_date  -- [iú
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     -- ãÀÑVIEW
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- ÚqR[h
--      ,inn_v.gvm_type                   gvm_type             -- êÊ^©Ì@^lb
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- ÚqiVKj
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- ÚqiVDFVKj
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- ÚqiVDÈOFVKj
--      ,inn_v.sales_date                 sales_date           -- ÌNú^ÌN
--      ,NULL                             tgt_amt              -- ãvæ
--      ,NULL                             tgt_vd_amt           -- ãvæiVDj
--      ,NULL                             tgt_other_amt        -- ãvæiVDÈOj
--      ,NULL                             tgt_vis_num          -- Kâvæ
--      ,NULL                             tgt_vis_vd_num       -- KâvæiVDj
--      ,NULL                             tgt_vis_other_num    -- KâvæiVDÈOj
--      ,NULL                             rslt_amt             -- ãÀÑ
--      ,NULL                             rslt_new_amt         -- ãÀÑiVKj
--      ,NULL                             rslt_vd_new_amt      -- ãÀÑiVDFVKj
--      ,NULL                             rslt_vd_amt          -- ãÀÑiVDj
--      ,NULL                             rslt_other_new_amt   -- ãÀÑiVDÈOFVKj
--      ,NULL                             rslt_other_amt       -- ãÀÑiVDÈOj
--      ,NULL                             rslt_center_amt      -- à¼_QãÀÑ
--      ,NULL                             rslt_center_vd_amt   -- à¼_QãÀÑiVDj
--      ,NULL                             rslt_center_other_amt-- à¼_QãÀÑiVDÈOj
--      ,COUNT(inn_v.task_id)             vis_num              -- KâÀÑ
--      ,COUNT
--            (
--             CASE WHEN (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_new_num          -- KâÀÑiVKj
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_new_num       -- KâÀÑiVDFVKj
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_num           -- KâÀÑiVDj
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_new_num    -- KâÀÑiVDÈOFVKj
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_num        -- KâÀÑiVDÈOj
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_mc)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_mc_num           -- KâÀÑiMCj
--      ,COUNT
--            (
--             CASE WHEN (
--                        inn_v.eff_visit_flag = cv_eff_visit_flag_1
--                       )
--                  THEN  inn_v.task_id
--                  ELSE  NULL
--             END
--            )                           vis_sales_num        -- Lø¬
--      ,SUM(inn_v.vis_a_num)             vis_a_num            -- Kâ`
--      ,SUM(inn_v.vis_b_num)             vis_b_num            -- Kâa
--      ,SUM(inn_v.vis_c_num)             vis_c_num            -- Kâb
--      ,SUM(inn_v.vis_d_num)             vis_d_num            -- Kâc
--      ,SUM(inn_v.vis_e_num)             vis_e_num            -- Kâd
--      ,SUM(inn_v.vis_f_num)             vis_f_num            -- Kâe
--      ,SUM(inn_v.vis_g_num)             vis_g_num            -- Kâf
--      ,SUM(inn_v.vis_h_num)             vis_h_num            -- Kâg
--      ,SUM(inn_v.vis_i_num)             vis_i_num            -- Kâú@
--      ,SUM(inn_v.vis_j_num)             vis_j_num            -- Kâi
--      ,SUM(inn_v.vis_k_num)             vis_k_num            -- Kâj
--      ,SUM(inn_v.vis_l_num)             vis_l_num            -- Kâk
--      ,SUM(inn_v.vis_m_num)             vis_m_num            -- Kâl
--      ,SUM(inn_v.vis_n_num)             vis_n_num            -- Kâm
--      ,SUM(inn_v.vis_o_num)             vis_o_num            -- Kân
--      ,SUM(inn_v.vis_p_num)             vis_p_num            -- Kâo
--      ,SUM(inn_v.vis_q_num)             vis_q_num            -- Kâp
--      ,SUM(inn_v.vis_r_num)             vis_r_num            -- Kâq
--      ,SUM(inn_v.vis_s_num)             vis_s_num            -- Kâr
--      ,SUM(inn_v.vis_t_num)             vis_t_num            -- Kâs
--      ,SUM(inn_v.vis_u_num)             vis_u_num            -- Kât
--      ,SUM(inn_v.vis_v_num)             vis_v_num            -- Kâu
--      ,SUM(inn_v.vis_w_num)             vis_w_num            -- Kâv
--      ,SUM(inn_v.vis_x_num)             vis_x_num            -- Kâw
--      ,SUM(inn_v.vis_y_num)             vis_y_num            -- Kâx
--      ,SUM(inn_v.vis_z_num)             vis_z_num            -- Kây
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- ÚqR[h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- êÊ^©Ì@^lb
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xvv.actual_end_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- ÚqiVKj
--         ,TO_CHAR(xvv.actual_end_date, 'YYYYMMDD')
--                                           sales_date           -- ÌNú^ÌN
--         ,xvv.task_id                      task_id              -- ^XNID
--         ,xvv.eff_visit_flag               eff_visit_flag       -- LøKâæª
--         ,xvv.visit_num_a                  vis_a_num            -- Kâ`
--         ,xvv.visit_num_b                  vis_b_num            -- Kâa
--         ,xvv.visit_num_c                  vis_c_num            -- Kâb
--         ,xvv.visit_num_d                  vis_d_num            -- Kâc
--         ,xvv.visit_num_e                  vis_e_num            -- Kâd
--         ,xvv.visit_num_f                  vis_f_num            -- Kâe
--         ,xvv.visit_num_g                  vis_g_num            -- Kâf
--         ,xvv.visit_num_h                  vis_h_num            -- Kâg
--         ,xvv.visit_num_i                  vis_i_num            -- Kâú@
--         ,xvv.visit_num_j                  vis_j_num            -- Kâi
--         ,xvv.visit_num_k                  vis_k_num            -- Kâj
--         ,xvv.visit_num_l                  vis_l_num            -- Kâk
--         ,xvv.visit_num_m                  vis_m_num            -- Kâl
--         ,xvv.visit_num_n                  vis_n_num            -- Kâm
--         ,xvv.visit_num_o                  vis_o_num            -- Kân
--         ,xvv.visit_num_p                  vis_p_num            -- Kâo
--         ,xvv.visit_num_q                  vis_q_num            -- Kâp
--         ,xvv.visit_num_r                  vis_r_num            -- Kâq
--         ,xvv.visit_num_s                  vis_s_num            -- Kâr
--         ,xvv.visit_num_t                  vis_t_num            -- Kâs
--         ,xvv.visit_num_u                  vis_u_num            -- Kât
--         ,xvv.visit_num_v                  vis_v_num            -- Kâu
--         ,xvv.visit_num_w                  vis_w_num            -- Kâv
--         ,xvv.visit_num_x                  vis_x_num            -- Kâw
--         ,xvv.visit_num_y                  vis_y_num            -- Kâx
--         ,xvv.visit_num_z                  vis_z_num            -- Kây
--        FROM
--          xxcso_cust_accounts_v xcav  -- Úq}X^r[
--         ,xxcso_visit_v xvv  -- KâÀÑr[
--         ,xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
--        WHERE  xcav.party_id = xvv.party_id  -- p[eBID
--          AND  TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
--                                              AND gd_process_date  -- ÀÑI¹ú
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- Úqæª
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     ) union_res
--  GROUP BY
--    union_res.sum_org_code                         -- ÚqR[h
--   ,union_res.gvm_type                             -- êÊ^©Ì@^lb
--   ,union_res.sales_date                           -- ÌNú^ÌN
/* 20090828_abe_0001194 START*/
    SELECT  /*+ FIRST_ROWS */
            inn_v.sum_org_code                 sum_org_code
--    SELECT  inn_v.sum_org_code                 sum_org_code
/* 20090828_abe_0001194 END*/
           ,inn_v.group_base_code              group_base_code
           ,inn_v.sales_date                   sales_date
           ,NULL                               gvm_type
           ,NULL                               cust_new_num
           ,NULL                               cust_vd_new_num
           ,NULL                               cust_other_new_num
           ,SUM(inn_v.rslt_amt)                rslt_amt
           ,NULL                               rslt_new_amt
           ,NULL                               rslt_vd_new_amt
           ,NULL                               rslt_vd_amt
           ,NULL                               rslt_other_new_amt
           ,NULL                               rslt_other_amt
           ,SUM(inn_v.rslt_center_amt)         rslt_center_amt
           ,NULL                               rslt_center_vd_amt
           ,NULL                               rslt_center_other_amt
           ,MAX(inn_v.tgt_amt)                 tgt_amt
           ,NULL                               tgt_vd_amt
           ,NULL                               tgt_other_amt
           ,MAX(inn_v.vis_num)                 vis_num
           ,NULL                               vis_new_num
           ,NULL                               vis_vd_new_num
           ,NULL                               vis_vd_num
           ,NULL                               vis_other_new_num
           ,NULL                               vis_other_num
           ,NULL                               vis_mc_num
           ,MAX(inn_v.vis_sales_num)           vis_sales_num
           ,NULL                               tgt_vis_num
           ,NULL                               tgt_vis_vd_num
           ,NULL                               tgt_vis_other_num
           ,MAX(inn_v.vis_a_num)               vis_a_num
           ,MAX(inn_v.vis_b_num)               vis_b_num
           ,MAX(inn_v.vis_c_num)               vis_c_num
           ,MAX(inn_v.vis_d_num)               vis_d_num
           ,MAX(inn_v.vis_e_num)               vis_e_num
           ,MAX(inn_v.vis_f_num)               vis_f_num
           ,MAX(inn_v.vis_g_num)               vis_g_num
           ,MAX(inn_v.vis_h_num)               vis_h_num
           ,MAX(inn_v.vis_i_num)               vis_i_num
           ,MAX(inn_v.vis_j_num)               vis_j_num
           ,MAX(inn_v.vis_k_num)               vis_k_num
           ,MAX(inn_v.vis_l_num)               vis_l_num
           ,MAX(inn_v.vis_m_num)               vis_m_num
           ,MAX(inn_v.vis_n_num)               vis_n_num
           ,MAX(inn_v.vis_o_num)               vis_o_num
           ,MAX(inn_v.vis_p_num)               vis_p_num
           ,MAX(inn_v.vis_q_num)               vis_q_num
           ,MAX(inn_v.vis_r_num)               vis_r_num
           ,MAX(inn_v.vis_s_num)               vis_s_num
           ,MAX(inn_v.vis_t_num)               vis_t_num
           ,MAX(inn_v.vis_u_num)               vis_u_num
           ,MAX(inn_v.vis_v_num)               vis_v_num
           ,MAX(inn_v.vis_w_num)               vis_w_num
           ,MAX(inn_v.vis_x_num)               vis_x_num
           ,MAX(inn_v.vis_y_num)               vis_y_num
           ,MAX(inn_v.vis_z_num)               vis_z_num
    FROM    (
             --------------------------------
             -- ÚqÊãvæiúÊj
             --------------------------------
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.plan_date                       sales_date
                    ,xasp.sales_plan_day_amt              tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMMDD')
                                        AND TO_CHAR(LAST_DAY(gd_process_date),'YYYYMMDD') 
               AND   xasp.month_date_div = cv_month_date_div_day
               AND   xasp.sales_plan_day_amt IS NOT NULL
             --------------------------------
             -- ÚqÊãvæiÊÌÝj
             --------------------------------
             UNION ALL
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.year_month || '01'              sales_date
                    ,xasp.sales_plan_month_amt            tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMM')
                                         AND TO_CHAR(gd_process_date,'YYYYMM')
               AND   xasp.month_date_div = cv_month_date_div_mon
               AND   NOT EXISTS (
                       -- úÊvæª éêÍoÍµÈ¢
                       SELECT  1
                       FROM    xxcso_account_sales_plans  xaspd
                       WHERE   xaspd.base_code      = xasp.base_code
                         AND   xaspd.account_number = xasp.account_number
                         AND   xaspd.month_date_div = cv_month_date_div_day
                         AND   xaspd.year_month     = xasp.year_month
                         AND   xaspd.sales_plan_day_amt IS NOT NULL
                     )
             --------------------------------
             -- ÚqÊãÀÑWv
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_{Ò®_02763
--             SELECT  xcav.sale_base_code                     group_base_code
             SELECT  (SELECT xcca.sale_base_code
                      FROM    xxcmm_cust_accounts xcca
                      WHERE   xcca.customer_code = xsv2.account_number
                      AND     rownum = 1
                      )          group_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_{Ò®_02763
                    ,xsv2.account_number                     sum_org_code
                    ,TO_CHAR(xsv2.delivery_date,'YYYYMMDD')  sales_date
                    ,NULL                                    tgt_amt
                    ,xsv2.pure_amount                        rslt_amt
                    ,(CASE
                        WHEN (xsv2.other_flag = 'Y') THEN
                          xsv2.pure_amount
                        ELSE
                          NULL
                      END
                     )                                       rslt_center_amt
                    ,NULL                                    vis_num
                    ,NULL                                    vis_sales_num
                    ,NULL                                    vis_a_num
                    ,NULL                                    vis_b_num
                    ,NULL                                    vis_c_num
                    ,NULL                                    vis_d_num
                    ,NULL                                    vis_e_num
                    ,NULL                                    vis_f_num
                    ,NULL                                    vis_g_num
                    ,NULL                                    vis_h_num
                    ,NULL                                    vis_i_num
                    ,NULL                                    vis_j_num
                    ,NULL                                    vis_k_num
                    ,NULL                                    vis_l_num
                    ,NULL                                    vis_m_num
                    ,NULL                                    vis_n_num
                    ,NULL                                    vis_o_num
                    ,NULL                                    vis_p_num
                    ,NULL                                    vis_q_num
                    ,NULL                                    vis_r_num
                    ,NULL                                    vis_s_num
                    ,NULL                                    vis_t_num
                    ,NULL                                    vis_u_num
                    ,NULL                                    vis_v_num
                    ,NULL                                    vis_w_num
                    ,NULL                                    vis_x_num
                    ,NULL                                    vis_y_num
                    ,NULL                                    vis_z_num
             FROM    (SELECT  xsv1.account_number
                             ,xsv1.delivery_date
                             ,xsv1.other_flag
                             ,(CASE
                                 WHEN (xsv1.pure_amount < 0)
                                  AND (xsv1.pure_amount > -500)
                                 THEN
                                   -1
                                 WHEN (xsv1.pure_amount = 0)
                                 THEN
                                   0
                                 WHEN (xsv1.pure_amount > 0)
                                  AND (xsv1.pure_amount < 500)
                                 THEN
                                   1
                                 ELSE
                                   ROUND(xsv1.pure_amount / 1000)
                               END
                              ) pure_amount
/* 20090828_abe_0001194 START*/
                      FROM    (
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_{Ò®_02763
--                      SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                      FROM    (SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'N'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class <> cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
--                               UNION ALL
/* 20090828_abe_0001194 START*/
--                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                               SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'Y'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_{Ò®_02763
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_{Ò®_02763
                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
                                   xsv.account_number     account_number
                                  ,xsv.delivery_date      delivery_date
                                  ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')  other_flag
                                  ,SUM(xsv.pure_amount)   pure_amount
                               FROM    xxcso_sales_v  xsv
                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
                               GROUP BY xsv.account_number 
                                       ,xsv.delivery_date
                                       ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_{Ò®_02763
                              ) xsv1
                     )                       xsv2
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_{Ò®_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.account_number = xsv2.account_number
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_{Ò®_02763
             --------------------------------
             -- ÚqÊKâÀÑWv
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_{Ò®_02763
--             SELECT  xcav.sale_base_code                       group_base_code
--                    ,xcav.account_number                       sum_org_code
             SELECT  xvv1.sale_base_code                       group_base_code
                    ,xvv1.account_number                       sum_org_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_{Ò®_02763
                    ,TO_CHAR(xvv1.actual_end_date,'YYYYMMDD')  sales_date
                    ,NULL                                      tgt_amt
                    ,NULL                                      rslt_amt
                    ,NULL                                      rslt_center_amt
                    ,xvv1.vis_num                              vis_num
                    ,(CASE
                        WHEN (xvv1.vis_sales_num > 0) THEN
                          xvv1.vis_sales_num
                        ELSE
                          NULL
                      END
                     )                                         vis_sales_num
                    ,xvv1.visit_num_a                          vis_a_num
                    ,xvv1.visit_num_b                          vis_b_num
                    ,xvv1.visit_num_c                          vis_c_num
                    ,xvv1.visit_num_d                          vis_d_num
                    ,xvv1.visit_num_e                          vis_e_num
                    ,xvv1.visit_num_f                          vis_f_num
                    ,xvv1.visit_num_g                          vis_g_num
                    ,xvv1.visit_num_h                          vis_h_num
                    ,xvv1.visit_num_i                          vis_i_num
                    ,xvv1.visit_num_j                          vis_j_num
                    ,xvv1.visit_num_k                          vis_k_num
                    ,xvv1.visit_num_l                          vis_l_num
                    ,xvv1.visit_num_m                          vis_m_num
                    ,xvv1.visit_num_n                          vis_n_num
                    ,xvv1.visit_num_o                          vis_o_num
                    ,xvv1.visit_num_p                          vis_p_num
                    ,xvv1.visit_num_q                          vis_q_num
                    ,xvv1.visit_num_r                          vis_r_num
                    ,xvv1.visit_num_s                          vis_s_num
                    ,xvv1.visit_num_t                          vis_t_num
                    ,xvv1.visit_num_u                          vis_u_num
                    ,xvv1.visit_num_v                          vis_v_num
                    ,xvv1.visit_num_w                          vis_w_num
                    ,xvv1.visit_num_x                          vis_x_num
                    ,xvv1.visit_num_y                          vis_y_num
                    ,xvv1.visit_num_z                          vis_z_num
/* 20090828_abe_0001194 START*/
             FROM    (SELECT  /*+ index(xvv.jtb xxcso_jtf_tasks_b_n20) */
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_{Ò®_02763
--                              xvv.party_id                                party_id
                              hca.account_number                          account_number
                             ,(SELECT xcca.sale_base_code
                               FROM  xxcmm_cust_accounts xcca
                               WHERE xcca.customer_code = hca.account_number
                               AND   rownum = 1
                              )                                           sale_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_{Ò®_02763
--             FROM    (SELECT  xvv.party_id                                party_id
/* 20090828_abe_0001194 END*/
                             ,TRUNC(xvv.actual_end_date)                  actual_end_date
                             ,COUNT(xvv.task_id)                          vis_num
                             ,SUM(
                                CASE
                                  WHEN (xvv.eff_visit_flag = cv_eff_visit_flag_1) THEN
                                    1
                                  ELSE
                                    0
                                END
                              )                                           vis_sales_num
                             ,SUM(xvv.visit_num_a)                        visit_num_a
                             ,SUM(xvv.visit_num_b)                        visit_num_b
                             ,SUM(xvv.visit_num_c)                        visit_num_c
                             ,SUM(xvv.visit_num_d)                        visit_num_d
                             ,SUM(xvv.visit_num_e)                        visit_num_e
                             ,SUM(xvv.visit_num_f)                        visit_num_f
                             ,SUM(xvv.visit_num_g)                        visit_num_g
                             ,SUM(xvv.visit_num_h)                        visit_num_h
                             ,SUM(xvv.visit_num_i)                        visit_num_i
                             ,SUM(xvv.visit_num_j)                        visit_num_j
                             ,SUM(xvv.visit_num_k)                        visit_num_k
                             ,SUM(xvv.visit_num_l)                        visit_num_l
                             ,SUM(xvv.visit_num_m)                        visit_num_m
                             ,SUM(xvv.visit_num_n)                        visit_num_n
                             ,SUM(xvv.visit_num_o)                        visit_num_o
                             ,SUM(xvv.visit_num_p)                        visit_num_p
                             ,SUM(xvv.visit_num_q)                        visit_num_q
                             ,SUM(xvv.visit_num_r)                        visit_num_r
                             ,SUM(xvv.visit_num_s)                        visit_num_s
                             ,SUM(xvv.visit_num_t)                        visit_num_t
                             ,SUM(xvv.visit_num_u)                        visit_num_u
                             ,SUM(xvv.visit_num_v)                        visit_num_v
                             ,SUM(xvv.visit_num_w)                        visit_num_w
                             ,SUM(xvv.visit_num_x)                        visit_num_x
                             ,SUM(xvv.visit_num_y)                        visit_num_y
                             ,SUM(xvv.visit_num_z)                        visit_num_z
                      FROM    xxcso_visit_v xvv
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_{Ò®_02763
                             ,hz_cust_accounts   hca
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_{Ò®_02763
                      WHERE   TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_{Ò®_02763
                      AND     hca.party_id = xvv.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_{Ò®_02763
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_{Ò®_02763
--                      GROUP BY xvv.party_id, TRUNC(xvv.actual_end_date)
                      --¯êaccount_number©çæ¾µ½sale_base_codeÍlÍj[NÌ×
                      --group by åÉÍÜß¸ÉÈªB
                      GROUP BY hca.account_number
                              , TRUNC(xvv.actual_end_date)
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_{Ò®_02763
                     )                       xvv1
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_{Ò®_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.party_id = xvv1.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_{Ò®_02763
            ) inn_v
    GROUP BY  inn_v.sum_org_code
             ,inn_v.group_base_code
             ,inn_v.sales_date
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
    ;
    -- KâÀÑVIEW
  -- ===============================
  -- [U[è`O[oR[h
  -- ===============================
  -- úÊÚqÊf[^æ¾pR[hè`
  g_get_day_acct_data_rec  g_get_day_acct_data_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ú (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- AvP[VZk¼
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
    -- *** DEBUG_LOG ***
    -- æ¾µ½WHOJðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'WHOJ'  || CHR(10) ||
 'created_by:' || TO_CHAR(cn_created_by            ) || CHR(10) ||
 'creation_date:' || TO_CHAR(cd_creation_date         ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_updated_by:' || TO_CHAR(cn_last_updated_by       ) || CHR(10) ||
 'last_update_date:' || TO_CHAR(cd_last_update_date      ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_update_login:' || TO_CHAR(cn_last_update_login     ) || CHR(10) ||
 'request_id:' || TO_CHAR(cn_request_id            ) || CHR(10) ||
 'program_application_id:' || TO_CHAR(cn_program_application_id) || CHR(10) ||
 'program_id:' || TO_CHAR(cn_program_id            ) || CHR(10) ||
 'program_update_date:' || TO_CHAR(cd_program_update_date   ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- ===========================
    -- Æ±úæ¾ 
    -- ===========================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- æ¾µ½Æ±úðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_process_date IS NULL) THEN
--    IF (gd_process_date = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --AvP[VZk¼
                    ,iv_name         => cv_tkn_number_01             --bZ[WR[h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- ïvúÔJnúæ¾ 
    -- ===========================
    gd_ar_gl_period_from := xxcso_util_common_pkg.get_ar_gl_period_from;
    -- *** DEBUG_LOG ***
    -- æ¾µ½ïvúÔJnúðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10) ||
                 cv_debug_msg4  || TO_CHAR(gd_ar_gl_period_from,'yyyy/mm/dd hh24:mi:ss') ||
                 CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_ar_gl_period_from IS NULL) THEN
--    IF (gd_ar_gl_period_from = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --AvP[VZk¼
                    ,iv_name         => cv_tkn_number_02             --bZ[WR[h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- oÎÛÌNXgæ¾ 
    -- ===========================
    -- Æ±úÌN
    gv_ym_lst_1 := TO_CHAR(gd_process_date, 'YYYYMM');
    -- Æ±úÌO
    IF (TO_CHAR(gd_process_date, 'MM') = '01') THEN
      gv_ym_lst_2 := (TO_CHAR(gd_process_date, 'YYYY') - 1) || '12';
    ELSE
      gv_ym_lst_2 := TO_CHAR(gd_process_date, 'YYYYMM') - 1;
    END IF;
    -- Æ±úÌON¯
    gv_ym_lst_3 := TO_CHAR(TO_CHAR(gd_process_date, 'YYYY')-1) || 
                   TO_CHAR(gd_process_date, 'MM');
    IF (TO_CHAR(gd_process_date, 'YYYYMM') <> TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')) THEN
      -- ïvúÔJnúÌN
      gv_ym_lst_4 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM');
      -- ïvúÔJnúÌO
      IF (TO_CHAR(gd_ar_gl_period_from, 'MM') = '01') THEN
        gv_ym_lst_5 := (TO_CHAR(gd_ar_gl_period_from, 'YYYY') - 1) || '12';
      ELSE
        gv_ym_lst_5 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM') - 1;
      END IF;
      -- ïvúÔJnúÌON¯
      gv_ym_lst_6 := TO_CHAR(TO_CHAR(gd_ar_gl_period_from, 'YYYY')-1) || 
                     TO_CHAR(gd_ar_gl_period_from, 'MM');
    END IF;
    -- *** DEBUG_LOG ***
    -- æ¾µ½Æ±úðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg5_1  || gv_ym_lst_1 || CHR(10) ||
                 cv_debug_msg5_2  || gv_ym_lst_2 || CHR(10) ||
                 cv_debug_msg5_3  || gv_ym_lst_3 || CHR(10) ||
                 cv_debug_msg5_4  || gv_ym_lst_4 || CHR(10) ||
                 cv_debug_msg5_5  || gv_ym_lst_5 || CHR(10) ||
                 cv_debug_msg5_6  || gv_ym_lst_6 || CHR(10) ||
                 CHR(10) ||
                 ''
    );
    -- ===========================
    -- oAoÍÌúlÝè 
    -- ===========================
    gn_delete_cnt := 0;              -- í
    gn_extrct_cnt := 0;              -- o
    gn_output_cnt := 0;              -- oÍ
    -- *** DEBUG_LOG ***
    -- æ¾µ½Æ±úðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_parm
   * Description      : p[^`FbN (A-2)
   ***********************************************************************************/
  PROCEDURE check_parm(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'check_parm';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
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
    -- INp[^FæªÌNULL`FbN
    IF (gv_prm_process_div IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --AvP[VZk¼
                    ,iv_name         => cv_tkn_number_13             --bZ[WR[h
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --ósÌoÍ
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- INp[^FæªoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_entry
                    ,iv_token_value1 => gv_prm_process_div
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- INp[^FæªÌÃ«`FbN
    IF (gv_prm_process_div NOT IN (cv_process_div_ins, cv_process_div_del)) THEN
      -- p[^æªª'1','9'ÅÍÈ¢ê
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --AvP[VZk¼
                    ,iv_name         => cv_tkn_number_15             --bZ[WR[h
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END check_parm;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ÎÛf[^í (A-3)
   ***********************************************************************************/
  PROCEDURE delete_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- G[EbZ[W            --# Åè #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ^[ER[h              --# Åè #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_data';  -- vO¼
--
--#######################  Åè[JÏé¾ START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_delete_cnt               NUMBER;              -- í
    /* 2009.12.28 K.Hosoi E_{Ò®_00686Î START */
    ld_calc_ar_gl_prid_frm      DATE;                -- íÎÛf[^oúÔvZp
    /* 2009.12.28 K.Hosoi E_{Ò®_00686Î END */
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- =======================
    -- Ïú» 
    -- =======================
    ln_delete_cnt := 0;
--
    -- =======================
    -- úÊÎÛf[^í 
    -- =======================
    BEGIN
      /* 2009.12.28 K.Hosoi E_{Ò®_00686Î START */
      --SELECT COUNT(xsvsr.sum_org_code)
      --INTO  ln_delete_cnt
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- ÌNú
      --;
      --gn_delete_cnt := ln_delete_cnt;
      --DELETE
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- ÌNú
      --;
      -- íÎÛf[^oúÔvZpÏÉAïvúÔFromði[
      ld_calc_ar_gl_prid_frm := gd_ar_gl_period_from;
      --
      --f[^í[vJn
      <<loop_del_sm_vst_sl_rp_dt>>
      LOOP
        -- íÎÛf[^oúÔvZpÏ ÌlªAÆ±Ìðæèå«¢êÍEXIT
        EXIT WHEN ( ld_calc_ar_gl_prid_frm > LAST_DAY(gd_process_date));
        --
        DELETE
        FROM  xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}
        WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
          AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                    AND TO_CHAR((ld_calc_ar_gl_prid_frm + 9), 'YYYYMMDD') -- ÌNú
        ;
        ln_delete_cnt := ln_delete_cnt + SQL%ROWCOUNT;
        -- R~bgðs¢Ü·B
        COMMIT;
        --
        ld_calc_ar_gl_prid_frm := ld_calc_ar_gl_prid_frm + 10;
        --
      END LOOP;
      --
      gn_delete_cnt := ln_delete_cnt;
      /* 2009.12.28 K.Hosoi E_{Ò®_00686Î END */
      -- *** DEBUG_LOG ***
      -- úÊíÎÛf[^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => 'úÊíÎÛf[^ = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- úÊÎÛf[^ðíµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || CHR(10) ||
                   ''
      );
--
    -- =======================
    -- ÊÎÛf[^í 
    -- =======================
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL Start
--      SELECT COUNT(xsvsr.sum_org_code)
--      INTO  ln_delete_cnt
--      FROM  xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}
--      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
--        AND  xsvsr.sales_date IN (
--                                   gv_ym_lst_1
--                                  ,gv_ym_lst_2
--                                  ,gv_ym_lst_3
--                                  ,gv_ym_lst_4
--                                  ,gv_ym_lst_5
--                                  ,gv_ym_lst_6
--                                 )  -- ÌNú
--      ;
--      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL End
      DELETE
      FROM  xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}
      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- ÌNú
      ;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
      ln_delete_cnt := SQL%ROWCOUNT;
      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
      /* 2009.12.28 K.Hosoi E_{Ò®_00686Î START */
      -- R~bgðs¤
      COMMIT;
      /* 2009.12.28 K.Hosoi E_{Ò®_00686Î END */
      -- *** DEBUG_LOG ***
      -- ÊíÎÛf[^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => 'ÊíÎÛf[^ = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- ÊÎÛf[^ðíµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_03             --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                 --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep  --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage            --g[NR[h2
                      ,iv_token_value2 => SQLERRM                      --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
    -- *** DEBUG_LOG ***
    -- úÊÎÛf[^ðíµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_acct_dt
   * Description      : KâãvæÇ\T}e[uÉo^ (A-5)
   ***********************************************************************************/
  PROCEDURE insert_day_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_acct_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
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
    -- *** [JER[h ***
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- ======================
    -- KâãvæÇ\T}e[uo^ 
    -- ======================
    BEGIN
      INSERT INTO xxcso_sum_visit_sale_rep(
        created_by                 --ì¬Ò
       ,creation_date              --ì¬ú
       ,last_updated_by            --ÅIXVÒ
       ,last_update_date           --ÅIXVú
       ,last_update_login          --ÅIXVOC
       ,request_id                 --vID
       ,program_application_id     --RJgEvOEAvP[VID
       ,program_id                 --RJgEvOID
       ,program_update_date        --vOXVú
       ,sum_org_type               --WvgDíÞ
       ,sum_org_code               --WvgDbc
       ,group_base_code            --O[ve_bc
       ,month_date_div             --úæª
       ,sales_date                 --ÌNú^ÌN
       ,gvm_type                   --êÊ^©Ì@^lb
       ,cust_new_num               --ÚqiVKj
       ,cust_vd_new_num            --ÚqiVDFVKj
       ,cust_other_new_num         --ÚqiVDÈOFVKj
       ,rslt_amt                   --ãÀÑ
       ,rslt_new_amt               --ãÀÑiVKj
       ,rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,rslt_vd_amt                --ãÀÑiVDj
       ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,rslt_other_amt             --ãÀÑiVDÈOj
       ,rslt_center_amt            --à¼_QãÀÑ
       ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,tgt_amt                    --ãvæ
       ,tgt_new_amt                --ãvæiVKj
       ,tgt_vd_new_amt             --ãvæiVDFVKj
       ,tgt_vd_amt                 --ãvæiVDj
       ,tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,tgt_other_amt              --ãvæiVDÈOj
       ,vis_num                    --KâÀÑ
       ,vis_new_num                --KâÀÑiVKj
       ,vis_vd_new_num             --KâÀÑiVDFVKj
       ,vis_vd_num                 --KâÀÑiVDj
       ,vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,vis_other_num              --KâÀÑiVDÈOj
       ,vis_mc_num                 --KâÀÑiMCj
       ,vis_sales_num              --Lø¬
       ,tgt_vis_num                --Kâvæ
       ,tgt_vis_new_num            --KâvæiVKj
       ,tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,tgt_vis_vd_num             --KâvæiVDj
       ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,tgt_vis_other_num          --KâvæiVDÈOj
       ,tgt_vis_mc_num             --KâvæiMCj
       ,vis_a_num                  --Kâ`
       ,vis_b_num                  --Kâa
       ,vis_c_num                  --Kâb
       ,vis_d_num                  --Kâc
       ,vis_e_num                  --Kâd
       ,vis_f_num                  --Kâe
       ,vis_g_num                  --Kâf
       ,vis_h_num                  --Kâg
       ,vis_i_num                  --Kâú@
       ,vis_j_num                  --Kâi
       ,vis_k_num                  --Kâj
       ,vis_l_num                  --Kâk
       ,vis_m_num                  --Kâl
       ,vis_n_num                  --Kâm
       ,vis_o_num                  --Kân
       ,vis_p_num                  --Kâo
       ,vis_q_num                  --Kâp
       ,vis_r_num                  --Kâq
       ,vis_s_num                  --Kâr
       ,vis_t_num                  --Kâs
       ,vis_u_num                  --Kât
       ,vis_v_num                  --Kâu
       ,vis_w_num                  --Kâv
       ,vis_x_num                  --Kâw
       ,vis_y_num                  --Kâx
       ,vis_z_num                  --Kây
      )VALUES(
        cn_created_by                                --ì¬Ò
       ,cd_creation_date                             --ì¬ú
       ,cn_last_updated_by                           --ÅIXVÒ
       ,cd_last_update_date                          --ÅIXVú
       ,cn_last_update_login                         --ÅIXVOC
       ,cn_request_id                                --vID
       ,cn_program_application_id                    --RJgEvOEAvP[VID
       ,cn_program_id                                --RJgEvOID
       ,cd_program_update_date                       --vOXVú
       ,cv_sum_org_type_accnt                        --WvgDíÞ
       ,g_get_day_acct_data_rec.sum_org_code               --WvgDbc
/* 20090519_Ogawa_T1_1037 START*/
--     ,cv_null                                            --O[ve_bc
       ,g_get_day_acct_data_rec.group_base_code            --O[ve_bc
/* 20090519_Ogawa_T1_1037 END*/
       ,cv_month_date_div_day                              --úæª
       ,g_get_day_acct_data_rec.sales_date                 --ÌNú^ÌN
       ,g_get_day_acct_data_rec.gvm_type                   --êÊ^©Ì@^lb
       ,g_get_day_acct_data_rec.cust_new_num               --ÚqiVKj
       ,g_get_day_acct_data_rec.cust_vd_new_num            --ÚqiVDFVKj
       ,g_get_day_acct_data_rec.cust_other_new_num         --ÚqiVDÈOFVKj
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--     /* 20090501_abe_ãvæoÍÎ START*/
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑ
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑiVKj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑiVDFVKj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑiVDj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑiVDÈOFVKj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --ãÀÑiVDÈOj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --à¼_QãÀÑ
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --à¼_QãÀÑiVDj
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --à¼_QãÀÑiVDÈOj
--     --,g_get_day_acct_data_rec.rslt_amt                   --ãÀÑ
--     --,g_get_day_acct_data_rec.rslt_new_amt               --ãÀÑiVKj
--     --,g_get_day_acct_data_rec.rslt_vd_new_amt            --ãÀÑiVDFVKj
--     --,g_get_day_acct_data_rec.rslt_vd_amt                --ãÀÑiVDj
--     --,g_get_day_acct_data_rec.rslt_other_new_amt         --ãÀÑiVDÈOFVKj
--     --,g_get_day_acct_data_rec.rslt_other_amt             --ãÀÑiVDÈOj
--     --,g_get_day_acct_data_rec.rslt_center_amt            --à¼_QãÀÑ
--     --,g_get_day_acct_data_rec.rslt_center_vd_amt         --à¼_QãÀÑiVDj
--     --,g_get_day_acct_data_rec.rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
--     /* 20090501_abe_ãvæoÍÎ END*/
       ,g_get_day_acct_data_rec.rslt_amt                   --ãÀÑ
       ,g_get_day_acct_data_rec.rslt_new_amt               --ãÀÑiVKj
       ,g_get_day_acct_data_rec.rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,g_get_day_acct_data_rec.rslt_vd_amt                --ãÀÑiVDj
       ,g_get_day_acct_data_rec.rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,g_get_day_acct_data_rec.rslt_other_amt             --ãÀÑiVDÈOj
       ,g_get_day_acct_data_rec.rslt_center_amt            --à¼_QãÀÑ
       ,g_get_day_acct_data_rec.rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,g_get_day_acct_data_rec.rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
       ,g_get_day_acct_data_rec.tgt_amt                    --ãvæ
       ,NULL                                               --ãvæiVKj
       ,NULL                                               --ãvæiVDFVKj
       ,g_get_day_acct_data_rec.tgt_vd_amt                 --ãvæiVDj
       ,NULL                                               --ãvæiVDÈOFVKj
       ,g_get_day_acct_data_rec.tgt_other_amt              --ãvæiVDÈOj
       ,g_get_day_acct_data_rec.vis_num                    --KâÀÑ
       ,g_get_day_acct_data_rec.vis_new_num                --KâÀÑiVKj
       ,g_get_day_acct_data_rec.vis_vd_new_num             --KâÀÑiVDFVKj
       ,g_get_day_acct_data_rec.vis_vd_num                 --KâÀÑiVDj
       ,g_get_day_acct_data_rec.vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,g_get_day_acct_data_rec.vis_other_num              --KâÀÑiVDÈOj
       ,g_get_day_acct_data_rec.vis_mc_num                 --KâÀÑiMCj
       ,g_get_day_acct_data_rec.vis_sales_num              --Lø¬
       ,g_get_day_acct_data_rec.tgt_vis_num                --Kâvæ
       ,NULL                                               --KâvæiVKj
       ,NULL                                               --KâvæiVDFVKj
       ,g_get_day_acct_data_rec.tgt_vis_vd_num             --KâvæiVDj
       ,NULL                                               --KâvæiVDÈOFVKj
       ,g_get_day_acct_data_rec.tgt_vis_other_num          --KâvæiVDÈOj
       ,NULL                                               --KâvæiMCj
       ,g_get_day_acct_data_rec.vis_a_num                  --Kâ`
       ,g_get_day_acct_data_rec.vis_b_num                  --Kâa
       ,g_get_day_acct_data_rec.vis_c_num                  --Kâb
       ,g_get_day_acct_data_rec.vis_d_num                  --Kâc
       ,g_get_day_acct_data_rec.vis_e_num                  --Kâd
       ,g_get_day_acct_data_rec.vis_f_num                  --Kâe
       ,g_get_day_acct_data_rec.vis_g_num                  --Kâf
       ,g_get_day_acct_data_rec.vis_h_num                  --Kâg
       ,g_get_day_acct_data_rec.vis_i_num                  --Kâú@
       ,g_get_day_acct_data_rec.vis_j_num                  --Kâi
       ,g_get_day_acct_data_rec.vis_k_num                  --Kâj
       ,g_get_day_acct_data_rec.vis_l_num                  --Kâk
       ,g_get_day_acct_data_rec.vis_m_num                  --Kâl
       ,g_get_day_acct_data_rec.vis_n_num                  --Kâm
       ,g_get_day_acct_data_rec.vis_o_num                  --Kân
       ,g_get_day_acct_data_rec.vis_p_num                  --Kâo
       ,g_get_day_acct_data_rec.vis_q_num                  --Kâp
       ,g_get_day_acct_data_rec.vis_r_num                  --Kâq
       ,g_get_day_acct_data_rec.vis_s_num                  --Kâr
       ,g_get_day_acct_data_rec.vis_t_num                  --Kâs
       ,g_get_day_acct_data_rec.vis_u_num                  --Kât
       ,g_get_day_acct_data_rec.vis_v_num                  --Kâu
       ,g_get_day_acct_data_rec.vis_w_num                  --Kâv
       ,g_get_day_acct_data_rec.vis_x_num                  --Kâw
       ,g_get_day_acct_data_rec.vis_y_num                  --Kâx
       ,g_get_day_acct_data_rec.vis_z_num                  --Kây
      )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_acct                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
    -- oÍÉÇÁ
    gn_output_cnt := gn_output_cnt + 1;
--
  EXCEPTION
    -- *** t@CáOnh ***
    WHEN insert_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_day_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : get_day_acct_data
   * Description      : úÊÚqÊf[^æ¾ (A-4)
   ***********************************************************************************/
  PROCEDURE get_day_acct_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- G[EbZ[W            --# Åè #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ^[ER[h              --# Åè #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_day_acct_data';  -- vO¼
--
--#######################  Åè[JÏé¾ START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
--
    -- *** [JÏ ***
--
    -- *** [JáO ***
    get_data_error_expt    EXCEPTION;    -- f[^oáO
    prog_error_expt        EXCEPTION;    -- TuvOáO
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
--
    BEGIN
      -- ========================
      -- úÊÚqÊf[^æ¾
      -- ========================
      OPEN g_get_day_acct_data_cur;
      -- *** DEBUG_LOG ***
      -- J[\I[vµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_acct || CHR(10)   ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_04               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_processing_name         --g[NR[h1
                      ,iv_token_value1 => cv_day_acct_data               --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmsg                  --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_data_error_expt;
    END;
--
    <<loop_g_get_day_acct_data>>
    LOOP 
      FETCH g_get_day_acct_data_cur INTO g_get_day_acct_data_rec;
      -- oi[
      ln_extrct_cnt := g_get_day_acct_data_cur%ROWCOUNT;
      EXIT WHEN g_get_day_acct_data_cur%NOTFOUND
      OR  g_get_day_acct_data_cur%ROWCOUNT = 0;
      /* 2009.11.06 K.Satomura E_T4_00135Î START */
      IF (g_get_day_acct_data_rec.sum_org_code IS NOT NULL
        AND g_get_day_acct_data_rec.group_base_code IS NOT NULL)
      THEN
      /* 2009.11.06 K.Satomura E_T4_00135Î END */
        -- KâãvæÇ\T}e[uÉo^ (A-5)
        insert_day_acct_dt(
          ov_errbuf      =>  lv_errbuf             -- G[EbZ[W
         ,ov_retcode     =>  lv_retcode            -- ^[ER[h
         ,ov_errmsg      =>  lv_errmsg             -- [U[EG[EbZ[W
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE prog_error_expt;
        END IF;
      /* 2009.11.06 K.Satomura E_T4_00135Î START */
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                             -- AvP[VZk¼
                       ,iv_name         => cv_tkn_number_12                        -- bZ[WR[h
                       ,iv_token_name1  => cv_tkn_sum_org_code                     -- g[NR[h1
                       ,iv_token_value1 => g_get_day_acct_data_rec.sum_org_code    -- g[Nl1
                       ,iv_token_name2  => cv_tkn_group_base_code                  -- g[NR[h2
                       ,iv_token_value2 => g_get_day_acct_data_rec.group_base_code -- g[Nl2
                       ,iv_token_name3  => cv_tkn_sales_date                       -- g[NR[h3
                       ,iv_token_value3 => g_get_day_acct_data_rec.sales_date      -- g[Nl3
                     );
        --
        lv_errbuf   := lv_errmsg;
        lv_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
      END IF;
      /* 2009.11.06 K.Satomura E_T4_00135Î END */
    END LOOP;
    -- *** DEBUG_LOG ***
    -- úÊÚqÊæ¾o^ðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_d_acct  || CHR(10) ||
                 ''
    );
    -- J[\N[Y
    CLOSE g_get_day_acct_data_cur;
--
    -- *** DEBUG_LOG ***
    -- J[\N[Yµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1|| cv_day_acct || CHR(10) ||
                 ''
    );
    -- oi[
    gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
    -- *** DEBUG_LOG ***
    -- oAoÍðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
  EXCEPTION
    -- *** f[^oáOnh ***
    WHEN get_data_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** TuvOáOnh ***
    WHEN prog_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END get_day_acct_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_emp_dt
   * Description      : úÊcÆõÊæ¾o^ (A-6)
   ***********************************************************************************/
  PROCEDURE insert_day_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_emp_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- úÊcÆõÊf[^æ¾pJ[\
    CURSOR day_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --WvgDbc
       ,xsvsr.sales_date                 sales_date                 --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --Kây
      FROM
        xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
       ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- WvgDíÞ
      AND    xcrv2.account_number = xsvsr.sum_org_code  -- ÚqR[h
      AND    xsvsr.month_date_div = cv_month_date_div_day  -- úæª
      AND    xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xcrv2.employee_number     --]ÆõÔ
               ,xsvsr.sales_date          --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- úÊcÆõÊf[^æ¾pR[h
     day_emp_dt_rec day_emp_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    BEGIN
      -- ========================
      -- úÊcÆõÊf[^æ¾
      -- ========================
      -- J[\I[v
      OPEN day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\I[vµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_emp || CHR(10)   ||
                   ''
      );
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_day_emp_dt>>
      LOOP
        FETCH day_emp_dt_cur INTO day_emp_dt_rec;
        -- oæ¾
        ln_extrct_cnt := day_emp_dt_cur%ROWCOUNT;
        EXIT WHEN day_emp_dt_cur%NOTFOUND
        OR  day_emp_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_emp                       --WvgDíÞ
         ,day_emp_dt_rec.sum_org_code               --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_day                     --úæª
         ,day_emp_dt_rec.sales_date                 --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,day_emp_dt_rec.cust_new_num               --ÚqiVKj
         ,day_emp_dt_rec.cust_vd_new_num            --ÚqiVDFVKj
         ,day_emp_dt_rec.cust_other_new_num         --ÚqiVDÈOFVKj
         ,day_emp_dt_rec.rslt_amt                   --ãÀÑ
         ,day_emp_dt_rec.rslt_new_amt               --ãÀÑiVKj
         ,day_emp_dt_rec.rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,day_emp_dt_rec.rslt_vd_amt                --ãÀÑiVDj
         ,day_emp_dt_rec.rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,day_emp_dt_rec.rslt_other_amt             --ãÀÑiVDÈOj
         ,day_emp_dt_rec.rslt_center_amt            --à¼_QãÀÑ
         ,day_emp_dt_rec.rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,day_emp_dt_rec.rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,day_emp_dt_rec.tgt_amt                    --ãvæ
         ,day_emp_dt_rec.tgt_new_amt                --ãvæiVKj
         ,day_emp_dt_rec.tgt_vd_new_amt             --ãvæiVDFVKj
         ,day_emp_dt_rec.tgt_vd_amt                 --ãvæiVDj
         ,day_emp_dt_rec.tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,day_emp_dt_rec.tgt_other_amt              --ãvæiVDÈOj
         ,day_emp_dt_rec.vis_num                    --KâÀÑ
         ,day_emp_dt_rec.vis_new_num                --KâÀÑiVKj
         ,day_emp_dt_rec.vis_vd_new_num             --KâÀÑiVDFVKj
         ,day_emp_dt_rec.vis_vd_num                 --KâÀÑiVDj
         ,day_emp_dt_rec.vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,day_emp_dt_rec.vis_other_num              --KâÀÑiVDÈOj
         ,day_emp_dt_rec.vis_mc_num                 --KâÀÑiMCj
         ,day_emp_dt_rec.vis_sales_num              --Lø¬
         ,day_emp_dt_rec.tgt_vis_num                --Kâvæ
         ,day_emp_dt_rec.tgt_vis_new_num            --KâvæiVKj
         ,day_emp_dt_rec.tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,day_emp_dt_rec.tgt_vis_vd_num             --KâvæiVDj
         ,day_emp_dt_rec.tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,day_emp_dt_rec.tgt_vis_other_num          --KâvæiVDÈOj
         ,day_emp_dt_rec.tgt_vis_mc_num             --KâvæiMCj
         ,day_emp_dt_rec.vis_a_num                  --Kâ`
         ,day_emp_dt_rec.vis_b_num                  --Kâa
         ,day_emp_dt_rec.vis_c_num                  --Kâb
         ,day_emp_dt_rec.vis_d_num                  --Kâc
         ,day_emp_dt_rec.vis_e_num                  --Kâd
         ,day_emp_dt_rec.vis_f_num                  --Kâe
         ,day_emp_dt_rec.vis_g_num                  --Kâf
         ,day_emp_dt_rec.vis_h_num                  --Kâg
         ,day_emp_dt_rec.vis_i_num                  --Kâú@
         ,day_emp_dt_rec.vis_j_num                  --Kâi
         ,day_emp_dt_rec.vis_k_num                  --Kâj
         ,day_emp_dt_rec.vis_l_num                  --Kâk
         ,day_emp_dt_rec.vis_m_num                  --Kâl
         ,day_emp_dt_rec.vis_n_num                  --Kâm
         ,day_emp_dt_rec.vis_o_num                  --Kân
         ,day_emp_dt_rec.vis_p_num                  --Kâo
         ,day_emp_dt_rec.vis_q_num                  --Kâp
         ,day_emp_dt_rec.vis_r_num                  --Kâq
         ,day_emp_dt_rec.vis_s_num                  --Kâr
         ,day_emp_dt_rec.vis_t_num                  --Kâs
         ,day_emp_dt_rec.vis_u_num                  --Kât
         ,day_emp_dt_rec.vis_v_num                  --Kâu
         ,day_emp_dt_rec.vis_w_num                  --Kâv
         ,day_emp_dt_rec.vis_x_num                  --Kâw
         ,day_emp_dt_rec.vis_y_num                  --Kâx
         ,day_emp_dt_rec.vis_z_num                  --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_emp_dt;
      -- *** DEBUG_LOG ***
      -- úÊcÆõÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_emp  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_emp || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_emp                     --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_day_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_group_dt
   * Description      : úÊcÆO[vÊæ¾o^ (A-7)
   ***********************************************************************************/
  PROCEDURE insert_day_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_group_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- úÊcÆO[vÊf[^æ¾pJ[\
    CURSOR day_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code               sum_org_code               --WvgDbc
       ,inn_v.group_base_code            group_base_code            --O[ve_bc
       ,inn_v.sales_date                 sales_date                 --ÌNú^ÌN
       ,SUM(inn_v.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,SUM(inn_v.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(inn_v.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(inn_v.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(inn_v.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(inn_v.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(inn_v.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(inn_v.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(inn_v.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(inn_v.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(inn_v.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(inn_v.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(inn_v.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(inn_v.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(inn_v.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(inn_v.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(inn_v.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(inn_v.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(inn_v.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(inn_v.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(inn_v.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(inn_v.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(inn_v.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(inn_v.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(inn_v.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(inn_v.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(inn_v.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(inn_v.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(inn_v.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(inn_v.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(inn_v.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(inn_v.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(inn_v.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(inn_v.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(inn_v.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(inn_v.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(inn_v.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(inn_v.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(inn_v.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(inn_v.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(inn_v.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(inn_v.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(inn_v.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(inn_v.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(inn_v.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(inn_v.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(inn_v.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(inn_v.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(inn_v.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(inn_v.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(inn_v.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(inn_v.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(inn_v.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(inn_v.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(inn_v.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(inn_v.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(inn_v.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(inn_v.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(inn_v.vis_z_num            ) vis_z_num                  --Kây
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code             --WvgDbc
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code          --O[ve_bc
          ,xsvsr.sales_date                 sales_date               --ÌNú^ÌN
          ,xsvsr.cust_new_num               cust_new_num             --ÚqiVKj
          ,xsvsr.cust_vd_new_num            cust_vd_new_num          --ÚqiVDFVKj
          ,xsvsr.cust_other_new_num         cust_other_new_num       --ÚqiVDÈOFVKj
          ,xsvsr.rslt_amt                   rslt_amt                 --ãÀÑ
          ,xsvsr.rslt_new_amt               rslt_new_amt             --ãÀÑiVKj
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt          --ãÀÑiVDFVKj
          ,xsvsr.rslt_vd_amt                rslt_vd_amt              --ãÀÑiVDj
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt       --ãÀÑiVDÈOFVKj
          ,xsvsr.rslt_other_amt             rslt_other_amt           --ãÀÑiVDÈOj
          ,xsvsr.rslt_center_amt            rslt_center_amt          --à¼_QãÀÑ
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt       --à¼_QãÀÑiVDj
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt    --à¼_QãÀÑiVDÈOj
          ,xsvsr.tgt_amt                    tgt_amt                  --ãvæ
          ,xsvsr.tgt_new_amt                tgt_new_amt              --ãvæiVKj
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt           --ãvæiVDFVKj
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt               --ãvæiVDj
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt        --ãvæiVDÈOFVKj
          ,xsvsr.tgt_other_amt              tgt_other_amt            --ãvæiVDÈOj
          ,xsvsr.vis_num                    vis_num                  --KâÀÑ
          ,xsvsr.vis_new_num                vis_new_num              --KâÀÑiVKj
          ,xsvsr.vis_vd_new_num             vis_vd_new_num           --KâÀÑiVDFVKj
          ,xsvsr.vis_vd_num                 vis_vd_num               --KâÀÑiVDj
          ,xsvsr.vis_other_new_num          vis_other_new_num        --KâÀÑiVDÈOFVKj
          ,xsvsr.vis_other_num              vis_other_num            --KâÀÑiVDÈOj
          ,xsvsr.vis_mc_num                 vis_mc_num               --KâÀÑiMCj
          ,xsvsr.vis_sales_num              vis_sales_num            --Lø¬
          ,xsvsr.tgt_vis_num                tgt_vis_num              --Kâvæ
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num          --KâvæiVKj
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num       --KâvæiVDFVKj
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num           --KâvæiVDj
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num    --KâvæiVDÈOFVKj
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num        --KâvæiVDÈOj
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num           --KâvæiMCj
          ,xsvsr.vis_a_num                  vis_a_num                --Kâ`
          ,xsvsr.vis_b_num                  vis_b_num                --Kâa
          ,xsvsr.vis_c_num                  vis_c_num                --Kâb
          ,xsvsr.vis_d_num                  vis_d_num                --Kâc
          ,xsvsr.vis_e_num                  vis_e_num                --Kâd
          ,xsvsr.vis_f_num                  vis_f_num                --Kâe
          ,xsvsr.vis_g_num                  vis_g_num                --Kâf
          ,xsvsr.vis_h_num                  vis_h_num                --Kâg
          ,xsvsr.vis_i_num                  vis_i_num                --Kâú@
          ,xsvsr.vis_j_num                  vis_j_num                --Kâi
          ,xsvsr.vis_k_num                  vis_k_num                --Kâj
          ,xsvsr.vis_l_num                  vis_l_num                --Kâk
          ,xsvsr.vis_m_num                  vis_m_num                --Kâl
          ,xsvsr.vis_n_num                  vis_n_num                --Kâm
          ,xsvsr.vis_o_num                  vis_o_num                --Kân
          ,xsvsr.vis_p_num                  vis_p_num                --Kâo
          ,xsvsr.vis_q_num                  vis_q_num                --Kâp
          ,xsvsr.vis_r_num                  vis_r_num                --Kâq
          ,xsvsr.vis_s_num                  vis_s_num                --Kâr
          ,xsvsr.vis_t_num                  vis_t_num                --Kâs
          ,xsvsr.vis_u_num                  vis_u_num                --Kât
          ,xsvsr.vis_v_num                  vis_v_num                --Kâu
          ,xsvsr.vis_w_num                  vis_w_num                --Kâv
          ,xsvsr.vis_x_num                  vis_x_num                --Kâw
          ,xsvsr.vis_y_num                  vis_y_num                --Kâx
          ,xsvsr.vis_z_num                  vis_z_num                --Kây
         FROM
           xxcso_resource_relations_v2 xrrv2  -- \[XÖA}X^iÅVjr[
          ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_emp  -- WvgDíÞ
           AND  xrrv2.employee_number = xsvsr.sum_org_code  -- ]ÆõÔ
           AND  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
           AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                     AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
        ) inn_v
      GROUP BY  inn_v.sum_org_code           --O[vÔ
               ,inn_v.group_base_code        --O[ve_bc
               ,inn_v.sales_date             --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- úÊcÆO[vÊf[^æ¾pR[h
     day_group_dt_rec day_group_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- úÊcÆõÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN day_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_day_group_dt>>
      LOOP
        FETCH day_group_dt_cur INTO day_group_dt_rec;
        -- oæ¾
        ln_extrct_cnt := day_group_dt_cur%ROWCOUNT;
        EXIT WHEN day_group_dt_cur%NOTFOUND
        OR  day_group_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                              --ì¬Ò
         ,cd_creation_date                           --ì¬ú
         ,cn_last_updated_by                         --ÅIXVÒ
         ,cd_last_update_date                        --ÅIXVú
         ,cn_last_update_login                       --ÅIXVOC
         ,cn_request_id                              --vID
         ,cn_program_application_id                  --RJgEvOEAvP[VID
         ,cn_program_id                              --RJgEvOID
         ,cd_program_update_date                     --vOXVú
         ,cv_sum_org_type_group                      --WvgDíÞ
         ,day_group_dt_rec.sum_org_code              --WvgDbc
         ,day_group_dt_rec.group_base_code            --O[ve_bc
         ,cv_month_date_div_day                      --úæª
         ,day_group_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                       --êÊ^©Ì@^lb
         ,day_group_dt_rec.cust_new_num              --ÚqiVKj
         ,day_group_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,day_group_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,day_group_dt_rec.rslt_amt                  --ãÀÑ
         ,day_group_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,day_group_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,day_group_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,day_group_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,day_group_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,day_group_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,day_group_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,day_group_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,day_group_dt_rec.tgt_amt                   --ãvæ
         ,day_group_dt_rec.tgt_new_amt               --ãvæiVKj
         ,day_group_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,day_group_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,day_group_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,day_group_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,day_group_dt_rec.vis_num                   --KâÀÑ
         ,day_group_dt_rec.vis_new_num               --KâÀÑiVKj
         ,day_group_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,day_group_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,day_group_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,day_group_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,day_group_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,day_group_dt_rec.vis_sales_num             --Lø¬
         ,day_group_dt_rec.tgt_vis_num               --Kâvæ
         ,day_group_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,day_group_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,day_group_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,day_group_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,day_group_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,day_group_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,day_group_dt_rec.vis_a_num                 --Kâ`
         ,day_group_dt_rec.vis_b_num                 --Kâa
         ,day_group_dt_rec.vis_c_num                 --Kâb
         ,day_group_dt_rec.vis_d_num                 --Kâc
         ,day_group_dt_rec.vis_e_num                 --Kâd
         ,day_group_dt_rec.vis_f_num                 --Kâe
         ,day_group_dt_rec.vis_g_num                 --Kâf
         ,day_group_dt_rec.vis_h_num                 --Kâg
         ,day_group_dt_rec.vis_i_num                 --Kâú@
         ,day_group_dt_rec.vis_j_num                 --Kâi
         ,day_group_dt_rec.vis_k_num                 --Kâj
         ,day_group_dt_rec.vis_l_num                 --Kâk
         ,day_group_dt_rec.vis_m_num                 --Kâl
         ,day_group_dt_rec.vis_n_num                 --Kâm
         ,day_group_dt_rec.vis_o_num                 --Kân
         ,day_group_dt_rec.vis_p_num                 --Kâo
         ,day_group_dt_rec.vis_q_num                 --Kâp
         ,day_group_dt_rec.vis_r_num                 --Kâq
         ,day_group_dt_rec.vis_s_num                 --Kâr
         ,day_group_dt_rec.vis_t_num                 --Kâs
         ,day_group_dt_rec.vis_u_num                 --Kât
         ,day_group_dt_rec.vis_v_num                 --Kâu
         ,day_group_dt_rec.vis_w_num                 --Kâv
         ,day_group_dt_rec.vis_x_num                 --Kâw
         ,day_group_dt_rec.vis_y_num                 --Kâx
         ,day_group_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_group_dt;
      -- *** DEBUG_LOG ***
      -- úÊO[vÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_grp  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE day_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_group || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_group                   --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_day_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_base_dt
   * Description      : úÊ_^ÛÊæ¾o^ (A-8)
   ***********************************************************************************/
  PROCEDURE insert_day_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_base_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- úÊ_^ÛÊf[^æ¾pJ[\
    CURSOR day_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code            sum_org_code          --WvgDbc
       ,xsvsr.sales_date                 sales_date            --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num         ) cust_new_num          --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num       --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num    --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt              --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt          --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt       --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt           --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt    --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt        --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt       --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt    --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_amt              ) tgt_amt               --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt           --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt        --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt            --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt     --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt         --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num               --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num           --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num        --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num            --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num     --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num         --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num            --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num         --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num           --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num       --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num    --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num        --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num     --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num        --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num             --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num             --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num             --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num             --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num             --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num             --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num             --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num             --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num             --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num             --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num             --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num             --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num             --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num             --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num             --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num             --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num             --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num             --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num             --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num             --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num             --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num             --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num             --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num             --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num             --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num             --Kây
      FROM
        xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- WvgDíÞ
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xsvsr.group_base_code  --O[ve_CD
               ,xsvsr.sales_date       --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- úÊ_^ÛÊf[^æ¾pR[h
     day_base_dt_rec day_base_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- úÊ_^ÛÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN day_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_day_base_dt>>
      LOOP
        FETCH day_base_dt_cur INTO day_base_dt_rec;
        -- oæ¾
        ln_extrct_cnt := day_base_dt_cur%ROWCOUNT;
        EXIT WHEN day_base_dt_cur%NOTFOUND
        OR  day_base_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_dept                      --WvgDíÞ
         ,day_base_dt_rec.sum_org_code              --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_day                     --úæª
         ,day_base_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,day_base_dt_rec.cust_new_num              --ÚqiVKj
         ,day_base_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,day_base_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,day_base_dt_rec.rslt_amt                  --ãÀÑ
         ,day_base_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,day_base_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,day_base_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,day_base_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,day_base_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,day_base_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,day_base_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,day_base_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,day_base_dt_rec.tgt_amt                   --ãvæ
         ,day_base_dt_rec.tgt_new_amt               --ãvæiVKj
         ,day_base_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,day_base_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,day_base_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,day_base_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,day_base_dt_rec.vis_num                   --KâÀÑ
         ,day_base_dt_rec.vis_new_num               --KâÀÑiVKj
         ,day_base_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,day_base_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,day_base_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,day_base_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,day_base_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,day_base_dt_rec.vis_sales_num             --Lø¬
         ,day_base_dt_rec.tgt_vis_num               --Kâvæ
         ,day_base_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,day_base_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,day_base_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,day_base_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,day_base_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,day_base_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,day_base_dt_rec.vis_a_num                 --Kâ`
         ,day_base_dt_rec.vis_b_num                 --Kâa
         ,day_base_dt_rec.vis_c_num                 --Kâb
         ,day_base_dt_rec.vis_d_num                 --Kâc
         ,day_base_dt_rec.vis_e_num                 --Kâd
         ,day_base_dt_rec.vis_f_num                 --Kâe
         ,day_base_dt_rec.vis_g_num                 --Kâf
         ,day_base_dt_rec.vis_h_num                 --Kâg
         ,day_base_dt_rec.vis_i_num                 --Kâú@
         ,day_base_dt_rec.vis_j_num                 --Kâi
         ,day_base_dt_rec.vis_k_num                 --Kâj
         ,day_base_dt_rec.vis_l_num                 --Kâk
         ,day_base_dt_rec.vis_m_num                 --Kâl
         ,day_base_dt_rec.vis_n_num                 --Kâm
         ,day_base_dt_rec.vis_o_num                 --Kân
         ,day_base_dt_rec.vis_p_num                 --Kâo
         ,day_base_dt_rec.vis_q_num                 --Kâp
         ,day_base_dt_rec.vis_r_num                 --Kâq
         ,day_base_dt_rec.vis_s_num                 --Kâr
         ,day_base_dt_rec.vis_t_num                 --Kâs
         ,day_base_dt_rec.vis_u_num                 --Kât
         ,day_base_dt_rec.vis_v_num                 --Kâu
         ,day_base_dt_rec.vis_w_num                 --Kâv
         ,day_base_dt_rec.vis_x_num                 --Kâw
         ,day_base_dt_rec.vis_y_num                 --Kâx
         ,day_base_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_base_dt;
      -- *** DEBUG_LOG ***
      -- úÊ_^ÛÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_base  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE day_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_base || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_base                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_day_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_area_dt
   * Description      : úÊnæcÆ^Êæ¾o^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_day_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_area_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- úÊnæcÆ^Êf[^æ¾pJ[\
    CURSOR day_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --WvgDbc
       ,xsvsr.sales_date                 sales_date                 --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --Kây
      FROM
        xxcso_aff_base_level_v xablv  -- AFFåKw}X^r[
       ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_dept  -- WvgDíÞ
        AND  xablv.child_base_code = xsvsr.sum_org_code  -- _R[hiqj
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xablv.base_code        --_R[h
               ,xsvsr.sales_date       --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- úÊnæcÆ^Êf[^æ¾pR[h
     day_area_dt_rec day_area_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- úÊnæcÆ^Êf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN day_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_day_area_dt>>
      LOOP
        FETCH day_area_dt_cur INTO day_area_dt_rec;
        -- oæ¾
        ln_extrct_cnt := day_area_dt_cur%ROWCOUNT;
        EXIT WHEN day_area_dt_cur%NOTFOUND
        OR  day_area_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_area                      --WvgDíÞ
         ,day_area_dt_rec.sum_org_code              --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_day                     --úæª
         ,day_area_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,day_area_dt_rec.cust_new_num              --ÚqiVKj
         ,day_area_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,day_area_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,day_area_dt_rec.rslt_amt                  --ãÀÑ
         ,day_area_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,day_area_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,day_area_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,day_area_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,day_area_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,day_area_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,day_area_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,day_area_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,day_area_dt_rec.tgt_amt                   --ãvæ
         ,day_area_dt_rec.tgt_new_amt               --ãvæiVKj
         ,day_area_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,day_area_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,day_area_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,day_area_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,day_area_dt_rec.vis_num                   --KâÀÑ
         ,day_area_dt_rec.vis_new_num               --KâÀÑiVKj
         ,day_area_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,day_area_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,day_area_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,day_area_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,day_area_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,day_area_dt_rec.vis_sales_num             --Lø¬
         ,day_area_dt_rec.tgt_vis_num               --Kâvæ
         ,day_area_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,day_area_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,day_area_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,day_area_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,day_area_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,day_area_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,day_area_dt_rec.vis_a_num                 --Kâ`
         ,day_area_dt_rec.vis_b_num                 --Kâa
         ,day_area_dt_rec.vis_c_num                 --Kâb
         ,day_area_dt_rec.vis_d_num                 --Kâc
         ,day_area_dt_rec.vis_e_num                 --Kâd
         ,day_area_dt_rec.vis_f_num                 --Kâe
         ,day_area_dt_rec.vis_g_num                 --Kâf
         ,day_area_dt_rec.vis_h_num                 --Kâg
         ,day_area_dt_rec.vis_i_num                 --Kâú@
         ,day_area_dt_rec.vis_j_num                 --Kâi
         ,day_area_dt_rec.vis_k_num                 --Kâj
         ,day_area_dt_rec.vis_l_num                 --Kâk
         ,day_area_dt_rec.vis_m_num                 --Kâl
         ,day_area_dt_rec.vis_n_num                 --Kâm
         ,day_area_dt_rec.vis_o_num                 --Kân
         ,day_area_dt_rec.vis_p_num                 --Kâo
         ,day_area_dt_rec.vis_q_num                 --Kâp
         ,day_area_dt_rec.vis_r_num                 --Kâq
         ,day_area_dt_rec.vis_s_num                 --Kâr
         ,day_area_dt_rec.vis_t_num                 --Kâs
         ,day_area_dt_rec.vis_u_num                 --Kât
         ,day_area_dt_rec.vis_v_num                 --Kâu
         ,day_area_dt_rec.vis_w_num                 --Kâv
         ,day_area_dt_rec.vis_x_num                 --Kâw
         ,day_area_dt_rec.vis_y_num                 --Kâx
         ,day_area_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- úÊnæcÆ^Êæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_area  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE day_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_area || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_area                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (day_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_day_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_acct_dt
   * Description      : ÊÚqÊæ¾o^ (A-10)
   ***********************************************************************************/
  PROCEDURE insert_mon_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_acct_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- ÊÚqÊf[^æ¾pJ[\
    CURSOR mon_acct_dt_cur
    IS
      SELECT
        xsvsr.sum_org_code               sum_org_code               --WvgDbc
/* 20090519_Ogawa_T1_1024 START*/
       ,xsvsr.group_base_code            group_base_code            --O[ve_bc
/* 20090519_Ogawa_T1_1024 END*/
       ,SUBSTRB(xsvsr.sales_date, 1, 6)  sales_date                 --ÌNú^ÌN
       ,xsvsr.gvm_type                   gvm_type                   --êÊ^©Ì@^lb
       ,MAX(xsvsr.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,MAX(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,MAX(xsvsr.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --Kây
      FROM
/* 20090519_Ogawa_T1_1024 START*/
--      xxcso_cust_accounts_v xcav  -- Úq}X^r[
--     ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
        xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
/* 20090519_Ogawa_T1_1024 END*/
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- WvgDíÞ
/* 20090519_Ogawa_T1_1024 START*/
--      AND  xcav.account_number = xsvsr.sum_org_code  -- ÚqR[h
/* 20090519_Ogawa_T1_1024 END*/
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- úæª
        AND  SUBSTRB(xsvsr.sales_date, 1, 6) IN (
                                                  gv_ym_lst_1
                                                 ,gv_ym_lst_2
                                                 ,gv_ym_lst_3
                                                 ,gv_ym_lst_4
                                                 ,gv_ym_lst_5
                                                 ,gv_ym_lst_6
                                                )  -- ÌNú
/* 20090519_Ogawa_T1_1024 START*/
--      AND  ((
--                  (
--                   xcav.customer_class_code IS NULL -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_10
--                                            ,cv_customer_status_20
--                                           )  -- ÚqXe[^X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_10 -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_25
--                                            ,cv_customer_status_30
--                                            ,cv_customer_status_40
--                                            ,cv_customer_status_50
--                                           )  -- ÚqXe[^X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_12 -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_30
--                                            ,cv_customer_status_40
--                                           )  -- ÚqXe[^X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_15 -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_16 -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_17 -- Úqæª
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- ÚqXe[^X
--                  )
--           ))
/* 20090519_Ogawa_T1_1024 END*/
      GROUP BY  sum_org_code  --ÚqR[h
/* 20090519_Ogawa_T1_1024 START*/
               ,xsvsr.group_base_code  --O[ve_bc
/* 20090519_Ogawa_T1_1024 END*/
               ,SUBSTRB(xsvsr.sales_date, 1, 6)       --ÌNú
               ,gvm_type         --êÊ^©Ì@^lb
    ;
    -- *** [JER[h ***
    -- ÊÚqÊf[^æ¾pR[h
     mon_acct_dt_rec mon_acct_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- ÊÚqÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN mon_acct_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_acct || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_mon_acct_dt>>
      LOOP
        FETCH mon_acct_dt_cur INTO mon_acct_dt_rec;
        -- oæ¾
        ln_extrct_cnt := mon_acct_dt_cur%ROWCOUNT;
        EXIT WHEN mon_acct_dt_cur%NOTFOUND
        OR  mon_acct_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                              --ì¬Ò
         ,cd_creation_date                           --ì¬ú
         ,cn_last_updated_by                         --ÅIXVÒ
         ,cd_last_update_date                        --ÅIXVú
         ,cn_last_update_login                       --ÅIXVOC
         ,cn_request_id                              --vID
         ,cn_program_application_id                  --RJgEvOEAvP[VID
         ,cn_program_id                              --RJgEvOID
         ,cd_program_update_date                     --vOXVú
         ,cv_sum_org_type_accnt                      --WvgDíÞ
         ,mon_acct_dt_rec.sum_org_code               --WvgDbc
/* 20090519_Ogawa_T1_1024 START*/
--       ,cv_null                                    --O[ve_bc
         ,mon_acct_dt_rec.group_base_code
/* 20090519_Ogawa_T1_1024 END*/
         ,cv_month_date_div_mon                      --úæª
         ,mon_acct_dt_rec.sales_date                 --ÌNú^ÌN
         ,mon_acct_dt_rec.gvm_type                   --êÊ^©Ì@^lb
         ,mon_acct_dt_rec.cust_new_num               --ÚqiVKj
         ,mon_acct_dt_rec.cust_vd_new_num            --ÚqiVDFVKj
         ,mon_acct_dt_rec.cust_other_new_num         --ÚqiVDÈOFVKj
         ,mon_acct_dt_rec.rslt_amt                   --ãÀÑ
         ,mon_acct_dt_rec.rslt_new_amt               --ãÀÑiVKj
         ,mon_acct_dt_rec.rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,mon_acct_dt_rec.rslt_vd_amt                --ãÀÑiVDj
         ,mon_acct_dt_rec.rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,mon_acct_dt_rec.rslt_other_amt             --ãÀÑiVDÈOj
         ,mon_acct_dt_rec.rslt_center_amt            --à¼_QãÀÑ
         ,mon_acct_dt_rec.rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,mon_acct_dt_rec.rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,mon_acct_dt_rec.tgt_amt                    --ãvæ
         ,mon_acct_dt_rec.tgt_new_amt                --ãvæiVKj
         ,mon_acct_dt_rec.tgt_vd_new_amt             --ãvæiVDFVKj
         ,mon_acct_dt_rec.tgt_vd_amt                 --ãvæiVDj
         ,mon_acct_dt_rec.tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,mon_acct_dt_rec.tgt_other_amt              --ãvæiVDÈOj
         ,mon_acct_dt_rec.vis_num                    --KâÀÑ
         ,mon_acct_dt_rec.vis_new_num                --KâÀÑiVKj
         ,mon_acct_dt_rec.vis_vd_new_num             --KâÀÑiVDFVKj
         ,mon_acct_dt_rec.vis_vd_num                 --KâÀÑiVDj
         ,mon_acct_dt_rec.vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,mon_acct_dt_rec.vis_other_num              --KâÀÑiVDÈOj
         ,mon_acct_dt_rec.vis_mc_num                 --KâÀÑiMCj
         ,mon_acct_dt_rec.vis_sales_num              --Lø¬
         ,mon_acct_dt_rec.tgt_vis_num                --Kâvæ
         ,mon_acct_dt_rec.tgt_vis_new_num            --KâvæiVKj
         ,mon_acct_dt_rec.tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,mon_acct_dt_rec.tgt_vis_vd_num             --KâvæiVDj
         ,mon_acct_dt_rec.tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,mon_acct_dt_rec.tgt_vis_other_num          --KâvæiVDÈOj
         ,mon_acct_dt_rec.tgt_vis_mc_num             --KâvæiMCj
         ,mon_acct_dt_rec.vis_a_num                  --Kâ`
         ,mon_acct_dt_rec.vis_b_num                  --Kâa
         ,mon_acct_dt_rec.vis_c_num                  --Kâb
         ,mon_acct_dt_rec.vis_d_num                  --Kâc
         ,mon_acct_dt_rec.vis_e_num                  --Kâd
         ,mon_acct_dt_rec.vis_f_num                  --Kâe
         ,mon_acct_dt_rec.vis_g_num                  --Kâf
         ,mon_acct_dt_rec.vis_h_num                  --Kâg
         ,mon_acct_dt_rec.vis_i_num                  --Kâú@
         ,mon_acct_dt_rec.vis_j_num                  --Kâi
         ,mon_acct_dt_rec.vis_k_num                  --Kâj
         ,mon_acct_dt_rec.vis_l_num                  --Kâk
         ,mon_acct_dt_rec.vis_m_num                  --Kâl
         ,mon_acct_dt_rec.vis_n_num                  --Kâm
         ,mon_acct_dt_rec.vis_o_num                  --Kân
         ,mon_acct_dt_rec.vis_p_num                  --Kâo
         ,mon_acct_dt_rec.vis_q_num                  --Kâp
         ,mon_acct_dt_rec.vis_r_num                  --Kâq
         ,mon_acct_dt_rec.vis_s_num                  --Kâr
         ,mon_acct_dt_rec.vis_t_num                  --Kâs
         ,mon_acct_dt_rec.vis_u_num                  --Kât
         ,mon_acct_dt_rec.vis_v_num                  --Kâu
         ,mon_acct_dt_rec.vis_w_num                  --Kâv
         ,mon_acct_dt_rec.vis_x_num                  --Kâw
         ,mon_acct_dt_rec.vis_y_num                  --Kâx
         ,mon_acct_dt_rec.vis_z_num                  --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_acct_dt;
      -- *** DEBUG_LOG ***
      -- ÊÚqÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_acct  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE mon_acct_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_acct || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_acct                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_acct_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_mon_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_emp_dt
   * Description      : ÊcÆõÊæ¾o^ (A-11)
   ***********************************************************************************/
  PROCEDURE insert_mon_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_emp_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- ÊcÆõÊf[^æ¾pJ[\
    CURSOR mon_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --WvgDbc
       ,xsvsr.sales_date                 sales_date                 --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,MAX(
            DECODE(xdmp.sales_plan_rel_div
                   ,'1', xspmp.tgt_sales_prsn_total_amt
                   ,'2', xspmp.bsc_sls_prsn_total_amt
                  )
           )                             tgt_sales_prsn_total_amt   --Êã\Z
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --Kây
      FROM
        xxcso_cust_resources_v2 xcrv2  -- ÚqScÆõiÅVjr[
       ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
       ,xxcso_sls_prsn_mnthly_plns xspmp  -- cÆõÊÊvæe[u
       ,xxcso_resources_v2 xrv2  -- \[X}X^iÅVjr[
       ,xxcso_dept_monthly_plans xdmp  -- _ÊÊvæe[u
      WHERE  xcrv2.account_number = xsvsr.sum_org_code  -- ÚqR[h
        AND  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- WvgDíÞ
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- ÌNú
        AND  xcrv2.employee_number =  xspmp.employee_number --]ÆõÔicÆõÊÊvæTBLj
        AND  xcrv2.employee_number =  xrv2.employee_number --]ÆõÔi\[X}X^j
        AND  (
              CASE WHEN (
                         TO_DATE(xrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                        )
                   THEN  xrv2.work_base_code_new
                   ELSE  xrv2.work_base_code_old
              END
             ) = xspmp.base_code  -- Î±n_R[h­ßú»f
        AND  xsvsr.sales_date = xspmp.year_month  -- ÌNú
        AND  xdmp.base_code = xspmp.base_code  -- _CD
        AND  xdmp.year_month = xspmp.year_month  -- N
      GROUP BY  xcrv2.employee_number    --]ÆõÔ
               ,xsvsr.sales_date         --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- ÊcÆõÊf[^æ¾pR[h
     mon_emp_dt_rec mon_emp_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- ÊcÆõÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN mon_emp_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_emp || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_mon_emp_dt>>
      LOOP
        FETCH mon_emp_dt_cur INTO mon_emp_dt_rec;
        -- oæ¾
        ln_extrct_cnt := mon_emp_dt_cur%ROWCOUNT;
        EXIT WHEN mon_emp_dt_cur%NOTFOUND
        OR  mon_emp_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_sales_prsn_total_amt   --Êã\Z
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_emp                       --WvgDíÞ
         ,mon_emp_dt_rec.sum_org_code               --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_mon                     --úæª
         ,mon_emp_dt_rec.sales_date                 --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,mon_emp_dt_rec.cust_new_num               --ÚqiVKj
         ,mon_emp_dt_rec.cust_vd_new_num            --ÚqiVDFVKj
         ,mon_emp_dt_rec.cust_other_new_num         --ÚqiVDÈOFVKj
         ,mon_emp_dt_rec.rslt_amt                   --ãÀÑ
         ,mon_emp_dt_rec.rslt_new_amt               --ãÀÑiVKj
         ,mon_emp_dt_rec.rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,mon_emp_dt_rec.rslt_vd_amt                --ãÀÑiVDj
         ,mon_emp_dt_rec.rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,mon_emp_dt_rec.rslt_other_amt             --ãÀÑiVDÈOj
         ,mon_emp_dt_rec.rslt_center_amt            --à¼_QãÀÑ
         ,mon_emp_dt_rec.rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,mon_emp_dt_rec.rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,mon_emp_dt_rec.tgt_sales_prsn_total_amt   --Êã\Z
         ,mon_emp_dt_rec.tgt_amt                    --ãvæ
         ,mon_emp_dt_rec.tgt_new_amt                --ãvæiVKj
         ,mon_emp_dt_rec.tgt_vd_new_amt             --ãvæiVDFVKj
         ,mon_emp_dt_rec.tgt_vd_amt                 --ãvæiVDj
         ,mon_emp_dt_rec.tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,mon_emp_dt_rec.tgt_other_amt              --ãvæiVDÈOj
         ,mon_emp_dt_rec.vis_num                    --KâÀÑ
         ,mon_emp_dt_rec.vis_new_num                --KâÀÑiVKj
         ,mon_emp_dt_rec.vis_vd_new_num             --KâÀÑiVDFVKj
         ,mon_emp_dt_rec.vis_vd_num                 --KâÀÑiVDj
         ,mon_emp_dt_rec.vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,mon_emp_dt_rec.vis_other_num              --KâÀÑiVDÈOj
         ,mon_emp_dt_rec.vis_mc_num                 --KâÀÑiMCj
         ,mon_emp_dt_rec.vis_sales_num              --Lø¬
         ,mon_emp_dt_rec.tgt_vis_num                --Kâvæ
         ,mon_emp_dt_rec.tgt_vis_new_num            --KâvæiVKj
         ,mon_emp_dt_rec.tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,mon_emp_dt_rec.tgt_vis_vd_num             --KâvæiVDj
         ,mon_emp_dt_rec.tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,mon_emp_dt_rec.tgt_vis_other_num          --KâvæiVDÈOj
         ,mon_emp_dt_rec.tgt_vis_mc_num             --KâvæiMCj
         ,mon_emp_dt_rec.vis_a_num                  --Kâ`
         ,mon_emp_dt_rec.vis_b_num                  --Kâa
         ,mon_emp_dt_rec.vis_c_num                  --Kâb
         ,mon_emp_dt_rec.vis_d_num                  --Kâc
         ,mon_emp_dt_rec.vis_e_num                  --Kâd
         ,mon_emp_dt_rec.vis_f_num                  --Kâe
         ,mon_emp_dt_rec.vis_g_num                  --Kâf
         ,mon_emp_dt_rec.vis_h_num                  --Kâg
         ,mon_emp_dt_rec.vis_i_num                  --Kâú@
         ,mon_emp_dt_rec.vis_j_num                  --Kâi
         ,mon_emp_dt_rec.vis_k_num                  --Kâj
         ,mon_emp_dt_rec.vis_l_num                  --Kâk
         ,mon_emp_dt_rec.vis_m_num                  --Kâl
         ,mon_emp_dt_rec.vis_n_num                  --Kâm
         ,mon_emp_dt_rec.vis_o_num                  --Kân
         ,mon_emp_dt_rec.vis_p_num                  --Kâo
         ,mon_emp_dt_rec.vis_q_num                  --Kâp
         ,mon_emp_dt_rec.vis_r_num                  --Kâq
         ,mon_emp_dt_rec.vis_s_num                  --Kâr
         ,mon_emp_dt_rec.vis_t_num                  --Kâs
         ,mon_emp_dt_rec.vis_u_num                  --Kât
         ,mon_emp_dt_rec.vis_v_num                  --Kâu
         ,mon_emp_dt_rec.vis_w_num                  --Kâv
         ,mon_emp_dt_rec.vis_x_num                  --Kâw
         ,mon_emp_dt_rec.vis_y_num                  --Kâx
         ,mon_emp_dt_rec.vis_z_num                  --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_emp_dt;
      -- *** DEBUG_LOG ***
      -- ÊcÆõÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_emp  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE mon_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_emp || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_emp                     --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_mon_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_group_dt
   * Description      : ÊcÆO[vÊæ¾o^ (A-12)
   ***********************************************************************************/
  PROCEDURE insert_mon_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_group_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- ÊcÆO[vÊf[^æ¾pJ[\
    CURSOR mon_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code                  sum_org_code               --WvgDbc
       ,inn_v.group_base_code               group_base_code            --O[ve_bc
       ,inn_v.sales_date                    sales_date                 --ÌNú^ÌN
       ,SUM(inn_v.cust_new_num            ) cust_new_num               --ÚqiVKj
       ,SUM(inn_v.cust_vd_new_num         ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(inn_v.cust_other_new_num      ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(inn_v.rslt_amt                ) rslt_amt                   --ãÀÑ
       ,SUM(inn_v.rslt_new_amt            ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(inn_v.rslt_vd_new_amt         ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(inn_v.rslt_vd_amt             ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(inn_v.rslt_other_new_amt      ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(inn_v.rslt_other_amt          ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(inn_v.rslt_center_amt         ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(inn_v.rslt_center_vd_amt      ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(inn_v.rslt_center_other_amt   ) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(inn_v.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --Êã\Z
       ,SUM(inn_v.tgt_amt                 ) tgt_amt                    --ãvæ
       ,SUM(inn_v.tgt_new_amt             ) tgt_new_amt                --ãvæiVKj
       ,SUM(inn_v.tgt_vd_new_amt          ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(inn_v.tgt_vd_amt              ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(inn_v.tgt_other_new_amt       ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(inn_v.tgt_other_amt           ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(inn_v.vis_num                 ) vis_num                    --KâÀÑ
       ,SUM(inn_v.vis_new_num             ) vis_new_num                --KâÀÑiVKj
       ,SUM(inn_v.vis_vd_new_num          ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(inn_v.vis_vd_num              ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(inn_v.vis_other_new_num       ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(inn_v.vis_other_num           ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(inn_v.vis_mc_num              ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(inn_v.vis_sales_num           ) vis_sales_num              --Lø¬
       ,SUM(inn_v.tgt_vis_num             ) tgt_vis_num                --Kâvæ
       ,SUM(inn_v.tgt_vis_new_num         ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(inn_v.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(inn_v.tgt_vis_vd_num          ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(inn_v.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(inn_v.tgt_vis_other_num       ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(inn_v.tgt_vis_mc_num          ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(inn_v.vis_a_num               ) vis_a_num                  --Kâ`
       ,SUM(inn_v.vis_b_num               ) vis_b_num                  --Kâa
       ,SUM(inn_v.vis_c_num               ) vis_c_num                  --Kâb
       ,SUM(inn_v.vis_d_num               ) vis_d_num                  --Kâc
       ,SUM(inn_v.vis_e_num               ) vis_e_num                  --Kâd
       ,SUM(inn_v.vis_f_num               ) vis_f_num                  --Kâe
       ,SUM(inn_v.vis_g_num               ) vis_g_num                  --Kâf
       ,SUM(inn_v.vis_h_num               ) vis_h_num                  --Kâg
       ,SUM(inn_v.vis_i_num               ) vis_i_num                  --Kâú@
       ,SUM(inn_v.vis_j_num               ) vis_j_num                  --Kâi
       ,SUM(inn_v.vis_k_num               ) vis_k_num                  --Kâj
       ,SUM(inn_v.vis_l_num               ) vis_l_num                  --Kâk
       ,SUM(inn_v.vis_m_num               ) vis_m_num                  --Kâl
       ,SUM(inn_v.vis_n_num               ) vis_n_num                  --Kâm
       ,SUM(inn_v.vis_o_num               ) vis_o_num                  --Kân
       ,SUM(inn_v.vis_p_num               ) vis_p_num                  --Kâo
       ,SUM(inn_v.vis_q_num               ) vis_q_num                  --Kâp
       ,SUM(inn_v.vis_r_num               ) vis_r_num                  --Kâq
       ,SUM(inn_v.vis_s_num               ) vis_s_num                  --Kâr
       ,SUM(inn_v.vis_t_num               ) vis_t_num                  --Kâs
       ,SUM(inn_v.vis_u_num               ) vis_u_num                  --Kât
       ,SUM(inn_v.vis_v_num               ) vis_v_num                  --Kâu
       ,SUM(inn_v.vis_w_num               ) vis_w_num                  --Kâv
       ,SUM(inn_v.vis_x_num               ) vis_x_num                  --Kâw
       ,SUM(inn_v.vis_y_num               ) vis_y_num                  --Kâx
       ,SUM(inn_v.vis_z_num               ) vis_z_num                  --Kây
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code               --WvgDbc
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code            --O[ve_bc
          ,xsvsr.sales_date                 sales_date                 --ÌNú^ÌN
          ,xsvsr.cust_new_num               cust_new_num               --ÚqiVKj
          ,xsvsr.cust_vd_new_num            cust_vd_new_num            --ÚqiVDFVKj
          ,xsvsr.cust_other_new_num         cust_other_new_num         --ÚqiVDÈOFVKj
          ,xsvsr.rslt_amt                   rslt_amt                   --ãÀÑ
          ,xsvsr.rslt_new_amt               rslt_new_amt               --ãÀÑiVKj
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt            --ãÀÑiVDFVKj
          ,xsvsr.rslt_vd_amt                rslt_vd_amt                --ãÀÑiVDj
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt         --ãÀÑiVDÈOFVKj
          ,xsvsr.rslt_other_amt             rslt_other_amt             --ãÀÑiVDÈOj
          ,xsvsr.rslt_center_amt            rslt_center_amt            --à¼_QãÀÑ
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt         --à¼_QãÀÑiVDj
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
          ,xsvsr.tgt_sales_prsn_total_amt   tgt_sales_prsn_total_amt   --Êã\Z
          ,xsvsr.tgt_amt                    tgt_amt                    --ãvæ
          ,xsvsr.tgt_new_amt                tgt_new_amt                --ãvæiVKj
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt             --ãvæiVDFVKj
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt                 --ãvæiVDj
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt          --ãvæiVDÈOFVKj
          ,xsvsr.tgt_other_amt              tgt_other_amt              --ãvæiVDÈOj
          ,xsvsr.vis_num                    vis_num                    --KâÀÑ
          ,xsvsr.vis_new_num                vis_new_num                --KâÀÑiVKj
          ,xsvsr.vis_vd_new_num             vis_vd_new_num             --KâÀÑiVDFVKj
          ,xsvsr.vis_vd_num                 vis_vd_num                 --KâÀÑiVDj
          ,xsvsr.vis_other_new_num          vis_other_new_num          --KâÀÑiVDÈOFVKj
          ,xsvsr.vis_other_num              vis_other_num              --KâÀÑiVDÈOj
          ,xsvsr.vis_mc_num                 vis_mc_num                 --KâÀÑiMCj
          ,xsvsr.vis_sales_num              vis_sales_num              --Lø¬
          ,xsvsr.tgt_vis_num                tgt_vis_num                --Kâvæ
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num            --KâvæiVKj
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num         --KâvæiVDFVKj
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num             --KâvæiVDj
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num      --KâvæiVDÈOFVKj
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num          --KâvæiVDÈOj
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num             --KâvæiMCj
          ,xsvsr.vis_a_num                  vis_a_num                  --Kâ`
          ,xsvsr.vis_b_num                  vis_b_num                  --Kâa
          ,xsvsr.vis_c_num                  vis_c_num                  --Kâb
          ,xsvsr.vis_d_num                  vis_d_num                  --Kâc
          ,xsvsr.vis_e_num                  vis_e_num                  --Kâd
          ,xsvsr.vis_f_num                  vis_f_num                  --Kâe
          ,xsvsr.vis_g_num                  vis_g_num                  --Kâf
          ,xsvsr.vis_h_num                  vis_h_num                  --Kâg
          ,xsvsr.vis_i_num                  vis_i_num                  --Kâú@
          ,xsvsr.vis_j_num                  vis_j_num                  --Kâi
          ,xsvsr.vis_k_num                  vis_k_num                  --Kâj
          ,xsvsr.vis_l_num                  vis_l_num                  --Kâk
          ,xsvsr.vis_m_num                  vis_m_num                  --Kâl
          ,xsvsr.vis_n_num                  vis_n_num                  --Kâm
          ,xsvsr.vis_o_num                  vis_o_num                  --Kân
          ,xsvsr.vis_p_num                  vis_p_num                  --Kâo
          ,xsvsr.vis_q_num                  vis_q_num                  --Kâp
          ,xsvsr.vis_r_num                  vis_r_num                  --Kâq
          ,xsvsr.vis_s_num                  vis_s_num                  --Kâr
          ,xsvsr.vis_t_num                  vis_t_num                  --Kâs
          ,xsvsr.vis_u_num                  vis_u_num                  --Kât
          ,xsvsr.vis_v_num                  vis_v_num                  --Kâu
          ,xsvsr.vis_w_num                  vis_w_num                  --Kâv
          ,xsvsr.vis_x_num                  vis_x_num                  --Kâw
          ,xsvsr.vis_y_num                  vis_y_num                  --Kâx
          ,xsvsr.vis_z_num                  vis_z_num                  --Kây
         FROM
           xxcso_resource_relations_v2 xrrv2  -- \[XÖA}X^iÅVjr[
          ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
         WHERE  xrrv2.employee_number = xsvsr.sum_org_code  -- ]ÆõÔ
           AND  xsvsr.sum_org_type = cv_sum_org_type_emp  -- WvgDíÞ
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- ÌNú
        ) inn_v
      GROUP BY  inn_v.sum_org_code     --O[vÔ
               ,inn_v.group_base_code  --O[ve_bc
               ,inn_v.sales_date       --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- ÊcÆO[vÊf[^æ¾pR[h
     mon_group_dt_rec mon_group_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- ÊcÆO[vÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN mon_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_mon_group_dt>>
      LOOP
        FETCH mon_group_dt_cur INTO mon_group_dt_rec;
        -- oæ¾
        ln_extrct_cnt := mon_group_dt_cur%ROWCOUNT;
        EXIT WHEN mon_group_dt_cur%NOTFOUND
        OR  mon_group_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_sales_prsn_total_amt   --Êã\Z
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                              --ì¬Ò
         ,cd_creation_date                           --ì¬ú
         ,cn_last_updated_by                         --ÅIXVÒ
         ,cd_last_update_date                        --ÅIXVú
         ,cn_last_update_login                       --ÅIXVOC
         ,cn_request_id                              --vID
         ,cn_program_application_id                  --RJgEvOEAvP[VID
         ,cn_program_id                              --RJgEvOID
         ,cd_program_update_date                     --vOXVú
         ,cv_sum_org_type_group                      --WvgDíÞ
         ,mon_group_dt_rec.sum_org_code              --WvgDbc
         ,mon_group_dt_rec.group_base_code           --O[ve_bc
         ,cv_month_date_div_mon                      --úæª
         ,mon_group_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                       --êÊ^©Ì@^lb
         ,mon_group_dt_rec.cust_new_num              --ÚqiVKj
         ,mon_group_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,mon_group_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,mon_group_dt_rec.rslt_amt                  --ãÀÑ
         ,mon_group_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,mon_group_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,mon_group_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,mon_group_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,mon_group_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,mon_group_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,mon_group_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,mon_group_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,mon_group_dt_rec.tgt_sales_prsn_total_amt  --Êã\Z
         ,mon_group_dt_rec.tgt_amt                   --ãvæ
         ,mon_group_dt_rec.tgt_new_amt               --ãvæiVKj
         ,mon_group_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,mon_group_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,mon_group_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,mon_group_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,mon_group_dt_rec.vis_num                   --KâÀÑ
         ,mon_group_dt_rec.vis_new_num               --KâÀÑiVKj
         ,mon_group_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,mon_group_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,mon_group_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,mon_group_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,mon_group_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,mon_group_dt_rec.vis_sales_num             --Lø¬
         ,mon_group_dt_rec.tgt_vis_num               --Kâvæ
         ,mon_group_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,mon_group_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,mon_group_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,mon_group_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,mon_group_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,mon_group_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,mon_group_dt_rec.vis_a_num                 --Kâ`
         ,mon_group_dt_rec.vis_b_num                 --Kâa
         ,mon_group_dt_rec.vis_c_num                 --Kâb
         ,mon_group_dt_rec.vis_d_num                 --Kâc
         ,mon_group_dt_rec.vis_e_num                 --Kâd
         ,mon_group_dt_rec.vis_f_num                 --Kâe
         ,mon_group_dt_rec.vis_g_num                 --Kâf
         ,mon_group_dt_rec.vis_h_num                 --Kâg
         ,mon_group_dt_rec.vis_i_num                 --Kâú@
         ,mon_group_dt_rec.vis_j_num                 --Kâi
         ,mon_group_dt_rec.vis_k_num                 --Kâj
         ,mon_group_dt_rec.vis_l_num                 --Kâk
         ,mon_group_dt_rec.vis_m_num                 --Kâl
         ,mon_group_dt_rec.vis_n_num                 --Kâm
         ,mon_group_dt_rec.vis_o_num                 --Kân
         ,mon_group_dt_rec.vis_p_num                 --Kâo
         ,mon_group_dt_rec.vis_q_num                 --Kâp
         ,mon_group_dt_rec.vis_r_num                 --Kâq
         ,mon_group_dt_rec.vis_s_num                 --Kâr
         ,mon_group_dt_rec.vis_t_num                 --Kâs
         ,mon_group_dt_rec.vis_u_num                 --Kât
         ,mon_group_dt_rec.vis_v_num                 --Kâu
         ,mon_group_dt_rec.vis_w_num                 --Kâv
         ,mon_group_dt_rec.vis_x_num                 --Kâw
         ,mon_group_dt_rec.vis_y_num                 --Kâx
         ,mon_group_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_group_dt;
      -- *** DEBUG_LOG ***
      -- ÊcÆO[vÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_grp  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE mon_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_group || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_group                   --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_mon_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_base_dt
   * Description      : Ê_^ÛÊæ¾o^ (A-13)
   ***********************************************************************************/
  PROCEDURE insert_mon_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_base_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- Ê_^ÛÊf[^æ¾pJ[\
    CURSOR mon_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code               sum_org_code               --WvgDbc
       ,xsvsr.sales_date                    sales_date                 --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num            ) cust_new_num               --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num         ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num      ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt                ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt            ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt         ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt             ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt      ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt          ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt         ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt      ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt   ) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --Êã\Z
       ,SUM(xsvsr.tgt_amt                 ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt             ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt          ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt              ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt       ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt           ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num                 ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num             ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num          ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num              ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num       ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num           ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num              ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num           ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num             ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num         ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num          ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num       ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num          ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num               ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num               ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num               ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num               ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num               ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num               ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num               ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num               ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num               ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num               ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num               ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num               ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num               ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num               ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num               ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num               ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num               ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num               ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num               ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num               ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num               ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num               ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num               ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num               ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num               ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num               ) vis_z_num                  --Kây
      FROM
           xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- WvgDíÞ
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- ÌNú
      GROUP BY  xsvsr.group_base_code     --Î±n_R[h
               ,xsvsr.sales_date          --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- Ê_^ÛÊf[^æ¾pR[h
     mon_base_dt_rec mon_base_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- Ê_^ÛÊf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN mon_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_mon_base_dt>>
      LOOP
        FETCH mon_base_dt_cur INTO mon_base_dt_rec;
        -- oæ¾
        ln_extrct_cnt := mon_base_dt_cur%ROWCOUNT;
        EXIT WHEN mon_base_dt_cur%NOTFOUND
        OR  mon_base_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_sales_prsn_total_amt   --Êã\Z
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_dept                      --WvgDíÞ
         ,mon_base_dt_rec.sum_org_code              --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_mon                     --úæª
         ,mon_base_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,mon_base_dt_rec.cust_new_num              --ÚqiVKj
         ,mon_base_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,mon_base_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,mon_base_dt_rec.rslt_amt                  --ãÀÑ
         ,mon_base_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,mon_base_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,mon_base_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,mon_base_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,mon_base_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,mon_base_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,mon_base_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,mon_base_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,mon_base_dt_rec.tgt_sales_prsn_total_amt  --Êã\Z
         ,mon_base_dt_rec.tgt_amt                   --ãvæ
         ,mon_base_dt_rec.tgt_new_amt               --ãvæiVKj
         ,mon_base_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,mon_base_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,mon_base_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,mon_base_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,mon_base_dt_rec.vis_num                   --KâÀÑ
         ,mon_base_dt_rec.vis_new_num               --KâÀÑiVKj
         ,mon_base_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,mon_base_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,mon_base_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,mon_base_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,mon_base_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,mon_base_dt_rec.vis_sales_num             --Lø¬
         ,mon_base_dt_rec.tgt_vis_num               --Kâvæ
         ,mon_base_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,mon_base_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,mon_base_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,mon_base_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,mon_base_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,mon_base_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,mon_base_dt_rec.vis_a_num                 --Kâ`
         ,mon_base_dt_rec.vis_b_num                 --Kâa
         ,mon_base_dt_rec.vis_c_num                 --Kâb
         ,mon_base_dt_rec.vis_d_num                 --Kâc
         ,mon_base_dt_rec.vis_e_num                 --Kâd
         ,mon_base_dt_rec.vis_f_num                 --Kâe
         ,mon_base_dt_rec.vis_g_num                 --Kâf
         ,mon_base_dt_rec.vis_h_num                 --Kâg
         ,mon_base_dt_rec.vis_i_num                 --Kâú@
         ,mon_base_dt_rec.vis_j_num                 --Kâi
         ,mon_base_dt_rec.vis_k_num                 --Kâj
         ,mon_base_dt_rec.vis_l_num                 --Kâk
         ,mon_base_dt_rec.vis_m_num                 --Kâl
         ,mon_base_dt_rec.vis_n_num                 --Kâm
         ,mon_base_dt_rec.vis_o_num                 --Kân
         ,mon_base_dt_rec.vis_p_num                 --Kâo
         ,mon_base_dt_rec.vis_q_num                 --Kâp
         ,mon_base_dt_rec.vis_r_num                 --Kâq
         ,mon_base_dt_rec.vis_s_num                 --Kâr
         ,mon_base_dt_rec.vis_t_num                 --Kâs
         ,mon_base_dt_rec.vis_u_num                 --Kât
         ,mon_base_dt_rec.vis_v_num                 --Kâu
         ,mon_base_dt_rec.vis_w_num                 --Kâv
         ,mon_base_dt_rec.vis_x_num                 --Kâw
         ,mon_base_dt_rec.vis_y_num                 --Kâx
         ,mon_base_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_base_dt;
      -- *** DEBUG_LOG ***
      -- Ê_^ÛÊæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_base  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE mon_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_base || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_base                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_mon_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_area_dt
   * Description      : ÊnæcÆ^Êæ¾o^ (A-14)
   ***********************************************************************************/
  PROCEDURE insert_mon_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_area_dt';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
--
    -- ===============================
    -- [U[é¾
    -- ===============================
    -- *** [Jè ***
--
    -- *** [JÏ ***
    ln_extrct_cnt        NUMBER;              -- o
    ln_output_cnt        NUMBER;              -- oÍ
--
    -- *** [JEJ[\ ***
    -- ÊnæcÆ^Êf[^æ¾pJ[\
    CURSOR mon_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --WvgDbc
       ,xsvsr.sales_date                 sales_date                 --ÌNú^ÌN
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --ÚqiVKj
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --ÚqiVDFVKj
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --ÚqiVDÈOFVKj
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --ãÀÑ
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --ãÀÑiVKj
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --ãÀÑiVDFVKj
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --ãÀÑiVDj
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --ãÀÑiVDÈOFVKj
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --ãÀÑiVDÈOj
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --à¼_QãÀÑ
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --à¼_QãÀÑiVDj
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --Êã\Z
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --ãvæ
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --ãvæiVKj
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --ãvæiVDFVKj
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --ãvæiVDj
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --ãvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --ãvæiVDÈOj
       ,SUM(xsvsr.vis_num              ) vis_num                    --KâÀÑ
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --KâÀÑiVKj
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --KâÀÑiVDFVKj
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --KâÀÑiVDj
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --KâÀÑiVDÈOFVKj
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --KâÀÑiVDÈOj
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --KâÀÑiMCj
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --Lø¬
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --Kâvæ
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --KâvæiVKj
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --KâvæiVDFVKj
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --KâvæiVDj
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --KâvæiVDÈOFVKj
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --KâvæiVDÈOj
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --KâvæiMCj
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --Kâ`
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --Kâa
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --Kâb
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --Kâc
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --Kâd
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --Kâe
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --Kâf
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --Kâg
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --Kâú@
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --Kâi
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --Kâj
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --Kâk
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --Kâl
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --Kâm
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --Kân
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --Kâo
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --Kâp
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --Kâq
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --Kâr
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --Kâs
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --Kât
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --Kâu
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --Kâv
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --Kâw
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --Kâx
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --Kây
      FROM
        xxcso_aff_base_level_v xablv  -- AFFåKw}X^r[
       ,xxcso_sum_visit_sale_rep xsvsr  -- KâãvæÇ\T}e[u
      WHERE  xablv.child_base_code = xsvsr.sum_org_code  -- _R[hiqj
        AND  xsvsr.sum_org_type = cv_sum_org_type_dept  -- WvgDíÞ
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- úæª
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- ÌNú
      GROUP BY  xablv.base_code      --_R[h
               ,xsvsr.sales_date     --ÌNú^ÌN
    ;
    -- *** [JER[h ***
    -- ÊnæcÆ^Êf[^æ¾pR[h
     mon_area_dt_rec mon_area_dt_cur%ROWTYPE;
    -- *** [JáO ***
    insert_error_expt    EXCEPTION;    -- o^áO
--
  BEGIN
--
--##################  ÅèXe[^Xú» START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  Åè END   ############################
--
    -- oAoÍú»
    ln_extrct_cnt := 0;              -- o
    ln_output_cnt := 0;              -- oÍ
    -- ========================
    -- ÊnæcÆ^Êf[^æ¾
    -- ========================
    -- J[\I[v
    OPEN mon_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- J[\I[vµ½±ÆðOoÍ
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- KâãvæÇ\T}e[uo^ 
      -- ======================
      <<loop_mon_area_dt>>
      LOOP
        FETCH mon_area_dt_cur INTO mon_area_dt_rec;
        -- oæ¾
        ln_extrct_cnt := mon_area_dt_cur%ROWCOUNT;
        EXIT WHEN mon_area_dt_cur%NOTFOUND
        OR  mon_area_dt_cur%ROWCOUNT = 0;
        -- o^
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --ì¬Ò
         ,creation_date              --ì¬ú
         ,last_updated_by            --ÅIXVÒ
         ,last_update_date           --ÅIXVú
         ,last_update_login          --ÅIXVOC
         ,request_id                 --vID
         ,program_application_id     --RJgEvOEAvP[VID
         ,program_id                 --RJgEvOID
         ,program_update_date        --vOXVú
         ,sum_org_type               --WvgDíÞ
         ,sum_org_code               --WvgDbc
         ,group_base_code            --O[ve_bc
         ,month_date_div             --úæª
         ,sales_date                 --ÌNú^ÌN
         ,gvm_type                   --êÊ^©Ì@^lb
         ,cust_new_num               --ÚqiVKj
         ,cust_vd_new_num            --ÚqiVDFVKj
         ,cust_other_new_num         --ÚqiVDÈOFVKj
         ,rslt_amt                   --ãÀÑ
         ,rslt_new_amt               --ãÀÑiVKj
         ,rslt_vd_new_amt            --ãÀÑiVDFVKj
         ,rslt_vd_amt                --ãÀÑiVDj
         ,rslt_other_new_amt         --ãÀÑiVDÈOFVKj
         ,rslt_other_amt             --ãÀÑiVDÈOj
         ,rslt_center_amt            --à¼_QãÀÑ
         ,rslt_center_vd_amt         --à¼_QãÀÑiVDj
         ,rslt_center_other_amt      --à¼_QãÀÑiVDÈOj
         ,tgt_sales_prsn_total_amt   --Êã\Z
         ,tgt_amt                    --ãvæ
         ,tgt_new_amt                --ãvæiVKj
         ,tgt_vd_new_amt             --ãvæiVDFVKj
         ,tgt_vd_amt                 --ãvæiVDj
         ,tgt_other_new_amt          --ãvæiVDÈOFVKj
         ,tgt_other_amt              --ãvæiVDÈOj
         ,vis_num                    --KâÀÑ
         ,vis_new_num                --KâÀÑiVKj
         ,vis_vd_new_num             --KâÀÑiVDFVKj
         ,vis_vd_num                 --KâÀÑiVDj
         ,vis_other_new_num          --KâÀÑiVDÈOFVKj
         ,vis_other_num              --KâÀÑiVDÈOj
         ,vis_mc_num                 --KâÀÑiMCj
         ,vis_sales_num              --Lø¬
         ,tgt_vis_num                --Kâvæ
         ,tgt_vis_new_num            --KâvæiVKj
         ,tgt_vis_vd_new_num         --KâvæiVDFVKj
         ,tgt_vis_vd_num             --KâvæiVDj
         ,tgt_vis_other_new_num      --KâvæiVDÈOFVKj
         ,tgt_vis_other_num          --KâvæiVDÈOj
         ,tgt_vis_mc_num             --KâvæiMCj
         ,vis_a_num                  --Kâ`
         ,vis_b_num                  --Kâa
         ,vis_c_num                  --Kâb
         ,vis_d_num                  --Kâc
         ,vis_e_num                  --Kâd
         ,vis_f_num                  --Kâe
         ,vis_g_num                  --Kâf
         ,vis_h_num                  --Kâg
         ,vis_i_num                  --Kâú@
         ,vis_j_num                  --Kâi
         ,vis_k_num                  --Kâj
         ,vis_l_num                  --Kâk
         ,vis_m_num                  --Kâl
         ,vis_n_num                  --Kâm
         ,vis_o_num                  --Kân
         ,vis_p_num                  --Kâo
         ,vis_q_num                  --Kâp
         ,vis_r_num                  --Kâq
         ,vis_s_num                  --Kâr
         ,vis_t_num                  --Kâs
         ,vis_u_num                  --Kât
         ,vis_v_num                  --Kâu
         ,vis_w_num                  --Kâv
         ,vis_x_num                  --Kâw
         ,vis_y_num                  --Kâx
         ,vis_z_num                  --Kây
        ) VALUES(
          cn_created_by                             --ì¬Ò
         ,cd_creation_date                          --ì¬ú
         ,cn_last_updated_by                        --ÅIXVÒ
         ,cd_last_update_date                       --ÅIXVú
         ,cn_last_update_login                      --ÅIXVOC
         ,cn_request_id                             --vID
         ,cn_program_application_id                 --RJgEvOEAvP[VID
         ,cn_program_id                             --RJgEvOID
         ,cd_program_update_date                    --vOXVú
         ,cv_sum_org_type_area                      --WvgDíÞ
         ,mon_area_dt_rec.sum_org_code              --WvgDbc
         ,cv_null                                   --O[ve_bc
         ,cv_month_date_div_mon                     --úæª
         ,mon_area_dt_rec.sales_date                --ÌNú^ÌN
         ,NULL                                      --êÊ^©Ì@^lb
         ,mon_area_dt_rec.cust_new_num              --ÚqiVKj
         ,mon_area_dt_rec.cust_vd_new_num           --ÚqiVDFVKj
         ,mon_area_dt_rec.cust_other_new_num        --ÚqiVDÈOFVKj
         ,mon_area_dt_rec.rslt_amt                  --ãÀÑ
         ,mon_area_dt_rec.rslt_new_amt              --ãÀÑiVKj
         ,mon_area_dt_rec.rslt_vd_new_amt           --ãÀÑiVDFVKj
         ,mon_area_dt_rec.rslt_vd_amt               --ãÀÑiVDj
         ,mon_area_dt_rec.rslt_other_new_amt        --ãÀÑiVDÈOFVKj
         ,mon_area_dt_rec.rslt_other_amt            --ãÀÑiVDÈOj
         ,mon_area_dt_rec.rslt_center_amt           --à¼_QãÀÑ
         ,mon_area_dt_rec.rslt_center_vd_amt        --à¼_QãÀÑiVDj
         ,mon_area_dt_rec.rslt_center_other_amt     --à¼_QãÀÑiVDÈOj
         ,mon_area_dt_rec.tgt_sales_prsn_total_amt  --Êã\Z
         ,mon_area_dt_rec.tgt_amt                   --ãvæ
         ,mon_area_dt_rec.tgt_new_amt               --ãvæiVKj
         ,mon_area_dt_rec.tgt_vd_new_amt            --ãvæiVDFVKj
         ,mon_area_dt_rec.tgt_vd_amt                --ãvæiVDj
         ,mon_area_dt_rec.tgt_other_new_amt         --ãvæiVDÈOFVKj
         ,mon_area_dt_rec.tgt_other_amt             --ãvæiVDÈOj
         ,mon_area_dt_rec.vis_num                   --KâÀÑ
         ,mon_area_dt_rec.vis_new_num               --KâÀÑiVKj
         ,mon_area_dt_rec.vis_vd_new_num            --KâÀÑiVDFVKj
         ,mon_area_dt_rec.vis_vd_num                --KâÀÑiVDj
         ,mon_area_dt_rec.vis_other_new_num         --KâÀÑiVDÈOFVKj
         ,mon_area_dt_rec.vis_other_num             --KâÀÑiVDÈOj
         ,mon_area_dt_rec.vis_mc_num                --KâÀÑiMCj
         ,mon_area_dt_rec.vis_sales_num             --Lø¬
         ,mon_area_dt_rec.tgt_vis_num               --Kâvæ
         ,mon_area_dt_rec.tgt_vis_new_num           --KâvæiVKj
         ,mon_area_dt_rec.tgt_vis_vd_new_num        --KâvæiVDFVKj
         ,mon_area_dt_rec.tgt_vis_vd_num            --KâvæiVDj
         ,mon_area_dt_rec.tgt_vis_other_new_num     --KâvæiVDÈOFVKj
         ,mon_area_dt_rec.tgt_vis_other_num         --KâvæiVDÈOj
         ,mon_area_dt_rec.tgt_vis_mc_num            --KâvæiMCj
         ,mon_area_dt_rec.vis_a_num                 --Kâ`
         ,mon_area_dt_rec.vis_b_num                 --Kâa
         ,mon_area_dt_rec.vis_c_num                 --Kâb
         ,mon_area_dt_rec.vis_d_num                 --Kâc
         ,mon_area_dt_rec.vis_e_num                 --Kâd
         ,mon_area_dt_rec.vis_f_num                 --Kâe
         ,mon_area_dt_rec.vis_g_num                 --Kâf
         ,mon_area_dt_rec.vis_h_num                 --Kâg
         ,mon_area_dt_rec.vis_i_num                 --Kâú@
         ,mon_area_dt_rec.vis_j_num                 --Kâi
         ,mon_area_dt_rec.vis_k_num                 --Kâj
         ,mon_area_dt_rec.vis_l_num                 --Kâk
         ,mon_area_dt_rec.vis_m_num                 --Kâl
         ,mon_area_dt_rec.vis_n_num                 --Kâm
         ,mon_area_dt_rec.vis_o_num                 --Kân
         ,mon_area_dt_rec.vis_p_num                 --Kâo
         ,mon_area_dt_rec.vis_q_num                 --Kâp
         ,mon_area_dt_rec.vis_r_num                 --Kâq
         ,mon_area_dt_rec.vis_s_num                 --Kâr
         ,mon_area_dt_rec.vis_t_num                 --Kâs
         ,mon_area_dt_rec.vis_u_num                 --Kât
         ,mon_area_dt_rec.vis_v_num                 --Kâu
         ,mon_area_dt_rec.vis_w_num                 --Kâv
         ,mon_area_dt_rec.vis_x_num                 --Kâw
         ,mon_area_dt_rec.vis_y_num                 --Kâx
         ,mon_area_dt_rec.vis_z_num                 --Kây
        )
        ;
        -- oÍÁZ
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- ÊnæcÆ^Êæ¾o^ðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_area  || CHR(10) ||
                   ''
      );
      -- J[\N[Y
      CLOSE mon_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_area || CHR(10)   ||
                   ''
      );
        -- oi[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- oÍi[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- oAoÍðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- G[bZ[Wæ¾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --AvP[VZk¼
                      ,iv_name         => cv_tkn_number_05               --bZ[WR[h
                      ,iv_token_name1  => cv_tkn_table                   --g[NR[h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_area                    --g[Nl1
                      ,iv_token_name2  => cv_tkn_errmessage              --g[NR[h2
                      ,iv_token_value2 => SQLERRM                        --g[Nl2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** o^áOnh ***
    WHEN insert_error_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊÖáOnh ***
    WHEN global_api_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      -- J[\ªN[Y³êÄ¢È¢ê
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- J[\N[Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- J[\N[Yµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END insert_mon_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : CvV[W
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- G[EbZ[W            --# Åè #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ^[ER[h              --# Åè #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- [U[EG[EbZ[W  --# Åè #
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- vO¼
--
--#####################  Åè[JÏé¾ START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode VARCHAR2(1);     -- ^[ER[h
    lv_errmsg  VARCHAR2(4000);  -- [U[EG[EbZ[W
--
--###########################  Åè END   ####################################
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
    /* 2009.11.06 K.Satomura E_T4_00135Î START */
    gn_warn_cnt   := 0;
    /* 2009.11.06 K.Satomura E_T4_00135Î END */
--
    -- ========================================
    -- A-1.ú 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf           -- G[EbZ[W            --# Åè #
      ,ov_retcode => lv_retcode          -- ^[ER[h              --# Åè #
      ,ov_errmsg  => lv_errmsg           -- [U[EG[EbZ[W  --# Åè #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ========================================
    -- A-2.p[^`FbN 
    -- ========================================
    check_parm(
       ov_errbuf  => lv_errbuf           -- G[EbZ[W            --# Åè #
      ,ov_retcode => lv_retcode          -- ^[ER[h              --# Åè #
      ,ov_errmsg  => lv_errmsg           -- [U[EG[EbZ[W  --# Åè #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gv_prm_process_div = cv_process_div_del) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- ========================================
      -- A-3.ÎÛf[^í 
      -- ========================================
      delete_data(
         ov_errbuf      => lv_errbuf      -- G[EbZ[W            --# Åè #
        ,ov_retcode     => lv_retcode     -- ^[ER[h              --# Åè #
        ,ov_errmsg      => lv_errmsg      -- [U[EG[EbZ[W  --# Åè #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    ELSIF (gv_prm_process_div = cv_process_div_ins) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- =================================================
      -- A-4.úÊÚqÊf[^æ¾ 
      -- =================================================
      get_day_acct_data(
         ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
        ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
        ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-6.úÊcÆõÊæ¾o^ 
--    -- =================================================
--    insert_day_emp_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-7.úÊcÆO[vÊæ¾o^ 
--    -- =================================================
--    insert_day_group_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-8.úÊ_^ÛÊæ¾o^ 
--    -- =================================================
--    insert_day_base_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-9.úÊnæcÆ^Êæ¾o^ 
--    -- =================================================
--    insert_day_area_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
      -- =================================================
      -- A-10.ÊÚqÊæ¾o^ 
      -- =================================================
      insert_mon_acct_dt(
         ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
        ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
        ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-11.ÊcÆõÊæ¾o^ 
--    -- =================================================
--    insert_mon_emp_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-12.ÊcÆO[vÊæ¾o^ 
--    -- =================================================
--    insert_mon_group_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-13.Ê_^ÛÊæ¾o^ 
--    -- =================================================
--    insert_mon_base_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-14.ÊnæcÆ^Êæ¾o^ 
--    -- =================================================
--    insert_mon_area_dt(
--       ov_errbuf    => lv_errbuf    -- G[EbZ[W            --# Åè #
--      ,ov_retcode   => lv_retcode   -- ^[ER[h              --# Åè #
--      ,ov_errmsg    => lv_errmsg    -- [U[EG[EbZ[W  --# Åè #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    /* 2009.11.06 K.Satomura E_T4_00135Î START */
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    /* 2009.11.06 K.Satomura E_T4_00135Î END */
  EXCEPTION
--#################################  ÅèáO START   ####################################
--
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  Åè END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : RJgÀst@Co^vV[W
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   G[EbZ[W  --# Åè #
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD Start
--    ,retcode       OUT NOCOPY VARCHAR2 )  --   ^[ER[h    --# Åè #
    ,retcode       OUT NOCOPY VARCHAR2    --   ^[ER[h    --# Åè #
    ,iv_process_div IN        VARCHAR2 )  --   æª
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD End
--
--###########################  Åè START   ###########################
--
  IS
--
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- vO¼
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
    lv_errbuf          VARCHAR2(4000);  -- G[EbZ[W
    lv_retcode         VARCHAR2(1);     -- ^[ER[h
    lv_errmsg          VARCHAR2(4000);  -- [U[EG[EbZ[W
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
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ===============================================
    -- p[^Ìi[
    -- ===============================================
    gv_prm_process_div := iv_process_div;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- ===============================================
    -- submainÌÄÑoµiÀÛÌÍsubmainÅs¤j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- G[EbZ[W            --# Åè #
      ,ov_retcode  => lv_retcode         -- ^[ER[h              --# Åè #
      ,ov_errmsg   => lv_errmsg          -- [U[EG[EbZ[W  --# Åè #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --G[oÍ
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --[U[EG[bZ[W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --G[bZ[W
       );
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- æªª'9'(í)ÌêAíð\¦
    IF (gv_prm_process_div = cv_process_div_del) THEN
      gn_extrct_cnt := gn_delete_cnt;
      gn_output_cnt := gn_delete_cnt;
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- =======================
    -- A-15.I¹ 
    -- =======================
    --ósÌoÍ
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --ÎÛoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_extrct_cnt)  -- o
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --¬÷oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_output_cnt)  -- oÍ
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --G[oÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(0)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --XLbvoÍ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    /* 2009.11.06 K.Satomura E_T4_00135Î START */
                    --,iv_token_value1 => TO_CHAR(0)
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                    /* 2009.11.06 K.Satomura E_T4_00135Î END */
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --I¹bZ[W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    /* 2009.11.06 K.Satomura E_T4_00135Î START */
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    /* 2009.11.06 K.Satomura E_T4_00135Î END */
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --Xe[^XZbg
    retcode := lv_retcode;
    --I¹Xe[^XªG[ÌêÍROLLBACK·é
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- [obNµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- [obNµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- [obNµ½±ÆðOoÍ
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  Åè END   #######################################################
--
END XXCSO019A10C;
/
